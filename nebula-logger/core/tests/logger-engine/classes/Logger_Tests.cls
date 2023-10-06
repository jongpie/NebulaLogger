//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount, PMD.NcssTypeCount')
@IsTest(IsParallel=true)
private class Logger_Tests {
    @IsTest
    static void it_should_return_version_number() {
        String expectedVersionNumber = Logger.CURRENT_VERSION_NUMBER;

        String returnedVersionNumber = Logger.getVersionNumber();

        System.Assert.areEqual(expectedVersionNumber, returnedVersionNumber);
    }

    @IsTest
    static void it_should_return_namespace_prefix() {
        String className = Logger_Tests.class.getName();
        String expectedNamespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

        String returnedNamespacePrefix = Logger.getNamespacePrefix();

        System.Assert.areEqual(expectedNamespacePrefix, returnedNamespacePrefix);
    }

    @IsTest
    static void it_should_return_organization_api_version() {
        String userJson = JSON.serialize(new User(Id = System.UserInfo.getUserId()));
        String expectedApiVersion = userJson.substringAfter('/data/').substringBefore('/sobjects/User');

        String returnedApiVersion = Logger.getOrganizationApiVersion();

        System.Assert.areEqual(expectedApiVersion, returnedApiVersion);
    }

    @IsTest
    static void it_should_create_new_in_memory_settings_with_default_field_values() {
        LoggerSettings__c expectedSettings = (LoggerSettings__c) Schema.LoggerSettings__c.SObjectType.newSObject(null, true);

        LoggerSettings__c returnedSettings = Logger.createSettings();

        System.Assert.areEqual(expectedSettings, returnedSettings);
        System.Assert.isNull(returnedSettings.Id);
        System.Assert.isTrue(returnedSettings.IsApexSystemDebugLoggingEnabled__c);
        System.Assert.isTrue(returnedSettings.IsJavaScriptConsoleLoggingEnabled__c);
        System.Assert.areEqual(System.LoggingLevel.FINEST.name(), returnedSettings.LoggingLevel__c);
        System.Assert.isNull(returnedSettings.SetupOwnerId);
    }

    @IsTest
    static void it_should_use_in_memory_default_settings_when_not_configured() {
        LoggerSettings__c expectedSettings = (LoggerSettings__c) LoggerSettings__c.SObjectType.newSObject(null, true);
        expectedSettings.IsApexSystemDebugLoggingEnabled__c = true;
        expectedSettings.IsJavaScriptConsoleLoggingEnabled__c = true;
        expectedSettings.LoggingLevel__c = System.LoggingLevel.FINEST.name();
        expectedSettings.SetupOwnerId = System.UserInfo.getUserId();

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        System.Assert.areEqual(expectedSettings, returnedSettings);
        System.Assert.isNull(returnedSettings.Id);
        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.Assert.areEqual(0, existingSettings.size(), 'LoggerSettings__c record should not have been saved');
    }

    @IsTest
    static void it_should_properly_set_default_field_values_for_settings() {
        LoggerSettings__c expectedSettings = (LoggerSettings__c) LoggerSettings__c.SObjectType.newSObject(null, true);
        expectedSettings.SetupOwnerId = System.UserInfo.getUserId();

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        System.Assert.areEqual(expectedSettings, returnedSettings);
        System.Assert.isNull(returnedSettings.Id);
        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.Assert.areEqual(0, existingSettings.size(), 'LoggerSettings__c record should not have been saved');
    }

    @IsTest
    static void it_should_use_org_default_settings_when_configured() {
        LoggerSettings__c expectedSettings = LoggerSettings__c.getOrgDefaults();
        expectedSettings.LoggingLevel__c = System.LoggingLevel.FINE.name();
        insert expectedSettings;
        expectedSettings = LoggerSettings__c.getOrgDefaults();
        expectedSettings.Id = null;
        expectedSettings.SetupOwnerId = System.UserInfo.getUserId();

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.Assert.areEqual(1, existingSettings.size(), 'LoggerSettings__c org defaults should have been saved');
        System.Assert.areEqual(expectedSettings, returnedSettings);
        System.Assert.isNull(returnedSettings.Id);
    }

    @IsTest
    static void it_should_not_use_org_default_settings_when_start_time_is_in_the_future() {
        LoggerSettings__c expectedSettings = Logger.createSettings();
        expectedSettings.SetupOwnerId = System.UserInfo.getUserId();
        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        orgDefaults.Id = null;
        orgDefaults.LoggingLevel__c = System.LoggingLevel.WARN.name();
        orgDefaults.SetupOwnerId = System.UserInfo.getOrganizationId();
        orgDefaults.StartTime__c = System.now().addDays(1);
        insert orgDefaults;

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.Assert.areEqual(1, existingSettings.size(), 'LoggerSettings__c org defaults settings should have been saved');
        System.Assert.areEqual(expectedSettings, returnedSettings);
        System.Assert.isNull(returnedSettings.Id);
    }

    @IsTest
    static void it_should_not_use_org_default_settings_when_end_time_is_in_the_past() {
        LoggerSettings__c expectedSettings = Logger.createSettings();
        expectedSettings.SetupOwnerId = System.UserInfo.getUserId();
        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        orgDefaults.Id = null;
        orgDefaults.LoggingLevel__c = System.LoggingLevel.WARN.name();
        orgDefaults.SetupOwnerId = System.UserInfo.getOrganizationId();
        orgDefaults.EndTime__c = System.now().addDays(-1);
        insert orgDefaults;

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.Assert.areEqual(1, existingSettings.size(), 'LoggerSettings__c org defaults settings should have been saved');
        System.Assert.areEqual(expectedSettings, returnedSettings);
        System.Assert.isNull(returnedSettings.Id);
    }

    @IsTest
    static void it_should_use_profile_settings_when_configured() {
        insert LoggerSettings__c.getOrgDefaults();
        LoggerSettings__c expectedSettings = LoggerSettings__c.getOrgDefaults();
        expectedSettings.Id = null;
        expectedSettings.LoggingLevel__c = System.LoggingLevel.WARN.name();
        expectedSettings.SetupOwnerId = System.UserInfo.getProfileId();
        insert expectedSettings;
        expectedSettings = LoggerSettings__c.getValues(System.UserInfo.getProfileId());
        expectedSettings.Id = null;
        expectedSettings.SetupOwnerId = System.UserInfo.getUserId();

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.Assert.areEqual(2, existingSettings.size(), 'LoggerSettings__c org defaults and profile settings should have been saved');
        System.Assert.areEqual(expectedSettings, returnedSettings);
        System.Assert.isNull(returnedSettings.Id);
    }

    @IsTest
    static void it_should_not_use_profile_settings_when_start_time_is_in_the_future() {
        LoggerSettings__c expectedSettings = LoggerSettings__c.getOrgDefaults();
        insert expectedSettings;
        expectedSettings = LoggerSettings__c.getOrgDefaults();
        expectedSettings.Id = null;
        expectedSettings.SetupOwnerId = System.UserInfo.getUserId();
        LoggerSettings__c profileSettings = expectedSettings.clone();
        profileSettings.Id = null;
        profileSettings.LoggingLevel__c = System.LoggingLevel.WARN.name();
        profileSettings.SetupOwnerId = System.UserInfo.getProfileId();
        profileSettings.StartTime__c = System.now().addDays(1);
        insert profileSettings;

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.Assert.areEqual(2, existingSettings.size(), 'LoggerSettings__c org defaults and profile settings should have been saved');
        System.Assert.areEqual(expectedSettings, returnedSettings);
        System.Assert.isNull(returnedSettings.Id);
    }

    @IsTest
    static void it_should_not_use_profile_settings_when_end_time_is_in_the_past() {
        LoggerSettings__c expectedSettings = LoggerSettings__c.getOrgDefaults();
        insert expectedSettings;
        expectedSettings = LoggerSettings__c.getOrgDefaults();
        expectedSettings.Id = null;
        expectedSettings.SetupOwnerId = System.UserInfo.getUserId();
        LoggerSettings__c profileSettings = expectedSettings.clone();
        profileSettings.Id = null;
        profileSettings.LoggingLevel__c = System.LoggingLevel.WARN.name();
        profileSettings.SetupOwnerId = System.UserInfo.getProfileId();
        profileSettings.EndTime__c = System.now().addDays(-1);
        insert profileSettings;

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.Assert.areEqual(2, existingSettings.size(), 'LoggerSettings__c org defaults and profile settings should have been saved');
        System.Assert.areEqual(expectedSettings, returnedSettings);
        System.Assert.isNull(returnedSettings.Id);
    }

    @IsTest
    static void it_should_use_user_settings_when_configured() {
        insert LoggerSettings__c.getOrgDefaults();
        LoggerSettings__c profileSettings = LoggerSettings__c.getOrgDefaults();
        profileSettings.Id = null;
        profileSettings.LoggingLevel__c = System.LoggingLevel.DEBUG.name();
        profileSettings.SetupOwnerId = System.UserInfo.getProfileId();
        insert profileSettings;
        LoggerSettings__c expectedSettings = LoggerSettings__c.getOrgDefaults();
        expectedSettings.Id = null;
        expectedSettings.LoggingLevel__c = System.LoggingLevel.WARN.name();
        expectedSettings.SetupOwnerId = System.UserInfo.getUserId();
        insert expectedSettings;
        expectedSettings = LoggerSettings__c.getValues(System.UserInfo.getUserId());

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.Assert.areEqual(3, existingSettings.size(), 'LoggerSettings__c org defaults, profile settings, and user settings should have been saved');
        System.Assert.areEqual(expectedSettings, returnedSettings);
        System.Assert.areEqual(expectedSettings.Id, returnedSettings.Id);
    }

    @IsTest
    static void it_should_not_use_user_settings_when_start_time_is_in_the_future() {
        LoggerSettings__c expectedSettings = LoggerSettings__c.getOrgDefaults();
        expectedSettings.SetupOwnerId = System.UserInfo.getProfileId();
        insert expectedSettings;
        expectedSettings = LoggerSettings__c.getValues(System.UserInfo.getProfileId());
        expectedSettings.Id = null;
        expectedSettings.SetupOwnerId = System.UserInfo.getUserId();
        LoggerSettings__c userSettings = expectedSettings.clone();
        userSettings.Id = null;
        userSettings.LoggingLevel__c = System.LoggingLevel.WARN.name();
        userSettings.SetupOwnerId = System.UserInfo.getUserId();
        userSettings.StartTime__c = System.now().addDays(1);
        insert userSettings;

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.Assert.areEqual(2, existingSettings.size(), 'LoggerSettings__c org defaults and profile settings should have been saved');
        System.Assert.areEqual(expectedSettings, returnedSettings);
        System.Assert.isNull(returnedSettings.Id);
    }

