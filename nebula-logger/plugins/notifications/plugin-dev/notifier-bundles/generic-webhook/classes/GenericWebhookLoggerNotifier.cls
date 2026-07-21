//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Delivers a `LoggerNotifierRequest` to any HTTP endpoint as a canonical JSON envelope.
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
public without sharing class GenericWebhookLoggerNotifier extends LoggerNotifier {
  private static final String DEFAULT_METHOD = 'POST';

  /**
   * @description Called by `LoggerNotificationAsyncDispatcher` in an async, callout-legal context.
   * @param request The rule + recipient + service + matching records to deliver.
   */
  public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
    if (request == null || request.recipient == null || request.matchingRecords == null || request.matchingRecords.isEmpty()) {
      return null;
    }
    System.HttpRequest httpRequest = this.buildRequest(request);
    if (httpRequest == null) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('GenericWebhookLoggerNotifier - service has neither Webhook URL nor Named Credential; skipping');
      }
      LoggerNotifierResult skipped = new LoggerNotifierResult();
      skipped.status = LoggerNotifierResult.STATUS_SKIPPED;
      skipped.errorMessage = 'Service has neither Webhook URL nor Named Credential configured';
      return skipped;
    }
    httpRequest.setBody(this.buildPayload(request));
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('GenericWebhookLoggerNotifier - sending payload').setHttpRequestDetails(httpRequest);
    }
    System.HttpResponse response = new System.Http().send(httpRequest);
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('GenericWebhookLoggerNotifier - response received').setHttpResponseDetails(response);
    }
    return new LoggerNotifierResult(httpRequest, response, this.collectHeaderNames(request));
  }

  private List<String> collectHeaderNames(LoggerNotifierRequest request) {
    // Apex HttpRequest offers no getHeaderKeys(), so the notifier has to hand every header name it set
    // to the runtime for capture. Start with the notifier's own Content-Type + any admin-configured
    // header names read from the same JSON blob that buildRequest already parsed.
    List<String> names = new List<String>{ 'Content-Type' };
    Map<String, Object> config = this.parseConfiguration(request.recipient.ConfigurationJson__c);
    Object headersRaw = config.get('headers');
    if (headersRaw instanceof Map<String, Object>) {
      names.addAll(((Map<String, Object>) headersRaw).keySet());
    }
    return names;
  }

  @TestVisible
  private System.HttpRequest buildRequest(LoggerNotifierRequest request) {
    Map<String, Object> config = this.parseConfiguration(request.recipient.ConfigurationJson__c);
    String endpoint = this.resolveEndpoint(request.recipient.LoggerNotificationService__r, config);
    if (String.isBlank(endpoint)) {
      return null;
    }
    System.HttpRequest httpRequest = new System.HttpRequest();
    httpRequest.setEndpoint(endpoint);
    httpRequest.setMethod(this.resolveMethod(config));
    httpRequest.setHeader('Content-Type', 'application/json');
    Object headersRaw = config.get('headers');
    if (headersRaw instanceof Map<String, Object>) {
      for (String headerName : ((Map<String, Object>) headersRaw).keySet()) {
        httpRequest.setHeader(headerName, String.valueOf(((Map<String, Object>) headersRaw).get(headerName)));
      }
    }
    return httpRequest;
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
  private String buildPayload(LoggerNotifierRequest request) {
    Map<String, Object> envelope = new Map<String, Object>();
    envelope.put('organizationId', System.UserInfo.getOrganizationId());
    envelope.put('ruleName', request.recipient.LoggerNotificationRule__r.Name);
    envelope.put('ruleId', request.recipient.LoggerNotificationRule__r.Id);
    envelope.put('ruleFilter', request.recipient.LoggerNotificationRule__r.SourceSObjectFilter__c);
    envelope.put('serviceName', request.recipient.LoggerNotificationService__r.Name);
    envelope.put('channelIdentifier', request.recipient.ChannelIdentifier__c);
    envelope.put('matchCount', request.matchingRecords.size());
    List<Map<String, Object>> records = new List<Map<String, Object>>();
    for (SObject record : request.matchingRecords) {
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
