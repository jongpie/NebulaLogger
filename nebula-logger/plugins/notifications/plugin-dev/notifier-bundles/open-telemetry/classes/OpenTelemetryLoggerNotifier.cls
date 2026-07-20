//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Delivers a `LoggerNotifiableContext` to any OpenTelemetry-compatible backend using
 *              OTLP-HTTP with a JSON body targeting the `/v1/logs` endpoint. One recipient +
 *              service configuration covers Datadog, Splunk (o11y cloud), Honeycomb, Grafana
 *              Cloud, New Relic, and any other vendor that speaks OTLP.
 *
 *              Endpoint resolution:
 *                - Named credential: `callout:{NamedCredentialDeveloperName__c}/v1/logs`
 *                  (recommended - keeps auth secrets in the Named Credential)
 *                - Webhook URL: the full URL to `/v1/logs` on your OTel collector or vendor
 *
 *              Optional per-recipient overrides supplied through `ConfigurationJson__c`:
 *                {
 *                  "headers": { "api-key": "..." },              // extra auth headers
 *                  "resourceAttributes": {                         // added to `resource.attributes`
 *                    "service.name": "my-service",
 *                    "deployment.environment": "production"
 *                  }
 *                }
 */
public without sharing class OpenTelemetryLoggerNotifier implements LoggerNotifiable {
  private static final String LOGS_PATH = '/v1/logs';
  @TestVisible
  private static final Integer SEVERITY_NUMBER_ERROR = 17;
  @TestVisible
  private static final Integer SEVERITY_NUMBER_WARN = 13;
  @TestVisible
  private static final Integer SEVERITY_NUMBER_INFO = 9;
  @TestVisible
  private static final Integer SEVERITY_NUMBER_DEBUG = 5;

  /**
   * @description Called by `LoggerNotifierAsyncDispatcher` in an async, callout-legal context.
   * @param context The rule + recipient + service + matching records to deliver.
   */
  public LoggerNotifiableResult sendNotification(LoggerNotifiableContext context) {
    if (context == null || context.recipient == null || context.matchingRecords == null || context.matchingRecords.isEmpty()) {
      return null;
    }
    Map<String, Object> config = this.parseConfiguration(context.recipient.ConfigurationJson__c);
    System.HttpRequest request = this.buildRequest(context, config);
    if (request == null) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('OpenTelemetryLoggerNotifier - service has neither Webhook URL nor Named Credential; skipping');
      }
      LoggerNotifiableResult skipped = new LoggerNotifiableResult();
      skipped.status = LoggerNotifiableResult.STATUS_SKIPPED;
      skipped.errorMessage = 'Service has neither Webhook URL nor Named Credential configured';
      return skipped;
    }
    request.setBody(this.buildPayload(context, config));
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('OpenTelemetryLoggerNotifier - sending OTLP-HTTP payload').setHttpRequestDetails(request);
    }
    System.HttpResponse response = new System.Http().send(request);
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('OpenTelemetryLoggerNotifier - response received').setHttpResponseDetails(response);
    }
    // See Backlog.md: notifier-side Logger.saveLog() re-fires the notifications plugin trigger; commented out for now.
    // Logger.saveLog();
    // Apex HttpRequest has no getHeaderKeys(), so the notifier hands the runtime every header name it set
    // (Content-Type + any admin-configured header names from the same JSON blob buildRequest parses).
    List<String> knownHeaderNames = new List<String>{ 'Content-Type' };
    Object headersRaw = config.get('headers');
    if (headersRaw instanceof Map<String, Object>) {
      knownHeaderNames.addAll(((Map<String, Object>) headersRaw).keySet());
    }
    return LoggerNotifiableResult.fromHttpRequestAndResponse(request, response, knownHeaderNames);
  }

  private System.HttpRequest buildRequest(LoggerNotifiableContext context, Map<String, Object> config) {
    String endpoint;
    if (String.isNotBlank(context.service.NamedCredentialDeveloperName__c)) {
      endpoint = 'callout:' + context.service.NamedCredentialDeveloperName__c + LOGS_PATH;
    } else if (String.isNotBlank(context.service.WebhookUrl__c)) {
      endpoint = context.service.WebhookUrl__c;
    } else {
      return null;
    }
    System.HttpRequest request = new System.HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    Object headersRaw = config.get('headers');
    if (headersRaw instanceof Map<String, Object>) {
      for (String headerName : ((Map<String, Object>) headersRaw).keySet()) {
        request.setHeader(headerName, String.valueOf(((Map<String, Object>) headersRaw).get(headerName)));
      }
    }
    return request;
  }

  @TestVisible
  private String buildPayload(LoggerNotifiableContext context, Map<String, Object> config) {
    List<Map<String, Object>> logRecords = new List<Map<String, Object>>();
    for (SObject record : context.matchingRecords) {
      logRecords.add(this.buildLogRecord(context, record));
    }
    Map<String, Object> scopeLogs = new Map<String, Object>{
      'scope' => new Map<String, Object>{ 'name' => 'nebula-logger', 'version' => '1.0.0' },
      'logRecords' => logRecords
    };
    Map<String, Object> resourceLogs = new Map<String, Object>{
      'resource' => new Map<String, Object>{ 'attributes' => this.buildResourceAttributes(config) },
      'scopeLogs' => new List<Map<String, Object>>{ scopeLogs }
    };
    return System.JSON.serialize(new Map<String, Object>{ 'resourceLogs' => new List<Map<String, Object>>{ resourceLogs } }, true);
  }

  private Map<String, Object> buildLogRecord(LoggerNotifiableContext context, SObject record) {
    Long nowNanos = System.now().getTime() * 1000000L;
    String severityText = this.tryGetString(record, 'LoggingLevel__c');
    Integer severityNumber = this.severityNumberFor(severityText);
    String message = this.tryGetString(record, 'Message__c');
    Map<String, Object> logRecord = new Map<String, Object>{
      'timeUnixNano' => String.valueOf(nowNanos),
      'observedTimeUnixNano' => String.valueOf(nowNanos),
      'severityNumber' => severityNumber,
      'severityText' => severityText,
      'body' => new Map<String, Object>{ 'stringValue' => message ?? '' },
      'attributes' => this.buildLogAttributes(context, record)
    };
    return logRecord;
  }

  private List<Map<String, Object>> buildLogAttributes(LoggerNotifiableContext context, SObject record) {
    List<Map<String, Object>> attributes = new List<Map<String, Object>>();
    this.addAttributeIfPresent(attributes, 'nebula.rule.name', context.notificationRule.Name);
    this.addAttributeIfPresent(attributes, 'nebula.rule.id', String.valueOf(context.notificationRule.Id));
    this.addAttributeIfPresent(attributes, 'nebula.service.name', context.service?.Name);
    this.addAttributeIfPresent(attributes, 'log.record.type', String.valueOf(record.getSObjectType()));
    Id recordId = (Id) record.get('Id');
    if (recordId != null) {
      this.addAttributeIfPresent(attributes, 'nebula.record.id', String.valueOf(recordId));
      this.addAttributeIfPresent(attributes, 'nebula.record.url', System.URL.getOrgDomainUrl().toExternalForm() + '/' + recordId);
    }
    this.addAttributeIfPresent(attributes, 'nebula.origin', this.tryGetString(record, 'Origin__c'));
    this.addAttributeIfPresent(attributes, 'nebula.originLocation', this.tryGetString(record, 'OriginLocation__c'));
    this.addAttributeIfPresent(attributes, 'nebula.exceptionType', this.tryGetString(record, 'ExceptionType__c'));
    return attributes;
  }

  private List<Map<String, Object>> buildResourceAttributes(Map<String, Object> config) {
    List<Map<String, Object>> attributes = new List<Map<String, Object>>();
    this.addAttributeIfPresent(attributes, 'service.name', 'nebula-logger');
    this.addAttributeIfPresent(attributes, 'organization.id', System.UserInfo.getOrganizationId());
    Object resourceOverrides = config.get('resourceAttributes');
    if (resourceOverrides instanceof Map<String, Object>) {
      for (String key : ((Map<String, Object>) resourceOverrides).keySet()) {
        Object value = ((Map<String, Object>) resourceOverrides).get(key);
        this.addAttributeIfPresent(attributes, key, value == null ? null : String.valueOf(value));
      }
    }
    return attributes;
  }

  private void addAttributeIfPresent(List<Map<String, Object>> attributes, String key, String value) {
    if (String.isBlank(value)) {
      return;
    }
    attributes.add(new Map<String, Object>{ 'key' => key, 'value' => new Map<String, Object>{ 'stringValue' => value } });
  }

  @TestVisible
  private Integer severityNumberFor(String loggingLevel) {
    if (loggingLevel == null) {
      return SEVERITY_NUMBER_INFO;
    }
    switch on loggingLevel {
      when 'ERROR' {
        return SEVERITY_NUMBER_ERROR;
      }
      when 'WARN' {
        return SEVERITY_NUMBER_WARN;
      }
      when 'INFO' {
        return SEVERITY_NUMBER_INFO;
      }
      when 'DEBUG', 'FINE', 'FINER', 'FINEST' {
        return SEVERITY_NUMBER_DEBUG;
      }
      when else {
        return SEVERITY_NUMBER_INFO;
      }
    }
  }

  private String tryGetString(SObject record, String fieldName) {
    Map<String, Schema.SObjectField> fields = record.getSObjectType().getDescribe().fields.getMap();
    if (fields.containsKey(fieldName.toLowerCase()) == false) {
      return null;
    }
    Object value = record.get(fieldName);
    return value == null ? null : String.valueOf(value);
  }

  private Map<String, Object> parseConfiguration(String rawJson) {
    if (String.isBlank(rawJson)) {
      return new Map<String, Object>();
    }
    try {
      Object parsed = System.JSON.deserializeUntyped(rawJson);
      return parsed instanceof Map<String, Object> ? (Map<String, Object>) parsed : new Map<String, Object>();
    } catch (System.Exception ex) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('OpenTelemetryLoggerNotifier - failed to parse ConfigurationJson__c, ignoring', ex);
      }
      return new Map<String, Object>();
    }
  }
}
