//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Delivers a `LoggerNotifierRequest` to a Microsoft Teams channel using an
 *              Incoming Webhook (or a Named Credential fronting one). The payload is a Teams
 *              Adaptive Card 1.4 wrapped in the `attachments` envelope Teams expects.
 */
public without sharing class MicrosoftTeamsLoggerNotifier extends LoggerNotifier {
  @TestVisible
  private static final String COLOR_ATTENTION = 'attention';
  @TestVisible
  private static final String COLOR_WARNING = 'warning';
  @TestVisible
  private static final String COLOR_GOOD = 'good';
  @TestVisible
  private static final String COLOR_DEFAULT = 'default';

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
        Logger.warn('MicrosoftTeamsLoggerNotifier - service has neither Webhook URL nor Named Credential; skipping');
      }
      LoggerNotifierResult skipped = new LoggerNotifierResult();
      skipped.status = LoggerNotifierResult.STATUS_SKIPPED;
      skipped.errorMessage = 'Service has neither Webhook URL nor Named Credential configured';
      return skipped;
    }
    httpRequest.setBody(this.buildPayload(request));
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('MicrosoftTeamsLoggerNotifier - sending payload').setHttpRequestDetails(httpRequest);
    }
    System.HttpResponse response = new System.Http().send(httpRequest);
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('MicrosoftTeamsLoggerNotifier - response received').setHttpResponseDetails(response);
    }
    // See Backlog.md: notifier-side Logger.saveLog() re-fires the notifications plugin trigger; commented out for now.
    // Logger.saveLog();
    return new LoggerNotifierResult(httpRequest, response, new List<String>{ 'Content-Type' });
  }

  private System.HttpRequest buildRequest(LoggerNotifierRequest request) {
    String endpoint;
    if (String.isNotBlank(request.service.NamedCredentialDeveloperName__c)) {
      endpoint = 'callout:' + request.service.NamedCredentialDeveloperName__c;
    } else if (String.isNotBlank(request.service.WebhookUrl__c)) {
      endpoint = request.service.WebhookUrl__c;
    } else {
      return null;
    }
    System.HttpRequest httpRequest = new System.HttpRequest();
    httpRequest.setEndpoint(endpoint);
    httpRequest.setMethod('POST');
    httpRequest.setHeader('Content-Type', 'application/json');
    return httpRequest;
  }

  @TestVisible
  private String buildPayload(LoggerNotifierRequest request) {
    List<Map<String, Object>> attachments = new List<Map<String, Object>>();
    attachments.add(
      new Map<String, Object>{ 'contentType' => 'application/vnd.microsoft.card.adaptive', 'contentUrl' => null, 'content' => this.buildAdaptiveCard(request) }
    );
    Map<String, Object> envelope = new Map<String, Object>{ 'type' => 'message', 'attachments' => attachments };
    return System.JSON.serialize(envelope, true);
  }

  private Map<String, Object> buildAdaptiveCard(LoggerNotifierRequest request) {
    List<Map<String, Object>> body = new List<Map<String, Object>>();
    body.add(
      new Map<String, Object>{
        'type' => 'TextBlock',
        'size' => 'Large',
        'weight' => 'Bolder',
        'color' => this.overallColor(request.matchingRecords),
        'text' => 'Nebula Logger: ' + request.notificationRule.Name
      }
    );
    body.add(
      new Map<String, Object>{ 'type' => 'TextBlock', 'spacing' => 'None', 'isSubtle' => true, 'text' => request.matchingRecords.size() + ' record(s) matched' }
    );
    for (SObject record : request.matchingRecords) {
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
    this.addFactIfPresent(facts, 'Message', this.tryGetString(record, 'Message__c')?.abbreviate(500));
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
}
