//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount, PMD.NcssTypeCount')
@IsTest(IsParallel=false)
private class LogEntryEventHandler_Tests {
    @IsTest
    static void it_should_return_the_logEntryEvent_sobjectType() {
        System.Assert.areEqual(Schema.LogEntryEvent__e.SObjectType, new LogEntryEventHandler().getSObjectType());
    }

    @IsTest
    static void it_should_not_run_when_disabled_via_configuration() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntryEvent__e.SObjectType).IsEnabled__c = false;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();

        LoggerDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.areEqual(
            0,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should not have executed'
        );
    }

    @IsTest
    static void it_should_gracefully_skip_execution_when_logEntryEvents_list_is_empty() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        Integer countOfLogs = [SELECT COUNT() FROM Log__c];
        System.Assert.areEqual(0, countOfLogs);
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);

        List<Database.SaveResult> saveResults = LoggerMockDataStore.getEventBus().publishRecords(new List<LogEntryEvent__e>());
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResults.isEmpty());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        countOfLogs = [SELECT COUNT() FROM Log__c];
        System.Assert.areEqual(0, countOfLogs);
        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);
    }

    @IsTest
    static void it_should_not_create_log_entry_data_when_platform_event_storage_logging_level_is_not_met() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.Assert.areEqual(0, [SELECT COUNT() FROM Log__c]);
        System.Assert.areEqual(0, [SELECT COUNT() FROM LogEntry__c]);
        System.LoggingLevel targetEventLoggingLevel = System.LoggingLevel.DEBUG;
        System.LoggingLevel targetStorageLoggingLevel = System.LoggingLevel.INFO;
        System.Assert.isTrue(
            targetEventLoggingLevel.ordinal() < targetStorageLoggingLevel.ordinal(),
            'Test started under the wrong conditions, targetEventLoggingLevel ordinal should be less than the targetStorageLoggingLevel ordinal'
        );
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.LoggingLevel__c = targetEventLoggingLevel.name();
        settings.DefaultPlatformEventStorageLoggingLevel__c = System.LoggingLevel.INFO.name();
        upsert settings;
        LogEntryEvent__e matchingLogEntryEvent = createLogEntryEvent();
        matchingLogEntryEvent.LoggingLevel__c = settings.DefaultPlatformEventStorageLoggingLevel__c;
        matchingLogEntryEvent.Message__c = 'This event should be saved in LogEntry__c';
        LogEntryEvent__e nonMatchingLogEntryEvent = createLogEntryEvent();
        nonMatchingLogEntryEvent.LoggingLevel__c = System.LoggingLevel.DEBUG.name();
        nonMatchingLogEntryEvent.Message__c = 'This event should NOT be saved in LogEntry__c';
        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>{ matchingLogEntryEvent, nonMatchingLogEntryEvent };

        List<Database.SaveResult> saveResults = LoggerMockDataStore.getEventBus().publishRecords(logEntryEvents);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.areEqual(logEntryEvents.size(), saveResults.size());
        for (Database.SaveResult saveResult : saveResults) {
            System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        }
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        System.Assert.areEqual(1, [SELECT COUNT() FROM Log__c]);
        List<LogEntry__c> logEntries = [SELECT Id, LoggingLevel__c, Message__c FROM LogEntry__c];
        System.Assert.areEqual(1, logEntries.size(), JSON.serializePretty(logEntries));
        System.Assert.areEqual(matchingLogEntryEvent.LoggingLevel__c, logEntries.get(0).LoggingLevel__c);
        System.Assert.areEqual(matchingLogEntryEvent.Message__c, logEntries.get(0).Message__c);
    }

    @IsTest
    static void it_should_not_create_log_or_log_entry_data_when_platform_event_storage_location_is_null_in_logger_settings() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        Integer countOfLogs = [SELECT COUNT() FROM Log__c];
        System.Assert.areEqual(0, countOfLogs);
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.IsEnabled__c = true;
        settings.IsSavingEnabled__c = true;
        settings.DefaultPlatformEventStorageLocation__c = null;
        upsert settings;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        countOfLogs = [SELECT COUNT() FROM Log__c];
        System.Assert.areEqual(0, countOfLogs);
        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);
    }

    @IsTest
    static void it_should_not_create_log_or_log_entry_data_when_platform_event_storage_location_is_null_in_logger_scenario_rule() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        Integer countOfLogs = [SELECT COUNT() FROM Log__c];
        System.Assert.areEqual(0, countOfLogs);
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.IsEnabled__c = true;
        settings.IsSavingEnabled__c = true;
        settings.DefaultPlatformEventStorageLocation__c = LogEntryEventHandler.DEFAULT_STORAGE_LOCATION_NAME;
        upsert settings;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.TransactionScenario__c = 'some scenario with a configured rule';
        LoggerScenarioRule.setMock(
            new LoggerScenarioRule__mdt(
                IsEnabled__c = true,
                IsPlatformEventStorageLocationEnabled__c = String.valueOf(true),
                PlatformEventStorageLocation__c = null,
                Scenario__c = logEntryEvent.TransactionScenario__c
            )
        );

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        countOfLogs = [SELECT COUNT() FROM Log__c];
        System.Assert.areEqual(0, countOfLogs);
        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);
    }

    @IsTest
    static void it_should_normalize_event_data_into_log_and_log_entry_when_no_scenario_specified() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.TransactionScenario__c = null;

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.Assert.isNull(log.TransactionScenario__c);
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @IsTest
    static void it_should_normalize_event_data_for_multiple_transactions_into_multiple_logs() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        List<String> transactionIds = new List<String>{ '123-456', '789-0' };
        System.Assert.areEqual(2, transactionIds.size());
        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        for (Integer i = 0; i < transactionIds.size(); i++) {
            LogEntryEvent__e logEntryEvent = createLogEntryEvent();
            logEntryEvent.TransactionEntryNumber__c = i;
            logEntryEvent.TransactionId__c = transactionIds.get(i);
            logEntryEvents.add(logEntryEvent);
        }
        System.Assert.areEqual(transactionIds.size(), logEntryEvents.size());

        List<Database.SaveResult> saveResults = LoggerMockDataStore.getEventBus().publishRecords(logEntryEvents);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.areEqual(transactionIds.size(), saveResults.size());
        for (Database.SaveResult saveResult : saveResults) {
            System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        }
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        List<Log__c> logs = [SELECT Id, TransactionId__c, (SELECT Id FROM LogEntries__r) FROM Log__c];
        System.Assert.areEqual(2, logs.size(), JSON.serializePretty(logs));
        Set<String> uniqueTransactionIds = new Set<String>(transactionIds);
        for (Log__c log : logs) {
            System.Assert.isTrue(uniqueTransactionIds.contains(log.TransactionId__c), log.TransactionId__c);
            System.Assert.areEqual(1, log.LogEntries__r.size());
        }
    }

    @IsTest
    static void it_should_normalize_event_data_into_logger_scenario_and_log_and_log_entry_when_scenario_specified() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.EntryScenario__c = null;
        logEntryEvent.TransactionScenario__c = '0'.repeat(Schema.LogEntryEvent__e.Scenario__c.getDescribe().getLength());

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerScenario__c]);
        Log__c log = getLog();
        System.Assert.isNotNull(log.TransactionScenario__c);
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @IsTest
    static void it_should_not_normalize_scenario_data_when_data_normalization_is_disabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.EntryScenario__c = 'some entry scenario';
        logEntryEvent.TransactionScenario__c = 'some transaction scenario';
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'NormalizeScenarioData', Value__c = JSON.serialize(false)));
        System.Assert.isFalse(LoggerParameter.NORMALIZE_SCENARIO_DATA);

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerScenario__c]);
        Log__c log = getLog();
        System.Assert.isNull(log.TransactionScenario__c);
        System.Assert.areEqual(logEntryEvent.TransactionScenario__c, log.TransactionScenarioName__c);
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.isNull(logEntry.EntryScenario__c);
        System.Assert.areEqual(logEntryEvent.EntryScenario__c, logEntry.EntryScenarioName__c);
    }

    @IsTest
    static void it_should_upsert_logger_scenarios_when_transaction_scenario_specified() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        LoggerScenario__c existingLogScenario = new LoggerScenario__c(UniqueId__c = 'hello, world');
        insert existingLogScenario;
        System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerScenario__c]);
        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        for (Integer i = 0; i < 2; i++) {
            LogEntryEvent__e logEntryEvent = createLogEntryEvent();
            logEntryEvent.TransactionEntryNumber__c = i;
            logEntryEvent.TransactionId__c = '123-456';
            logEntryEvent.EntryScenario__c = null;
            logEntryEvent.TransactionScenario__c = existingLogScenario.UniqueId__c;
            logEntryEvents.add(logEntryEvent);
        }

        List<Database.SaveResult> saveResults = LoggerMockDataStore.getEventBus().publishRecords(logEntryEvents);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.areEqual(logEntryEvents.size(), saveResults.size());
        for (Database.SaveResult saveResult : saveResults) {
            System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        }
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerScenario__c]);
        Log__c log = getLog();
        System.Assert.areEqual(existingLogScenario.Id, log.TransactionScenario__c);
        System.Assert.areEqual(logEntryEvents.size(), log.LogEntries__r.size());
        for (Integer i = 0; i < logEntryEvents.size(); i++) {
            LogEntryEvent__e logEntryEvent = logEntryEvents.get(i);
            LogEntry__c logEntry = log.LogEntries__r.get(i);
            System.Assert.areEqual(logEntryEvent.TransactionScenario__c, log.TransactionScenario__r.UniqueId__c);
            validateLogFields(logEntryEvent, log);
            validateLogEntryFields(logEntryEvent, logEntry);
        }
    }

    @IsTest
    static void it_should_upsert_logger_scenarios_when_entry_scenario_specified() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        LoggerScenario__c existingLoggerScenario = new LoggerScenario__c(UniqueId__c = 'hello, world');
        insert existingLoggerScenario;
        String newScenario = 'some new value';
        System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerScenario__c]);
        LogEntryEvent__e firstLogEntryEvent = createLogEntryEvent();
        firstLogEntryEvent.TransactionEntryNumber__c = 1;
        firstLogEntryEvent.EntryScenario__c = existingLoggerScenario.UniqueId__c;
        firstLogEntryEvent.TransactionScenario__c = null;
        LogEntryEvent__e secondLogEntryEvent = createLogEntryEvent();
        secondLogEntryEvent.TransactionEntryNumber__c = 2;
        secondLogEntryEvent.EntryScenario__c = newScenario;
        secondLogEntryEvent.TransactionScenario__c = null;
        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>{ firstLogEntryEvent, secondLogEntryEvent };

        List<Database.SaveResult> saveResults = LoggerMockDataStore.getEventBus().publishRecords(logEntryEvents);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.areEqual(logEntryEvents.size(), saveResults.size());
        for (Database.SaveResult saveResult : saveResults) {
            System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        }
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        System.Assert.areEqual(2, [SELECT COUNT() FROM LoggerScenario__c]);
        Log__c log = getLog();
        System.Assert.areEqual(logEntryEvents.size(), log.LogEntries__r.size());
        for (Integer i = 0; i < logEntryEvents.size(); i++) {
            LogEntryEvent__e logEntryEvent = logEntryEvents.get(i);
            LogEntry__c logEntry = log.LogEntries__r.get(i);
            System.Assert.areEqual(logEntryEvent.EntryScenario__c, logEntry.EntryScenario__r.UniqueId__c);
            validateLogFields(logEntryEvent, log);
            validateLogEntryFields(logEntryEvent, logEntry);
        }
    }

    @IsTest
    static void it_should_upsert_logger_scenarios_when_transaction_and_entry_scenarios_specified() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        LoggerScenario__c existingLoggerScenario = new LoggerScenario__c(UniqueId__c = 'hello, world');
        insert existingLoggerScenario;
        String newTransactionScenario = 'some new value';
        String newEntryScenario = 'some OTHER new value';
        System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerScenario__c]);
        LogEntryEvent__e firstLogEntryEvent = createLogEntryEvent();
        firstLogEntryEvent.EntryScenario__c = existingLoggerScenario.UniqueId__c;
        firstLogEntryEvent.TransactionEntryNumber__c = 1;
        firstLogEntryEvent.TransactionScenario__c = newTransactionScenario;
        LogEntryEvent__e secondLogEntryEvent = createLogEntryEvent();
        secondLogEntryEvent.TransactionEntryNumber__c = 2;
        secondLogEntryEvent.EntryScenario__c = newEntryScenario;
        secondLogEntryEvent.TransactionScenario__c = newTransactionScenario;
        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>{ firstLogEntryEvent, secondLogEntryEvent };

        List<Database.SaveResult> saveResults = LoggerMockDataStore.getEventBus().publishRecords(logEntryEvents);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.areEqual(logEntryEvents.size(), saveResults.size());
        for (Database.SaveResult saveResult : saveResults) {
            System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        }
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        System.Assert.areEqual(3, [SELECT COUNT() FROM LoggerScenario__c]);
        Log__c log = getLog();
        System.Assert.areEqual(logEntryEvents.size(), log.LogEntries__r.size());
        for (Integer i = 0; i < logEntryEvents.size(); i++) {
            LogEntryEvent__e logEntryEvent = logEntryEvents.get(i);
            LogEntry__c logEntry = log.LogEntries__r.get(i);
            System.Assert.areEqual(logEntryEvent.TransactionScenario__c, log.TransactionScenario__r.UniqueId__c);
            System.Assert.areEqual(logEntryEvent.EntryScenario__c, logEntry.EntryScenario__r.UniqueId__c);
            validateLogFields(logEntryEvent, log);
            validateLogEntryFields(logEntryEvent, logEntry);
        }
    }

    @IsTest
    static void it_should_save_log_entries_when_event_uuid_is_not_populated() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent = (LogEntryEvent__e) LoggerMockDataCreator.setReadOnlyField(logEntryEvent, Schema.LogEntryEvent__e.EventUuid, null);
        System.Assert.isNull(logEntryEvent.EventUuid);

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        List<LogEntry__c> logEntries = [SELECT Id, EventUuid__c FROM LogEntry__c];
        System.Assert.areEqual(1, logEntries.size());
        System.Assert.isNull(logEntries.get(0).EventUuid__c);
    }

    @IsTest
    static void it_should_upsert_log_entries_when_event_uuid_is_populated() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        LogEntryEvent__e originalLogEntryEvent = createLogEntryEvent();
        System.Assert.isNotNull(originalLogEntryEvent.EventUuid);
        LogEntryEvent__e duplicateLogEntryEvent = originalLogEntryEvent.clone();

        Database.SaveResult firstSaveResult = LoggerMockDataStore.getEventBus().publishRecord(originalLogEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());
        List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c WHERE EventUuid__c = :originalLogEntryEvent.EventUuid];
        System.Assert.areEqual(1, logEntries.size());
        Database.SaveResult secondSaveResult = LoggerMockDataStore.getEventBus().publishRecord(duplicateLogEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(firstSaveResult.isSuccess(), firstSaveResult.getErrors().toString());
        System.Assert.isTrue(secondSaveResult.isSuccess(), secondSaveResult.getErrors().toString());
        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed two times for AFTER_INSERT (once for each LogEntryEvent__e record'
        );
        logEntries = [SELECT Id FROM LogEntry__c WHERE EventUuid__c = :originalLogEntryEvent.EventUuid];
        System.Assert.areEqual(1, logEntries.size());
    }

    @IsTest
    static void it_should_set_logging_user_as_log_owner_when_anonymous_mode_is_disabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        String automatedProcessUsername = 'autoproc@' + System.UserInfo.getOrganizationId();
        User automatedProcessUser = [
            SELECT Id, TimeZoneSidKey
            FROM User
            WHERE Username = :automatedProcessUsername AND Profile.Name = NULL
        ];
        User currentUser = new User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
        LoggerSettings__c currentUserSettings = Logger.getUserSettings(currentUser);
        currentUserSettings.IsAnonymousModeEnabled__c = false;
        insert currentUserSettings;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();

        System.runAs(automatedProcessUser) {
            LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
            LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());
        }

        Log__c log = getLog();
        System.Assert.areEqual(currentUser.Id, log.OwnerId);
    }

    @IsTest
    static void it_should_not_set_logging_user_as_log_owner_when_anonymous_mode_is_enabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        String automatedProcessUsername = 'autoproc@' + System.UserInfo.getOrganizationId();
        User automatedProcessUser = [
            SELECT Id, TimeZoneSidKey
            FROM User
            WHERE Username = :automatedProcessUsername AND Profile.Name = NULL
        ];
        User currentUser = new User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
        LoggerSettings__c currentUserSettings = Logger.getUserSettings(currentUser);
        currentUserSettings.IsAnonymousModeEnabled__c = true;
        insert currentUserSettings;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();

        System.runAs(automatedProcessUser) {
            LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
            LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());
        }

        Log__c log = getLog();
        System.Assert.areEqual(automatedProcessUser.Id, log.OwnerId);
    }

    @IsTest
    static void it_should_set_logger_scenario_owner_as_log_owner_when_log_assignment_enabled_via_logger_scenario_rule() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LoggerScenario__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        User loggerScenarioOwner = LoggerMockDataCreator.createUser();
        insert loggerScenarioOwner;
        LoggerScenario__c loggerScenario = new LoggerScenario__c(Name = 'Some Scenario', OwnerId = loggerScenarioOwner.Id, UniqueId__c = 'Some Scenario');
        insert loggerScenario;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.TransactionScenario__c = loggerScenario.UniqueId__c;
        LoggerScenarioRule.setMock(
            new LoggerScenarioRule__mdt(
                IsEnabled__c = true,
                IsLogAssignmentEnabled__c = String.valueOf(true),
                Scenario__c = logEntryEvent.TransactionScenario__c
            )
        );

        LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        Log__c log = getLog();
        System.Assert.areEqual(loggerScenario.OwnerId, log.OwnerId);
    }

    @IsTest
    static void it_should_query_and_set_auth_session_data_when_synchronous_querying_is_disabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LoggerScenario__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        // The createLogEntryEvent() method sets all fields on LogEntryEvent__e, so clear the relevant fields to ensure
        // that the values are only set based on the queried AuthSession record
        logEntryEvent.LoginApplication__c = null;
        logEntryEvent.LoginBrowser__c = null;
        logEntryEvent.LoginHistoryId__c = null;
        logEntryEvent.LoginPlatform__c = null;
        logEntryEvent.LoginType__c = null;
        logEntryEvent.LogoutUrl__c = null;
        logEntryEvent.SessionId__c = null;
        logEntryEvent.SessionSecurityLevel__c = null;
        logEntryEvent.SessionType__c = null;
        logEntryEvent.SourceIp__c = null;
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryAuthSessionDataSynchronously', Value__c = String.valueOf(false)));

        LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        List<Id> userIds = new List<Id>{ logEntryEvent.LoggedById__c };
        LoggerSObjectProxy.AuthSession expectedAuthSessionProxy = LoggerEngineDataSelector.getInstance()
            .getAuthSessionProxies(userIds)
            .get(logEntryEvent.LoggedById__c);
        Log__c log = getLog();
        System.Assert.areEqual(expectedAuthSessionProxy?.LoginHistory.Application, log.LoginApplication__c);
        System.Assert.areEqual(expectedAuthSessionProxy?.LoginHistory.Browser, log.LoginBrowser__c);
        System.Assert.areEqual(expectedAuthSessionProxy?.LoginHistoryId, log.LoginHistoryId__c);
        System.Assert.areEqual(expectedAuthSessionProxy?.LoginHistory.Platform, log.LoginPlatform__c);
        System.Assert.areEqual(expectedAuthSessionProxy?.LoginType, log.LoginType__c);
        System.Assert.areEqual(expectedAuthSessionProxy?.LogoutUrl, log.LogoutUrl__c);
        System.Assert.areEqual(expectedAuthSessionProxy?.Id, log.SessionId__c);
        System.Assert.areEqual(expectedAuthSessionProxy?.SessionSecurityLevel, log.SessionSecurityLevel__c);
        System.Assert.areEqual(expectedAuthSessionProxy?.SessionType, log.SessionType__c);
        System.Assert.areEqual(expectedAuthSessionProxy?.SourceIp, log.SourceIp__c);
    }

    @IsTest
    static void it_should_query_and_set_organization_data_when_synchronous_querying_is_disabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LoggerScenario__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryOrganizationDataSynchronously', Value__c = String.valueOf(false)));

        LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        Organization expectedOrganization = LoggerEngineDataSelector.getInstance().getCachedOrganization();
        Log__c log = getLog();
        System.Assert.areEqual(String.valueOf(expectedOrganization.Id), log.OrganizationId__c);
        System.Assert.areEqual(expectedOrganization.InstanceName, log.OrganizationInstanceName__c);
        System.Assert.areEqual(expectedOrganization.Name, log.OrganizationName__c);
        System.Assert.areEqual(expectedOrganization.NamespacePrefix, log.OrganizationNamespacePrefix__c);
        System.Assert.areEqual(expectedOrganization.OrganizationType, log.OrganizationType__c);
    }

    @IsTest
    static void it_should_query_and_set_user_data_when_synchronous_querying_is_disabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LoggerScenario__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryUserDataSynchronously', Value__c = String.valueOf(false)));

        LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        List<Id> userIds = new List<Id>{ logEntryEvent.LoggedById__c };
        User expectedUser = LoggerEngineDataSelector.getInstance().getUsers(userIds).get(logEntryEvent.LoggedById__c);
        Log__c log = getLog();
        System.Assert.areEqual(expectedUser.Username, log.LoggedByUsername__c);
        System.Assert.areEqual(expectedUser.Profile.Name, log.ProfileName__c);
        System.Assert.areEqual(expectedUser.Profile.UserLicense.LicenseDefinitionKey, log.UserLicenseDefinitionKey__c);
        System.Assert.areEqual(expectedUser.Profile.UserLicenseId, log.UserLicenseId__c);
        System.Assert.areEqual(expectedUser.Profile.UserLicense.Name, log.UserLicenseName__c);
        System.Assert.areEqual(expectedUser.UserRole?.Name, log.UserRoleName__c);
    }

    // TODO - testing topics is tricky. Within the unlocked package, we can test it,
    // but for people that prefer using the unpackaged metadata + don't use topics,
    // the tests would fail. Need to further investigate ways to handle this
    // @IsTest
    // static void it_should_create_topic_and_topicAssignment_records_when_enabled() {
    //     String transactionId = '123-456-789-0';

    //     List<String> tags = new List<String>{ 'test-tag-1', 'test-tag-2' };
    //     LogEntryEvent__e logEntryEvent = new LogEntryEvent__e(
    //         EpochTimestamp__c = System.now().getTime(),
    //         Message__c = 'my message',
    //         Timestamp__c = System.now(),
    //         Tags__c = String.join(tags, '\n'),
    //         TransactionEntryNumber__c = 1,
    //         TransactionId__c = transactionId
    //     );

    //     System.Test.startTest();
    //     LogEntryEventHandler.ENABLE_TAGGING = true;
    //     LogEntryEventHandler.USE_TOPICS_FOR_TAGS = true;
    //     Database.SaveResult saveResult = EventBus.publish(logEntryEvent);
    //     System.Test.stopTest();

    //     System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());

    //     Log__c log = getLog();
    //     System.Assert.areEqual(1, log.LogEntries__r.size());
    //     LogEntry__c logEntry = log.LogEntries__r.get(0);

    //     System.Assert.areEqual(logEntryEvent.TransactionId__c, log.TransactionId__c);
    //     validateLogFields(logEntryEvent, log);
    //     validateLogEntryFields(logEntryEvent, logEntry);

    //     Set<String> tagsSet = new Set<String>(tags);
    //     List<TopicAssignment> topicAssignments = [SELECT Id, EntityId, TopicId, Topic.Name FROM TopicAssignment WHERE EntityId = :logEntry.Id];
    //     for (TopicAssignment topicAssignment : topicAssignments) {
    //         System.Assert.isTrue(tagsSet.contains(topicAssignment.Topic.Name));
    //     }
    // }

    @IsTest
    static void it_should_not_normalize_tag_data_when_data_normalization_is_disabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.Tags__c = 'some entry scenario';
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'NormalizeTagData', Value__c = JSON.serialize(false)));
        System.Assert.isFalse(LoggerParameter.NORMALIZE_TAG_DATA);

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerTag__c]);
        System.Assert.areEqual(0, [SELECT COUNT() FROM LogEntryTag__c]);
        Log__c log = getLog();
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(logEntryEvent.Tags__c, logEntry.Tags__c);
    }

    @IsTest
    static void it_should_create_tag_records_when_tagging_is_enabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.Assert.isTrue(LoggerParameter.ENABLE_TAGGING, 'Tagging is not enabled within test context, cannot execute tagging test');
        List<String> tags = new List<String>{ 'test-tag-1', 'test-tag-2' };
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        System.Assert.isNotNull(logEntryEvent.EventUuid);
        logEntryEvent.Tags__c = String.join(tags, '\n');

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
        List<LogEntryTag__c> logEntryTags = [SELECT Id, LogEntry__c, Tag__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        System.Assert.areEqual(tags.size(), logEntryTags.size());
        Set<String> tagsSet = new Set<String>(tags);
        for (LogEntryTag__c logEntryTag : logEntryTags) {
            System.Assert.isTrue(tagsSet.contains(logEntryTag.Tag__r.Name));
        }
    }

    @IsTest
    static void it_should_reuse_existing_tag_records() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.Assert.isTrue(LoggerParameter.ENABLE_TAGGING, 'Tagging is not enabled within test context, cannot execute tagging test');
        String testTagName = 'Some tag!';
        LoggerTag__c tag = new LoggerTag__c(Name = testTagName);
        insert tag;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        System.Assert.isNotNull(logEntryEvent.EventUuid);
        logEntryEvent.Tags__c = testTagName;

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
        Integer countOfTagsWithTagName = [SELECT COUNT() FROM LoggerTag__c WHERE Name = :testTagName];
        System.Assert.areEqual(1, countOfTagsWithTagName);
        LogEntryTag__c logEntryTag = [SELECT Id, LogEntry__c, Tag__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        System.Assert.areEqual(tag.Id, logEntryTag.Tag__c);
        System.Assert.areEqual(tag.Name, logEntryTag.Tag__r.Name);
    }

    @IsTest
    static void it_should_gracefully_skip_tag_rule_when_field_is_null() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.Assert.isTrue(LoggerParameter.ENABLE_TAGGING, 'Tagging is not enabled within test context, cannot execute tagging test');
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.Message__c = null;
        logEntryEvent.Tags__c = null;
        String configuredTagName = 'CMDT Tag';
        LoggerTestConfigurator.setMock(
            new LogEntryTagRule__mdt(
                SObjectField__c = Schema.LogEntry__c.Message__c.getDescribe().getName(),
                ComparisonType__c = 'CONTAINS',
                ComparisonValue__c = 'some value',
                Tags__c = configuredTagName
            )
        );

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
        Integer countOfTagsWithTagName = [SELECT COUNT() FROM LoggerTag__c WHERE Name = :configuredTagName];
        System.Assert.areEqual(0, countOfTagsWithTagName);
    }

    @IsTest
    static void it_should_append_tags_for_contains_rule() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.Assert.isTrue(LoggerParameter.ENABLE_TAGGING, 'Tagging is not enabled within test context, cannot execute tagging test');
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.Message__c = 'my message';
        logEntryEvent.Tags__c = null;
        String configuredTagName = 'CMDT Tag';
        LoggerTestConfigurator.setMock(
            new LogEntryTagRule__mdt(
                SObjectField__c = Schema.LogEntry__c.Message__c.getDescribe().getName(),
                ComparisonType__c = 'CONTAINS',
                ComparisonValue__c = logEntryEvent.Message__c.substring(1, 4),
                Tags__c = configuredTagName
            )
        );

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
        Integer countOfTagsWithTagName = [SELECT COUNT() FROM LoggerTag__c WHERE Name = :configuredTagName];
        System.Assert.areEqual(1, countOfTagsWithTagName);
        LogEntryTag__c logEntryTag = [SELECT Id, LogEntry__c, Tag__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        System.Assert.areEqual(configuredTagName, logEntryTag.Tag__r.Name);
    }

    @IsTest
    static void it_should_append_tags_for_equals_rule() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.Assert.isTrue(LoggerParameter.ENABLE_TAGGING, 'Tagging is not enabled within test context, cannot execute tagging test');
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.Tags__c = null;
        String configuredTagName = 'CMDT Tag';
        LoggerTestConfigurator.setMock(
            new LogEntryTagRule__mdt(
                SObjectField__c = Schema.LogEntry__c.Message__c.getDescribe().getName(),
                ComparisonType__c = 'EQUALS',
                ComparisonValue__c = logEntryEvent.Message__c,
                Tags__c = configuredTagName
            )
        );

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
        Integer countOfTagsWithTagName = [SELECT COUNT() FROM LoggerTag__c WHERE Name = :configuredTagName];
        System.Assert.areEqual(1, countOfTagsWithTagName);
        LogEntryTag__c logEntryTag = [SELECT Id, LogEntry__c, Tag__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        System.Assert.areEqual(configuredTagName, logEntryTag.Tag__r.Name);
    }

    @IsTest
    static void it_should_append_tags_for_regex_rule() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.Assert.isTrue(LoggerParameter.ENABLE_TAGGING, 'Tagging is not enabled within test context, cannot execute tagging test');
        String zipCodeRegEx = '(^[0-9]{4}?[0-9]$|^[0-9]{4}?[0-9]-[0-9]{4}$)';
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.Message__c = '94541';
        logEntryEvent.Tags__c = null;
        String configuredTagName = 'CMDT Tag';
        LoggerTestConfigurator.setMock(
            new LogEntryTagRule__mdt(
                SObjectField__c = Schema.LogEntry__c.Message__c.getDescribe().getName(),
                ComparisonType__c = 'MATCHES_REGEX',
                ComparisonValue__c = zipCodeRegEx,
                Tags__c = configuredTagName
            )
        );

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
        Integer countOfTagsWithTagName = [SELECT COUNT() FROM LoggerTag__c WHERE Name = :configuredTagName];
        System.Assert.areEqual(1, countOfTagsWithTagName);
        LogEntryTag__c logEntryTag = [SELECT Id, LogEntry__c, Tag__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        System.Assert.areEqual(configuredTagName, logEntryTag.Tag__r.Name);
    }

    @IsTest
    static void it_should_append_tags_for_startsWith_rule() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.Assert.isTrue(LoggerParameter.ENABLE_TAGGING, 'Tagging is not enabled within test context, cannot execute tagging test');
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.Message__c = 'my message';
        logEntryEvent.Tags__c = null;
        String configuredTagName = 'CMDT Tag';
        LoggerTestConfigurator.setMock(
            new LogEntryTagRule__mdt(
                SObjectField__c = Schema.LogEntry__c.Message__c.getDescribe().getName(),
                ComparisonType__c = 'STARTS_WITH',
                ComparisonValue__c = logEntryEvent.Message__c.left(3),
                Tags__c = configuredTagName
            )
        );

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
        Integer countOfTagsWithTagName = [SELECT COUNT() FROM LoggerTag__c WHERE Name = :configuredTagName];
        System.Assert.areEqual(1, countOfTagsWithTagName);
        LogEntryTag__c logEntryTag = [SELECT Id, LogEntry__c, Tag__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        System.Assert.areEqual(configuredTagName, logEntryTag.Tag__r.Name);
    }

    @IsTest
    static void it_should_set_api_release_number_and_api_release_version_from_callout_when_enabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        Logger.StatusApiResponse mockApiResponse = createStatusApiResponse();
        System.Test.setMock(
            System.HttpCalloutMock.class,
            LoggerMockDataCreator.createHttpCallout().setStatusCode(200).setResponseBody(System.JSON.serialize(mockApiResponse))
        );
        LoggerParameter__mdt mockCallStatusApiParameter = new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = 'true');
        LoggerTestConfigurator.setMock(mockCallStatusApiParameter);
        System.Assert.isTrue(LoggerParameter.CALL_STATUS_API);
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();

        // TODO System.Test.startTest() & stopTest() are still being used so that the callout in LogEntryEventHandler executes,
        // but it be nice if this was instead mocked via LoggerMockDataStore (? or some other similar class?)
        System.Test.startTest();
        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());
        System.Test.stopTest();

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(mockApiResponse.location, log.OrganizationLocation__c);
        System.Assert.areEqual(mockApiResponse.releaseNumber, log.OrganizationReleaseNumber__c);
        System.Assert.areEqual(mockApiResponse.releaseVersion, log.OrganizationReleaseVersion__c);
        // Legacy fields
        System.Assert.areEqual(log.OrganizationReleaseNumber__c, log.ApiReleaseNumber__c);
        System.Assert.areEqual(log.OrganizationReleaseVersion__c, log.ApiReleaseVersion__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @IsTest
    static void it_should_set_api_release_number_and_api_release_version_from_recent_record() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        Log__c recentLog = new Log__c(
            ApiReleaseNumber__c = 'QWERTY',
            ApiReleaseVersion__c = 'ASDF',
            OrganizationReleaseNumber__c = 'POIUY',
            OrganizationReleaseVersion__c = 'LKJH',
            TransactionId__c = 'ABC-XYZ'
        );
        insert recentLog;
        insert new LogEntry__c(Log__c = recentLog.Id, Timestamp__c = System.now().addHours(-1));
        LoggerParameter__mdt mockCallStatusApiParameter = new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = 'true');
        LoggerTestConfigurator.setMock(mockCallStatusApiParameter);
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();

        // TODO System.Test.startTest() & stopTest() are still being used so that the callout in LogEntryEventHandler executes,
        // but it be nice if this was instead mocked via LoggerMockDataStore (? or some other similar class?)
        System.Test.startTest();
        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());
        System.Test.stopTest();

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        System.Assert.areEqual(0, System.Limits.getCallouts());
        Log__c log = getLog();
        System.Assert.areNotEqual(recentLog.Id, log.Id);
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(recentLog.ApiReleaseNumber__c, log.ApiReleaseNumber__c);
        System.Assert.areEqual(recentLog.ApiReleaseVersion__c, log.ApiReleaseVersion__c);
        System.Assert.areEqual(recentLog.OrganizationReleaseNumber__c, log.OrganizationReleaseNumber__c);
        System.Assert.areEqual(recentLog.OrganizationReleaseVersion__c, log.OrganizationReleaseVersion__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @IsTest
    static void it_should_not_set_api_release_number_or_api_release_version_from_callout_when_disabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        Logger.StatusApiResponse mockApiResponse = createStatusApiResponse();
        System.Test.setMock(
            System.HttpCalloutMock.class,
            LoggerMockDataCreator.createHttpCallout().setStatusCode(200).setResponseBody(System.JSON.serialize(mockApiResponse))
        );
        LoggerParameter__mdt mockCallStatusApiParameter = new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = 'false');
        LoggerTestConfigurator.setMock(mockCallStatusApiParameter);
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();

        // TODO System.Test.startTest() & stopTest() are still being used so that the callout in LogEntryEventHandler executes,
        // but it be nice if this was instead mocked via LoggerMockDataStore (? or some other similar class?)
        System.Test.startTest();
        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());
        System.Test.stopTest();

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        System.Assert.areEqual(0, System.Limits.getCallouts());
        Log__c log = getLog();
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(logEntryEvent.TransactionId__c, log.TransactionId__c);
        System.Assert.isNull(log.ApiReleaseNumber__c);
        System.Assert.isNull(log.ApiReleaseVersion__c);
        System.Assert.isNull(log.OrganizationReleaseNumber__c);
        System.Assert.isNull(log.OrganizationReleaseVersion__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @IsTest
    static void it_should_skip_setting_api_release_number_and_api_release_version_when_callout_fails() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        Logger.StatusApiResponse mockApiResponse = createStatusApiResponse();
        System.Test.setMock(
            System.HttpCalloutMock.class,
            LoggerMockDataCreator.createHttpCallout().setStatusCode(400).setResponseBody(System.JSON.serialize(mockApiResponse))
        );
        LoggerParameter__mdt mockCallStatusApiParameter = new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = 'true');
        LoggerTestConfigurator.setMock(mockCallStatusApiParameter);
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        System.Assert.areEqual(0, System.Limits.getCallouts());

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.Assert.areEqual(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.Assert.areEqual(logEntryEvent.TransactionId__c, log.TransactionId__c);
        System.Assert.isNull(log.ApiReleaseNumber__c);
        System.Assert.isNull(log.ApiReleaseVersion__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @IsTest
    static void it_should_save_data_when_saving_with_synchronous_dml() {
        System.Assert.areEqual(0, [SELECT COUNT() FROM Log__c], 'Test has started under the wrong conditions');
        System.Assert.areEqual(0, [SELECT COUNT() FROM LogEntry__c], 'Test has started under the wrong conditions');
        System.Assert.areEqual(0, [SELECT COUNT() FROM LogEntryTag__c], 'Test has started under the wrong conditions');
        System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerTag__c], 'Test has started under the wrong conditions');
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        String exampleTag = 'Some tag';

        System.Test.startTest();
        LogEntryEventBuilder builder = Logger.info('some INFO message').addTag(exampleTag);
        System.Assert.areEqual(1, Logger.getBufferSize());
        Logger.setSaveMethod(Logger.SaveMethod.SYNCHRONOUS_DML);
        System.Assert.areEqual(Logger.getSaveMethod(), Logger.SaveMethod.SYNCHRONOUS_DML, 'Save method should be SYNCHRONOUS_DML');
        Logger.saveLog();
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Test.stopTest();

        System.Assert.areEqual(1, [SELECT COUNT() FROM Log__c], '1 matching Log__c record should have been generated');
        System.Assert.areEqual(
            1,
            [SELECT COUNT() FROM LogEntry__c WHERE LoggingLevel__c = :builder.getLogEntryEvent().LoggingLevel__c],
            '1 matching LogEntry__c record should have been generated'
        );
        System.Assert.areEqual(1, [SELECT COUNT() FROM LoggerTag__c WHERE Name = :exampleTag], '1 matching LoggerTag__c record should have been generated');
    }

    private static LogEntryEvent__e createLogEntryEvent() {
        // The data builder class handles populating field values, but for some fields,
        // certain values are expected (e.g., LoggedById__c should have a valid user ID),
        // so this method handles any additional manipulation to the field values
        LogEntryEvent__e logEntryEvent = (LogEntryEvent__e) LoggerMockDataCreator.createDataBuilder(Schema.LogEntryEvent__e.SObjectType)
            .populateAllFields()
            .getRecord();
        logEntryEvent.ImpersonatedById__c = null;
        logEntryEvent.LoggedById__c = System.UserInfo.getUserId();
        logEntryEvent.LoggingLevel__c = System.LoggingLevel.INFO.name();
        logEntryEvent.LoggingLevelOrdinal__c = System.LoggingLevel.INFO.ordinal();
        logEntryEvent.ProfileId__c = System.UserInfo.getProfileId();
        logEntryEvent.RecordCollectionSize__c = 1;
        logEntryEvent.RecordCollectionType__c = 'Single';
        logEntryEvent.RecordId__c = System.UserInfo.getUserId();
        logEntryEvent.TimestampString__c = String.valueOf(logEntryEvent.Timestamp__c.getTime());
        logEntryEvent.UserLoggingLevel__c = System.LoggingLevel.INFO.name();
        logEntryEvent.UserLoggingLevelOrdinal__c = System.LoggingLevel.INFO.ordinal();
        logEntryEvent = (LogEntryEvent__e) LoggerMockDataCreator.setReadOnlyField(
            logEntryEvent,
            Schema.LogEntryEvent__e.EventUuid,
            new Logger.Uuid().getValue()
        );

        return logEntryEvent;
    }

    private static Logger.StatusApiResponse createStatusApiResponse() {
        Logger.StatusApiResponse mockApiResponse = new Logger.StatusApiResponse();
        mockApiResponse.location = 'NA';
        mockApiResponse.releaseNumber = '242.19.17';
        mockApiResponse.releaseVersion = 'Spring \'23 Patch 19.17';
        return mockApiResponse;
    }

    private static Log__c getLog() {
        return [
            SELECT
                ApiReleaseNumber__c,
                ApiReleaseVersion__c,
                ApiVersion__c,
                AsyncContextChildJobId__c,
                AsyncContextParentJobId__c,
                AsyncContextTriggerId__c,
                AsyncContextType__c,
                Id,
                Locale__c,
                LoggedBy__c,
                LoggedByUsername__c,
                LoggerVersionNumber__c,
                LoginApplication__c,
                LoginBrowser__c,
                LoginDomain__c,
                LoginHistoryId__c,
                LoginPlatform__c,
                LoginType__c,
                LogoutUrl__c,
                NetworkId__c,
                OrganizationApiVersion__c,
                OrganizationDomainUrl__c,
                OrganizationEnvironmentType__c,
                OrganizationId__c,
                OrganizationInstanceName__c,
                OrganizationLocation__c,
                OrganizationName__c,
                OrganizationNamespacePrefix__c,
                OrganizationReleaseNumber__c,
                OrganizationReleaseVersion__c,
                OrganizationType__c,
                OwnerId,
                ParentLogTransactionId__c,
                ProfileId__c,
                ProfileName__c,
                RequestId__c,
                Scenario__c,
                SessionId__c,
                SessionSecurityLevel__c,
                SessionType__c,
                SourceIp__c,
                StartTime__c,
                SystemMode__c,
                ThemeDisplayed__c,
                TimeZoneId__c,
                TimeZoneName__c,
                TransactionId__c,
                TransactionScenario__c,
                TransactionScenario__r.Name,
                TransactionScenario__r.UniqueId__c,
                TransactionScenarioName__c,
                UserLicenseDefinitionKey__c,
                UserLicenseId__c,
                UserLicenseName__c,
                UserLoggingLevel__c,
                UserLoggingLevelOrdinal__c,
                UserRoleId__c,
                UserRoleName__c,
                UserType__c,
                (
                    SELECT
                        BrowserFormFactor__c,
                        BrowserLanguage__c,
                        BrowserScreenResolution__c,
                        BrowserUrl__c,
                        BrowserUserAgent__c,
                        BrowserWindowResolution__c,
                        ComponentType__c,
                        DatabaseResultCollectionSize__c,
                        DatabaseResultCollectionType__c,
                        DatabaseResultJson__c,
                        DatabaseResultType__c,
                        EntryScenario__c,
                        EntryScenario__r.Name,
                        EntryScenario__r.UniqueId__c,
                        EntryScenarioName__c,
                        EpochTimestamp__c,
                        ExceptionStackTrace__c,
                        ExceptionType__c,
                        HttpRequestBody__c,
                        HttpRequestBodyMasked__c,
                        HttpRequestCompressed__c,
                        HttpRequestEndpoint__c,
                        HttpRequestMethod__c,
                        HttpResponseBody__c,
                        HttpResponseBodyMasked__c,
                        HttpResponseHeaderKeys__c,
                        HttpResponseHeaders__c,
                        HttpResponseStatus__c,
                        HttpResponseStatusCode__c,
                        LimitsAggregateQueriesMax__c,
                        LimitsAggregateQueriesUsed__c,
                        LimitsAsyncCallsMax__c,
                        LimitsAsyncCallsUsed__c,
                        LimitsCalloutsMax__c,
                        LimitsCalloutsUsed__c,
                        LimitsCpuTimeMax__c,
                        LimitsCpuTimeUsed__c,
                        LimitsDmlRowsMax__c,
                        LimitsDmlRowsUsed__c,
                        LimitsDmlStatementsMax__c,
                        LimitsDmlStatementsUsed__c,
                        LimitsEmailInvocationsMax__c,
                        LimitsEmailInvocationsUsed__c,
                        LimitsFutureCallsMax__c,
                        LimitsFutureCallsUsed__c,
                        LimitsHeapSizeMax__c,
                        LimitsHeapSizeUsed__c,
                        LimitsMobilePushApexCallsMax__c,
                        LimitsMobilePushApexCallsUsed__c,
                        LimitsPublishImmediateDmlStatementsMax__c,
                        LimitsPublishImmediateDmlStatementsUsed__c,
                        LimitsQueueableJobsMax__c,
                        LimitsQueueableJobsUsed__c,
                        LimitsSoqlQueriesMax__c,
                        LimitsSoqlQueriesUsed__c,
                        LimitsSoqlQueryLocatorRowsMax__c,
                        LimitsSoqlQueryLocatorRowsUsed__c,
                        LimitsSoqlQueryRowsMax__c,
                        LimitsSoqlQueryRowsUsed__c,
                        LimitsSoslSearchesUsed__c,
                        LimitsSoslSearchesMax__c,
                        Log__c,
                        LoggingLevel__c,
                        LoggingLevelOrdinal__c,
                        Message__c,
                        MessageTruncated__c,
                        Id,
                        Name,
                        OriginType__c,
                        OriginLocation__c,
                        RecordCollectionSize__c,
                        RecordCollectionType__c,
                        RecordId__c,
                        RecordJson__c,
                        RecordJsonMasked__c,
                        RecordSObjectClassification__c,
                        RecordSObjectType__c,
                        RecordSObjectTypeNamespace__c,
                        StackTrace__c,
                        Tags__c,
                        Timestamp__c,
                        TransactionEntryNumber__c,
                        TriggerIsExecuting__c,
                        TriggerOperationType__c,
                        TriggerSObjectType__c
                    FROM LogEntries__r
                )
            FROM Log__c
            ORDER BY StartTime__c DESC
            LIMIT 1
        ];
    }

    private static void validateLogFields(LogEntryEvent__e logEntryEvent, Log__c log) {
        Organization org = [SELECT Id, Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization];
        String orgEnvironmentType;
        if (org.IsSandbox && org.TrialExpirationDate != null) {
            orgEnvironmentType = 'Scratch Org';
        } else if (org.IsSandbox) {
            orgEnvironmentType = 'Sandbox';
        } else {
            orgEnvironmentType = 'Production';
        }

        Id logOwnerId = logEntryEvent.LoggedById__c == null ? System.UserInfo.getUserId() : logEntryEvent.LoggedById__c;

        System.Assert.areEqual(logEntryEvent.ApiVersion__c, log.ApiVersion__c, 'log.ApiVersion__c was not properly set');
        System.Assert.areEqual(logEntryEvent.AsyncContextChildJobId__c, log.AsyncContextChildJobId__c, 'log.AsyncContextChildJobId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.AsyncContextParentJobId__c, log.AsyncContextParentJobId__c, 'log.AsyncContextParentJobId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.AsyncContextTriggerId__c, log.AsyncContextTriggerId__c, 'log.AsyncContextTriggerId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.AsyncContextType__c, log.AsyncContextType__c, 'log.AsyncContextTriggerId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.Locale__c, log.Locale__c, 'log.Locale__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LoggedById__c, log.LoggedBy__c, 'log.LoggedBy__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LoggedByUsername__c, log.LoggedByUsername__c, 'log.LoggedByUsername__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LoggerVersionNumber__c, log.LoggerVersionNumber__c, 'log.LoggerVersionNumber__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LoginDomain__c, log.LoginDomain__c, 'log.LoginDomain__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LoginHistoryId__c, log.LoginHistoryId__c, 'log.LoginHistoryId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LoginType__c, log.LoginType__c, 'log.LoginType__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LogoutUrl__c, log.LogoutUrl__c, 'log.LogoutUrl__c was not properly set');
        System.Assert.areEqual(logEntryEvent.NetworkId__c, log.NetworkId__c, 'log.NetworkId__c was not properly set');
        System.Assert.areEqual(logOwnerId, log.OwnerId, 'log.OwnerId was not properly set');
        System.Assert.areEqual(logEntryEvent.OrganizationApiVersion__c, log.OrganizationApiVersion__c, 'log.OrganizationApiVersion__c was not properly set');
        System.Assert.areEqual(logEntryEvent.ParentLogTransactionId__c, log.ParentLogTransactionId__c, 'log.ParentLogTransactionId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.ProfileId__c, log.ProfileId__c, 'log.ProfileId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.ProfileName__c, log.ProfileName__c, 'log.ProfileName__c was not properly set');
        System.Assert.areEqual(logEntryEvent.RequestId__c, log.RequestId__c, 'log.RequestId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.SessionId__c, log.SessionId__c, 'log.SessionId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.SessionId__c, log.SessionId__c, 'log.SessionId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.SessionSecurityLevel__c, log.SessionSecurityLevel__c, 'log.SessionSecurityLevel__c was not properly set');
        System.Assert.areEqual(logEntryEvent.SessionType__c, log.SessionType__c, 'log.SessionType__c was not properly set');
        System.Assert.areEqual(logEntryEvent.SourceIp__c, log.SourceIp__c, 'log.SourceIp__c was not properly set');
        System.Assert.areEqual(logEntryEvent.SystemMode__c, log.SystemMode__c, 'log.SystemMode__c was not properly set');
        System.Assert.areEqual(logEntryEvent.ThemeDisplayed__c, log.ThemeDisplayed__c, 'log.ThemeDisplayed__c was not properly set');
        System.Assert.areEqual(logEntryEvent.TimeZoneId__c, log.TimeZoneId__c, 'log.TimeZoneId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.TimeZoneName__c, log.TimeZoneName__c, 'log.TimeZoneName__c was not properly set');
        System.Assert.areEqual(logEntryEvent.TransactionId__c, log.TransactionId__c, 'log.TransactionId__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.TransactionScenario__c?.left(Schema.LoggerScenario__c.Name.getDescribe().getLength()),
            log.TransactionScenario__r?.Name,
            'log.TransactionScenario__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.TransactionScenario__c,
            log.TransactionScenario__r.UniqueId__c,
            'log.TransactionScenario__r.UniqueId__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.UserLoggingLevel__c, log.UserLoggingLevel__c, 'log.UserLoggingLevel__c was not properly set');
        System.Assert.areEqual(logEntryEvent.UserLoggingLevelOrdinal__c, log.UserLoggingLevelOrdinal__c, 'log.UserLoggingLevelOrdinal__c was not properly set');
        // System.Assert.areEqual(currentUser.UserRoleId, log.UserRoleId__c, 'log.UserRoleId__c was not properly set');
        // System.Assert.areEqual(currentUser.UserRoleId == null ? null : currentUser.UserRole.Name, log.UserRoleName__c, 'log.UserRoleName__c was not properly set');
        System.Assert.areEqual(logEntryEvent.UserType__c, log.UserType__c, 'log.UserType__c was not properly set');

        // Org fields
        System.Assert.areEqual(logEntryEvent.OrganizationDomainUrl__c, log.OrganizationDomainUrl__c, 'log.OrganizationDomainUrl__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.OrganizationEnvironmentType__c,
            log.OrganizationEnvironmentType__c,
            'log.OrganizationEnvironmentType__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.OrganizationId__c, log.OrganizationId__c, 'log.OrganizationId__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.OrganizationInstanceName__c,
            log.OrganizationInstanceName__c,
            'log.OrganizationInstanceName__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.OrganizationName__c, log.OrganizationName__c, 'log.OrganizationName__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.OrganizationNamespacePrefix__c,
            log.OrganizationNamespacePrefix__c,
            'log.OrganizationNamespacePrefix__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.OrganizationType__c, log.OrganizationType__c, 'log.OrganizationType__c was not properly set');

        // Profile fields
        System.Assert.areEqual(
            logEntryEvent.UserLicenseDefinitionKey__c,
            log.UserLicenseDefinitionKey__c,
            'log.UserLicenseDefinitionKey__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.UserLicenseId__c, log.UserLicenseId__c, 'log.UserLicenseId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.UserLicenseName__c, log.UserLicenseName__c, 'log.UserLicenseName__c was not properly set');
    }

    private static void validateLogEntryFields(LogEntryEvent__e logEntryEvent, LogEntry__c logEntry) {
        System.Assert.areEqual(logEntryEvent.BrowserFormFactor__c, logEntry.BrowserFormFactor__c, 'logEntry.BrowserFormFactor__c was not properly set');
        System.Assert.areEqual(logEntryEvent.BrowserLanguage__c, logEntry.BrowserLanguage__c, 'logEntry.BrowserLanguage__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.BrowserScreenResolution__c,
            logEntry.BrowserScreenResolution__c,
            'logEntry.BrowserScreenResolution__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.BrowserUrl__c, logEntry.BrowserUrl__c, 'logEntry.BrowserUrl__c was not properly set');
        System.Assert.areEqual(logEntryEvent.BrowserUserAgent__c, logEntry.BrowserUserAgent__c, 'logEntry.BrowserUserAgent__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.BrowserWindowResolution__c,
            logEntry.BrowserWindowResolution__c,
            'logEntry.BrowserWindowResolution__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.ComponentType__c, logEntry.ComponentType__c, 'logEntry.ComponentType__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.DatabaseResultCollectionSize__c,
            logEntry.DatabaseResultCollectionSize__c,
            'logEntry.DatabaseResultCollectionSize__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.DatabaseResultCollectionType__c,
            logEntry.DatabaseResultCollectionType__c,
            'logEntry.DatabaseResultCollectionType__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.DatabaseResultJson__c, logEntry.DatabaseResultJson__c, 'logEntry.DatabaseResultJson__c was not properly set');
        System.Assert.areEqual(logEntryEvent.DatabaseResultType__c, logEntry.DatabaseResultType__c, 'logEntry.DatabaseResultType__c was not properly set');
        System.Assert.areEqual(logEntryEvent.EpochTimestamp__c, logEntry.EpochTimestamp__c, 'logEntry.EpochTimestamp__c was not properly set');
        System.Assert.areEqual(logEntryEvent.ExceptionStackTrace__c, logEntry.ExceptionStackTrace__c, 'logEntry.ExceptionStackTrace__c was not properly set');
        System.Assert.areEqual(logEntryEvent.ExceptionType__c, logEntry.ExceptionType__c, 'logEntry.ExceptionType__c was not properly set');
        System.Assert.areEqual(logEntryEvent.HttpRequestBody__c, logEntry.HttpRequestBody__c, 'logEntry.HttpRequestBody__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.HttpRequestBodyMasked__c,
            logEntry.HttpRequestBodyMasked__c,
            'logEntry.HttpRequestBodyMasked__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.HttpRequestCompressed__c,
            logEntry.HttpRequestCompressed__c,
            'logEntry.HttpRequestCompressed__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.HttpRequestEndpoint__c, logEntry.HttpRequestEndpoint__c, 'logEntry.HttpRequestEndpoint__c was not properly set');
        System.Assert.areEqual(logEntryEvent.HttpRequestMethod__c, logEntry.HttpRequestMethod__c, 'logEntry.HttpRequestMethod__c was not properly set');
        System.Assert.areEqual(logEntryEvent.HttpResponseBody__c, logEntry.HttpResponseBody__c, 'logEntry.HttpResponseBody__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.HttpResponseBodyMasked__c,
            logEntry.HttpResponseBodyMasked__c,
            'logEntry.HttpResponseBodyMasked__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.HttpResponseHeaderKeys__c,
            logEntry.HttpResponseHeaderKeys__c,
            'logEntry.HttpResponseHeaderKeys__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.HttpResponseHeaders__c, logEntry.HttpResponseHeaders__c, 'logEntry.HttpResponseHeaders__c was not properly set');
        System.Assert.areEqual(logEntryEvent.HttpResponseStatus__c, logEntry.HttpResponseStatus__c, 'logEntry.HttpResponseStatus__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.HttpResponseStatusCode__c,
            logEntry.HttpResponseStatusCode__c,
            'logEntry.HttpResponseStatusCode__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsAggregateQueriesMax__c,
            logEntry.LimitsAggregateQueriesMax__c,
            'logEntry.LimitsAggregateQueriesMax__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsAggregateQueriesUsed__c,
            logEntry.LimitsAggregateQueriesUsed__c,
            'logEntry.LimitsAggregateQueriesUsed__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.LimitsAsyncCallsMax__c, logEntry.LimitsAsyncCallsMax__c, 'logEntry.LimitsAsyncCallsMax__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.LimitsAsyncCallsUsed__c,
            logEntry.LimitsAsyncCallsUsed__c,
            'logEntry.LimitsAsyncCallsUsed__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.LimitsCalloutsMax__c, logEntry.LimitsCalloutsMax__c, 'logEntry.LimitsCalloutsMax__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LimitsCalloutsUsed__c, logEntry.LimitsCalloutsUsed__c, 'logEntry.LimitsCalloutsUsed__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LimitsCpuTimeMax__c, logEntry.LimitsCpuTimeMax__c, 'logEntry.LimitsCpuTimeMax__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LimitsCpuTimeUsed__c, logEntry.LimitsCpuTimeUsed__c, 'logEntry.LimitsCpuTimeUsed__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LimitsDmlRowsMax__c, logEntry.LimitsDmlRowsMax__c, 'logEntry.LimitsDmlRowsMax__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LimitsDmlRowsUsed__c, logEntry.LimitsDmlRowsUsed__c, 'logEntry.LimitsDmlRowsUsed__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.LimitsDmlStatementsMax__c,
            logEntry.LimitsDmlStatementsMax__c,
            'logEntry.LimitsDmlStatementsMax__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsDmlStatementsUsed__c,
            logEntry.LimitsDmlStatementsUsed__c,
            'logEntry.LimitsDmlStatementsUsed__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsEmailInvocationsMax__c,
            logEntry.LimitsEmailInvocationsMax__c,
            'logEntry.LimitsEmailInvocationsMax__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsEmailInvocationsUsed__c,
            logEntry.LimitsEmailInvocationsUsed__c,
            'logEntry.LimitsEmailInvocationsUsed__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsFutureCallsMax__c,
            logEntry.LimitsFutureCallsMax__c,
            'logEntry.LimitsFutureCallsMax__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsFutureCallsUsed__c,
            logEntry.LimitsFutureCallsUsed__c,
            'logEntry.LimitsFutureCallsUsed__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.LimitsHeapSizeMax__c, logEntry.LimitsHeapSizeMax__c, 'logEntry.LimitsHeapSizeMax__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LimitsHeapSizeUsed__c, logEntry.LimitsHeapSizeUsed__c, 'logEntry.LimitsHeapSizeUsed__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.LimitsMobilePushApexCallsMax__c,
            logEntry.LimitsMobilePushApexCallsMax__c,
            'logEntry.LimitsMobilePushApexCallsMax__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsMobilePushApexCallsUsed__c,
            logEntry.LimitsMobilePushApexCallsUsed__c,
            'logEntry.LimitsMobilePushApexCallsUsed__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsPublishImmediateDmlStatementsMax__c,
            logEntry.LimitsPublishImmediateDmlStatementsMax__c,
            'logEntry.LimitsPublishImmediateDmlStatementsMax__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsPublishImmediateDmlStatementsUsed__c,
            logEntry.LimitsPublishImmediateDmlStatementsUsed__c,
            'logEntry.LimitsPublishImmediateDmlStatementsUsed__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsQueueableJobsMax__c,
            logEntry.LimitsQueueableJobsMax__c,
            'logEntry.LimitsQueueableJobsMax__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsQueueableJobsUsed__c,
            logEntry.LimitsQueueableJobsUsed__c,
            'logEntry.LimitsQueueableJobsUsed__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsSoqlQueriesMax__c,
            logEntry.LimitsSoqlQueriesMax__c,
            'logEntry.LimitsSoqlQueriesMax__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsSoqlQueriesUsed__c,
            logEntry.LimitsSoqlQueriesUsed__c,
            'logEntry.LimitsSoqlQueriesUsed__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c,
            logEntry.LimitsSoqlQueryLocatorRowsMax__c,
            'logEntry.LimitsSoqlQueryLocatorRowsMax__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c,
            logEntry.LimitsSoqlQueryLocatorRowsUsed__c,
            'logEntry.LimitsSoqlQueryLocatorRowsUsed__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsSoqlQueryRowsMax__c,
            logEntry.LimitsSoqlQueryRowsMax__c,
            'logEntry.LimitsSoqlQueryRowsMax__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsSoqlQueryRowsUsed__c,
            logEntry.LimitsSoqlQueryRowsUsed__c,
            'logEntry.LimitsSoqlQueryRowsUsed__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsSoslSearchesUsed__c,
            logEntry.LimitsSoslSearchesUsed__c,
            'logEntry.LimitsSoslSearchesUsed__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.LimitsSoslSearchesMax__c,
            logEntry.LimitsSoslSearchesMax__c,
            'logEntry.LimitsSoslSearchesMax__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.LoggingLevel__c, logEntry.LoggingLevel__c, 'logEntry.LoggingLevel__c was not properly set');
        System.Assert.areEqual(logEntryEvent.LoggingLevelOrdinal__c, logEntry.LoggingLevelOrdinal__c, 'logEntry.LoggingLevelOrdinal__c was not properly set');
        System.Assert.areEqual(logEntryEvent.Message__c, logEntry.Message__c, 'logEntry.Message__c was not properly set');
        System.Assert.areEqual(logEntryEvent.MessageTruncated__c, logEntry.MessageTruncated__c, 'logEntry.MessageTruncated__c was not properly set');
        System.Assert.areEqual(logEntry.Id, logEntry.Name, 'logEntry.Name was not properly set');
        System.Assert.areEqual(logEntryEvent.OriginType__c, logEntry.OriginType__c, 'logEntry.OriginType__c was not properly set');
        System.Assert.areEqual(logEntryEvent.OriginLocation__c, logEntry.OriginLocation__c, 'logEntry.OriginLocation__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.RecordCollectionSize__c,
            logEntry.RecordCollectionSize__c,
            'logEntry.RecordCollectionSize__c was not properly set'
        );
        System.Assert.areEqual(
            logEntryEvent.RecordCollectionType__c,
            logEntry.RecordCollectionType__c,
            'logEntry.RecordCollectionType__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.RecordId__c, logEntry.RecordId__c, 'logEntry.RecordId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.RecordJson__c, logEntry.RecordJson__c, 'logEntry.RecordJson__c was not properly set');
        System.Assert.areEqual(logEntryEvent.RecordJsonMasked__c, logEntry.RecordJsonMasked__c, 'logEntry.RecordJsonMasked__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.RecordSObjectClassification__c,
            logEntry.RecordSObjectClassification__c,
            'logEntry.RecordSObjectClassification__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.RecordSObjectType__c, logEntry.RecordSObjectType__c, 'logEntry.RecordSObjectType__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.RecordSObjectTypeNamespace__c,
            logEntry.RecordSObjectTypeNamespace__c,
            'logEntry.RecordSObjectTypeNamespace__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.RecordId__c, logEntry.RecordId__c, 'logEntry.RecordId__c was not properly set');
        System.Assert.areEqual(logEntryEvent.RecordJson__c, logEntry.RecordJson__c, 'logEntry.RecordJson__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.RecordSObjectClassification__c,
            logEntry.RecordSObjectClassification__c,
            'logEntry.RecordSObjectClassification__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.RecordSObjectType__c, logEntry.RecordSObjectType__c, 'logEntry.RecordSObjectType__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.RecordSObjectTypeNamespace__c,
            logEntry.RecordSObjectTypeNamespace__c,
            'logEntry.RecordSObjectTypeNamespace__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.StackTrace__c, logEntry.StackTrace__c, 'logEntry.StackTrace__c was not properly set');
        System.Assert.areEqual(logEntryEvent.Timestamp__c, logEntry.Timestamp__c, 'logEntry.Timestamp__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.TransactionEntryNumber__c,
            logEntry.TransactionEntryNumber__c,
            'logEntry.TransactionEntryNumber__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.TriggerIsExecuting__c, logEntry.TriggerIsExecuting__c, 'logEntry.TriggerIsExecuting__c was not properly set');
        System.Assert.areEqual(
            logEntryEvent.TriggerOperationType__c,
            logEntry.TriggerOperationType__c,
            'logEntry.TriggerOperationType__c was not properly set'
        );
        System.Assert.areEqual(logEntryEvent.TriggerSObjectType__c, logEntry.TriggerSObjectType__c, 'logEntry.TriggerSObjectType__c was not properly set');
    }
}
