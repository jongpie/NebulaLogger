//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount, PMD.NcssTypeCount')
@IsTest(IsParallel=false)
private class Logger_Tests {
    @IsTest
    static void it_should_return_version_number() {
        String expectedVersionNumber = Logger.CURRENT_VERSION_NUMBER;

        String returnedVersionNumber = Logger.getVersionNumber();

        System.assertEquals(expectedVersionNumber, returnedVersionNumber);
    }

    @IsTest
    static void it_should_return_namespace_prefix() {
        String className = Logger_Tests.class.getName();
        String expectedNamespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

        String returnedNamespacePrefix = Logger.getNamespacePrefix();

        System.assertEquals(expectedNamespacePrefix, returnedNamespacePrefix);
    }

    @IsTest
    static void it_should_use_in_memory_default_settings_when_not_configured() {
        LoggerSettings__c expectedSettings = (LoggerSettings__c) LoggerSettings__c.SObjectType.newSObject(null, true);
        expectedSettings.SetupOwnerId = UserInfo.getUserId();

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.assertEquals(0, existingSettings.size(), 'LoggerSettings__c record should not have been saved');
        System.assertEquals(expectedSettings, returnedSettings);
        System.assertEquals(null, returnedSettings.Id);
    }

    @IsTest
    static void it_should_use_org_default_settings_when_configured() {
        LoggerSettings__c expectedSettings = LoggerSettings__c.getOrgDefaults();
        expectedSettings.LoggingLevel__c = LoggingLevel.FINEST.name();
        insert expectedSettings;
        expectedSettings = LoggerSettings__c.getOrgDefaults();
        expectedSettings.Id = null;
        expectedSettings.SetupOwnerId = UserInfo.getUserId();

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.assertEquals(1, existingSettings.size(), 'LoggerSettings__c org defaults should have been saved');
        System.assertEquals(expectedSettings, returnedSettings);
        System.assertEquals(null, returnedSettings.Id);
    }

    @IsTest
    static void it_should_use_profile_settings_when_configured() {
        insert LoggerSettings__c.getOrgDefaults();
        LoggerSettings__c expectedSettings = LoggerSettings__c.getOrgDefaults();
        expectedSettings.Id = null;
        expectedSettings.LoggingLevel__c = LoggingLevel.FINEST.name();
        expectedSettings.SetupOwnerId = UserInfo.getProfileId();
        insert expectedSettings;
        expectedSettings = LoggerSettings__c.getValues(UserInfo.getProfileId());
        expectedSettings.Id = null;
        expectedSettings.SetupOwnerId = UserInfo.getUserId();

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.assertEquals(2, existingSettings.size(), 'LoggerSettings__c org defaults and profile settings should have been saved');
        System.assertEquals(expectedSettings, returnedSettings);
        System.assertEquals(null, returnedSettings.Id);
    }

    @IsTest
    static void it_should_use_user_settings_when_configured() {
        insert LoggerSettings__c.getOrgDefaults();
        LoggerSettings__c profileSettings = LoggerSettings__c.getOrgDefaults();
        profileSettings.Id = null;
        profileSettings.LoggingLevel__c = LoggingLevel.DEBUG.name();
        profileSettings.SetupOwnerId = UserInfo.getProfileId();
        insert profileSettings;
        LoggerSettings__c expectedSettings = LoggerSettings__c.getOrgDefaults();
        expectedSettings.Id = null;
        expectedSettings.LoggingLevel__c = LoggingLevel.FINEST.name();
        expectedSettings.SetupOwnerId = UserInfo.getUserId();
        insert expectedSettings;
        expectedSettings = LoggerSettings__c.getValues(UserInfo.getUserId());

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.assertEquals(3, existingSettings.size(), 'LoggerSettings__c org defaults, profile settings, and user settings should have been saved');
        System.assertEquals(expectedSettings, returnedSettings);
        System.assertEquals(expectedSettings.Id, returnedSettings.Id);
    }

    @IsTest
    static void it_should_generate_a_valid_uuid() {
        Pattern pattern = Pattern.compile('[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}');

        Logger.Uuid uuid = new Logger.Uuid();

        System.assertEquals(36, uuid.getValue().length());
        Matcher matcher = pattern.matcher(uuid.getValue());
        System.assert(matcher.matches(), 'Generated UUID=' + uuid.getValue());
    }

    @IsTest
    static void it_should_return_uuid_transaction_id() {
        Pattern pattern = Pattern.compile('[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}');

        String transactionId = Logger.getTransactionId();

        System.assert(String.isNotBlank(transactionId));
        System.assertEquals(36, transactionId.length());
        Matcher matcher = pattern.matcher(transactionId);
        System.assert(matcher.matches(), 'Generated UUID=' + transactionId);
    }

    @IsTest
    static void it_should_set_logger_version_number() {
        for (Integer i = 0; i < 10; i++) {
            LogEntryEventBuilder builder = Logger.info('my log entry');

            System.assertNotEquals(null, builder.getLogEntryEvent().LoggerVersionNumber__c);
            System.assertEquals(Logger.CURRENT_VERSION_NUMBER, builder.getLogEntryEvent().LoggerVersionNumber__c);
        }
    }

    @IsTest
    static void it_should_set_transaction_entry_number() {
        for (Integer i = 0; i < 5; i++) {
            LogEntryEventBuilder builder = Logger.info('my log entry');

            System.assertEquals(i + 1, builder.getLogEntryEvent().TransactionEntryNumber__c);
        }
    }

    @IsTest
    static void it_should_set_scenario_when_default_scenario_configured() {
        String mockScenario = 'some test scenario for this transaction';
        LoggerSettings__c userSettings = LoggerSettings__c.getInstance();
        userSettings.DefaultLogScenario__c = mockScenario;
        upsert userSettings;

        String currentScenario = Logger.getScenario();

        System.assertEquals(
            mockScenario,
            currentScenario,
            'The value of LoggerSettings__c.DefaultLogScenario__c should have been used as the current transaction scenario'
        );
    }

