//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class OpenTelemetryLoggerNotifier_Tests {
  @IsTest
  static void it_should_short_circuit_when_context_is_null_or_has_no_records() {
    OpenTelemetryLoggerNotifier notifier = new OpenTelemetryLoggerNotifier();
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
    OpenTelemetryLoggerNotifier notifier = new OpenTelemetryLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(buildContext(null, null, new LoggerNotificationRecipient__c()));

    System.Assert.isNull(calloutMock.request);
  }

  @IsTest
  static void it_should_append_v1_logs_path_to_named_credential_endpoint() {
    OpenTelemetryLoggerNotifier notifier = new OpenTelemetryLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(buildContext(null, 'DatadogOtel', new LoggerNotificationRecipient__c()));

    System.Assert.areEqual('callout:DatadogOtel/v1/logs', calloutMock.request.getEndpoint());
    System.Assert.areEqual('POST', calloutMock.request.getMethod());
    System.Assert.areEqual('application/json', calloutMock.request.getHeader('Content-Type'));
  }

  @IsTest
  static void it_should_post_directly_to_webhook_url_without_appending_path() {
    OpenTelemetryLoggerNotifier notifier = new OpenTelemetryLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);

    notifier.sendNotification(buildContext('https://otel.example.com/v1/logs', null, new LoggerNotificationRecipient__c()));

    System.Assert.areEqual(
      'https://otel.example.com/v1/logs',
      calloutMock.request.getEndpoint(),
      'Webhook URL should be used as-is - admin sets the full path'
    );
  }

  @IsTest
  static void it_should_apply_custom_headers_from_configurationJson() {
    OpenTelemetryLoggerNotifier notifier = new OpenTelemetryLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"headers": {"DD-API-KEY": "abc123"}}');

    notifier.sendNotification(buildContext(null, 'DatadogOtel', recipient));

    System.Assert.areEqual('abc123', calloutMock.request.getHeader('DD-API-KEY'));
  }

  @IsTest
  static void it_should_include_resource_attribute_overrides_in_the_payload() {
    OpenTelemetryLoggerNotifier notifier = new OpenTelemetryLoggerNotifier();
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"resourceAttributes": {"service.name": "my-service", "deployment.environment": "prod"}}'
    );

    String payload = notifier.buildPayload(
      buildContext(null, 'DatadogOtel', recipient),
      new Map<String, Object>{ 'resourceAttributes' => new Map<String, Object>{ 'service.name' => 'my-service', 'deployment.environment' => 'prod' } }
    );

    System.Assert.isTrue(payload.contains('"service.name"'));
    System.Assert.isTrue(payload.contains('"my-service"'));
    System.Assert.isTrue(payload.contains('"deployment.environment"'));
  }

  @IsTest
  static void it_should_map_logging_levels_to_otel_severity_numbers() {
    OpenTelemetryLoggerNotifier notifier = new OpenTelemetryLoggerNotifier();

    System.Assert.areEqual(OpenTelemetryLoggerNotifier.SEVERITY_NUMBER_ERROR, notifier.severityNumberFor('ERROR'));
    System.Assert.areEqual(OpenTelemetryLoggerNotifier.SEVERITY_NUMBER_WARN, notifier.severityNumberFor('WARN'));
    System.Assert.areEqual(OpenTelemetryLoggerNotifier.SEVERITY_NUMBER_INFO, notifier.severityNumberFor('INFO'));
    System.Assert.areEqual(OpenTelemetryLoggerNotifier.SEVERITY_NUMBER_DEBUG, notifier.severityNumberFor('DEBUG'));
    System.Assert.areEqual(OpenTelemetryLoggerNotifier.SEVERITY_NUMBER_DEBUG, notifier.severityNumberFor('FINEST'));
    System.Assert.areEqual(OpenTelemetryLoggerNotifier.SEVERITY_NUMBER_INFO, notifier.severityNumberFor('SOMETHING_ELSE'));
    System.Assert.areEqual(OpenTelemetryLoggerNotifier.SEVERITY_NUMBER_INFO, notifier.severityNumberFor(null));
  }

  @IsTest
  static void it_should_build_a_well_formed_otlp_envelope() {
    OpenTelemetryLoggerNotifier notifier = new OpenTelemetryLoggerNotifier();

    String payload = notifier.buildPayload(
      buildContext('https://otel.example.com/v1/logs', null, new LoggerNotificationRecipient__c()),
      new Map<String, Object>()
    );

    System.Assert.isTrue(payload.contains('"resourceLogs"'), 'Payload should include resourceLogs');
    System.Assert.isTrue(payload.contains('"scopeLogs"'), 'Payload should include scopeLogs');
    System.Assert.isTrue(payload.contains('"logRecords"'), 'Payload should include logRecords');
    System.Assert.isTrue(payload.contains('"severityNumber"'), 'Payload should include severityNumber');
    System.Assert.isTrue(payload.contains('"severityText"'), 'Payload should include severityText');
    System.Assert.isTrue(payload.contains('"nebula-logger"'), 'Payload should include the scope name');
  }

  private static LoggerNotifiableContext buildContext(String webhookUrl, String namedCredentialDeveloperName, LoggerNotificationRecipient__c recipient) {
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(
      Name = 'Test rule',
      SourceSObjectType__c = 'LogEntry__c',
      SourceSObjectFilter__c = 'ISPICKVAL(LoggingLevel__c, \'ERROR\')'
    );
    LoggerNotificationService__c service = new LoggerNotificationService__c(
      Name = 'OpenTelemetry',
      NotifierApexClassName__c = 'OpenTelemetryLoggerNotifier',
      IsEnabled__c = true,
      WebhookUrl__c = webhookUrl,
      NamedCredentialDeveloperName__c = namedCredentialDeveloperName
    );
    List<SObject> matchingRecords = new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR', Message__c = 'Something went wrong') };
    return new LoggerNotifiableContext(rule, recipient, service, matchingRecords);
  }
}
