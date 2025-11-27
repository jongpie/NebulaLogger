//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Optional plugin that integrates with OpenTelemetry to send log records using the OTLP format
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount')
public without sharing class OpenTelemetryLoggerPlugin implements LoggerPlugin.Triggerable, System.Queueable, System.Finalizer, Database.AllowsCallouts {
  @TestVisible
  private static final String ENDPOINT = LoggerParameter.getString('OpenTelemetryEndpoint', null);
  @TestVisible
  private static final String SERVICE_NAME = LoggerParameter.getString('OpenTelemetryServiceName', 'Salesforce');
  @TestVisible
  private static final String SERVICE_VERSION = LoggerParameter.getString('OpenTelemetryServiceVersion', '1.0.0');
  @TestVisible
  private static final System.LoggingLevel NOTIFICATION_LOGGING_LEVEL = Logger.getLoggingLevel(
    LoggerParameter.getString('OpenTelemetryNotificationLoggingLevel', System.LoggingLevel.WARN.name())
  );
  @TestVisible
  private static final String OTLP_VERSION = '1.0.0';
  @TestVisible
  private static final String AUTH_HEADER = LoggerParameter.getString('OpenTelemetryAuthHeader', null);

  private List<Log__c> logs;

  /**
   * @description Default constructor
   */
  @SuppressWarnings('PMD.EmptyStatementBlock')
  public OpenTelemetryLoggerPlugin() {
  }

  private OpenTelemetryLoggerPlugin(List<Log__c> unsentLogs) {
    this();
    this.logs = unsentLogs;
  }

  /**
   * @description Handles the integration with OpenTelemetry. This method is automatically called by Nebula Logger's plugin framework.
   * @param  configuration The instance of `LoggerPlugin__mdt` configured for this specific plugin
   * @param  context The instance of `LoggerTriggerableContext`, provided by the logging system
   */
  public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext context) {
    if (context.sobjectType != Schema.Log__c.SObjectType || String.isBlank(ENDPOINT)) {
      return;
    }

    this.logs = (List<Log__c>) context.triggerNew;
    switch on context.triggerOperationType {
      when BEFORE_INSERT, BEFORE_UPDATE {
        this.flagLogsForOpenTelemetryExport();
      }
      when AFTER_INSERT, AFTER_UPDATE {
        this.sendAsyncOpenTelemetryLogs();
      }
    }
  }

  /**
   * @description Handles the queueable execute logic. Required by the System.Queueable interface.
   * @param queueableContext Context of the current queueable instance.
   */
  public void execute(System.QueueableContext queueableContext) {
    // Since this runs in an async context, requery the logs just in case any field values have changed
    this.requeryLogs();

    if (this.logs.isEmpty()) {
      return;
    }

    List<Log__c> sentLogs = new List<Log__c>();
    List<Log__c> unsentLogs = new List<Log__c>();    
    DateTime exportTimeNow = System.now();

    for (Log__c log : this.logs) {
      if (System.Limits.getCallouts() == System.Limits.getLimitCallouts()) {
        // If there are too many logs to send in the same transaction
        // add them to the unsentLogs list, which will be queued as a separate job
        unsentLogs.add(log);
        continue;
      }

      System.HttpRequest request = this.createOpenTelemetryHttpRequest(log);
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.finest('Sending log entries to OpenTelemetry endpoint').setHttpRequestDetails(request);
      }

      System.HttpResponse response = new System.Http().send(request);
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.finest('Sent log entries to OpenTelemetry endpoint').setHttpResponseDetails(response);
      }

      log.OpenTelemetryExportDate__c = exportTimeNow;
      sentLogs.add(log);
    }
    Logger.saveLog();
    update sentLogs;

    // If any logs couldn't be sent due to governor limits, start a new instance of the job
    if (unsentLogs.size() > 0) {
      Id jobId = System.enqueueJob(new OpenTelemetryLoggerPlugin(unsentLogs));
      System.attachFinalizer(new OpenTelemetryLoggerPlugin(unsentLogs));
    }
  }

  /**
   * @description Handles errors that occur during queueable execution. Required by the System.Finalizer interface.
   * @param finalizerContext Context of the current finalizer instance containing error information.
   */
  public void execute(System.FinalizerContext finalizerContext) {
    if (finalizerContext.getResult() == System.ParentJobResult.SUCCESS) {
      return;
    }

    // Log the error that occurred during queueable execution
    String errorMessage = 'OpenTelemetry queueable job failed';
    Exception jobException = finalizerContext.getException();
    
    if (jobException != null) {
      Logger.error(errorMessage, jobException);
    } else {
      Logger.error(errorMessage);
    }
    
    // Add context about which logs were being processed
    if (this.logs != null && !this.logs.isEmpty()) {
      List<Id> logIds = new List<Id>();
      for (Log__c log : this.logs) {
        logIds.add(log.Id);
      }
      Logger.error('Failed to send ' + this.logs.size() + ' log(s) to OpenTelemetry. Log IDs: ' + String.join(logIds, ', '));
    }
    
    Logger.saveLog();
  }

  private void flagLogsForOpenTelemetryExport() {
    if (NOTIFICATION_LOGGING_LEVEL == null) {
      return;
    }

    for (Log__c log : this.logs) {
      if (log.MaxLogEntryLoggingLevelOrdinal__c >= NOTIFICATION_LOGGING_LEVEL.ordinal()) {
        log.SendToOpenTelemetry__c = true;
      }
    }
  }

  private void sendAsyncOpenTelemetryLogs() {
    List<Log__c> logsToSend = new List<Log__c>();
    for (Log__c log : this.logs) {
      // Only send logs that are flagged for export AND have not already been exported
      if (log.SendToOpenTelemetry__c && log.OpenTelemetryExportDate__c == null) {
        logsToSend.add(log);
      }
    }
    // Since plugins are called from trigger handlers, and triggers can't make callouts
    // run this class as a queueable (async) job
    if (logsToSend.isEmpty() == false) {
      Id jobId = System.enqueueJob(new OpenTelemetryLoggerPlugin(logsToSend));
      System.attachFinalizer(new OpenTelemetryLoggerPlugin(logsToSend));
    }
  }

  @SuppressWarnings('PMD.UnusedLocalVariable')
  private void requeryLogs() {
    Integer loggingLevelOrdinal = NOTIFICATION_LOGGING_LEVEL.ordinal();
    String logEntryChildQuery =
      '\n(' +
      '\nSELECT Id, LoggingLevel__c, LoggingLevelOrdinal__c, Message__c, ExceptionType__c, ExceptionMessage__c,' +
      '\n  ExceptionStackTrace__c, StackTrace__c, Timestamp__c, RecordId__c, RecordJson__c,' +
      '\n  HttpRequestBodyMasked__c, HttpResponseBody__c, LimitsAggregateQueriesUsed__c,' +
      '\n  LimitsCpuTimeUsed__c, LimitsHeapSizeUsed__c' +
      '\nFROM LogEntries__r' +
      '\nWHERE LoggingLevelOrdinal__c >= :loggingLevelOrdinal' +
      '\nORDER BY Timestamp__c ASC' +
      '\n)';
    List<String> fieldNames = new List<String>{
      Schema.Log__c.Name.toString(),
      Schema.Log__c.ApiVersion__c.toString(),
      Schema.Log__c.OrganizationId__c.toString(),
      Schema.Log__c.TransactionId__c.toString(),
      Schema.Log__c.StartTime__c.toString(),
      logEntryChildQuery,
      'LoggedBy__r.Username',
      'TYPEOF Owner WHEN User THEN Username ELSE Name END'
    };
    // Deduplicate the list of field names
    fieldNames = new List<String>(new Set<String>(fieldNames));
    String query =
      'SELECT ' +
      String.join(fieldNames, ', ') +
      ' FROM Log__c' +
      '\nWHERE Id IN :logs' +
      '\nAND MaxLogEntryLoggingLevelOrdinal__c >= :loggingLevelOrdinal' +
      '\nAND SendToOpenTelemetry__c = TRUE' +
      '\nAND OpenTelemetryExportDate__c = NULL';
    this.logs = (List<Log__c>) System.Database.query(query);
  }

  private System.HttpRequest createOpenTelemetryHttpRequest(Log__c log) {
    System.HttpRequest request = new System.HttpRequest();
    request.setEndpoint(ENDPOINT);
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    
    // Add authentication header if configured
    if (String.isNotBlank(AUTH_HEADER)) {
      // Expected format: "Authorization: Bearer <token>" or "x-api-key: <key>"
      List<String> headerParts = AUTH_HEADER.split(':', 2);
      if (headerParts.size() == 2) {
        request.setHeader(headerParts[0].trim(), headerParts[1].trim());
      }
    }

    // Build the OTLP JSON payload
    String payload = this.buildOtlpPayload(log);
    request.setBody(payload);

    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('Created OpenTelemetry HTTP Request').setHttpRequestDetails(request);
    }
    return request;
  }

  @SuppressWarnings('PMD.NcssMethodCount')
  private String buildOtlpPayload(Log__c log) {
    OtlpPayload payload = new OtlpPayload();
    payload.resourceLogs = new List<ResourceLogs>();
    
    ResourceLogs resourceLog = new ResourceLogs();
    resourceLog.resource = this.buildResource();
    resourceLog.scopeLogs = new List<ScopeLogs>();
    
    ScopeLogs scopeLog = new ScopeLogs();
    scopeLog.scope = this.buildScope();
    scopeLog.logRecords = new List<LogRecord>();
    
    // Convert each LogEntry to a LogRecord
    for (LogEntry__c logEntry : log.LogEntries__r) {
      scopeLog.logRecords.add(this.convertLogEntryToLogRecord(log, logEntry));
    }
    
    resourceLog.scopeLogs.add(scopeLog);
    payload.resourceLogs.add(resourceLog);
    
    return System.JSON.serialize(payload);
  }

  private Resource buildResource() {
    Resource resource = new Resource();
    resource.attributes = new List<Attribute>();
    
    // Add service.name
    Attribute serviceName = new Attribute();
    serviceName.key = 'service.name';
    serviceName.value = new AttributeValue();
    serviceName.value.stringValue = SERVICE_NAME;
    resource.attributes.add(serviceName);
    
    // Add service.version
    Attribute serviceVersion = new Attribute();
    serviceVersion.key = 'service.version';
    serviceVersion.value = new AttributeValue();
    serviceVersion.value.stringValue = SERVICE_VERSION;
    resource.attributes.add(serviceVersion);
    
    // Add organization.id
    Attribute orgId = new Attribute();
    orgId.key = 'organization.id';
    orgId.value = new AttributeValue();
    orgId.value.stringValue = System.UserInfo.getOrganizationId();
    resource.attributes.add(orgId);
    
    return resource;
  }

  private Scope buildScope() {
    Scope scope = new Scope();
    scope.name = 'NebulaLogger';
    scope.version = OTLP_VERSION;
    scope.attributes = new List<Attribute>();
    return scope;
  }

  @SuppressWarnings('PMD.NcssMethodCount, PMD.CognitiveComplexity')
  private LogRecord convertLogEntryToLogRecord(Log__c log, LogEntry__c logEntry) {
    LogRecord record = new LogRecord();
    
    // Set timestamp in nanoseconds (Salesforce DateTime is in milliseconds)
    Long timestampMillis = logEntry.Timestamp__c.getTime();
    record.timeUnixNano = String.valueOf(timestampMillis * 1000000);
    
    // Set observed timestamp (when the log was recorded)
    record.observedTimeUnixNano = record.timeUnixNano;
    
    // Set severity
    record.severityNumber = this.mapLoggingLevelToSeverityNumber(logEntry.LoggingLevel__c);
    record.severityText = logEntry.LoggingLevel__c;
    
    // Set body (main log message)
    record.body = new AttributeValue();
    record.body.stringValue = logEntry.Message__c;
    
    // Set attributes
    record.attributes = new List<Attribute>();
    
    // Add transaction ID
    this.addStringAttribute(record.attributes, 'transaction.id', log.TransactionId__c);
    
    // Add logged by user
    this.addStringAttribute(record.attributes, 'user.name', log.LoggedBy__r.Username);
    
    // Add organization ID
    this.addStringAttribute(record.attributes, 'organization.id', log.OrganizationId__c);
    
    // Add API version
    if (log.ApiVersion__c != null) {
      this.addStringAttribute(record.attributes, 'api.version', String.valueOf(log.ApiVersion__c));
    }
    
    // Add exception information if present
    if (String.isNotBlank(logEntry.ExceptionType__c)) {
      this.addStringAttribute(record.attributes, 'exception.type', logEntry.ExceptionType__c);
    }
    if (String.isNotBlank(logEntry.ExceptionMessage__c)) {
      this.addStringAttribute(record.attributes, 'exception.message', logEntry.ExceptionMessage__c);
    }
    if (String.isNotBlank(logEntry.ExceptionStackTrace__c)) {
      this.addStringAttribute(record.attributes, 'exception.stacktrace', logEntry.ExceptionStackTrace__c);
    }
    
    // Add stack trace
    if (String.isNotBlank(logEntry.StackTrace__c)) {
      this.addStringAttribute(record.attributes, 'code.stacktrace', logEntry.StackTrace__c);
    }
    
    // Add record information if present
    if (String.isNotBlank(logEntry.RecordId__c)) {
      this.addStringAttribute(record.attributes, 'record.id', logEntry.RecordId__c);
    }
    
    // Add limits information
    if (logEntry.LimitsAggregateQueriesUsed__c != null) {
      this.addIntAttribute(record.attributes, 'limits.aggregate_queries', Integer.valueOf(logEntry.LimitsAggregateQueriesUsed__c));
    }
    if (logEntry.LimitsCpuTimeUsed__c != null) {
      this.addIntAttribute(record.attributes, 'limits.cpu_time', Integer.valueOf(logEntry.LimitsCpuTimeUsed__c));
    }
    if (logEntry.LimitsHeapSizeUsed__c != null) {
      this.addIntAttribute(record.attributes, 'limits.heap_size', Integer.valueOf(logEntry.LimitsHeapSizeUsed__c));
    }
    
    // Add trace context (using TransactionId as trace ID)
    record.traceId = this.convertToHexTraceId(log.TransactionId__c);
    record.spanId = this.convertToHexSpanId(logEntry.Id);
    
    return record;
  }

  private void addStringAttribute(List<Attribute> attributes, String key, String value) {
    if (String.isBlank(value)) {
      return;
    }
    Attribute attr = new Attribute();
    attr.key = key;
    attr.value = new AttributeValue();
    attr.value.stringValue = value;
    attributes.add(attr);
  }

  private void addIntAttribute(List<Attribute> attributes, String key, Integer value) {
    if (value == null) {
      return;
    }
    Attribute attr = new Attribute();
    attr.key = key;
    attr.value = new AttributeValue();
    attr.value.intValue = String.valueOf(value);
    attributes.add(attr);
  }

  private Integer mapLoggingLevelToSeverityNumber(String loggingLevel) {
    // Map Salesforce logging levels to OpenTelemetry severity numbers
    // See: https://opentelemetry.io/docs/specs/otel/logs/data-model/#field-severitynumber
    switch on loggingLevel {
      when 'FINEST' {
        return 1; // TRACE
      }
      when 'FINER' {
        return 5; // DEBUG
      }
      when 'FINE' {
        return 9; // DEBUG2
      }
      when 'DEBUG' {
        return 9; // DEBUG2
      }
      when 'INFO' {
        return 13; // INFO2
      }
      when 'WARN' {
        return 17; // WARN2
      }
      when 'ERROR' {
        return 21; // ERROR2
      }
      when else {
        return 13; // INFO2 as default
      }
    }
  }

  private String convertToHexTraceId(String transactionId) {
    // Convert transaction ID to a 32-character hex string for trace ID
    if (String.isBlank(transactionId)) {
      return null;
    }
    String hexString = EncodingUtil.convertToHex(Blob.valueOf(transactionId)).toLowerCase();
    // Ensure it's 32 characters (pad or truncate)
    return hexString.length() >= 32 ? hexString.substring(0, 32) : hexString.rightPad(32, '0');
  }

  private String convertToHexSpanId(String logEntryId) {
    // Convert log entry ID to a 16-character hex string for span ID
    if (String.isBlank(logEntryId)) {
      return null;
    }
    String hexString = EncodingUtil.convertToHex(Blob.valueOf(logEntryId)).toLowerCase();
    // Ensure it's 16 characters (pad or truncate)
    return hexString.length() >= 16 ? hexString.substring(0, 16) : hexString.rightPad(16, '0');
  }

  // Private DTO classes that match OpenTelemetry OTLP JSON format
  @TestVisible
  private class OtlpPayload {
    public List<ResourceLogs> resourceLogs;
  }

  @TestVisible
  private class ResourceLogs {
    public Resource resource;
    public List<ScopeLogs> scopeLogs;
  }

  @TestVisible
  private class Resource {
    public List<Attribute> attributes;
  }

  @TestVisible
  private class ScopeLogs {
    public Scope scope;
    public List<LogRecord> logRecords;
  }

  @TestVisible
  private class Scope {
    public String name;
    public String version;
    public List<Attribute> attributes;
  }

  @SuppressWarnings('PMD.FieldNamingConventions, PMD.VariableNamingConventions')
  @TestVisible
  private class LogRecord {
    public String timeUnixNano;
    public String observedTimeUnixNano;
    public Integer severityNumber;
    public String severityText;
    public AttributeValue body;
    public List<Attribute> attributes;
    public String traceId;
    public String spanId;
  }

  @TestVisible
  private class Attribute {
    public String key;
    public AttributeValue value;
  }

  @SuppressWarnings('PMD.FieldNamingConventions, PMD.VariableNamingConventions')
  @TestVisible
  private class AttributeValue {
    public String stringValue;
    public String intValue;
    public String doubleValue;
    public String boolValue;
  }
}

