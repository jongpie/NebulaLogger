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
    static void it_should_save_component_log_entry_without_stack_trace() {
        LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
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
        System.Assert.isNull(
            publishedLogEntryEvent.OriginSourceMetadataType__c,
            'Non-null value populated for OriginSourceMetadata__c: ' + System.JSON.serializePretty(publishedLogEntryEvent)
        );
        System.Assert.isNull(publishedLogEntryEvent.StackTrace__c);
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserAddress__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual(componentLogEntry.recordId, publishedLogEntryEvent.RecordId__c);
        System.Assert.areEqual(System.JSON.serializePretty(componentLogEntry.record), publishedLogEntryEvent.RecordJson__c);
        System.Assert.areEqual(Schema.SObjectType.User.getName(), publishedLogEntryEvent.RecordSObjectType__c);
        System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }

    @IsTest
    static void it_should_save_component_log_entry_with_queueable_job() {
        LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerDataStore.setMock(LoggerMockDataStore.getJobQueue());
        System.Assert.areEqual(0, System.Limits.getQueueableJobs(), 'Test should start with 0 queueable jobs used');
        String expectedComponentType = 'Aura';
        String expectedComponentApiName = 'c/loggerAuraDemo';
        String expectedComponentFunctionName = 'saveLogAuraExample';
        String expectedSourceType = 'AuraDefinitionBundle';
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        componentLogEntry.stack = getMockAuraComponentStackTrace(expectedComponentApiName, expectedComponentFunctionName);
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
        System.Assert.areEqual(expectedComponentType, publishedLogEntryEvent.ComponentType__c);
        System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, publishedLogEntryEvent.OriginLocation__c);
        System.Assert.areEqual(expectedSourceType, publishedLogEntryEvent.OriginSourceMetadataType__c);
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserAddress__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual(componentLogEntry.recordId, publishedLogEntryEvent.RecordId__c);
        System.Assert.areEqual(System.JSON.serializePretty(componentLogEntry.record), publishedLogEntryEvent.RecordJson__c);
        System.Assert.areEqual(Schema.SObjectType.User.getName(), publishedLogEntryEvent.RecordSObjectType__c);
        System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }

    @IsTest
    static void it_should_save_component_log_entry_with_aura_component_error() {
        LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String exceptionSourceApiName = 'c/someAuraComponent';
        String exceptionFunctionName = 'someAuraFunction';
        ComponentLogger.ComponentError mockComponentError = new ComponentLogger.ComponentError();
        mockComponentError.message = 'some JavaScript error message';
        mockComponentError.stack = getMockAuraComponentStackTrace(exceptionSourceApiName, exceptionFunctionName);
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
        System.Assert.areEqual(componentLogEntry.error.message, publishedLogEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual(componentLogEntry.error.type, publishedLogEntryEvent.ExceptionType__c);
        LoggerStackTrace exceptionStackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, mockComponentError.stack);
        System.Assert.areEqual(exceptionStackTrace.Location, publishedLogEntryEvent.ExceptionLocation__c);
        System.Assert.areEqual(exceptionStackTrace.Source?.ActionName, publishedLogEntryEvent.ExceptionSourceActionName__c);
        System.Assert.areEqual(exceptionStackTrace.Source?.ApiName, publishedLogEntryEvent.ExceptionSourceApiName__c);
        // Ensure the metadata type is AuraDefinitionBundle since the error originated from an (fake) JavaScript file (not an Apex controller method)
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.AuraDefinitionBundle.name(), publishedLogEntryEvent.ExceptionSourceMetadataType__c);
        System.Assert.areEqual(exceptionStackTrace.Source?.MetadataType.name(), publishedLogEntryEvent.ExceptionSourceMetadataType__c);
        System.Assert.areEqual(exceptionStackTrace.ParsedStackTraceString, publishedLogEntryEvent.ExceptionStackTrace__c);
    }

    @IsTest
    static void it_should_save_component_log_entry_with_web_component_error() {
        LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String exceptionSourceApiName = 'c/someWebComponent';
        String exceptionFunctionName = 'someFunction';
        ComponentLogger.ComponentError mockComponentError = new ComponentLogger.ComponentError();
        mockComponentError.message = 'some JavaScript error message';
        mockComponentError.stack = getMockModernWebComponentStackTrace(exceptionSourceApiName, exceptionFunctionName);
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
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserAddress__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
        System.Assert.areEqual(componentLogEntry.error.message, publishedLogEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual(componentLogEntry.error.type, publishedLogEntryEvent.ExceptionType__c);
        LoggerStackTrace exceptionStackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.JavaScript, mockComponentError.stack);
        System.Assert.areEqual(exceptionStackTrace.Location, publishedLogEntryEvent.ExceptionLocation__c);
        System.Assert.areEqual(exceptionStackTrace.Source?.ActionName, publishedLogEntryEvent.ExceptionSourceActionName__c);
        System.Assert.areEqual(exceptionStackTrace.Source?.ApiName, publishedLogEntryEvent.ExceptionSourceApiName__c);
        // Ensure the metadata type is LightningComponentBundle since the error originated from an (fake) JavaScript file (not an Apex controller method)
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.LightningComponentBundle.name(), publishedLogEntryEvent.ExceptionSourceMetadataType__c);
        System.Assert.areEqual(exceptionStackTrace.Source?.MetadataType.name(), publishedLogEntryEvent.ExceptionSourceMetadataType__c);
        System.Assert.areEqual(exceptionStackTrace.ParsedStackTraceString, publishedLogEntryEvent.ExceptionStackTrace__c);
    }

    @IsTest
    static void it_should_save_component_log_entry_with_apex_controller_error() {
        // Here, the test should NOT ignore the current class ComponentLogger_Tests, since it's
        // generating a mock Apex exception to use for testing stack trace parsing
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
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserAddress__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
        System.Assert.areEqual(componentLogEntry.error.message, publishedLogEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual(componentLogEntry.error.type, publishedLogEntryEvent.ExceptionType__c);
        LoggerStackTrace exceptionStackTrace = new LoggerStackTrace(LoggerStackTrace.SourceLanguage.Apex, mockComponentError.stack);
        System.Assert.areEqual(exceptionStackTrace.Location, publishedLogEntryEvent.ExceptionLocation__c);
        System.Assert.areEqual(exceptionStackTrace.Source?.ActionName, publishedLogEntryEvent.ExceptionSourceActionName__c);
        System.Assert.areEqual(exceptionStackTrace.Source?.ApiName, publishedLogEntryEvent.ExceptionSourceApiName__c);
        // Ensure the metadata type is ApexClass since the error originated from an Apex class (not JavaScript)
        System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.ApexClass.name(), publishedLogEntryEvent.ExceptionSourceMetadataType__c);
        System.Assert.areEqual(exceptionStackTrace.Source?.MetadataType.name(), publishedLogEntryEvent.ExceptionSourceMetadataType__c);
        System.Assert.areEqual(exceptionStackTrace.ParsedStackTraceString, publishedLogEntryEvent.ExceptionStackTrace__c);
    }

    @IsTest
    static void it_should_truncate_long_origin_stack_trace_when_publishing_to_the_event_bus() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String mockComponentApiName = 'c/loggerLWCDemo';
        String mockComponentFunctionName = 'logErrorExample';
        String excessivelyLongString =
            getMockModernWebComponentStackTrace(mockComponentApiName, mockComponentFunctionName) +
            'A'.repeat(Schema.LogEntryEvent__e.StackTrace__c.getDescribe().getLength() + 1);
        System.Assert.isTrue(excessivelyLongString.length() > Schema.LogEntryEvent__e.StackTrace__c.getDescribe().getLength());
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        componentLogEntry.stack = excessivelyLongString;
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(Schema.LogEntryEvent__e.StackTrace__c.getDescribe().getLength(), publishedLogEntryEvent.StackTrace__c.length());
    }

    @IsTest
    static void it_should_truncate_long_exception_stack_trace_when_publishing_to_the_event_bus() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String mockComponentApiName = 'c/loggerLWCDemo';
        String mockComponentFunctionName = 'logErrorExample';
        String excessivelyLongString =
            getMockModernWebComponentStackTrace(mockComponentApiName, mockComponentFunctionName) +
            'A'.repeat(Schema.LogEntryEvent__e.StackTrace__c.getDescribe().getLength() + 1);
        System.Assert.isTrue(excessivelyLongString.length() > Schema.LogEntryEvent__e.StackTrace__c.getDescribe().getLength());
        ComponentLogger.ComponentError mockComponentError = new ComponentLogger.ComponentError();
        mockComponentError.message = 'some JavaScript error message';
        mockComponentError.stack = excessivelyLongString;
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
        System.Assert.areEqual(
            Schema.LogEntryEvent__e.ExceptionStackTrace__c.getDescribe().getLength(),
            publishedLogEntryEvent.ExceptionStackTrace__c.length()
        );
    }

    @IsTest
    static void it_should_truncate_long_browser_fields_when_publishing_to_the_event_bus() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        componentLogEntry.browserAddress = 'A'.repeat(Schema.LogEntryEvent__e.BrowserAddress__c.getDescribe().getLength() + 1);
        componentLogEntry.browserFormFactor = 'B'.repeat(Schema.LogEntryEvent__e.BrowserFormFactor__c.getDescribe().getLength() + 1);
        componentLogEntry.browserLanguage = 'C'.repeat(Schema.LogEntryEvent__e.BrowserLanguage__c.getDescribe().getLength() + 1);
        componentLogEntry.browserScreenResolution = 'D'.repeat(Schema.LogEntryEvent__e.BrowserScreenResolution__c.getDescribe().getLength() + 1);
        componentLogEntry.browserUrl = 'E'.repeat(Schema.LogEntryEvent__e.BrowserUrl__c.getDescribe().getLength() + 1);
        componentLogEntry.browserUserAgent = 'F'.repeat(Schema.LogEntryEvent__e.BrowserUserAgent__c.getDescribe().getLength() + 1);
        componentLogEntry.browserWindowResolution = 'G'.repeat(Schema.LogEntryEvent__e.BrowserWindowResolution__c.getDescribe().getLength() + 1);
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(
            componentLogEntry.browserAddress.left(Schema.LogEntryEvent__e.BrowserAddress__c.getDescribe().getLength()),
            publishedLogEntryEvent.BrowserAddress__c
        );
        System.Assert.areEqual(
            componentLogEntry.browserFormFactor.left(Schema.LogEntryEvent__e.BrowserFormFactor__c.getDescribe().getLength()),
            publishedLogEntryEvent.BrowserFormFactor__c
        );
        System.Assert.areEqual(
            componentLogEntry.browserLanguage.left(Schema.LogEntryEvent__e.BrowserLanguage__c.getDescribe().getLength()),
            publishedLogEntryEvent.BrowserLanguage__c
        );
        System.Assert.areEqual(
            componentLogEntry.browserScreenResolution.left(Schema.LogEntryEvent__e.BrowserScreenResolution__c.getDescribe().getLength()),
            publishedLogEntryEvent.BrowserScreenResolution__c
        );
        System.Assert.areEqual(
            componentLogEntry.browserAddress.left(Schema.LogEntryEvent__e.BrowserUrl__c.getDescribe().getLength()),
            publishedLogEntryEvent.BrowserUrl__c
        );
        System.Assert.areEqual(
            componentLogEntry.browserUserAgent.left(Schema.LogEntryEvent__e.BrowserUserAgent__c.getDescribe().getLength()),
            publishedLogEntryEvent.BrowserUserAgent__c
        );
        System.Assert.areEqual(
            componentLogEntry.browserWindowResolution.left(Schema.LogEntryEvent__e.BrowserWindowResolution__c.getDescribe().getLength()),
            publishedLogEntryEvent.BrowserWindowResolution__c
        );
    }

    @IsTest
    static void it_should_set_logger_scenario() {
        LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
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
        System.Assert.areEqual(componentLogEntry.scenario, publishedLogEntryEvent.TransactionScenario__c);
        System.Assert.areEqual(componentLogEntry.scenario, publishedLogEntryEvent.EntryScenario__c);
    }

    @IsTest
    static void it_should_parse_aura_component_stack_trace() {
        LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String expectedComponentType = 'Aura';
        String expectedComponentApiName = 'c/loggerAuraDemo';
        String expectedComponentFunctionName = 'saveLogAuraExample';
        String expectedSourceType = 'AuraDefinitionBundle';
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        componentLogEntry.stack = getMockAuraComponentStackTrace(expectedComponentApiName, expectedComponentFunctionName);
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserAddress__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, publishedLogEntryEvent.OriginLocation__c);
        System.Assert.areEqual(expectedSourceType, publishedLogEntryEvent.OriginSourceMetadataType__c);
        // TODO Move these asserts to LogEntryHandler_Tests
        // System.Assert.areEqual(expectedComponentApiName, publishedLogEntryEvent.ComponentApiName__c);
        // System.Assert.areEqual(expectedComponentFunctionName, publishedLogEntryEvent.ComponentFunctionName__c);
        System.Assert.areEqual(expectedComponentType, publishedLogEntryEvent.ComponentType__c);
        System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }

    @IsTest
    static void it_should_parse_web_component_stack_trace_when_stack_trace_is_modern_format() {
        LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String expectedComponentType = 'LWC';
        String expectedComponentApiName = 'c/loggerLWCDemo';
        String expectedComponentFunctionName = 'logErrorExample';
        String expectedSourceType = 'LightningComponentBundle';
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        componentLogEntry.stack = getMockModernWebComponentStackTrace(expectedComponentApiName, expectedComponentFunctionName);
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserAddress__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, publishedLogEntryEvent.OriginLocation__c);
        System.Assert.areEqual(expectedSourceType, publishedLogEntryEvent.OriginSourceMetadataType__c);
        // TODO Move these asserts to LogEntryHandler_Tests
        // System.Assert.areEqual(expectedComponentApiName, publishedLogEntryEvent.ComponentApiName__c);
        // System.Assert.areEqual(expectedComponentFunctionName, publishedLogEntryEvent.ComponentFunctionName__c);
        System.Assert.areEqual(expectedComponentType, publishedLogEntryEvent.ComponentType__c);
        System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }

    @IsTest
    static void it_should_parse_web_component_stack_trace_when_stack_trace_is_legacy_format() {
        LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String expectedComponentType = 'LWC';
        String expectedComponentApiName = 'c/loggerLWCDemo';
        String expectedComponentFunctionName = 'saveLogWebExample';
        String expectedSourceType = 'LightningComponentBundle';
        ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
        componentLogEntry.stack = getMockLegacyWebComponentStackTrace(expectedComponentApiName);
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserAddress__c);
        System.Assert.areEqual(componentLogEntry.browserFormFactor, publishedLogEntryEvent.BrowserFormFactor__c);
        System.Assert.areEqual(componentLogEntry.browserLanguage, publishedLogEntryEvent.BrowserLanguage__c);
        System.Assert.areEqual(componentLogEntry.browserScreenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
        System.Assert.areEqual(componentLogEntry.browserAddress, publishedLogEntryEvent.BrowserUrl__c);
        System.Assert.areEqual(componentLogEntry.browserUserAgent, publishedLogEntryEvent.BrowserUserAgent__c);
        System.Assert.areEqual(componentLogEntry.browserWindowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
        System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual(expectedComponentApiName + '.' + expectedComponentFunctionName, publishedLogEntryEvent.OriginLocation__c);
        System.Assert.areEqual(expectedSourceType, publishedLogEntryEvent.OriginSourceMetadataType__c);
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
        componentLogEntry.browserAddress = 'https://flow-ruby-5228.scratch.lightning.force.com/lightning/n/Logger_lwc_demo?c__asdfsdf=asdf';
        componentLogEntry.browserFormFactor = 'Large';
        componentLogEntry.browserLanguage = 'en-US';
        componentLogEntry.browserScreenResolution = '1536 x 824';
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

    private static String getMockAuraComponentStackTrace(String originComponentName, String originFunctionName) {
        // This is a copy of an actual stack trace generated from c/loggerAuraDemo in August 2021
        List<String> auraStackTraceLines = new List<String>{
            'LogEntryBuilder@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            ComponentLogger.LOGGER_COMPONENT_NAME +
            '.js:28:24' +
            'newLogEntry@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            ComponentLogger.LOGGER_COMPONENT_NAME +
            '.js:172:14',
            '_newEntry@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            ComponentLogger.LOGGER_COMPONENT_NAME +
            '.js:349:44',
            'info@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            ComponentLogger.LOGGER_COMPONENT_NAME +
            '.js:253:21',
            'callHook@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:24774:35',
            'createMethodCaller/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:7822:18',
            'InteropComponent.prototype.$setupMethods$/</self[m]@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:45047:24',
            'createFilteredMethod/<.value<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:30260:46',
            originFunctionName +
            '@https://flow-ability-5496.lightning.force.com/lightning/n/components/' +
            originComponentName +
            '.js:16:30',
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
            '\nloggerAuraDemo.js:17:17'
        };
        return String.join(auraStackTraceLines, '\n');
    }

    private static String getMockLegacyWebComponentStackTrace(String originComponentName) {
        // This is a copy of an actual stack trace generated from c/loggerLWCDemo in August 2021
        List<String> lwcStackTraceLines = new List<String>{
            'LogEntryBuilder@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            ComponentLogger.LOGGER_COMPONENT_NAME +
            '.js:28:24',
            'newLogEntry@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            ComponentLogger.LOGGER_COMPONENT_NAME +
            '.js:172:14',
            '_newEntry@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            ComponentLogger.LOGGER_COMPONENT_NAME +
            '.js:349:44',
            'error@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            ComponentLogger.LOGGER_COMPONENT_NAME +
            '.js:233:21',
            'callHook@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:24774:35',
            'createMethodCaller/<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:7822:18',
            'createFilteredMethodStateless/<.value<@https://static.lightning.force.com/cs44/auraFW/javascript/QPQi8lbYE8YujG6og6Dqgw/aura_proddebug.js:30288:47',
            'saveLogWebExample@https://flow-ability-5496.lightning.force.com/lightning/n/modules/' +
            originComponentName +
            '.js:204:30',
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

    private static String getMockModernWebComponentStackTrace(String originComponentName, String originFunctionName) {
        // This is a partial copy of an actual stack trace generated from c/loggerLWCDemo in January 2024
        List<String> lwcStackTraceLines = new List<String>{
            '@modules/' +
            ComponentLogger.LOGGER_COMPONENT_NAME +
            '.js:33:22',
            'LogEntryBuilder@modules/' +
            ComponentLogger.LOGGER_COMPONENT_NAME +
            '.js:59:87',
            'newLogEntry@modules/' +
            ComponentLogger.LOGGER_COMPONENT_NAME +
            '.js:189:14',
            '_newEntry@modules/' +
            ComponentLogger.LOGGER_COMPONENT_NAME +
            '.js:397:44',
            'error@modules/' +
            ComponentLogger.LOGGER_COMPONENT_NAME +
            '.js:264:21',
            originFunctionName +
            '@modules/' +
            originComponentName +
            '.js:266:35',
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
