//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotificationAsyncDispatcher_Tests {
  private static final String MOCK_NOTIFIER_CLASS = MockNotifier.class.getName();
  private static Integer mockNotifierInvocationCount = 0;
  private static Integer mockNotifierThrownCount = 0;
  private static Boolean mockNotifierShouldThrowNext = false;

  // Static config the CapturingNotifier reads from when returning its LoggerNotifierResult. Nulled
  // out between tests via `resetCapturingNotifier`.
  private static List<SObject> deferredDmlInsertsToReturn;
  private static List<SObject> deferredDmlUpdatesToReturn;
  private static List<SObject> deferredDmlDeletesToReturn;
  private static List<Messaging.SingleEmailMessage> deferredEmailsToReturn;
  private static List<System.Queueable> capturedFollowUpQueueablesToReturn;

  static {
    // Don't use the org's actual custom metadata records when running tests
    LoggerConfigurationSelector.useMocks();
  }

  private static void resetMockNotifier() {
    mockNotifierInvocationCount = 0;
    mockNotifierThrownCount = 0;
    mockNotifierShouldThrowNext = false;
  }

  private static void resetCapturingNotifier() {
    deferredDmlInsertsToReturn = null;
    deferredDmlUpdatesToReturn = null;
    deferredDmlDeletesToReturn = null;
    deferredEmailsToReturn = null;
    capturedFollowUpQueueablesToReturn = null;
  }

  @IsTest
  static void it_should_handle_null_and_empty_dispatch_lists_without_error() {
    resetMockNotifier();
    LoggerNotificationAsyncDispatcher nullDispatcher = new LoggerNotificationAsyncDispatcher(null);
    LoggerNotificationAsyncDispatcher emptyDispatcher = new LoggerNotificationAsyncDispatcher(new List<LoggerNotificationAsyncDispatcher.PendingDispatch>());

    System.Test.startTest();
    nullDispatcher.execute(null);
    emptyDispatcher.execute(null);
    System.Test.stopTest();

    System.Assert.areEqual(0, mockNotifierInvocationCount);
  }

  @IsTest
  static void it_should_invoke_each_notifier_for_each_pending_dispatch() {
    resetMockNotifier();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(MOCK_NOTIFIER_CLASS),
      buildDispatch(MOCK_NOTIFIER_CLASS),
      buildDispatch(MOCK_NOTIFIER_CLASS)
    };
    LoggerNotificationAsyncDispatcher dispatcher = new LoggerNotificationAsyncDispatcher(dispatches);

    System.Test.startTest();
    dispatcher.execute(null);
    System.Test.stopTest();

    System.Assert.areEqual(3, mockNotifierInvocationCount);
  }

  @IsTest
  static void it_should_swallow_exceptions_thrown_by_a_notifier_and_continue() {
    resetMockNotifier();
    mockNotifierShouldThrowNext = true;
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(MOCK_NOTIFIER_CLASS),
      buildDispatch(MOCK_NOTIFIER_CLASS)
    };
    LoggerNotificationAsyncDispatcher dispatcher = new LoggerNotificationAsyncDispatcher(dispatches);

    System.Test.startTest();
    dispatcher.execute(null);
    System.Test.stopTest();

    System.Assert.areEqual(2, mockNotifierInvocationCount, 'Subsequent dispatch should still fire after a prior one throws');
    System.Assert.areEqual(1, mockNotifierThrownCount, 'The first dispatch should have thrown');
  }

  @IsTest
  static void it_should_skip_dispatch_when_notifier_class_cannot_be_instantiated() {
    resetMockNotifier();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch('SomeApexClassThatDoesNotExist'),
      buildDispatch(MOCK_NOTIFIER_CLASS)
    };
    LoggerNotificationAsyncDispatcher dispatcher = new LoggerNotificationAsyncDispatcher(dispatches);

    System.Test.startTest();
    dispatcher.execute(null);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount, 'Valid dispatch should still fire even if an earlier one failed to instantiate');
  }

  @IsTest
  static void it_should_deliver_both_recipients_when_a_rule_mixes_dml_and_callout_notifiers() {
    // The historical bug: a rule with two recipients where one notifier performs DML (like
    // Messaging.CustomNotification.send, which Salesforce treats as DML against the pending
    // notification queue) alongside one that performs an HTTP callout (like SlackLoggerNotifier).
    // Under the old single-Queueable dispatcher, the callout ran in the same transaction as the DML
    // and threw `System.CalloutException: You have uncommitted work pending. Please commit or
    // rollback before calling out.` One of the two recipients silently ended up FAILED.
    //
    // The new dispatcher hands its input to LoggerNotifierDispatchPacker. `Operation.CALLOUT` and
    // `Operation.DML` in the same input split into two groups: CALLOUT runs first in the current
    // Queueable, the DML notifier waits for a chained Queueable that the Finalizer enqueues. Each
    // group starts with a clean transactional slate. Both deliveries reach `Delivered`.
    Log__c dmlSideEffectParent = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(dmlSideEffectParent);
    LogEntry__c matchingEntry = new LogEntry__c(
      Log__c = dmlSideEffectParent.Id,
      LoggingLevel__c = System.LoggingLevel.ERROR.name(),
      Timestamp__c = System.now()
    );
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(Name = 'Rule with DML + callout', SourceSObjectType__c = 'LogEntry__c');
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c calloutService = new LoggerNotificationService__c(
      Name = 'Callout service',
      NotifierApexClassName__c = CalloutPerformingNotifier.class.getName(),
      IsEnabled__c = true,
      WebhookUrl__c = 'https://example.com/webhook'
    );
    LoggerNotificationService__c dmlService = new LoggerNotificationService__c(
      Name = 'DML service',
      NotifierApexClassName__c = DmlPerformingNotifier.class.getName(),
      IsEnabled__c = true
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationService__c>{ calloutService, dmlService });
    LoggerNotificationRecipient__c calloutRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = calloutService.Id
    );
    LoggerNotificationRecipient__c dmlRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = dmlService.Id
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationRecipient__c>{ calloutRecipient, dmlRecipient });
    LoggerNotificationMatch__c match = new LoggerNotificationMatch__c(
      LoggerNotificationRule__c = rule.Id,
      LogEntry__c = matchingEntry.Id,
      MatchedRecordId__c = matchingEntry.Id,
      MatchedSObjectType__c = 'LogEntry__c'
    );
    LoggerDataStore.getDatabase().insertRecord(match);
    LoggerNotificationDelivery__c pendingCalloutDelivery = new LoggerNotificationDelivery__c(
      AttemptCount__c = 0,
      LoggerNotificationMatch__c = match.Id,
      LoggerNotificationRecipient__c = calloutRecipient.Id,
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = calloutService.Id,
      Status__c = LoggerNotifierResult.STATUS_PENDING
    );
    LoggerNotificationDelivery__c pendingDmlDelivery = new LoggerNotificationDelivery__c(
      AttemptCount__c = 0,
      LoggerNotificationMatch__c = match.Id,
      LoggerNotificationRecipient__c = dmlRecipient.Id,
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = dmlService.Id,
      Status__c = LoggerNotifierResult.STATUS_PENDING
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationDelivery__c>{ pendingCalloutDelivery, pendingDmlDelivery });

    // Under the new isolation model, `Operation.CALLOUT` + `Operation.DML` in the same input
    // packs into ONE group with a CALLOUT-first reorder. CALLOUT runs, callout completes, THEN
    // DML runs - which is legal in a single Salesforce transaction. So both notifiers can complete
    // successfully in a single group. This test drives that scenario and asserts both deliveries
    // reach `Delivered`.
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(DmlPerformingNotifier.class.getName(), new List<Id>{ pendingDmlDelivery.Id }),
      buildDispatch(CalloutPerformingNotifier.class.getName(), new List<Id>{ pendingCalloutDelivery.Id })
    };
    LoggerNotificationAsyncDispatcher dispatcher = new LoggerNotificationAsyncDispatcher(dispatches);

    System.Test.startTest();
    System.Test.setMock(System.HttpCalloutMock.class, LoggerMockDataCreator.createHttpCallout().setStatusCode(200));
    dispatcher.execute(null);
    LoggerNotificationAsyncDispatcher.Finalizer finalizer = new LoggerNotificationAsyncDispatcher.Finalizer(
      dispatcher.pendingDispatches,
      dispatcher.deliveriesToUpdate,
      dispatcher.deferredWork,
      dispatcher.remainingGroups
    );
    finalizer.finalizeCurrentGroup(System.ParentJobResult.SUCCESS);
    System.Test.stopTest();

    Map<Id, LoggerNotificationDelivery__c> deliveryById = new Map<Id, LoggerNotificationDelivery__c>(
      [
        SELECT ErrorMessage__c, Status__c
        FROM LoggerNotificationDelivery__c
        WHERE Id IN :new List<Id>{ pendingCalloutDelivery.Id, pendingDmlDelivery.Id }
        WITH SYSTEM_MODE
      ]
    );
    System.Assert.areEqual(
      LoggerNotifierResult.STATUS_DELIVERED,
      deliveryById.get(pendingCalloutDelivery.Id).Status__c,
      'CALLOUT recipient should have been delivered without hitting the uncommitted-work exception'
    );
    System.Assert.areEqual(
      LoggerNotifierResult.STATUS_DELIVERED,
      deliveryById.get(pendingDmlDelivery.Id).Status__c,
      'DML recipient should have been delivered in its own group without blocking the callout'
    );
  }

  @IsTest
  static void it_should_pack_incompatible_dispatches_into_multiple_groups_on_construction() {
    // Verifies the dispatcher hands its input to LoggerNotifierDispatchPacker. EMAIL-and-CALLOUT is
    // one of the combinations the packer must split - EMAIL after a callout in the same transaction
    // is conservatively unsafe. The dispatcher's first group runs CALLOUT (the packer reorders
    // callouts first inside a group); the follow-up group with EMAIL is queued in `remainingGroups`
    // for the Finalizer to enqueue as its own Queueable. DML-and-CALLOUT would NOT split - CALLOUT
    // then DML in one transaction is legal, which is why the packer reorders callouts first.
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(EmailDeclaringNotifier.class.getName()),
      buildDispatch(CalloutPerformingNotifier.class.getName())
    };

    LoggerNotificationAsyncDispatcher dispatcher = new LoggerNotificationAsyncDispatcher(dispatches);

    System.Assert.areEqual(1, dispatcher.pendingDispatches.size(), 'First group should contain exactly the CALLOUT notifier');
    System.Assert.areEqual(
      CalloutPerformingNotifier.class.getName(),
      dispatcher.pendingDispatches.get(0).recipient.LoggerNotificationService__r.NotifierApexClassName__c,
      'Packer should reorder the CALLOUT notifier to run first'
    );
    System.Assert.areEqual(1, dispatcher.remainingGroups.size(), 'EMAIL notifier belongs to a follow-up group');
    System.Assert.areEqual(
      EmailDeclaringNotifier.class.getName(),
      dispatcher.remainingGroups.get(0).get(0).recipient.LoggerNotificationService__r.NotifierApexClassName__c,
      'Follow-up group should contain the EMAIL notifier'
    );
  }

  @IsTest
  static void it_should_apply_delivery_updates_from_the_finalizer_not_from_execute() {
    // The Queueable now accumulates delivery-record updates on the instance but does NOT commit them
    // in execute - that DML moves to the Finalizer, which runs in a fresh transaction with a clean
    // callout budget. Verify: after execute (with a null QueueableContext so no Finalizer attaches),
    // the delivery record is UNCHANGED. Invoke the Finalizer's core method directly and the delivery
    // record then reflects the notifier's outcome.
    resetMockNotifier();
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(Name = 'Test rule', SourceSObjectType__c = 'LogEntry__c');
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = new LoggerNotificationService__c(
      Name = 'Mock service',
      NotifierApexClassName__c = MOCK_NOTIFIER_CLASS,
      IsEnabled__c = true
    );
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);
    LoggerNotificationMatch__c match = new LoggerNotificationMatch__c(
      LoggerNotificationRule__c = rule.Id,
      LogEntry__c = matchingEntry.Id,
      MatchedRecordId__c = matchingEntry.Id,
      MatchedSObjectType__c = 'LogEntry__c'
    );
    LoggerDataStore.getDatabase().insertRecord(match);
    LoggerNotificationDelivery__c pendingDelivery = new LoggerNotificationDelivery__c(
      AttemptCount__c = 0,
      LoggerNotificationMatch__c = match.Id,
      LoggerNotificationRecipient__c = recipient.Id,
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id,
      Status__c = LoggerNotifierResult.STATUS_PENDING
    );
    LoggerDataStore.getDatabase().insertRecord(pendingDelivery);
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(MOCK_NOTIFIER_CLASS, new List<Id>{ pendingDelivery.Id })
    };
    LoggerNotificationAsyncDispatcher dispatcher = new LoggerNotificationAsyncDispatcher(dispatches);
    dispatcher.execute(null);
    LoggerNotificationDelivery__c postExecute = [SELECT Status__c FROM LoggerNotificationDelivery__c WHERE Id = :pendingDelivery.Id WITH SYSTEM_MODE];
    System.Assert.areEqual(
      LoggerNotifierResult.STATUS_PENDING,
      postExecute.Status__c,
      'Queueable.execute should NOT commit delivery updates - the Finalizer owns that DML'
    );
    System.Assert.areEqual(1, dispatcher.deliveriesToUpdate.size(), 'Queueable accumulated the delivery record for the Finalizer to update');

    LoggerNotificationAsyncDispatcher.Finalizer finalizer = new LoggerNotificationAsyncDispatcher.Finalizer(
      dispatcher.pendingDispatches,
      dispatcher.deliveriesToUpdate,
      dispatcher.deferredWork,
      new List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>>()
    );
    finalizer.finalizeCurrentGroup(System.ParentJobResult.SUCCESS);

    LoggerNotificationDelivery__c postFinalizer = [SELECT Status__c FROM LoggerNotificationDelivery__c WHERE Id = :pendingDelivery.Id WITH SYSTEM_MODE];
    System.Assert.areEqual(LoggerNotifierResult.STATUS_DELIVERED, postFinalizer.Status__c, 'Finalizer should commit the accumulated delivery updates');
  }

  @IsTest
  static void it_should_mark_untouched_deliveries_as_failed_when_the_queueable_had_an_unhandled_exception() {
    // If the Queueable throws uncaught, its Finalizer still runs (with UNHANDLED_EXCEPTION). The
    // Finalizer walks the current-group dispatches, finds pending delivery Ids that never got
    // stamped with an outcome, and marks them as FAILED so admins see the failure on the delivery
    // row instead of a stuck-forever PENDING.
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(Name = 'Test rule', SourceSObjectType__c = 'LogEntry__c');
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = new LoggerNotificationService__c(
      Name = 'Mock service',
      NotifierApexClassName__c = MOCK_NOTIFIER_CLASS,
      IsEnabled__c = true
    );
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);
    LoggerNotificationMatch__c match = new LoggerNotificationMatch__c(
      LoggerNotificationRule__c = rule.Id,
      LogEntry__c = matchingEntry.Id,
      MatchedRecordId__c = matchingEntry.Id,
      MatchedSObjectType__c = 'LogEntry__c'
    );
    LoggerDataStore.getDatabase().insertRecord(match);
    LoggerNotificationDelivery__c untouchedDelivery = new LoggerNotificationDelivery__c(
      AttemptCount__c = 0,
      LoggerNotificationMatch__c = match.Id,
      LoggerNotificationRecipient__c = recipient.Id,
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id,
      Status__c = LoggerNotifierResult.STATUS_PENDING
    );
    LoggerDataStore.getDatabase().insertRecord(untouchedDelivery);
    LoggerNotificationAsyncDispatcher.PendingDispatch dispatch = buildDispatch(MOCK_NOTIFIER_CLASS, new List<Id>{ untouchedDelivery.Id });
    LoggerNotificationAsyncDispatcher.Finalizer finalizer = new LoggerNotificationAsyncDispatcher.Finalizer(
      new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{ dispatch },
      new List<LoggerNotificationDelivery__c>(),
      new LoggerNotificationAsyncDispatcher.DeferredWorkBuffer(),
      new List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>>()
    );

    finalizer.finalizeCurrentGroup(System.ParentJobResult.UNHANDLED_EXCEPTION);

    LoggerNotificationDelivery__c postFinalizer = [
      SELECT Status__c, ErrorMessage__c
      FROM LoggerNotificationDelivery__c
      WHERE Id = :untouchedDelivery.Id
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(LoggerNotifierResult.STATUS_FAILED, postFinalizer.Status__c, 'Untouched delivery should be marked FAILED so admins see the failure');
    System.Assert.isTrue(
      postFinalizer.ErrorMessage__c.containsIgnoreCase('unhandled exception'),
      'ErrorMessage__c should mention the unhandled exception: ' + postFinalizer.ErrorMessage__c
    );
  }

  @IsTest
  static void it_should_still_chain_next_group_after_a_queueable_unhandled_exception() {
    // Downstream notifiers should not be blocked by an upstream group's unhandled exception. The
    // Finalizer enqueues the next group regardless.
    LoggerNotificationAsyncDispatcher.PendingDispatch nextGroupDispatch = buildDispatch(MOCK_NOTIFIER_CLASS);
    LoggerNotificationAsyncDispatcher.Finalizer finalizer = new LoggerNotificationAsyncDispatcher.Finalizer(
      new List<LoggerNotificationAsyncDispatcher.PendingDispatch>(),
      new List<LoggerNotificationDelivery__c>(),
      new LoggerNotificationAsyncDispatcher.DeferredWorkBuffer(),
      new List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>>{ new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{ nextGroupDispatch } }
    );

    System.Test.startTest();
    finalizer.finalizeCurrentGroup(System.ParentJobResult.UNHANDLED_EXCEPTION);
    System.Assert.areEqual(1, System.Limits.getQueueableJobs(), 'Finalizer should have chained the next group');
    System.Test.stopTest();
  }

  @IsTest
  static void it_should_not_chain_when_there_are_no_remaining_groups() {
    LoggerNotificationAsyncDispatcher.Finalizer finalizer = new LoggerNotificationAsyncDispatcher.Finalizer(
      new List<LoggerNotificationAsyncDispatcher.PendingDispatch>(),
      new List<LoggerNotificationDelivery__c>(),
      new LoggerNotificationAsyncDispatcher.DeferredWorkBuffer(),
      new List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>>()
    );

    System.Test.startTest();
    finalizer.finalizeCurrentGroup(System.ParentJobResult.SUCCESS);
    System.Assert.areEqual(0, System.Limits.getQueueableJobs(), 'Finalizer should not enqueue anything when no groups remain');
    System.Test.stopTest();
  }

  @IsTest
  static void it_should_accumulate_deferred_work_from_every_notifier_in_the_group() {
    // Execute a Queueable whose notifier returns a LoggerNotifierResult carrying every deferred*
    // bucket populated. The dispatcher should accumulate all of them onto its DeferredWorkBuffer
    // instance for the Finalizer to flush later. This test asserts the accumulation step - the
    // subsequent tests exercise the individual flush behaviors.
    resetCapturingNotifier();
    capturedFollowUpQueueablesToReturn = new List<System.Queueable>{ new CapturingFollowUpQueueable() };
    deferredDmlInsertsToReturn = new List<SObject>{ new Log__c(TransactionId__c = 'deferred-insert') };
    deferredDmlUpdatesToReturn = new List<SObject>{
      new Log__c(Id = LoggerMockDataCreator.createId(Schema.Log__c.SObjectType), TransactionId__c = 'deferred-update')
    };
    deferredDmlDeletesToReturn = new List<SObject>{ new Log__c(Id = LoggerMockDataCreator.createId(Schema.Log__c.SObjectType)) };
    deferredEmailsToReturn = new List<Messaging.SingleEmailMessage>{ new Messaging.SingleEmailMessage() };
    LoggerNotificationAsyncDispatcher dispatcher = new LoggerNotificationAsyncDispatcher(
      new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{ buildDispatch(CapturingNotifier.class.getName()) }
    );

    dispatcher.execute(null);

    System.Assert.areEqual(1, dispatcher.deferredWork.dmlInserts.size(), 'Deferred DML inserts should be accumulated onto the buffer');
    System.Assert.areEqual(1, dispatcher.deferredWork.dmlUpdates.size(), 'Deferred DML updates should be accumulated onto the buffer');
    System.Assert.areEqual(1, dispatcher.deferredWork.dmlDeletes.size(), 'Deferred DML deletes should be accumulated onto the buffer');
    System.Assert.areEqual(1, dispatcher.deferredWork.emails.size(), 'Deferred emails should be accumulated onto the buffer');
    System.Assert.areEqual(1, dispatcher.deferredWork.followUpQueueables.size(), 'Follow-up queueables should be accumulated onto the buffer');
  }

  @IsTest
  static void it_should_run_deferred_dml_inserts_and_updates_from_the_finalizer() {
    // The Finalizer's flushDmlAndFollowUpQueueables step should execute inserts / updates / deletes
    // the notifier queued on its LoggerNotifierResult. Uses real Log__c records so the persistence
    // side of the DML is observable via a follow-up SOQL query.
    Log__c targetForUpdate = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    targetForUpdate.TransactionId__c = 'original-value';
    LoggerDataStore.getDatabase().insertRecord(targetForUpdate);
    LoggerNotificationAsyncDispatcher.DeferredWorkBuffer buffer = new LoggerNotificationAsyncDispatcher.DeferredWorkBuffer();
    LoggerNotifierResult result = new LoggerNotifierResult();
    Log__c toInsert = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    toInsert.TransactionId__c = 'from-deferred-insert';
    Log__c toUpdate = new Log__c(Id = targetForUpdate.Id, TransactionId__c = 'from-deferred-update');
    result.deferredDmlInserts = new List<SObject>{ toInsert };
    result.deferredDmlUpdates = new List<SObject>{ toUpdate };
    buffer.accumulate(result);
    LoggerNotificationAsyncDispatcher.Finalizer finalizer = new LoggerNotificationAsyncDispatcher.Finalizer(
      new List<LoggerNotificationAsyncDispatcher.PendingDispatch>(),
      new List<LoggerNotificationDelivery__c>(),
      buffer,
      new List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>>()
    );

    finalizer.finalizeCurrentGroup(System.ParentJobResult.SUCCESS);

    List<Log__c> insertedLogs = [SELECT Id, TransactionId__c FROM Log__c WHERE TransactionId__c = 'from-deferred-insert' WITH SYSTEM_MODE];
    System.Assert.areEqual(1, insertedLogs.size(), 'Deferred insert should have persisted a new Log__c record');
    Log__c reloadedForUpdate = [SELECT TransactionId__c FROM Log__c WHERE Id = :targetForUpdate.Id WITH SYSTEM_MODE];
    System.Assert.areEqual('from-deferred-update', reloadedForUpdate.TransactionId__c, 'Deferred update should have mutated the existing Log__c record');
  }

  @IsTest
  static void it_should_run_deferred_dml_deletes_from_the_finalizer() {
    Log__c toDelete = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(toDelete);
    LoggerNotificationAsyncDispatcher.DeferredWorkBuffer buffer = new LoggerNotificationAsyncDispatcher.DeferredWorkBuffer();
    LoggerNotifierResult result = new LoggerNotifierResult();
    result.deferredDmlDeletes = new List<SObject>{ new Log__c(Id = toDelete.Id) };
    buffer.accumulate(result);
    LoggerNotificationAsyncDispatcher.Finalizer finalizer = new LoggerNotificationAsyncDispatcher.Finalizer(
      new List<LoggerNotificationAsyncDispatcher.PendingDispatch>(),
      new List<LoggerNotificationDelivery__c>(),
      buffer,
      new List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>>()
    );

    finalizer.finalizeCurrentGroup(System.ParentJobResult.SUCCESS);

    List<Log__c> remaining = [SELECT Id FROM Log__c WHERE Id = :toDelete.Id WITH SYSTEM_MODE];
    System.Assert.areEqual(0, remaining.size(), 'Deferred delete should have removed the target Log__c record');
  }

  @IsTest
  static void it_should_send_deferred_callouts_from_the_finalizer_before_any_dml() {
    // The Finalizer runs deferred callouts BEFORE any DML sets the uncommitted-work flag in its
    // transaction. This test wires a deferred callout onto the buffer + a mock HTTP handler, and
    // asserts the mock recorded the request. The test also queues deferred DML - the callout MUST
    // succeed even though DML is queued in the same Finalizer transaction.
    Log__c parent = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(parent);
    LoggerNotificationAsyncDispatcher.DeferredWorkBuffer buffer = new LoggerNotificationAsyncDispatcher.DeferredWorkBuffer();
    LoggerNotifierResult result = new LoggerNotifierResult();
    System.HttpRequest deferredRequest = new System.HttpRequest();
    deferredRequest.setEndpoint('https://example.com/deferred-callout');
    deferredRequest.setMethod('POST');
    deferredRequest.setBody('{}');
    result.deferredCallouts = new List<System.HttpRequest>{ deferredRequest };
    Log__c toInsert = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    result.deferredDmlInserts = new List<SObject>{ toInsert };
    buffer.accumulate(result);
    LoggerNotificationAsyncDispatcher.Finalizer finalizer = new LoggerNotificationAsyncDispatcher.Finalizer(
      new List<LoggerNotificationAsyncDispatcher.PendingDispatch>(),
      new List<LoggerNotificationDelivery__c>(),
      buffer,
      new List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>>()
    );
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);

    System.Test.startTest();
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    finalizer.finalizeCurrentGroup(System.ParentJobResult.SUCCESS);
    System.Test.stopTest();

    System.Assert.isNotNull(calloutMock.request, 'Deferred callout should have been sent by the Finalizer');
    System.Assert.areEqual(
      'https://example.com/deferred-callout',
      calloutMock.request.getEndpoint(),
      'The captured request should match the deferred callout the notifier queued'
    );
  }

  @IsTest
  static void it_should_call_messaging_sendEmail_for_deferred_emails_without_throwing() {
    // Messaging.sendEmail is a no-op in test context, so there's nothing to inspect on the
    // send-side. But the buffer's flushCalloutsAndEmails path must at least accept the list without
    // throwing - if it did, the whole Finalizer would abort mid-flight and the delivery-record
    // update DML that follows it would never run. Direct-invoke the flush to exercise the code path.
    LoggerNotificationAsyncDispatcher.DeferredWorkBuffer buffer = new LoggerNotificationAsyncDispatcher.DeferredWorkBuffer();
    LoggerNotifierResult result = new LoggerNotifierResult();
    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    email.setToAddresses(new List<String>{ 'someone@example.com' });
    email.setSubject('Deferred email');
    email.setPlainTextBody('body');
    result.deferredEmails = new List<Messaging.SingleEmailMessage>{ email };
    buffer.accumulate(result);

    buffer.flushCalloutsAndEmails();

    System.Assert.areEqual(1, buffer.emails.size(), 'Buffer should retain the email list post-flush (no reset semantics)');
  }

  @IsTest
  static void it_should_enqueue_follow_up_queueables_from_the_finalizer() {
    LoggerNotificationAsyncDispatcher.DeferredWorkBuffer buffer = new LoggerNotificationAsyncDispatcher.DeferredWorkBuffer();
    LoggerNotifierResult result = new LoggerNotifierResult();
    result.followUpQueueables = new List<System.Queueable>{ new CapturingFollowUpQueueable() };
    buffer.accumulate(result);
    LoggerNotificationAsyncDispatcher.Finalizer finalizer = new LoggerNotificationAsyncDispatcher.Finalizer(
      new List<LoggerNotificationAsyncDispatcher.PendingDispatch>(),
      new List<LoggerNotificationDelivery__c>(),
      buffer,
      new List<List<LoggerNotificationAsyncDispatcher.PendingDispatch>>()
    );

    System.Test.startTest();
    finalizer.finalizeCurrentGroup(System.ParentJobResult.SUCCESS);
    System.Assert.areEqual(1, System.Limits.getQueueableJobs(), 'Follow-up queueable should have been enqueued by the Finalizer');
    System.Test.stopTest();
  }

  @IsTest
  static void it_should_expose_pending_dispatches_via_the_testVisible_field() {
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(MOCK_NOTIFIER_CLASS)
    };

    LoggerNotificationAsyncDispatcher dispatcher = new LoggerNotificationAsyncDispatcher(dispatches);

    System.Assert.areEqual(1, dispatcher.pendingDispatches.size());
  }

  private static LoggerNotificationAsyncDispatcher.PendingDispatch buildDispatch(String apexClassName) {
    return buildDispatch(apexClassName, null);
  }

  private static LoggerNotificationAsyncDispatcher.PendingDispatch buildDispatch(String apexClassName, List<Id> pendingDeliveryIds) {
    LoggerNotificationService__c service = new LoggerNotificationService__c(
      Name = 'Mock service',
      NotifierApexClassName__c = apexClassName,
      IsEnabled__c = true,
      OriginOrganizationId__c = System.UserInfo.getOrganizationId(),
      WebhookUrl__c = 'https://example.com/webhook'
    );
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(Name = 'Test rule', SourceSObjectType__c = 'LogEntry__c');
    // PendingDispatch snapshots rule + service from the recipient's parent relationships at construction
    // time, so both __r lookups have to be populated on the recipient. In-memory SObject relationships
    // aren't directly assignable in Apex; round-trip through JSON to attach them.
    LoggerNotificationRecipient__c recipient = (LoggerNotificationRecipient__c) System.JSON.deserialize(
      System.JSON.serialize(
        new Map<String, Object>{
          'attributes' => new Map<String, String>{ 'type' => 'LoggerNotificationRecipient__c' },
          'LoggerNotificationRule__r' => rule,
          'LoggerNotificationService__r' => service
        }
      ),
      LoggerNotificationRecipient__c.class
    );
    LoggerNotificationAsyncDispatcher.PendingDispatch dispatch = new LoggerNotificationAsyncDispatcher.PendingDispatch(
      recipient,
      new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name()) },
      null
    );
    dispatch.pendingDeliveryIds = pendingDeliveryIds;
    return dispatch;
  }

  public class MockNotifier extends LoggerNotifier {
    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      mockNotifierInvocationCount++;
      if (mockNotifierShouldThrowNext) {
        mockNotifierShouldThrowNext = false;
        mockNotifierThrownCount++;
        throw new System.CalloutException('Simulated notifier failure');
      }
      return null;
    }
  }

  /**
   * @description Stand-in for a notifier that performs an HTTP callout - modeled on `SlackLoggerNotifier`.
   *              Uses a hard-coded endpoint and lets the surrounding test install the HttpCalloutMock via
   *              `System.Test.setMock`. In a well-ordered dispatcher run this returns cleanly; when the run
   *              is preceded by a DML-performing notifier, `System.Http.send` throws CalloutException with
   *              the `uncommitted work` message, which the async dispatcher catches and finalizes as FAILED.
   */
  public class CalloutPerformingNotifier extends LoggerNotifier {
    public override Set<LoggerNotifier.Operation> getSupportedOperations() {
      return new Set<LoggerNotifier.Operation>{ LoggerNotifier.Operation.CALLOUT };
    }

    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      System.HttpRequest httpRequest = new System.HttpRequest();
      httpRequest.setEndpoint('https://example.com/webhook');
      httpRequest.setMethod('POST');
      httpRequest.setBody('{}');
      new System.Http().send(httpRequest);
      return new LoggerNotifierResult(LoggerNotifierResult.STATUS_DELIVERED, null);
    }
  }

  /**
   * @description Stand-in for a notifier that performs DML - modeled on `CustomNotificationLoggerNotifier`,
   *              whose `Messaging.CustomNotification.send(...)` call is treated by the platform as DML
   *              against the pending-notification queue. Inserts a real record so `System.Limits.getDMLStatements()`
   *              actually increments and the transaction is flagged as having uncommitted work; a follow-up
   *              callout in the same transaction then throws the uncommitted-work CalloutException.
   */
  public class DmlPerformingNotifier extends LoggerNotifier {
    public override Set<LoggerNotifier.Operation> getSupportedOperations() {
      return new Set<LoggerNotifier.Operation>{ LoggerNotifier.Operation.DML };
    }

    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      Log__c dmlSideEffect = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
      LoggerDataStore.getDatabase().insertRecord(dmlSideEffect);
      return new LoggerNotifierResult(LoggerNotifierResult.STATUS_DELIVERED, null);
    }
  }

  /**
   * @description Stand-in for a notifier that sends email. Declares only EMAIL as a supported
   *              operation so the packer treats it as isolation-worthy from CALLOUT / DML. The
   *              notifier itself does nothing at runtime - the tests only care about the packer's
   *              grouping behavior.
   */
  public class EmailDeclaringNotifier extends LoggerNotifier {
    public override Set<LoggerNotifier.Operation> getSupportedOperations() {
      return new Set<LoggerNotifier.Operation>{ LoggerNotifier.Operation.EMAIL };
    }

    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      return new LoggerNotifierResult(LoggerNotifierResult.STATUS_DELIVERED, null);
    }
  }

  /**
   * @description Notifier that returns a LoggerNotifierResult populated with whichever `deferred*`
   *              buckets the surrounding test set on the enclosing class's static fields. Lets the
   *              slice-5 tests assert the dispatcher accumulates every bucket without hard-wiring
   *              the notifier's return value to a single shape.
   */
  public class CapturingNotifier extends LoggerNotifier {
    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      LoggerNotifierResult result = new LoggerNotifierResult(LoggerNotifierResult.STATUS_DELIVERED, null);
      result.deferredDmlInserts = deferredDmlInsertsToReturn;
      result.deferredDmlUpdates = deferredDmlUpdatesToReturn;
      result.deferredDmlDeletes = deferredDmlDeletesToReturn;
      result.deferredEmails = deferredEmailsToReturn;
      result.followUpQueueables = capturedFollowUpQueueablesToReturn;
      return result;
    }
  }

  /**
   * @description No-op queueable that lets the slice-5 tests assert follow-up queueables get
   *              enqueued without running actual work when the dispatcher chains them.
   */
  public class CapturingFollowUpQueueable implements System.Queueable {
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void execute(System.QueueableContext context) {
    }
  }
}
