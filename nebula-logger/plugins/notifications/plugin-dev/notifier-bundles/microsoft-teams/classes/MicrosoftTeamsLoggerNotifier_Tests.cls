//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class MicrosoftTeamsLoggerNotifier_Tests {
  @IsTest
  static void it_should_short_circuit_when_context_is_null_or_has_no_records() {
    MicrosoftTeamsLoggerNotifier notifier = new MicrosoftTeamsLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(null);
    notifier.sendNotification(
      new LoggerNotifierRequest(new LoggerNotificationRule__c(), new LoggerNotificationRecipient__c(), new LoggerNotificationService__c(), null)
    );

    System.Assert.isNull(calloutMock.request);
  }

  @IsTest
  static void it_should_skip_delivery_when_service_has_no_endpoint() {
    MicrosoftTeamsLoggerNotifier notifier = new MicrosoftTeamsLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(buildRequest(null, null));

    System.Assert.isNull(calloutMock.request);
  }

  @IsTest
  static void it_should_post_to_webhook_url() {
    MicrosoftTeamsLoggerNotifier notifier = new MicrosoftTeamsLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(buildRequest('https://outlook.office.com/webhook/xyz', null));

    System.Assert.areEqual('https://outlook.office.com/webhook/xyz', calloutMock.request.getEndpoint());
    System.Assert.areEqual('POST', calloutMock.request.getMethod());
    System.Assert.areEqual('application/json', calloutMock.request.getHeader('Content-Type'));
  }

  @IsTest
  static void it_should_route_through_named_credential_when_configured() {
    MicrosoftTeamsLoggerNotifier notifier = new MicrosoftTeamsLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(buildRequest(null, 'TeamsWebhook'));

    System.Assert.areEqual('callout:TeamsWebhook', calloutMock.request.getEndpoint());
  }

  @IsTest
  static void it_should_build_an_adaptive_card_envelope() {
    MicrosoftTeamsLoggerNotifier notifier = new MicrosoftTeamsLoggerNotifier();

    String payload = notifier.buildPayload(buildRequest('https://outlook.office.com/webhook/xyz', null));

    System.Assert.isTrue(payload.contains('application/vnd.microsoft.card.adaptive'), 'Payload should declare adaptive card content type');
    System.Assert.isTrue(payload.contains('AdaptiveCard'), 'Payload should include AdaptiveCard type');
    System.Assert.isTrue(payload.contains('adaptive-card.json'), 'Payload should reference the adaptive card schema');
  }

  @IsTest
  static void it_should_color_error_records_attention() {
    MicrosoftTeamsLoggerNotifier notifier = new MicrosoftTeamsLoggerNotifier();

    String error = notifier.overallColor(new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') });
    String warn = notifier.overallColor(new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'WARN') });
    String info = notifier.overallColor(new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'INFO') });

    System.Assert.areEqual(MicrosoftTeamsLoggerNotifier.COLOR_ATTENTION, error);
    System.Assert.areEqual(MicrosoftTeamsLoggerNotifier.COLOR_WARNING, warn);
    System.Assert.areEqual(MicrosoftTeamsLoggerNotifier.COLOR_GOOD, info);
  }

  @IsTest
  static void it_should_prefer_attention_when_any_record_is_error() {
    MicrosoftTeamsLoggerNotifier notifier = new MicrosoftTeamsLoggerNotifier();
    List<SObject> mixed = new List<SObject>{
      new LogEntry__c(LoggingLevel__c = 'INFO'),
      new LogEntry__c(LoggingLevel__c = 'ERROR'),
      new LogEntry__c(LoggingLevel__c = 'WARN')
    };

    String color = notifier.overallColor(mixed);

    System.Assert.areEqual(MicrosoftTeamsLoggerNotifier.COLOR_ATTENTION, color);
  }

  private static LoggerNotifierRequest buildRequest(String webhookUrl, String namedCredentialDeveloperName) {
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(Name = 'Test rule', SourceSObjectType__c = 'LogEntry__c');
    LoggerNotificationService__c service = new LoggerNotificationService__c(
      Name = 'Teams',
      NotifierApexClassName__c = 'MicrosoftTeamsLoggerNotifier',
      IsEnabled__c = true,
      WebhookUrl__c = webhookUrl,
      NamedCredentialDeveloperName__c = namedCredentialDeveloperName
    );
    List<SObject> matchingRecords = new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR', Message__c = 'Something went wrong') };
    return new LoggerNotifierRequest(rule, new LoggerNotificationRecipient__c(), service, matchingRecords);
  }
}
