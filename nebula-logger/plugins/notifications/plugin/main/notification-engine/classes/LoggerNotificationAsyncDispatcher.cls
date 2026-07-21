//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Async harness for every `LoggerNotifier` implementation. `LoggerNotificationProcessor`
 *              batches all recipients across all matched rules into a single instance of this
 *              Queueable and enqueues it once per transaction. The Queueable rehydrates each
 *              request, instantiates the notifier class, invokes `sendNotification` in an async
 *              request where callouts are legal, and updates the pre-inserted
 *              `LoggerNotificationDelivery__c` records with the outcome.
 *
 *              Even non-callout notifiers (Email, CustomNotification) run here rather than in
 *              the source trigger transaction. That way notifier failures never break the record
 *              insert, and every notification gets its own governor budget separate from the
 *              trigger's.
 *
 *              If the callout limit is reached partway through, the remaining dispatches are
 *              re-enqueued into a fresh instance so no work is dropped.
 */
public without sharing class LoggerNotificationAsyncDispatcher implements System.Queueable, Database.AllowsCallouts {
  @TestVisible
  private final List<PendingDispatch> pendingDispatches;

  /**
   * @description Constructs a dispatcher with a batch of pending dispatches.
   * @param pendingDispatches The list of rule+recipient+service+records tuples to deliver.
   */
  public LoggerNotificationAsyncDispatcher(List<PendingDispatch> pendingDispatches) {
    this.pendingDispatches = pendingDispatches ?? new List<PendingDispatch>();
  }

  /**
   * @description Called by the Salesforce Queueable framework.
   * @param queueableContext Provided by the platform; unused.
   */
  public void execute(System.QueueableContext queueableContext) {
    Id jobId = queueableContext?.getJobId();
    List<PendingDispatch> remaining = new List<PendingDispatch>();
    Integer index = 0;
    List<LoggerNotificationDelivery__c> deliveriesToUpdate = new List<LoggerNotificationDelivery__c>();
    for (PendingDispatch dispatch : this.pendingDispatches) {
      if (this.isCalloutLimitReached()) {
        for (Integer i = index; i < this.pendingDispatches.size(); i++) {
          remaining.add(this.pendingDispatches.get(i));
        }
        break;
      }
      this.invokeNotifier(dispatch, jobId, deliveriesToUpdate);
      index++;
    }
    LoggerDataStore.getDatabase().updateRecords(deliveriesToUpdate);
    if (remaining.isEmpty() == false && System.Limits.getQueueableJobs() < System.Limits.getLimitQueueableJobs()) {
      LoggerDataStore.getJobQueue().enqueueJob(new LoggerNotificationAsyncDispatcher(remaining));
    }
  }

  private void invokeNotifier(PendingDispatch dispatch, Id jobId, List<LoggerNotificationDelivery__c> deliveriesToUpdate) {
    LoggerNotifier notifier = newNotifierInstance(dispatch.service?.NotifierApexClassName__c);
    List<LoggerNotificationDelivery__c> deliveries = this.rehydrateDeliveries(dispatch);
    if (notifier == null) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('Nebula Logger Notifications - async dispatcher could not instantiate notifier class ' + dispatch.service?.NotifierApexClassName__c);
      }
      if (deliveries != null) {
        LoggerNotifierResult skipped = new LoggerNotifierResult();
        skipped.status = LoggerNotifierResult.STATUS_SKIPPED;
        skipped.errorMessage = 'Could not instantiate notifier class ' + dispatch.service?.NotifierApexClassName__c;
        skipped.jobId = jobId;
        Datetime now = System.now();
        skipped.finalizeDeliveries(deliveries, now, now);
        deliveriesToUpdate.addAll(deliveries);
      }
      return;
    }
    LoggerNotifierRequest request = new LoggerNotifierRequest(dispatch.notificationRule, dispatch.recipient, dispatch.service, dispatch.matchingRecords);
    Datetime dispatchStart = System.now();
    LoggerNotifierResult result;
    try {
      result = notifier.sendNotification(request);
    } catch (System.Exception ex) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.error('Nebula Logger Notifications - async notifier ' + dispatch.service?.NotifierApexClassName__c + ' threw an exception', ex);
      }
      result = new LoggerNotifierResult();
      result.status = LoggerNotifierResult.STATUS_FAILED;
      result.errorMessage = ex.getMessage();
      result.errorStackTrace = ex.getStackTraceString();
    }
    Datetime dispatchEnd = System.now();
    if (deliveries != null) {
      if (result == null) {
        result = new LoggerNotifierResult(LoggerNotifierResult.STATUS_DELIVERED, null);
      }
      result.jobId = jobId;
      result.finalizeDeliveries(deliveries, dispatchStart, dispatchEnd);
      deliveriesToUpdate.addAll(deliveries);
    }
  }

  private List<LoggerNotificationDelivery__c> rehydrateDeliveries(PendingDispatch dispatch) {
    if (dispatch.pendingDeliveryIds == null || dispatch.pendingDeliveryIds.isEmpty()) {
      return null;
    }
    List<LoggerNotificationDelivery__c> deliveries = new List<LoggerNotificationDelivery__c>();
    for (Id deliveryId : dispatch.pendingDeliveryIds) {
      deliveries.add(new LoggerNotificationDelivery__c(Id = deliveryId));
    }
    return deliveries;
  }

  @TestVisible
  private Boolean isCalloutLimitReached() {
    return System.Limits.getCallouts() >= (System.Limits.getLimitCallouts() - 1);
  }

  private static LoggerNotifier newNotifierInstance(String apexClassName) {
    if (String.isBlank(apexClassName)) {
      return null;
    }
    System.Type notifierType = System.Type.forName(apexClassName);
    if (notifierType == null) {
      return null;
    }
    Object instance = notifierType.newInstance();
    return instance instanceof LoggerNotifier ? (LoggerNotifier) instance : null;
  }

  /**
   * @description DTO representing one pending dispatch - a single (rule, recipient, service, records)
   *              tuple that will be delivered by a `LoggerNotifier` implementation. Optionally carries
   *              the Ids of pre-inserted `LoggerNotificationDelivery__c` records so the async dispatcher
   *              can update them with the delivery outcome.
   */
  public class PendingDispatch {
    public LoggerNotificationRule__c notificationRule { get; private set; }
    public LoggerNotificationRecipient__c recipient { get; private set; }
    public LoggerNotificationService__c service { get; private set; }
    public List<SObject> matchingRecords { get; private set; }
    // Populated by the runtime when delivery history is enabled. In-memory only during the enqueuing
    // transaction; the dispatcher uses the Ids to update the deliveries after the callout completes.
    public List<LoggerNotificationDelivery__c> pendingDeliveries;
    public List<Id> pendingDeliveryIds;

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public PendingDispatch(
      LoggerNotificationRule__c notificationRule,
      LoggerNotificationRecipient__c recipient,
      LoggerNotificationService__c service,
      List<SObject> matchingRecords
    ) {
      this.notificationRule = notificationRule;
      this.recipient = recipient;
      this.service = service;
      this.matchingRecords = matchingRecords;
    }
  }
}
