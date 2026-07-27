//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Async harness for every `LoggerNotifier` implementation. `LoggerNotificationProcessor`
 *              batches all recipients across all matched rules into a single instance of this
 *              Queueable and enqueues it once per transaction.
 *
 *              On construction, incoming dispatches are handed to `LoggerNotifierDispatchPacker`,
 *              which partitions them into transactionally-compatible groups. The FIRST group runs
 *              inside this Queueable's `execute`; any remaining groups are stored on the instance
 *              and enqueued by the attached `Finalizer` after the Queueable completes. Each group
 *              gets its own Queueable transaction, which means each group starts with a clean DML
 *              and callout budget - a rule with a DML-performing notifier alongside a
 *              callout-performing notifier no longer produces "uncommitted work pending".
 *
 *              Even non-callout, non-DML notifiers (e.g. Email) run here rather than in the source
 *              trigger transaction. That way notifier failures never break the record insert, and
 *              every notification gets its own governor budget separate from the trigger's.
 *
 *              Delivery-record updates happen in the Finalizer, not in the Queueable itself. The
 *              Finalizer runs in a fresh transaction with a fresh DML budget, so writing outcomes
 *              onto delivery records never competes with the callouts the notifiers just made.
 *
 *              If the callout budget is exhausted partway through the current group, the untried
 *              dispatches are prepended to the remaining groups so the follow-up Queueable picks
 *              them up first.
 */
