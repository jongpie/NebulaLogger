//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings(
    'PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount'
)
@IsTest(IsParallel=true)
private class ComponentLogger_Tests {
    @IsTest
    static void it_should_return_logger_settings() {
        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.IsEnabled__c = true;
        loggerSettings.LoggingLevel__c = 'FINEST';
        upsert loggerSettings;

        ComponentLogger.ComponentLoggerSettings componentLoggerSettings = ComponentLogger.getSettings();

        System.Assert.areEqual(loggerSettings.IsEnabled__c, componentLoggerSettings.isEnabled);
        System.Assert.areEqual(loggerSettings.LoggingLevel__c, componentLoggerSettings.userLoggingLevel.name);
        System.LoggingLevel userLoggingLevel = Logger.getLoggingLevel(loggerSettings.LoggingLevel__c);
        System.Assert.areEqual(userLoggingLevel.name(), componentLoggerSettings.userLoggingLevel.name);
        System.Assert.areEqual(userLoggingLevel.ordinal(), componentLoggerSettings.userLoggingLevel.ordinal);
        for (System.LoggingLevel currentLoggingLevel : System.LoggingLevel.values()) {
            // We don't care about logging level NONE, or the secret/undocumented INTERNAL logging level
            if (currentLoggingLevel == System.LoggingLevel.NONE || currentLoggingLevel == System.LoggingLevel.INTERNAL) {
                continue;
            }
            System.Assert.isTrue(
                componentLoggerSettings.supportedLoggingLevels.containsKey(currentLoggingLevel.name()),
                'Cmp settings did not contain level: ' + currentLoggingLevel
            );
            Integer returnedOrdinal = componentLoggerSettings.supportedLoggingLevels.get(currentLoggingLevel.name());
            System.Assert.areEqual(currentLoggingLevel.ordinal(), returnedOrdinal);
        }
    }

    @IsTest
    static void it_should_return_aura_exception_when_it_breaks() {
        try {
            ComponentLogger.saveComponentLogEntries(null, null);
            System.Assert.fail('This assert shouldn\'t run since this is a negative test');
        } catch (System.Exception apexException) {
            System.Assert.isInstanceOfType(apexException, System.AuraHandledException.class);
        }
    }

    @IsTest
    static void it_should_save_component_log_entry() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual('Component', publishedLogEntryEvent.OriginType__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserUrl, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual(componentLogEntry.recordId, publishedLogEntryEvent.RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(componentLogEntry.record), publishedLogEntryEvent.RecordJson__c);
        System.Assert.areEqual(Schema.SObjectType.User.getName(), publishedLogEntryEvent.RecordSObjectType__c);
        System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }

