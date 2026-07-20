//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Delivers a `LoggerNotifierRequest` to a Google Chat space using an
 *              Incoming Webhook (or a Named Credential fronting one). Uses the Card v2 payload
 *              format under the `cardsV2` field.
 */
public without sharing class GoogleChatLoggerNotifier implements LoggerNotifier {
  /**
   * @description Called by `LoggerNotificationAsyncDispatcher` in an async, callout-legal context.
   * @param request The rule + recipient + service + matching records to deliver.
   */
  public LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
    if (request == null || request.recipient == null || request.matchingRecords == null || request.matchingRecords.isEmpty()) {
      return null;
    }
    System.HttpRequest httpRequest = this.buildRequest(request);
    if (httpRequest == null) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('GoogleChatLoggerNotifier - service has neither Webhook URL nor Named Credential; skipping');
      }
      LoggerNotifierResult skipped = new LoggerNotifierResult();
      skipped.status = LoggerNotifierResult.STATUS_SKIPPED;
      skipped.errorMessage = 'Service has neither Webhook URL nor Named Credential configured';
      return skipped;
    }
    httpRequest.setBody(this.buildPayload(request));
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('GoogleChatLoggerNotifier - sending payload').setHttpRequestDetails(httpRequest);
    }
    System.HttpResponse response = new System.Http().send(httpRequest);
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.finest('GoogleChatLoggerNotifier - response received').setHttpResponseDetails(response);
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
    httpRequest.setHeader('Content-Type', 'application/json; charset=UTF-8');
    return httpRequest;  }

  @TestVisible
  private String buildPayload(LoggerNotifierRequest request) {
    Map<String, Object> envelope = new Map<String, Object>();
    envelope.put('text', 'Nebula Logger: ' + request.notificationRule.Name + ' - ' + request.matchingRecords.size() + ' record(s) matched');
    envelope.put('cardsV2', new List<Map<String, Object>>{ this.buildCard(request) });
    return System.JSON.serialize(envelope, true);
  }

  private Map<String, Object> buildCard(LoggerNotifierRequest request) {
    List<Map<String, Object>> sections = new List<Map<String, Object>>();
    for (SObject record : request.matchingRecords) {
      sections.add(this.buildSection(record));
    }
    return new Map<String, Object>{
      'cardId' => 'nebula-logger-notification',
      'card' => new Map<String, Object>{
        'header' => new Map<String, Object>{ 'title' => request.notificationRule.Name, 'subtitle' => request.matchingRecords.size() + ' record(s) matched' },
        'sections' => sections
      }
    };
  }

  private Map<String, Object> buildSection(SObject record) {
    List<Map<String, Object>> widgets = new List<Map<String, Object>>();
    this.addWidgetIfPresent(widgets, 'Logging Level', this.tryGetString(record, 'LoggingLevel__c'));
    this.addWidgetIfPresent(widgets, 'Origin', this.tryGetString(record, 'Origin__c'));
    this.addWidgetIfPresent(widgets, 'Message', this.truncate(this.tryGetString(record, 'Message__c'), 1000));
    this.addWidgetIfPresent(widgets, 'Exception Type', this.tryGetString(record, 'ExceptionType__c'));
    Id recordId = (Id) record.get('Id');
    if (recordId != null) {
      String url = System.URL.getOrgDomainUrl().toExternalForm() + '/' + recordId;
      widgets.add(
        new Map<String, Object>{ 'decoratedText' => new Map<String, Object>{ 'topLabel' => 'Link', 'text' => '<a href="' + url + '">Open record</a>' } }
      );
    }
    return new Map<String, Object>{ 'widgets' => widgets };
  }

  private void addWidgetIfPresent(List<Map<String, Object>> widgets, String label, String value) {
    if (String.isNotBlank(value)) {
      widgets.add(new Map<String, Object>{ 'decoratedText' => new Map<String, Object>{ 'topLabel' => label, 'text' => value, 'wrapText' => true } });
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

  private String truncate(String value, Integer maxLength) {
    if (value == null || value.length() <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength) + '...(truncated)';
  }
}
