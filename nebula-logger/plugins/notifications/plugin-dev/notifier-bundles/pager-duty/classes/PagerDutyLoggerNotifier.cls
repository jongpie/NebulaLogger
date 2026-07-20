//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Delivers a `LoggerNotifiableContext` to PagerDuty via the Events API v2.
 *              Endpoint defaults to `https://events.pagerduty.com/v2/enqueue`, or the recipient's
 *              `WebhookUrl__c`, or `callout:<NamedCredentialDeveloperName__c>/v2/enqueue` if set.
 *
 *              PagerDuty routing key must be supplied via `ConfigurationJson__c`:
 *                {
 *                  "routingKey": "<32-char integration key>",
 *                  "eventAction": "trigger" | "acknowledge" | "resolve"  // default "trigger"
 *                }
 */
public without sharing class PagerDutyLoggerNotifier implements LoggerNotifiable {
  @TestVisible
  private static final String DEFAULT_ENDPOINT = 'https://events.pagerduty.com/v2/enqueue';
  private static final String DEFAULT_EVENT_ACTION = 'trigger';

  /**
   * @description Called by `LoggerNotifierAsyncDispatcher` in an async, callout-legal context.
   * @param context The rule + recipient + service + matching records to deliver.
   */
  public LoggerNotifiableResult sendNotification(LoggerNotifiableContext context) {
    if (context == null || context.recipient == null || context.matchingRecords == null || context.matchingRecords.isEmpty()) {
      return null;
    }
    Map<String, Object> config = this.parseConfiguration(context.recipient.ConfigurationJson__c);
    String routingKey = this.tryGetConfigString(config, 'routingKey');
    if (String.isBlank(routingKey)) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('PagerDutyLoggerNotifier - ConfigurationJson__c must set routingKey; skipping');
      }
      LoggerNotifiableResult skipped = new LoggerNotifiableResult();
      skipped.status = LoggerNotifiableResult.STATUS_SKIPPED;
      skipped.errorMessage = 'routingKey missing from ConfigurationJson__c';
      return skipped;
    }
    System.HttpRequest request = this.buildRequest(context);
    request.setBody(this.buildPayload(context, routingKey, this.tryGetConfigString(config, 'eventAction')));
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('PagerDutyLoggerNotifier - sending Events API v2 payload').setHttpRequestDetails(request);
    }
    System.HttpResponse response = new System.Http().send(request);
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('PagerDutyLoggerNotifier - response received').setHttpResponseDetails(response);
    }
    // See Backlog.md: notifier-side Logger.saveLog() re-fires the notifications plugin trigger; commented out for now.
    // Logger.saveLog();
    return LoggerNotifiableResult.fromHttpRequestAndResponse(request, response, new List<String>{ 'Content-Type', 'Accept' });
  }

  @TestVisible
  private System.HttpRequest buildRequest(LoggerNotifiableContext context) {
    String endpoint;
    if (String.isNotBlank(context.service.NamedCredentialDeveloperName__c)) {
      endpoint = 'callout:' + context.service.NamedCredentialDeveloperName__c + '/v2/enqueue';
    } else if (String.isNotBlank(context.service.WebhookUrl__c)) {
      endpoint = context.service.WebhookUrl__c;
    } else {
      endpoint = DEFAULT_ENDPOINT;
    }
    System.HttpRequest request = new System.HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('Accept', 'application/json');
    return request;
  }

  @TestVisible
  private String buildPayload(LoggerNotifiableContext context, String routingKey, String eventAction) {
    Map<String, Object> envelope = new Map<String, Object>();
    envelope.put('routing_key', routingKey);
    envelope.put('event_action', String.isNotBlank(eventAction) ? eventAction : DEFAULT_EVENT_ACTION);
    envelope.put('dedup_key', this.buildDedupKey(context));
    envelope.put('payload', this.buildEventPayload(context));
    envelope.put('links', this.buildLinks(context));
    return System.JSON.serialize(envelope, true);
  }

  @TestVisible
  private String buildDedupKey(LoggerNotifiableContext context) {
    Id firstMatchId = this.firstRecordIdOrNull(context.matchingRecords);
    String rulePart = context.notificationRule.Id != null ? String.valueOf(context.notificationRule.Id) : context.notificationRule.Name;
    String recordPart = firstMatchId != null ? String.valueOf(firstMatchId) : String.valueOf(context.matchingRecords.size());
    return 'nebula-logger:' + rulePart + ':' + recordPart;
  }

  private Map<String, Object> buildEventPayload(LoggerNotifiableContext context) {
    Map<String, Object> payload = new Map<String, Object>();
    payload.put('summary', this.buildSummary(context));
    payload.put('severity', this.severityFor(context.matchingRecords));
    payload.put('source', this.buildSource());
    payload.put('component', 'nebula-logger');
    payload.put('group', context.notificationRule.Name);
    payload.put('class', context.service?.Name);
    payload.put('custom_details', this.buildCustomDetails(context));
    return payload;
  }

  @TestVisible
  private String buildSummary(LoggerNotifiableContext context) {
    Integer matchCount = context.matchingRecords.size();
    String noun = matchCount == 1 ? 'record' : 'records';
    String base = 'Nebula Logger: ' + context.notificationRule.Name + ' - ' + matchCount + ' ' + noun + ' matched';
    SObject first = context.matchingRecords.get(0);
    String firstMessage = this.tryGetString(first, 'Message__c');
    if (String.isNotBlank(firstMessage)) {
      return this.truncate(base + ' - ' + firstMessage, 1024);
    }
    return this.truncate(base, 1024);
  }

  @TestVisible
  private String severityFor(List<SObject> records) {
    Boolean hasError = false;
    Boolean hasWarn = false;
    for (SObject record : records) {
      String level = this.tryGetString(record, 'LoggingLevel__c');
      if (level == 'ERROR') {
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

  private Map<String, Object> buildCustomDetails(LoggerNotifiableContext context) {
    Map<String, Object> details = new Map<String, Object>();
    details.put('rule', context.notificationRule.Name);
    details.put('ruleId', context.notificationRule.Id);
    details.put('filter', context.notificationRule.SourceSObjectFilter__c);
    details.put('matchCount', context.matchingRecords.size());
    List<Map<String, Object>> recordSummaries = new List<Map<String, Object>>();
    for (SObject record : context.matchingRecords) {
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
        summary.put('message', this.truncate(message, 500));
      }
      recordSummaries.add(summary);
    }
    details.put('records', recordSummaries);
    return details;
  }

  private List<Map<String, Object>> buildLinks(LoggerNotifiableContext context) {
    List<Map<String, Object>> links = new List<Map<String, Object>>();
    for (SObject record : context.matchingRecords) {
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

  private String truncate(String value, Integer maxLength) {
    if (value == null || value.length() <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength - 3) + '...';
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
