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

  private static void resetMockNotifier() {
    mockNotifierInvocationCount = 0;
    mockNotifierThrownCount = 0;
    mockNotifierLastRequest = null;
    mockNotifierShouldThrowNext = false;
  }

  @IsTest
  static void it_should_short_circuit_when_records_are_null_or_empty() {
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>());
    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();

    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, null);
    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>());
    notifier.sendNotifications(null, new List<SObject>{ new LogEntry__c() });

    System.Assert.areEqual(0, mockNotifierInvocationCount);
  }

  @IsTest
  static void it_should_populate_logger_cache_when_active_rules_are_queried() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'NotificationsUsePlatformCache', Value__c = String.valueOf(true)));
    System.Assert.isTrue(LoggerNotificationProcessor.USE_PLATFORM_CACHE, 'Test has started under the wrong conditions');
    LoggerNotificationRule__c rule = buildRule();
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerDataStore.getDatabase()
      .insertRecord(new LoggerNotificationRecipient__c(LoggerNotificationRule__c = rule.Id, LoggerNotificationService__c = service.Id));

    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') });

    System.Assert.isTrue(
      LoggerCache.getOrganizationCache().contains(LoggerNotificationProcessor.CACHE_KEY_ACTIVE_RULES),
      'sendNotifications should have populated LoggerCache after querying active rules'
    );
    Map<String, List<LoggerNotificationRule__c>> cachedRules = (Map<String, List<LoggerNotificationRule__c>>) LoggerCache.getOrganizationCache()
      .get(LoggerNotificationProcessor.CACHE_KEY_ACTIVE_RULES);
    System.Assert.areEqual(
      new Set<String>{ Schema.LogEntry__c.SObjectType.toString() },
      cachedRules.keySet(),
      'Only the rule\'s source SObject type should be cached'
    );
    List<LoggerNotificationRule__c> logEntryRules = cachedRules.get(Schema.LogEntry__c.SObjectType.toString());
    System.Assert.areEqual(1, logEntryRules.size(), 'The active rule should have been cached under its source SObject type');
    System.Assert.areEqual(rule.Id, logEntryRules.get(0).Id, 'The cached rule should match the inserted rule');
  }

  @IsTest
  static void it_should_reuse_cached_active_rules_without_querying() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'NotificationsUsePlatformCache', Value__c = String.valueOf(true)));
    System.Assert.isTrue(LoggerNotificationProcessor.USE_PLATFORM_CACHE, 'Test has started under the wrong conditions');
    LoggerNotificationRule__c rule = buildRule(
      'LogEntry__c',
      'ISPICKVAL(LoggingLevel__c, \'ERROR\')',
      new List<LoggerNotificationRecipient__c>{ buildRecipient() }
    );
    LoggerCache.getOrganizationCache()
      .put(
        LoggerNotificationProcessor.CACHE_KEY_ACTIVE_RULES,
        new Map<String, List<LoggerNotificationRule__c>>{ Schema.LogEntry__c.SObjectType.toString() => new List<LoggerNotificationRule__c>{ rule } }
      );
    Integer queryCountBefore = System.Limits.getQueries();

    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') });

    System.Assert.areEqual(queryCountBefore, System.Limits.getQueries(), 'getActiveRules should have used the cached rules without issuing a SOQL query');
  }

  @IsTest
  static void it_should_skip_the_logger_cache_when_notifications_use_platform_cache_is_disabled() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'NotificationsUsePlatformCache', Value__c = String.valueOf(false)));
    System.Assert.isFalse(LoggerNotificationProcessor.USE_PLATFORM_CACHE, 'Test has started under the wrong conditions');
    LoggerNotificationRule__c rule = buildRule();
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerDataStore.getDatabase()
      .insertRecord(new LoggerNotificationRecipient__c(LoggerNotificationRule__c = rule.Id, LoggerNotificationService__c = service.Id));

    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') });

    System.Assert.isFalse(
      LoggerCache.getOrganizationCache().contains(LoggerNotificationProcessor.CACHE_KEY_ACTIVE_RULES),
      'sendNotifications should not have written to LoggerCache when NotificationsUsePlatformCache is disabled'
    );
  }

  @IsTest
  static void it_should_ignore_rules_for_a_different_source_sobject_type() {
    LoggerNotificationRule__c rule = buildRule('Log__c', 'TotalERRORLogEntries__c >= 1', new List<LoggerNotificationRecipient__c>{ buildRecipient() });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ rule });
    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();

    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') });

    System.Assert.areEqual(0, mockNotifierInvocationCount, 'Rules for a different sobject type should be ignored');
  }

  @IsTest
  static void it_should_dispatch_only_to_enabled_recipients_whose_service_is_enabled_and_valid() {
    // The runtime's SOQL subquery filters recipients to those with IsEnabled__c=TRUE pointing at a service
    // whose IsEnabled__c=TRUE AND IsOriginOrganizationIdValid__c=TRUE. A disabled recipient, a recipient
    // whose service is disabled, or a recipient whose service was cloned in from another org never reaches
    // the dispatch loop. Exercising this test against the DB (no setCachedRules) so the SOQL filter is what
    // is under test.
    LoggerNotificationRule__c persistedRule = buildRule();
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    LoggerNotificationService__c enabledService = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c disabledService = buildService(false, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c invalidOriginService = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationService__c>{ enabledService, disabledService, invalidOriginService });
    // The handler overwrites OriginOrganizationId__c on insert - flip it to a foreign org via a follow-up
    // update with the handler suppressed so IsOriginOrganizationIdValid__c evaluates to FALSE.
    LoggerSObjectHandler.shouldExecute(false);
    invalidOriginService.OriginOrganizationId__c = LoggerMockDataCreator.createId(Schema.LoginHistory.SObjectType);
    LoggerDataStore.getDatabase().updateRecord(invalidOriginService);
    LoggerSObjectHandler.shouldExecute(true);
    LoggerDataStore.getDatabase()
      .insertRecords(
        new List<LoggerNotificationRecipient__c>{
          new LoggerNotificationRecipient__c(
            LoggerNotificationRule__c = persistedRule.Id,
            LoggerNotificationService__c = enabledService.Id,
            IsEnabled__c = true
          ),
          new LoggerNotificationRecipient__c(
            LoggerNotificationRule__c = persistedRule.Id,
            LoggerNotificationService__c = enabledService.Id,
            IsEnabled__c = false
          ),
          new LoggerNotificationRecipient__c(
            LoggerNotificationRule__c = persistedRule.Id,
            LoggerNotificationService__c = disabledService.Id,
            IsEnabled__c = true
          ),
          new LoggerNotificationRecipient__c(
            LoggerNotificationRule__c = persistedRule.Id,
            LoggerNotificationService__c = invalidOriginService.Id,
            IsEnabled__c = true
          )
        }
      );
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);

    resetMockNotifier();
    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });
    System.Test.stopTest();

    System.Assert.areEqual(
      1,
      mockNotifierInvocationCount,
      'Only the enabled recipient pointing at the enabled + valid-origin service should receive the notification'
    );
  }

  @IsTest
  static void it_should_pass_only_matching_records_to_the_notifier() {
    LoggerNotificationRule__c rule = buildRule(
      'LogEntry__c',
      'ISPICKVAL(LoggingLevel__c, \'ERROR\')',
      new List<LoggerNotificationRecipient__c>{ buildRecipient() }
    );
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ rule });
    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();
    List<SObject> records = new List<SObject>{
      new LogEntry__c(LoggingLevel__c = 'ERROR'),
      new LogEntry__c(LoggingLevel__c = 'INFO'),
      new LogEntry__c(LoggingLevel__c = 'ERROR')
    };

    System.Test.startTest();
    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, records);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount);
    System.Assert.areEqual(2, mockNotifierLastRequest.matchingRecords.size());
    for (SObject match : mockNotifierLastRequest.matchingRecords) {
      System.Assert.areEqual('ERROR', ((LogEntry__c) match).LoggingLevel__c);
    }
  }

  @IsTest
  static void it_should_not_invoke_notifier_when_no_records_match() {
    LoggerNotificationRule__c rule = buildRule(
      'LogEntry__c',
      'ISPICKVAL(LoggingLevel__c, \'ERROR\')',
      new List<LoggerNotificationRecipient__c>{ buildRecipient() }
    );
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ rule });
    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();

    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'INFO') });

    System.Assert.areEqual(0, mockNotifierInvocationCount);
  }

  @IsTest
  static void it_should_swallow_exceptions_thrown_by_a_notifier() {
    LoggerNotificationRule__c rule = buildRule(
      'LogEntry__c',
      'ISPICKVAL(LoggingLevel__c, \'ERROR\')',
      new List<LoggerNotificationRecipient__c>{ buildRecipient(), buildRecipient() }
    );
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ rule });
    resetMockNotifier();
    mockNotifierShouldThrowNext = true;
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();

    System.Test.startTest();
    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') });
    System.Test.stopTest();

    System.Assert.areEqual(2, mockNotifierInvocationCount, 'Both recipients should have been invoked, including the one after the throw');
    System.Assert.areEqual(1, mockNotifierThrownCount, 'The first recipient should have thrown');
  }

  @IsTest
  static void it_should_skip_recipient_when_notifier_class_cannot_be_instantiated() {
    LoggerNotificationService__c serviceWithBadClass = buildService(true, true, 'NoSuchApexClassThatDoesNotExist');
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c();
    recipient.LoggerNotificationService__r = serviceWithBadClass;
    LoggerNotificationRule__c rule = buildRule('LogEntry__c', 'ISPICKVAL(LoggingLevel__c, \'ERROR\')', new List<LoggerNotificationRecipient__c>{ recipient });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ rule });
    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();

    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') });

    System.Assert.areEqual(0, mockNotifierInvocationCount);
  }

  @IsTest
  static void it_should_compute_cutoff_correctly_for_each_unit() {
    Datetime now = Datetime.newInstance(2026, 1, 15, 12, 0, 0);

    System.Assert.areEqual(now.addMinutes(-5), LoggerNotificationProcessor.computeCutoff(now, 5, 'Minutes'), 'Minutes cutoff should be exactly 5 minutes before now');
    System.Assert.areEqual(now.addHours(-2), LoggerNotificationProcessor.computeCutoff(now, 2, 'Hours'), 'Hours cutoff should be exactly 2 hours before now');
    System.Assert.areEqual(now.addDays(-1), LoggerNotificationProcessor.computeCutoff(now, 1, 'Days'), 'Days cutoff should be exactly 1 day before now');
    System.Assert.isNull(LoggerNotificationProcessor.computeCutoff(now, 5, 'Fortnights'), 'Unknown units should produce null');
  }

  @IsTest
  static void it_should_persist_matching_log_entries_for_logEntry_source_rules() {
    LoggerNotificationRule__c persistedRule = buildRule();
    LoggerDataStore.getDatabase().insertRecord(persistedRule);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LogEntry__c nonMatchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'INFO', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ matchingEntry, nonMatchingEntry });

    seedCachedRuleFromPersisted(persistedRule);
    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();

    System.Test.startTest();
    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry, nonMatchingEntry });
    System.Test.stopTest();

    List<LoggerNotificationMatch__c> matches = [
      SELECT Id, LogEntry__c, LoggerNotificationRule__c, MatchedRecordId__c, MatchedSObjectType__c
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :persistedRule.Id
    ];
    System.Assert.areEqual(1, matches.size(), 'Only the ERROR entry should be recorded as a match');
    System.Assert.areEqual(matchingEntry.Id, matches.get(0).LogEntry__c);
    System.Assert.areEqual(String.valueOf(matchingEntry.Id), matches.get(0).MatchedRecordId__c);
    System.Assert.areEqual('LogEntry__c', matches.get(0).MatchedSObjectType__c);
    System.Assert.areEqual(1, mockNotifierInvocationCount);
  }

  @IsTest
  static void it_should_suppress_dispatch_when_threshold_not_reached() {
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.IsMatchThresholdEnabled__c = true;
    persistedRule.MatchCountThreshold__c = 5;
    persistedRule.MatchThresholdTimePeriodIncrement__c = 60;
    persistedRule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(persistedRule);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);

    seedCachedRuleFromPersisted(persistedRule);
    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();

    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });

    System.Assert.areEqual(0, mockNotifierInvocationCount, 'Threshold of 5 with only 1 match should suppress dispatch');
  }

  @IsTest
  static void it_should_record_suppressed_by_threshold_delivery_rows_when_threshold_not_reached() {
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.IsMatchThresholdEnabled__c = true;
    persistedRule.MatchCountThreshold__c = 10;
    persistedRule.MatchThresholdTimePeriodIncrement__c = 60;
    persistedRule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c persistedRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = persistedRule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(persistedRecipient);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c firstEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LogEntry__c secondEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ firstEntry, secondEntry });

    LoggerNotificationRecipient__c hydratedRecipient = new LoggerNotificationRecipient__c(
      Id = persistedRecipient.Id,
      LoggerNotificationService__c = service.Id
    );
    hydratedRecipient.LoggerNotificationService__r = service;
    LoggerNotificationRule__c ruleCopy = persistedRule.clone(true, true, true, true);
    LoggerNotificationRule__c hydrated = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ hydratedRecipient });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ hydrated });

    resetMockNotifier();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ firstEntry, secondEntry });

    System.Assert.areEqual(0, mockNotifierInvocationCount, 'Threshold of 10 with 2 matches should suppress dispatch');
    List<LoggerNotificationMatch__c> matches = [SELECT Id FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :persistedRule.Id];
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
    System.Assert.areEqual(2, deliveries.size(), 'A suppressed-by-threshold delivery row should still be recorded per (match, recipient) tuple');
    for (LoggerNotificationDelivery__c delivery : deliveries) {
      System.Assert.areEqual(
        LoggerNotifierResult.STATUS_SUPPRESSED_BY_THRESHOLD,
        delivery.Status__c,
        'Suppressed rows should carry the SUPPRESSED_BY_THRESHOLD status'
      );
      System.Assert.areEqual(persistedRecipient.Id, delivery.LoggerNotificationRecipient__c, 'Delivery should point at the recipient it would have gone to');
      System.Assert.areEqual(service.Id, delivery.LoggerNotificationService__c, 'Delivery should denormalize the recipient service Id');
      System.Assert.areEqual(0, delivery.AttemptCount__c, 'Suppressed deliveries should not count as an attempt');
      System.Assert.isNull(delivery.DispatchTimestamp__c, 'Suppressed deliveries should not carry a dispatch timestamp');
      System.Assert.isNull(delivery.CompletedTimestamp__c, 'Suppressed deliveries should not carry a completed timestamp');
    }
  }

  @IsTest
  static void it_should_only_record_suppressed_deliveries_for_valid_recipients() {
    // Exercised end-to-end against the DB (no setCachedRules) so the runtime's SOQL subquery filter is
    // what drops disabled and cloned-in-from-another-org services before threshold suppression records
    // its "would have delivered here" rows.
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.IsMatchThresholdEnabled__c = true;
    persistedRule.MatchCountThreshold__c = 10;
    persistedRule.MatchThresholdTimePeriodIncrement__c = 60;
    persistedRule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    LoggerNotificationService__c enabledService = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c disabledService = buildService(false, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c invalidOriginService = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationService__c>{ enabledService, disabledService, invalidOriginService });
    LoggerSObjectHandler.shouldExecute(false);
    invalidOriginService.OriginOrganizationId__c = LoggerMockDataCreator.createId(Schema.LoginHistory.SObjectType);
    LoggerDataStore.getDatabase().updateRecord(invalidOriginService);
    LoggerSObjectHandler.shouldExecute(true);
    LoggerNotificationRecipient__c enabledRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = persistedRule.Id,
      LoggerNotificationService__c = enabledService.Id
    );
    LoggerDataStore.getDatabase()
      .insertRecords(
        new List<LoggerNotificationRecipient__c>{
          enabledRecipient,
          new LoggerNotificationRecipient__c(LoggerNotificationRule__c = persistedRule.Id, LoggerNotificationService__c = disabledService.Id),
          new LoggerNotificationRecipient__c(LoggerNotificationRule__c = persistedRule.Id, LoggerNotificationService__c = invalidOriginService.Id)
        }
      );

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);

    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });

    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT Id, Status__c, LoggerNotificationRecipient__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationMatch__r.LoggerNotificationRule__c = :persistedRule.Id
    ];
    System.Assert.areEqual(1, deliveries.size(), 'Only the enabled + valid-origin recipient should get a suppressed delivery row');
    System.Assert.areEqual(enabledRecipient.Id, deliveries.get(0).LoggerNotificationRecipient__c);
    System.Assert.areEqual(LoggerNotifierResult.STATUS_SUPPRESSED_BY_THRESHOLD, deliveries.get(0).Status__c);
  }

  @IsTest
  static void it_should_not_record_suppressed_deliveries_when_match_history_is_disabled() {
    // Validation rules block IsMatchHistoryEnabled__c=false alongside IsMatchThresholdEnabled__c=true, so
    // the persisted rule is legal but the hydrated cached copy toggles match history off - this proves the
    // runtime's guard on work.matches, independent of what the validation rules currently allow.
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.IsMatchThresholdEnabled__c = true;
    persistedRule.MatchCountThreshold__c = 5;
    persistedRule.MatchThresholdTimePeriodIncrement__c = 60;
    persistedRule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c persistedRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = persistedRule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(persistedRecipient);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);

    LoggerNotificationRecipient__c hydratedRecipient = new LoggerNotificationRecipient__c(
      Id = persistedRecipient.Id,
      LoggerNotificationService__c = service.Id
    );
    hydratedRecipient.LoggerNotificationService__r = service;
    LoggerNotificationRule__c ruleCopy = persistedRule.clone(true, true, true, true);
    ruleCopy.IsMatchHistoryEnabled__c = false;
    LoggerNotificationRule__c hydrated = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ hydratedRecipient });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ hydrated });

    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });

    Integer matchCount = [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :persistedRule.Id];
    System.Assert.areEqual(0, matchCount, 'Match rows should not be persisted when IsMatchHistoryEnabled__c is false');
    Integer deliveryCount = [SELECT COUNT() FROM LoggerNotificationDelivery__c WHERE LoggerNotificationRecipient__c = :persistedRecipient.Id];
    System.Assert.areEqual(
      0,
      deliveryCount,
      'Suppressed delivery rows require match rows to reference, so they must not be recorded when match history is disabled'
    );
  }

  @IsTest
  static void it_should_not_record_suppressed_deliveries_when_delivery_history_is_disabled() {
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.IsDeliveryHistoryEnabled__c = false;
    persistedRule.IsMatchThresholdEnabled__c = true;
    persistedRule.MatchCountThreshold__c = 5;
    persistedRule.MatchThresholdTimePeriodIncrement__c = 60;
    persistedRule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c persistedRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = persistedRule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(persistedRecipient);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);

    LoggerNotificationRecipient__c hydratedRecipient = new LoggerNotificationRecipient__c(
      Id = persistedRecipient.Id,
      LoggerNotificationService__c = service.Id
    );
    hydratedRecipient.LoggerNotificationService__r = service;
    LoggerNotificationRule__c ruleCopy = persistedRule.clone(true, true, true, true);
    LoggerNotificationRule__c hydrated = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ hydratedRecipient });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ hydrated });

    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ logEntry });

    Integer deliveryCount = [SELECT COUNT() FROM LoggerNotificationDelivery__c WHERE LoggerNotificationMatch__r.LoggerNotificationRule__c = :persistedRule.Id];
    System.Assert.areEqual(
      0,
      deliveryCount,
      'Delivery rows should not be recorded when IsDeliveryHistoryEnabled__c is false, even for suppressed-by-threshold outcomes'
    );
  }

  @IsTest
  static void it_should_route_every_recipient_through_the_async_dispatcher() {
    // Every notification goes through LoggerNotificationAsyncDispatcher - no notifier fires
    // synchronously inside the source trigger. This isolates notifier failures + callouts from
    // the record insert transaction and gives each notification its own governor budget.
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c();
    recipient.LoggerNotificationService__r = service;
    LoggerNotificationRule__c rule = buildRule('LogEntry__c', 'ISPICKVAL(LoggingLevel__c, \'ERROR\')', new List<LoggerNotificationRecipient__c>{ recipient });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ rule });
    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();

    System.Test.startTest();
    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') });
    System.Assert.areEqual(0, mockNotifierInvocationCount, 'Notifier should not fire synchronously - it should be queued');
    System.Assert.areEqual(1, System.Limits.getQueueableJobs(), 'One async dispatcher job should have been enqueued');
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount);
  }

  @IsTest
  static void it_should_batch_multiple_recipients_into_a_single_queueable() {
    LoggerNotificationService__c serviceA = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c serviceB = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationRecipient__c recipientA = new LoggerNotificationRecipient__c();
    recipientA.LoggerNotificationService__r = serviceA;
    LoggerNotificationRecipient__c recipientB = new LoggerNotificationRecipient__c();
    recipientB.LoggerNotificationService__r = serviceB;
    LoggerNotificationRule__c rule = buildRule(
      'LogEntry__c',
      'ISPICKVAL(LoggingLevel__c, \'ERROR\')',
      new List<LoggerNotificationRecipient__c>{ recipientA, recipientB }
    );
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ rule });
    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();

    System.Test.startTest();
    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') });
    System.Assert.areEqual(1, System.Limits.getQueueableJobs(), 'Both recipients should have been batched into one Queueable job');
    System.Test.stopTest();

    System.Assert.areEqual(2, mockNotifierInvocationCount);
  }

  @IsTest
  static void it_should_dispatch_when_threshold_reached_via_current_batch() {
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.IsMatchThresholdEnabled__c = true;
    persistedRule.MatchCountThreshold__c = 3;
    persistedRule.MatchThresholdTimePeriodIncrement__c = 60;
    persistedRule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(persistedRule);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    List<LogEntry__c> entries = new List<LogEntry__c>{
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now()),
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now()),
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now())
    };
    LoggerDataStore.getDatabase().insertRecords(entries);

    seedCachedRuleFromPersisted(persistedRule);
    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();

    System.Test.startTest();
    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, entries);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount, 'Threshold of 3 with 3 matches should dispatch once');
    System.Assert.areEqual(3, mockNotifierLastRequest.matchingRecords.size());
  }

  @IsTest
  static void it_should_emit_one_delivery_row_per_recipient_when_a_rule_has_multiple_recipients() {
    LoggerNotificationRule__c persistedRule = buildRule();
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    LoggerNotificationService__c serviceOne = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c serviceTwo = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationService__c>{ serviceOne, serviceTwo });

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    LoggerNotificationRecipient__c persistedRecipientOne = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = persistedRule.Id,
      LoggerNotificationService__c = serviceOne.Id
    );
    LoggerNotificationRecipient__c persistedRecipientTwo = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = persistedRule.Id,
      LoggerNotificationService__c = serviceTwo.Id
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationRecipient__c>{ persistedRecipientOne, persistedRecipientTwo });

    LoggerNotificationRecipient__c hydratedRecipientOne = new LoggerNotificationRecipient__c(
      Id = persistedRecipientOne.Id,
      LoggerNotificationService__c = serviceOne.Id
    );
    hydratedRecipientOne.LoggerNotificationService__r = serviceOne;
    LoggerNotificationRecipient__c hydratedRecipientTwo = new LoggerNotificationRecipient__c(
      Id = persistedRecipientTwo.Id,
      LoggerNotificationService__c = serviceTwo.Id
    );
    hydratedRecipientTwo.LoggerNotificationService__r = serviceTwo;
    LoggerNotificationRule__c ruleCopy = persistedRule.clone(true, true, true, true);
    LoggerNotificationRule__c hydrated = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ hydratedRecipientOne, hydratedRecipientTwo });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ hydrated });

    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();
    System.Test.startTest();
    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });
    System.Test.stopTest();

    List<LoggerNotificationMatch__c> matches = [
      SELECT Id, MatchedRecordId__c
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :persistedRule.Id
    ];
    System.Assert.areEqual(1, matches.size(), 'Match rows are now one-per-matched-record (not per recipient)');
    System.Assert.areEqual(String.valueOf(matchingEntry.Id), matches.get(0).MatchedRecordId__c);

    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT LoggerNotificationMatch__c, LoggerNotificationRecipient__c, LoggerNotificationService__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationMatch__c = :matches.get(0).Id
    ];
    System.Assert.areEqual(2, deliveries.size(), 'One delivery row per recipient - two recipients means two delivery rows for the one match');
    Set<Id> deliveryRecipientIds = new Set<Id>();
    Set<Id> deliveryServiceIds = new Set<Id>();
    for (LoggerNotificationDelivery__c row : deliveries) {
      deliveryRecipientIds.add(row.LoggerNotificationRecipient__c);
      deliveryServiceIds.add(row.LoggerNotificationService__c);
    }
    System.Assert.areEqual(
      new Set<Id>{ persistedRecipientOne.Id, persistedRecipientTwo.Id },
      deliveryRecipientIds,
      'Each recipient should have its own delivery row'
    );
    System.Assert.areEqual(
      new Set<Id>{ serviceOne.Id, serviceTwo.Id },
      deliveryServiceIds,
      'The denormalized service field should also be set on each delivery row'
    );
    System.Assert.areEqual(2, mockNotifierInvocationCount, 'Both recipients should have received the notification');
  }

  @IsTest
  static void it_should_skip_match_persistence_when_match_history_is_disabled() {
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.IsMatchHistoryEnabled__c = false;
    persistedRule.IsDeliveryHistoryEnabled__c = false;
    LoggerDataStore.getDatabase().insertRecord(persistedRule);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    seedCachedRuleFromPersisted(persistedRule);
    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();
    System.Test.startTest();
    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });
    System.Test.stopTest();

    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :persistedRule.Id]);
    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerNotificationDelivery__c]);
    System.Assert.areEqual(1, mockNotifierInvocationCount, 'Dispatch should still fire even when history storage is off');
  }

  @IsTest
  static void it_should_skip_delivery_persistence_when_delivery_history_is_disabled_but_still_persist_matches() {
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.IsDeliveryHistoryEnabled__c = false;
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c persistedRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = persistedRule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(persistedRecipient);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    LoggerNotificationRecipient__c hydrated = new LoggerNotificationRecipient__c(Id = persistedRecipient.Id, LoggerNotificationService__c = service.Id);
    hydrated.LoggerNotificationService__r = service;
    LoggerNotificationRule__c ruleCopy = persistedRule.clone(true, true, true, true);
    LoggerNotificationRule__c hydratedRule = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ hydrated });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ hydratedRule });

    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();
    System.Test.startTest();
    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });
    System.Test.stopTest();

    System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :persistedRule.Id]);
    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerNotificationDelivery__c]);
    System.Assert.areEqual(1, mockNotifierInvocationCount, 'Dispatch should still fire when delivery history is off');
  }

  @IsTest
  static void it_should_count_matches_for_threshold_naturally_deduplicated() {
    // Match rows are now one-per-matched-record (not per recipient), so a plain COUNT(Id) is
    // already deduplicated. Two recipients pointing at the same rule should not inflate the count.
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.IsMatchThresholdEnabled__c = true;
    persistedRule.MatchCountThreshold__c = 2;
    persistedRule.MatchThresholdTimePeriodIncrement__c = 60;
    persistedRule.MatchThresholdTimePeriodUnit__c = 'Minutes';
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    LoggerNotificationService__c serviceOne = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationService__c serviceTwo = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationService__c>{ serviceOne, serviceTwo });
    LoggerNotificationRecipient__c persistedRecipientOne = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = persistedRule.Id,
      LoggerNotificationService__c = serviceOne.Id
    );
    LoggerNotificationRecipient__c persistedRecipientTwo = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = persistedRule.Id,
      LoggerNotificationService__c = serviceTwo.Id
    );
    LoggerDataStore.getDatabase().insertRecords(new List<LoggerNotificationRecipient__c>{ persistedRecipientOne, persistedRecipientTwo });

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c priorEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LogEntry__c currentEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ priorEntry, currentEntry });
    LoggerDataStore.getDatabase()
      .insertRecord(
        new LoggerNotificationMatch__c(
          LoggerNotificationRule__c = persistedRule.Id,
          LogEntry__c = priorEntry.Id,
          MatchedRecordId__c = String.valueOf(priorEntry.Id),
          MatchedSObjectType__c = 'LogEntry__c'
        )
      );

    LoggerNotificationRecipient__c hydratedOne = new LoggerNotificationRecipient__c(
      Id = persistedRecipientOne.Id,
      LoggerNotificationService__c = serviceOne.Id
    );
    hydratedOne.LoggerNotificationService__r = serviceOne;
    LoggerNotificationRecipient__c hydratedTwo = new LoggerNotificationRecipient__c(
      Id = persistedRecipientTwo.Id,
      LoggerNotificationService__c = serviceTwo.Id
    );
    hydratedTwo.LoggerNotificationService__r = serviceTwo;
    LoggerNotificationRule__c ruleCopy = persistedRule.clone(true, true, true, true);
    LoggerNotificationRule__c hydrated = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ hydratedOne, hydratedTwo });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ hydrated });

    resetMockNotifier();
    LoggerNotificationProcessor notifier = new LoggerNotificationProcessor();
    System.Test.startTest();
    notifier.sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ currentEntry });
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
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    resetMockNotifier();
    // Let the runtime query real rules from the DB - do NOT call setCachedRules here, so the WHERE clause matters.
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });

    Set<Id> ruleIds = new Set<Id>{ ruleWithNoRecipients.Id, ruleWithDisabledRecipient.Id };
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c IN :ruleIds],
      'Rules with zero enabled recipients should be skipped before any match rows are inserted'
    );
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM LoggerNotificationDelivery__c WHERE LoggerNotificationRule__c IN :ruleIds],
      'Rules with zero enabled recipients should not produce delivery rows'
    );
    System.Assert.areEqual(0, mockNotifierInvocationCount, 'Dispatch should not fire for rules with zero enabled recipients');
  }

  @IsTest
  static void it_should_stamp_the_notification_lookup_on_delivery_rows() {
    LoggerNotificationRule__c persistedRule = buildRule();
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c persistedRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = persistedRule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(persistedRecipient);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    LoggerNotificationRecipient__c hydrated = new LoggerNotificationRecipient__c(Id = persistedRecipient.Id, LoggerNotificationService__c = service.Id);
    hydrated.LoggerNotificationService__r = service;
    LoggerNotificationRule__c ruleCopy = persistedRule.clone(true, true, true, true);
    LoggerNotificationRule__c hydratedRule = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ hydrated });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ hydratedRule });

    resetMockNotifier();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });

    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT LoggerNotificationRule__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationRecipient__c = :persistedRecipient.Id
    ];
    System.Assert.areEqual(1, deliveries.size());
    System.Assert.areEqual(
      persistedRule.Id,
      deliveries.get(0).LoggerNotificationRule__c,
      'Delivery rows should carry the denormalized rule Id for report/list-view filtering'
    );
  }

  @IsTest
  static void it_should_deduplicate_matching_records_by_the_rule_deduplication_source_field() {
    Log__c logA = new Log__c(TransactionId__c = 'log-a');
    Log__c logB = new Log__c(TransactionId__c = 'log-b');
    LoggerDataStore.getDatabase().insertRecords(new List<Log__c>{ logA, logB });
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.DeduplicationSourceField__c = 'Log__c';
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    List<LogEntry__c> entries = new List<LogEntry__c>{
      new LogEntry__c(Log__c = logA.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now()),
      new LogEntry__c(Log__c = logA.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now()),
      new LogEntry__c(Log__c = logA.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now()),
      new LogEntry__c(Log__c = logB.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now())
    };
    LoggerDataStore.getDatabase().insertRecords(entries);

    seedCachedRuleFromPersisted(persistedRule);
    resetMockNotifier();
    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, entries);
    System.Test.stopTest();

    Integer matchCount = [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :persistedRule.Id];
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
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.DeduplicationSourceField__c = 'Log__c';
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    LogEntry__c firstEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now(), Message__c = 'first');
    LogEntry__c secondEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now(), Message__c = 'second');
    LoggerDataStore.getDatabase().insertRecords(new List<LogEntry__c>{ firstEntry, secondEntry });

    seedCachedRuleFromPersisted(persistedRule);
    resetMockNotifier();
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
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.DeduplicationSourceField__c = null;
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    List<LogEntry__c> entries = new List<LogEntry__c>{
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now()),
      new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now())
    };
    LoggerDataStore.getDatabase().insertRecords(entries);

    seedCachedRuleFromPersisted(persistedRule);
    resetMockNotifier();
    System.Test.startTest();
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, entries);
    System.Test.stopTest();

    System.Assert.areEqual(2, [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :persistedRule.Id]);
    System.Assert.areEqual(2, mockNotifierLastRequest.matchingRecords.size());
  }

  @IsTest
  static void it_should_treat_null_deduplicate_values_as_their_own_group() {
    // Two records with the same non-null deduplication value collapse to one; a record with a null value
    // survives in its own group.
    List<SObject> matching = new List<SObject>{
      new LogEntry__c(Log__c = null, LoggingLevel__c = 'ERROR'),
      new LogEntry__c(Log__c = null, LoggingLevel__c = 'ERROR')
    };

    List<SObject> result = LoggerNotificationProcessor.deduplicateMatchingRecords(matching, 'Log__c');

    System.Assert.areEqual(1, result.size(), 'Two null-deduplication-value records should collapse to one group keyed on the null sentinel');
  }

  @IsTest
  static void it_should_not_deduplicate_when_the_deduplication_source_field_does_not_exist_on_the_source_sobject() {
    // Fallback path: an admin somehow saved a bogus field name that snuck past validation. Rather than
    // throw at runtime, the runtime treats it as "no deduplication" so notifications still fire.
    List<SObject> matching = new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR'), new LogEntry__c(LoggingLevel__c = 'ERROR') };

    List<SObject> result = LoggerNotificationProcessor.deduplicateMatchingRecords(matching, 'ThisFieldDoesNotExist__c');

    System.Assert.areEqual(2, result.size(), 'Unknown deduplication field should fall through without collapsing records');
  }

  @IsTest
  static void it_should_stamp_match_and_delivery_retention_dates_independently_from_the_rules_two_retention_fields() {
    // Match rows stamp RetentionDate__c from NumberOfDaysToRetainMatches__c; delivery rows stamp
    // from NumberOfDaysToRetainDeliveries__c. The two values can differ (subject to the handler's
    // "deliveries <= matches" constraint), so the runtime has to read the right field for each row
    // rather than sharing a single value.
    Integer matchRetentionDays = 30;
    Integer deliveryRetentionDays = 7;
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.NumberOfDaysToRetainMatches__c = matchRetentionDays;
    persistedRule.NumberOfDaysToRetainDeliveries__c = deliveryRetentionDays;
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c persistedRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = persistedRule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(persistedRecipient);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    LoggerNotificationRecipient__c hydrated = new LoggerNotificationRecipient__c(Id = persistedRecipient.Id, LoggerNotificationService__c = service.Id);
    hydrated.LoggerNotificationService__r = service;
    LoggerNotificationRule__c ruleCopy = persistedRule.clone(true, true, true, true);
    LoggerNotificationRule__c hydratedRule = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ hydrated });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ hydratedRule });

    Date expectedMatchRetentionDate = System.today().addDays(matchRetentionDays);
    Date expectedDeliveryRetentionDate = System.today().addDays(deliveryRetentionDays);
    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });

    List<LoggerNotificationMatch__c> matches = [
      SELECT Id, RetentionDate__c
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :persistedRule.Id
    ];
    System.Assert.areEqual(1, matches.size());
    System.Assert.areEqual(
      expectedMatchRetentionDate,
      matches.get(0).RetentionDate__c,
      'Match rows should stamp RetentionDate__c from NumberOfDaysToRetainMatches__c'
    );
    List<LoggerNotificationDelivery__c> deliveries = [
      SELECT Id, RetentionDate__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationRecipient__c = :persistedRecipient.Id
    ];
    System.Assert.areEqual(1, deliveries.size());
    System.Assert.areEqual(
      expectedDeliveryRetentionDate,
      deliveries.get(0).RetentionDate__c,
      'Delivery rows should stamp RetentionDate__c from NumberOfDaysToRetainDeliveries__c'
    );
  }

  @IsTest
  static void it_should_leave_retention_date_null_when_the_rules_retention_days_is_null_or_non_positive() {
    // Null / zero / negative retention on either field means "keep that object's rows forever" -
    // the runtime stamps RetentionDate__c as null and LogBatchPurger's WHERE clause skips rows
    // without a retention date. Test with both fields null so we exercise both stamping paths.
    LoggerNotificationRule__c persistedRule = buildRule();
    persistedRule.NumberOfDaysToRetainMatches__c = null;
    persistedRule.NumberOfDaysToRetainDeliveries__c = null;
    LoggerDataStore.getDatabase().insertRecord(persistedRule);
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c persistedRecipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = persistedRule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(persistedRecipient);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c matchingEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(matchingEntry);

    LoggerNotificationRecipient__c hydrated = new LoggerNotificationRecipient__c(Id = persistedRecipient.Id, LoggerNotificationService__c = service.Id);
    hydrated.LoggerNotificationService__r = service;
    LoggerNotificationRule__c ruleCopy = persistedRule.clone(true, true, true, true);
    LoggerNotificationRule__c hydratedRule = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ hydrated });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ hydratedRule });

    new LoggerNotificationProcessor().sendNotifications(Schema.LogEntry__c.SObjectType, new List<SObject>{ matchingEntry });

    LoggerNotificationMatch__c match = [
      SELECT Id, RetentionDate__c
      FROM LoggerNotificationMatch__c
      WHERE LoggerNotificationRule__c = :persistedRule.Id
      LIMIT 1
    ];
    System.Assert.isNull(match.RetentionDate__c, 'Null NumberOfDaysToRetainMatches__c should leave the match row untouched by LogBatchPurger');
    LoggerNotificationDelivery__c delivery = [
      SELECT Id, RetentionDate__c
      FROM LoggerNotificationDelivery__c
      WHERE LoggerNotificationRecipient__c = :persistedRecipient.Id
      LIMIT 1
    ];
    System.Assert.isNull(delivery.RetentionDate__c, 'Null NumberOfDaysToRetainDeliveries__c should leave the delivery row untouched by LogBatchPurger');
  }

  @IsTest
  static void it_should_stamp_the_queueable_job_id_from_the_result_onto_delivery_rows_that_have_none_yet() {
    Id fakeJobId = LoggerMockDataCreator.createId(Schema.AsyncApexJob.SObjectType);
    List<LoggerNotificationDelivery__c> deliveries = new List<LoggerNotificationDelivery__c>{
      new LoggerNotificationDelivery__c(),
      new LoggerNotificationDelivery__c()
    };
    LoggerNotifierResult result = new LoggerNotifierResult(LoggerNotifierResult.STATUS_DELIVERED, null);
    result.jobId = fakeJobId;
    Datetime dispatchStart = System.now();
    Datetime dispatchEnd = dispatchStart.addSeconds(1);

    LoggerNotificationProcessor.applyResultToDeliveries(deliveries, result, dispatchStart, dispatchEnd);

    for (LoggerNotificationDelivery__c delivery : deliveries) {
      System.Assert.areEqual(fakeJobId, delivery.JobId__c, 'JobId__c should have been stamped on delivery rows that had none: ' + delivery);
    }
  }

  @IsTest
  static void it_should_not_overwrite_an_existing_job_id_on_a_delivery_row() {
    // Preserving the first-attempt job id is the whole point of the "only when blank" guard - a re-enqueue
    // after a callout-limit exhaustion runs in a different Queueable job, but the first-attempt job id is
    // the one admins want to correlate to Apex Jobs / logs.
    Id firstJobId = LoggerMockDataCreator.createId(Schema.AsyncApexJob.SObjectType);
    Id secondJobId = LoggerMockDataCreator.createId(Schema.AsyncApexJob.SObjectType);
    LoggerNotificationDelivery__c delivery = new LoggerNotificationDelivery__c(JobId__c = firstJobId);
    LoggerNotifierResult result = new LoggerNotifierResult(LoggerNotifierResult.STATUS_DELIVERED, null);
    result.jobId = secondJobId;
    Datetime dispatchStart = System.now();

    LoggerNotificationProcessor.applyResultToDeliveries(new List<LoggerNotificationDelivery__c>{ delivery }, result, dispatchStart, dispatchStart);

    System.Assert.areEqual(firstJobId, delivery.JobId__c, 'First-attempt job id should not be overwritten by a re-enqueue');
  }

  @IsTest
  static void it_should_leave_job_id_null_when_the_result_carries_no_job_id() {
    LoggerNotificationDelivery__c delivery = new LoggerNotificationDelivery__c();
    LoggerNotifierResult result = new LoggerNotifierResult(LoggerNotifierResult.STATUS_DELIVERED, null);
    Datetime dispatchStart = System.now();

    LoggerNotificationProcessor.applyResultToDeliveries(new List<LoggerNotificationDelivery__c>{ delivery }, result, dispatchStart, dispatchStart);

    System.Assert.isNull(delivery.JobId__c, 'JobId__c should stay null when the result carries no jobId');
  }

  // Test helpers

  private static LoggerNotificationRule__c buildRule(String sourceSObjectTypeName, String filter, List<LoggerNotificationRecipient__c> recipients) {
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(
      Name = 'Test rule',
      SourceSObjectType__c = sourceSObjectTypeName,
      SourceSObjectFilter__c = filter,
      IsEnabled__c = true
    );
    return attachRecipients(rule, recipients);
  }

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

  private static LoggerNotificationRule__c buildRule() {
    LoggerNotificationRule__c persistedRule = (LoggerNotificationRule__c) LoggerMockDataCreator.createDataBuilder(Schema.LoggerNotificationRule__c.SObjectType)
      .populateRequiredFields()
      .getRecord();
    persistedRule.SourceSObjectType__c = 'LogEntry__c';
    persistedRule.SourceSObjectFilter__c = 'ISPICKVAL(LoggingLevel__c, \'ERROR\')';
    persistedRule.IsEnabled__c = true;
    // Reset the inverted-boolean values that LoggerMockDataCreator produces, so we don't trip validation rules.
    persistedRule.IsMatchHistoryEnabled__c = true;
    persistedRule.IsDeliveryHistoryEnabled__c = true;
    persistedRule.IsMatchThresholdEnabled__c = false;
    return persistedRule;
  }

  private static void seedCachedRuleFromPersisted(LoggerNotificationRule__c persistedRule) {
    LoggerNotificationService__c service = buildService(true, true, MOCK_NOTIFIER_CLASS);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c();
    recipient.LoggerNotificationService__r = service;
    LoggerNotificationRule__c ruleCopy = persistedRule.clone(true, true, true, true);
    LoggerNotificationRule__c hydrated = attachRecipients(ruleCopy, new List<LoggerNotificationRecipient__c>{ recipient });
    LoggerNotificationProcessor.setCachedRules(new List<LoggerNotificationRule__c>{ hydrated });
  }

  private static LoggerNotificationRecipient__c buildRecipient() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c();
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

  public class MockNotifier implements LoggerNotifier {
    public LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
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
