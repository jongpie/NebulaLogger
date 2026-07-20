//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Delivers a `LoggerNotifiableContext` to a Microsoft Teams channel using an
 *              Incoming Webhook (or a Named Credential fronting one). The payload is a Teams
 *              Adaptive Card 1.4 wrapped in the `attachments` envelope Teams expects.
 */
public without sharing class MicrosoftTeamsLoggerNotifier implements LoggerNotifiable {
  @TestVisible
  private static final String COLOR_ATTENTION = 'attention';
  @TestVisible
  private static final String COLOR_WARNING = 'warning';
  @TestVisible
  private static final String COLOR_GOOD = 'good';
  @TestVisible
  private static final String COLOR_DEFAULT = 'default';

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
        Logger.warn('MicrosoftTeamsLoggerNotifier - service has neither Webhook URL nor Named Credential; skipping');
      }
      LoggerNotifiableResult skipped = new LoggerNotifiableResult();
      skipped.status = LoggerNotifiableResult.STATUS_SKIPPED;
      skipped.errorMessage = 'Service has neither Webhook URL nor Named Credential configured';
      return skipped;
    }
    request.setBody(this.buildPayload(context));
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('MicrosoftTeamsLoggerNotifier - sending payload').setHttpRequestDetails(request);
    }
    System.HttpResponse response = new System.Http().send(request);
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('MicrosoftTeamsLoggerNotifier - response received').setHttpResponseDetails(response);
    }
    // See Backlog.md: notifier-side Logger.saveLog() re-fires the notifications plugin trigger; commented out for now.
    // Logger.saveLog();
    return LoggerNotifiableResult.fromHttpRequestAndResponse(request, response, new List<String>{ 'Content-Type' });
  }

  private System.HttpRequest buildRequest(LoggerNotifiableContext context) {
    String endpoint;
    if (String.isNotBlank(context.service.NamedCredentialDeveloperName__c)) {
      endpoint = 'callout:' + context.service.NamedCredentialDeveloperName__c;
    } else if (String.isNotBlank(context.service.WebhookUrl__c)) {
      endpoint = context.service.WebhookUrl__c;
    } else {
      return null;
    }
    System.HttpRequest request = new System.HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');
    return request;
  }

  @TestVisible
  private String buildPayload(LoggerNotifiableContext context) {
    List<Map<String, Object>> attachments = new List<Map<String, Object>>();
    attachments.add(
      new Map<String, Object>{ 'contentType' => 'application/vnd.microsoft.card.adaptive', 'contentUrl' => null, 'content' => this.buildAdaptiveCard(context) }
    );
    Map<String, Object> envelope = new Map<String, Object>{ 'type' => 'message', 'attachments' => attachments };
    return System.JSON.serialize(envelope, true);
  }

  private Map<String, Object> buildAdaptiveCard(LoggerNotifiableContext context) {
    List<Map<String, Object>> body = new List<Map<String, Object>>();
    body.add(
      new Map<String, Object>{
        'type' => 'TextBlock',
        'size' => 'Large',
        'weight' => 'Bolder',
        'color' => this.overallColor(context.matchingRecords),
        'text' => 'Nebula Logger: ' + context.notificationRule.Name
      }
    );
    body.add(
      new Map<String, Object>{ 'type' => 'TextBlock', 'spacing' => 'None', 'isSubtle' => true, 'text' => context.matchingRecords.size() + ' record(s) matched' }
    );
    for (SObject record : context.matchingRecords) {
      body.add(this.buildRecordFactSet(record));
    }
    return new Map<String, Object>{
      'type' => 'AdaptiveCard',
      '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
      'version' => '1.4',
      'body' => body
    };
  }

  private Map<String, Object> buildRecordFactSet(SObject record) {
    List<Map<String, Object>> facts = new List<Map<String, Object>>();
    this.addFactIfPresent(facts, 'Logging Level', this.tryGetString(record, 'LoggingLevel__c'));
    this.addFactIfPresent(facts, 'Origin', this.tryGetString(record, 'Origin__c'));
    this.addFactIfPresent(facts, 'Message', this.truncate(this.tryGetString(record, 'Message__c'), 500));
    this.addFactIfPresent(facts, 'Exception Type', this.tryGetString(record, 'ExceptionType__c'));
    Id recordId = (Id) record.get('Id');
    if (recordId != null) {
      this.addFactIfPresent(facts, 'Link', System.URL.getOrgDomainUrl().toExternalForm() + '/' + recordId);
    }
    return new Map<String, Object>{ 'type' => 'FactSet', 'facts' => facts, 'separator' => true };
  }

  private void addFactIfPresent(List<Map<String, Object>> facts, String title, String value) {
    if (String.isNotBlank(value)) {
      facts.add(new Map<String, Object>{ 'title' => title, 'value' => value });
    }
  }

  @TestVisible
  private String overallColor(List<SObject> records) {
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
      return COLOR_ATTENTION;
    }
    if (hasWarn) {
      return COLOR_WARNING;
    }
    return COLOR_GOOD;
  }

  private String tryGetString(SObject record, String fieldName) {
    Map<String, Schema.SObjectField> fields = record.getSObjectType().getDescribe().fields.getMap();
    if (fields.containsKey(fieldName.toLowerCase()) == false) {
      return null;
    }
    Object value = record.get(fieldName);
    return value == null ? null : String.valueOf(value);
  }

  private String truncate(String value, Integer maxLength) {
    if (value == null || value.length() <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength) + '...(truncated)';
  }
}
