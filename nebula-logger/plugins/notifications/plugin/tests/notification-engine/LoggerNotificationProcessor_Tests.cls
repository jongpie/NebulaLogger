//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount, PMD.MethodNamingConventions, PMD.NcssCount, PMD.NcssMethodCount')
@IsTest(IsParallel=false)
private class LoggerNotificationProcessor_Tests {
  private static final String MOCK_NOTIFIER_CLASS = MockNotifier.class.getName();
  private static Integer mockNotifierInvocationCount = 0;
  private static Integer mockNotifierThrownCount = 0;
  private static LoggerNotifierRequest mockNotifierLastRequest;
  private static Boolean mockNotifierShouldThrowNext = false;

  static {
    LoggerConfigurationSelector.useMocks();
  }

  @IsTest
  static void it_should_short_circuit_when_records_are_null_or_empty() {
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>());

    LoggerNotificationProcessor processor = new LoggerNotificationProcessor();
    processor.sendNotifications(Schema.LogEntry__c.SObjectType, null);
    processor.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>());
    processor.sendNotifications(null, new List<SObject>{ new LogEntry__c() });

    System.Assert.areEqual(0, mockNotifierInvocationCount);
    System.Assert.areEqual(0, mockNotifierThrownCount);
  }

  @IsTest
  static void it_should_reuse_queried_rules_after_one_query() {
    LoggerNotificationRule__c rule = buildRule();
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    log.TransactionId__c = 'some value';
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    // Notification data setup
    LoggerNotificationRule__c rule = buildRule('Log__c', 'TransactionId__c != null');
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    // Notification data setup
    // The runtime's SOQL subquery filters recipients to those with IsEnabled__c=TRUE pointing at a service
    // whose IsEnabled__c=TRUE AND IsOriginOrganizationIdValid__c=TRUE. A disabled recipient, a recipient
    // whose service is disabled, or a recipient whose service was cloned in from another org never reaches
    // the dispatch loop. Exercising this test against the DB (no setCachedRules) so the SOQL filter is what
    // is under test.
    LoggerNotificationRule__c rule = buildRule();
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c enabledService = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c disabledService = buildService(false, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c invalidOriginService = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
    ];
    System.Assert.areEqual(1, matches.size(), 'Only 1 notification match should have been created');
    System.Assert.areEqual(logEntry.Id, matches.get(0).LogEntry__c);
    System.Assert.areEqual(logEntry.Id, matches.get(0).MatchedRecordId__c);
    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT Id, LoggerNotificationRecipient__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationMatch__c = :matches.get(0).Id
    ];
    System.Assert.areEqual(1, deliveries.size(), 'Only 1 notification delivery should have been created');
    System.Assert.areEqual(validRecipient.Id, deliveries.get(0).LoggerNotificationRecipient__c);
  }

  @IsTest
  static void it_should_pass_only_matching_records_to_the_notifier() {
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c firstMatchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c secondMatchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.INFO.name(), Timestamp__c = System.now());
    List<LogEntry__c> logEntries = new List<SObject>{ firstMatchingLogEntry, secondMatchingLogEntry, nonMatchingLogEntry };
    LoggerDataStore.getDatabase().insertRecords(logEntries);
    // Notification data setup
    LoggerNotificationRule__c rule = buildRule('LogEntry__c', 'ISPICKVAL(LoggingLevel__c, \'ERROR\')');
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.INFO.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(nonMatchingLogEntry);
    // Notification data setup
    LoggerNotificationRule__c rule = buildRule('LogEntry__c', 'ISPICKVAL(LoggingLevel__c, \'ERROR\')');
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    // Notification data setup
    LoggerNotificationRule__c rule = buildRule('LogEntry__c', 'ISPICKVAL(LoggingLevel__c, \'ERROR\')');
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c firstService = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c secondService = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    // Notification data setup
    LoggerNotificationRule__c rule = buildRule('LogEntry__c', 'ISPICKVAL(LoggingLevel__c, \'ERROR\')');
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c serviceWithBadClass = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
      ]
    );
    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT ErrorMessage__c, Status__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationRecipient__r.LoggerNotificationService__c = :serviceWithBadClass.Id
    ];
    System.Assert.areEqual(1, deliveries.size());
    System.Assert.areEqual('Could not instantiate notifier class ' + serviceWithBadClass.NotifierApexClassName__c, deliveries.get(0).ErrorMessage__c);
    System.Assert.areEqual(LoggerNotifierResult.STATUS_SKIPPED, deliveries.get(0).Status__c);
  }

  @IsTest
  static void it_should_persist_matching_log_entries_for_logEntry_source_rules() {
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c nonMatchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.INFO.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ matchingEntry, nonMatchingEntry });
    // Notification data setup
    LoggerNotificationRule__c rule = buildRule();
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
      ]
    );
  }

  // @IsTest
  // static void it_should_suppress_dispatch_when_match_threshold_not_reached() {
  //   // Logging data setup
  //   Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
  //   LoggerDataStore.getDatabase().insertRecord(log);
  //   LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
  //   LoggerDataStore.getDatabase().insertRecord(logEntry);
  //   // Notification data setup
  //   LoggerNotificationRule__c rule = buildRule(
  //     'LogEntry__c',
  //     'ISPICKVAL(LoggingLevel__c, \'ERROR\')',
  //     new List<LoggerNotificationRecipient__c>{ buildRecipient() }
  //   );
  //   rule.IsMatchThresholdEnabled__c = true;
  //   rule.MatchCountThreshold__c = 5;
  //   rule.MatchThresholdTimePeriodIncrement__c = 60;
  //   rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
  //   LoggerDataStore.getDatabase().insertRecord(rule);
  //   LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
  //   System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = rule.Id]);
  //   List<LoggerNotificationDelivery__c> deliveries = [SELECT COUNT() FROM LoggerNotificationDelivery__c WHERE LoggerNotificationRecipient__c = ;recipient.Id];
  //   System.Assert.areEqual(
  //     1,
  //     deliveries.size()
  //   );
  //   System.Assert.areEqual(0, deliveries.get(0).AttemptCount__c);
  //   System.Assert.areEqual(LoggerNotifierResult.STATUS_SUPPRESSED_BY_THRESHOLD, deliveries.get(0).Status__c);
  // }

  @IsTest
  static void it_should_record_suppressed_by_match_threshold_delivery_rows_when_match_threshold_not_reached() {
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c firstEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c secondEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ firstEntry, secondEntry });
    // Notification data setup
    LoggerNotificationRule__c rule = buildRule();
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 10;
    rule.MatchThresholdTimePeriodIncrement__c = 60;
    rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
    List<LoggerNotificationMatch__c> matches = [SELECT Id FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id];
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
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    // Notification data setup
    LoggerNotificationRule__c rule = buildRule();
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 10;
    rule.MatchThresholdTimePeriodIncrement__c = 60;
    rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c enabledService = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c disabledService = buildService(false, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c invalidOriginService = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
    ];
    System.Assert.areEqual(1, deliveries.size(), 'Only the enabled + valid-origin recipient should get a suppressed delivery record');
    System.Assert.areEqual(enabledRecipient.Id, deliveries.get(0).LoggerNotificationRecipient__c);
    System.Assert.areEqual(LoggerNotifierResult.STATUS_SUPPRESSED_BY_THRESHOLD, deliveries.get(0).Status__c);
  }

  // @IsTest
  // static void it_should_not_record_suppressed_deliveries_when_match_history_is_disabled() {
  //   // Logging data setup
  //   Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
  //   LoggerDataStore.getDatabase().insertRecord(log);
  //   LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
  //   LoggerDataStore.getDatabase().insertRecord(logEntry);
  //   // Notification data setup
  //   LoggerNotificationRule__c rule = buildRule();
  //   rule.IsMatchHistoryEnabled__c = false;
  //   rule.IsMatchThresholdEnabled__c = true;
  //   rule.MatchCountThreshold__c = 5;
  //   rule.MatchThresholdTimePeriodIncrement__c = 60;
  //   rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
  //   LoggerDataStore.getDatabase().insertRecord(rule);
  //   LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
  //   LoggerDataStore.getDatabase().insertRecord(service);
  //   LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
  //     LoggerNotificationRule__c = rule.Id,
  //     LoggerNotificationService__c = service.Id
  //   );
  //   LoggerDataStore.getDatabase().insertRecord(recipient);

  //   System.Test.startTest();
  //   new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });
  //   System.Test.stopTest();

  //   Integer matchCount = [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id];
  //   System.Assert.areEqual(0, matchCount, 'Match records should not be persisted when IsMatchHistoryEnabled__c is false');
  //   Integer deliveryCount = [SELECT COUNT() FROM LoggerNotificationDelivery__c WHERE LoggerNotificationRecipient__c = :recipient.Id];
  //   System.Assert.areEqual(
  //     0,
  //     deliveryCount,
  //     'Suppressed delivery records require match records to reference, so they must not be recorded when match history is disabled'
  //   );
  // }

  @IsTest
  static void it_should_not_record_suppressed_deliveries_when_delivery_history_is_disabled() {
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    // Notification data setup
    LoggerNotificationRule__c rule = buildRule();
    rule.IsMatchHistoryEnabled__c = true;
    rule.IsDeliveryHistoryEnabled__c = false;
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 5;
    rule.MatchThresholdTimePeriodIncrement__c = 60;
    rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
      [SELECT COUNT() FROM LoggerNotificationDelivery__c WHERE LoggerNotificationMatch__r.LoggerNotificationRule__c = :rule.Id],
      'Delivery records should not be recorded when IsDeliveryHistoryEnabled__c is false, even for suppressed-by-threshold outcomes'
    );
  }

  @IsTest
  static void it_should_route_every_recipient_through_the_async_dispatcher() {
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    // Notification data setup
    // Every notification goes through LoggerNotificationAsyncDispatcher - no notifier fires
    // synchronously inside the source trigger. This isolates notifier failures + callouts from
    // the record insert transaction and gives each notification its own governor budget.
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c();
    recipient.LoggerNotificationService__r = service;
    LoggerNotificationRule__c rule = buildRule('LogEntry__c', 'ISPICKVAL(LoggingLevel__c, \'ERROR\')', new List<LoggerNotificationRecipient__c>{ recipient });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ rule });

    // Since this test is trying to validate what happens sync vs async, there are intentionally
    // asserts inside (and outside) of System.Test.startTest() & System.Test.stopTest()
    System.Test.startTest();
    System.Assert.areEqual(0, System.Limits.getQueueableJobs(), 'One async dispatcher job should have been enqueued');
    System.Assert.areEqual(0, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName()]);
    new LoggerNotificationProcessor()
      .sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name()) });
    System.Assert.areEqual(0, mockNotifierInvocationCount, 'Notifier should not fire synchronously - it should be queued');
    System.Assert.areEqual(1, System.Limits.getQueueableJobs(), 'One async dispatcher job should have been enqueued');
    System.Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName()]);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount, 'Notifier should have fired synchronously');
    System.Assert.areEqual(0, System.Limits.getQueueableJobs(), 'No async dispatcher job should have been enqueued after System.Test.stopTest()');
    System.Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName()]);
  }

  @IsTest
  static void it_should_batch_multiple_recipients_into_a_single_queueable() {
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ logEntry });
    // Notification data setup
    LoggerNotificationRule__c rule = buildRule('LogEntry__c', 'ISPICKVAL(LoggingLevel__c, \'ERROR\')', new List<LoggerNotificationRecipient__c>());
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c serviceA = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c serviceB = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
    System.Assert.areEqual(0, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName()]);
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });
    System.Assert.areEqual(0, mockNotifierInvocationCount, 'Notifier should not fire synchronously - it should be queued');
    System.Assert.areEqual(1, System.Limits.getQueueableJobs(), 'One async dispatcher job should have been enqueued');
    System.Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName()]);
    System.Test.stopTest();

    System.Assert.areEqual(2, mockNotifierInvocationCount, 'Notifiers should have fired for 2 recipients');
    System.Assert.areEqual(0, System.Limits.getQueueableJobs(), 'No async dispatcher job should have been enqueued after System.Test.stopTest()');
    System.Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :LoggerNotificationAsyncDispatcher.class.getName()]);
  }

  @IsTest
  static void it_should_exclude_prior_matches_older_than_the_time_window_from_match_threshold_counting() {
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c priorEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c currentEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ priorEntry, currentEntry });
    // Notification data setup
    // Threshold is 2 with a 5-minute window. A prior match backdated to 10 minutes ago falls outside
    // the cutoff, so it must not count toward the threshold. The current batch's single matching
    // record is therefore below the threshold and dispatch is suppressed. This asserts that the
    // runtime's prior-match query is actually applying the cutoff, not just returning every match
    // for the rule.
    LoggerNotificationRule__c rule = buildRule();
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
    System.Assert.fail('maybe add asserts about delivery being suppressed?');
  }

  @IsTest
  static void it_should_include_prior_matches_within_the_time_window_when_counting_toward_the_threshold() {
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c priorEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c currentEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ priorEntry, currentEntry });
    // Notification data setup
    // Threshold is 2 with a 5-minute window. A prior match backdated to 2 minutes ago falls inside
    // the cutoff, so it counts toward the threshold. Combined with the current batch's single
    // matching record, the threshold is met and dispatch fires. This also proves the Minutes arm of
    // the unit switch is being used - if the runtime fell through to the switch's default and got
    // a null cutoff, the prior match would be excluded and dispatch would be suppressed.
    LoggerNotificationRule__c rule = buildRule();
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 2;
    rule.MatchThresholdTimePeriodIncrement__c = 5;
    rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
    System.Assert.fail('maybe add asserts about delivery being suppressed?');
  }

  @IsTest
  static void it_should_respect_the_hours_time_period_unit_when_computing_the_cutoff() {
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c priorEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c currentEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ priorEntry, currentEntry });
    // Notification data setup
    // Threshold is 2 with a 1-hour window. A prior match backdated 30 minutes falls inside a 1-hour
    // cutoff but would be excluded under a Minutes interpretation of the same increment (cutoff would
    // be 1 minute ago). Dispatch firing here proves the Hours arm of the unit switch is being used
    // rather than another arm or the null-cutoff fallback.
    LoggerNotificationRule__c rule = buildRule();
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 2;
    rule.MatchThresholdTimePeriodIncrement__c = 1;
    rule.MatchThresholdTimePeriodUnit__c = 'Hours';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
    System.Assert.fail('maybe add asserts about delivery records?');
  }

  @IsTest
  static void it_should_respect_the_days_time_period_unit_when_computing_the_cutoff() {
    // Logging data setup
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c priorEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c currentEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ priorEntry, currentEntry });
    // Notification data setup
    // Threshold is 2 with a 1-day window. A prior match backdated 12 hours falls inside a 1-day
    // cutoff but would be excluded under any tighter unit. Dispatch firing here proves the Days arm
    // of the unit switch is being used rather than another arm or the null-cutoff fallback.
    LoggerNotificationRule__c rule = buildRule();
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 2;
    rule.MatchThresholdTimePeriodIncrement__c = 1;
    rule.MatchThresholdTimePeriodUnit__c = 'Days';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
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
    System.Assert.fail('maybe add asserts about delivery records?');
  }

  @IsTest
  static void it_should_dispatch_when_match_threshold_reached_via_current_batch() {
    System.Assert.fail('RESUME HERE!');
    LoggerNotificationRule__c rule = buildRule();
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 3;
    rule.MatchThresholdTimePeriodIncrement__c = 60;
    rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(rule);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    List<LogEntry__c> entries = new List<LogEntry__c>{
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now()),
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now()),
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now())
    };
    LoggerDataStore.getDatabase().insertRecords(entries);

    // resetMockNotifier();
    LoggerNotificationProcessor processor = new LoggerNotificationProcessor();

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, entries);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount, 'Threshold of 3 with 3 matches should dispatch once');
    System.Assert.areEqual(3, mockNotifierLastRequest.matchingRecords.size());
  }

  @IsTest
  static void it_should_emit_one_delivery_row_per_recipient_when_a_rule_has_multiple_recipients() {
    LoggerNotificationRule__c rule = buildRule();
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c serviceOne = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c serviceTwo = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationService__c>{ serviceOne, serviceTwo });

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    LoggerNotificationRecipient__c recipientOne = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = serviceOne.Id
    );
    LoggerNotificationRecipient__c recipientTwo = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = serviceTwo.Id
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationRecipient__c>{ recipientOne, recipientTwo });

    LoggerNotificationRecipient__c cachedRecipientOne = new LoggerNotificationRecipient__c(Id = recipientOne.Id, LoggerNotificationService__c = serviceOne.Id);
    cachedRecipientOne.LoggerNotificationService__r = serviceOne;
    LoggerNotificationRecipient__c cachedRecipientTwo = new LoggerNotificationRecipient__c(Id = recipientTwo.Id, LoggerNotificationService__c = serviceTwo.Id);
    cachedRecipientTwo.LoggerNotificationService__r = serviceTwo;
    LoggerNotificationRule__c ruleCopy = rule.clone(true, true, true, true);
    LoggerNotificationRule__c cachedRule = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ cachedRecipientOne, cachedRecipientTwo });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ cachedRule });

    // resetMockNotifier();
    LoggerNotificationProcessor processor = new LoggerNotificationProcessor();
    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });
    System.Test.stopTest();

    List<LoggerNotificationMatch__c> matches = [
      SELECT Id, MatchedRecordId__c
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :rule.Id
    ];
    System.Assert.areEqual(1, matches.size(), 'Match records are now one-per-matched-record (not per recipient)');
    System.Assert.areEqual(String.valueOf(matchingEntry.Id), matches.get(0).MatchedRecordId__c);

    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT LoggerNotificationMatch__c, LoggerNotificationRecipient__c, LoggerNotificationService__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationMatch__c = :matches.get(0).Id
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
    LoggerNotificationRule__c rule = buildRule();
    rule.IsMatchHistoryEnabled__c = false;
    rule.IsDeliveryHistoryEnabled__c = false;
    LoggerDataStore.getDatabase().insertRecord(rule);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    // resetMockNotifier();
    LoggerNotificationProcessor processor = new LoggerNotificationProcessor();
    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });
    System.Test.stopTest();

    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id]);
    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerNotificationDelivery__c]);
    System.Assert.areEqual(1, mockNotifierInvocationCount, 'Dispatch should still fire even when history storage is off');
  }

  @IsTest
  static void it_should_skip_delivery_persistence_when_delivery_history_is_disabled_but_still_persist_matches() {
    LoggerNotificationRule__c rule = buildRule();
    rule.IsDeliveryHistoryEnabled__c = false;
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    LoggerNotificationRecipient__c cachedRecipient = new LoggerNotificationRecipient__c(Id = recipient.Id, LoggerNotificationService__c = service.Id);
    cachedRecipient.LoggerNotificationService__r = service;
    LoggerNotificationRule__c ruleCopy = rule.clone(true, true, true, true);
    LoggerNotificationRule__c cachedRule = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ cachedRecipient });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ cachedRule });

    // resetMockNotifier();
    LoggerNotificationProcessor processor = new LoggerNotificationProcessor();
    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });
    System.Test.stopTest();

    System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id]);
    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerNotificationDelivery__c]);
    System.Assert.areEqual(1, mockNotifierInvocationCount, 'Dispatch should still fire when delivery history is off');
  }

  @IsTest
  static void it_should_count_matches_for_match_threshold_naturally_deduplicated() {
    // Match records are now one-per-matched-record (not per recipient), so a plain COUNT(Id) is
    // already deduplicated. Two recipients pointing at the same rule should not inflate the count.
    LoggerNotificationRule__c rule = buildRule();
    rule.IsMatchThresholdEnabled__c = true;
    rule.MatchCountThreshold__c = 2;
    rule.MatchThresholdTimePeriodIncrement__c = 60;
    rule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c serviceOne = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c serviceTwo = buildService(true, true, MOCK_NOTIFIER_CLASS);
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

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c priorEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LogEntry__c currentEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ priorEntry, currentEntry });
    LoggerDataStore.getDatabase()
      .insertRecord(
        new LoggerNotificationMatch__c(
          LoggerNotificationRule__c = rule.Id,
          LogEntry__c = priorEntry.Id,
          MatchedRecordId__c = String.valueOf(priorEntry.Id),
          MatchedSObjectType__c = 'LogEntry__c'
        )
      );

    LoggerNotificationRecipient__c cachedRecipientOne = new LoggerNotificationRecipient__c(Id = recipientOne.Id, LoggerNotificationService__c = serviceOne.Id);
    cachedRecipientOne.LoggerNotificationService__r = serviceOne;
    LoggerNotificationRecipient__c cachedRecipientTwo = new LoggerNotificationRecipient__c(Id = recipientTwo.Id, LoggerNotificationService__c = serviceTwo.Id);
    cachedRecipientTwo.LoggerNotificationService__r = serviceTwo;
    LoggerNotificationRule__c ruleCopy = rule.clone(true, true, true, true);
    LoggerNotificationRule__c cachedRule = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ cachedRecipientOne, cachedRecipientTwo });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ cachedRule });

    // resetMockNotifier();
    LoggerNotificationProcessor processor = new LoggerNotificationProcessor();
    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ currentEntry });
    System.Test.stopTest();

    // Prior match count = 1 (single priorEntry); current batch adds 1 more distinct record.
    // Total = 2, which meets the threshold of 2, so we DO dispatch to both recipients.
    System.Assert.areEqual(2, mockNotifierInvocationCount, 'Both recipients should have fired once the threshold was met');
  }

  @IsTest
  static void it_should_skip_rule_entirely_when_total_enabled_recipients_is_zero() {
    // The runtime's SOQL now filters on TotalEnabledRecipients__c > 0 so a rule that is IsEnabled__c=TRUE
    // but has zero enabled recipients (either no recipients at all, or every recipient has IsEnabled__c=false)
    // is dropped before any records are evaluated - no matches, no deliveries, no dispatch.
    LoggerNotificationRule__c ruleWithNoRecipients = buildRule();
    LoggerDataStore.getDatabase().insertRecord(ruleWithNoRecipients);
    LoggerNotificationRule__c ruleWithDisabledRecipient = buildRule();
    LoggerDataStore.getDatabase().insertRecord(ruleWithDisabledRecipient);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerDataStore.getDatabase()
      .insertRecord(
        new LoggerNotificationRecipient__c(
          LoggerNotificationRule__c = ruleWithDisabledRecipient.Id,
          LoggerNotificationService__c = service.Id,
          IsEnabled__c = false
        )
      );

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    // resetMockNotifier();
    // Let the runtime query real rules from the DB - do NOT call setCachedRules here, so the WHERE clause matters.
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });

    Set<Id> ruleIds = new Set<Id>{ ruleWithNoRecipients.Id, ruleWithDisabledRecipient.Id };
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c IN :ruleIds],
      'Rules with zero enabled recipients should be skipped before any match records are inserted'
    );
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM LoggerNotificationDelivery__c WHERE LoggerNotificationRule__c IN :ruleIds],
      'Rules with zero enabled recipients should not produce delivery records'
    );
    System.Assert.areEqual(0, mockNotifierInvocationCount, 'Dispatch should not fire for rules with zero enabled recipients');
  }

  @IsTest
  static void it_should_stamp_the_notification_lookup_on_delivery_rows() {
    LoggerNotificationRule__c rule = buildRule();
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    LoggerNotificationRecipient__c cachedRecipient = new LoggerNotificationRecipient__c(Id = recipient.Id, LoggerNotificationService__c = service.Id);
    cachedRecipient.LoggerNotificationService__r = service;
    LoggerNotificationRule__c ruleCopy = rule.clone(true, true, true, true);
    LoggerNotificationRule__c cachedRule = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ cachedRecipient });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ cachedRule });

    // resetMockNotifier();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });

    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT LoggerNotificationRule__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationRecipient__c = :recipient.Id
    ];
    System.Assert.areEqual(1, deliveries.size());
    System.Assert.areEqual(
      rule.Id,
      deliveries.get(0).LoggerNotificationRule__c,
      'Delivery records should carry the denormalized rule Id for report/list-view filtering'
    );
  }

  @IsTest
  static void it_should_deduplicate_matching_records_by_the_rule_deduplication_source_field() {
    Log__c logA = new Log__c(TransactionId__c = 'log-a');
    Log__c logB = new Log__c(TransactionId__c = 'log-b');
    LoggerDataStore.getDatabase().insertRecords(new List<Log__c>{ logA, logB });
    List<LogEntry__c> entries = new List<LogEntry__c>{
      new LogEntry__c(Log__c = logA.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now()),
      new LogEntry__c(Log__c = logA.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now()),
      new LogEntry__c(Log__c = logA.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now()),
      new LogEntry__c(Log__c = logB.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now())
    };
    LoggerDataStore.getDatabase().insertRecords(entries);
    LoggerNotificationRule__c rule = buildRule();
    rule.DeduplicationSourceField__c = 'Log__c';
    LoggerDataStore.getDatabase().insertRecord(rule);

    // resetMockNotifier();
    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, entries);
    System.Test.stopTest();

    Integer matchCount = [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id];
    System.Assert.areEqual(2, matchCount, 'Two distinct Log__c values should collapse the four entries into two matches');
    System.Assert.areEqual(
      1,
      mockNotifierInvocationCount,
      'Dispatch happens once per (rule, recipient), and the notifier receives the deduplicated record list'
    );
    System.Assert.areEqual(2, mockNotifierLastRequest.matchingRecords.size(), 'Notifier should see the deduplicated matching records');
  }

  @IsTest
  static void it_should_preserve_first_seen_record_when_deduping() {
    Log__c log = new Log__c(TransactionId__c = 'log-order');
    LoggerDataStore.getDatabase().insertRecord(log);
    LoggerNotificationRule__c rule = buildRule();
    rule.DeduplicationSourceField__c = 'Log__c';
    LoggerDataStore.getDatabase().insertRecord(rule);
    LogEntry__c firstEntry = new LogEntry__c(
      Log__c = log.Id,
      LoggingLevel__c = System.LoggingLevel.ERROR.name(),
      Timestamp__c = System.now(),
      Message__c = 'first'
    );
    LogEntry__c secondEntry = new LogEntry__c(
      Log__c = log.Id,
      LoggingLevel__c = System.LoggingLevel.ERROR.name(),
      Timestamp__c = System.now(),
      Message__c = 'second'
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ firstEntry, secondEntry });

    // resetMockNotifier();
    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ firstEntry, secondEntry });
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierLastRequest.matchingRecords.size());
    LogEntry__c kept = (LogEntry__c) mockNotifierLastRequest.matchingRecords.get(0);
    System.Assert.areEqual(firstEntry.Id, kept.Id, 'First-seen record per key wins - order should be preserved');
  }

  @IsTest
  static void it_should_not_deduplicate_when_the_deduplication_source_field_is_blank() {
    Log__c log = new Log__c(TransactionId__c = 'log-no-deduplication');
    LoggerDataStore.getDatabase().insertRecord(log);
    LoggerNotificationRule__c rule = buildRule();
    rule.DeduplicationSourceField__c = null;
    LoggerDataStore.getDatabase().insertRecord(rule);
    List<LogEntry__c> entries = new List<LogEntry__c>{
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now()),
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now())
    };
    LoggerDataStore.getDatabase().insertRecords(entries);

    // resetMockNotifier();
    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, entries);
    System.Test.stopTest();

    System.Assert.areEqual(2, [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id]);
    System.Assert.areEqual(2, mockNotifierLastRequest.matchingRecords.size());
  }

  @IsTest
  static void it_should_treat_null_deduplicate_values_as_their_own_group() {
    // Records whose deduplication source field value is null share the null-sentinel key and collapse
    // into a single group, so the notifier receives one deduplicated record rather than the raw two.
    LoggerNotificationRule__c rule = buildRule(
      'LogEntry__c',
      'ISPICKVAL(LoggingLevel__c, \'ERROR\')',
      new List<LoggerNotificationRecipient__c>{ buildRecipient() }
    );
    rule.DeduplicationSourceField__c = 'Log__c';
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ rule });
    // resetMockNotifier();
    List<SObject> records = new List<SObject>{
      new LogEntry__c(Log__c = null, LoggingLevel__c = System.LoggingLevel.ERROR.name()),
      new LogEntry__c(Log__c = null, LoggingLevel__c = System.LoggingLevel.ERROR.name())
    };

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, records);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount);
    System.Assert.areEqual(
      1,
      mockNotifierLastRequest.matchingRecords.size(),
      'Two null-deduplication-value records should collapse to one group keyed on the null sentinel'
    );
  }

  @IsTest
  static void it_should_not_deduplicate_when_the_deduplication_source_field_does_not_exist_on_the_source_sobject() {
    // Fallback path: an admin somehow saved a bogus field name that snuck past validation. Rather than
    // throw at runtime, the runtime treats it as "no deduplication" so notifications still fire and the
    // notifier receives every matching record untouched.
    LoggerNotificationRule__c rule = buildRule(
      'LogEntry__c',
      'ISPICKVAL(LoggingLevel__c, \'ERROR\')',
      new List<LoggerNotificationRecipient__c>{ buildRecipient() }
    );
    rule.DeduplicationSourceField__c = 'ThisFieldDoesNotExist__c';
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ rule });
    // resetMockNotifier();
    List<SObject> records = new List<SObject>{
      new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name()),
      new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name())
    };

    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, records);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount);
    System.Assert.areEqual(2, mockNotifierLastRequest.matchingRecords.size(), 'Unknown deduplication field should fall through without collapsing records');
  }

  @IsTest
  static void it_should_stamp_match_and_delivery_retention_dates_independently_from_the_rules_two_retention_fields() {
    // Match records stamp RetentionDate__c from NumberOfDaysToRetainMatches__c; delivery records stamp
    // from NumberOfDaysToRetainDeliveries__c. The two values can differ (subject to the handler's
    // "deliveries <= matches" constraint), so the runtime has to read the right field for each record
    // rather than sharing a single value.
    Integer matchRetentionDays = 30;
    Integer deliveryRetentionDays = 7;
    LoggerNotificationRule__c rule = buildRule();
    rule.NumberOfDaysToRetainMatches__c = matchRetentionDays;
    rule.NumberOfDaysToRetainDeliveries__c = deliveryRetentionDays;
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    LoggerNotificationRecipient__c cachedRecipient = new LoggerNotificationRecipient__c(Id = recipient.Id, LoggerNotificationService__c = service.Id);
    cachedRecipient.LoggerNotificationService__r = service;
    LoggerNotificationRule__c ruleCopy = rule.clone(true, true, true, true);
    LoggerNotificationRule__c cachedRule = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ cachedRecipient });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ cachedRule });

    Date expectedMatchRetentionDate = System.today().addDays(matchRetentionDays);
    Date expectedDeliveryRetentionDate = System.today().addDays(deliveryRetentionDays);
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });

    List<LoggerNotificationMatch__c> matches = [
      SELECT Id, RetentionDate__c
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :rule.Id
    ];
    System.Assert.areEqual(1, matches.size());
    System.Assert.areEqual(
      expectedMatchRetentionDate,
      matches.get(0).RetentionDate__c,
      'Match records should stamp RetentionDate__c from NumberOfDaysToRetainMatches__c'
    );
    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT Id, RetentionDate__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationRecipient__c = :recipient.Id
    ];
    System.Assert.areEqual(1, deliveries.size());
    System.Assert.areEqual(
      expectedDeliveryRetentionDate,
      deliveries.get(0).RetentionDate__c,
      'Delivery records should stamp RetentionDate__c from NumberOfDaysToRetainDeliveries__c'
    );
  }

  @IsTest
  static void it_should_leave_retention_date_null_when_the_rules_retention_days_is_null_or_non_positive() {
    // Null / zero / negative retention on either field means "keep that object's records forever" -
    // the runtime stamps RetentionDate__c as null and LogBatchPurger's WHERE clause skips records
    // without a retention date. Test with both fields null so we exercise both stamping paths.
    LoggerNotificationRule__c rule = buildRule();
    rule.NumberOfDaysToRetainMatches__c = null;
    rule.NumberOfDaysToRetainDeliveries__c = null;
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    LoggerNotificationRecipient__c cachedRecipient = new LoggerNotificationRecipient__c(Id = recipient.Id, LoggerNotificationService__c = service.Id);
    cachedRecipient.LoggerNotificationService__r = service;
    LoggerNotificationRule__c ruleCopy = rule.clone(true, true, true, true);
    LoggerNotificationRule__c cachedRule = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ cachedRecipient });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ cachedRule });

    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });

    LoggerNotificationMatch__c match = [
      SELECT Id, RetentionDate__c
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :rule.Id
      LIMIT 1
    ];
    System.Assert.isNull(match.RetentionDate__c, 'Null NumberOfDaysToRetainMatches__c should leave the match record untouched by LogBatchPurger');
    LoggerNotificationDelivery__c delivery = [
      SELECT Id, RetentionDate__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationRecipient__c = :recipient.Id
      LIMIT 1
    ];
    System.Assert.isNull(delivery.RetentionDate__c, 'Null NumberOfDaysToRetainDeliveries__c should leave the delivery record untouched by LogBatchPurger');
  }

  // Test helpers

  // TODO keep only this overload?
  private static LoggerNotificationRule__c buildRule(String sourceSObjectTypeName, String filter) {
    return buildRule(sourceSObjectTypeName, filter, null);
  }

  // TODO eliminate this overload?
  private static LoggerNotificationRule__c buildRule(String sourceSObjectTypeName, String filter, List<LoggerNotificationRecipient__c> recipients) {
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(
      IsEnabled__c = true,
      Name = 'Test rule',
      SourceSObjectFilter__c = filter,
      SourceSObjectType__c = sourceSObjectTypeName
    );
    return rule;
  }

  // TODO eliminate this overload?
  private static LoggerNotificationRule__c buildRule() {
    // TODO stop calling LoggerMockDataCreator.createDataBuilder
    LoggerNotificationRule__c rule = (LoggerNotificationRule__c) LoggerMockDataCreator.createDataBuilder(Schema.LoggerNotificationRule__c.SObjectType)
      .populateRequiredFields()
      .getRecord();
    rule.SourceSObjectType__c = 'LogEntry__c';
    rule.SourceSObjectFilter__c = 'ISPICKVAL(LoggingLevel__c, \'ERROR\')';
    rule.IsEnabled__c = true;
    // Reset the inverted-boolean values that LoggerMockDataCreator produces, so we don't trip validation rules.
    rule.IsMatchHistoryEnabled__c = true;
    rule.IsDeliveryHistoryEnabled__c = true;
    rule.IsMatchThresholdEnabled__c = false;
    return rule;
  }

  // TODO eliminate this method
  private static LoggerNotificationRule__c attachRecipients(LoggerNotificationRule__c rule, List<LoggerNotificationRecipient__c> recipients) {
    // Child relationships on in-memory SObjects can't be assigned directly - round-trip through JSON.
    Map<String, Object> ruleJson = (Map<String, Object>) System.JSON.deserializeUntyped(System.JSON.serialize(rule));
    Map<String, Object> recipientsSubquery = new Map<String, Object>();
    recipientsSubquery.put('totalSize', recipients.size());
    recipientsSubquery.put('done', true);
    recipientsSubquery.put('records', recipients);
    ruleJson.put('LoggerNotificationRecipients__r', recipientsSubquery);
    return (LoggerNotificationRule__c) System.JSON.deserialize(System.JSON.serialize(ruleJson), LoggerNotificationRule__c.class);
  }

  // TODO eliminate?
  private static LoggerNotificationRecipient__c buildRecipient() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c();

    // TODO stop creating a service inline here
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    service.WebhookUrl__c = 'https://example.com/webhook';
    recipient.LoggerNotificationService__r = service;
    return recipient;
  }

  private static LoggerNotificationService__c buildService(Boolean isEnabled, Boolean isOriginValid, String apexClassName) {
    String originOrgId = isOriginValid ? System.UserInfo.getOrganizationId() : LoggerMockDataCreator.createId(Schema.Organization.SObjectType);
    return new LoggerNotificationService__c(
      Name = 'Mock service',
      NotifierApexClassName__c = apexClassName,
      IsEnabled__c = isEnabled,
      OriginOrganizationId__c = originOrgId
    );
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
