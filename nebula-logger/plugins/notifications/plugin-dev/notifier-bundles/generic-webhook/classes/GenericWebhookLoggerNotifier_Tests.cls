//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class GenericWebhookLoggerNotifier_Tests {
  @IsTest
  static void it_should_short_circuit_when_context_is_null_or_has_no_records() {
    GenericWebhookLoggerNotifier notifier = new GenericWebhookLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(null);
    notifier.sendNotification(
      new LoggerNotifierRequest(new LoggerNotificationRule__c(), new LoggerNotificationRecipient__c(), new LoggerNotificationService__c(), null)
    );
    notifier.sendNotification(
      new LoggerNotifierRequest(
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
    GenericWebhookLoggerNotifier notifier = new GenericWebhookLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(buildRequest(null, null, new LoggerNotificationRecipient__c()));

    System.Assert.isNull(calloutMock.request);
  }

  @IsTest
  static void it_should_post_to_the_webhook_url_by_default() {
    GenericWebhookLoggerNotifier notifier = new GenericWebhookLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(buildRequest('https://example.com/hook/abc', null, new LoggerNotificationRecipient__c()));

    System.Assert.areEqual('https://example.com/hook/abc', calloutMock.request.getEndpoint());
    System.Assert.areEqual('POST', calloutMock.request.getMethod());
    System.Assert.areEqual('application/json', calloutMock.request.getHeader('Content-Type'));
  }

  @IsTest
  static void it_should_route_through_a_named_credential_when_configured() {
    GenericWebhookLoggerNotifier notifier = new GenericWebhookLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(buildRequest(null, 'MyServiceApi', new LoggerNotificationRecipient__c()));

    System.Assert.areEqual('callout:MyServiceApi', calloutMock.request.getEndpoint());
  }

  @IsTest
  static void it_should_append_path_from_configurationJson_to_the_named_credential_endpoint() {
    GenericWebhookLoggerNotifier notifier = new GenericWebhookLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"path": "/v1/events"}');

    notifier.sendNotification(buildRequest(null, 'MyServiceApi', recipient));

    System.Assert.areEqual('callout:MyServiceApi/v1/events', calloutMock.request.getEndpoint());
  }

  @IsTest
  static void it_should_override_method_when_supplied_in_configurationJson() {
    GenericWebhookLoggerNotifier notifier = new GenericWebhookLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"method": "put"}');

    notifier.sendNotification(buildRequest('https://example.com/hook', null, recipient));

    System.Assert.areEqual('PUT', calloutMock.request.getMethod());
  }

  @IsTest
  static void it_should_apply_custom_headers_from_configurationJson() {
    GenericWebhookLoggerNotifier notifier = new GenericWebhookLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"headers": {"X-Api-Token": "secret", "X-Environment": "prod"}}'
    );

    notifier.sendNotification(buildRequest('https://example.com/hook', null, recipient));

    System.Assert.areEqual('secret', calloutMock.request.getHeader('X-Api-Token'));
    System.Assert.areEqual('prod', calloutMock.request.getHeader('X-Environment'));
  }

  @IsTest
  static void it_should_still_post_when_configurationJson_is_malformed() {
    GenericWebhookLoggerNotifier notifier = new GenericWebhookLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"not valid json');

    notifier.sendNotification(buildRequest('https://example.com/hook', null, recipient));

    System.Assert.isNotNull(calloutMock.request, 'A malformed config should not prevent delivery');
    System.Assert.areEqual('POST', calloutMock.request.getMethod());
  }

  @IsTest
  static void it_should_include_the_canonical_envelope_fields_in_the_payload() {
    GenericWebhookLoggerNotifier notifier = new GenericWebhookLoggerNotifier();

    String payload = notifier.buildPayload(buildRequest('https://example.com/hook', null, new LoggerNotificationRecipient__c()));

    System.Assert.isTrue(payload.contains('"ruleName"'), 'Payload should include ruleName: ' + payload);
    System.Assert.isTrue(payload.contains('"matchCount" : 2') || payload.contains('"matchCount":2'), 'Payload should include matchCount: ' + payload);
    System.Assert.isTrue(payload.contains('"matchingRecords"'), 'Payload should include matchingRecords: ' + payload);
    System.Assert.isTrue(payload.contains('"organizationId"'), 'Payload should include organizationId: ' + payload);
  }

  private static LoggerNotifierRequest buildRequest(String webhookUrl, String namedCredentialDeveloperName, LoggerNotificationRecipient__c recipient) {
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(
      Name = 'Test rule',
      SourceSObjectType__c = 'LogEntry__c',
      SourceSObjectFilter__c = 'ISPICKVAL(LoggingLevel__c, \'ERROR\')'
    );
    LoggerNotificationService__c service = new LoggerNotificationService__c(
      Name = 'Webhook',
      NotifierApexClassName__c = 'GenericWebhookLoggerNotifier',
      IsEnabled__c = true,
      WebhookUrl__c = webhookUrl,
      NamedCredentialDeveloperName__c = namedCredentialDeveloperName
    );
    List<SObject> matchingRecords = new List<SObject>{
      new LogEntry__c(LoggingLevel__c = 'ERROR', Message__c = 'first'),
      new LogEntry__c(LoggingLevel__c = 'ERROR', Message__c = 'second')
    };
    return new LoggerNotifierRequest(rule, recipient, service, matchingRecords);
  }
}
