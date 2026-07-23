//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Async harness for every `LoggerNotifier` implementation. `LoggerNotificationProcessor`
 *              batches all recipients across all matched rules into a single instance of this
 *              Queueable and enqueues it once per transaction. The Queueable builds a
 *              `LoggerNotifierRequest` per dispatch, instantiates the notifier class, invokes
 *              `sendNotification` in an async request where callouts are legal, and updates the
 *              pre-inserted `LoggerNotificationDelivery__c` records with the outcome.
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
    LoggerNotifier notifier = newNotifierInstance(dispatch.recipient.LoggerNotificationService__r.NotifierApexClassName__c);
    List<LoggerNotificationDelivery__c> deliveries = this.buildDeliveriesToUpdate(dispatch);
    if (notifier == null) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn(
          'Nebula Logger Notifications - async dispatcher could not instantiate notifier class ' +
          dispatch.recipient.LoggerNotificationService__r.NotifierApexClassName__c
        );
      }
      if (deliveries != null) {
        LoggerNotifierResult skipped = new LoggerNotifierResult();
        skipped.errorMessage = 'Could not instantiate notifier class ' + dispatch.recipient.LoggerNotificationService__r.NotifierApexClassName__c;
        skipped.jobId = jobId;
        skipped.status = LoggerNotifierResult.STATUS_SKIPPED;
        Datetime now = System.now();
        skipped.finalizeDeliveries(deliveries, now, now);
        deliveriesToUpdate.addAll(deliveries);
      }
      return;
    }
    LoggerNotifierRequest request = new LoggerNotifierRequest(dispatch.recipient, dispatch.matchingRecords);
    Datetime dispatchStart = System.now();
    LoggerNotifierResult result;
    try {
      result = notifier.sendNotification(request);
    } catch (System.Exception ex) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.error(
          'Nebula Logger Notifications - async notifier ' + dispatch.recipient.LoggerNotificationService__r.NotifierApexClassName__c + ' threw an exception',
          ex
        );
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

  /**
   * @description Constructs empty `LoggerNotificationDelivery__c` records carrying only the pre-inserted
   *              delivery IDs. Returns null when the rule had `IsDeliveryHistoryEnabled__c` = FALSE
   *              (no pending delivery records were inserted).
   */
  private List<LoggerNotificationDelivery__c> buildDeliveriesToUpdate(PendingDispatch dispatch) {
    if (dispatch.pendingDeliveryIds == null || dispatch.pendingDeliveryIds.isEmpty()) {
      return null;
    }
    List<LoggerNotificationDelivery__c> deliveries = new List<LoggerNotificationDelivery__c>();
    for (Id deliveryId : dispatch.pendingDeliveryIds) {
      deliveries.add(new LoggerNotificationDelivery__c(Id = deliveryId));
    }
    return deliveries;
  }

  private Boolean isCalloutLimitReached() {
    // TODO remove this method probably
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
    // The recipient carries its own rule + service via `LoggerNotificationRule__r` and
    // `LoggerNotificationService__r`; callers read them off the recipient directly.
    public final LoggerNotificationRecipient__c recipient;
    public final List<SObject> matchingRecords;
    // Set at construction time by the runtime when delivery history is enabled. In-memory only during
    // the enqueuing transaction; the dispatcher reads their Ids into `pendingDeliveryIds` after DML so
    // it can update them once the callout completes.
    public final List<LoggerNotificationDelivery__c> pendingDeliveries;
    // Populated by the runtime AFTER the pending deliveries are inserted; the dispatcher builds
    // Id-only update records from these values at execute time.
    public List<Id> pendingDeliveryIds;

    public PendingDispatch(LoggerNotificationRecipient__c recipient, List<SObject> matchingRecords, List<LoggerNotificationDelivery__c> pendingDeliveries) {
      this.recipient = recipient;
      this.matchingRecords = matchingRecords;
      this.pendingDeliveries = pendingDeliveries;
    }
  }
}
