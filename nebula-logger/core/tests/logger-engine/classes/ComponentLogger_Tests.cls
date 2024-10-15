//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings(
  'PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount'
)
@IsTest(IsParallel=true)
private class ComponentLogger_Tests {
  static {
    // Don't use the org's actual custom metadata records when running tests
    LoggerConfigurationDataSelector.useMocks();
  }

  @IsTest
  static void it_should_return_logger_settings() {
    LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
    loggerSettings.IsEnabled__c = !((Boolean) LoggerSettings__c.IsEnabled__c.getDescribe().getDefaultValue());
    loggerSettings.IsJavaScriptConsoleLoggingEnabled__c = !((Boolean) LoggerSettings__c.IsJavaScriptConsoleLoggingEnabled__c.getDescribe().getDefaultValue());
    loggerSettings.IsJavaScriptLightningLoggerEnabled__c = !((Boolean) LoggerSettings__c.IsJavaScriptLightningLoggerEnabled__c.getDescribe().getDefaultValue());
    loggerSettings.LoggingLevel__c = 'FINE';
    upsert loggerSettings;

    ComponentLogger.ComponentLoggerSettings componentLoggerSettings = ComponentLogger.getSettings();

    System.Assert.areEqual(loggerSettings.IsEnabled__c, componentLoggerSettings.isEnabled);
    System.Assert.areEqual(loggerSettings.IsJavaScriptConsoleLoggingEnabled__c, componentLoggerSettings.isConsoleLoggingEnabled);
    System.Assert.areEqual(loggerSettings.IsJavaScriptLightningLoggerEnabled__c, componentLoggerSettings.isLightningLoggerEnabled);
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
    componentLogEntry.originStackTrace = null;
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
    System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
    System.Assert.areEqual(componentLogEntry.recordId, publishedLogEntryEvent.RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(componentLogEntry.record), publishedLogEntryEvent.RecordJson__c);
    System.Assert.areEqual(Schema.SObjectType.User.getName(), publishedLogEntryEvent.RecordSObjectType__c);
    System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
  }

