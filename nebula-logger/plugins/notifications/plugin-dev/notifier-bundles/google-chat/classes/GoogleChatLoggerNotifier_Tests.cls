//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class GoogleChatLoggerNotifier_Tests {
  @IsTest
  static void it_should_short_circuit_when_context_is_null_or_has_no_records() {
    GoogleChatLoggerNotifier notifier = new GoogleChatLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(null);
    notifier.sendNotification(
      new LoggerNotifiableContext(
        new LoggerNotificationRule__c(),
        new LoggerNotificationRecipient__c(),
        new LoggerNotificationService__c(),
        new List<SObject>()
      )
    );

    System.Assert.isNull(calloutMock.request);
  }

  @IsTest
  static void it_should_skip_delivery_when_service_has_no_endpoint() {
    GoogleChatLoggerNotifier notifier = new GoogleChatLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(buildContext(null, null));

    System.Assert.isNull(calloutMock.request);
  }

  @IsTest
  static void it_should_post_to_webhook_url() {
    GoogleChatLoggerNotifier notifier = new GoogleChatLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(buildContext('https://chat.googleapis.com/v1/spaces/xyz/messages?key=abc&token=def', null));

    System.Assert.areEqual('https://chat.googleapis.com/v1/spaces/xyz/messages?key=abc&token=def', calloutMock.request.getEndpoint());
    System.Assert.areEqual('POST', calloutMock.request.getMethod());
    System.Assert.isTrue(calloutMock.request.getHeader('Content-Type').startsWith('application/json'));
  }

  @IsTest
  static void it_should_route_through_named_credential_when_configured() {
    GoogleChatLoggerNotifier notifier = new GoogleChatLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(buildContext(null, 'GoogleChatWebhook'));

    System.Assert.areEqual('callout:GoogleChatWebhook', calloutMock.request.getEndpoint());
  }

  @IsTest
  static void it_should_build_a_cardsV2_envelope() {
    GoogleChatLoggerNotifier notifier = new GoogleChatLoggerNotifier();

    String payload = notifier.buildPayload(buildContext('https://chat.googleapis.com/v1/spaces/xyz', null));

    System.Assert.isTrue(payload.contains('cardsV2'), 'Payload should include cardsV2 field: ' + payload);
    System.Assert.isTrue(payload.contains('"text"'), 'Payload should include text field: ' + payload);
    System.Assert.isTrue(payload.contains('nebula-logger-notification'), 'Payload should include cardId: ' + payload);
    System.Assert.isTrue(payload.contains('"widgets"'), 'Payload should include widgets: ' + payload);
  }

  private static LoggerNotifiableContext buildContext(String webhookUrl, String namedCredentialDeveloperName) {
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(Name = 'Test rule', SourceSObjectType__c = 'LogEntry__c');
    LoggerNotificationService__c service = new LoggerNotificationService__c(
      Name = 'Google Chat',
      NotifierApexClassName__c = 'GoogleChatLoggerNotifier',
      IsEnabled__c = true,
      WebhookUrl__c = webhookUrl,
      NamedCredentialDeveloperName__c = namedCredentialDeveloperName
    );
    List<SObject> matchingRecords = new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR', Message__c = 'boom') };
    return new LoggerNotifiableContext(rule, new LoggerNotificationRecipient__c(), service, matchingRecords);
  }
}
