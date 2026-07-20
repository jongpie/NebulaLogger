//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Delivers a `LoggerNotifiableContext` to any HTTP endpoint as a canonical JSON envelope.
 *              Useful for wiring log notifications to Zapier / Make / n8n / Discord / any internal
 *              service without writing a service-specific notifier.
 *
 *              Endpoint: `WebhookUrl__c` OR `callout:{NamedCredentialDeveloperName__c}`.
 *              Optional per-recipient overrides supplied through `ConfigurationJson__c`:
 *                {
 *                  "method": "POST" | "PUT" | "PATCH",  // default POST
 *                  "headers": { "X-Custom": "value" },
 *                  "path": "/optional/suffix/appended/to/named/credential/endpoint"
 *                }
 */
public without sharing class GenericWebhookLoggerNotifier implements LoggerNotifiable {
  private static final String DEFAULT_METHOD = 'POST';

  /**
   * @description Called by `LoggerNotifierAsyncDispatcher` in an async, callout-legal context.
   * @param context The rule + recipient + service + matching records to deliver.
   */
  public LoggerNotifiableResult sendNotification(LoggerNotifiableContext context) {
    if (context == null || context.recipient == null || context.matchingRecords == null || context.matchingRecords.isEmpty()) {
      return null;
    }
    System.HttpRequest request = this.buildRequest(context);
    if (request == null) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('GenericWebhookLoggerNotifier - service has neither Webhook URL nor Named Credential; skipping');
      }
      LoggerNotifiableResult skipped = new LoggerNotifiableResult();
      skipped.status = LoggerNotifiableResult.STATUS_SKIPPED;
      skipped.errorMessage = 'Service has neither Webhook URL nor Named Credential configured';
      return skipped;
    }
    request.setBody(this.buildPayload(context));
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('GenericWebhookLoggerNotifier - sending payload').setHttpRequestDetails(request);
    }
    System.HttpResponse response = new System.Http().send(request);
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('GenericWebhookLoggerNotifier - response received').setHttpResponseDetails(response);
    }
    // See Backlog.md: notifier-side Logger.saveLog() re-fires the notifications plugin trigger; commented out for now.
    // Logger.saveLog();
    return LoggerNotifiableResult.fromHttpRequestAndResponse(request, response, this.collectHeaderNames(context));
  }

  private List<String> collectHeaderNames(LoggerNotifiableContext context) {
    // Apex HttpRequest offers no getHeaderKeys(), so the notifier has to hand every header name it set
    // to the runtime for capture. Start with the notifier's own Content-Type + any admin-configured
    // header names read from the same JSON blob that buildRequest already parsed.
    List<String> names = new List<String>{ 'Content-Type' };
    Map<String, Object> config = this.parseConfiguration(context.recipient.ConfigurationJson__c);
    Object headersRaw = config.get('headers');
    if (headersRaw instanceof Map<String, Object>) {
      names.addAll(((Map<String, Object>) headersRaw).keySet());
    }
    return names;
  }

  @TestVisible
  private System.HttpRequest buildRequest(LoggerNotifiableContext context) {
    Map<String, Object> config = this.parseConfiguration(context.recipient.ConfigurationJson__c);
    String endpoint = this.resolveEndpoint(context.service, config);
    if (String.isBlank(endpoint)) {
      return null;
    }
    System.HttpRequest request = new System.HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod(this.resolveMethod(config));
    request.setHeader('Content-Type', 'application/json');
    Object headersRaw = config.get('headers');
    if (headersRaw instanceof Map<String, Object>) {
      for (String headerName : ((Map<String, Object>) headersRaw).keySet()) {
        request.setHeader(headerName, String.valueOf(((Map<String, Object>) headersRaw).get(headerName)));
      }
    }
    return request;
  }

  private String resolveEndpoint(LoggerNotificationService__c service, Map<String, Object> config) {
    if (String.isNotBlank(service.NamedCredentialDeveloperName__c)) {
      String base = 'callout:' + service.NamedCredentialDeveloperName__c;
      Object path = config.get('path');
      if (path != null && String.isNotBlank(String.valueOf(path))) {
        return base + String.valueOf(path);
      }
      return base;
    }
    if (String.isNotBlank(service.WebhookUrl__c)) {
      return service.WebhookUrl__c;
    }
    return null;
  }

  private String resolveMethod(Map<String, Object> config) {
    Object method = config.get('method');
    if (method == null || String.isBlank(String.valueOf(method))) {
      return DEFAULT_METHOD;
    }
    return String.valueOf(method).toUpperCase();
  }

  @TestVisible
  private String buildPayload(LoggerNotifiableContext context) {
    Map<String, Object> envelope = new Map<String, Object>();
    envelope.put('organizationId', System.UserInfo.getOrganizationId());
    envelope.put('ruleName', context.notificationRule.Name);
    envelope.put('ruleId', context.notificationRule.Id);
    envelope.put('ruleFilter', context.notificationRule.SourceSObjectFilter__c);
    envelope.put('serviceName', context.service?.Name);
    envelope.put('channelIdentifier', context.recipient.ChannelIdentifier__c);
    envelope.put('matchCount', context.matchingRecords.size());
    List<Map<String, Object>> records = new List<Map<String, Object>>();
    for (SObject record : context.matchingRecords) {
      records.add(record.getPopulatedFieldsAsMap());
    }
    envelope.put('matchingRecords', records);
    return System.JSON.serialize(envelope, true);
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
        Logger.warn('GenericWebhookLoggerNotifier - failed to parse ConfigurationJson__c, ignoring', ex);
      }
      return new Map<String, Object>();
    }
  }
}