    @IsTest
    static void it_should_set_scenario_when_specified() {
        String mockScenario = 'some test scenario for this transaction';

        Logger.setScenario(mockScenario);

        System.assertEquals(mockScenario, Logger.getScenario(), 'The mock scenario should have been used as the current transaction scenario');
    }

    @IsTest
    static void it_should_use_the_first_specified_scenario_when_parameter_is_true() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'UseFirstSpecifiedScenario', Value__c = String.valueOf(true)));
        String firstMockScenario = 'the first test scenario specified for this transaction';
        String secondMockScenario = 'the second test scenario specified for this transaction';

        Logger.setScenario(firstMockScenario);
        Logger.setScenario(secondMockScenario);

        System.assertEquals(firstMockScenario, Logger.getScenario(), 'The first specified scenario should have been used');
    }

    @IsTest
    static void it_should_use_the_last_specified_scenario_when_parameter_is_false() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'UseFirstSpecifiedScenario', Value__c = String.valueOf(false)));
        String firstMockScenario = 'the first test scenario specified for this transaction';
        String secondMockScenario = 'the second test scenario specified for this transaction';

        Logger.setScenario(firstMockScenario);
        Logger.setScenario(secondMockScenario);

        System.assertEquals(secondMockScenario, Logger.getScenario(), 'The last specified scenario should have been used');
    }

    @IsTest
    static void it_should_apply_scenario_rule_logging_level_when_scenario_is_set() {
        String mockScenario = 'some test scenario for this transaction';
        LogScenarioRule__mdt scenarioRule = new LogScenarioRule__mdt(Scenario__c = mockScenario, UserLoggingLevel__c = LoggingLevel.FINER.name());
        Logger.setMockScenarioRule(scenarioRule);
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        System.assertNotEquals(scenarioRule.UserLoggingLevel__c, Logger.getUserSettings().LoggingLevel__c);

        Logger.setScenario(mockScenario);

        System.assertEquals(scenarioRule.UserLoggingLevel__c, Logger.getUserSettings().LoggingLevel__c);
    }

    @IsTest
    static void it_should_set_scenario_when_platform_events_are_published() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String mockScenario = 'some test scenario for this transaction';

        Logger.info('hello');
        Logger.setScenario(mockScenario);
        Logger.info('world');
        Logger.saveLog();

        System.assertEquals(2, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        for (LogEntryEvent__e logEntryEvent : (List<LogEntryEvent__e>) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents()) {
            System.assertEquals(mockScenario, logEntryEvent.Scenario__c);
        }
    }

    @IsTest
    static void it_should_set_parent_transaction_id() {
        String expectedParentTransactionId = 'imagineThisWereAGuid';

        Logger.setParentLogTransactionId(expectedParentTransactionId);

        System.assertEquals(expectedParentTransactionId, Logger.getParentLogTransactionId());
    }

    @IsTest
    static void it_should_ignore_parent_transaction_id_when_set_to_current_transaction_id() {
        String currentTransactionId = Logger.getTransactionId();

        Logger.setParentLogTransactionId(currentTransactionId);

        System.assertEquals(null, Logger.getParentLogTransactionId());
    }

    @IsTest
    static void it_should_return_quiddity_level() {
        List<Quiddity> acceptableDefaultQuidditiesForTests = new List<Quiddity>{ Quiddity.RUNTEST_ASYNC, Quiddity.RUNTEST_DEPLOY, Quiddity.RUNTEST_SYNC };

        Quiddity currentQuiddity = Logger.getCurrentQuiddity();

        System.assertEquals(true, acceptableDefaultQuidditiesForTests.contains(currentQuiddity));
        System.assertEquals(System.Request.getCurrent().getQuiddity(), currentQuiddity);
    }

    @IsTest
    static void it_should_return_user_logging_level() {
        LoggingLevel expectedLoggingLevel = LoggingLevel.FINE;
        Logger.getUserSettings().LoggingLevel__c = expectedLoggingLevel.name();

        LoggingLevel returnedLoggingLevel = Logger.getUserLoggingLevel();

        System.assertEquals(expectedLoggingLevel, returnedLoggingLevel);
    }

    @IsTest
    static void it_should_return_true_when_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;

        Boolean returnedValue = Logger.isEnabled();

        System.assertEquals(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_provided_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();

        Boolean returnedValue = Logger.isEnabled(loggingLevel);

        System.assertEquals(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_error_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();

        Boolean returnedValue = Logger.isErrorEnabled();

        System.assertEquals(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_warn_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.WARN.name();

        Boolean returnedValue = Logger.isWarnEnabled();

        System.assertEquals(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_info_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.INFO.name();

        Boolean returnedValue = Logger.isInfoEnabled();

        System.assertEquals(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_debug_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.DEBUG.name();

        Boolean returnedValue = Logger.isDebugEnabled();

        System.assertEquals(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_fine_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINE.name();

        Boolean returnedValue = Logger.isFineEnabled();

        System.assertEquals(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_finer_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINER.name();

        Boolean returnedValue = Logger.isFinerEnabled();

        System.assertEquals(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_finest_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();

        Boolean returnedValue = Logger.isFinestEnabled();

        System.assertEquals(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_saving_is_suspended() {
        System.assertEquals(false, Logger.isSavingSuspended());

        Logger.suspendSaving();

        System.assertEquals(true, Logger.isSavingSuspended());
    }

    @IsTest
    static void it_should_suspend_saving() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfExistingLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfExistingLogEntries);

        System.Test.startTest();

        Logger.getUserSettings().IsEnabled__c = true;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.DEBUG.name();

        Logger.suspendSaving();

        Logger.debug('test log entry');
        Logger.saveLog();

        System.Test.stopTest();

        countOfExistingLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfExistingLogEntries);
    }

    @IsTest
    static void it_should_resume_saving() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        System.Test.startTest();

        Logger.getUserSettings().IsEnabled__c = true;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();

        Integer logEntriesToCreate = 4;

        Logger.suspendSaving();
        System.assertEquals(true, Logger.isSavingSuspended());

        for (Integer i = 0; i < logEntriesToCreate; i++) {
            Logger.info('test log entry #' + i);
        }
        System.assertEquals(logEntriesToCreate, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(logEntriesToCreate, Logger.getBufferSize());
        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        Logger.resumeSaving();
        System.assertEquals(false, Logger.isSavingSuspended());

        Logger.saveLog();

        System.Test.getEventBus().deliver();

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(logEntriesToCreate, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_accurate_timestamp_when_logging_user_has_different_time_zone() {
        // TODO Move this test to LogEntryEventBuilder_Tests, see if there's a way to eliminate creating a user
        User automatedProcessUser = [SELECT Id, TimeZoneSidKey FROM User WHERE Name = 'Automated Process' AND Profile.Name = NULL];
        User testStandardUser = LoggerMockDataCreator.createUser();
        // Make sure that the test user has a different time zone from the automated process user
        if (automatedProcessUser.TimeZoneSidKey == testStandardUser.TimeZoneSidKey) {
            switch on automatedProcessUser.TimeZoneSidKey {
                when 'America/Los_Angeles' {
                    testStandardUser.TimeZoneSidKey = 'America/New_York';
                }
                when else {
                    testStandardUser.TimeZoneSidKey = 'America/Los_Angeles';
                }
            }
            System.assertNotEquals(automatedProcessUser.TimeZoneSidKey, testStandardUser.TimeZoneSidKey);
        }

        Datetime originalTimestamp;
        System.runAs(testStandardUser) {
            Logger.getUserSettings().IsEnabled__c = true;
            Logger.getUserSettings().LoggingLevel__c = LoggingLevel.INFO.name();

            LogEntryEventBuilder builder = Logger.info('test log entry');
            originalTimestamp = builder.getLogEntryEvent().TimeStamp__c;
            System.assertNotEquals(null, originalTimestamp);

            System.assertEquals(1, Logger.getBufferSize());
            Logger.saveLog();

            System.Test.getEventBus().deliver();
        }

        LogEntry__c logEntry = [SELECT Id, Timestamp__c FROM LogEntry__c];
        System.assertEquals(originalTimestamp, logEntry.Timestamp__c);
    }

    @IsTest
    static void it_should_return_the_buffer_size() {
        System.assertEquals(0, Logger.getBufferSize());

        Logger.debug('test log entry');
        Logger.warn('another test log entry');

        System.assertEquals(2, Logger.getBufferSize());
    }

    @IsTest
    static void it_should_not_save_when_saving_is_disabled() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.getUserSettings().IsSavingEnabled__c = false;

        System.assertEquals(Logger.SaveMethod.EVENT_BUS, Logger.getSaveMethod());

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getPublishImmediateDml());

        System.Test.startTest();

        Logger.saveLog();
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_via_event_bus_when_defaulted() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.getUserSettings().DefaultSaveMethod__c = 'EVENT_BUS';

        System.assertEquals(Logger.SaveMethod.EVENT_BUS, Logger.getSaveMethod());

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getPublishImmediateDml());

        System.Test.startTest();

        Logger.saveLog();
        System.assertEquals(1, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(2, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_via_event_bus_when_specified_via_settings() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getPublishImmediateDml());

        System.Test.startTest();

        Logger.saveLog(Logger.SaveMethod.EVENT_BUS);
        System.assertEquals(1, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(2, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_via_event_bus_when_specified_via_setSaveMethod() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getPublishImmediateDml());

        System.Test.startTest();

        Logger.SaveMethod expectedSaveMethod = Logger.SaveMethod.EVENT_BUS;
        Logger.setSaveMethod(expectedSaveMethod);
        System.assertEquals(expectedSaveMethod, Logger.getSaveMethod());
        Logger.saveLog();
        System.assertEquals(1, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(2, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_via_queueable_when_defaulted() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.DEBUG.name();
        Logger.getUserSettings().DefaultSaveMethod__c = 'QUEUEABLE';
        upsert Logger.getUserSettings();

        System.Test.startTest();

        System.assertEquals(Logger.SaveMethod.QUEUEABLE, Logger.getSaveMethod());

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(2, Logger.getBufferSize());
        System.assertEquals(0, Limits.getQueueableJobs());

        Logger.saveLog();

        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(1, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(2, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_via_queueable_when_specified_via_settings() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getQueueableJobs());

        System.Test.startTest();

        Logger.saveLog(Logger.SaveMethod.QUEUEABLE);
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(1, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());

        System.Test.getEventBus().deliver();

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(2, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_via_queueable_when_specified_via_setSaveMethod() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getQueueableJobs());

        System.Test.startTest();

        Logger.SaveMethod expectedSaveMethod = Logger.SaveMethod.QUEUEABLE;
        Logger.setSaveMethod(expectedSaveMethod);
        System.assertEquals(expectedSaveMethod, Logger.getSaveMethod());
        Logger.saveLog();
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(1, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());

        System.Test.getEventBus().deliver();

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(2, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_via_rest_api_when_defaulted() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        System.Test.setMock(HttpCalloutMock.class, LoggerMockDataCreator.createHttpCallout().setStatusCode(200));

        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.getUserSettings().DefaultSaveMethod__c = 'REST';

        System.assertEquals(Logger.SaveMethod.REST, Logger.getSaveMethod());

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getCallouts());

        System.Test.startTest();

        Logger.saveLog();
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(1, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());

        System.Test.stopTest();
    }

    @IsTest
    static void it_should_save_via_rest_api_when_specified_via_settings() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        System.Test.setMock(HttpCalloutMock.class, LoggerMockDataCreator.createHttpCallout().setStatusCode(200));

        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getCallouts());

        System.Test.startTest();

        Logger.saveLog(Logger.SaveMethod.REST);
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(1, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());

        System.Test.stopTest();
    }

    @IsTest
    static void it_should_save_via_rest_api_when_specified_via_setSaveMethod() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        System.Test.setMock(HttpCalloutMock.class, LoggerMockDataCreator.createHttpCallout().setStatusCode(200));

        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getCallouts());

        System.Test.startTest();

        Logger.SaveMethod expectedSaveMethod = Logger.SaveMethod.REST;
        Logger.setSaveMethod(expectedSaveMethod);
        System.assertEquals(expectedSaveMethod, Logger.getSaveMethod());
        Logger.saveLog();
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(1, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());

        System.Test.stopTest();
    }

    @IsTest
    static void it_should_throw_exception_when_save_via_rest_api_fails() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        System.Test.setMock(HttpCalloutMock.class, LoggerMockDataCreator.createHttpCallout().setStatusCode(400));

        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getCallouts());

        System.Test.startTest();

        try {
            Logger.saveLog(Logger.SaveMethod.REST);
        } catch (Exception ex) {
            System.assertEquals(CalloutException.class.getName(), ex.getTypeName());
        }
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(1, Limits.getCallouts());
        System.assertEquals(0, Limits.getDmlStatements());

        System.Test.stopTest();
    }

    @IsTest
    static void it_should_save_via_synchronous_dml_when_defaulted() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        LoggerSObjectHandler.setMock(
            new LoggerSObjectHandler__mdt(
                DeveloperName = 'Mock_Log_Entry_Event_Config',
                IsEnabled__c = true,
                SObjectHandlerApexClass__c = MockSObjectHandler.class.getName(),
                SObjectType__c = Schema.LogEntryEvent__e.SObjectType.getDescribe().getName()
            )
        );
        Logger.getUserSettings().DefaultSaveMethod__c = Logger.SaveMethod.SYNCHRONOUS_DML.name();
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.DEBUG.name();
        System.assertEquals(LoggingLevel.DEBUG, Logger.getUserLoggingLevel());
        System.assertEquals(Logger.SaveMethod.SYNCHRONOUS_DML, Logger.getSaveMethod());
        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        logEntryEvents.add(Logger.debug('test log entry').getLogEntryEvent());
        logEntryEvents.add(Logger.debug('another test log entry').getLogEntryEvent());
        System.Test.startTest();
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        System.assertEquals(logEntryEvents.size(), Logger.getBufferSize());

        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        MockSObjectHandler mockLogEntryEventBeforeInsertHandler = (MockSObjectHandler) LoggerSObjectHandler.getExecutedHandlers()
            .get(Schema.LogEntryEvent__e.SObjectType)
            .get(0);
        // System.assertEquals(1, mockLogEntryEventBeforeInsertHandler.executionCount);
        System.assertEquals(TriggerOperation.BEFORE_INSERT, mockLogEntryEventBeforeInsertHandler.executedTriggerOperationType);
        System.assertEquals(logEntryEvents.size(), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.size());
        System.assertEquals(logEntryEvents.get(0), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.get(0));
        System.assertEquals(logEntryEvents.get(1), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.get(1));
        MockSObjectHandler mockLogEntryEventAfterInsertHandler = (MockSObjectHandler) LoggerSObjectHandler.getExecutedHandlers()
            .get(Schema.LogEntryEvent__e.SObjectType)
            .get(1);
        // System.assertEquals(1, mockLogEntryEventAfterInsertHandler.executionCount);
        System.assertEquals(TriggerOperation.AFTER_INSERT, mockLogEntryEventAfterInsertHandler.executedTriggerOperationType);
        System.assertEquals(logEntryEvents.size(), mockLogEntryEventAfterInsertHandler.executedTriggerNew.size());
        System.assertEquals(logEntryEvents.get(0), mockLogEntryEventAfterInsertHandler.executedTriggerNew.get(0));
        System.assertEquals(logEntryEvents.get(1), mockLogEntryEventAfterInsertHandler.executedTriggerNew.get(1));
        System.Test.stopTest();
    }

    @IsTest
    static void it_should_save_via_synchronous_dml_when_specified_via_settings() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        LoggerSObjectHandler.setMock(
            new LoggerSObjectHandler__mdt(
                DeveloperName = 'Mock_Log_Entry_Event_Config',
                IsEnabled__c = true,
                SObjectHandlerApexClass__c = MockSObjectHandler.class.getName(),
                SObjectType__c = Schema.LogEntryEvent__e.SObjectType.getDescribe().getName()
            )
        );
        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        logEntryEvents.add(Logger.debug('test log entry').getLogEntryEvent());
        logEntryEvents.add(Logger.debug('another test log entry').getLogEntryEvent());
        System.Test.startTest();
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        System.assertEquals(logEntryEvents.size(), Logger.getBufferSize());

        Logger.getUserSettings().DefaultSaveMethod__c = Logger.SaveMethod.SYNCHRONOUS_DML.name();
        System.assertEquals(Logger.SaveMethod.SYNCHRONOUS_DML, Logger.getSaveMethod());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        MockSObjectHandler mockLogEntryEventBeforeInsertHandler = (MockSObjectHandler) LoggerSObjectHandler.getExecutedHandlers()
            .get(Schema.LogEntryEvent__e.SObjectType)
            .get(0);
        // System.assertEquals(1, mockLogEntryEventBeforeInsertHandler.executionCount);
        System.assertEquals(TriggerOperation.BEFORE_INSERT, mockLogEntryEventBeforeInsertHandler.executedTriggerOperationType);
        System.assertEquals(logEntryEvents.size(), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.size());
        System.assertEquals(logEntryEvents.get(0), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.get(0));
        System.assertEquals(logEntryEvents.get(1), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.get(1));
        MockSObjectHandler mockLogEntryEventAfterInsertHandler = (MockSObjectHandler) LoggerSObjectHandler.getExecutedHandlers()
            .get(Schema.LogEntryEvent__e.SObjectType)
            .get(1);
        // System.assertEquals(1, mockLogEntryEventAfterInsertHandler.executionCount);
        System.assertEquals(TriggerOperation.AFTER_INSERT, mockLogEntryEventAfterInsertHandler.executedTriggerOperationType);
        System.assertEquals(logEntryEvents.size(), mockLogEntryEventAfterInsertHandler.executedTriggerNew.size());
        System.assertEquals(logEntryEvents.get(0), mockLogEntryEventAfterInsertHandler.executedTriggerNew.get(0));
        System.assertEquals(logEntryEvents.get(1), mockLogEntryEventAfterInsertHandler.executedTriggerNew.get(1));
        System.Test.stopTest();
    }

    @IsTest
    static void it_should_save_via_synchronous_dml_when_specified_via_setSaveMethod() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        LoggerSObjectHandler.setMock(
            new LoggerSObjectHandler__mdt(
                DeveloperName = 'Mock_Log_Entry_Event_Config',
                IsEnabled__c = true,
                SObjectHandlerApexClass__c = MockSObjectHandler.class.getName(),
                SObjectType__c = Schema.LogEntryEvent__e.SObjectType.getDescribe().getName()
            )
        );
        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        logEntryEvents.add(Logger.debug('test log entry').getLogEntryEvent());
        logEntryEvents.add(Logger.debug('another test log entry').getLogEntryEvent());
        System.Test.startTest();
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        System.assertEquals(logEntryEvents.size(), Logger.getBufferSize());

        Logger.SaveMethod expectedSaveMethod = Logger.SaveMethod.SYNCHRONOUS_DML;
        Logger.setSaveMethod(expectedSaveMethod);
        System.assertEquals(expectedSaveMethod, Logger.getSaveMethod());
        Logger.saveLog();

        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());
        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        MockSObjectHandler mockLogEntryEventBeforeInsertHandler = (MockSObjectHandler) LoggerSObjectHandler.getExecutedHandlers()
            .get(Schema.LogEntryEvent__e.SObjectType)
            .get(0);
        // System.assertEquals(1, mockLogEntryEventBeforeInsertHandler.executionCount);
        System.assertEquals(TriggerOperation.BEFORE_INSERT, mockLogEntryEventBeforeInsertHandler.executedTriggerOperationType);
        System.assertEquals(logEntryEvents.size(), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.size());
        System.assertEquals(logEntryEvents.get(0), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.get(0));
        System.assertEquals(logEntryEvents.get(1), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.get(1));
        MockSObjectHandler mockLogEntryEventAfterInsertHandler = (MockSObjectHandler) LoggerSObjectHandler.getExecutedHandlers()
            .get(Schema.LogEntryEvent__e.SObjectType)
            .get(1);
        // System.assertEquals(1, mockLogEntryEventAfterInsertHandler.executionCount);
        System.assertEquals(TriggerOperation.AFTER_INSERT, mockLogEntryEventAfterInsertHandler.executedTriggerOperationType);
        System.assertEquals(logEntryEvents.size(), mockLogEntryEventAfterInsertHandler.executedTriggerNew.size());
        System.assertEquals(logEntryEvents.get(0), mockLogEntryEventAfterInsertHandler.executedTriggerNew.get(0));
        System.assertEquals(logEntryEvents.get(1), mockLogEntryEventAfterInsertHandler.executedTriggerNew.get(1));
        System.Test.stopTest();
    }

    @IsTest
    static void it_should_flush_buffer() {
        Logger.debug('test log entry');
        Logger.debug('another test log entry');
        System.assertEquals(2, Logger.getBufferSize());

        Logger.flushBuffer();

        System.assertEquals(0, Logger.getBufferSize());
    }

    // Start ERROR methods for LogMessage
    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), deleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), saveResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), undeleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordId_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord().Id, getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_record_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord(), getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordList_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), users, getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End ERROR methods for LogMessage

    // Start ERROR methods for String
    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), deleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), saveResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), undeleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_recordId_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord().Id, getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_record_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord(), getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_recordList_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), users, getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    // Start WARN methods for LogMessage
    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_recordId_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord().Id, getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_record_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord(), getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_recordList_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), users, getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End WARN methods for LogMessage

    // Start WARN methods for String
    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_recordId_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord().Id, getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_record_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord(), getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_recordList_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), users, getException());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End WARN methods for String

    // Start INFO methods for LogMessage
    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), deleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), saveResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), undeleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), upsertResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End INFO methods for LogMessage

    // Start INFO methods for String
    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), deleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), saveResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), undeleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), upsertResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End INFO methods for String

    // Start DEBUG methods for LogMessage
    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), deleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), saveResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), undeleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), upsertResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End DEBUG methods for LogMessage

    // Start DEBUG methods for String
    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), deleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), saveResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), undeleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), upsertResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End DEBUG methods for String

    // Start FINE methods for LogMessage
    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), deleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), saveResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), undeleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), upsertResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End FINE methods for LogMessage

    // Start FINE methods for String
    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), deleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), saveResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), undeleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), upsertResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End FINE methods for String

    // Start FINER methods for LogMessage
    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), deleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), saveResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), undeleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), upsertResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End FINER methods for LogMessage

    // Start FINER methods for String
    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), deleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), saveResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), undeleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), upsertResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End FINER methods for String

    // Start FINEST methods for LogMessage
    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), deleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), saveResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), undeleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), upsertResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End FINEST methods for LogMessage

    // Start FINEST methods for String
    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), deleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), saveResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), upsertResult);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_deleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), deleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_saveResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), saveResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_undeleteResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), undeleteResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_upsertResultList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), upsertResults);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), getRecord());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_recordList() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), users);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End FINEST methods for String

    // Start logDatabaseErrors() test methods
    @IsTest
    static void it_should_skip_logging_database_deleteResult_for_logMessage_when_logging_level_is_disabled() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.DeleteResult successfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        Database.DeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(false, recordId);
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, deleteResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, deleteResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_skip_logging_database_deleteResult_for_logMessage_when_no_errors_found() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.DeleteResult successfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        Database.DeleteResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>{ successfulResult, anotherSuccessfulResult };
        System.assertEquals(2, deleteResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, deleteResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_log_database_deleteResult_for_logMessage_when_isSuccess_is_false() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.DeleteResult successfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        Database.DeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(false, recordId);
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, deleteResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, deleteResults);

        System.assertEquals(1, Logger.getBufferSize());
        System.assertNotEquals(null, returnedBuilder);
        System.assertEquals(logMessage.getMessage(), returnedBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.DeleteResult>{ unsuccessfulResult });
        System.assertEquals(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_deleteResult_for_string_message_when_logging_level_is_disabled() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.DeleteResult successfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        Database.DeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(false, recordId);
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, deleteResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, deleteResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_skip_logging_database_deleteResult_for_string_message_when_no_errors_found() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.DeleteResult successfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        Database.DeleteResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>{ successfulResult, anotherSuccessfulResult };
        System.assertEquals(2, deleteResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, deleteResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_log_database_deleteResult_for_string_message_when_isSuccess_is_false() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.DeleteResult successfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        Database.DeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(false, recordId);
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, deleteResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, deleteResults);

        System.assertEquals(1, Logger.getBufferSize());
        System.assertNotEquals(null, returnedBuilder);
        System.assertEquals(message, returnedBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.DeleteResult>{ unsuccessfulResult });
        System.assertEquals(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_mergeResult_for_logMessage_when_logging_level_is_disabled() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.MergeResult successfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        Database.MergeResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseMergeResult(false, recordId);
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, mergeResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, mergeResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_skip_logging_database_mergeResult_for_logMessage_when_no_errors_found() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.MergeResult successfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        Database.MergeResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>{ successfulResult, anotherSuccessfulResult };
        System.assertEquals(2, mergeResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, mergeResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_log_database_mergeResult_for_logMessage_when_isSuccess_is_false() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.MergeResult successfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        Database.MergeResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseMergeResult(false, recordId);
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, mergeResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, mergeResults);

        System.assertEquals(1, Logger.getBufferSize());
        System.assertNotEquals(null, returnedBuilder);
        System.assertEquals(logMessage.getMessage(), returnedBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.MergeResult>{ unsuccessfulResult });
        System.assertEquals(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_mergeResult_for_string_message_when_logging_level_is_disabled() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.MergeResult successfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        Database.MergeResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseMergeResult(false, recordId);
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, mergeResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, mergeResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_skip_logging_database_mergeResult_for_string_message_when_no_errors_found() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.MergeResult successfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        Database.MergeResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>{ successfulResult, anotherSuccessfulResult };
        System.assertEquals(2, mergeResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, mergeResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_log_database_mergeResult_for_string_message_when_isSuccess_is_false() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.MergeResult successfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        Database.MergeResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseMergeResult(false, recordId);
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, mergeResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, mergeResults);

        System.assertEquals(1, Logger.getBufferSize());
        System.assertNotEquals(null, returnedBuilder);
        System.assertEquals(message, returnedBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.MergeResult>{ unsuccessfulResult });
        System.assertEquals(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_saveResult_for_logMessage_when_logging_level_is_disabled() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.SaveResult successfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        Database.SaveResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseSaveResult(false, recordId);
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, saveResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, saveResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_skip_logging_database_saveResult_for_logMessage_when_no_errors_found() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.SaveResult successfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        Database.SaveResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ successfulResult, anotherSuccessfulResult };
        System.assertEquals(2, saveResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, saveResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_log_database_saveResult_for_logMessage_when_isSuccess_is_false() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.SaveResult successfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        Database.SaveResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseSaveResult(false, recordId);
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, saveResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, saveResults);

        System.assertEquals(1, Logger.getBufferSize());
        System.assertNotEquals(null, returnedBuilder);
        System.assertEquals(logMessage.getMessage(), returnedBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.SaveResult>{ unsuccessfulResult });
        System.assertEquals(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_saveResult_for_string_message_when_logging_level_is_disabled() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.SaveResult successfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        Database.SaveResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseSaveResult(false, recordId);
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, saveResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, saveResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_skip_logging_database_saveResult_for_string_message_when_no_errors_found() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.SaveResult successfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        Database.SaveResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ successfulResult, anotherSuccessfulResult };
        System.assertEquals(2, saveResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, saveResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_log_database_saveResult_for_string_message_when_isSuccess_is_false() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.SaveResult successfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        Database.SaveResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseSaveResult(false, recordId);
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, saveResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, saveResults);

        System.assertEquals(1, Logger.getBufferSize());
        System.assertNotEquals(null, returnedBuilder);
        System.assertEquals(message, returnedBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.SaveResult>{ unsuccessfulResult });
        System.assertEquals(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_upsertResult_for_logMessage_when_logging_level_is_disabled() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.UpsertResult successfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        Database.UpsertResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true, recordId);
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, upsertResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, upsertResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_skip_logging_database_upsertResult_for_logMessage_when_no_errors_found() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.UpsertResult successfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        Database.UpsertResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>{ successfulResult, anotherSuccessfulResult };
        System.assertEquals(2, upsertResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, upsertResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_log_database_upsertResult_for_logMessage_when_isSuccess_is_false() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.UpsertResult successfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        Database.UpsertResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true, recordId);
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, upsertResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, upsertResults);

        System.assertEquals(1, Logger.getBufferSize());
        System.assertNotEquals(null, returnedBuilder);
        System.assertEquals(logMessage.getMessage(), returnedBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.UpsertResult>{ unsuccessfulResult });
        System.assertEquals(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_upsertResult_for_string_message_when_logging_level_is_disabled() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.UpsertResult successfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        Database.UpsertResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true, recordId);
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, upsertResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, upsertResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_skip_logging_database_upsertResult_for_string_message_when_no_errors_found() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.UpsertResult successfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        Database.UpsertResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>{ successfulResult, anotherSuccessfulResult };
        System.assertEquals(2, upsertResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, upsertResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_log_database_upsertResult_for_string_message_when_isSuccess_is_false() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.UpsertResult successfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        Database.UpsertResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true, recordId);
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, upsertResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, upsertResults);

        System.assertEquals(1, Logger.getBufferSize());
        System.assertNotEquals(null, returnedBuilder);
        System.assertEquals(message, returnedBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.UpsertResult>{ unsuccessfulResult });
        System.assertEquals(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_undeleteResult_for_logMessage_when_logging_level_is_disabled() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.UndeleteResult successfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        Database.UndeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(false, recordId);
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, undeleteResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, undeleteResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_skip_logging_database_undeleteResult_for_logMessage_when_no_errors_found() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.UndeleteResult successfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        Database.UndeleteResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>{ successfulResult, anotherSuccessfulResult };
        System.assertEquals(2, undeleteResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, undeleteResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_log_database_undeleteResult_for_logMessage_when_isSuccess_is_false() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', UserInfo.getUserId());
        Id recordId = UserInfo.getUserId();
        Database.UndeleteResult successfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        Database.UndeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(false, recordId);
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, undeleteResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, undeleteResults);

        System.assertEquals(1, Logger.getBufferSize());
        System.assertNotEquals(null, returnedBuilder);
        System.assertEquals(logMessage.getMessage(), returnedBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.UndeleteResult>{ unsuccessfulResult });
        System.assertEquals(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_undeleteResult_for_string_message_when_logging_level_is_disabled() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.UndeleteResult successfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        Database.UndeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(false, recordId);
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, undeleteResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, undeleteResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_skip_logging_database_undeleteResult_for_string_message_when_no_errors_found() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.UndeleteResult successfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        Database.UndeleteResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>{ successfulResult, anotherSuccessfulResult };
        System.assertEquals(2, undeleteResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, undeleteResults);

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(null, returnedBuilder);
    }

    @IsTest
    static void it_should_log_database_undeleteResult_for_string_message_when_isSuccess_is_false() {
        LoggingLevel logEntryLevel = LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = UserInfo.getUserId();
        Database.UndeleteResult successfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        Database.UndeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(false, recordId);
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>{ successfulResult, unsuccessfulResult };
        System.assertEquals(2, undeleteResults.size());
        System.assertEquals(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, undeleteResults);

        System.assertEquals(1, Logger.getBufferSize());
        System.assertNotEquals(null, returnedBuilder);
        System.assertEquals(message, returnedBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.UndeleteResult>{ unsuccessfulResult });
        System.assertEquals(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }
    // End logDatabaseErrors() test methods

    // Start newEntry for LogMessage test methods
    @IsTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_logMessage_and_shouldSave_override() {
        LoggingLevel userLoggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        LoggingLevel logEntryLoggingLevel = LoggingLevel.FINEST;
        System.assertEquals(false, Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        Boolean shouldSave = true;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getLogMessage(), shouldSave);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(shouldSave, entryBuilder.shouldSave());
        System.assertEquals(logEntryLoggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_not_add_a_new_entry_for_loggingLevel_with_logMessage_and_shouldNotSave_override() {
        LoggingLevel userLoggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        LoggingLevel logEntryLoggingLevel = LoggingLevel.FINEST;
        System.assertEquals(false, Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        Boolean shouldSave = false;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getLogMessage(), shouldSave);

        System.Test.stopTest();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(shouldSave, entryBuilder.shouldSave());
        System.assertEquals(null, entryBuilder.getLogEntryEvent());
    }

    @IsTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.newEntry(loggingLevel, getLogMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(true, entryBuilder.shouldSave());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End newEntry for LogMessage test methods

    // Start newEntry for String test methods
    @IsTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_string_and_shouldSave_override() {
        LoggingLevel userLoggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        LoggingLevel logEntryLoggingLevel = LoggingLevel.FINEST;
        System.assertEquals(false, Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        Boolean shouldSave = true;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getMessage(), shouldSave);

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(shouldSave, entryBuilder.shouldSave());
        System.assertEquals(logEntryLoggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_not_add_a_new_entry_for_loggingLevel_with_string_and_shouldNotSave_override() {
        LoggingLevel userLoggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        LoggingLevel logEntryLoggingLevel = LoggingLevel.FINEST;
        System.assertEquals(false, Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        Boolean shouldSave = false;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getMessage(), shouldSave);

        System.Test.stopTest();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(shouldSave, entryBuilder.shouldSave());
        System.assertEquals(null, entryBuilder.getLogEntryEvent());
    }

    @IsTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_string() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.newEntry(loggingLevel, getMessage());

        System.Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(true, entryBuilder.shouldSave());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End newEntry for String test methods

    // Start tests for utility methods
    @IsTest
    static void it_should_return_logging_levels_for_string_names() {
        System.assertEquals(LoggingLevel.DEBUG, Logger.getLoggingLevel('fake'));
        System.assertEquals(LoggingLevel.NONE, Logger.getLoggingLevel('none'));
        System.assertEquals(LoggingLevel.ERROR, Logger.getLoggingLevel('error'));
        System.assertEquals(LoggingLevel.WARN, Logger.getLoggingLevel('warn'));
        System.assertEquals(LoggingLevel.INFO, Logger.getLoggingLevel('info'));
        System.assertEquals(LoggingLevel.DEBUG, Logger.getLoggingLevel('debug'));
        System.assertEquals(LoggingLevel.FINE, Logger.getLoggingLevel('fine'));
        System.assertEquals(LoggingLevel.FINER, Logger.getLoggingLevel('finer'));
        System.assertEquals(LoggingLevel.FINEST, Logger.getLoggingLevel('finest'));
    }
    // End tests for utility methods

    // Helper methods
    static void setUserLoggingLevel(LoggingLevel loggingLevel) {
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();
    }

    static String getMessage() {
        return 'Hello, world';
    }

    static LogMessage getLogMessage() {
        return new LogMessage('The current user is {0}', getRecord());
    }

    static SObject getRecord() {
        return new User(
            Id = UserInfo.getUserId(),
            ProfileId = UserInfo.getProfileId(),
            Username = UserInfo.getUserName(),
            UserRoleId = UserInfo.getUserRoleId()
        );
    }

    static Exception getException() {
        return new DmlException('Example DML Exception');
    }

    static List<Database.DeleteResult> getDeleteResultList() {
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>();
        for (Integer i = 0; i < 3; i++) {
            deleteResults.add(LoggerMockDataCreator.createDatabaseDeleteResult(true));
        }
        return deleteResults;
    }

    static List<Database.SaveResult> getSaveResultList() {
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        for (Integer i = 0; i < 3; i++) {
            saveResults.add(LoggerMockDataCreator.createDatabaseSaveResult(true));
        }
        return saveResults;
    }

    static List<Database.UpsertResult> getUpsertResultList() {
        List<Database.UpsertResult> upsertresults = new List<Database.UpsertResult>();
        for (Integer i = 0; i < 3; i++) {
            upsertresults.add(LoggerMockDataCreator.createDatabaseUpsertResult(true, true));
        }
        return upsertresults;
    }

    static List<Database.UndeleteResult> getUndeleteResultList() {
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>();
        for (Integer i = 0; i < 3; i++) {
            undeleteResults.add(LoggerMockDataCreator.createDatabaseUndeleteResult(true));
        }
        return undeleteResults;
    }

    static String getOriginLocation() {
        String originLocation;
        for (String currentStackTraceLine : new DmlException().getStackTraceString().split('\n')) {
            if (currentStackTraceLine.contains('Logger_Tests.getOriginLocation')) {
                continue;
            }
            if (currentStackTraceLine.contains('.LogEntryEventBuilder.')) {
                continue;
            }
            if (currentStackTraceLine.contains('.Logger.')) {
                continue;
            }
            originLocation = currentStackTraceLine.substringBefore(':');
            if (originLocation.startsWith('Class.')) {
                originLocation = originLocation.substringAfter('Class.');
            }
            break;
        }

        return originLocation;
    }

    public class MockSObjectHandler extends LoggerSObjectHandler {
        public Integer executionCount = 0;
        public TriggerOperation executedTriggerOperationType;
        public List<SObject> executedTriggerNew;
        public Map<Id, SObject> executedTriggerNewMap;
        public Map<Id, SObject> executedTriggerOldMap;

        private Schema.SObjectType sobjectType;

        public MockSObjectHandler() {
            this.sobjectType = Schema.LogEntryEvent__e.SObjectType;
        }

        public override Schema.SObjectType getSObjectType() {
            return this.sobjectType;
        }

        public MockSObjectHandler setSObjectType(Schema.SObjectType sobjectType) {
            this.sobjectType = sobjectType;
            return this;
        }

        protected override void executeBeforeInsert(List<SObject> triggerNew) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.BEFORE_INSERT;
            this.executedTriggerNew = triggerNew;
        }

        protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.BEFORE_UPDATE;
            this.executedTriggerNewMap = triggerNewMap;
            this.executedTriggerOldMap = triggerOldMap;
        }

        protected override void executeBeforeDelete(Map<Id, SObject> triggerNewMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.BEFORE_DELETE;
            this.executedTriggerNewMap = triggerNewMap;
        }

        protected override void executeAfterInsert(List<SObject> triggerNew) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_INSERT;
            this.executedTriggerNew = triggerNew;
        }

        protected override void executeAfterInsert(Map<Id, SObject> triggerNewMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_INSERT;
            this.executedTriggerNewMap = triggerNewMap;
        }

        protected override void executeAfterUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_UPDATE;
            this.executedTriggerNewMap = triggerNewMap;
            this.executedTriggerOldMap = triggerOldMap;
        }

        protected override void executeAfterDelete(Map<Id, SObject> triggerNewMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_DELETE;
            this.executedTriggerNewMap = triggerNewMap;
        }

        protected override void executeAfterUndelete(Map<Id, SObject> triggerNewMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_UNDELETE;
            this.executedTriggerNewMap = triggerNewMap;
        }
    }
}
