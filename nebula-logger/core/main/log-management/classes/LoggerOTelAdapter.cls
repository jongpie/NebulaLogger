/**
 * @group Log Management
 * @description Class used to handle the translation between Nebula Logger-specific concepts/data model
 *              and OpenTelemetry's (OTel) schema. All of this is specific to Nebula Logger.
 * @see LoggerOTelSchema
 * @see LoggerRestResource
 * @see LogEntryEventBuilder
 * @see LogViewerController
 */
public without sharing class LoggerOTelAdapter {
  // Use case: logViewer LWC on Log__c should have a tab to show Log__c in OTel format
  public static LoggerOTelSchema.LogsPayload convertToOTel(Log__c log) {
    return LoggerOTelAdapter.convertToOTel(new List<Log__c>{ log }).get(0);
  }

  // Use case: Alerting system (WIP) may have actions configured to send Log__c records to an OTel collector endpoint.
  public static List<LoggerOTelSchema.LogsPayload> convertToOTel(List<Log__c> logs) {
    return null;
  }

  // Use case: Alerting system (WIP) may have actions configured to send platform events to an OTel collector endpoint.
  // TODO each LoggerOTelSchema.LogsPayload instance would be for a different transaction ID (and/or the OTel equivalent - traceId?), need to determine
  //      what exactly that would be.
  public static List<LoggerOTelSchema.LogsPayload> convertToOTel(List<LogEntryEvent__e> logEntryEvents) {
    // TODO loop through events, and create 1 LoggerOTelSchema.LogsPayload per... TransactionId__c value, probably?

    return null;
  }

  public static Map<Schema.SObjectType, List<SObject>> convertToCustomObjects(LoggerOTelSchema.LogsPayload payload) {
    return LoggerOTelAdapter.convertToCustomObjects(new List<LoggerOTelSchema.LogsPayload>{ payload });
  }

  // Multiple use cases below: converting OTel logs payload into either Nebula Logger's platform events, or custom objects
  public static Map<Schema.SObjectType, List<SObject>> convertToCustomObjects(List<LoggerOTelSchema.LogsPayload> payloads) {
    Map<Schema.SObjectType, List<SObject>> sobjectTypeToConvertedRecords = new Map<Schema.SObjectType, List<SObject>>();

    // TODO

    return sobjectTypeToConvertedRecords;
  }

  public static List<LogEntryEvent__e> convertToPlatformEvents(LoggerOTelSchema.LogsPayload payload) {
    return LoggerOTelAdapter.convertToPlatformEvents(new List<LoggerOTelSchema.LogsPayload>{ payload });
  }

  public static List<LogEntryEvent__e> convertToPlatformEvents(List<LoggerOTelSchema.LogsPayload> payloads) {
    List<LogEntryEvent__e> convertedPlatformEvents = new List<LogEntryEvent__e>();

    // TODO

    return convertedPlatformEvents;
  }

  // TODO revisit where this code should live
  private Map<String, Object> getAttributesByKey(List<LoggerOTelSchema.Attribute> attributes) {
    Map<String, Object> attributeKeyToAttribute = new Map<String, Object>();

    for (LoggerOTelSchema.Attribute entryAttribute : attributes) {
      attributeKeyToAttribute.put(entryAttribute.key, entryAttribute.value?.getDataValue());
    }

    return attributeKeyToAttribute;
  }

  private class LogEntryEventConverter {
    private final List<LoggerOTelSchema.LogsPayload> payloads;
    public LogEntryEventConverter(List<LoggerOTelSchema.LogsPayload> payloads) {
      this.payloads = payloads;
    }

    public Map<Schema.SObjectType, List<SObject>> getCustomObjects() {
      Map<Schema.SObjectType, List<SObject>> sobjectTypeToConvertedRecords = new Map<Schema.SObjectType, List<SObject>>();

      return sobjectTypeToConvertedRecords;
    }

    public List<LogEntryEvent__e> getLogEntryEvents() {
      List<LogEntryEvent__e> convertedLogEntryEvents = new List<LogEntryEvent__e>();

      // Four fors?!
      for (LoggerOTelSchema.LogsPayload payload : this.payloads) {
        for (LoggerOTelSchema.ResourceLog resourceLog : payload.resourceLogs) {
          for (LoggerOTelSchema.ScopeLog scopeLog : resourceLog.scopeLogs) {
            for (LoggerOTelSchema.LogRecord logRecord : scopeLog.LogRecords) {
              // TODO
              LogEntryEvent__e convertedLogEntryEvent = this.convertToLogEntryEvent(logRecord);
              // TODO possible have overloads for setAttributeFieldValues() that takes either logRecord or resource,
              // each with its own corresponding mappings. This should ensure that the attributes have to be correctly mapped
              // in order to be set as expected.
              // this.setAttributeFieldValues(logRecord.getAttributesByKey(), convertedLogEntryEvent);
              // this.setAttributeFieldValues(resourceLog.resource.getAttributesByKey(), convertedLogEntryEvent);
            }
          }
        }
      }

      return convertedLogEntryEvents;
    }

    private LogEntryEvent__e convertToLogEntryEvent(LoggerOTelSchema.LogRecord otelLogRecord) {
      LoggerOTelSchema.SeverityLevel entrySeverityLevel = otelLogRecord.getSeverityLevel();
      System.LoggingLevel entryLoggingLevel = entrySeverityLevel.toLoggingLevel();

      // TODO revisit how to handle setting the various timestamp fields, if LogEntryEventBuilder isn't being used
      // Long entryEpochTimestamp = timeUnixNano == null ? null : Long.valueOf(this.timeUnixNano) / 1000000;
      // Datetime entryTimestamp = timeUnixNano == null ? null : Datetime.newInstance(entryEpochTimestamp);
      // String convertedTraceId = this.convertTraceId();

      // TODO don't use Logger here, just instantiate new LogEntryEvent__e() - it should "just" be a data conversion
      // LogEntryEventBuilder builder = Logger.newEntry(entryLoggingLevel, this.body?.stringValue);
      // if (entryTimestamp != null) {
      //   builder.setTimestamp(entryTimestamp);
      // }
      // this.convertedLogEntryEvent = builder.getLogEntryEvent();

      LogEntryEvent__e convertedLogEntryEvent = new LogEntryEvent__e(
        LoggingLevel__c = entryLoggingLevel?.name(),
        LoggingLevelOrdinal__c = entryLoggingLevel?.ordinal(),
        Message__c = otelLogRecord.body?.getDataValue()?.toString(),
        // TODO revisit EntryScenario__c mapping
        // EntryScenario__c = this.name,
        // TODO revisit TransactionId__c mapping & OTel's traceId usage
        // TransactionId__c = convertedTraceId,
        OTelSeverityNumber__c = entrySeverityLevel.SeverityNumber,
        OTelSeverityText__c = entrySeverityLevel.SeverityText,
        OTelSpanId__c = otelLogRecord.spanId,
        OTelTraceId__c = otelLogRecord.traceId
      );

      // TODO revisit/re-implement this
      // Map<Schema.SObjectField, Object> supplementalFieldToValue = this.convertAttributes();
      // for (Schema.SObjectField field : supplementalFieldToValue.keySet()) {
      //   this.convertedLogEntryEvent.put(field, supplementalFieldToValue.get(field));
      // }

      return convertedLogEntryEvent;
    }

    private void setAttributeFieldValues(Map<String, Object> attributeKeyToValue, LogEntryEvent__e logEntryEvent) {
      // browser attributes
      logEntryEvent.put(LogEntryEvent__e.BrowserAddress__c, attributeKeyToValue.get('browser.address'));
      logEntryEvent.put(LogEntryEvent__e.BrowserFormFactor__c, attributeKeyToValue.get('browser.form_factor'));
      logEntryEvent.put(LogEntryEvent__e.BrowserLanguage__c, attributeKeyToValue.get('browser.language'));
      logEntryEvent.put(LogEntryEvent__e.BrowserScreenResolution__c, attributeKeyToValue.get('browser.screen_resolution'));
      logEntryEvent.put(LogEntryEvent__e.BrowserUserAgent__c, attributeKeyToValue.get('browser.user_agent'));
      logEntryEvent.put(LogEntryEvent__e.BrowserWindowResolution__c, attributeKeyToValue.get('browser.window_resolution'));

      // exception attributes
      logEntryEvent.put(LogEntryEvent__e.ExceptionMessage__c, attributeKeyToValue.get('exception.message'));
      logEntryEvent.put(LogEntryEvent__e.ExceptionStackTrace__c, attributeKeyToValue.get('exception.stack_trace'));
      logEntryEvent.put(LogEntryEvent__e.ExceptionType__c, attributeKeyToValue.get('exception.type'));

      // http_request attributes
      logEntryEvent.put(LogEntryEvent__e.HttpRequestBody__c, attributeKeyToValue.get('http_request.body'));
      logEntryEvent.put(LogEntryEvent__e.HttpRequestBodyMasked__c, attributeKeyToValue.get('http_request.body_masked'));
      logEntryEvent.put(LogEntryEvent__e.HttpRequestCompressed__c, attributeKeyToValue.get('http_request.compressed'));
      logEntryEvent.put(LogEntryEvent__e.HttpRequestEndpoint__c, attributeKeyToValue.get('http_request.endpoint'));
      logEntryEvent.put(LogEntryEvent__e.HttpRequestHeaderKeys__c, attributeKeyToValue.get('http_request.header_keys'));
      logEntryEvent.put(LogEntryEvent__e.HttpRequestHeaders__c, attributeKeyToValue.get('http_request.headers'));
      logEntryEvent.put(LogEntryEvent__e.HttpRequestMethod__c, attributeKeyToValue.get('http_request.method'));

      // http_response attributes
      logEntryEvent.put(LogEntryEvent__e.HttpResponseBody__c, attributeKeyToValue.get('http_response.body'));
      logEntryEvent.put(LogEntryEvent__e.HttpResponseBodyMasked__c, attributeKeyToValue.get('http_response.body_masked'));
      logEntryEvent.put(LogEntryEvent__e.HttpResponseHeaderKeys__c, attributeKeyToValue.get('http_response.header_keys'));
      logEntryEvent.put(LogEntryEvent__e.HttpResponseHeaders__c, attributeKeyToValue.get('http_response.headers'));
      logEntryEvent.put(LogEntryEvent__e.HttpResponseStatus__c, attributeKeyToValue.get('http_response.status'));
      logEntryEvent.put(LogEntryEvent__e.HttpResponseStatusCode__c, attributeKeyToValue.get('http_response.status_code'));

      // limits attributes
      logEntryEvent.put(LogEntryEvent__e.LimitsAggregateQueriesMax__c, attributeKeyToValue.get('limits.aggregate_queries_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsAggregateQueriesUsed__c, attributeKeyToValue.get('limits.aggregate_queries_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsAsyncCallsMax__c, attributeKeyToValue.get('limits.async_calls_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsAsyncCallsUsed__c, attributeKeyToValue.get('limits.async_calls_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsCalloutsMax__c, attributeKeyToValue.get('limits.callouts_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsCalloutsUsed__c, attributeKeyToValue.get('limits.callouts_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsCpuTimeMax__c, attributeKeyToValue.get('limits.cpu_time_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsCpuTimeUsed__c, attributeKeyToValue.get('limits.cpu_time_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsDmlRowsMax__c, attributeKeyToValue.get('limits.dml_rows_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsDmlRowsUsed__c, attributeKeyToValue.get('limits.dml_rows_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsDmlStatementsMax__c, attributeKeyToValue.get('limits.dml_statements_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsDmlStatementsUsed__c, attributeKeyToValue.get('limits.dml_statements_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsEmailInvocationsMax__c, attributeKeyToValue.get('limits.email_invocations_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsEmailInvocationsUsed__c, attributeKeyToValue.get('limits.email_invocations_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsFutureCallsMax__c, attributeKeyToValue.get('limits.future_calls_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsFutureCallsUsed__c, attributeKeyToValue.get('limits.future_calls_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsHeapSizeMax__c, attributeKeyToValue.get('limits.heap_size_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsHeapSizeUsed__c, attributeKeyToValue.get('limits.heap_size_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsMobilePushApexCallsMax__c, attributeKeyToValue.get('limits.mobile_push_apex_calls_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsMobilePushApexCallsUsed__c, attributeKeyToValue.get('limits.mobile_push_apex_calls_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsPublishImmediateDmlStatementsMax__c, attributeKeyToValue.get('limits.publish_immediate_dml_statements_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsPublishImmediateDmlStatementsUsed__c, attributeKeyToValue.get('limits.publish_immediate_dml_statements_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsQueueableJobsMax__c, attributeKeyToValue.get('limits.queueable_jobs_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsQueueableJobsUsed__c, attributeKeyToValue.get('limits.queueable_jobs_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsSoqlQueriesMax__c, attributeKeyToValue.get('limits.soql_queries_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsSoqlQueriesUsed__c, attributeKeyToValue.get('limits.soql_queries_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsSoqlQueryLocatorRowsMax__c, attributeKeyToValue.get('limits.soql_query_locator_rows_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsSoqlQueryLocatorRowsUsed__c, attributeKeyToValue.get('limits.soql_query_locator_rows_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsSoqlQueryRowsMax__c, attributeKeyToValue.get('limits.soql_query_rows_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsSoqlQueryRowsUsed__c, attributeKeyToValue.get('limits.soql_query_rows_used'));
      logEntryEvent.put(LogEntryEvent__e.LimitsSoslSearchesMax__c, attributeKeyToValue.get('limits.sosl_searches_max'));
      logEntryEvent.put(LogEntryEvent__e.LimitsSoslSearchesUsed__c, attributeKeyToValue.get('limits.sosl_searches_used'));

      // logged_by attributes
      logEntryEvent.put(LogEntryEvent__e.LoggedByFederationIdentifier__c, attributeKeyToValue.get('logged_by.federation_identifier'));
      logEntryEvent.put(LogEntryEvent__e.LoggedById__c, attributeKeyToValue.get('logged_by.id'));
      logEntryEvent.put(LogEntryEvent__e.LoggedByUsername__c, attributeKeyToValue.get('logged_by.username'));
      logEntryEvent.put(LogEntryEvent__e.Locale__c, attributeKeyToValue.get('logged_by.locale'));
      logEntryEvent.put(LogEntryEvent__e.ProfileId__c, attributeKeyToValue.get('logged_by.profile_id'));
      logEntryEvent.put(LogEntryEvent__e.ThemeDisplayed__c, attributeKeyToValue.get('logged_by.theme_displayed'));
      logEntryEvent.put(LogEntryEvent__e.TimeZoneId__c, attributeKeyToValue.get('logged_by.time_zone_id'));
      logEntryEvent.put(LogEntryEvent__e.TimeZoneName__c, attributeKeyToValue.get('logged_by.time_zone_name'));
      logEntryEvent.put(LogEntryEvent__e.UserLicenseDefinitionKey__c, attributeKeyToValue.get('logged_by.user_license_definition_key'));
      logEntryEvent.put(LogEntryEvent__e.UserLicenseId__c, attributeKeyToValue.get('logged_by.user_license_id'));
      logEntryEvent.put(LogEntryEvent__e.UserLicenseName__c, attributeKeyToValue.get('logged_by.user_license_name'));
      logEntryEvent.put(LogEntryEvent__e.UserRoleId__c, attributeKeyToValue.get('logged_by.user_role_id'));
      logEntryEvent.put(LogEntryEvent__e.UserRoleName__c, attributeKeyToValue.get('logged_by.user_role_name'));
      logEntryEvent.put(LogEntryEvent__e.UserType__c, attributeKeyToValue.get('logged_by.user_type'));

      // origin attributes
      logEntryEvent.put(LogEntryEvent__e.OriginLocation__c, attributeKeyToValue.get('origin.location'));
      logEntryEvent.put(LogEntryEvent__e.OriginSourceActionName__c, attributeKeyToValue.get('origin.source_action_name'));
      logEntryEvent.put(LogEntryEvent__e.OriginSourceApiName__c, attributeKeyToValue.get('origin.source_api_name'));
      logEntryEvent.put(LogEntryEvent__e.OriginSourceId__c, attributeKeyToValue.get('origin.source_id'));
      logEntryEvent.put(LogEntryEvent__e.OriginSourceMetadataType__c, attributeKeyToValue.get('origin.source_metadata_type'));
      // TODO revisit originType, add in any other missing origin fields
      String originType = attributeKeyToValue.get('origin.type')?.toString() ?? 'External Service';
      logEntryEvent.put(LogEntryEvent__e.OriginType__c, originType);
      logEntryEvent.put(LogEntryEvent__e.StackTrace__c, attributeKeyToValue.get('origin.stack_trace'));

      // parent_log attributes
      logEntryEvent.put(LogEntryEvent__e.ParentLogTransactionId__c, attributeKeyToValue.get('parent_log.transaction_id'));

      // service attributes
      logEntryEvent.put(LogEntryEvent__e.ExternalServiceId__c, attributeKeyToValue.get('service.id'));
      logEntryEvent.put(LogEntryEvent__e.ExternalServiceName__c, attributeKeyToValue.get('service.name'));
      logEntryEvent.put(LogEntryEvent__e.ExternalServiceType__c, attributeKeyToValue.get('service.type'));
      logEntryEvent.put(LogEntryEvent__e.ExternalServiceVersion__c, attributeKeyToValue.get('service.version'));

      // transaction attributes
      logEntryEvent.put(LogEntryEvent__e.TransactionEntryNumber__c, attributeKeyToValue.get('transaction.entry_number'));
      logEntryEvent.put(LogEntryEvent__e.TransactionId__c, attributeKeyToValue.get('transaction.id'));
      logEntryEvent.put(LogEntryEvent__e.TransactionScenario__c, attributeKeyToValue.get('transaction.scenario'));
    }
  }
}
