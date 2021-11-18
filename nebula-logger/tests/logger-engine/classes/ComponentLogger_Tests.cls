//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class ComponentLogger_Tests {
    @IsTest
    static void it_should_return_logger_settings() {
        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.IsEnabled__c = true;
        loggerSettings.LoggingLevel__c = 'FINEST';
        upsert loggerSettings;

        Test.startTest();
        ComponentLogger.ComponentLoggerSettings componentLoggerSettings = ComponentLogger.getSettings();
        Test.stopTest();

        System.assertEquals(loggerSettings.IsEnabled__c, componentLoggerSettings.isEnabled);
        System.assertEquals(loggerSettings.LoggingLevel__c, componentLoggerSettings.userLoggingLevel.name);

        LoggingLevel userLoggingLevel = Logger.getLoggingLevel(loggerSettings.LoggingLevel__c);
        System.assertEquals(userLoggingLevel.name(), componentLoggerSettings.userLoggingLevel.name);
        System.assertEquals(userLoggingLevel.ordinal(), componentLoggerSettings.userLoggingLevel.ordinal);

        for (LoggingLevel currentLoggingLevel : LoggingLevel.values()) {
            // We don't care about logging level NONE, or the secret/undocumented INTERNAL logging level
            if (currentLoggingLevel == LoggingLevel.NONE || currentLoggingLevel == LoggingLevel.INTERNAL) {
                continue;
            }

            System.assert(
                componentLoggerSettings.supportedLoggingLevels.containsKey(currentLoggingLevel.name()),
                'Cmp settings did not contain level: ' + currentLoggingLevel
            );

            Integer returnedOrdinal = componentLoggerSettings.supportedLoggingLevels.get(currentLoggingLevel.name());
            System.assertEquals(currentLoggingLevel.ordinal(), returnedOrdinal);
        }
    }

    @IsTest
    static void it_should_return_aura_exception_when_it_breaks() {
        Test.startTest();
        try {
            ComponentLogger.saveComponentLogEntries(null, null);
            System.assert(false, 'This assert shouldn\'t run since this is a negative test');
        } catch (Exception apexException) {
            System.assertEquals(AuraHandledException.class.getName(), apexException.getTypeName());
        }
        Test.stopTest();
    }

    @IsTest
    static void it_should_save_component_log_entry() {
        upsert LoggerSettings__c.getInstance();
        System.assertEquals(0, [SELECT COUNT() FROM Log__c]);

        User currentUser = new User(FirstName = UserInfo.getFirstName(), Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());

        List<ComponentLogger.ComponentLogEntry> componentLogEntries = new List<ComponentLogger.ComponentLogEntry>();
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.recordId = currentUser.Id;
        componentLogEntry.record = currentUser;
        componentLogEntry.timestamp = System.now().addDays(-1 / 24);
        componentLogEntry.tags = new List<String>{ 'some tag', 'one more tag' };
        componentLogEntries.add(componentLogEntry);

        Test.startTest();
        ComponentLogger.saveComponentLogEntries(componentLogEntries, null);
        Test.stopTest();

        List<LogEntry__c> logEntries = [
            SELECT Id, LoggingLevel__c, Message__c, RecordId__c, RecordJson__c, RecordSObjectType__c, Timestamp__c
            FROM LogEntry__c
        ];
        System.assertEquals(1, logEntries.size());

        LogEntry__c logEntry = logEntries.get(0);

        System.assertEquals(componentLogEntry.loggingLevel, logEntry.LoggingLevel__c);
        System.assertEquals(componentLogEntry.message, logEntry.Message__c);
        System.assertEquals(componentLogEntry.recordId, logEntry.RecordId__c);
        System.assertEquals(JSON.serializePretty(currentUser), logEntry.RecordJson__c);
        System.assertEquals(Schema.SObjectType.User.getName(), logEntry.RecordSObjectType__c);
        System.assertEquals(componentLogEntry.timestamp, logEntry.Timestamp__c);
    }

    @IsTest
    static void it_should_save_component_log_entry_with_queueable_job() {
        upsert LoggerSettings__c.getInstance();
        System.assertEquals(0, [SELECT COUNT() FROM Log__c]);

        User currentUser = new User(FirstName = UserInfo.getFirstName(), Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());

        List<ComponentLogger.ComponentLogEntry> componentLogEntries = new List<ComponentLogger.ComponentLogEntry>();
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.recordId = currentUser.Id;
        componentLogEntry.record = currentUser;
        componentLogEntry.timestamp = System.now().addDays(-1 / 24);
        componentLogEntry.tags = new List<String>{ 'some tag', 'one more tag' };
        componentLogEntries.add(componentLogEntry);

        Test.startTest();
        System.assertEquals(0, Limits.getQueueableJobs(), 'Test should start with 0 queueable jobs used');

        ComponentLogger.saveComponentLogEntries(componentLogEntries, Logger.SaveMethod.QUEUEABLE.name());

        System.assertEquals(1, Limits.getQueueableJobs(), 'Log entries should have been saved using the QUEUEABLE save method');
        Test.stopTest();

        List<LogEntry__c> logEntries = [
            SELECT Id, LoggingLevel__c, Message__c, RecordId__c, RecordJson__c, RecordSObjectType__c, Timestamp__c
            FROM LogEntry__c
        ];
        System.assertEquals(1, logEntries.size());

        LogEntry__c logEntry = logEntries.get(0);

        System.assertEquals(componentLogEntry.loggingLevel, logEntry.LoggingLevel__c);
        System.assertEquals(componentLogEntry.message, logEntry.Message__c);
        System.assertEquals(componentLogEntry.recordId, logEntry.RecordId__c);
        System.assertEquals(JSON.serializePretty(currentUser), logEntry.RecordJson__c);
        System.assertEquals(Schema.SObjectType.User.getName(), logEntry.RecordSObjectType__c);
        System.assertEquals(componentLogEntry.timestamp, logEntry.Timestamp__c);
    }

    @IsTest
    static void it_should_save_component_log_entry_with_javascript_error() {
        upsert LoggerSettings__c.getInstance();
        System.assertEquals(0, [SELECT COUNT() FROM Log__c]);

        User currentUser = new User(FirstName = UserInfo.getFirstName(), Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());

        List<ComponentLogger.ComponentLogEntry> componentLogEntries = new List<ComponentLogger.ComponentLogEntry>();
        ComponentLogger.ComponentError mockComponentError = new ComponentLogger.ComponentError();
        mockComponentError.message = 'some javascript error message';
        mockComponentError.stack = 'some \nstack \ntrace \nstring';
        mockComponentError.type = 'ReferenceError';

        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.error = mockComponentError;
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.recordId = currentUser.Id;
        componentLogEntry.record = currentUser;
        componentLogEntry.timestamp = System.now().addDays(-1 / 24);
        componentLogEntry.tags = new List<String>{ 'some tag', 'one more tag' };
        componentLogEntries.add(componentLogEntry);

        Test.startTest();
        ComponentLogger.saveComponentLogEntries(componentLogEntries, null);
        Test.stopTest();

        List<LogEntry__c> logEntries = [
            SELECT Id, LoggingLevel__c, Message__c, ExceptionMessage__c, ExceptionStackTrace__c, ExceptionType__c, Timestamp__c
            FROM LogEntry__c
        ];
        System.assertEquals(1, logEntries.size());

        LogEntry__c logEntry = logEntries.get(0);

        System.assertEquals(componentLogEntry.loggingLevel, logEntry.LoggingLevel__c);
        System.assertEquals(componentLogEntry.message, logEntry.Message__c);
        System.assertEquals(componentLogEntry.timestamp, logEntry.Timestamp__c);
        System.assertEquals(componentLogEntry.error.message, logEntry.ExceptionMessage__c);
        System.assertEquals(componentLogEntry.error.stack, logEntry.ExceptionStackTrace__c);
        System.assertEquals(ComponentLogger.EXCEPTION_TYPE_PREFIX + componentLogEntry.error.type, logEntry.ExceptionType__c);
    }

    @IsTest
    static void it_should_set_log_scenario() {
        System.assertEquals(0, [SELECT COUNT() FROM Log__c]);
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();

        List<ComponentLogger.ComponentLogEntry> componentLogEntries = new List<ComponentLogger.ComponentLogEntry>();
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.scenario = 'Some scenario';
        componentLogEntry.timestamp = System.now();
        componentLogEntries.add(componentLogEntry);

        Test.startTest();
        ComponentLogger.saveComponentLogEntries(componentLogEntries, null);
        Test.stopTest();

        Log__c log = [SELECT Id, Scenario__c FROM Log__c];
        System.assertEquals(componentLogEntry.scenario, log.Scenario__c);
    }

    @IsTest
    static void it_should_parse_aura_component_stack_trace() {
        String expectedComponentType = 'Aura';
        String expectedComponentApiName = 'c/loggerAuraDemo';
        String expectedComponentFunctionName = 'saveLogAuraExample';

        List<ComponentLogger.ComponentLogEntry> componentLogEntries = new List<ComponentLogger.ComponentLogEntry>();
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.stack = getMockAuraComponentStackTrace();
        componentLogEntry.timestamp = System.now().addDays(-1 / 24);
        componentLogEntries.add(componentLogEntry);

        Test.startTest();
        ComponentLogger.saveComponentLogEntries(componentLogEntries, null);
        Test.stopTest();

        List<LogEntry__c> logEntries = [
            SELECT
                Id,
                LoggingLevel__c,
                Message__c,
                ComponentApiName__c,
                ComponentFunctionName__c,
                ComponentType__c,
                OriginLocation__c,
                OriginType__c,
                Timestamp__c
            FROM LogEntry__c
        ];
        System.assertEquals(1, logEntries.size());

        LogEntry__c logEntry = logEntries.get(0);

        System.assertEquals(componentLogEntry.loggingLevel, logEntry.LoggingLevel__c, logEntry);
        System.assertEquals(componentLogEntry.message, logEntry.Message__c, logEntry);
        System.assertEquals('Component', logEntry.OriginType__c, logEntry);
        System.assertEquals(expectedComponentApiName + '.' + expectedComponentFunctionName, logEntry.OriginLocation__c, logEntry);
        System.assertEquals(expectedComponentApiName, logEntry.ComponentApiName__c, logEntry);
        System.assertEquals(expectedComponentFunctionName, logEntry.ComponentFunctionName__c, logEntry);
        System.assertEquals(expectedComponentType, logEntry.ComponentType__c, logEntry);
        System.assertEquals(componentLogEntry.timestamp, logEntry.Timestamp__c, logEntry);
    }

    @IsTest
    static void it_should_parse_web_component_stack_trace() {
        String expectedComponentType = 'LWC';
        String expectedComponentApiName = 'c/loggerLWCDemo';
        String expectedComponentFunctionName = 'saveLogWebExample';

        List<ComponentLogger.ComponentLogEntry> componentLogEntries = new List<ComponentLogger.ComponentLogEntry>();
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.stack = getMockWebComponentStackTrace();
        componentLogEntry.timestamp = System.now().addDays(-1 / 24);
        componentLogEntries.add(componentLogEntry);

        Test.startTest();
        ComponentLogger.saveComponentLogEntries(componentLogEntries, null);
        Test.stopTest();

        List<LogEntry__c> logEntries = [
            SELECT
                Id,
                LoggingLevel__c,
                Message__c,
                ComponentApiName__c,
                ComponentFunctionName__c,
                ComponentType__c,
                OriginLocation__c,
                OriginType__c,
                Timestamp__c
            FROM LogEntry__c
        ];
        System.assertEquals(1, logEntries.size());

        LogEntry__c logEntry = logEntries.get(0);

        System.assertEquals(componentLogEntry.loggingLevel, logEntry.LoggingLevel__c, logEntry);
        System.assertEquals(componentLogEntry.message, logEntry.Message__c, logEntry);
        System.assertEquals('Component', logEntry.OriginType__c, logEntry);
        System.assertEquals(expectedComponentApiName + '.' + expectedComponentFunctionName, logEntry.OriginLocation__c, logEntry);
        System.assertEquals(expectedComponentApiName, logEntry.ComponentApiName__c, logEntry);
        System.assertEquals(expectedComponentFunctionName, logEntry.ComponentFunctionName__c, logEntry);
        System.assertEquals(expectedComponentType, logEntry.ComponentType__c, logEntry);
        System.assertEquals(componentLogEntry.timestamp, logEntry.Timestamp__c, logEntry);
    }

    private static String getMockAuraComponentStackTrace() {
        // This is a copy of an actual stack trace generated from c/loggerAuraDemo
        return 'Error' +
            '\nat new eval (https://ability-enterprise-5142.lightning.force.com/lightning/n/modules/c/logger.js:4:237)' +
            '\nat i (https://ability-enterprise-5142.lightning.force.com/lightning/n/modules/c/logger.js:4:139)' +
            '\nat g._newEntry (https://ability-enterprise-5142.lightning.force.com/lightning/n/modules/c/logger.js:4:2208)' +
            '\nat g.info (https://ability-enterprise-5142.lightning.force.com/lightning/n/modules/c/logger.js:4:1446)' +
            '\nat callHook (https://static.lightning.force.com/cs10/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_prod.js:37:80204)' +
            '\nat HTMLElement.<anonymous> (https://static.lightning.force.com/cs10/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_prod.js:12:12752)' +
            '\nat a.<computed> [as info] (https://static.lightning.force.com/cs10/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_prod.js:455:415)' +
            '\nat Object.info (https://static.lightning.force.com/cs10/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_prod.js:37:135617)' +
            '\nat saveLogAuraExample (https://ability-enterprise-5142.lightning.force.com/lightning/n/components/c/loggerAuraDemo.js:16:30)' +
            '\nat J.Uc (https://static.lightning.force.com/cs10/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_prod.js:537:177)';
    }

    private static String getMockWebComponentStackTrace() {
        // This is a copy of an actual stack trace generated from c/loggerLWCDemo
        return 'Error' +
            '\nat new eval (https://ability-enterprise-5142.lightning.force.com/lightning/n/modules/c/logger.js:4:237)' +
            '\nat i (https://ability-enterprise-5142.lightning.force.com/lightning/n/modules/c/logger.js:4:139)' +
            '\nat g._newEntry (https://ability-enterprise-5142.lightning.force.com/lightning/n/modules/c/logger.js:4:2208)' +
            '\nat g.error (https://ability-enterprise-5142.lightning.force.com/lightning/n/modules/c/logger.js:4:1365)' +
            '\nat callHook (https://static.lightning.force.com/cs10/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_prod.js:37:80204)' +
            '\nat HTMLElement.<anonymous> (https://static.lightning.force.com/cs10/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_prod.js:12:12752)' +
            '\nat Proxy.<anonymous> (https://static.lightning.force.com/cs10/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_prod.js:37:135933)' +
            '\nat p.saveLogWebExample (https://ability-enterprise-5142.lightning.force.com/lightning/n/modules/c/loggerLWCDemo.js:4:2399)' +
            '\nat callHook (https://static.lightning.force.com/cs10/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_prod.js:37:80204)' +
            '\nat https://static.lightning.force.com/cs10/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_prod.js:12:24297';
    }
}