public without sharing class LoggerNotificationAsyncDispatcher implements System.Queueable, Database.AllowsCallouts {
  @TestVisible
  private final List<PendingDispatch> pendingDispatches;
  @TestVisible
  private final List<List<PendingDispatch>> remainingGroups;
  @TestVisible
  private final List<LoggerNotificationDelivery__c> deliveriesToUpdate = new List<LoggerNotificationDelivery__c>();
  @TestVisible
  private final DeferredWorkBuffer deferredWork = new DeferredWorkBuffer();

  /**
   * @description Public constructor called by `LoggerNotificationProcessor` after the source trigger
   *              transaction has inserted the pending delivery records. Runs the dispatches through
   *              `LoggerNotifierDispatchPacker` so this Queueable executes only the first
   *              transactionally-compatible group; any remaining groups are chained by the Finalizer.
   * @param pendingDispatches The flat list of dispatches to deliver.
   */
  public LoggerNotificationAsyncDispatcher(List<PendingDispatch> pendingDispatches) {
    List<List<PendingDispatch>> groups = new LoggerNotifierDispatchPacker().pack(pendingDispatches);
    this.pendingDispatches = groups.isEmpty() ? new List<PendingDispatch>() : groups.get(0);
    this.remainingGroups = new List<List<PendingDispatch>>();
    for (Integer i = 1; i < groups.size(); i++) {
      this.remainingGroups.add(groups.get(i));
    }
  }

  /**
   * @description Internal factory used by the `Finalizer` when chaining to the next group's
   *              Queueable. Skips the packer because the input is already partitioned - re-packing
   *              a single group would collapse it back into one but would also spend the notifier
   *              instantiation budget again for no benefit.
   * @param preGroupedDispatches The groups the previous Finalizer wanted to enqueue, in order.
   * @return A dispatcher whose `pendingDispatches` is the first group and whose `remainingGroups`
   *         is everything after it.
   */
  public static LoggerNotificationAsyncDispatcher forRemainingGroups(List<List<PendingDispatch>> preGroupedDispatches) {
    return new LoggerNotificationAsyncDispatcher(preGroupedDispatches, true);
  }

  private LoggerNotificationAsyncDispatcher(List<List<PendingDispatch>> preGroupedDispatches, Boolean skipPacking) {
    this.pendingDispatches = preGroupedDispatches == null || preGroupedDispatches.isEmpty() ? new List<PendingDispatch>() : preGroupedDispatches.get(0);
    this.remainingGroups = new List<List<PendingDispatch>>();
    if (preGroupedDispatches != null) {
      for (Integer i = 1; i < preGroupedDispatches.size(); i++) {
        this.remainingGroups.add(preGroupedDispatches.get(i));
      }
    }
  }

  /**
   * @description Called by the Salesforce Queueable framework. Runs the current group's notifiers,
   *              accumulates delivery-record updates in `deliveriesToUpdate`, and attaches a
   *              `Finalizer` that applies those updates and enqueues the next group.
   * @param queueableContext Provided by the platform.
   */
  public void execute(System.QueueableContext queueableContext) {
    Id jobId = queueableContext?.getJobId();
    List<PendingDispatch> untried = new List<PendingDispatch>();
    for (Integer i = 0; i < this.pendingDispatches.size(); i++) {
      if (this.isCalloutLimitReached()) {
        for (Integer j = i; j < this.pendingDispatches.size(); j++) {
          untried.add(this.pendingDispatches.get(j));
        }
        break;
      }
      this.invokeNotifier(this.pendingDispatches.get(i), jobId, this.deliveriesToUpdate);
    }
    List<List<PendingDispatch>> effectiveRemaining = new List<List<PendingDispatch>>();
    if (untried.isEmpty() == false) {
      effectiveRemaining.add(untried);
    }
    effectiveRemaining.addAll(this.remainingGroups);
    // A null QueueableContext means we're being invoked outside the platform's Queueable framework -
    // typically a synchronous test call. `System.attachFinalizer` throws in that context, so tests
    // that want to exercise the Finalizer's chain / delivery-update behavior invoke
    // `Finalizer.finalizeCurrentGroup` directly via its @TestVisible seam.
    if (queueableContext != null) {
      System.attachFinalizer(new Finalizer(this.pendingDispatches, this.deliveriesToUpdate, this.deferredWork, effectiveRemaining));
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
    if (result != null) {
      this.deferredWork.accumulate(result);
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

  /**
   * @description Runs post-Queueable in a fresh transaction. Two responsibilities: apply the
   *              outcome updates the Queueable accumulated onto the pre-inserted delivery records,
   *              and enqueue the next group's Queueable when more groups remain. Fresh transaction
   *              here means neither the delivery-record update nor the next Queueable's execution
   *              interact with the callouts / DML the Queueable just performed.
   *
   *              On unhandled exception in the Queueable (`ParentJobResult.UNHANDLED_EXCEPTION`),
   *              the Finalizer marks every current-group delivery that wasn't already stamped as
   *              `Failed` and STILL enqueues the next group - so an upstream failure doesn't block
   *              downstream notifiers.
   */
  public class Finalizer implements System.Finalizer {
    @TestVisible
    private final List<PendingDispatch> currentGroupDispatches;
    @TestVisible
    private final List<LoggerNotificationDelivery__c> deliveriesToUpdate;
    @TestVisible
    private final DeferredWorkBuffer deferredWork;
    @TestVisible
    private final List<List<PendingDispatch>> remainingGroups;

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public Finalizer(
      List<PendingDispatch> currentGroupDispatches,
      List<LoggerNotificationDelivery__c> deliveriesToUpdate,
      DeferredWorkBuffer deferredWork,
      List<List<PendingDispatch>> remainingGroups
    ) {
      this.currentGroupDispatches = currentGroupDispatches;
      this.deliveriesToUpdate = deliveriesToUpdate;
      this.deferredWork = deferredWork;
      this.remainingGroups = remainingGroups;
    }

    /**
     * @description Called by the Salesforce Queueable-Finalizer framework.
     * @param context Provided by the platform - exposes the parent Queueable's result
     *                (`SUCCESS` or `UNHANDLED_EXCEPTION`) and job id.
     */
    public void execute(System.FinalizerContext context) {
      this.finalizeCurrentGroup(context?.getResult());
    }

    /**
     * @description The Finalizer's core logic, factored out so tests can invoke it directly with a
     *              `System.ParentJobResult`. Salesforce does not let user code construct a
     *              `System.FinalizerContext`, so tests exercise this seam instead of `execute`.
     * @param result The parent Queueable's terminal state.
     */
    @TestVisible
    private void finalizeCurrentGroup(System.ParentJobResult result) {
      if (result == System.ParentJobResult.UNHANDLED_EXCEPTION) {
        this.markUntouchedDeliveriesAsFailed();
      }
      // Order within this fresh Finalizer transaction follows the same per-transaction rules the
      // packer enforces across groups: callouts and emails first (before any DML sets the
      // uncommitted-work flag), THEN the delivery-record update DML, THEN any notifier-deferred DML,
      // THEN enqueue follow-up queueables (each of which runs in its own transaction).
      if (this.deferredWork != null) {
        this.deferredWork.flushCalloutsAndEmails();
      }
      if (this.deliveriesToUpdate != null && this.deliveriesToUpdate.isEmpty() == false) {
        LoggerDataStore.getDatabase().updateRecords(this.deliveriesToUpdate);
      }
      if (this.deferredWork != null) {
        this.deferredWork.flushDmlAndFollowUpQueueables();
      }
      this.chainNextGroup();
    }

    /**
     * @description When the parent Queueable threw uncaught, any current-group dispatches that didn't
     *              record an outcome get a synthetic `Failed` delivery record so the admin-facing
     *              delivery row reflects reality instead of staying stuck at `Pending` indefinitely.
     */
    private void markUntouchedDeliveriesAsFailed() {
      if (this.currentGroupDispatches == null || this.currentGroupDispatches.isEmpty()) {
        return;
      }
      Set<Id> alreadyStampedIds = new Set<Id>();
      if (this.deliveriesToUpdate != null) {
        for (LoggerNotificationDelivery__c delivery : this.deliveriesToUpdate) {
          if (delivery.Id != null) {
            alreadyStampedIds.add(delivery.Id);
          }
        }
      }
      Datetime now = System.now();
      LoggerNotifierResult failure = new LoggerNotifierResult();
      failure.status = LoggerNotifierResult.STATUS_FAILED;
      failure.errorMessage = 'Async dispatcher Queueable threw an unhandled exception before this delivery could be attempted';
      for (PendingDispatch dispatch : this.currentGroupDispatches) {
        if (dispatch.pendingDeliveryIds == null || dispatch.pendingDeliveryIds.isEmpty()) {
          continue;
        }
        List<LoggerNotificationDelivery__c> untouchedDeliveries = new List<LoggerNotificationDelivery__c>();
        for (Id pendingId : dispatch.pendingDeliveryIds) {
          if (alreadyStampedIds.contains(pendingId)) {
            continue;
          }
          untouchedDeliveries.add(new LoggerNotificationDelivery__c(Id = pendingId));
        }
        if (untouchedDeliveries.isEmpty() == false) {
          failure.finalizeDeliveries(untouchedDeliveries, now, now);
          this.deliveriesToUpdate.addAll(untouchedDeliveries);
        }
      }
    }

    private void chainNextGroup() {
      if (this.remainingGroups == null || this.remainingGroups.isEmpty()) {
        return;
      }
      // TODO surface a warning when the queueable-jobs limit is reached instead of silently dropping
      if (System.Limits.getQueueableJobs() >= System.Limits.getLimitQueueableJobs()) {
        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
          Logger.warn('Nebula Logger Notifications - queueable limit reached; ' + this.remainingGroups.size() + ' remaining group(s) not enqueued');
        }
        return;
      }
      LoggerDataStore.getJobQueue().enqueueJob(LoggerNotificationAsyncDispatcher.forRemainingGroups(this.remainingGroups));
    }
  }

  /**
   * @description Accumulates the deferred work fields off every `LoggerNotifierResult` a notifier
   *              returns in the current group. The Finalizer flushes the buffer in two halves so the
   *              callouts and emails execute before any DML sets the uncommitted-work flag on the
   *              Finalizer's transaction: `flushCalloutsAndEmails` runs first, then the Finalizer
   *              does its own delivery-record update DML, then `flushDmlAndFollowUpQueueables` runs
   *              any notifier-deferred DML and enqueues follow-up queueables.
   *
   *              Accumulator lists are lazily initialized so a group of notifiers that declare no
   *              deferred work costs nothing beyond the buffer's own construction.
   */
  public class DeferredWorkBuffer {
    @TestVisible
    private List<SObject> dmlInserts;
    @TestVisible
    private List<SObject> dmlUpdates;
    @TestVisible
    private List<SObject> dmlDeletes;
    @TestVisible
    private List<System.HttpRequest> callouts;
    @TestVisible
    private List<Messaging.SingleEmailMessage> emails;
    @TestVisible
    private List<System.Queueable> followUpQueueables;

    /**
     * @description Copies the deferred* fields off the given result onto this buffer. Null / empty
     *              lists on the result contribute nothing.
     * @param result The notifier's return value.
     */
    public void accumulate(LoggerNotifierResult result) {
      if (result == null) {
        return;
      }
      this.dmlInserts = append(this.dmlInserts, result.deferredDmlInserts);
      this.dmlUpdates = append(this.dmlUpdates, result.deferredDmlUpdates);
      this.dmlDeletes = append(this.dmlDeletes, result.deferredDmlDeletes);
      this.callouts = append(this.callouts, result.deferredCallouts);
      this.emails = append(this.emails, result.deferredEmails);
      this.followUpQueueables = append(this.followUpQueueables, result.followUpQueueables);
    }

    /**
     * @description First half of the flush. Fires callouts and sends emails before any DML in the
     *              Finalizer's transaction sets the uncommitted-work flag. Errors from an individual
     *              callout / email are swallowed so downstream deferred work still gets a chance.
     */
    public void flushCalloutsAndEmails() {
      if (this.callouts != null) {
        for (System.HttpRequest request : this.callouts) {
          try {
            new System.Http().send(request);
          } catch (System.Exception ex) {
            if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
              Logger.warn('Nebula Logger Notifications - deferred callout failed: ' + ex.getMessage(), ex);
            }
          }
        }
      }
      if (this.emails != null && this.emails.isEmpty() == false) {
        try {
          Messaging.sendEmail(this.emails, false);
        } catch (System.Exception ex) {
          if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
            Logger.warn('Nebula Logger Notifications - deferred email send failed: ' + ex.getMessage(), ex);
          }
        }
      }
    }

    /**
     * @description Second half of the flush. Runs any notifier-deferred DML, then enqueues any
     *              escape-hatch queueables. Runs AFTER the Finalizer's own delivery-record update
     *              so the two DML statements batch cleanly (they both mutate `LoggerNotificationDelivery__c`
     *              vs. plugin-owned sobjects, but the platform doesn't care).
     */
    public void flushDmlAndFollowUpQueueables() {
      if (this.dmlInserts != null && this.dmlInserts.isEmpty() == false) {
        LoggerDataStore.getDatabase().insertRecords(this.dmlInserts);
      }
      if (this.dmlUpdates != null && this.dmlUpdates.isEmpty() == false) {
        LoggerDataStore.getDatabase().updateRecords(this.dmlUpdates);
      }
      if (this.dmlDeletes != null && this.dmlDeletes.isEmpty() == false) {
        LoggerDataStore.getDatabase().deleteRecords(this.dmlDeletes);
      }
      this.enqueueFollowUpQueueables();
    }

    private void enqueueFollowUpQueueables() {
      if (this.followUpQueueables == null) {
        return;
      }
      for (System.Queueable queueable : this.followUpQueueables) {
        if (System.Limits.getQueueableJobs() >= System.Limits.getLimitQueueableJobs()) {
          if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
            Logger.warn('Nebula Logger Notifications - queueable limit reached; a deferred follow-up queueable was not enqueued');
          }
          return;
        }
        LoggerDataStore.getJobQueue().enqueueJob(queueable);
      }
    }

    private List<SObject> append(List<SObject> destination, List<SObject> source) {
      if (source == null || source.isEmpty()) {
        return destination;
      }
      List<SObject> effective = destination == null ? new List<SObject>() : destination;
      effective.addAll(source);
      return effective;
    }

    private List<System.HttpRequest> append(List<System.HttpRequest> destination, List<System.HttpRequest> source) {
      if (source == null || source.isEmpty()) {
        return destination;
      }
      List<System.HttpRequest> effective = destination == null ? new List<System.HttpRequest>() : destination;
      effective.addAll(source);
      return effective;
    }

    private List<Messaging.SingleEmailMessage> append(List<Messaging.SingleEmailMessage> destination, List<Messaging.SingleEmailMessage> source) {
      if (source == null || source.isEmpty()) {
        return destination;
      }
      List<Messaging.SingleEmailMessage> effective = destination == null ? new List<Messaging.SingleEmailMessage>() : destination;
      effective.addAll(source);
      return effective;
    }

    private List<System.Queueable> append(List<System.Queueable> destination, List<System.Queueable> source) {
      if (source == null || source.isEmpty()) {
        return destination;
      }
      List<System.Queueable> effective = destination == null ? new List<System.Queueable>() : destination;
      effective.addAll(source);
      return effective;
    }
  }
}