    @IsTest
    static void it_should_not_use_user_settings_when_end_time_is_in_the_past() {
        LoggerSettings__c expectedSettings = LoggerSettings__c.getOrgDefaults();
        expectedSettings.SetupOwnerId = System.UserInfo.getProfileId();
        insert expectedSettings;
        expectedSettings = LoggerSettings__c.getValues(System.UserInfo.getProfileId());
        expectedSettings.Id = null;
        expectedSettings.SetupOwnerId = System.UserInfo.getUserId();
        LoggerSettings__c userSettings = expectedSettings.clone();
        userSettings.Id = null;
        userSettings.LoggingLevel__c = System.LoggingLevel.WARN.name();
        userSettings.SetupOwnerId = System.UserInfo.getUserId();
        userSettings.EndTime__c = System.now().addDays(-1);
        insert userSettings;

        LoggerSettings__c returnedSettings = Logger.getUserSettings();

        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.Assert.areEqual(2, existingSettings.size(), 'LoggerSettings__c org defaults and profile settings should have been saved');
        System.Assert.areEqual(expectedSettings, returnedSettings);
        System.Assert.isNull(returnedSettings.Id);
    }

    @IsTest
    static void it_should_generate_a_valid_uuid() {
        Pattern pattern = Pattern.compile('[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}');

        Logger.Uuid uuid = new Logger.Uuid();

        System.Assert.areEqual(36, uuid.getValue().length());
        Matcher matcher = pattern.matcher(uuid.getValue());
        System.Assert.isTrue(matcher.matches(), 'Generated UUID=' + uuid.getValue());
    }

    @IsTest
    static void it_should_return_uuid_transaction_id() {
        Pattern pattern = System.Pattern.compile('[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}');

        String transactionId = Logger.getTransactionId();

        System.Assert.isTrue(String.isNotBlank(transactionId));
        System.Assert.areEqual(36, transactionId.length());
        Matcher matcher = pattern.matcher(transactionId);
        System.Assert.isTrue(matcher.matches(), 'Generated UUID=' + transactionId);
    }

    @IsTest
    static void it_should_set_transaction_details() {
        for (Integer i = 0; i < 3; i++) {
            LogEntryEventBuilder builder = Logger.info('my log entry for index ' + i);

            System.Assert.isNotNull(builder.getLogEntryEvent().LoggerVersionNumber__c);
            System.Assert.areEqual(Logger.getVersionNumber(), builder.getLogEntryEvent().LoggerVersionNumber__c);
            System.Assert.areEqual(Logger.getScenario(), builder.getLogEntryEvent().EntryScenario__c);
            System.Assert.areEqual(Logger.getOrganizationApiVersion(), builder.getLogEntryEvent().OrganizationApiVersion__c);
            System.Assert.areEqual(System.URL.getOrgDomainUrl()?.toExternalForm(), builder.getLogEntryEvent().OrganizationDomainUrl__c);
            System.Assert.areEqual(Logger.getParentLogTransactionId(), builder.getLogEntryEvent().ParentLogTransactionId__c);
            System.Assert.areEqual(System.Request.getCurrent().getRequestId(), builder.getLogEntryEvent().RequestId__c);
            System.Assert.areEqual(i + 1, builder.getLogEntryEvent().TransactionEntryNumber__c);
            System.Assert.areEqual(Logger.getTransactionId(), builder.getLogEntryEvent().TransactionId__c);
            System.Assert.areEqual(Logger.getScenario(), builder.getLogEntryEvent().TransactionScenario__c);
            System.Assert.areEqual(Logger.getUserSettings().LoggingLevel__c, builder.getLogEntryEvent().UserLoggingLevel__c);
            System.Assert.areEqual(Logger.getUserLoggingLevel().ordinal(), builder.getLogEntryEvent().UserLoggingLevelOrdinal__c);
        }
    }

    @IsTest
    static void it_should_set_scenario_when_default_scenario_configured() {
        String mockScenario = 'some test scenario for this transaction';
        LoggerSettings__c userSettings = LoggerSettings__c.getInstance();
        userSettings.DefaultScenario__c = mockScenario;
        upsert userSettings;

        String currentScenario = Logger.getScenario();

        System.Assert.areEqual(
            mockScenario,
            currentScenario,
            'The value of LoggerSettings__c.DefaultScenario__c should have been used as the current transaction scenario'
        );
    }

    @IsTest
    static void it_should_set_scenario_when_specified() {
        String mockScenario = 'some test scenario for this transaction';

        Logger.setScenario(mockScenario);

        System.Assert.areEqual(mockScenario, Logger.getScenario(), 'The mock scenario should have been used as the current transaction scenario');
    }

