//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount, PMD.MethodNamingConventions, PMD.NcssCount, PMD.NcssMethodCount')
@IsTest(IsParallel=false)
private class LoggerNotificationProcessor_Tests {
  private static final String LOG_ENTRY_SAMPLE_FILTER = 'ISPICKVAL(LoggingLevel__c, \'ERROR\')';
  private static final String LOG_SAMPLE_FILTER = 'TransactionId__c != null';
  private static final String MOCK_NOTIFIER_CLASS = MockNotifier.class.getName();

  private static Integer mockNotifierInvocationCount = 0;
  private static Integer mockNotifierThrownCount = 0;
  private static LoggerNotifierRequest mockNotifierLastRequest;
  private static Boolean mockNotifierShouldThrowNext = false;

  static {
    LoggerConfigurationSelector.useMocks();
    // TODO add mock CMDT records for notification plugin??
  }

  @IsTest
  static void it_should_short_circuit_when_records_are_null_or_empty() {
    System.Assert.areEqual(0, mockNotifierThrownCount, 'Test has started under the wrong conditions');
    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerNotificationRule__c WITH SYSTEM_MODE], 'Test has started under the wrong conditions');

    System.Test.startTest();
    LoggerNotificationProcessor processor = new LoggerNotificationProcessor();
    processor.sendNotifications(Schema.LogEntry__c.SObjectType, null);
    processor.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>());
    processor.sendNotifications(null, new List<SObject>{ new LogEntry__c() });
    System.Assert.areEqual(0, System.Limits.getQueueableJobs(), 'One async dispatcher job should have been enqueued');
    System.Assert.areEqual(0, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName() WITH SYSTEM_MODE]);
    System.Test.stopTest();

    System.Assert.areEqual(0, mockNotifierInvocationCount);
    System.Assert.areEqual(0, mockNotifierThrownCount);
    System.Assert.areEqual(0, System.Limits.getQueueableJobs(), 'One async dispatcher job should have been enqueued');
    System.Assert.areEqual(0, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName() WITH SYSTEM_MODE]);
  }

  @IsTest
  static void it_should_reuse_queried_rules_after_one_query() {
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerDataStore.getDatabase()
      .insertRecord(new LoggerNotificationRecipient__c(LoggerNotificationRule__c = rule.Id, LoggerNotificationService__c = service.Id));
    Integer queryCountBefore = System.Limits.getQueries();

    for (Integer i = 0; i < 5; i++) {
      new LoggerNotificationProcessor()
        .sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name()) });
    }

    System.Assert.areEqual(queryCountBefore + 1, System.Limits.getQueries(), 'Queried rules should have cached the rules with 1 SOQL query');
  }

  @IsTest
  static void it_should_ignore_rules_for_a_different_source_sobject_type() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    log.TransactionId__c = 'some value';
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.Log__c.SObjectType, LOG_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });
    System.Test.stopTest();

    System.Assert.areEqual(0, mockNotifierInvocationCount, 'Rules for a different sobject type should be ignored');
  }

  @IsTest
  static void it_should_dispatch_only_to_enabled_recipients_whose_service_is_enabled_and_valid() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c enabledService = buildService(MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c disabledService = buildService(MOCK_NOTIFIER_CLASS);
    disabledService.IsEnabled__c = false;
    LoggerNotificationService__c invalidOriginService = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationService__c>{ enabledService, disabledService, invalidOriginService });
    // The handler overwrites OriginOrganizationId__c on insert - flip it to a foreign org via a follow-up
    // update with the handler suppressed so IsOriginOrganizationIdValid__c evaluates to FALSE.
    LoggerSObjectHandler.shouldExecute(false);
    invalidOriginService.OriginOrganizationId__c = LoggerMockDataCreator.createId(Schema.Organization.SObjectType);
    LoggerDataStore.getDatabase().updateRecord(invalidOriginService);
    LoggerSObjectHandler.shouldExecute(true);
    LoggerNotificationRecipient__c validRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = enabledService.Id,
      IsEnabled__c = true
    );
    LoggerDataStore.getDatabase()
      .insertRecords(
        new List<LoggerNotificationRecipient__c>{
          validRecipient,
          new LoggerNotificationRecipient__c(LoggerNotificationRule__c = rule.Id, LoggerNotificationService__c = enabledService.Id, IsEnabled__c = false),
          new LoggerNotificationRecipient__c(LoggerNotificationRule__c = rule.Id, LoggerNotificationService__c = disabledService.Id, IsEnabled__c = true),
          new LoggerNotificationRecipient__c(LoggerNotificationRule__c = rule.Id, LoggerNotificationService__c = invalidOriginService.Id, IsEnabled__c = true)
        }
      );

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });
    System.Test.stopTest();

    System.Assert.areEqual(
      1,
      mockNotifierInvocationCount,
      'Only the enabled recipient pointing at the enabled + valid-origin service should receive the notification'
    );
    List<LoggerNotificationMatch__c> matches = [
      SELECT Id, LogEntry__c, MatchedRecordId__c
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :rule.Id
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(1, matches.size(), 'Only 1 notification match should have been created');
    System.Assert.areEqual(logEntry.Id, matches.get(0).LogEntry__c);
    System.Assert.areEqual(logEntry.Id, matches.get(0).MatchedRecordId__c);
    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT Id, LoggerNotificationRecipient__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationMatch__c = :matches.get(0).Id
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(1, deliveries.size(), 'Only 1 notification delivery should have been created');
    System.Assert.areEqual(validRecipient.Id, deliveries.get(0).LoggerNotificationRecipient__c);
  }

  @IsTest
  static void it_should_pass_only_matching_records_to_the_notifier() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c firstMatchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c secondMatchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.INFO.name(), Timestamp__c = System.now());
    List<LogEntry__c> logEntries = new List<SObject>{ firstMatchingLogEntry, secondMatchingLogEntry, nonMatchingLogEntry };
    LoggerDataStore.getDatabase().insertRecords(logEntries);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, logEntries);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount);
    System.Assert.areEqual(2, mockNotifierLastRequest.matchingRecords.size());
    for (SObject match : mockNotifierLastRequest.matchingRecords) {
      System.Assert.areEqual(System.LoggingLevel.ERROR.name(), ((LogEntry__c) match).LoggingLevel__c);
    }
  }

  @IsTest
  static void it_should_not_invoke_notifier_when_no_records_match() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.INFO.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(nonMatchingLogEntry);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ nonMatchingLogEntry });

    System.Assert.areEqual(0, mockNotifierInvocationCount);
  }

  @IsTest
  static void it_should_swallow_exceptions_thrown_by_a_notifier() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c firstService = buildService(MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c secondService = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecords(new List<SObject>{ firstService, secondService });
    LoggerNotificationRecipient__c firstRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = firstService.Id
    );
    LoggerNotificationRecipient__c secondRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = secondService.Id
    );
    LoggerDataStore.getDatabase().insertRecords(new List<SObject>{ firstRecipient, secondRecipient });
    mockNotifierShouldThrowNext = true;

    System.Test.startTest();
    new LoggerNotificationProcessor()
      .sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name()) });
    System.Test.stopTest();

    System.Assert.areEqual(2, mockNotifierInvocationCount, 'Both recipients should have been invoked, including the one after the throw');
    System.Assert.areEqual(1, mockNotifierThrownCount, 'The first recipient should have thrown');
  }

  @IsTest
  static void it_should_skip_recipient_when_notifier_class_cannot_be_instantiated() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c serviceWithBadClass = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(serviceWithBadClass);
    // The handler validates that NotifierApexClass__c is a valid instance of LoggerNotifier - flip it to a bad value via a follow-up
    // update with the handler suppressed so the nonexistent class name can be saved.
    LoggerSObjectHandler.shouldExecute(false);
    serviceWithBadClass.NotifierApexClassName__c = 'FakeApexClassThatDoesNotExist';
    LoggerDataStore.getDatabase().updateRecord(serviceWithBadClass);
    LoggerSObjectHandler.shouldExecute(true);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = serviceWithBadClass.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });
    System.Test.stopTest();

    System.Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM LoggerNotificationMatch__c
        WHERE LoggerNotificationRule__c = :rule.Id
        WITH SYSTEM_MODE
      ]
    );
    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT ErrorMessage__c, Status__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationRecipient__r.LoggerNotificationService__c = :serviceWithBadClass.Id
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(1, deliveries.size());
    System.Assert.areEqual('Could not instantiate notifier class ' + serviceWithBadClass.NotifierApexClassName__c, deliveries.get(0).ErrorMessage__c);
    System.Assert.areEqual(LoggerNotifierResult.STATUS_SKIPPED, deliveries.get(0).Status__c);
  }

  @IsTest
  static void it_should_persist_matching_log_entries_for_logEntry_source_rules() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c nonMatchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.INFO.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ matchingEntry, nonMatchingEntry });
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry, nonMatchingEntry });
    System.Test.stopTest();

    List<LoggerNotificationMatch__c> matches = [
      SELECT Id, LogEntry__c, LoggerNotificationRule__c, MatchedRecordId__c, MatchedSObjectType__c
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :rule.Id
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(1, matches.size(), 'Only the ERROR entry should be recorded as a match');
    System.Assert.areEqual(matchingEntry.Id, matches.get(0).LogEntry__c);
    System.Assert.areEqual(matchingEntry.Id, matches.get(0).MatchedRecordId__c);
    System.Assert.areEqual('LogEntry__c', matches.get(0).MatchedSObjectType__c);
    System.Assert.areEqual(1, mockNotifierInvocationCount);
    System.Assert.areEqual(0, mockNotifierThrownCount);
    System.Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM LoggerNotificationDelivery__c
        WHERE LoggerNotificationRecipient__r.LoggerNotificationService__c = :service.Id
        WITH SYSTEM_MODE
      ]
    );
  }

  // @IsTest
  // static void it_should_suppress_dispatch_when_match_threshold_not_reached() {
  //   /* 🪵 Logging data setup */
  //   Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
  //   LoggerDataStore.getDatabase().insertRecord(log);
  //   LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
  //   LoggerDataStore.getDatabase().insertRecord(logEntry);
  //   /* 🔔 Notification data setup */
  //   LoggerNotificationRule__c rule = buildRule(
  //     'LogEntry__c',
  //     LOG_ENTRY_SAMPLE_FILTER
  //   );
  //   rule.IsMatchThresholdEnabled__c = true;
  //   rule.MatchCountThreshold__c = 5;
  //   rule.MatchThresholdTimePeriodIncrement__c = 60;
  //   rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
  //   LoggerDataStore.getDatabase().insertRecord(rule);
  //   LoggerNotificationService__c service = buildService( MOCK_NOTIFIER_CLASS);
  //   LoggerDataStore.getDatabase().insertRecord(service);
  //   LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
  //     LoggerNotificationRule__c = rule.Id,
  //     LoggerNotificationService__c = service.Id
  //   );
  //   LoggerDataStore.getDatabase().insertRecord(recipient);

  //   System.Test.startTest();
  //   new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });
  //   System.Test.stopTest();

  //   System.Assert.areEqual(0, mockNotifierInvocationCount, 'Threshold of 5 with only 1 match should suppress dispatch');
  //   // TODO confirm if LoggerNotificationMatch__c should be created even when match threshold isn't met
  //   System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = rule.Id WITH SYSTEM_MODE]);
  //   List<LoggerNotificationDelivery__c> deliveries = [SELECT COUNT() FROM LoggerNotificationDelivery__c WHERE LoggerNotificationRecipient__c = ;recipient.Id  WITH SYSTEM_MODE];
  //   System.Assert.areEqual(
  //     1,
  //     deliveries.size()
  //   );
  //   System.Assert.areEqual(0, deliveries.get(0).AttemptCount__c);
  //   System.Assert.areEqual(LoggerNotifierResult.STATUS_SUPPRESSED_BY_THRESHOLD, deliveries.get(0).Status__c);
  // }

  @IsTest
  static void it_should_record_suppressed_by_match_threshold_delivery_rows_when_match_threshold_not_reached() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c firstEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c secondEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ firstEntry, secondEntry });
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 10;
    rule.MatchThresholdTimePeriodIncrement__c = 60;
    rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ firstEntry, secondEntry });
    System.Test.stopTest();

    System.Assert.areEqual(0, mockNotifierInvocationCount, 'Threshold of 10 with 2 matches should suppress dispatch');
    List<LoggerNotificationMatch__c> matches = [SELECT Id FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id WITH SYSTEM_MODE];
    System.Assert.areEqual(2, matches.size(), 'Both matches should still be recorded for threshold accounting');
    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT
        Id,
        Status__c,
        LoggerNotificationRecipient__c,
        LoggerNotificationService__c,
        LoggerNotificationMatch__c,
        AttemptCount__c,
        DispatchTimestamp__c,
        CompletedTimestamp__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationMatch__c IN :matches
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(2, deliveries.size(), 'A suppressed-by-threshold delivery record should still be recorded per (match, recipient) tuple');
    for (LoggerNotificationDelivery__c delivery : deliveries) {
      System.Assert.areEqual(
        LoggerNotifierResult.STATUS_SUPPRESSED_BY_THRESHOLD,
        delivery.Status__c,
        'Suppressed deliveries should carry the SUPPRESSED_BY_THRESHOLD status'
      );
      System.Assert.areEqual(recipient.Id, delivery.LoggerNotificationRecipient__c, 'Delivery should point at the recipient it would have gone to');
      System.Assert.areEqual(service.Id, delivery.LoggerNotificationService__c, 'Delivery should denormalize the recipient service Id');
      System.Assert.areEqual(0, delivery.AttemptCount__c, 'Suppressed deliveries should not count as an attempt');
      System.Assert.isNull(delivery.DispatchTimestamp__c, 'Suppressed deliveries should not carry a dispatch timestamp');
      System.Assert.isNull(delivery.CompletedTimestamp__c, 'Suppressed deliveries should not carry a completed timestamp');
    }
  }

  @IsTest
  static void it_should_only_record_suppressed_deliveries_for_valid_recipients() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 10;
    rule.MatchThresholdTimePeriodIncrement__c = 60;
    rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c enabledService = buildService(MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c disabledService = buildService(MOCK_NOTIFIER_CLASS);
    disabledService.IsEnabled__c = false;
    LoggerNotificationService__c invalidOriginService = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationService__c>{ enabledService, disabledService, invalidOriginService });
    // The handler overwrites OriginOrganizationId__c on insert - flip it to a foreign org via a follow-up
    // update with the handler suppressed so IsOriginOrganizationIdValid__c evaluates to FALSE.
    LoggerSObjectHandler.shouldExecute(false);
    invalidOriginService.OriginOrganizationId__c = LoggerMockDataCreator.createId(Schema.Organization.SObjectType);
    LoggerDataStore.getDatabase().updateRecord(invalidOriginService);
    LoggerSObjectHandler.shouldExecute(true);
    LoggerNotificationRecipient__c enabledRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = enabledService.Id
    );
    LoggerDataStore.getDatabase()
      .insertRecords(
        new List<LoggerNotificationRecipient__c>{
          enabledRecipient,
          new LoggerNotificationRecipient__c(LoggerNotificationRule__c = rule.Id, LoggerNotificationService__c = disabledService.Id),
          new LoggerNotificationRecipient__c(LoggerNotificationRule__c = rule.Id, LoggerNotificationService__c = invalidOriginService.Id)
        }
      );

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });
    System.Test.stopTest();

    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT Id, Status__c, LoggerNotificationRecipient__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationMatch__r.LoggerNotificationRule__c = :rule.Id
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(1, deliveries.size(), 'Only the enabled + valid-origin recipient should get a suppressed delivery record');
    System.Assert.areEqual(enabledRecipient.Id, deliveries.get(0).LoggerNotificationRecipient__c);
    System.Assert.areEqual(LoggerNotifierResult.STATUS_SUPPRESSED_BY_THRESHOLD, deliveries.get(0).Status__c);
  }

  // @IsTest
  // static void it_should_not_record_suppressed_deliveries_when_match_history_is_disabled() {
  //   /* 🪵 Logging data setup */
  //   Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
  //   LoggerDataStore.getDatabase().insertRecord(log);
  //   LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
  //   LoggerDataStore.getDatabase().insertRecord(logEntry);
  //   /* 🔔 Notification data setup */
  //   LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
  //   rule.IsMatchHistoryEnabled__c = false;
  //   rule.IsMatchThresholdEnabled__c = true;
  //   rule.MatchCountThreshold__c = 5;
  //   rule.MatchThresholdTimePeriodIncrement__c = 60;
  //   rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
  //   LoggerDataStore.getDatabase().insertRecord(rule);
  //   LoggerNotificationService__c service = buildService( MOCK_NOTIFIER_CLASS);
  //   LoggerDataStore.getDatabase().insertRecord(service);
  //   LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
  //     LoggerNotificationRule__c = rule.Id,
  //     LoggerNotificationService__c = service.Id
  //   );
  //   LoggerDataStore.getDatabase().insertRecord(recipient);

  //   System.Test.startTest();
  //   new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });
  //   System.Test.stopTest();

  //   Integer matchCount = [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id  WITH SYSTEM_MODE];
  //   System.Assert.areEqual(0, matchCount, 'Match records should not be persisted when IsMatchHistoryEnabled__c is false');
  //   Integer deliveryCount = [SELECT COUNT() FROM LoggerNotificationDelivery__c WHERE LoggerNotificationRecipient__c = :recipient.Id  WITH SYSTEM_MODE];
  //   System.Assert.areEqual(
  //     0,
  //     deliveryCount,
  //     'Suppressed delivery records require match records to reference, so they must not be recorded when match history is disabled'
  //   );
  // }

  @IsTest
  static void it_should_not_record_suppressed_deliveries_when_delivery_history_is_disabled() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.IsMatchHistoryEnabled__c = true;
    rule.IsDeliveryHistoryEnabled__c = false;
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 5;
    rule.MatchThresholdTimePeriodIncrement__c = 60;
    rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });
    System.Test.stopTest();

    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM LoggerNotificationDelivery__c WHERE LoggerNotificationMatch__r.LoggerNotificationRule__c = :rule.Id WITH SYSTEM_MODE],
      'Delivery records should not be recorded when IsDeliveryHistoryEnabled__c is false, even for suppressed-by-threshold outcomes'
    );
  }

  @IsTest
  static void it_should_route_every_recipient_through_the_async_dispatcher() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingLogEntry);
    /* 🔔 Notification data setup */
    // Every notification goes through LoggerNotificationAsyncDispatcher - no notifier fires
    // synchronously inside the source trigger. This isolates notifier failures + callouts from
    // the record insert transaction and gives each notification its own governor budget.
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    // Since this test is trying to validate what happens sync vs async, there are intentionally
    // asserts inside (and outside) of System.Test.startTest() & System.Test.stopTest()
    System.Test.startTest();
    System.Assert.areEqual(0, System.Limits.getQueueableJobs(), 'One async dispatcher job should have been enqueued');
    System.Assert.areEqual(0, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName() WITH SYSTEM_MODE]);
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingLogEntry });
    System.Assert.areEqual(0, mockNotifierInvocationCount, 'Notifier should not fire synchronously - it should be queued');
    System.Assert.areEqual(1, System.Limits.getQueueableJobs(), 'One async dispatcher job should have been enqueued');
    System.Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName() WITH SYSTEM_MODE]);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount, 'Notifier should have fired synchronously');
    System.Assert.areEqual(0, System.Limits.getQueueableJobs(), 'No async dispatcher job should have been enqueued after System.Test.stopTest()');
    System.Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName() WITH SYSTEM_MODE]);
  }

  @IsTest
  static void it_should_batch_multiple_recipients_into_a_single_queueable() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ logEntry });
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c serviceA = buildService(MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c serviceB = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecords(new List<SObject>{ serviceA, serviceB });
    LoggerNotificationRecipient__c recipientA = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = serviceA.Id
    );
    LoggerNotificationRecipient__c recipientB = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = serviceB.Id
    );
    LoggerDataStore.getDatabase().insertRecords(new List<SObject>{ recipientA, recipientB });

    // Since this test is trying to validate what happens sync vs async, there are intentionally
    // asserts inside (and outside) of System.Test.startTest() & System.Test.stopTest()
    System.Test.startTest();
    System.Assert.areEqual(0, System.Limits.getQueueableJobs(), 'One async dispatcher job should have been enqueued');
    System.Assert.areEqual(0, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName() WITH SYSTEM_MODE]);
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });
    System.Assert.areEqual(0, mockNotifierInvocationCount, 'Notifier should not fire synchronously - it should be queued');
    System.Assert.areEqual(1, System.Limits.getQueueableJobs(), 'One async dispatcher job should have been enqueued');
    System.Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName() WITH SYSTEM_MODE]);
    System.Test.stopTest();

    System.Assert.areEqual(2, mockNotifierInvocationCount, 'Notifiers should have fired for 2 recipients');
    System.Assert.areEqual(0, System.Limits.getQueueableJobs(), 'No async dispatcher job should have been enqueued after System.Test.stopTest()');
    System.Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName() WITH SYSTEM_MODE]);
  }

  @IsTest
  static void it_should_exclude_prior_matches_older_than_the_time_window_from_match_threshold_counting() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c priorEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c currentEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ priorEntry, currentEntry });
    /* 🔔 Notification data setup */
    // Threshold is 2 with a 5-minute window. A prior match backdated to 10 minutes ago falls outside
    // the cutoff, so it must not count toward the threshold. The current batch's single matching
    // record is therefore below the threshold and dispatch is suppressed. This asserts that the
    // runtime's prior-match query is actually applying the cutoff, not just returning every match
    // for the rule.
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 2;
    rule.MatchThresholdTimePeriodIncrement__c = 5;
    rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationMatch__c priorMatch = new LoggerNotificationMatch__c(
      LoggerNotificationRule__c = rule.Id,
      LogEntry__c = priorEntry.Id,
      MatchedRecordId__c = String.valueOf(priorEntry.Id),
      MatchedSObjectType__c = 'LogEntry__c'
    );
    LoggerDataStore.getDatabase().insertRecord(priorMatch);
    System.Test.setCreatedDate(priorMatch.Id, System.now().addMinutes(-10));

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ currentEntry });
    System.Test.stopTest();

    System.Assert.areEqual(
      0,
      mockNotifierInvocationCount,
      'Prior match older than the 5-minute cutoff should not count toward the threshold, so the single current match is below the threshold and dispatch is suppressed'
    );
  }

  @IsTest
  static void it_should_include_prior_matches_within_the_time_window_when_counting_toward_the_threshold() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c priorEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c currentEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ priorEntry, currentEntry });
    /* 🔔 Notification data setup */
    // Threshold is 2 with a 5-minute window. A prior match backdated to 2 minutes ago falls inside
    // the cutoff, so it counts toward the threshold. Combined with the current batch's single
    // matching record, the threshold is met and dispatch fires. This also proves the Minutes arm of
    // the unit switch is being used - if the runtime fell through to the switch's default and got
    // a null cutoff, the prior match would be excluded and dispatch would be suppressed.
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 2;
    rule.MatchThresholdTimePeriodIncrement__c = 5;
    rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);
    LoggerNotificationMatch__c priorMatch = new LoggerNotificationMatch__c(
      LoggerNotificationRule__c = rule.Id,
      LogEntry__c = priorEntry.Id,
      MatchedRecordId__c = String.valueOf(priorEntry.Id),
      MatchedSObjectType__c = 'LogEntry__c'
    );
    LoggerDataStore.getDatabase().insertRecord(priorMatch);
    System.Test.setCreatedDate(priorMatch.Id, System.now().addMinutes(-2));

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ currentEntry });
    System.Test.stopTest();

    System.Assert.areEqual(
      1,
      mockNotifierInvocationCount,
      'Prior match inside the 5-minute cutoff should count toward the threshold, so the current batch of 1 plus 1 prior meets the threshold and dispatch fires'
    );
  }

  @IsTest
  static void it_should_respect_the_hours_time_period_unit_when_computing_the_cutoff() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c priorEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c currentEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ priorEntry, currentEntry });
    /* 🔔 Notification data setup */
    // Threshold is 2 with a 1-hour window. A prior match backdated 30 minutes falls inside a 1-hour
    // cutoff but would be excluded under a Minutes interpretation of the same increment (cutoff would
    // be 1 minute ago). Dispatch firing here proves the Hours arm of the unit switch is being used
    // rather than another arm or the null-cutoff fallback.
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 2;
    rule.MatchThresholdTimePeriodIncrement__c = 1;
    rule.MatchThresholdTimePeriodUnit__c = 'Hours';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);
    LoggerNotificationMatch__c priorMatch = new LoggerNotificationMatch__c(
      LoggerNotificationRule__c = rule.Id,
      LogEntry__c = priorEntry.Id,
      MatchedRecordId__c = String.valueOf(priorEntry.Id),
      MatchedSObjectType__c = 'LogEntry__c'
    );
    LoggerDataStore.getDatabase().insertRecord(priorMatch);
    System.Test.setCreatedDate(priorMatch.Id, System.now().addMinutes(-30));

    // resetMockNotifier();
    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ currentEntry });
    System.Test.stopTest();

    System.Assert.areEqual(
      1,
      mockNotifierInvocationCount,
      'A prior match 30 minutes old falls inside a 1-hour cutoff, so it should count toward the threshold and dispatch should fire - proves the Hours unit is being applied'
    );
  }

  @IsTest
  static void it_should_respect_the_days_time_period_unit_when_computing_the_cutoff() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c priorEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c currentEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ priorEntry, currentEntry });
    /* 🔔 Notification data setup */
    // Threshold is 2 with a 1-day window. A prior match backdated 12 hours falls inside a 1-day
    // cutoff but would be excluded under any tighter unit. Dispatch firing here proves the Days arm
    // of the unit switch is being used rather than another arm or the null-cutoff fallback.
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 2;
    rule.MatchThresholdTimePeriodIncrement__c = 1;
    rule.MatchThresholdTimePeriodUnit__c = 'Days';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);
    LoggerNotificationMatch__c priorMatch = new LoggerNotificationMatch__c(
      LoggerNotificationRule__c = rule.Id,
      LogEntry__c = priorEntry.Id,
      MatchedRecordId__c = String.valueOf(priorEntry.Id),
      MatchedSObjectType__c = 'LogEntry__c'
    );
    LoggerDataStore.getDatabase().insertRecord(priorMatch);
    System.Test.setCreatedDate(priorMatch.Id, System.now().addHours(-12));

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ currentEntry });
    System.Test.stopTest();

    System.Assert.areEqual(
      1,
      mockNotifierInvocationCount,
      'A prior match 12 hours old falls inside a 1-day cutoff, so it should count toward the threshold and dispatch should fire - proves the Days unit is being applied'
    );
  }

  @IsTest
  static void it_should_dispatch_when_match_threshold_reached_via_current_batch() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    List<LogEntry__c> logEntries = new List<LogEntry__c>{
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now()),
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now()),
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now())
    };
    LoggerDataStore.getDatabase().insertRecords(logEntries);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 3;
    rule.MatchThresholdTimePeriodIncrement__c = 60;
    rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, logEntries);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount, 'Threshold of 3 with 3 matches should dispatch once');
    System.Assert.areEqual(3, mockNotifierLastRequest.matchingRecords.size());
    List<LoggerNotificationMatch__c> matches = [
      SELECT Id
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :rule.Id AND LogEntry__c IN :logEntries
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(3, matches.size());
    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT LoggerNotificationMatch__r.LogEntry__c, Status__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationMatch__c IN :matches
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(3, deliveries.size());
    // TODO revisit these asserts
    // for (LoggerNotificationDelivery__c delivery : deliveries) {
    //   if (delivery.LoggerNotificationMatch__r.LogEntry__c == logEntries.get(2).Id) {
    //     System.Assert.areEqual(LoggerNotifierResult.STATUS_DELIVERED, delivery.Status__c);
    //   } else {
    //     System.Assert.areEqual(LoggerNotifierResult.STATUS_SUPPRESSED_BY_THRESHOLD, delivery.Status__c, System.JSON.serializePretty(deliveries));
    //   }
    // }
  }

  @IsTest
  static void it_should_emit_one_delivery_row_per_recipient_when_a_rule_has_multiple_recipients() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c serviceOne = buildService(MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c serviceTwo = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationService__c>{ serviceOne, serviceTwo });
    LoggerNotificationRecipient__c recipientOne = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = serviceOne.Id
    );
    LoggerNotificationRecipient__c recipientTwo = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = serviceTwo.Id
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationRecipient__c>{ recipientOne, recipientTwo });

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });
    System.Test.stopTest();

    List<LoggerNotificationMatch__c> matches = [
      SELECT Id, MatchedRecordId__c
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :rule.Id
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(1, matches.size(), 'Match records are now one-per-matched-record (not per recipient)');
    System.Assert.areEqual(String.valueOf(matchingEntry.Id), matches.get(0).MatchedRecordId__c);
    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT LoggerNotificationMatch__c, LoggerNotificationRecipient__c, LoggerNotificationService__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationMatch__c = :matches.get(0).Id
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(2, deliveries.size(), 'One delivery record per recipient - two recipients means two delivery records for the one match');
    Set<Id> deliveryRecipientIds = new Set<Id>();
    Set<Id> deliveryServiceIds = new Set<Id>();
    for (LoggerNotificationDelivery__c delivery : deliveries) {
      deliveryRecipientIds.add(delivery.LoggerNotificationRecipient__c);
      deliveryServiceIds.add(delivery.LoggerNotificationService__c);
    }
    System.Assert.areEqual(new Set<Id>{ recipientOne.Id, recipientTwo.Id }, deliveryRecipientIds, 'Each recipient should have its own delivery record');
    System.Assert.areEqual(
      new Set<Id>{ serviceOne.Id, serviceTwo.Id },
      deliveryServiceIds,
      'The denormalized service field should also be set on each delivery record'
    );
    System.Assert.areEqual(2, mockNotifierInvocationCount, 'Both recipients should have received the notification');
  }

  @IsTest
  static void it_should_skip_match_persistence_when_match_history_is_disabled() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingLogEntry);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.IsMatchHistoryEnabled__c = false;
    rule.IsDeliveryHistoryEnabled__c = false;
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingLogEntry });
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount, 'Dispatch should still fire even when history storage is off');
    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerNotificationMatch__c WITH SYSTEM_MODE]);
    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerNotificationDelivery__c WITH SYSTEM_MODE]);
  }

  @IsTest
  static void it_should_skip_delivery_persistence_when_delivery_history_is_disabled_but_still_persist_matches() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingLogEntry);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.IsMatchHistoryEnabled__c = true;
    rule.IsDeliveryHistoryEnabled__c = false;
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingLogEntry });
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount, 'Dispatch should still fire when delivery history is off');
    System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerNotificationMatch__c WITH SYSTEM_MODE]);
    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerNotificationDelivery__c WITH SYSTEM_MODE]);
  }

  @IsTest
  static void it_should_count_matches_for_match_threshold_naturally_deduplicated() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c priorLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c currentLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ priorLogEntry, currentLogEntry });
    /* 🔔 Notification data setup */
    // Match records are one-per-matched-record (not per recipient), so a plain COUNT(Id) is
    // already deduplicated. Two recipients pointing at the same rule should not inflate the count.
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 2;
    rule.MatchThresholdTimePeriodIncrement__c = 60;
    rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c serviceOne = buildService(MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c serviceTwo = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationService__c>{ serviceOne, serviceTwo });
    LoggerNotificationRecipient__c recipientOne = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = serviceOne.Id
    );
    LoggerNotificationRecipient__c recipientTwo = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = serviceTwo.Id
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationRecipient__c>{ recipientOne, recipientTwo });
    LoggerNotificationMatch__c priorMatch = new LoggerNotificationMatch__c(
      LoggerNotificationRule__c = rule.Id,
      LogEntry__c = priorLogEntry.Id,
      MatchedRecordId__c = String.valueOf(priorLogEntry.Id),
      MatchedSObjectType__c = 'LogEntry__c'
    );
    LoggerDataStore.getDatabase().insertRecord(priorMatch);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ currentLogEntry });
    System.Test.stopTest();

    // Prior match count = 1 (single priorLogEntry); current batch adds 1 more distinct record.
    // Total = 2, which meets the threshold of 2, so we DO dispatch to both recipients.
    System.Assert.areEqual(2, mockNotifierInvocationCount, 'Both recipients should have fired once the threshold was met');
    System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE Id != :priorMatch.Id WITH SYSTEM_MODE]);
    System.Assert.areEqual(
      2,
      [
        SELECT COUNT()
        FROM LoggerNotificationDelivery__c
        WHERE LoggerNotificationMatch__c != :priorMatch.Id AND LoggerNotificationMatch__r.LogEntry__c = :currentLogEntry.Id
        WITH SYSTEM_MODE
      ]
    );
  }

  @IsTest
  static void it_should_skip_rule_entirely_when_total_enabled_recipients_is_zero() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingLogEntry);
    /* 🔔 Notification data setup */
    // The runtime's SOQL filters on TotalEnabledRecipients__c > 0, so a rule that is IsEnabled__c = true
    // but has zero enabled recipients (either no recipients at all, or every recipient has IsEnabled__c = false)
    // is filtered out before any records are evaluated - no matches, no deliveries, no dispatch.
    LoggerNotificationRule__c ruleWithNoRecipients = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerNotificationRule__c ruleWithDisabledRecipient = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecords(new List<SObject>{ ruleWithNoRecipients, ruleWithDisabledRecipient });
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerDataStore.getDatabase()
      .insertRecord(
        new LoggerNotificationRecipient__c(
          IsEnabled__c = false,
          LoggerNotificationRule__c = ruleWithDisabledRecipient.Id,
          LoggerNotificationService__c = service.Id
        )
      );
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM LoggerNotificationRule__c WHERE TotalEnabledRecipients__c > 0 WITH SYSTEM_MODE],
      'Test has started under the wrong conditions'
    );

    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingLogEntry });

    System.Assert.areEqual(0, mockNotifierInvocationCount, 'Dispatch should not fire for rules with zero enabled recipients');
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM LoggerNotificationMatch__c WITH SYSTEM_MODE],
      'Rules with zero enabled recipients should be skipped before any match records are inserted'
    );
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM LoggerNotificationDelivery__c WITH SYSTEM_MODE],
      'Rules with zero enabled recipients should not produce delivery records'
    );
  }

  @IsTest
  static void it_should_stamp_the_notification_lookup_on_delivery_rows() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingLogEntry);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingLogEntry });
    System.Test.stopTest();

    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT LoggerNotificationRule__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationRecipient__c = :recipient.Id
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(1, deliveries.size());
    System.Assert.areEqual(
      rule.Id,
      deliveries.get(0).LoggerNotificationRule__c,
      'Delivery records should have the denormalized rule ID for reporting/related lists/list-view filtering'
    );
  }

  @IsTest
  static void it_should_fire_every_matching_rule_when_multiple_rules_have_overlapping_criteria() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);
    /* 🔔 Notification data setup */
    // Two rules whose filters both evaluate to TRUE against the same LogEntry__c - one narrow (ERROR only),
    // one broader (ERROR or WARN). Neither rule should short-circuit the other; each should produce its own
    // match record, its own delivery record, and its own notifier invocation.
    LoggerNotificationRule__c errorOnlyRule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    errorOnlyRule.Name = 'ERROR Only Rule';
    LoggerNotificationRule__c errorAndWarnRule = buildRule(
      Schema.LogEntry__c.SObjectType,
      'OR(ISPICKVAL(LoggingLevel__c, \'ERROR\'), ISPICKVAL(LoggingLevel__c, \'WARN\'))'
    );
    errorAndWarnRule.Name = 'ERROR and WARN Rule';
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationRule__c>{ errorOnlyRule, errorAndWarnRule });
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c errorOnlyRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = errorOnlyRule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerNotificationRecipient__c errorAndWarnRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = errorAndWarnRule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationRecipient__c>{ errorOnlyRecipient, errorAndWarnRecipient });

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });
    System.Test.stopTest();

    System.Assert.areEqual(2, mockNotifierInvocationCount, 'Each overlapping rule should independently dispatch to its own recipient');
    Map<Id, LoggerNotificationMatch__c> matchesByRule = new Map<Id, LoggerNotificationMatch__c>();
    for (LoggerNotificationMatch__c match : [
      SELECT Id, LoggerNotificationRule__c, LoggerNotificationRule__r.Name, MatchedRecordId__c
      FROM LoggerNotificationMatch__c
      WITH SYSTEM_MODE
    ]) {
      if (matchesByRule.containsKey(match.LoggerNotificationRule__c)) {
        throw new System.IllegalArgumentException(
          'Expected exactly one match record per rule for this test, but rule ' + match.LoggerNotificationRule__r.Name + ' has more than one'
        );
      }
      matchesByRule.put(match.LoggerNotificationRule__c, match);
    }
    System.Assert.areEqual(
      new Set<Id>{ errorOnlyRule.Id, errorAndWarnRule.Id },
      matchesByRule.keySet(),
      'One match record should be inserted for each rule that matched the same source record'
    );
    System.Assert.areEqual(String.valueOf(matchingEntry.Id), matchesByRule.get(errorOnlyRule.Id).MatchedRecordId__c);
    System.Assert.areEqual(String.valueOf(matchingEntry.Id), matchesByRule.get(errorAndWarnRule.Id).MatchedRecordId__c);
    Map<Id, LoggerNotificationDelivery__c> deliveriesByRule = new Map<Id, LoggerNotificationDelivery__c>();
    for (LoggerNotificationDelivery__c delivery : [
      SELECT LoggerNotificationRecipient__c, LoggerNotificationRule__c, LoggerNotificationRule__r.Name
      FROM LoggerNotificationDelivery__c
      WITH SYSTEM_MODE
    ]) {
      if (deliveriesByRule.containsKey(delivery.LoggerNotificationRule__c)) {
        throw new System.IllegalArgumentException(
          'Expected exactly one delivery record per rule for this test, but rule ' + delivery.LoggerNotificationRule__r.Name + ' has more than one'
        );
      }
      deliveriesByRule.put(delivery.LoggerNotificationRule__c, delivery);
    }
    System.Assert.areEqual(2, deliveriesByRule.size(), 'Each rule should produce its own delivery record');
    System.Assert.areEqual(
      errorOnlyRecipient.Id,
      deliveriesByRule.get(errorOnlyRule.Id).LoggerNotificationRecipient__c,
      'The ERROR-only rule\'s delivery should be for its own recipient'
    );
    System.Assert.areEqual(
      errorAndWarnRecipient.Id,
      deliveriesByRule.get(errorAndWarnRule.Id).LoggerNotificationRecipient__c,
      'The any-severity rule\'s delivery should be for its own recipient'
    );
  }

  @IsTest
  static void it_should_deduplicate_matching_records_by_the_rule_deduplication_source_field() {
    /* 🪵 Logging data setup */
    Log__c logA = new Log__c(TransactionId__c = 'log-a');
    Log__c logB = new Log__c(TransactionId__c = 'log-b');
    LoggerDataStore.getDatabase().insertRecords(new List<Log__c>{ logA, logB });
    List<LogEntry__c> logEntries = new List<LogEntry__c>{
      new LogEntry__c(Log__c = logA.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now()),
      new LogEntry__c(Log__c = logA.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now()),
      new LogEntry__c(Log__c = logA.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now()),
      new LogEntry__c(Log__c = logB.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now())
    };
    LoggerDataStore.getDatabase().insertRecords(logEntries);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.DeduplicationSourceField__c = Schema.LogEntry__c.Log__c.toString();
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, logEntries);
    System.Test.stopTest();

    System.Assert.areEqual(
      1,
      mockNotifierInvocationCount,
      'Dispatch happens once per (rule, recipient), and the notifier receives the deduplicated record list'
    );
    System.Assert.areEqual(2, mockNotifierLastRequest.matchingRecords.size(), 'Notifier should see the deduplicated matching records');
    System.Assert.areEqual(
      2,
      [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id WITH SYSTEM_MODE],
      'Two distinct Log__c values should collapse the four LogEntry__c matches into two LoggerNotificationMatch__c records'
    );
  }

  @IsTest
  static void it_should_preserve_first_seen_record_when_deduping() {
    /* 🪵 Logging data setup */
    Log__c log = new Log__c(TransactionId__c = 'log-order');
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c firstLogEntry = new LogEntry__c(
      Log__c = log.Id,
      LoggingLevel__c = System.LoggingLevel.ERROR.name(),
      Timestamp__c = System.now(),
      Message__c = 'first'
    );
    LogEntry__c secondLogEntry = new LogEntry__c(
      Log__c = log.Id,
      LoggingLevel__c = System.LoggingLevel.ERROR.name(),
      Timestamp__c = System.now(),
      Message__c = 'second'
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ firstLogEntry, secondLogEntry });
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.DeduplicationSourceField__c = Schema.LogEntry__c.Log__c.toString();
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ firstLogEntry, secondLogEntry });
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierLastRequest.matchingRecords.size());
    LogEntry__c keptLogEntry = (LogEntry__c) mockNotifierLastRequest.matchingRecords.get(0);
    System.Assert.areEqual(firstLogEntry.Id, keptLogEntry.Id, 'First-seen record per key wins - order should be preserved');
    List<LoggerNotificationMatch__c> matches = [
      SELECT Id, LogEntry__c
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :rule.Id
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(1, matches.size(), 'Match record should only have been created for 1 LogEntry__c');
    System.Assert.areEqual(keptLogEntry.Id, matches.get(0).LogEntry__c);
  }

  @IsTest
  static void it_should_not_deduplicate_when_the_deduplication_source_field_is_blank() {
    /* 🪵 Logging data setup */
    Log__c log = new Log__c(TransactionId__c = 'log-no-deduplication');
    LoggerDataStore.getDatabase().insertRecord(log);
    List<LogEntry__c> logEntries = new List<LogEntry__c>{
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now()),
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now())
    };
    LoggerDataStore.getDatabase().insertRecords(logEntries);
    /* 🔔 Notification data setup */
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.DeduplicationSourceField__c = null;
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, logEntries);
    System.Test.stopTest();

    System.Assert.areEqual(2, mockNotifierLastRequest.matchingRecords.size());
    System.Assert.areEqual(
      2,
      [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id AND LogEntry__c IN :logEntries WITH SYSTEM_MODE]
    );
  }

  @IsTest
  static void it_should_treat_null_deduplicate_values_as_their_own_group() {
    /* 🪵 Logging data setup */
    Log__c log = new Log__c(TransactionId__c = 'log-no-deduplication');
    LoggerDataStore.getDatabase().insertRecord(log);
    List<SObject> logEntries = new List<SObject>{
      new LogEntry__c(ExceptionType__c = null, Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name()),
      new LogEntry__c(ExceptionType__c = null, Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name())
    };
    /* 🔔 Notification data setup */
    // Records whose deduplication source field value is null share the null-sentinel key and collapse
    // into a single group, so the notifier receives one deduplicated record rather than the raw two.
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.DeduplicationSourceField__c = Schema.LogEntry__c.ExceptionType__c.toString();
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, logEntries);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount);
    System.Assert.areEqual(
      1,
      mockNotifierLastRequest.matchingRecords.size(),
      'Two null-deduplication-value records should collapse to one group keyed on the null sentinel'
    );
    System.Assert.areEqual(
      1,
      [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id AND LogEntry__c IN :logEntries WITH SYSTEM_MODE]
    );
  }

  @IsTest
  static void it_should_not_deduplicate_when_the_deduplication_source_field_does_not_exist_on_the_source_sobject() {
    /* 🪵 Logging data setup */
    Log__c log = new Log__c(TransactionId__c = 'log-no-deduplication');
    LoggerDataStore.getDatabase().insertRecord(log);
    List<SObject> logEntries = new List<SObject>{
      new LogEntry__c(ExceptionType__c = null, Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name()),
      new LogEntry__c(ExceptionType__c = null, Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name())
    };
    /* 🔔 Notification data setup */
    // Fallback path: an admin somehow saved a bogus field name that snuck past validation. Rather than
    // throw at runtime, the runtime treats it as "no deduplication" so notifications still fire and the
    // notifier receives every matching record untouched.
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    // The rule handler normally validates that DeduplicationSourceField__c is a real field on the specific
    // SObject (SourceSObjectType__c), so here we temporarily disable the handler so we can save an invalid value
    LoggerSObjectHandler.shouldExecute(false);
    rule.DeduplicationSourceField__c = 'ThisFieldDoesNotExist__c';
    LoggerDataStore.getDatabase().updateRecord(rule);
    LoggerSObjectHandler.shouldExecute(true);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, logEntries);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount);
    System.Assert.areEqual(2, mockNotifierLastRequest.matchingRecords.size(), 'Unknown deduplication field should fall through without collapsing records');
    System.Assert.areEqual(
      2,
      [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id AND LogEntry__c IN :logEntries WITH SYSTEM_MODE]
    );
  }

  @IsTest
  static void it_should_stamp_match_and_delivery_retention_dates_independently_based_on_the_rules_two_retention_fields() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingLogEntry);
    /* 🔔 Notification data setup */
    // Match records stamp RetentionDate__c from NumberOfDaysToRetainMatches__c; delivery records stamp
    // from NumberOfDaysToRetainDeliveries__c. The two values can differ (subject to the handler's
    // "deliveries <= matches" constraint), so the runtime has to read the right field for each record
    // rather than sharing a single value.
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.NumberOfDaysToRetainMatches__c = 30;
    rule.NumberOfDaysToRetainDeliveries__c = 7;
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingLogEntry });
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount);
    System.Assert.areEqual(1, mockNotifierLastRequest.matchingRecords.size(), 'Unknown deduplication field should fall through without collapsing records');
    List<LoggerNotificationMatch__c> matches = [
      SELECT Id, RetentionDate__c
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :rule.Id
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(1, matches.size());
    System.Assert.areEqual(
      System.today().addDays(rule.NumberOfDaysToRetainMatches__c.intValue()),
      matches.get(0).RetentionDate__c,
      'Match records should stamp RetentionDate__c from NumberOfDaysToRetainMatches__c'
    );
    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT Id, RetentionDate__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationRecipient__c = :recipient.Id
      WITH SYSTEM_MODE
    ];
    System.Assert.areEqual(1, deliveries.size());
    System.Assert.areEqual(
      System.today().addDays(rule.NumberOfDaysToRetainDeliveries__c.intValue()),
      deliveries.get(0).RetentionDate__c,
      'Delivery records should stamp RetentionDate__c from NumberOfDaysToRetainDeliveries__c'
    );
  }

  @IsTest
  static void it_should_leave_retention_dates_null_when_the_rule_retention_days_are_null_or_non_positive() {
    /* 🪵 Logging data setup */
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingLogEntry);
    /* 🔔 Notification data setup */
    // Null / zero / negative retention on either field means "keep that object's records forever" -
    // the runtime stamps RetentionDate__c as null and LogBatchPurger's WHERE clause skips records
    // without a retention date. Test with both fields null so we exercise both stamping paths.
    LoggerNotificationRule__c rule = buildRule(Schema.LogEntry__c.SObjectType, LOG_ENTRY_SAMPLE_FILTER);
    rule.NumberOfDaysToRetainMatches__c = null;
    rule.NumberOfDaysToRetainDeliveries__c = null;
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingLogEntry });
    System.Test.stopTest();

    LoggerNotificationMatch__c match = [
      SELECT Id, RetentionDate__c
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :rule.Id
      WITH SYSTEM_MODE
    ];
    System.Assert.isNull(match.RetentionDate__c, 'Null NumberOfDaysToRetainMatches__c should leave the match record\'s retention date as null');
    LoggerNotificationDelivery__c delivery = [
      SELECT Id, RetentionDate__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationRecipient__c = :recipient.Id
      WITH SYSTEM_MODE
    ];
    System.Assert.isNull(delivery.RetentionDate__c, 'Null NumberOfDaysToRetainDeliveries__c should leave the delivery record\'s retention date as null');
  }

  // Test helpers
  private static LoggerNotificationRule__c buildRule(Schema.SObjectType sobjectType, String filter) {
    return new LoggerNotificationRule__c(
      IsEnabled__c = true,
      IsMatchHistoryEnabled__c = true,
      IsDeliveryHistoryEnabled__c = true,
      IsMatchThresholdEnabled__c = false,
      Name = 'Test rule',
      SourceSObjectFilter__c = filter,
      SourceSObjectType__c = sobjectType.toString()
    );
  }

  private static LoggerNotificationService__c buildService(String notifierApexClassName) {
    return new LoggerNotificationService__c(IsEnabled__c = true, Name = 'Mock service', NotifierApexClassName__c = notifierApexClassName);
  }

  public class MockNotifier extends LoggerNotifier {
    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      mockNotifierInvocationCount++;
      mockNotifierLastRequest = request;
      if (mockNotifierShouldThrowNext) {
        mockNotifierShouldThrowNext = false;
        mockNotifierThrownCount++;
        throw new System.CalloutException('Simulated notifier failure');
      }
      return null;
    }
  }
}
