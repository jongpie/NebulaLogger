//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Partitions a list of `LoggerNotificationAsyncDispatcher.PendingDispatch` entries into
 *              one or more transactionally-compatible groups. Each group can safely run in a single
 *              Queueable transaction: no notifier in the group performs a callout after another
 *              notifier in the group performed DML, and no notifier is scheduled alongside an
 *              email-sending notifier when their combination is unsafe.
 *
 *              The packer walks a compatibility state machine to answer "can dispatch N join the
 *              current group?" for each dispatch in order. When the answer is no, the current group
 *              closes and a new one starts.
 *
 *              Ordering rules Salesforce imposes, from which the compatibility rules are derived:
 *                - Callouts after DML in the same transaction throw
 *                  `System.CalloutException: You have uncommitted work pending`.
 *                - `Messaging.sendEmail(...)` after either DML or a callout is conservatively unsafe
 *                  and gets its own group.
 *
 *              Within a group the packer reorders dispatches so `CALLOUT`-only notifiers run first,
 *              then `DML`-only, then `EMAIL`-only. That maximizes packing: a group whose recipients
 *              are (in enqueue order) DML, CALLOUT, DML packs into one group because the reorder
 *              produces CALLOUT, DML, DML.
 *
 *              A notifier that declares `Operation.CALLOUT` and `Operation.DML` together is treated
 *              as callout-first because the notifier's own `sendNotification` runs its callouts
 *              before its DML - the notifier author's responsibility, not the framework's.
 *
 *              Notifiers whose class can't be resolved from `NotifierApexClassName__c` (misconfigured
 *              service record, deleted class) are assigned an empty operation set. That is safe under
 *              the compatibility rules (empty set = "does nothing tracked") and lets the async
 *              dispatcher's per-invocation error handling take over instead of failing here.
 */
public without sharing class LoggerNotifierDispatchPacker {
  private final Map<String, Set<LoggerNotifier.Operation>> operationsByApexClassName = new Map<String, Set<LoggerNotifier.Operation>>();

  /**
   * @description Partitions `dispatches` into groups. The returned list preserves each group's
   *              (reordered) internal dispatch order. An empty or null input yields an empty list.
   * @param dispatches The dispatches to pack.
   * @return One list of dispatches per group, in the order the async dispatcher should execute them.
   */
  public List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>> pack(List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches) {
    List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>> groups = new List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>>();
    if (dispatches == null || dispatches.isEmpty()) {
      return groups;
    }

    List<LoggerNotificationAsyncDispatcher.PendingDispatch> reordered = this.reorderForMaximalPacking(dispatches);

    List<LoggerNotificationAsyncDispatcher.PendingDispatch> currentGroup = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>();
    Boolean groupDidDml = false;
    Boolean groupDidCallout = false;
    Boolean groupDidEmail = false;
    for (LoggerNotificationAsyncDispatcher.PendingDispatch dispatch : reordered) {
      Set<LoggerNotifier.Operation> operations = this.getOperationsForDispatch(dispatch);
      Boolean wantsCallout = operations.contains(LoggerNotifier.Operation.CALLOUT);
      Boolean wantsDml = operations.contains(LoggerNotifier.Operation.DML);
      Boolean wantsEmail = operations.contains(LoggerNotifier.Operation.EMAIL);

      // "Callout after DML" and "anything after EMAIL" (and "EMAIL after CALLOUT") force a new group.
      Boolean fitsCurrentGroup = true;
      if (wantsCallout && groupDidDml) {
        fitsCurrentGroup = false;
      }
      if (wantsEmail && (groupDidCallout || groupDidDml)) {
        fitsCurrentGroup = false;
      }
      if ((wantsCallout || wantsDml) && groupDidEmail) {
        fitsCurrentGroup = false;
      }

      if (fitsCurrentGroup == false && currentGroup.isEmpty() == false) {
        groups.add(currentGroup);
        currentGroup = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>();
        groupDidDml = false;
        groupDidCallout = false;
        groupDidEmail = false;
      }

      currentGroup.add(dispatch);
      if (wantsCallout) {
        groupDidCallout = true;
      }
      if (wantsDml) {
        groupDidDml = true;
      }
      if (wantsEmail) {
        groupDidEmail = true;
      }
    }
    if (currentGroup.isEmpty() == false) {
      groups.add(currentGroup);
    }
    return groups;
  }

  /**
   * @description Reorders the incoming dispatches so callout-only notifiers come first, then
   *              DML-only, then EMAIL-only, with any mixed / empty-set dispatches interleaved by
   *              their original relative order. Preserves relative order within each bucket so the
   *              output is stable given a stable input.
   */
  private List<LoggerNotificationAsyncDispatcher.PendingDispatch> reorderForMaximalPacking(List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches) {
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> calloutFirst = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dmlOnly = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> emailOnly = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> everythingElse = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>();
    for (LoggerNotificationAsyncDispatcher.PendingDispatch dispatch : dispatches) {
      Set<LoggerNotifier.Operation> operations = this.getOperationsForDispatch(dispatch);
      Boolean hasCallout = operations.contains(LoggerNotifier.Operation.CALLOUT);
      Boolean hasDml = operations.contains(LoggerNotifier.Operation.DML);
      Boolean hasEmail = operations.contains(LoggerNotifier.Operation.EMAIL);

      if (hasCallout) {
        calloutFirst.add(dispatch);
      } else if (hasDml && hasEmail == false) {
        dmlOnly.add(dispatch);
      } else if (hasEmail && hasDml == false) {
        emailOnly.add(dispatch);
      } else {
        everythingElse.add(dispatch);
      }
    }
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> reordered = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>();
    reordered.addAll(calloutFirst);
    reordered.addAll(dmlOnly);
    reordered.addAll(emailOnly);
    reordered.addAll(everythingElse);
    return reordered;
  }

  /**
   * @description Resolves the notifier class named on the dispatch's service and returns its
   *              declared operations, memoized by apex class name so a rule with many recipients
   *              pointing at the same notifier class only instantiates and inspects it once.
   *              Returns an empty set when the class name is blank, unresolvable, or the resolved
   *              class is not a `LoggerNotifier` - which lets the packer keep going and hands the
   *              actual dispatch-time error handling back to `LoggerNotificationAsyncDispatcher`.
   */
  private Set<LoggerNotifier.Operation> getOperationsForDispatch(LoggerNotificationAsyncDispatcher.PendingDispatch dispatch) {
    String apexClassName = dispatch?.recipient?.LoggerNotificationService__r?.NotifierApexClassName__c;
    if (String.isBlank(apexClassName)) {
      return new Set<LoggerNotifier.Operation>();
    }
    if (this.operationsByApexClassName.containsKey(apexClassName)) {
      return this.operationsByApexClassName.get(apexClassName);
    }
    Set<LoggerNotifier.Operation> operations = resolveOperationsForClass(apexClassName);
    this.operationsByApexClassName.put(apexClassName, operations);
    return operations;
  }

  private static Set<LoggerNotifier.Operation> resolveOperationsForClass(String apexClassName) {
    System.Type notifierType = System.Type.forName(apexClassName);
    if (notifierType == null) {
      return new Set<LoggerNotifier.Operation>();
    }
    Object instance = notifierType.newInstance();
    if ((instance instanceof LoggerNotifier) == false) {
      return new Set<LoggerNotifier.Operation>();
    }
    Set<LoggerNotifier.Operation> declared = ((LoggerNotifier) instance).getSupportedOperations();
    return declared == null ? new Set<LoggerNotifier.Operation>() : declared;
  }
}