    @IsTest
    static void it_should_save_component_log_entry_with_queueable_job() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerDataStore.setMock(LoggerMockDataStore.getJobQueue());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs(), 'Test should start with 0 queueable jobs used');
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        System.Test.startTest();
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        System.Assert.areEqual(0, LoggerMockDataStore.getJobQueue().getEnqueuedJobs().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, Logger.SaveMethod.QUEUEABLE.name());
        System.Assert.areEqual(1, LoggerMockDataStore.getJobQueue().getEnqueuedJobs().size());
        LoggerMockDataStore.getJobQueue().executeJobs();

        System.Assert.areEqual(Logger.SaveMethod.QUEUEABLE.name(), Logger.lastSaveMethodNameUsed);
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual('Component', publishedLogEntryEvent.OriginType__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserUrl, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual(componentLogEntry.recordId, publishedLogEntryEvent.RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(componentLogEntry.record), publishedLogEntryEvent.RecordJson__c);
        System.Assert.areEqual(Schema.SObjectType.User.getName(), publishedLogEntryEvent.RecordSObjectType__c);
        System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }

    @IsTest
    static void it_should_save_component_log_entry_with_javascript_error() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        ComponentLogger.ComponentError mockComponentError = new ComponentLogger.ComponentError();
        mockComponentError.message = 'some JavaScript error message';
        mockComponentError.stack = 'some \nstack \ntrace \nstring';
        mockComponentError.type = 'JavaScript.ReferenceError';
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        componentLogEntry.error = mockComponentError;
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual('Component', publishedLogEntryEvent.OriginType__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserUrl, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
        System.Assert.areEqual(componentLogEntry.error.message, publishedLogEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual(componentLogEntry.error.stack, publishedLogEntryEvent.ExceptionStackTrace__c);
        System.Assert.areEqual(componentLogEntry.error.type, publishedLogEntryEvent.ExceptionType__c);
    }

    @IsTest
    static void it_should_save_component_log_entry_with_apex_controller_error() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.Exception mockApexException = new System.DmlException(
            'It is with much sadness that I must inform you that this DML statement was most unsuccessful'
        );
        ComponentLogger.ComponentError mockComponentError = new ComponentLogger.ComponentError();
        mockComponentError.message = mockApexException.getMessage();
        mockComponentError.stack = mockApexException.getStackTraceString();
        mockComponentError.type = mockApexException.getTypeName();
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        componentLogEntry.error = mockComponentError;
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual('Component', publishedLogEntryEvent.OriginType__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserUrl, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
        System.Assert.areEqual(componentLogEntry.error.message, publishedLogEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual(componentLogEntry.error.stack, publishedLogEntryEvent.ExceptionStackTrace__c);
        System.Assert.areEqual(componentLogEntry.error.type, publishedLogEntryEvent.ExceptionType__c);
    }

    @IsTest
    static void it_should_set_logger_scenario() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.FINEST.name();
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        componentLogEntry.scenario = 'Some scenario';
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual('Component', publishedLogEntryEvent.OriginType__c);
        System.Assert.areEqual(componentLogEntry.scenario, publishedLogEntryEvent.TransactionScenario__c);
        System.Assert.areEqual(componentLogEntry.scenario, publishedLogEntryEvent.EntryScenario__c);
    }

    @IsTest
    static void it_should_parse_aura_component_stack_trace() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String expectedComponentType = 'Aura';
        String expectedComponentApiName = 'c/loggerAuraDemo';
        String expectedComponentFunctionName = 'saveLogAuraExample';
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        componentLogEntry.stack = getMockAuraComponentStackTrace();
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual('Component', publishedLogEntryEvent.OriginType__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserUrl, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual('Component', publishedLogEntryEvent.OriginType__c);
        System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, publishedLogEntryEvent.OriginLocation__c);
        // TODO Move these asserts to LogEntryHandler_Tests
        // System.Assert.areEqual(expectedComponentApiName, publishedLogEntryEvent.ComponentApiName__c);
        // System.Assert.areEqual(expectedComponentFunctionName, publishedLogEntryEvent.ComponentFunctionName__c);
        System.Assert.areEqual(expectedComponentType, publishedLogEntryEvent.ComponentType__c);
        System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }

    @IsTest
    static void it_should_parse_web_component_stack_trace_when_stack_trace_is_modern_format() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String expectedComponentType = 'LWC';
        String expectedComponentApiName = 'c/loggerLWCDemo';
        String expectedComponentFunctionName = 'logErrorExample';
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        componentLogEntry.stack = getMockModernWebComponentStackTrace();
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual('Component', publishedLogEntryEvent.OriginType__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserUrl, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual('Component', publishedLogEntryEvent.OriginType__c);
        System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, publishedLogEntryEvent.OriginLocation__c);
        // TODO Move these asserts to LogEntryHandler_Tests
        // System.Assert.areEqual(expectedComponentApiName, publishedLogEntryEvent.ComponentApiName__c);
        // System.Assert.areEqual(expectedComponentFunctionName, publishedLogEntryEvent.ComponentFunctionName__c);
        System.Assert.areEqual(expectedComponentType, publishedLogEntryEvent.ComponentType__c);
        System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }

    @IsTest
    static void it_should_parse_web_component_stack_trace_when_stack_trace_is_legacy_format() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String expectedComponentType = 'LWC';
        String expectedComponentApiName = 'c/loggerLWCDemo';
        String expectedComponentFunctionName = 'saveLogWebExample';
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        componentLogEntry.stack = getMockLegacyWebComponentStackTrace();
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual('Component', publishedLogEntryEvent.OriginType__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserUrl, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual('Component', publishedLogEntryEvent.OriginType__c);
        System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, publishedLogEntryEvent.OriginLocation__c);
        // TODO Move these asserts to LogEntryHandler_Tests
        // System.Assert.areEqual(expectedComponentApiName, publishedLogEntryEvent.ComponentApiName__c);
        // System.Assert.areEqual(expectedComponentFunctionName, publishedLogEntryEvent.ComponentFunctionName__c);
        System.Assert.areEqual(expectedComponentType, publishedLogEntryEvent.ComponentType__c);
        System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }

    private static ComponentLogger.ComponentLogEntry createMockComponentLogEntry() {
        Schema.User currentUser = new Schema.User(
            FirstName = System.UserInfo.getFirstName(),
            Id = System.UserInfo.getUserId(),
            ProfileId = System.UserInfo.getProfileId()
        );
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.browserFormFactor = 'Large';
        componentLogEntry.browserLanguage = 'en-US';
        componentLogEntry.browserScreenResolution = '1536 x 824';
        componentLogEntry.browserUrl = 'https://flow-ruby-5228.scratch.lightning.force.com/lightning/n/Logger_lwc_demo?c__asdfsdf=asdf';
        componentLogEntry.browserUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/113.0';
        componentLogEntry.browserWindowResolution = '1536 x 474';
        componentLogEntry.loggingLevel = System.LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.recordId = currentUser.Id;
        componentLogEntry.record = currentUser;
        componentLogEntry.timestamp = System.now().addDays(-1 / 24);
        componentLogEntry.tags = new List<String>{ 'some tag', 'one more tag' };
        return componentLogEntry;
    }

    private static String getMockAuraComponentStackTrace() {
        // This is a copy of an actual stack trace generated from c/loggerAuraDemo in August 2021
        String componentNamespace = String.isNotBlank(Logger.getNamespacePrefix()) ? Logger.getNamespacePrefix() : 'c';
        String qualifiedLoggerComponentName = componentNamespace + '/logger.js';
        List<String> auraStackTraceLines = new List<String>{
            'LogEntryBuilder@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            qualifiedLoggerComponentName +
            ':28:24' +
            'newLogEntry@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            qualifiedLoggerComponentName +
            ':172:14',
            '_newEntry@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            qualifiedLoggerComponentName +
            ':349:44',
            'info@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            qualifiedLoggerComponentName +
            ':253:21',
            'callHook@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:24774:35',
            'createMethodCaller/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:7822:18',
            'InteropComponent.prototype.$setupMethods$/</self[m]@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:45047:24',
            'createFilteredMethod/<.value<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:30260:46',
            'saveLogAuraExample@https://flow-ability-5496.lightning.force.com/lightning/n/components/c/loggerAuraDemo.js:16:30',
            'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47648:36',
            'Action.prototype.$run$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47635:8',
            'handleClick@https://flow-ability-5496.lightning.force.com/components/lightning/button.js:23:20',
            'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47648:36',
            '$dispatchAction$/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:44173:12',
            'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:59193:12',
            '$dispatchAction$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:44172:6',
            'DomHandlersPlugin.prototype.$instrumentCallback$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:61246:23',
            'Aura.$Utils$.$Override$.prototype.$continuation$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:39996:20',
            'bound@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:39933:29',
            '$domEventHandler$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:44168:12',
            'callbackWrapper@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:59040:23',
            'wrapperFn@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:505:29',
            'EventListener.handleEvent*patchedAddEventListener$1@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:3249:31',
            'Aura.$Utils$.$Util$.prototype.$on$</<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:38804:17',
            '$addNamedClickHandler$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:44144:14',
            '$createHtmlAttribute$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:44187:12',
            'render@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:44056:14',
            'Component.prototype.$render$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42890:26',
            'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54033:34',
            'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54337:29',
            'render@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:43718:45',
            'Component.prototype.$render$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42890:26',
            'Component.prototype.$superRender$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42420:34',
            'Component.prototype.$render$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42899:17',
            'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54033:34',
            'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54337:29',
            'render@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:44063:27',
            'Component.prototype.$render$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42890:26',
            'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54033:34',
            'AuraRenderingService.prototype.$renderFacet$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54337:29',
            'render@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:43718:45',
            'Component.prototype.$render$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42890:26',
            'Component.prototype.$superRender$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42420:34',
            'Component.prototype.$render$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42899:17',
            'AuraRenderingService.prototype.$render$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54033:34',
            'AuraRenderingService.prototype.$rerenderFacet$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54421:33',
            'rerender@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:43898:33',
            'Component.prototype.$rerender$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42929:28',
            'AuraRenderingService.prototype.$rerender$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54084:34',
            'AuraRenderingService.prototype.$rerenderFacet$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54441:35',
            'rerender@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:43722:32',
            'Component.prototype.$rerender$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42929:28',
            'Component.prototype.$superRerender$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42432:34',
            'Component.prototype.$rerender$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42938:17',
            'AuraRenderingService.prototype.$rerender$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54084:34',
            'AuraRenderingService.prototype.$rerenderDirty$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:54668:14',
            'AuraClientService.prototype.$finishProcessing$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:51244:27',
            'AuraClientService.prototype.$finishCollection$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:51089:10',
            'AuraClientService.prototype.$runClientActions$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:51049:8',
            'AuraClientService.prototype.$continueProcessing$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:50818:10',
            'AuraClientService.prototype.$process$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:50778:8',
            'AuraClientService.prototype.$postProcess$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:50765:12',
            'AuraClientService.prototype.$popStack$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:50759:10',
            'callbackWrapper@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:59075:28',
            'retrievePendingSuccess@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:41384:32',
            'promise callback*ComponentDefLoader.prototype.$retrievePending$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:41380:34',
            'retrievePendingWrapper@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:41520:28',
            'setTimeout handler*ComponentDefLoader.prototype.$schedulePending$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:41519:10',
            'ComponentDefLoader.prototype.$loadComponentDef$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:41529:10',
            'AuraComponentService.prototype.$createComponentPrivAsync$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:53680:31',
            'AuraComponentService.prototype.$createComponent$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:52719:8',
            'createComponent@https://flow-ability-5496.lightning.force.com/auraCmpDef?_au=5iLE974seQA7PgrxViMHSw&_c=false&_density=VIEW_ONE&_ff=DESKTOP&_l=true&_l10n=en_US&_lrmc=533941497&_style=735439548&aura.app=markup://one:one&aura.mode=PRODDEBUG&_def=markup://one:auraContainer&_uid=LATEST-8:110:12',
            'init@https://flow-ability-5496.lightning.force.com/auraCmpDef?_au=5iLE974seQA7PgrxViMHSw&_c=false&_density=VIEW_ONE&_ff=DESKTOP&_l=true&_l10n=en_US&_lrmc=533941497&_style=735439548&aura.app=markup://one:one&aura.mode=PRODDEBUG&_def=markup://one:auraContainer&_uid=LATEST-8:14:16',
            'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47648:36',
            'Component$getActionCaller@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:43377:20',
            'Aura.$Event$.$Event$.prototype.$executeHandlerIterator$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47102:17',
            'Aura.$Event$.$Event$.prototype.$executeHandlers$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47076:8',
            'Aura.$Event$.$Event$.prototype.$fire$/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47135:10',
            'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:59193:12',
            'Aura.$Event$.$Event$.prototype.$fire$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47133:6',
            'Component.prototype.$fire$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42793:11',
            'Component@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:41911:12',
            'componentConstructor@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:41101:10',
            'AuraComponentService.prototype.$createComponentPriv$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:53744:13',
            'AuraComponentService.prototype.$createComponentPrivAsync$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:53670:12',
            'AuraComponentService.prototype.$createComponent$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:52719:8',
            'createComponentWithStateOverrides@https://flow-ability-5496.lightning.force.com/libraries/force/componentLibrary.components.js:5:8',
            'lib/components.createPanel@https://flow-ability-5496.lightning.force.com/libraries/force/componentLibrary.components.js:31:38',
            'loadContent@https://flow-ability-5496.lightning.force.com/components/laf/pageHost.js:653:42',
            'createContent/<@https://flow-ability-5496.lightning.force.com/components/laf/pageHost.js:571:22',
            'callbackWrapper@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:59040:23',
            'promise callback*createContent@https://flow-ability-5496.lightning.force.com/components/laf/pageHost.js:556:48',
            'changePage@https://flow-ability-5496.lightning.force.com/components/laf/pageHost.js:308:26',
            'onPageChange@https://flow-ability-5496.lightning.force.com/components/laf/pageHost.js:33:16',
            'Action.prototype.$runDeprecated$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47648:36',
            'Component$getActionCaller@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:43377:20',
            'Aura.$Event$.$Event$.prototype.$executeHandlerIterator$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47102:17',
            'Aura.$Event$.$Event$.prototype.$executeHandlers$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47076:8',
            'Aura.$Event$.$Event$.prototype.$fire$/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47135:10',
            'AuraInstance.prototype.$run$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:59193:12',
            'Aura.$Event$.$Event$.prototype.$fire$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:47133:6',
            'Component.prototype.$fireChangeEvent$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42677:19',
            'Component.prototype.set@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:42632:12',
            'createWorkspaceWrapper/<@https://flow-ability-5496.lightning.force.com/components/navex/workspace.js:1219:30',
            'callbackWrapper@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:59040:23',
            'AuraComponentService.prototype.$createComponentPriv$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:53765:17',
            'AuraComponentService.prototype.$createComponentPrivAsync$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:53670:12',
            'AuraComponentService.prototype.$createComponent$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:52719:8',
            'createWorkspaceWrapper@https://flow-ability-5496.lightning.force.com/components/navex/workspace.js:1202:12',
            'wrapTab/</</<@https://flow-ability-5496.lightning.force.com/components/navex/workspace.js:1186:32',
            'AuraComponentService.prototype.$createComponentPriv$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:53765:17',
            'AuraComponentService.prototype.$createComponentPrivAsync$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:53670:12',
            'AuraComponentService.prototype.$createComponent$@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:52719:8',
            'wrapTab/</<@https://flow-ability-5496.lightning.force.com/components/navex/workspace.js:1177:20',
            'callbackWrapper@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:59040:23',
            'promise callback*wrapTab/<@https://flow-ability-5496.lightning.force.com/components/navex/workspace.js:1176:81',
            'callbackWrapper@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:59040:23',
            'promise@https://flow-ability-5496.lightning.force.com/components/navex/workspace.js:1971:16',
            'wrapTab@https://flow-ability-5496.lightning.force.com/components/navex/workspace.js:1123:23',
            '\nloggerAuraDemo.js:17:17'
        };
        return String.join(auraStackTraceLines, '\n');
    }

    private static String getMockLegacyWebComponentStackTrace() {
        // This is a copy of an actual stack trace generated from c/loggerLWCDemo in August 2021
        String componentNamespace = String.isNotBlank(Logger.getNamespacePrefix()) ? Logger.getNamespacePrefix() : 'c';
        String qualifiedLoggerComponentName = componentNamespace + '/logger.js';
        List<String> lwcStackTraceLines = new List<String>{
            'LogEntryBuilder@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            qualifiedLoggerComponentName +
            ':28:24',
            'newLogEntry@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            qualifiedLoggerComponentName +
            ':172:14',
            '_newEntry@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            qualifiedLoggerComponentName +
            ':349:44',
            'error@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            qualifiedLoggerComponentName +
            ':233:21',
            'callHook@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:24774:35',
            'createMethodCaller/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:7822:18',
            'createFilteredMethodStateless/<.value<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:30288:47',
            'saveLogWebExample@https://flow-ability-5496.lightning.force.com/lightning/n/modules/c/loggerLWCDemo.js:204:30',
            'callHook@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:24774:35',
            'invokeEventListener/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:9992:19',
            'runWithBoundaryProtection@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:10696:7',
            'invokeEventListener@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:9987:32',
            'b/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:9352:30',
            'customElementWrappedListener@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:575:28',
            'invokeListenersByPlacement/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:617:32',
            'invokeListenersByPlacement@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:612:19',
            'domListener@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:627:37'
        };
        return String.join(lwcStackTraceLines, '\n');
    }

    private static String getMockModernWebComponentStackTrace() {
        // This is a partial copy of an actual stack trace generated from c/loggerLWCDemo in January 2024
        String componentNamespace = String.isNotBlank(Logger.getNamespacePrefix()) ? Logger.getNamespacePrefix() : 'c';
        String qualifiedLoggerComponentName = componentNamespace + '/logger.js';
        List<String> lwcStackTraceLines = new List<String>{
            '@modules/' +
            qualifiedLoggerComponentName +
            ':33:22',
            'LogEntryBuilder@modules/' +
            qualifiedLoggerComponentName +
            ':59:87',
            'newLogEntry@modules/' +
            qualifiedLoggerComponentName +
            ':189:14',
            '_newEntry@modules/' +
            qualifiedLoggerComponentName +
            ':397:44',
            'error@modules/' +
            qualifiedLoggerComponentName +
            ':264:21',
            'logErrorExample@modules/c/loggerLWCDemo.js:266:35',
            'createHooksCallback$LWS/<@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js line 35465 > eval:2583:24',
            'applyOrConstructTrapForTwoOrMoreArgs$LWS@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:32254:38',
            'callHook@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:10035:19',
            'invokeEventListener/<@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:9926:21',
            'runWithBoundaryProtection@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:10517:13',
            'invokeEventListener@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:9921:34',
            'b/<@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:9365:32',
            'handleEvent@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:1615:51',
            'invokeListenersByPlacement/<@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:1660:46',
            'invokeListenersByPlacement@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:1655:21',
            'domListener@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:1670:39',
            'EventListener.handleEvent*attachDOMListener@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:1687:30',
            'addCustomElementEventListener@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:1712:30',
            'patchedAddEventListener@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:3022:50',
            'value@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:5567:53',
            'addEventListener@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:11554:20',
            'applyEventListeners@https://static.lightning.force.com/cs220/auraFW/javascript/YWYyQV90T3g3VDhySzNWUm1kcF9WUVY4bi1LdGdMbklVbHlMdER1eVVlUGcyNDYuMTUuNS0zLjAuNA/aura_proddebug.js:8200:29',
            '...blah,blah,blah more javascript code goes here, etc.'
        };
        return String.join(lwcStackTraceLines, '\n');
    }
}
