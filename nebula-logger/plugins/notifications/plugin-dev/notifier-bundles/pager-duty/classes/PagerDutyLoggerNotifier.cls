//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Delivers a `LoggerNotifierRequest` to PagerDuty via the Events API v2.
 *              Endpoint defaults to `https://events.pagerduty.com/v2/enqueue`, or the recipient's
 *              `WebhookUrl__c`, or `callout:<NamedCredentialDeveloperName__c>/v2/enqueue` if set.
 *
 *              PagerDuty routing key must be supplied via `ConfigurationJson__c`:
 *                {
 *                  "routingKey": "<32-char integration key>",
 *                  "eventAction": "trigger" | "acknowledge" | "resolve"  // default "trigger"
 *                }
 */
public without sharing class PagerDutyLoggerNotifier extends LoggerNotifier {
  @TestVisible
  private static final String DEFAULT_ENDPOINT = 'https://events.pagerduty.com/v2/enqueue';
  private static final String DEFAULT_EVENT_ACTION = 'trigger';

  /**
   * @description Called by `LoggerNotificationAsyncDispatcher` in an async, callout-legal context.
   * @param request The rule + recipient + service + matching records to deliver.
   */
  public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
    if (request == null || request.recipient == null || request.matchingRecords == null || request.matchingRecords.isEmpty()) {
      return null;
    }
    Map<String, Object> config = this.parseConfiguration(request.recipient.ConfigurationJson__c);
    String routingKey = this.tryGetConfigString(config, 'routingKey');
    if (String.isBlank(routingKey)) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('PagerDutyLoggerNotifier - ConfigurationJson__c must set routingKey; skipping');
      }
      LoggerNotifierResult skipped = new LoggerNotifierResult();
      skipped.status = LoggerNotifierResult.STATUS_SKIPPED;
      skipped.errorMessage = 'routingKey missing from ConfigurationJson__c';
      return skipped;
    }
    System.HttpRequest httpRequest = this.buildRequest(request);
    httpRequest.setBody(this.buildPayload(request, routingKey, this.tryGetConfigString(config, 'eventAction')));
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('PagerDutyLoggerNotifier - sending Events API v2 payload').setHttpRequestDetails(httpRequest);
    }
    System.HttpResponse response = new System.Http().send(httpRequest);
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('PagerDutyLoggerNotifier - response received').setHttpResponseDetails(response);
    }
    return new LoggerNotifierResult(httpRequest, response, new List<String>{ 'Content-Type', 'Accept' });
  }

  @TestVisible
  private System.HttpRequest buildRequest(LoggerNotifierRequest request) {
    String endpoint;
    if (String.isNotBlank(request.recipient.LoggerNotificationService__r.NamedCredentialDeveloperName__c)) {
      endpoint = 'callout:' + request.recipient.LoggerNotificationService__r.NamedCredentialDeveloperName__c + '/v2/enqueue';
    } else if (String.isNotBlank(request.recipient.LoggerNotificationService__r.WebhookUrl__c)) {
      endpoint = request.recipient.LoggerNotificationService__r.WebhookUrl__c;
    } else {
      endpoint = DEFAULT_ENDPOINT;
    }
    System.HttpRequest httpRequest = new System.HttpRequest();
    httpRequest.setEndpoint(endpoint);
    httpRequest.setMethod('POST');
    httpRequest.setHeader('Content-Type', 'application/json');
    httpRequest.setHeader('Accept', 'application/json');
    return httpRequest;
  }

  @TestVisible
  private String buildPayload(LoggerNotifierRequest request, String routingKey, String eventAction) {
    Map<String, Object> envelope = new Map<String, Object>();
    envelope.put('routing_key', routingKey);
    envelope.put('event_action', String.isNotBlank(eventAction) ? eventAction : DEFAULT_EVENT_ACTION);
    envelope.put('dedup_key', this.buildDedupKey(request));
    envelope.put('payload', this.buildEventPayload(request));
    envelope.put('links', this.buildLinks(request));
    return System.JSON.serialize(envelope, true);
  }

  @TestVisible
  private String buildDedupKey(LoggerNotifierRequest request) {
    Id firstMatchId = this.firstRecordIdOrNull(request.matchingRecords);
    String rulePart = request.recipient.LoggerNotificationRule__r.Id != null
      ? String.valueOf(request.recipient.LoggerNotificationRule__r.Id)
      : request.recipient.LoggerNotificationRule__r.Name;
    String recordPart = firstMatchId != null ? String.valueOf(firstMatchId) : String.valueOf(request.matchingRecords.size());
    return 'nebula-logger:' + rulePart + ':' + recordPart;
  }

  private Map<String, Object> buildEventPayload(LoggerNotifierRequest request) {
    Map<String, Object> payload = new Map<String, Object>();
    payload.put('summary', this.buildSummary(request));
    payload.put('severity', this.severityFor(request.matchingRecords));
    payload.put('source', this.buildSource());
    payload.put('component', 'nebula-logger');
    payload.put('group', request.recipient.LoggerNotificationRule__r.Name);
    payload.put('class', request.recipient.LoggerNotificationService__r.Name);
    payload.put('custom_details', this.buildCustomDetails(request));
    return payload;
  }

  @TestVisible
  private String buildSummary(LoggerNotifierRequest request) {
    Integer matchCount = request.matchingRecords.size();
    String noun = matchCount == 1 ? 'record' : 'records';
    String base = 'Nebula Logger: ' + request.recipient.LoggerNotificationRule__r.Name + ' - ' + matchCount + ' ' + noun + ' matched';
    SObject first = request.matchingRecords.get(0);
    String firstMessage = this.tryGetString(first, 'Message__c');
    if (String.isNotBlank(firstMessage)) {
      return (base + ' - ' + firstMessage)?.abbreviate(1024);
    }
    return base?.abbreviate(1024);
  }

  @TestVisible
  private String severityFor(List<SObject> records) {
    Boolean hasError = false;
    Boolean hasWarn = false;
    for (SObject record : records) {
      String level = this.tryGetString(record, 'LoggingLevel__c');
      if (level == System.LoggingLevel.ERROR.name()) {
        hasError = true;
      } else if (level == 'WARN') {
        hasWarn = true;
      }
    }
    if (hasError) {
      return 'error';
    }
    if (hasWarn) {
      return 'warning';
    }
    return 'info';
  }

  private String buildSource() {
    return 'salesforce:' + System.UserInfo.getOrganizationId();
  }

  private Map<String, Object> buildCustomDetails(LoggerNotifierRequest request) {
    Map<String, Object> details = new Map<String, Object>();
    details.put('rule', request.recipient.LoggerNotificationRule__r.Name);
    details.put('ruleId', request.recipient.LoggerNotificationRule__r.Id);
    details.put('filter', request.recipient.LoggerNotificationRule__r.SourceSObjectFilter__c);
    details.put('matchCount', request.matchingRecords.size());
    List<Map<String, Object>> recordSummaries = new List<Map<String, Object>>();
    for (SObject record : request.matchingRecords) {
      Map<String, Object> summary = new Map<String, Object>();
      Id recordId = (Id) record.get('Id');
      if (recordId != null) {
        summary.put('id', recordId);
      }
      String loggingLevel = this.tryGetString(record, 'LoggingLevel__c');
      if (String.isNotBlank(loggingLevel)) {
        summary.put('loggingLevel', loggingLevel);
      }
      String message = this.tryGetString(record, 'Message__c');
      if (String.isNotBlank(message)) {
        summary.put('message', message?.abbreviate(500));
      }
      recordSummaries.add(summary);
    }
    details.put('records', recordSummaries);
    return details;
  }

  private List<Map<String, Object>> buildLinks(LoggerNotifierRequest request) {
    List<Map<String, Object>> links = new List<Map<String, Object>>();
    for (SObject record : request.matchingRecords) {
      Id recordId = (Id) record.get('Id');
      if (recordId == null) {
        continue;
      }
      links.add(new Map<String, Object>{ 'href' => System.URL.getOrgDomainUrl().toExternalForm() + '/' + recordId, 'text' => 'Log Record ' + recordId });
    }
    return links;
  }

  private Id firstRecordIdOrNull(List<SObject> records) {
    for (SObject record : records) {
      Id recordId = (Id) record.get('Id');
      if (recordId != null) {
        return recordId;
      }
    }
    return null;
  }

  private String tryGetString(SObject record, String fieldName) {
    Map<String, Schema.SObjectField> fields = record.getSObjectType().getDescribe().fields.getMap();
    if (fields.containsKey(fieldName.toLowerCase()) == false) {
      return null;
    }
    Object value = record.get(fieldName);
    return value == null ? null : String.valueOf(value);
  }

  private String tryGetConfigString(Map<String, Object> config, String key) {
    Object value = config.get(key);
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
        Logger.warn('PagerDutyLoggerNotifier - failed to parse ConfigurationJson__c, ignoring', ex);
      }
      return new Map<String, Object>();
    }
  }
}
