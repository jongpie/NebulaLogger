//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class ComponentLogger_Tests {
    @IsTest
    static void it_should_return_logger_settings() {
        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.IsEnabled__c = true;
        loggerSettings.LoggingLevel__c = 'FINEST';
        upsert loggerSettings;

        ComponentLogger.ComponentLoggerSettings componentLoggerSettings = ComponentLogger.getSettings();

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
        try {
            ComponentLogger.saveComponentLogEntries(null, null);
            System.assert(false, 'This assert shouldn\'t run since this is a negative test');
        } catch (Exception apexException) {
            System.assertEquals(AuraHandledException.class.getName(), apexException.getTypeName());
        }
    }

    @IsTest
    static void it_should_save_component_log_entry() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        User currentUser = new User(FirstName = UserInfo.getFirstName(), Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.recordId = currentUser.Id;
        componentLogEntry.record = currentUser;
        componentLogEntry.timestamp = System.now().addDays(-1 / 24);
        componentLogEntry.tags = new List<String>{ 'some tag', 'one more tag' };
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals('Component', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals(componentLogEntry.recordId, publishedLogEntryEvent.RecordId__c);
        System.assertEquals(JSON.serializePretty(currentUser), publishedLogEntryEvent.RecordJson__c);
        System.assertEquals(Schema.SObjectType.User.getName(), publishedLogEntryEvent.RecordSObjectType__c);
        System.assertEquals(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }

    @IsTest
    static void it_should_save_component_log_entry_with_queueable_job() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerDataStore.setMock(LoggerMockDataStore.getJobQueue());
        User currentUser = new User(FirstName = UserInfo.getFirstName(), Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        System.assertEquals(0, Limits.getQueueableJobs(), 'Test should start with 0 queueable jobs used');
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.recordId = currentUser.Id;
        componentLogEntry.record = currentUser;
        componentLogEntry.timestamp = System.now().addDays(-1 / 24);
        componentLogEntry.tags = new List<String>{ 'some tag', 'one more tag' };
        System.Test.startTest();
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        System.assertEquals(0, LoggerMockDataStore.getJobQueue().getEnqueuedJobs().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, Logger.SaveMethod.QUEUEABLE.name());
        System.assertEquals(1, LoggerMockDataStore.getJobQueue().getEnqueuedJobs().size());
        LoggerMockDataStore.getJobQueue().executeJobs();

        System.assertEquals(Logger.SaveMethod.QUEUEABLE.name(), Logger.lastSaveMethodNameUsed);
        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals('Component', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals(componentLogEntry.recordId, publishedLogEntryEvent.RecordId__c);
        System.assertEquals(JSON.serializePretty(currentUser), publishedLogEntryEvent.RecordJson__c);
        System.assertEquals(Schema.SObjectType.User.getName(), publishedLogEntryEvent.RecordSObjectType__c);
        System.assertEquals(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }

    @IsTest
    static void it_should_save_component_log_entry_with_javascript_error() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        User currentUser = new User(FirstName = UserInfo.getFirstName(), Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        ComponentLogger.ComponentError mockComponentError = new ComponentLogger.ComponentError();
        mockComponentError.message = 'some JavaScript error message';
        mockComponentError.stack = 'some \nstack \ntrace \nstring';
        mockComponentError.type = 'JavaScript.ReferenceError';
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.error = mockComponentError;
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.recordId = currentUser.Id;
        componentLogEntry.record = currentUser;
        componentLogEntry.timestamp = System.now().addDays(-1 / 24);
        componentLogEntry.tags = new List<String>{ 'some tag', 'one more tag' };
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals('Component', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
        System.assertEquals(componentLogEntry.error.message, publishedLogEntryEvent.ExceptionMessage__c);
        System.assertEquals(componentLogEntry.error.stack, publishedLogEntryEvent.ExceptionStackTrace__c);
        System.assertEquals(componentLogEntry.error.type, publishedLogEntryEvent.ExceptionType__c);
    }

    @IsTest
    static void it_should_save_component_log_entry_with_apex_controller_error() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        User currentUser = new User(FirstName = UserInfo.getFirstName(), Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
        Exception mockApexException = new DmlException('It is with much sadness that I must inform you that this DML statement was most unsuccessful');
        ComponentLogger.ComponentError mockComponentError = new ComponentLogger.ComponentError();
        mockComponentError.message = mockApexException.getMessage();
        mockComponentError.stack = mockApexException.getStackTraceString();
        mockComponentError.type = mockApexException.getTypeName();
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.error = mockComponentError;
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.recordId = currentUser.Id;
        componentLogEntry.record = currentUser;
        componentLogEntry.timestamp = System.now().addDays(-1 / 24);
        componentLogEntry.tags = new List<String>{ 'some tag', 'one more tag' };
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals('Component', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
        System.assertEquals(componentLogEntry.error.message, publishedLogEntryEvent.ExceptionMessage__c);
        System.assertEquals(componentLogEntry.error.stack, publishedLogEntryEvent.ExceptionStackTrace__c);
        System.assertEquals(componentLogEntry.error.type, publishedLogEntryEvent.ExceptionType__c);
    }

    @IsTest
    static void it_should_set_log_scenario() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.scenario = 'Some scenario';
        componentLogEntry.timestamp = System.now();
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals('Component', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(componentLogEntry.scenario, publishedLogEntryEvent.Scenario__c);
    }

    @IsTest
    static void it_should_parse_aura_component_stack_trace() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String expectedComponentType = 'Aura';
        String expectedComponentApiName = 'c/loggerAuraDemo';
        String expectedComponentFunctionName = 'saveLogAuraExample';
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.stack = getMockAuraComponentStackTrace();
        componentLogEntry.timestamp = System.now().addDays(-1 / 24);
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals('Component', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c, publishedLogEntryEvent);
        System.assertEquals(componentLogEntry.message, publishedLogEntryEvent.Message__c, publishedLogEntryEvent);
        System.assertEquals('Component', publishedLogEntryEvent.OriginType__c, publishedLogEntryEvent);
        System.assertEquals(expectedComponentApiName + '.' + expectedComponentFunctionName, publishedLogEntryEvent.OriginLocation__c, publishedLogEntryEvent);
        // TODO Move these asserts to LogEntryHandler_Tests
        // System.assertEquals(expectedComponentApiName, publishedLogEntryEvent.ComponentApiName__c, publishedLogEntryEvent);
        // System.assertEquals(expectedComponentFunctionName, publishedLogEntryEvent.ComponentFunctionName__c, publishedLogEntryEvent);
        System.assertEquals(expectedComponentType, publishedLogEntryEvent.ComponentType__c, publishedLogEntryEvent);
        System.assertEquals(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c, publishedLogEntryEvent);
    }

    @IsTest
    static void it_should_parse_web_component_stack_trace() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String expectedComponentType = 'LWC';
        String expectedComponentApiName = 'c/loggerLWCDemo';
        String expectedComponentFunctionName = 'saveLogWebExample';
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.stack = getMockWebComponentStackTrace();
        componentLogEntry.timestamp = System.now().addDays(-1 / 24);
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals('Component', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c, publishedLogEntryEvent);
        System.assertEquals(componentLogEntry.message, publishedLogEntryEvent.Message__c, publishedLogEntryEvent);
        System.assertEquals('Component', publishedLogEntryEvent.OriginType__c, publishedLogEntryEvent);
        System.assertEquals(expectedComponentApiName + '.' + expectedComponentFunctionName, publishedLogEntryEvent.OriginLocation__c, publishedLogEntryEvent);
        // TODO Move these asserts to LogEntryHandler_Tests
        // System.assertEquals(expectedComponentApiName, publishedLogEntryEvent.ComponentApiName__c, publishedLogEntryEvent);
        // System.assertEquals(expectedComponentFunctionName, publishedLogEntryEvent.ComponentFunctionName__c, publishedLogEntryEvent);
        System.assertEquals(expectedComponentType, publishedLogEntryEvent.ComponentType__c, publishedLogEntryEvent);
        System.assertEquals(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c, publishedLogEntryEvent);
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