  @IsTest
  static void it_should_save_component_log_entry_with_browser_context() {
    LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
    System.Assert.isNotNull(componentLogEntry.browser, 'Test assumes the browser context has been populated');
    System.Assert.isNotNull(componentLogEntry.browser.address, 'Test assumes the browser context has been populated');

    ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

    LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
    System.Assert.areEqual(componentLogEntry.browser.address, publishedLogEntryEvent.BrowserAddress__c);
    System.Assert.areEqual(componentLogEntry.browser.formFactor, publishedLogEntryEvent.BrowserFormFactor__c);
    System.Assert.areEqual(componentLogEntry.browser.language, publishedLogEntryEvent.BrowserLanguage__c);
    System.Assert.areEqual(componentLogEntry.browser.screenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
    System.Assert.areEqual(componentLogEntry.browser.address, publishedLogEntryEvent.BrowserUrl__c);
    System.Assert.areEqual(componentLogEntry.browser.userAgent, publishedLogEntryEvent.BrowserUserAgent__c);
    System.Assert.areEqual(componentLogEntry.browser.windowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
  }

  @IsTest
  static void it_should_save_component_log_entry_without_browser_context() {
    LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
    componentLogEntry.browser = null;

    ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

    LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
    System.Assert.isNull(publishedLogEntryEvent.BrowserAddress__c);
    System.Assert.isNull(publishedLogEntryEvent.BrowserFormFactor__c);
    System.Assert.isNull(publishedLogEntryEvent.BrowserLanguage__c);
    System.Assert.isNull(publishedLogEntryEvent.BrowserScreenResolution__c);
    System.Assert.isNull(publishedLogEntryEvent.BrowserUrl__c);
    System.Assert.isNull(publishedLogEntryEvent.BrowserUserAgent__c);
    System.Assert.isNull(publishedLogEntryEvent.BrowserWindowResolution__c);
  }

  @IsTest
  static void it_should_save_component_log_entry_with_valid_custom_fields() {
    LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
    // Realistically, people shouldn't/wouldn't set fields like HttpRequestBody__c or HttpRequestMethod__c...
    // But to avoid adding an extra field just for test purposes, we'll use some existing fields
    componentLogEntry.fieldToValue = new Map<String, Object>{
      Schema.LogEntryEvent__e.HttpRequestBody__c.toString() => 'some value',
      Schema.LogEntryEvent__e.HttpRequestMethod__c.toString() => 'another value'
    };
    System.Assert.areEqual(0, Logger.saveLogCallCount);
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

    ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

    LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
    System.Assert.areEqual('some value', publishedLogEntryEvent.HttpRequestBody__c);
    System.Assert.areEqual('another value', publishedLogEntryEvent.HttpRequestMethod__c);
  }

  @IsTest
  static void it_should_save_component_log_entry_with_invalid_custom_fields() {
    LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
    componentLogEntry.fieldToValue = new Map<String, Object>{ 'Some Fake Field That Definitely Will Never Exist' => 'some value' };
    System.Assert.areEqual(0, Logger.saveLogCallCount);
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

    ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

    LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
    System.Assert.isNotNull(publishedLogEntryEvent);
  }

  @IsTest
  static void it_should_save_component_log_entry_without_custom_fields() {
    LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
    componentLogEntry.fieldToValue = null;
    System.Assert.areEqual(0, Logger.saveLogCallCount);
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

    ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

    LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
    System.Assert.isNotNull(publishedLogEntryEvent);
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
    componentLogEntry.originStackTrace = createMockComponentStackTrace(
      LoggerStackTrace.SourceMetadataType.AuraDefinitionBundle,
      expectedComponentApiName,
      expectedComponentFunctionName
    );
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
    System.Assert.areEqual(componentLogEntry.browser.address, publishedLogEntryEvent.BrowserAddress__c);
    System.Assert.areEqual(componentLogEntry.browser.formFactor, publishedLogEntryEvent.BrowserFormFactor__c);
    System.Assert.areEqual(componentLogEntry.browser.language, publishedLogEntryEvent.BrowserLanguage__c);
    System.Assert.areEqual(componentLogEntry.browser.screenResolution, publishedLogEntryEvent.BrowserScreenResolution__c);
    System.Assert.areEqual(componentLogEntry.browser.address, publishedLogEntryEvent.BrowserUrl__c);
    System.Assert.areEqual(componentLogEntry.browser.userAgent, publishedLogEntryEvent.BrowserUserAgent__c);
    System.Assert.areEqual(componentLogEntry.browser.windowResolution, publishedLogEntryEvent.BrowserWindowResolution__c);
    System.Assert.areEqual(componentLogEntry.loggingLevel, publishedLogEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(componentLogEntry.message, publishedLogEntryEvent.Message__c);
    System.Assert.areEqual(componentLogEntry.recordId, publishedLogEntryEvent.RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(componentLogEntry.record), publishedLogEntryEvent.RecordJson__c);
    System.Assert.areEqual(Schema.SObjectType.User.getName(), publishedLogEntryEvent.RecordSObjectType__c);
    System.Assert.areEqual(componentLogEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
  }

  @IsTest
  static void it_should_save_component_log_entry_with_component_error() {
    LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    String exceptionSourceApiName = 'c/someAuraComponent';
    String exceptionFunctionName = 'someAuraFunction';
    ComponentLogger.ComponentError mockComponentError = new ComponentLogger.ComponentError();
    mockComponentError.message = 'some JavaScript error message';
    mockComponentError.type = 'JavaScript.ReferenceError';
    ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
    componentLogEntry.error = mockComponentError;
    componentLogEntry.error.stackTrace = createMockComponentStackTrace(
      LoggerStackTrace.SourceMetadataType.AuraDefinitionBundle,
      exceptionSourceApiName,
      exceptionFunctionName
    );
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
    System.Assert.areEqual(
      componentLogEntry.error.stackTrace.componentName + '.' + componentLogEntry.error.stackTrace.functionName,
      publishedLogEntryEvent.ExceptionLocation__c
    );
    System.Assert.areEqual(componentLogEntry.error.stackTrace.functionName, publishedLogEntryEvent.ExceptionSourceActionName__c);
    System.Assert.areEqual(componentLogEntry.error.stackTrace.componentName, publishedLogEntryEvent.ExceptionSourceApiName__c);
    // Ensure the metadata type is AuraDefinitionBundle since the error originated from an (fake) JavaScript file (not an Apex controller method)
    System.Assert.areEqual(LoggerStackTrace.SourceMetadataType.AuraDefinitionBundle.name(), publishedLogEntryEvent.ExceptionSourceMetadataType__c);
    System.Assert.areEqual(componentLogEntry.error.stackTrace.parsedStackTraceString, publishedLogEntryEvent.ExceptionStackTrace__c);
  }

  @IsTest
  static void it_should_truncate_long_origin_stack_trace_fields_when_publishing_to_the_event_bus() {
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
    componentLogEntry.originStackTrace.componentName = 'A'.repeat(Schema.LogEntryEvent__e.OriginSourceApiName__c.getDescribe().getLength());
    componentLogEntry.originStackTrace.functionName = 'B'.repeat(Schema.LogEntryEvent__e.OriginSourceActionName__c.getDescribe().getLength());
    componentLogEntry.originStackTrace.metadataType = 'C'.repeat(Schema.LogEntryEvent__e.OriginSourceMetadataType__c.getDescribe().getLength());
    componentLogEntry.originStackTrace.parsedStackTraceString = 'D'.repeat(Schema.LogEntryEvent__e.StackTrace__c.getDescribe().getLength());
    System.Assert.areEqual(0, Logger.saveLogCallCount);
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

    ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

    System.Assert.areEqual(1, Logger.saveLogCallCount);
    System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
    LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
    System.Assert.areEqual(
      componentLogEntry.originStackTrace.componentName.left(Schema.LogEntryEvent__e.OriginSourceApiName__c.getDescribe().getLength()),
      publishedLogEntryEvent.OriginSourceApiName__c
    );
    System.Assert.areEqual(
      (componentLogEntry.originStackTrace.componentName +
        '.' +
        componentLogEntry.originStackTrace.functionName)
        .left(Schema.LogEntryEvent__e.OriginSourceApiName__c.getDescribe().getLength()),
      publishedLogEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual(
      componentLogEntry.originStackTrace.functionName.left(Schema.LogEntryEvent__e.OriginSourceActionName__c.getDescribe().getLength()),
      publishedLogEntryEvent.OriginSourceActionName__c
    );
    System.Assert.areEqual(
      componentLogEntry.originStackTrace.metadataType.left(Schema.LogEntryEvent__e.OriginSourceMetadataType__c.getDescribe().getLength()),
      publishedLogEntryEvent.OriginSourceMetadataType__c
    );
    System.Assert.areEqual(
      componentLogEntry.originStackTrace.parsedStackTraceString.left(Schema.LogEntryEvent__e.StackTrace__c.getDescribe().getLength()),
      publishedLogEntryEvent.StackTrace__c
    );
  }

  @IsTest
  static void it_should_truncate_long_exception_stack_trace_when_publishing_to_the_event_bus() {
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    String excessivelyLongString = 'A'.repeat(Schema.LogEntryEvent__e.StackTrace__c.getDescribe().getLength() + 1);
    System.Assert.isTrue(excessivelyLongString.length() > Schema.LogEntryEvent__e.StackTrace__c.getDescribe().getLength());
    ComponentLogger.ComponentError mockComponentError = new ComponentLogger.ComponentError();
    mockComponentError.message = 'some JavaScript error message';
    mockComponentError.stackTrace = createMockComponentStackTrace();
    mockComponentError.stackTrace.parsedStackTraceString = excessivelyLongString;
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
      componentLogEntry.error.stackTrace.componentName.left(Schema.LogEntryEvent__e.ExceptionSourceApiName__c.getDescribe().getLength()),
      publishedLogEntryEvent.ExceptionSourceApiName__c
    );
    System.Assert.areEqual(
      (componentLogEntry.error.stackTrace.componentName +
        '.' +
        componentLogEntry.error.stackTrace.functionName)
        .left(Schema.LogEntryEvent__e.ExceptionSourceApiName__c.getDescribe().getLength()),
      publishedLogEntryEvent.ExceptionLocation__c
    );
    System.Assert.areEqual(
      componentLogEntry.error.stackTrace.functionName.left(Schema.LogEntryEvent__e.ExceptionSourceActionName__c.getDescribe().getLength()),
      publishedLogEntryEvent.ExceptionSourceActionName__c
    );
    System.Assert.areEqual(
      componentLogEntry.error.stackTrace.metadataType.left(Schema.LogEntryEvent__e.ExceptionSourceMetadataType__c.getDescribe().getLength()),
      publishedLogEntryEvent.ExceptionSourceMetadataType__c
    );
    System.Assert.areEqual(
      componentLogEntry.error.stackTrace.parsedStackTraceString.left(Schema.LogEntryEvent__e.ExceptionStackTrace__c.getDescribe().getLength()),
      publishedLogEntryEvent.ExceptionStackTrace__c
    );
  }

  @IsTest
  static void it_should_truncate_long_browser_fields_when_publishing_to_the_event_bus() {
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
    componentLogEntry.browser.address = 'A'.repeat(Schema.LogEntryEvent__e.BrowserAddress__c.getDescribe().getLength() + 1);
    componentLogEntry.browser.formFactor = 'B'.repeat(Schema.LogEntryEvent__e.BrowserFormFactor__c.getDescribe().getLength() + 1);
    componentLogEntry.browser.language = 'C'.repeat(Schema.LogEntryEvent__e.BrowserLanguage__c.getDescribe().getLength() + 1);
    componentLogEntry.browser.screenResolution = 'D'.repeat(Schema.LogEntryEvent__e.BrowserScreenResolution__c.getDescribe().getLength() + 1);
    componentLogEntry.browser.userAgent = 'E'.repeat(Schema.LogEntryEvent__e.BrowserUserAgent__c.getDescribe().getLength() + 1);
    componentLogEntry.browser.windowResolution = 'F'.repeat(Schema.LogEntryEvent__e.BrowserWindowResolution__c.getDescribe().getLength() + 1);
    System.Assert.areEqual(0, Logger.saveLogCallCount);
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

    ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

    System.Assert.areEqual(1, Logger.saveLogCallCount);
    System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
    LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
    System.Assert.areEqual(
      componentLogEntry.browser.address.left(Schema.LogEntryEvent__e.BrowserAddress__c.getDescribe().getLength()),
      publishedLogEntryEvent.BrowserAddress__c
    );
    System.Assert.areEqual(
      componentLogEntry.browser.formFactor.left(Schema.LogEntryEvent__e.BrowserFormFactor__c.getDescribe().getLength()),
      publishedLogEntryEvent.BrowserFormFactor__c
    );
    System.Assert.areEqual(
      componentLogEntry.browser.language.left(Schema.LogEntryEvent__e.BrowserLanguage__c.getDescribe().getLength()),
      publishedLogEntryEvent.BrowserLanguage__c
    );
    System.Assert.areEqual(
      componentLogEntry.browser.screenResolution.left(Schema.LogEntryEvent__e.BrowserScreenResolution__c.getDescribe().getLength()),
      publishedLogEntryEvent.BrowserScreenResolution__c
    );
    System.Assert.areEqual(
      componentLogEntry.browser.address.left(Schema.LogEntryEvent__e.BrowserUrl__c.getDescribe().getLength()),
      publishedLogEntryEvent.BrowserUrl__c
    );
    System.Assert.areEqual(
      componentLogEntry.browser.userAgent.left(Schema.LogEntryEvent__e.BrowserUserAgent__c.getDescribe().getLength()),
      publishedLogEntryEvent.BrowserUserAgent__c
    );
    System.Assert.areEqual(
      componentLogEntry.browser.windowResolution.left(Schema.LogEntryEvent__e.BrowserWindowResolution__c.getDescribe().getLength()),
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
  static void it_should_set_aura_javascript_origin_stack_trace_details() {
    LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.FINEST.name();
    ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
    componentLogEntry.originStackTrace = createMockComponentStackTrace(
      LoggerStackTrace.SourceMetadataType.AuraDefinitionBundle,
      'c/someAuraComponent',
      'someFunction'
    );
    System.Assert.areEqual(0, Logger.saveLogCallCount);
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

    ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

    System.Assert.areEqual(1, Logger.saveLogCallCount);
    System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
    LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
    System.Assert.areEqual('Component', publishedLogEntryEvent.OriginType__c);
    System.Assert.areEqual('Aura', publishedLogEntryEvent.ComponentType__c);
    System.Assert.areEqual(
      componentLogEntry.originStackTrace.componentName + '.' + componentLogEntry.originStackTrace.functionName,
      publishedLogEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual(componentLogEntry.originStackTrace.metadataType, publishedLogEntryEvent.OriginSourceMetadataType__c);
    System.Assert.areEqual(componentLogEntry.originStackTrace.componentName, publishedLogEntryEvent.OriginSourceApiName__c);
    System.Assert.areEqual(componentLogEntry.originStackTrace.functionName, publishedLogEntryEvent.OriginSourceActionName__c);
    System.Assert.areEqual(componentLogEntry.originStackTrace.parsedStackTraceString, publishedLogEntryEvent.StackTrace__c);
  }

  @IsTest
  static void it_should_set_lwc_javascript_origin_stack_trace_details() {
    LoggerStackTrace.ignoreOrigin(ComponentLogger_Tests.class);
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.FINEST.name();
    ComponentLogger.ComponentLogEntry componentLogEntry = createMockComponentLogEntry();
    componentLogEntry.originStackTrace = new ComponentLogger.ComponentStackTrace();
    componentLogEntry.originStackTrace.metadataType = LoggerStackTrace.SourceMetadataType.LightningComponentBundle.name();
    componentLogEntry.originStackTrace.componentName = 'c/someLightningWebComponent';
    componentLogEntry.originStackTrace.functionName = 'someFunction';
    System.Assert.areEqual(0, Logger.saveLogCallCount);
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

    ComponentLogger.saveComponentLogEntries(new List<ComponentLogger.ComponentLogEntry>{ componentLogEntry }, null);

    System.Assert.areEqual(1, Logger.saveLogCallCount);
    System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
    LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
    System.Assert.areEqual('Component', publishedLogEntryEvent.OriginType__c);
    System.Assert.areEqual('LWC', publishedLogEntryEvent.ComponentType__c);
    System.Assert.areEqual(
      componentLogEntry.originStackTrace.componentName + '.' + componentLogEntry.originStackTrace.functionName,
      publishedLogEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual(componentLogEntry.originStackTrace.metadataType, publishedLogEntryEvent.OriginSourceMetadataType__c);
    System.Assert.areEqual(componentLogEntry.originStackTrace.componentName, publishedLogEntryEvent.OriginSourceApiName__c);
    System.Assert.areEqual(componentLogEntry.originStackTrace.functionName, publishedLogEntryEvent.OriginSourceActionName__c);
    System.Assert.areEqual(componentLogEntry.originStackTrace.parsedStackTraceString, publishedLogEntryEvent.StackTrace__c);
  }

  private static ComponentLogger.ComponentLogEntry createMockComponentLogEntry() {
    Schema.User currentUser = new Schema.User(
      FirstName = System.UserInfo.getFirstName(),
      Id = System.UserInfo.getUserId(),
      ProfileId = System.UserInfo.getProfileId()
    );
    ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
    componentLogEntry.browser = new ComponentLogger.ComponentBrowserContext();
    componentLogEntry.browser.address = 'https://flow-ruby-5228.scratch.lightning.force.com/lightning/n/Logger_lwc_demo?c__asdfsdf=asdf';
    componentLogEntry.browser.formFactor = 'Large';
    componentLogEntry.browser.language = 'en-US';
    componentLogEntry.browser.screenResolution = '1536 x 824';
    componentLogEntry.browser.userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/113.0';
    componentLogEntry.browser.windowResolution = '1536 x 474';
    componentLogEntry.loggingLevel = System.LoggingLevel.INFO.name();
    componentLogEntry.message = 'hello, world';
    componentLogEntry.originStackTrace = createMockComponentStackTrace();
    componentLogEntry.recordId = currentUser.Id;
    componentLogEntry.record = currentUser;
    componentLogEntry.timestamp = System.now().addDays(-1 / 24);
    componentLogEntry.tags = new List<String>{ 'some tag', 'one more tag' };
    return componentLogEntry;
  }

  private static ComponentLogger.ComponentStackTrace createMockComponentStackTrace() {
    return createMockComponentStackTrace(LoggerStackTrace.SourceMetadataType.LightningComponentBundle, 'c/someComponent', 'someFunction');
  }

  private static ComponentLogger.ComponentStackTrace createMockComponentStackTrace(
    LoggerStackTrace.SourceMetadataType sourceMetadataType,
    String componentApiName,
    String componentFunctionName
  ) {
    ComponentLogger.ComponentStackTrace componentStackTrace = new ComponentLogger.ComponentStackTrace();
    componentStackTrace.metadataType = sourceMetadataType.name();
    componentStackTrace.componentName = componentApiName;
    componentStackTrace.functionName = componentFunctionName;
    return componentStackTrace;
  }
}
