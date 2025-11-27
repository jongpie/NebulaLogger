//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class OpenTelemetryLoggerPlugin_Tests {
  @IsTest
  static void it_should_not_flag_log_to_send_opentelemetry_when_logging_level_is_not_met() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.WARN;
    System.LoggingLevel openTelemetryLoggingLevel = System.LoggingLevel.ERROR;
    System.Assert.isTrue(logEntryLoggingLevel.ordinal() < openTelemetryLoggingLevel.ordinal(), 'OpenTelemetry logging level ordinal was incorrect');
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(openTelemetryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, false);
    Log__c log = logs.get(0);
    System.Assert.isFalse(log.SendToOpenTelemetry__c);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.BEFORE_INSERT, logs);

    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);

    System.Assert.isFalse(log.SendToOpenTelemetry__c, 'SendToOpenTelemetry__c incorrectly set to true');
    System.Assert.isNull(log.OpenTelemetryExportDate__c, 'OpenTelemetryExportDate__c was not null');
  }

  @IsTest
  static void it_should_flag_log_to_send_opentelemetry_when_logging_level_is_met() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.ERROR;
    System.LoggingLevel openTelemetryLoggingLevel = System.LoggingLevel.WARN;
    System.Assert.isTrue(logEntryLoggingLevel.ordinal() > openTelemetryLoggingLevel.ordinal(), 'OpenTelemetry logging level ordinal was incorrect');
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(openTelemetryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, false);
    Log__c log = logs.get(0);
    System.Assert.isFalse(log.SendToOpenTelemetry__c);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.BEFORE_INSERT, logs);

    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);

    log = logs.get(0);
    System.Assert.isTrue(log.SendToOpenTelemetry__c, 'SendToOpenTelemetry__c incorrectly set to false');
    System.Assert.isNull(log.OpenTelemetryExportDate__c, 'OpenTelemetryExportDate__c was not null');
  }

  @IsTest
  static void it_should_not_send_opentelemetry_for_log_when_logging_level_is_not_met() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.WARN;
    System.LoggingLevel openTelemetryLoggingLevel = System.LoggingLevel.ERROR;
    System.Assert.isTrue(logEntryLoggingLevel.ordinal() < openTelemetryLoggingLevel.ordinal(), 'OpenTelemetry logging level ordinal was incorrect');
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(openTelemetryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, false);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Assert.areEqual(0, System.Limits.getAsyncCalls(), 'The queueable job should not have been enqueued');
    System.Test.stopTest();

    Log__c log = queryLogs(logEntryLoggingLevel).get(0);
    System.Assert.isFalse(log.SendToOpenTelemetry__c, 'SendToOpenTelemetry__c incorrectly set to true');
    System.Assert.isNull(log.OpenTelemetryExportDate__c, 'OpenTelemetryExportDate__c was not null');
    System.Assert.isNull(calloutMock.request);
  }

  @IsTest
  static void it_should_send_opentelemetry_for_log_when_logging_level_is_met_for_error() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.ERROR;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    validateOpenTelemetryPayload(calloutMock, logs.get(0), 'ERROR');
  }

  @IsTest
  static void it_should_send_opentelemetry_for_log_when_logging_level_is_met_for_warn() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.WARN;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    validateOpenTelemetryPayload(calloutMock, logs.get(0), 'WARN');
  }

  @IsTest
  static void it_should_send_opentelemetry_for_log_when_logging_level_is_met_for_info() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.INFO;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    validateOpenTelemetryPayload(calloutMock, logs.get(0), 'INFO');
  }

  @IsTest
  static void it_should_send_opentelemetry_for_log_when_logging_level_is_met_for_debug() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.DEBUG;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    validateOpenTelemetryPayload(calloutMock, logs.get(0), 'DEBUG');
  }

  @IsTest
  static void it_should_send_opentelemetry_for_log_when_logging_level_is_met_for_fine() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.FINE;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    validateOpenTelemetryPayload(calloutMock, logs.get(0), 'FINE');
  }

  @IsTest
  static void it_should_send_opentelemetry_for_log_when_logging_level_is_met_for_finer() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.FINER;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    validateOpenTelemetryPayload(calloutMock, logs.get(0), 'FINER');
  }

  @IsTest
  static void it_should_send_opentelemetry_for_log_when_logging_level_is_met_for_finest() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.FINEST;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    validateOpenTelemetryPayload(calloutMock, logs.get(0), 'FINEST');
  }

  @IsTest
  static void it_should_include_auth_header_when_configured() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.ERROR;
    // Simulate the value that would be retrieved from a Named Credential
    // Format: "HeaderName: HeaderValue"
    String authHeader = 'x-api-key: test-api-key-123';
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel, authHeader);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    System.Assert.isNotNull(calloutMock.request, 'HTTP request should have been made');
    System.Assert.areEqual('test-api-key-123', calloutMock.request.getHeader('x-api-key'), 'x-api-key header should be set correctly');
  }

  @IsTest
  static void it_should_parse_bearer_token_auth_header_when_configured() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.ERROR;
    // Simulate a Bearer token from a Named Credential
    String authHeader = 'Authorization: Bearer test-token-xyz';
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel, authHeader);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    System.Assert.isNotNull(calloutMock.request, 'HTTP request should have been made');
    System.Assert.areEqual('Bearer test-token-xyz', calloutMock.request.getHeader('Authorization'), 'Authorization header should be set correctly with Bearer token');
  }

  @IsTest
  static void it_should_handle_exception_data_in_log_entry() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.ERROR;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogWithException(logEntryLoggingLevel);
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Test.stopTest();

    System.Assert.isNotNull(calloutMock.request, 'HTTP request should have been made');
    String requestBody = calloutMock.request.getBody();
    System.Assert.isTrue(requestBody.contains('exception.type'), 'Should include exception type');
    System.Assert.isTrue(requestBody.contains('NullPointerException'), 'Should include exception type value');
  }

  @IsTest
  static void it_should_not_send_logs_that_have_already_been_exported() {
    System.LoggingLevel logEntryLoggingLevel = System.LoggingLevel.ERROR;
    LoggerPlugin__mdt pluginConfiguration = mockConfigurations(logEntryLoggingLevel);
    List<Log__c> logs = insertLogAndLogEntry(logEntryLoggingLevel, true);
    
    // Simulate that the log has already been exported by setting the export date
    logs[0].OpenTelemetryExportDate__c = System.now();
    update logs[0];
    
    // Re-query to ensure we have the updated record
    logs = queryLogs(logEntryLoggingLevel);
    
    LoggerTriggerableContext context = mockContext(System.TriggerOperation.AFTER_UPDATE, logs);
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    System.Test.startTest();
    OpenTelemetryLoggerPlugin plugin = new OpenTelemetryLoggerPlugin();
    plugin.execute(pluginConfiguration, context);
    System.Assert.areEqual(0, System.Limits.getAsyncCalls(), 'The queueable job should not have been enqueued for already-exported logs');
    System.Test.stopTest();

    // Verify no HTTP callout was made
    System.Assert.isNull(calloutMock.request, 'HTTP request should NOT have been made for already-exported logs');
    
    // Verify the export date hasn't changed
    Log__c log = queryLogs(logEntryLoggingLevel).get(0);
    System.Assert.isTrue(log.SendToOpenTelemetry__c, 'SendToOpenTelemetry__c should still be true');
    System.Assert.isNotNull(log.OpenTelemetryExportDate__c, 'OpenTelemetryExportDate__c should remain populated');
  }

  private static LoggerPlugin__mdt mockConfigurations(System.LoggingLevel notificationLoggingLevel) {
    return mockConfigurations(notificationLoggingLevel, null);
  }

  private static LoggerPlugin__mdt mockConfigurations(System.LoggingLevel notificationLoggingLevel, String authHeader) {
    String mockEndpoint = 'https://fake.otel.example.com/v1/logs';
    LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'OpenTelemetryEndpoint', Value__c = mockEndpoint));
    LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'OpenTelemetryServiceName', Value__c = 'Salesforce'));
    LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'OpenTelemetryServiceVersion', Value__c = '1.0.0'));
    LoggerTestConfigurator.setMock(
      new LoggerParameter__mdt(DeveloperName = 'OpenTelemetryNotificationLoggingLevel', Value__c = notificationLoggingLevel.name())
    );
    if (String.isNotBlank(authHeader)) {
      LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'OpenTelemetryAuthHeader', Value__c = authHeader));
    }
    System.Assert.areEqual(mockEndpoint, LoggerParameter.getString('OpenTelemetryEndpoint', null));
    System.Assert.areEqual(mockEndpoint, OpenTelemetryLoggerPlugin.ENDPOINT);
    System.Assert.areEqual(notificationLoggingLevel.name(), LoggerParameter.getString('OpenTelemetryNotificationLoggingLevel', null));
    System.Assert.areEqual(notificationLoggingLevel, OpenTelemetryLoggerPlugin.NOTIFICATION_LOGGING_LEVEL);

    LoggerPlugin__mdt pluginConfiguration = new LoggerPlugin__mdt(
      DeveloperName = 'OpenTelemetryPlugin',
      IsEnabled__c = true,
      SObjectHandlerApexClass__c = OpenTelemetryLoggerPlugin.class.getName()
    );
    LoggerTestConfigurator.setMock(pluginConfiguration);
    return pluginConfiguration;
  }

  private static LoggerTriggerableContext mockContext(System.TriggerOperation operationType, List<Log__c> logs) {
    return new LoggerTriggerableContext(Schema.Log__c.SObjectType, operationType, logs, new Map<Id, SObject>(logs), new Map<Id, SObject>(logs));
  }

  private static List<Log__c> insertLogAndLogEntry(System.LoggingLevel logEntryLoggingLevel, Boolean sendToOpenTelemetry) {
    LoggerSObjectHandler.shouldExecute(false);
    Log__c log = new Log__c(LoggedBy__c = System.UserInfo.getUserId(), SendToOpenTelemetry__c = sendToOpenTelemetry, TransactionId__c = '1234-5678-90ab');
    insert log;
    LogEntry__c logEntry = new LogEntry__c(
      ExceptionStackTrace__c = 'Some exception stack trace',
      Log__c = log.Id,
      LoggingLevel__c = logEntryLoggingLevel.name(),
      LoggingLevelOrdinal__c = logEntryLoggingLevel.ordinal(),
      Message__c = 'Test log message',
      StackTrace__c = 'A stack trace',
      Timestamp__c = System.now()
    );
    insert logEntry;
    return queryLogs(logEntryLoggingLevel);
  }

  private static List<Log__c> insertLogWithException(System.LoggingLevel logEntryLoggingLevel) {
    LoggerSObjectHandler.shouldExecute(false);
    Log__c log = new Log__c(LoggedBy__c = System.UserInfo.getUserId(), SendToOpenTelemetry__c = true, TransactionId__c = '1234-5678-90ab');
    insert log;
    LogEntry__c logEntry = new LogEntry__c(
      ExceptionType__c = 'NullPointerException',
      ExceptionMessage__c = 'Attempt to de-reference a null object',
      ExceptionStackTrace__c = 'Class.MyClass.myMethod: line 42',
      Log__c = log.Id,
      LoggingLevel__c = logEntryLoggingLevel.name(),
      LoggingLevelOrdinal__c = logEntryLoggingLevel.ordinal(),
      Message__c = 'Test log message with exception',
      StackTrace__c = 'A stack trace',
      Timestamp__c = System.now()
    );
    insert logEntry;
    return queryLogs(logEntryLoggingLevel);
  }

  private static void validateOpenTelemetryPayload(LoggerMockDataCreator.MockHttpCallout calloutMock, Log__c log, String expectedLevel) {
    System.Assert.isNotNull(calloutMock.request, 'HTTP request should have been made');
    String requestBody = calloutMock.request.getBody();
    
    OpenTelemetryLoggerPlugin.OtlpPayload payload = (OpenTelemetryLoggerPlugin.OtlpPayload) System.JSON.deserialize(
      requestBody,
      OpenTelemetryLoggerPlugin.OtlpPayload.class
    );
    
    System.Assert.isNotNull(payload.resourceLogs, 'resourceLogs should not be null');
    System.Assert.areEqual(1, payload.resourceLogs.size(), 'Should have one resourceLog');
    System.Assert.isNotNull(payload.resourceLogs[0].scopeLogs, 'scopeLogs should not be null');
    System.Assert.areEqual(1, payload.resourceLogs[0].scopeLogs.size(), 'Should have one scopeLog');
    System.Assert.isNotNull(payload.resourceLogs[0].scopeLogs[0].logRecords, 'logRecords should not be null');
    System.Assert.isTrue(payload.resourceLogs[0].scopeLogs[0].logRecords.size() > 0, 'Should have at least one logRecord');
    
    OpenTelemetryLoggerPlugin.LogRecord firstRecord = payload.resourceLogs[0].scopeLogs[0].logRecords[0];
    System.Assert.areEqual(expectedLevel, firstRecord.severityText, 'Severity text should match expected level');
    System.Assert.isNotNull(firstRecord.body, 'Body should not be null');
    System.Assert.isTrue(String.isNotBlank(firstRecord.body.stringValue), 'Body should have a message');
  }

  @SuppressWarnings('PMD.UnusedLocalVariable')
  private static List<Log__c> queryLogs(System.LoggingLevel notificationLoggingLevel) {
    Integer notificationLoggingLevelOrdinal = notificationLoggingLevel.ordinal();
    String logEntryChildQuery =
      '\n(' +
      '\nSELECT Id, LoggingLevel__c, LoggingLevelOrdinal__c, Message__c, ExceptionType__c, ExceptionMessage__c,' +
      '\n  ExceptionStackTrace__c, StackTrace__c, Timestamp__c' +
      '\nFROM LogEntries__r' +
      '\nWHERE LoggingLevelOrdinal__c >= :notificationLoggingLevelOrdinal' +
      '\nORDER BY Timestamp__c ASC' +
      '\n)';
    
    String query =
      'SELECT Id, Name, TransactionId__c, OrganizationId__c, SendToOpenTelemetry__c, OpenTelemetryExportDate__c, MaxLogEntryLoggingLevelOrdinal__c, ' +
      'LoggedBy__r.Username, ' +
      logEntryChildQuery +
      ' FROM Log__c';
    return (List<Log__c>) System.Database.query(query);
  }
}