    @IsTest
    static void it_should_use_the_first_specified_scenario_as_transaction_scenario_when_parameter_is_true() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'UseFirstSpecifiedScenario', Value__c = String.valueOf(true)));
        System.Assert.isTrue(LoggerParameter.USE_FIRST_SCENARIO_FOR_TRANSACTION);
        String firstMockScenario = 'the first test scenario specified for this transaction';
        String secondMockScenario = 'the second test scenario specified for this transaction';

        Logger.setScenario(firstMockScenario);
        Logger.info('hello');
        Logger.setScenario(secondMockScenario);
        Logger.info('world');
        Logger.saveLog();

        System.Assert.areEqual(2, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        for (LogEntryEvent__e logEntryEvent : (List<LogEntryEvent__e>) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents()) {
            System.Assert.areEqual(firstMockScenario, logEntryEvent.TransactionScenario__c);
        }
    }

    @IsTest
    static void it_should_use_the_last_specified_scenario_as_transaction_scenario_when_parameter_is_false() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'UseFirstSpecifiedScenario', Value__c = String.valueOf(false)));
        System.Assert.isFalse(LoggerParameter.USE_FIRST_SCENARIO_FOR_TRANSACTION);
        String firstMockScenario = 'the first test scenario specified for this transaction';
        String secondMockScenario = 'the second test scenario specified for this transaction';

        Logger.setScenario(firstMockScenario);
        Logger.info('hello');
        Logger.setScenario(secondMockScenario);
        Logger.info('world');
        Logger.saveLog();

        System.Assert.areEqual(2, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        for (LogEntryEvent__e logEntryEvent : (List<LogEntryEvent__e>) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents()) {
            System.Assert.areEqual(secondMockScenario, logEntryEvent.TransactionScenario__c, 'The last specified scenario should have been used');
        }
    }

    @IsTest
    static void it_should_set_transaction_scenario_and_entry_scenario_for_published_log_entry_events() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String firstMockScenario = 'the first test scenario specified for this transaction';
        String secondMockScenario = 'the second test scenario specified for this transaction';

        Logger.setScenario(firstMockScenario);
        Logger.info('hello');
        Logger.setScenario(secondMockScenario);
        Logger.info('world');
        Logger.saveLog();

        System.Assert.areEqual(2, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        List<LogEntryEvent__e> publishedLogEntryEvents = (List<LogEntryEvent__e>) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents();
        LogEntryEvent__e firstLogEntryEvent = publishedLogEntryEvents.get(0);
        System.Assert.areEqual(firstMockScenario, firstLogEntryEvent.EntryScenario__c);
        System.Assert.areEqual(firstMockScenario, firstLogEntryEvent.TransactionScenario__c);
        LogEntryEvent__e secondLogEntryEvent = publishedLogEntryEvents.get(1);
        System.Assert.areEqual(secondMockScenario, secondLogEntryEvent.EntryScenario__c);
        System.Assert.areEqual(firstMockScenario, secondLogEntryEvent.TransactionScenario__c);
    }

    @IsTest
    static void it_should_end_scenario_when_no_scenario_was_previously_set() {
        System.Assert.isNull(Logger.getScenario());

        Logger.endScenario('some scenario that was never set');

        System.Assert.isNull(Logger.getScenario());
    }

    @IsTest
    static void it_should_end_scenario_when_specified_scenario_matches() {
        System.Assert.isNull(Logger.getScenario());
        String mockScenario = 'some test scenario for this transaction';
        Logger.setScenario(mockScenario);
        System.Assert.areEqual(mockScenario, Logger.getScenario(), 'The mock scenario should have been set as the current scenario');

        Logger.endScenario(mockScenario);

        System.Assert.isNull(Logger.getScenario(), 'The mock scenario should have been cleared');
    }

    @IsTest
    static void it_should_revert_to_previous_scenario_when_current_scenario_is_ended() {
        System.Assert.isNull(Logger.getScenario());
        String firstMockScenario = 'some test scenario ';
        Logger.setScenario(firstMockScenario);
        System.Assert.areEqual(firstMockScenario, Logger.getScenario());
        String secondMockScenario = 'another test scenario ';
        Logger.setScenario(secondMockScenario);
        System.Assert.areEqual(secondMockScenario, Logger.getScenario());

        Logger.endScenario(secondMockScenario);

        System.Assert.areEqual(firstMockScenario, Logger.getScenario(), 'The scenario should have reverted to the first scenario');
    }

    @IsTest
    static void it_should_revert_to_previous_scenario_rule_when_current_scenario_is_ended() {
        System.LoggingLevel originalLoggingLevel = Logger.getUserLoggingLevel();
        System.Assert.isNull(Logger.getScenario());
        String firstMockScenario = 'some test scenario ';
        LoggerScenarioRule__mdt firstMockScenarioRule = new LoggerScenarioRule__mdt(
            IsEnabled__c = true,
            Scenario__c = firstMockScenario,
            UserLoggingLevel__c = System.LoggingLevel.ERROR.name()
        );
        LoggerScenarioRule.setMock(firstMockScenarioRule);
        System.Assert.areNotEqual(originalLoggingLevel.name(), firstMockScenarioRule.UserLoggingLevel__c);
        Logger.setScenario(firstMockScenario);
        System.Assert.areEqual(firstMockScenario, Logger.getScenario());
        String secondMockScenario = 'another test scenario ';
        LoggerScenarioRule__mdt secondMockScenarioRule = new LoggerScenarioRule__mdt(
            IsEnabled__c = true,
            Scenario__c = secondMockScenario,
            UserLoggingLevel__c = System.LoggingLevel.WARN.name()
        );
        LoggerScenarioRule.setMock(secondMockScenarioRule);
        System.Assert.areNotEqual(firstMockScenarioRule.UserLoggingLevel__c, secondMockScenarioRule.UserLoggingLevel__c);
        Logger.setScenario(secondMockScenario);
        System.Assert.areEqual(secondMockScenario, Logger.getScenario());
        System.Assert.areEqual(secondMockScenarioRule.UserLoggingLevel__c, Logger.getUserLoggingLevel().name());

        Logger.endScenario(secondMockScenario);

        System.Assert.areEqual(firstMockScenario, Logger.getScenario(), 'The scenario should have reverted to the first scenario');
        System.Assert.areEqual(firstMockScenarioRule, LoggerScenarioRule.getInstance(firstMockScenario));
        System.Assert.isNotNull(LoggerScenarioRule.getInstance(secondMockScenario));
        System.Assert.areEqual(firstMockScenarioRule.UserLoggingLevel__c, Logger.getUserLoggingLevel().name());
    }

    @IsTest
    static void it_should_not_ignore_origin_when_apex_class_type_not_specified() {
        // Don't bother testing stack trace logic when using a namespace prefix - there are
        // some platform limitations that prevent these tests from behaving as expected
        if (String.isNotBlank(Logger.getNamespacePrefix())) {
            return;
        }

        System.Type nonIgnoredApexClassType = MockClassWithLogging.class;
        String qualifiedNonIgnoredClassName = nonIgnoredApexClassType.getName();
        String expectedOriginLocation = qualifiedNonIgnoredClassName + '.logSomething';

        LogEntryEventBuilder builder = new MockClassWithLogging().logSomething();

        System.Assert.areEqual(expectedOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
    }

    @IsTest
    static void it_should_ignore_origin_when_apex_class_type_specified() {
        // Don't bother testing stack trace logic when using a namespace prefix - there are
        // some platform limitations that prevent these tests from behaving as expected
        if (String.isNotBlank(Logger.getNamespacePrefix())) {
            return;
        }

        System.Type ignoredApexClassType = MockClassWithLogging.class;
        String qualifiedTopLevelClassName = Logger_Tests.class.getName();
        String expectedOriginLocation = qualifiedTopLevelClassName + '.it_should_ignore_origin_when_apex_class_type_specified';

        Logger.ignoreOrigin(ignoredApexClassType);
        LogEntryEventBuilder builder = new MockClassWithLogging().logSomething();

        System.Assert.areEqual(expectedOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
    }

    @IsTest
    static void it_should_override_logger_is_enabled_setting_when_matching_logger_scenario_rule_is_configured() {
        LoggerScenarioRule__mdt scenarioRule = new LoggerScenarioRule__mdt(
            IsEnabled__c = true,
            IsLoggerEnabled__c = String.valueOf(!Logger.getUserSettings().IsEnabled__c),
            Scenario__c = 'Some scenario'
        );
        LoggerScenarioRule.setMock(scenarioRule);
        System.Assert.isNotNull(LoggerScenarioRule.getInstance(scenarioRule.Scenario__c));
        System.Assert.areNotEqual(Boolean.valueOf(scenarioRule.IsLoggerEnabled__c), Logger.getUserSettings().IsEnabled__c);
        System.Assert.areNotEqual(Boolean.valueOf(scenarioRule.IsLoggerEnabled__c), Logger.isEnabled());

        Logger.setScenario(scenarioRule.Scenario__c);

        System.Assert.areEqual(Boolean.valueOf(scenarioRule.IsLoggerEnabled__c), Logger.getUserSettings().IsEnabled__c);
        System.Assert.areEqual(Boolean.valueOf(scenarioRule.IsLoggerEnabled__c), Logger.isEnabled());
    }

    @IsTest
    static void it_should_override_anonymous_mode_setting_when_matching_logger_scenario_rule_is_configured() {
        LoggerScenarioRule__mdt scenarioRule = new LoggerScenarioRule__mdt(
            IsAnonymousModeEnabled__c = String.valueOf(!Logger.getUserSettings().IsAnonymousModeEnabled__c),
            IsEnabled__c = true,
            Scenario__c = 'Some scenario'
        );
        LoggerScenarioRule.setMock(scenarioRule);
        System.Assert.isNotNull(LoggerScenarioRule.getInstance(scenarioRule.Scenario__c));
        System.Assert.areNotEqual(Boolean.valueOf(scenarioRule.IsAnonymousModeEnabled__c), Logger.getUserSettings().IsAnonymousModeEnabled__c);

        Logger.setScenario(scenarioRule.Scenario__c);

        System.Assert.areEqual(Boolean.valueOf(scenarioRule.IsAnonymousModeEnabled__c), Logger.getUserSettings().IsAnonymousModeEnabled__c);
    }

    @IsTest
    static void it_should_override_apex_system_debugging_setting_when_matching_logger_scenario_rule_is_configured() {
        LoggerScenarioRule__mdt scenarioRule = new LoggerScenarioRule__mdt(
            IsApexSystemDebugLoggingEnabled__c = String.valueOf(!Logger.getUserSettings().IsApexSystemDebugLoggingEnabled__c),
            IsEnabled__c = true,
            Scenario__c = 'Some scenario'
        );
        LoggerScenarioRule.setMock(scenarioRule);
        System.Assert.isNotNull(LoggerScenarioRule.getInstance(scenarioRule.Scenario__c));
        System.Assert.areNotEqual(
            Boolean.valueOf(scenarioRule.IsApexSystemDebugLoggingEnabled__c),
            Logger.getUserSettings().IsApexSystemDebugLoggingEnabled__c
        );

        Logger.setScenario(scenarioRule.Scenario__c);

        System.Assert.areEqual(Boolean.valueOf(scenarioRule.IsApexSystemDebugLoggingEnabled__c), Logger.getUserSettings().IsApexSystemDebugLoggingEnabled__c);
    }

    @IsTest
    static void it_should_override_data_masking_setting_when_matching_logger_scenario_rule_is_configured() {
        LoggerScenarioRule__mdt scenarioRule = new LoggerScenarioRule__mdt(
            IsDataMaskingEnabled__c = String.valueOf(!Logger.getUserSettings().IsDataMaskingEnabled__c),
            IsEnabled__c = true,
            Scenario__c = 'Some scenario'
        );
        LoggerScenarioRule.setMock(scenarioRule);
        System.Assert.isNotNull(LoggerScenarioRule.getInstance(scenarioRule.Scenario__c));
        System.Assert.areNotEqual(Boolean.valueOf(scenarioRule.IsDataMaskingEnabled__c), Logger.getUserSettings().IsDataMaskingEnabled__c);

        Logger.setScenario(scenarioRule.Scenario__c);

        System.Assert.areEqual(Boolean.valueOf(scenarioRule.IsDataMaskingEnabled__c), Logger.getUserSettings().IsDataMaskingEnabled__c);
    }

    @IsTest
    static void it_should_override_javascript_console_logging_setting_when_matching_logger_scenario_rule_is_configured() {
        LoggerScenarioRule__mdt scenarioRule = new LoggerScenarioRule__mdt(
            IsEnabled__c = true,
            IsJavaScriptConsoleLoggingEnabled__c = String.valueOf(!Logger.getUserSettings().IsJavaScriptConsoleLoggingEnabled__c),
            Scenario__c = 'Some scenario'
        );
        LoggerScenarioRule.setMock(scenarioRule);
        System.Assert.isNotNull(LoggerScenarioRule.getInstance(scenarioRule.Scenario__c));
        System.Assert.areNotEqual(
            Boolean.valueOf(scenarioRule.IsJavaScriptConsoleLoggingEnabled__c),
            Logger.getUserSettings().IsJavaScriptConsoleLoggingEnabled__c
        );

        Logger.setScenario(scenarioRule.Scenario__c);

        System.Assert.areEqual(
            Boolean.valueOf(scenarioRule.IsJavaScriptConsoleLoggingEnabled__c),
            Logger.getUserSettings().IsJavaScriptConsoleLoggingEnabled__c
        );
    }

    @IsTest
    static void it_should_override_record_field_stripping_setting_when_matching_logger_scenario_rule_is_configured() {
        LoggerScenarioRule__mdt scenarioRule = new LoggerScenarioRule__mdt(
            IsEnabled__c = true,
            IsRecordFieldStrippingEnabled__c = String.valueOf(!Logger.getUserSettings().IsRecordFieldStrippingEnabled__c),
            Scenario__c = 'Some scenario'
        );
        LoggerScenarioRule.setMock(scenarioRule);
        System.Assert.isNotNull(LoggerScenarioRule.getInstance(scenarioRule.Scenario__c));
        System.Assert.areNotEqual(Boolean.valueOf(scenarioRule.IsRecordFieldStrippingEnabled__c), Logger.getUserSettings().IsRecordFieldStrippingEnabled__c);

        Logger.setScenario(scenarioRule.Scenario__c);

        System.Assert.areEqual(Boolean.valueOf(scenarioRule.IsRecordFieldStrippingEnabled__c), Logger.getUserSettings().IsRecordFieldStrippingEnabled__c);
    }

    @IsTest
    static void it_should_override_saving_enabled_setting_when_matching_logger_scenario_rule_is_configured() {
        LoggerScenarioRule__mdt scenarioRule = new LoggerScenarioRule__mdt(
            IsEnabled__c = true,
            IsSavingEnabled__c = String.valueOf(!Logger.getUserSettings().IsSavingEnabled__c),
            Scenario__c = 'Some scenario'
        );
        LoggerScenarioRule.setMock(scenarioRule);
        System.Assert.isNotNull(LoggerScenarioRule.getInstance(scenarioRule.Scenario__c));
        System.Assert.areNotEqual(Boolean.valueOf(scenarioRule.IsSavingEnabled__c), Logger.getUserSettings().IsSavingEnabled__c);

        Logger.setScenario(scenarioRule.Scenario__c);

        System.Assert.areEqual(Boolean.valueOf(scenarioRule.IsSavingEnabled__c), Logger.getUserSettings().IsSavingEnabled__c);
    }

    @IsTest
    static void it_should_override_save_method_setting_when_matching_logger_scenario_rule_is_configured() {
        LoggerScenarioRule__mdt scenarioRule = new LoggerScenarioRule__mdt(
            IsEnabled__c = true,
            SaveMethod__c = Logger.SaveMethod.QUEUEABLE.name(),
            Scenario__c = 'Some scenario'
        );
        LoggerScenarioRule.setMock(scenarioRule);
        System.Assert.isNotNull(LoggerScenarioRule.getInstance(scenarioRule.Scenario__c));
        System.Assert.areNotEqual(scenarioRule.SaveMethod__c, Logger.getSaveMethod().name());

        Logger.setScenario(scenarioRule.Scenario__c);

        System.Assert.areEqual(scenarioRule.SaveMethod__c, Logger.getSaveMethod().name());
    }

    @IsTest
    static void it_should_override_user_logging_level_when_matching_logger_scenario_rule_is_configured() {
        LoggerScenarioRule__mdt scenarioRule = new LoggerScenarioRule__mdt(
            IsEnabled__c = true,
            Scenario__c = 'Some scenario',
            UserLoggingLevel__c = System.LoggingLevel.FINER.name()
        );
        LoggerScenarioRule.setMock(scenarioRule);
        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        System.Assert.areNotEqual(scenarioRule.UserLoggingLevel__c, Logger.getUserSettings().LoggingLevel__c);

        Logger.setScenario(scenarioRule.Scenario__c);

        System.Assert.areEqual(scenarioRule.UserLoggingLevel__c, Logger.getUserSettings().LoggingLevel__c);
    }

    @IsTest
    static void it_should_set_async_context_details_for_batchable_context_when_event_published() {
        Id mockParentAsyncApexJobId = LoggerMockDataCreator.createId(Schema.AsyncApexJob.SObjectType);
        Id mockChildAsyncApexJobId = LoggerMockDataCreator.createId(Schema.AsyncApexJob.SObjectType);
        Database.BatchableContext mockContext = new LoggerMockDataCreator.MockBatchableContext(mockParentAsyncApexJobId, mockChildAsyncApexJobId);
        System.Assert.areEqual(mockChildAsyncApexJobId, mockContext.getChildJobId());
        System.Assert.areEqual(mockParentAsyncApexJobId, mockContext.getJobId());
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LogEntryEvent__e logEntryEvent = Logger.info('hello, world').getLogEntryEvent();
        System.Assert.isNull(logEntryEvent.AsyncContextChildJobId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextParentJobId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextTriggerId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextType__c);
        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        Logger.setAsyncContext(mockContext);
        Logger.saveLog(Logger.SaveMethod.EVENT_BUS);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        System.Assert.areEqual(logEntryEvent, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0));
        System.Assert.areEqual(mockContext.getChildJobId(), logEntryEvent.AsyncContextChildJobId__c);
        System.Assert.areEqual(mockContext.getJobId(), logEntryEvent.AsyncContextParentJobId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextTriggerId__c);
        System.Assert.areEqual(Database.BatchableContext.class.getName(), logEntryEvent.AsyncContextType__c);
    }

    @IsTest
    static void it_should_set_async_context_details_for_finalizer_context_when_event_published() {
        Id mockParentAsyncApexJobId = LoggerMockDataCreator.createId(Schema.AsyncApexJob.SObjectType);
        System.FinalizerContext mockContext = new LoggerMockDataCreator.MockFinalizerContext(mockParentAsyncApexJobId);
        System.Assert.areEqual(mockParentAsyncApexJobId, mockContext.getAsyncApexJobId());
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LogEntryEvent__e logEntryEvent = Logger.info('hello, world').getLogEntryEvent();
        System.Assert.isNull(logEntryEvent.AsyncContextChildJobId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextParentJobId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextTriggerId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextType__c);
        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        Logger.setAsyncContext(mockContext);
        Logger.saveLog(Logger.SaveMethod.EVENT_BUS);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        System.Assert.areEqual(logEntryEvent, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0));
        System.Assert.isNull(logEntryEvent.AsyncContextChildJobId__c);
        System.Assert.areEqual(mockContext.getAsyncApexJobId(), logEntryEvent.AsyncContextParentJobId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextTriggerId__c);
        System.Assert.areEqual(System.FinalizerContext.class.getName(), logEntryEvent.AsyncContextType__c);
    }

    @IsTest
    static void it_should_set_async_context_details_for_queueable_context_when_event_published() {
        Id mockParentAsyncApexJobId = LoggerMockDataCreator.createId(Schema.AsyncApexJob.SObjectType);
        System.QueueableContext mockContext = new LoggerMockDataCreator.MockQueueableContext(mockParentAsyncApexJobId);
        System.Assert.areEqual(mockParentAsyncApexJobId, mockContext.getJobId());
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LogEntryEvent__e logEntryEvent = Logger.info('hello, world').getLogEntryEvent();
        System.Assert.isNull(logEntryEvent.AsyncContextChildJobId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextParentJobId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextTriggerId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextType__c);
        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        Logger.setAsyncContext(mockContext);
        Logger.saveLog(Logger.SaveMethod.EVENT_BUS);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        System.Assert.areEqual(logEntryEvent, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0));
        System.Assert.isNull(logEntryEvent.AsyncContextChildJobId__c);
        System.Assert.areEqual(mockContext.getJobId(), logEntryEvent.AsyncContextParentJobId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextTriggerId__c);
        System.Assert.areEqual(System.QueueableContext.class.getName(), logEntryEvent.AsyncContextType__c);
    }

    @IsTest
    static void it_should_set_async_context_details_for_schedulable_context_when_event_published() {
        Id mockCronTriggerId = LoggerMockDataCreator.createId(Schema.CronTrigger.SObjectType);
        System.SchedulableContext mockContext = new LoggerMockDataCreator.MockSchedulableContext(mockCronTriggerId);
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LogEntryEvent__e logEntryEvent = Logger.info('hello, world').getLogEntryEvent();
        System.Assert.isNull(logEntryEvent.AsyncContextChildJobId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextParentJobId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextTriggerId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextType__c);
        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        Logger.setAsyncContext(mockContext);
        Logger.saveLog(Logger.SaveMethod.EVENT_BUS);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        System.Assert.areEqual(logEntryEvent, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0));
        System.Assert.isNull(logEntryEvent.AsyncContextChildJobId__c);
        System.Assert.isNull(logEntryEvent.AsyncContextParentJobId__c);
        System.Assert.areEqual(mockContext.getTriggerId(), logEntryEvent.AsyncContextTriggerId__c);
        System.Assert.areEqual(System.SchedulableContext.class.getName(), logEntryEvent.AsyncContextType__c);
    }

    @IsTest
    static void it_should_set_parent_transaction_id() {
        String expectedParentTransactionId = 'imagineThisWereAGuid';

        Logger.setParentLogTransactionId(expectedParentTransactionId);

        System.Assert.areEqual(expectedParentTransactionId, Logger.getParentLogTransactionId());
    }

    @IsTest
    static void it_should_ignore_parent_transaction_id_when_set_to_current_transaction_id() {
        String currentTransactionId = Logger.getTransactionId();

        Logger.setParentLogTransactionId(currentTransactionId);

        System.Assert.isNull(Logger.getParentLogTransactionId());
    }

    @IsTest
    static void it_should_return_quiddity_level() {
        List<Quiddity> acceptableDefaultQuidditiesForTests = new List<Quiddity>{ Quiddity.RUNTEST_ASYNC, Quiddity.RUNTEST_DEPLOY, Quiddity.RUNTEST_SYNC };

        Quiddity currentQuiddity = Logger.getCurrentQuiddity();

        System.Assert.isTrue(acceptableDefaultQuidditiesForTests.contains(currentQuiddity));
        System.Assert.areEqual(System.Request.getCurrent().getQuiddity(), currentQuiddity);
    }

    @IsTest
    static void it_should_return_user_logging_level() {
        System.LoggingLevel expectedLoggingLevel = System.LoggingLevel.FINE;
        Logger.getUserSettings().LoggingLevel__c = expectedLoggingLevel.name();

        System.LoggingLevel returnedLoggingLevel = Logger.getUserLoggingLevel();

        System.Assert.areEqual(expectedLoggingLevel, returnedLoggingLevel);
    }

    @IsTest
    static void it_should_return_true_when_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;

        Boolean returnedValue = Logger.isEnabled();

        System.Assert.areEqual(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_provided_logging_level_is_enabled() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = loggingLevel.name();

        Boolean returnedValue = Logger.isEnabled(loggingLevel);

        System.Assert.areEqual(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_error_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();

        Boolean returnedValue = Logger.isErrorEnabled();

        System.Assert.areEqual(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_warn_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.WARN.name();

        Boolean returnedValue = Logger.isWarnEnabled();

        System.Assert.areEqual(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_info_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.INFO.name();

        Boolean returnedValue = Logger.isInfoEnabled();

        System.Assert.areEqual(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_debug_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.DEBUG.name();

        Boolean returnedValue = Logger.isDebugEnabled();

        System.Assert.areEqual(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_fine_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.FINE.name();

        Boolean returnedValue = Logger.isFineEnabled();

        System.Assert.areEqual(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_finer_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.FINER.name();

        Boolean returnedValue = Logger.isFinerEnabled();

        System.Assert.areEqual(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_finest_logging_level_is_enabled() {
        Boolean expectedValue = true;
        Logger.getUserSettings().IsEnabled__c = expectedValue;
        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.FINEST.name();

        Boolean returnedValue = Logger.isFinestEnabled();

        System.Assert.areEqual(expectedValue, returnedValue);
    }

    @IsTest
    static void it_should_return_true_when_saving_is_suspended() {
        System.Assert.isFalse(Logger.isSavingSuspended());

        Logger.suspendSaving();

        System.Assert.isTrue(Logger.isSavingSuspended());
    }

    @IsTest
    static void it_should_suspend_saving() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        System.Assert.isTrue(Logger.isDebugEnabled());
        Logger.debug('test log entry');
        System.Assert.areEqual(1, Logger.getBufferSize());

        Logger.suspendSaving();
        Logger.saveLog();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
    }

    @IsTest
    static void it_should_resume_saving() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        System.Assert.isTrue(Logger.isInfoEnabled());
        Integer logEntriesToCreate = 4;
        for (Integer i = 0; i < logEntriesToCreate; i++) {
            Logger.info('test log entry #' + i);
        }
        System.Assert.areEqual(logEntriesToCreate, Logger.getBufferSize());
        Logger.suspendSaving();
        System.Assert.isTrue(Logger.isSavingSuspended());
        Logger.saveLog();
        System.Assert.areEqual(logEntriesToCreate, Logger.getBufferSize());
        System.Assert.areEqual(logEntriesToCreate, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        Logger.resumeSaving();
        System.Assert.isFalse(Logger.isSavingSuspended());
        Logger.saveLog();

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(logEntriesToCreate, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
    }

    @IsTest
    static void it_should_save_accurate_timestamp_when_logging_user_has_different_time_zone() {
        // TODO Move this test to LogEntryEventBuilder_Tests
        String automatedProcessUsername = 'autoproc@' + System.UserInfo.getOrganizationId();
        User automatedProcessUser = [SELECT Id, TimeZoneSidKey FROM User WHERE Username = :automatedProcessUsername AND Profile.Name = NULL];
        User currentUser = new User(Id = System.UserInfo.getUserId());
        // Make sure that the test user has a different time zone from the automated process user
        if (automatedProcessUser.TimeZoneSidKey == currentUser.TimeZoneSidKey) {
            switch on automatedProcessUser.TimeZoneSidKey {
                when 'America/Los_Angeles' {
                    currentUser.TimeZoneSidKey = 'America/New_York';
                }
                when else {
                    currentUser.TimeZoneSidKey = 'America/Los_Angeles';
                }
            }
            System.Assert.areNotEqual(automatedProcessUser.TimeZoneSidKey, currentUser.TimeZoneSidKey);
        }

        Datetime originalTimestamp;
        System.runAs(currentUser) {
            Logger.getUserSettings().IsEnabled__c = true;
            Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.INFO.name();

            LogEntryEventBuilder builder = Logger.info('test log entry');

            originalTimestamp = builder.getLogEntryEvent().TimeStamp__c;
            System.Assert.isNotNull(originalTimestamp);
            System.Assert.areEqual(1, Logger.getBufferSize());
            Logger.saveLog();
            System.Test.getEventBus().deliver();
        }

        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        LogEntry__c logEntry = [SELECT Id, Timestamp__c FROM LogEntry__c];
        System.Assert.areEqual(originalTimestamp, logEntry.Timestamp__c);
    }

    @IsTest
    static void it_should_return_the_buffer_size() {
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isTrue(Logger.isInfoEnabled());

        Logger.info('test log entry');
        Logger.warn('another test log entry');

        System.Assert.areEqual(2, Logger.getBufferSize());
    }

    @IsTest
    static void it_should_not_save_when_saving_is_disabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        Logger.getUserSettings().IsSavingEnabled__c = false;
        System.Assert.isFalse(Logger.getUserSettings().IsSavingEnabled__c);
        System.Assert.isTrue(Logger.isDebugEnabled());
        Logger.debug('test log entry');
        System.Assert.areEqual(1, Logger.getBufferSize());

        Logger.saveLog();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(0, System.Limits.getDmlStatements());
    }

    @IsTest
    static void it_should_save_via_event_bus_when_defaulted() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);

        setUserLoggingLevel(System.LoggingLevel.DEBUG);

        Logger.getUserSettings().DefaultSaveMethod__c = 'EVENT_BUS';

        System.Assert.areEqual(Logger.SaveMethod.EVENT_BUS, Logger.getSaveMethod());

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());

        System.Test.startTest();

        Logger.saveLog();
        System.Assert.areEqual(1, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(0, System.Limits.getDmlStatements());

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(2, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_via_event_bus_when_specified_via_settings() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);

        setUserLoggingLevel(System.LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());

        System.Test.startTest();

        Logger.saveLog(Logger.SaveMethod.EVENT_BUS);
        System.Assert.areEqual(1, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(0, System.Limits.getDmlStatements());

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(2, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_via_event_bus_when_specified_via_setSaveMethod() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);

        setUserLoggingLevel(System.LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());

        System.Test.startTest();

        Logger.SaveMethod expectedSaveMethod = Logger.SaveMethod.EVENT_BUS;
        Logger.setSaveMethod(expectedSaveMethod);
        System.Assert.areEqual(expectedSaveMethod, Logger.getSaveMethod());
        Logger.saveLog();
        System.Assert.areEqual(1, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(0, System.Limits.getDmlStatements());

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(2, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_via_queueable_when_defaulted() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.DEBUG.name();
        Logger.getUserSettings().DefaultSaveMethod__c = 'QUEUEABLE';
        upsert Logger.getUserSettings();

        System.Test.startTest();

        System.Assert.areEqual(Logger.SaveMethod.QUEUEABLE, Logger.getSaveMethod());

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.Assert.areEqual(2, Logger.getBufferSize());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());

        Logger.saveLog();

        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(1, System.Limits.getQueueableJobs());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(0, System.Limits.getDmlStatements());

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(2, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_via_queueable_when_specified_via_settings() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);

        setUserLoggingLevel(System.LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.Assert.areEqual(0, System.Limits.getQueueableJobs());

        System.Test.startTest();

        Logger.saveLog(Logger.SaveMethod.QUEUEABLE);
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(1, System.Limits.getQueueableJobs());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(0, System.Limits.getDmlStatements());

        System.Test.getEventBus().deliver();

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(2, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_via_queueable_when_specified_via_setSaveMethod() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);

        setUserLoggingLevel(System.LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.Assert.areEqual(0, System.Limits.getQueueableJobs());

        System.Test.startTest();

        Logger.SaveMethod expectedSaveMethod = Logger.SaveMethod.QUEUEABLE;
        Logger.setSaveMethod(expectedSaveMethod);
        System.Assert.areEqual(expectedSaveMethod, Logger.getSaveMethod());
        Logger.saveLog();
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(1, System.Limits.getQueueableJobs());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(0, System.Limits.getDmlStatements());

        System.Test.getEventBus().deliver();

        System.Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(2, countOfLogEntries);
    }

    @IsTest
    static void it_should_save_via_rest_api_when_defaulted() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        System.Test.setMock(System.HttpCalloutMock.class, LoggerMockDataCreator.createHttpCallout().setStatusCode(200));

        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);

        setUserLoggingLevel(System.LoggingLevel.DEBUG);

        Logger.getUserSettings().DefaultSaveMethod__c = 'REST';

        System.Assert.areEqual(Logger.SaveMethod.REST, Logger.getSaveMethod());

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.Assert.areEqual(0, System.Limits.getCallouts());

        System.Test.startTest();

        Logger.saveLog();
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(1, System.Limits.getCallouts());
        System.Assert.areEqual(0, System.Limits.getDmlStatements());

        System.Test.stopTest();
    }

    @IsTest
    static void it_should_save_via_rest_api_when_specified_via_settings() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        System.Test.setMock(System.HttpCalloutMock.class, LoggerMockDataCreator.createHttpCallout().setStatusCode(200));

        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);

        setUserLoggingLevel(System.LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.Assert.areEqual(0, System.Limits.getCallouts());

        System.Test.startTest();

        Logger.saveLog(Logger.SaveMethod.REST);
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(1, System.Limits.getCallouts());
        System.Assert.areEqual(0, System.Limits.getDmlStatements());

        System.Test.stopTest();
    }

    @IsTest
    static void it_should_save_via_rest_api_when_specified_via_setSaveMethod() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        System.Test.setMock(System.HttpCalloutMock.class, LoggerMockDataCreator.createHttpCallout().setStatusCode(200));

        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);

        setUserLoggingLevel(System.LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.Assert.areEqual(0, System.Limits.getCallouts());

        System.Test.startTest();

        Logger.SaveMethod expectedSaveMethod = Logger.SaveMethod.REST;
        Logger.setSaveMethod(expectedSaveMethod);
        System.Assert.areEqual(expectedSaveMethod, Logger.getSaveMethod());
        Logger.saveLog();
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(1, System.Limits.getCallouts());
        System.Assert.areEqual(0, System.Limits.getDmlStatements());

        System.Test.stopTest();
    }

    @IsTest
    static void it_should_throw_exception_when_save_via_rest_api_fails() {
        // TODO eliminate references to Log__c, find alternative way to assert on expected data
        System.Test.setMock(System.HttpCalloutMock.class, LoggerMockDataCreator.createHttpCallout().setStatusCode(400));

        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.Assert.areEqual(0, countOfLogEntries);

        setUserLoggingLevel(System.LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.Assert.areEqual(0, System.Limits.getCallouts());

        System.Test.startTest();

        try {
            Logger.saveLog(Logger.SaveMethod.REST);
        } catch (System.Exception apexException) {
            System.Assert.isInstanceOfType(apexException, System.CalloutException.class);
        }
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(1, System.Limits.getCallouts());
        System.Assert.areEqual(0, System.Limits.getDmlStatements());

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
        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.DEBUG.name();
        System.Assert.areEqual(System.LoggingLevel.DEBUG, Logger.getUserLoggingLevel());
        System.Assert.areEqual(Logger.SaveMethod.SYNCHRONOUS_DML, Logger.getSaveMethod());
        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        logEntryEvents.add(Logger.debug('test log entry').getLogEntryEvent());
        logEntryEvents.add(Logger.debug('another test log entry').getLogEntryEvent());
        System.Test.startTest();
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(logEntryEvents.size(), Logger.getBufferSize());

        Logger.saveLog();

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        MockSObjectHandler mockLogEntryEventBeforeInsertHandler = (MockSObjectHandler) LoggerSObjectHandler.getExecutedHandlers()
            .get(Schema.LogEntryEvent__e.SObjectType)
            .get(0);
        // System.Assert.areEqual(1, mockLogEntryEventBeforeInsertHandler.executionCount);
        System.Assert.areEqual(TriggerOperation.BEFORE_INSERT, mockLogEntryEventBeforeInsertHandler.executedTriggerOperationType);
        System.Assert.areEqual(logEntryEvents.size(), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.size());
        System.Assert.areEqual(logEntryEvents.get(0), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.get(0));
        System.Assert.areEqual(logEntryEvents.get(1), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.get(1));
        MockSObjectHandler mockLogEntryEventAfterInsertHandler = (MockSObjectHandler) LoggerSObjectHandler.getExecutedHandlers()
            .get(Schema.LogEntryEvent__e.SObjectType)
            .get(1);
        // System.Assert.areEqual(1, mockLogEntryEventAfterInsertHandler.executionCount);
        System.Assert.areEqual(TriggerOperation.AFTER_INSERT, mockLogEntryEventAfterInsertHandler.executedTriggerOperationType);
        System.Assert.areEqual(logEntryEvents.size(), mockLogEntryEventAfterInsertHandler.executedTriggerNew.size());
        System.Assert.areEqual(logEntryEvents.get(0), mockLogEntryEventAfterInsertHandler.executedTriggerNew.get(0));
        System.Assert.areEqual(logEntryEvents.get(1), mockLogEntryEventAfterInsertHandler.executedTriggerNew.get(1));
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
        System.Assert.isTrue(Logger.isInfoEnabled());
        logEntryEvents.add(Logger.info('test log entry').getLogEntryEvent());
        logEntryEvents.add(Logger.info('another test log entry').getLogEntryEvent());
        System.Test.startTest();
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(logEntryEvents.size(), Logger.getBufferSize());

        Logger.getUserSettings().DefaultSaveMethod__c = Logger.SaveMethod.SYNCHRONOUS_DML.name();
        System.Assert.areEqual(Logger.SaveMethod.SYNCHRONOUS_DML, Logger.getSaveMethod());
        Logger.saveLog();

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        MockSObjectHandler mockLogEntryEventBeforeInsertHandler = (MockSObjectHandler) LoggerSObjectHandler.getExecutedHandlers()
            .get(Schema.LogEntryEvent__e.SObjectType)
            .get(0);
        // System.Assert.areEqual(1, mockLogEntryEventBeforeInsertHandler.executionCount);
        System.Assert.areEqual(TriggerOperation.BEFORE_INSERT, mockLogEntryEventBeforeInsertHandler.executedTriggerOperationType);
        System.Assert.areEqual(logEntryEvents.size(), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.size());
        System.Assert.areEqual(logEntryEvents.get(0), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.get(0));
        System.Assert.areEqual(logEntryEvents.get(1), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.get(1));
        MockSObjectHandler mockLogEntryEventAfterInsertHandler = (MockSObjectHandler) LoggerSObjectHandler.getExecutedHandlers()
            .get(Schema.LogEntryEvent__e.SObjectType)
            .get(1);
        // System.Assert.areEqual(1, mockLogEntryEventAfterInsertHandler.executionCount);
        System.Assert.areEqual(TriggerOperation.AFTER_INSERT, mockLogEntryEventAfterInsertHandler.executedTriggerOperationType);
        System.Assert.areEqual(logEntryEvents.size(), mockLogEntryEventAfterInsertHandler.executedTriggerNew.size());
        System.Assert.areEqual(logEntryEvents.get(0), mockLogEntryEventAfterInsertHandler.executedTriggerNew.get(0));
        System.Assert.areEqual(logEntryEvents.get(1), mockLogEntryEventAfterInsertHandler.executedTriggerNew.get(1));
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
        logEntryEvents.add(Logger.info('test log entry').getLogEntryEvent());
        logEntryEvents.add(Logger.info('another test log entry').getLogEntryEvent());
        System.Test.startTest();
        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(logEntryEvents.size(), Logger.getBufferSize());

        Logger.SaveMethod expectedSaveMethod = Logger.SaveMethod.SYNCHRONOUS_DML;
        Logger.setSaveMethod(expectedSaveMethod);
        System.Assert.areEqual(expectedSaveMethod, Logger.getSaveMethod());
        Logger.saveLog();

        System.Assert.areEqual(0, System.Limits.getPublishImmediateDml());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs());
        System.Assert.areEqual(0, System.Limits.getCallouts());
        System.Assert.areEqual(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
        MockSObjectHandler mockLogEntryEventBeforeInsertHandler = (MockSObjectHandler) LoggerSObjectHandler.getExecutedHandlers()
            .get(Schema.LogEntryEvent__e.SObjectType)
            .get(0);
        // System.Assert.areEqual(1, mockLogEntryEventBeforeInsertHandler.executionCount);
        System.Assert.areEqual(TriggerOperation.BEFORE_INSERT, mockLogEntryEventBeforeInsertHandler.executedTriggerOperationType);
        System.Assert.areEqual(logEntryEvents.size(), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.size());
        System.Assert.areEqual(logEntryEvents.get(0), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.get(0));
        System.Assert.areEqual(logEntryEvents.get(1), mockLogEntryEventBeforeInsertHandler.executedTriggerNew.get(1));
        MockSObjectHandler mockLogEntryEventAfterInsertHandler = (MockSObjectHandler) LoggerSObjectHandler.getExecutedHandlers()
            .get(Schema.LogEntryEvent__e.SObjectType)
            .get(1);
        // System.Assert.areEqual(1, mockLogEntryEventAfterInsertHandler.executionCount);
        System.Assert.areEqual(TriggerOperation.AFTER_INSERT, mockLogEntryEventAfterInsertHandler.executedTriggerOperationType);
        System.Assert.areEqual(logEntryEvents.size(), mockLogEntryEventAfterInsertHandler.executedTriggerNew.size());
        System.Assert.areEqual(logEntryEvents.get(0), mockLogEntryEventAfterInsertHandler.executedTriggerNew.get(0));
        System.Assert.areEqual(logEntryEvents.get(1), mockLogEntryEventAfterInsertHandler.executedTriggerNew.get(1));
        System.Test.stopTest();
    }

    @IsTest
    static void it_should_flush_buffer() {
        Logger.info('test log entry');
        Logger.info('another test log entry');
        System.Assert.areEqual(2, Logger.getBufferSize());

        Logger.flushBuffer();

        System.Assert.areEqual(0, Logger.getBufferSize());
    }

    // Start exception methods for LogMessage
    @IsTest
    static void it_should_save_and_throw_exception_for_logMessage() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogMessage logMessage = getLogMessage();
        System.Exception apexException = new System.DmlException('oops, some DML broke');

        System.Exception thrownException;
        try {
            Logger.exception(logMessage, apexException);
        } catch (Exception ex) {
            thrownException = ex;
        }

        System.Assert.areEqual(apexException, thrownException);
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e logEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(System.LoggingLevel.ERROR.name(), logEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(logMessage.getMessage(), logEntryEvent.Message__c);
        System.Assert.areEqual(apexException.getMessage(), logEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual(apexException.getTypeName(), logEntryEvent.ExceptionType__c);
    }

    @IsTest
    static void it_should_save_and_throw_exception_for_logMessage_with_recordId() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogMessage logMessage = getLogMessage();
        Id recordId = System.UserInfo.getUserId();
        System.Exception apexException = new System.DmlException('oops, some DML broke');

        System.Exception thrownException;
        try {
            Logger.exception(logMessage, recordId, apexException);
        } catch (Exception ex) {
            thrownException = ex;
        }

        System.Assert.areEqual(apexException, thrownException);
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e logEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(System.LoggingLevel.ERROR.name(), logEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(logMessage.getMessage(), logEntryEvent.Message__c);
        System.Assert.areEqual(recordId, logEntryEvent.RecordId__c);
        System.Assert.areEqual(apexException.getMessage(), logEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual(apexException.getTypeName(), logEntryEvent.ExceptionType__c);
    }

    @IsTest
    static void it_should_save_and_throw_exception_for_logMessage_with_record() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogMessage logMessage = getLogMessage();
        User record = new User(Id = System.UserInfo.getUserId());
        System.Exception apexException = new System.DmlException('oops, some DML broke');

        System.Exception thrownException;
        try {
            Logger.exception(logMessage, record, apexException);
        } catch (Exception ex) {
            thrownException = ex;
        }

        System.Assert.areEqual(apexException, thrownException);
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e logEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(System.LoggingLevel.ERROR.name(), logEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(logMessage.getMessage(), logEntryEvent.Message__c);
        System.Assert.areEqual(record.Id, logEntryEvent.RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(record), logEntryEvent.RecordJson__c);
        System.Assert.areEqual(apexException.getMessage(), logEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual(apexException.getTypeName(), logEntryEvent.ExceptionType__c);
    }

    @IsTest
    static void it_should_save_and_throw_exception_for_logMessage_with_recordList() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogMessage logMessage = getLogMessage();
        List<User> records = new List<User>{ new User(Id = System.UserInfo.getUserId()) };
        System.Exception apexException = new System.DmlException('oops, some DML broke');

        System.Exception thrownException;
        try {
            Logger.exception(logMessage, records, apexException);
        } catch (Exception ex) {
            thrownException = ex;
        }

        System.Assert.areEqual(apexException, thrownException);
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e logEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(System.LoggingLevel.ERROR.name(), logEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(logMessage.getMessage(), logEntryEvent.Message__c);
        System.Assert.isNull(logEntryEvent.RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(records), logEntryEvent.RecordJson__c);
        System.Assert.areEqual(apexException.getMessage(), logEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual(apexException.getTypeName(), logEntryEvent.ExceptionType__c);
    }
    // End exception methods for LogMessage

    // Start exception methods for String
    @IsTest
    static void it_should_save_and_throw_exception_for_string_message() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        String message = 'Something broke 😥';
        System.Exception apexException = new System.DmlException('oops, some DML broke');

        System.Exception thrownException;
        try {
            Logger.exception(message, apexException);
        } catch (Exception ex) {
            thrownException = ex;
        }

        System.Assert.areEqual(apexException, thrownException);
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e logEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(System.LoggingLevel.ERROR.name(), logEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(message, logEntryEvent.Message__c);
        System.Assert.areEqual(apexException.getMessage(), logEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual(apexException.getTypeName(), logEntryEvent.ExceptionType__c);
    }

    @IsTest
    static void it_should_save_and_throw_exception_for_string_message_with_recordId() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        String message = 'Something broke 😥';
        Id recordId = System.UserInfo.getUserId();
        System.Exception apexException = new System.DmlException('oops, some DML broke');

        System.Exception thrownException;
        try {
            Logger.exception(message, recordId, apexException);
        } catch (Exception ex) {
            thrownException = ex;
        }

        System.Assert.areEqual(apexException, thrownException);
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e logEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(System.LoggingLevel.ERROR.name(), logEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(message, logEntryEvent.Message__c);
        System.Assert.areEqual(recordId, logEntryEvent.RecordId__c);
        System.Assert.areEqual(apexException.getMessage(), logEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual(apexException.getTypeName(), logEntryEvent.ExceptionType__c);
    }

    @IsTest
    static void it_should_save_and_throw_exception_for_string_message_with_record() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        String message = 'Something broke 😥';
        User record = new User(Id = System.UserInfo.getUserId());
        System.Exception apexException = new System.DmlException('oops, some DML broke');

        System.Exception thrownException;
        try {
            Logger.exception(message, record, apexException);
        } catch (Exception ex) {
            thrownException = ex;
        }

        System.Assert.areEqual(apexException, thrownException);
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e logEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(System.LoggingLevel.ERROR.name(), logEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(message, logEntryEvent.Message__c);
        System.Assert.areEqual(record.Id, logEntryEvent.RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(record), logEntryEvent.RecordJson__c);
        System.Assert.areEqual(apexException.getMessage(), logEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual(apexException.getTypeName(), logEntryEvent.ExceptionType__c);
    }

    @IsTest
    static void it_should_save_and_throw_exception_for_string_message_with_recordList() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        String message = 'Something broke 😥';
        List<User> records = new List<User>{ new User(Id = System.UserInfo.getUserId()) };
        System.Exception apexException = new System.DmlException('oops, some DML broke');

        System.Exception thrownException;
        try {
            Logger.exception(message, records, apexException);
        } catch (Exception ex) {
            thrownException = ex;
        }

        System.Assert.areEqual(apexException, thrownException);
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e logEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(System.LoggingLevel.ERROR.name(), logEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(message, logEntryEvent.Message__c);
        System.Assert.isNull(logEntryEvent.RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(records), logEntryEvent.RecordJson__c);
        System.Assert.areEqual(apexException.getMessage(), logEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual(apexException.getTypeName(), logEntryEvent.ExceptionType__c);
    }
    // End exception methods for String

    // Start ERROR methods for LogMessage
    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult convertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), convertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(convertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(convertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult convertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), convertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(convertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(convertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_deleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), deleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_saveResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), saveResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_undeleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), undeleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_upsertResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordId_and_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord().Id, getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_record_and_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord(), getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordList_and_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), users, getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_logMessage() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End ERROR methods for LogMessage

    // Start ERROR methods for String
    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_deleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), deleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_saveResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), saveResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_undeleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), undeleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_upsertResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_recordId_and_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord().Id, getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_record_and_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord(), getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_recordList_and_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), users, getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_error_entry_for_string_message() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    // Start WARN methods for LogMessage
    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_successful_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_failed_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_recordId_and_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord().Id, getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_record_and_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord(), getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_recordList_and_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), users, getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_logMessage() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End WARN methods for LogMessage

    // Start WARN methods for String
    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_successful_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_failed_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_recordId_and_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord().Id, getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_record_and_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord(), getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_recordList_and_exception() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), users, getException());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_a_warn_entry_for_string_message() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End WARN methods for String

    // Start INFO methods for LogMessage
    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_deleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), deleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_saveResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), saveResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_undeleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), undeleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_upsertResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), upsertResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_logMessage() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End INFO methods for LogMessage

    // Start INFO methods for String
    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_deleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), deleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_saveResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), saveResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_undeleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), undeleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_upsertResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), upsertResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_info_entry_for_string_message() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End INFO methods for String

    // Start DEBUG methods for LogMessage
    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_deleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), deleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_saveResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), saveResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_undeleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), undeleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_upsertResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), upsertResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_logMessage() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End DEBUG methods for LogMessage

    // Start DEBUG methods for String
    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_deleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), deleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_saveResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), saveResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_undeleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), undeleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_upsertResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), upsertResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_debug_entry_for_string_message() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End DEBUG methods for String

    // Start FINE methods for LogMessage
    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_deleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), deleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_saveResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), saveResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_undeleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), undeleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_upsertResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), upsertResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_logMessage() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End FINE methods for LogMessage

    // Start FINE methods for String
    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_deleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), deleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_saveResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), saveResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_undeleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), undeleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_upsertResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), upsertResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_fine_entry_for_string_message() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End FINE methods for String

    // Start FINER methods for LogMessage
    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_deleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), deleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_saveResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), saveResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_undeleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), undeleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_upsertResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), upsertResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_logMessage() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End FINER methods for LogMessage

    // Start FINER methods for String
    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_deleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), deleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_saveResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), saveResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_undeleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), undeleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_upsertResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), upsertResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finer_entry_for_string_message() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End FINER methods for String

    // Start FINEST methods for LogMessage
    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_deleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), deleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_saveResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), saveResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_undeleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), undeleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_upsertResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), upsertResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_logMessage() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End FINEST methods for LogMessage

    // Start FINEST methods for String
    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_leadConvertResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), leadConvertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(leadConvertResult.getLeadId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_deleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), deleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_saveResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), saveResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_undeleteResult() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), undeleteResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_upsertResult_when_insert() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_upsertResult_when_update() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), upsertResult);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_deleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.DeleteResult> deleteResults = getDeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), deleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_saveResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.SaveResult> saveResults = getSaveResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), saveResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(saveResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_undeleteResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UndeleteResult> undeleteResults = getUndeleteResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), undeleteResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_upsertResultList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        List<Database.UpsertResult> upsertResults = getUpsertResultList();

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), upsertResults);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResults), entryBuilder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName(), entryBuilder.getLogEntryEvent().DatabaseResultType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_recordId() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), getRecord().Id);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_record() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), getRecord());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message_with_recordList() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), users);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_add_an_finest_entry_for_string_message() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End FINEST methods for String

    // Start logDatabaseErrors() test methods
    @IsTest
    static void it_should_skip_logging_database_leadConvertResult_for_logMessage_when_logging_level_is_disabled() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.LeadConvertResult successfulResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true, recordId);
        Database.LeadConvertResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(false, recordId);
        List<Database.LeadConvertResult> leadConvertResults = new List<Database.LeadConvertResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, leadConvertResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, leadConvertResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_skip_logging_database_leadConvertResult_for_logMessage_when_no_errors_found() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.LeadConvertResult successfulResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true, recordId);
        Database.LeadConvertResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true, recordId);
        List<Database.LeadConvertResult> leadConvertResults = new List<Database.LeadConvertResult>{ successfulResult, anotherSuccessfulResult };
        System.Assert.areEqual(2, leadConvertResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, leadConvertResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_log_database_leadConvertResult_for_string_message_when_isSuccess_is_false() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.LeadConvertResult successfulResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true, recordId);
        Database.LeadConvertResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(false, recordId);
        List<Database.LeadConvertResult> convertResults = new List<Database.LeadConvertResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, convertResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, convertResults);

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.isTrue(returnedBuilder.shouldSave());
        System.Assert.areEqual(message, returnedBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.LeadConvertResult>{ unsuccessfulResult });
        System.Assert.areEqual(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_leadConvertResult_for_string_message_when_logging_level_is_disabled() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.LeadConvertResult successfulResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true, recordId);
        Database.LeadConvertResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(false, recordId);
        List<Database.LeadConvertResult> leadConvertResults = new List<Database.LeadConvertResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, leadConvertResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, leadConvertResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_skip_logging_database_leadConvertResult_for_string_message_when_no_errors_found() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.LeadConvertResult successfulResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true, recordId);
        Database.LeadConvertResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true, recordId);
        List<Database.LeadConvertResult> leadConvertResults = new List<Database.LeadConvertResult>{ successfulResult, anotherSuccessfulResult };
        System.Assert.areEqual(2, leadConvertResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, leadConvertResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_skip_logging_database_deleteResult_for_logMessage_when_logging_level_is_disabled() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.DeleteResult successfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        Database.DeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(false, recordId);
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, deleteResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, deleteResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_skip_logging_database_deleteResult_for_logMessage_when_no_errors_found() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.DeleteResult successfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        Database.DeleteResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>{ successfulResult, anotherSuccessfulResult };
        System.Assert.areEqual(2, deleteResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, deleteResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_log_database_deleteResult_for_logMessage_when_isSuccess_is_false() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.DeleteResult successfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        Database.DeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(false, recordId);
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, deleteResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, deleteResults);

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.isTrue(returnedBuilder.shouldSave());
        System.Assert.areEqual(logMessage.getMessage(), returnedBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.DeleteResult>{ unsuccessfulResult });
        System.Assert.areEqual(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_deleteResult_for_string_message_when_logging_level_is_disabled() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.DeleteResult successfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        Database.DeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(false, recordId);
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, deleteResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, deleteResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_skip_logging_database_deleteResult_for_string_message_when_no_errors_found() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.DeleteResult successfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        Database.DeleteResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>{ successfulResult, anotherSuccessfulResult };
        System.Assert.areEqual(2, deleteResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, deleteResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_log_database_deleteResult_for_string_message_when_isSuccess_is_false() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.DeleteResult successfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(true, recordId);
        Database.DeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseDeleteResult(false, recordId);
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, deleteResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, deleteResults);

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.isTrue(returnedBuilder.shouldSave());
        System.Assert.areEqual(message, returnedBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.DeleteResult>{ unsuccessfulResult });
        System.Assert.areEqual(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_mergeResult_for_logMessage_when_logging_level_is_disabled() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.MergeResult successfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        Database.MergeResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseMergeResult(false, recordId);
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, mergeResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, mergeResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_skip_logging_database_mergeResult_for_logMessage_when_no_errors_found() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.MergeResult successfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        Database.MergeResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>{ successfulResult, anotherSuccessfulResult };
        System.Assert.areEqual(2, mergeResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, mergeResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_log_database_mergeResult_for_logMessage_when_isSuccess_is_false() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.MergeResult successfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        Database.MergeResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseMergeResult(false, recordId);
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, mergeResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, mergeResults);

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.isTrue(returnedBuilder.shouldSave());
        System.Assert.areEqual(logMessage.getMessage(), returnedBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.MergeResult>{ unsuccessfulResult });
        System.Assert.areEqual(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_mergeResult_for_string_message_when_logging_level_is_disabled() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.MergeResult successfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        Database.MergeResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseMergeResult(false, recordId);
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, mergeResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, mergeResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_skip_logging_database_mergeResult_for_string_message_when_no_errors_found() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.MergeResult successfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        Database.MergeResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>{ successfulResult, anotherSuccessfulResult };
        System.Assert.areEqual(2, mergeResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, mergeResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_log_database_mergeResult_for_string_message_when_isSuccess_is_false() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.MergeResult successfulResult = LoggerMockDataCreator.createDatabaseMergeResult(true, recordId);
        Database.MergeResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseMergeResult(false, recordId);
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, mergeResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, mergeResults);

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.isTrue(returnedBuilder.shouldSave());
        System.Assert.areEqual(message, returnedBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.MergeResult>{ unsuccessfulResult });
        System.Assert.areEqual(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_saveResult_for_logMessage_when_logging_level_is_disabled() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.SaveResult successfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        Database.SaveResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseSaveResult(false, recordId);
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, saveResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, saveResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_skip_logging_database_saveResult_for_logMessage_when_no_errors_found() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.SaveResult successfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        Database.SaveResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ successfulResult, anotherSuccessfulResult };
        System.Assert.areEqual(2, saveResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, saveResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_log_database_saveResult_for_logMessage_when_isSuccess_is_false() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.SaveResult successfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        Database.SaveResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseSaveResult(false, recordId);
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, saveResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, saveResults);

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.isTrue(returnedBuilder.shouldSave());
        System.Assert.areEqual(logMessage.getMessage(), returnedBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.SaveResult>{ unsuccessfulResult });
        System.Assert.areEqual(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_saveResult_for_string_message_when_logging_level_is_disabled() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.SaveResult successfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        Database.SaveResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseSaveResult(false, recordId);
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, saveResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, saveResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_skip_logging_database_saveResult_for_string_message_when_no_errors_found() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.SaveResult successfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        Database.SaveResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ successfulResult, anotherSuccessfulResult };
        System.Assert.areEqual(2, saveResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, saveResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_log_database_saveResult_for_string_message_when_isSuccess_is_false() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.SaveResult successfulResult = LoggerMockDataCreator.createDatabaseSaveResult(true, recordId);
        Database.SaveResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseSaveResult(false, recordId);
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, saveResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, saveResults);

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.isTrue(returnedBuilder.shouldSave());
        System.Assert.areEqual(message, returnedBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.SaveResult>{ unsuccessfulResult });
        System.Assert.areEqual(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_upsertResult_for_logMessage_when_logging_level_is_disabled() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.UpsertResult successfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        Database.UpsertResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true, recordId);
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, upsertResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, upsertResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_skip_logging_database_upsertResult_for_logMessage_when_no_errors_found() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.UpsertResult successfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        Database.UpsertResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>{ successfulResult, anotherSuccessfulResult };
        System.Assert.areEqual(2, upsertResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, upsertResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_log_database_upsertResult_for_logMessage_when_isSuccess_is_false() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.UpsertResult successfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        Database.UpsertResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true, recordId);
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, upsertResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, upsertResults);

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.isTrue(returnedBuilder.shouldSave());
        System.Assert.areEqual(logMessage.getMessage(), returnedBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.UpsertResult>{ unsuccessfulResult });
        System.Assert.areEqual(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_upsertResult_for_string_message_when_logging_level_is_disabled() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.UpsertResult successfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        Database.UpsertResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true, recordId);
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, upsertResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, upsertResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_skip_logging_database_upsertResult_for_string_message_when_no_errors_found() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.UpsertResult successfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        Database.UpsertResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>{ successfulResult, anotherSuccessfulResult };
        System.Assert.areEqual(2, upsertResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, upsertResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_log_database_upsertResult_for_string_message_when_isSuccess_is_false() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.UpsertResult successfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true, recordId);
        Database.UpsertResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUpsertResult(false, true, recordId);
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, upsertResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, upsertResults);

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.isTrue(returnedBuilder.shouldSave());
        System.Assert.areEqual(message, returnedBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.UpsertResult>{ unsuccessfulResult });
        System.Assert.areEqual(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_undeleteResult_for_logMessage_when_logging_level_is_disabled() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.UndeleteResult successfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        Database.UndeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(false, recordId);
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, undeleteResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, undeleteResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_skip_logging_database_undeleteResult_for_logMessage_when_no_errors_found() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.UndeleteResult successfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        Database.UndeleteResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>{ successfulResult, anotherSuccessfulResult };
        System.Assert.areEqual(2, undeleteResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, undeleteResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_log_database_undeleteResult_for_logMessage_when_isSuccess_is_false() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        LogMessage logMessage = new LogMessage('Some logMessage for ID {0}', System.UserInfo.getUserId());
        Id recordId = System.UserInfo.getUserId();
        Database.UndeleteResult successfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        Database.UndeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(false, recordId);
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, undeleteResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, logMessage, undeleteResults);

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.isTrue(returnedBuilder.shouldSave());
        System.Assert.areEqual(logMessage.getMessage(), returnedBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.UndeleteResult>{ unsuccessfulResult });
        System.Assert.areEqual(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }

    @IsTest
    static void it_should_skip_logging_database_undeleteResult_for_string_message_when_logging_level_is_disabled() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.UndeleteResult successfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        Database.UndeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(false, recordId);
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, undeleteResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, undeleteResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_skip_logging_database_undeleteResult_for_string_message_when_no_errors_found() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.UndeleteResult successfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        Database.UndeleteResult anotherSuccessfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>{ successfulResult, anotherSuccessfulResult };
        System.Assert.areEqual(2, undeleteResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.ERROR.name();
        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, undeleteResults);

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.isFalse(returnedBuilder.shouldSave());
    }

    @IsTest
    static void it_should_log_database_undeleteResult_for_string_message_when_isSuccess_is_false() {
        System.LoggingLevel logEntryLevel = System.LoggingLevel.WARN;
        String message = 'Some message';
        Id recordId = System.UserInfo.getUserId();
        Database.UndeleteResult successfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true, recordId);
        Database.UndeleteResult unsuccessfulResult = LoggerMockDataCreator.createDatabaseUndeleteResult(false, recordId);
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>{ successfulResult, unsuccessfulResult };
        System.Assert.areEqual(2, undeleteResults.size());
        System.Assert.areEqual(0, Logger.getBufferSize());

        LogEntryEventBuilder returnedBuilder = Logger.logDatabaseErrors(logEntryLevel, message, undeleteResults);

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.isTrue(returnedBuilder.shouldSave());
        System.Assert.areEqual(message, returnedBuilder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(1, returnedBuilder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        String expectedDatabaseResultJson = JSON.serializePretty(new List<Database.UndeleteResult>{ unsuccessfulResult });
        System.Assert.areEqual(expectedDatabaseResultJson, returnedBuilder.getLogEntryEvent().DatabaseResultJson__c);
    }
    // End logDatabaseErrors() test methods

    // Start newEntry for LogMessage test methods
    @IsTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_logMessage_and_shouldSave_override() {
        System.LoggingLevel userLoggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.FINEST;
        System.Assert.isFalse(Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        Boolean shouldSave = true;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getLogMessage(), shouldSave);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(shouldSave, entryBuilder.shouldSave());
        System.Assert.areEqual(logEntryLoggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_not_add_a_new_entry_for_loggingLevel_with_logMessage_and_shouldNotSave_override() {
        System.LoggingLevel userLoggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.FINEST;
        System.Assert.isFalse(Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        Boolean shouldSave = false;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getLogMessage(), shouldSave);

        System.Test.stopTest();

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(shouldSave, entryBuilder.shouldSave());
        System.Assert.isNull(entryBuilder.getLogEntryEvent());
    }

    @IsTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_logMessage() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.newEntry(loggingLevel, getLogMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.isTrue(entryBuilder.shouldSave());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End newEntry for LogMessage test methods

    // Start newEntry for String test methods
    @IsTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_string_and_shouldSave_override() {
        System.LoggingLevel userLoggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.FINEST;
        System.Assert.isFalse(Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        Boolean shouldSave = true;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getMessage(), shouldSave);

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.areEqual(shouldSave, entryBuilder.shouldSave());
        System.Assert.areEqual(logEntryLoggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_not_add_a_new_entry_for_loggingLevel_with_string_and_shouldNotSave_override() {
        System.LoggingLevel userLoggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.FINEST;
        System.Assert.isFalse(Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        Boolean shouldSave = false;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getMessage(), shouldSave);

        System.Test.stopTest();

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(shouldSave, entryBuilder.shouldSave());
        System.Assert.isNull(entryBuilder.getLogEntryEvent());
    }

    @IsTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_string() {
        System.LoggingLevel loggingLevel = System.LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.Assert.areEqual(0, Logger.getBufferSize());

        System.Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.newEntry(loggingLevel, getMessage());

        System.Test.stopTest();

        System.Assert.areEqual(1, Logger.getBufferSize());
        System.Assert.isTrue(entryBuilder.shouldSave());
        System.Assert.areEqual(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.Assert.areEqual(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.Assert.isNull(entryBuilder.getLogEntryEvent().Tags__c);
    }
    // End newEntry for String test methods

    // Start tests for utility methods
    @IsTest
    static void it_should_return_logging_levels_for_string_names() {
        System.Assert.areEqual(System.LoggingLevel.DEBUG, Logger.getLoggingLevel('fake'));
        System.Assert.areEqual(System.LoggingLevel.NONE, Logger.getLoggingLevel('none'));
        System.Assert.areEqual(System.LoggingLevel.ERROR, Logger.getLoggingLevel('error'));
        System.Assert.areEqual(System.LoggingLevel.WARN, Logger.getLoggingLevel('warn'));
        System.Assert.areEqual(System.LoggingLevel.INFO, Logger.getLoggingLevel('info'));
        System.Assert.areEqual(System.LoggingLevel.DEBUG, Logger.getLoggingLevel('debug'));
        System.Assert.areEqual(System.LoggingLevel.FINE, Logger.getLoggingLevel('fine'));
        System.Assert.areEqual(System.LoggingLevel.FINER, Logger.getLoggingLevel('finer'));
        System.Assert.areEqual(System.LoggingLevel.FINEST, Logger.getLoggingLevel('finest'));
    }

    @IsTest
    static void it_should_return_callout_response_from_status_api() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = System.JSON.serialize(true)));
        System.Assert.isTrue(LoggerParameter.CALL_STATUS_API);
        Logger.StatusApiResponse mockApiResponse = new Logger.StatusApiResponse();
        mockApiResponse.location = 'NA';
        mockApiResponse.maintenanceWindow = 'Saturdays 07:00 PM - 11:00 PM PST';
        mockApiResponse.releaseNumber = '242.19.17';
        mockApiResponse.releaseVersion = 'Spring \'23 Patch 19.17';
        System.Test.setMock(
            System.HttpCalloutMock.class,
            LoggerMockDataCreator.createHttpCallout().setStatusCode(200).setResponseBody(JSON.serialize(mockApiResponse))
        );

        Logger.StatusApiResponse returnedApiResponse = Logger.callStatusApi();

        System.Assert.areEqual(JSON.serialize(mockApiResponse), JSON.serialize(returnedApiResponse));
    }

    @IsTest
    static void it_should_gracefully_return_null_when_callout_fails_to_status_api() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = System.JSON.serialize(true)));
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'EnableLoggerSystemMessages', Value__c = System.JSON.serialize(true)));
        System.Assert.isTrue(LoggerParameter.CALL_STATUS_API);
        String mockErrorMessage = 'It broke! 😥';
        Integer errorStatusCode = 404;
        String errorStatusMessage = 'Oops, did not understand request, or something... IDK.... it\'s broken ¯\\_(ツ)_/¯';
        System.Test.setMock(
            System.HttpCalloutMock.class,
            LoggerMockDataCreator.createHttpCallout().setStatusCode(errorStatusCode).setStatus(errorStatusMessage).setResponseBody(mockErrorMessage)
        );
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        Logger.StatusApiResponse returnedApiResponse = Logger.callStatusApi();

        System.Assert.isNull(returnedApiResponse);
        Logger.saveLog();
        System.Assert.areEqual(2, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e logEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual('Callout to api.status.salesforce.com failed', logEntryEvent.Message__c);
        System.Assert.areEqual('System.CalloutException', logEntryEvent.ExceptionType__c);
        Organization organization = LoggerEngineDataSelector.getInstance().getCachedOrganization();
        String expectedExceptionMessage =
            'Callout failed for https://api.status.salesforce.com/v1/instances/' +
            organization.InstanceName +
            '/status' +
            '\nReceived request status code ' +
            errorStatusCode +
            ', status message: ' +
            errorStatusMessage;
        System.Assert.areEqual(expectedExceptionMessage, logEntryEvent.ExceptionMessage__c);
    }

    @IsTest
    static void it_should_return_null_when_status_api_callout_is_disabled() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = System.JSON.serialize(false)));
        System.Assert.isFalse(LoggerParameter.CALL_STATUS_API);

        Logger.StatusApiResponse returnedApiResponse = Logger.callStatusApi();

        System.Assert.isNull(returnedApiResponse);
    }
    // End tests for utility methods

    // Helper methods
    static void setUserLoggingLevel(System.LoggingLevel loggingLevel) {
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
            Id = System.UserInfo.getUserId(),
            ProfileId = System.UserInfo.getProfileId(),
            Username = System.UserInfo.getUsername(),
            UserRoleId = System.UserInfo.getUserRoleId()
        );
    }

    static System.Exception getException() {
        return new System.DmlException('Example DML System.Exception');
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
        for (String currentStackTraceLine : new System.DmlException().getStackTraceString().split('\n')) {
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

    public class MockClassWithLogging {
        public LogEntryEventBuilder logSomething() {
            return Logger.info('Hello, world');
        }
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
