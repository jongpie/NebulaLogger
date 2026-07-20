//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class PagerDutyLoggerNotifier_Tests {
  @IsTest
  static void it_should_short_circuit_when_context_is_null_or_has_no_records() {
    PagerDutyLoggerNotifier notifier = new PagerDutyLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(202);
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
  static void it_should_skip_delivery_when_routing_key_is_missing() {
    PagerDutyLoggerNotifier notifier = new PagerDutyLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(202);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    LoggerNotifiableContext context = buildContext(null, null, new LoggerNotificationRecipient__c());

    notifier.sendNotification(context);

    System.Assert.isNull(calloutMock.request, 'No callout should be made without a routing key');
  }

  @IsTest
  static void it_should_post_to_default_endpoint_with_routing_key_from_config() {
    PagerDutyLoggerNotifier notifier = new PagerDutyLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(202);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    LoggerNotifiableContext context = buildContext(null, null, new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"routingKey": "abc123"}'));

    notifier.sendNotification(context);

    System.Assert.areEqual(PagerDutyLoggerNotifier.DEFAULT_ENDPOINT, calloutMock.request.getEndpoint());
    System.Assert.areEqual('POST', calloutMock.request.getMethod());
    System.Assert.areEqual('application/json', calloutMock.request.getHeader('Content-Type'));
    String body = calloutMock.request.getBody();
    System.Assert.isTrue(body.contains('"routing_key"') && body.contains('"abc123"'));
    System.Assert.isTrue(body.contains('"event_action"'));
    System.Assert.isTrue(body.contains('"trigger"'), 'Default event_action should be trigger');
  }

  @IsTest
  static void it_should_use_the_service_webhook_url_when_provided() {
    PagerDutyLoggerNotifier notifier = new PagerDutyLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(202);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    LoggerNotifiableContext context = buildContext(
      'https://proxy.example.com/pd',
      null,
      new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"routingKey": "abc"}')
    );

    notifier.sendNotification(context);

    System.Assert.areEqual('https://proxy.example.com/pd', calloutMock.request.getEndpoint());
  }

  @IsTest
  static void it_should_route_through_named_credential_when_configured() {
    PagerDutyLoggerNotifier notifier = new PagerDutyLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(202);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    LoggerNotifiableContext context = buildContext(null, 'PagerDutyEvents', new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"routingKey": "abc"}'));

    notifier.sendNotification(context);

    System.Assert.areEqual('callout:PagerDutyEvents/v2/enqueue', calloutMock.request.getEndpoint());
  }

  @IsTest
  static void it_should_map_severity_to_error_when_any_record_is_error() {
    PagerDutyLoggerNotifier notifier = new PagerDutyLoggerNotifier();

    String error = notifier.severityFor(new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') });
    String warn = notifier.severityFor(new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'WARN') });
    String info = notifier.severityFor(new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'INFO') });
    String mixed = notifier.severityFor(new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'INFO'), new LogEntry__c(LoggingLevel__c = 'ERROR') });

    System.Assert.areEqual('error', error);
    System.Assert.areEqual('warning', warn);
    System.Assert.areEqual('info', info);
    System.Assert.areEqual('error', mixed, 'Any ERROR should escalate the whole event');
  }

  @IsTest
  static void it_should_build_a_stable_dedup_key_from_rule_id_and_first_record_id() {
    PagerDutyLoggerNotifier notifier = new PagerDutyLoggerNotifier();
    Id ruleId = LoggerMockDataCreator.createId(Schema.LoggerNotificationRule__c.SObjectType);
    Id entryId = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType);
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(Id = ruleId, Name = 'r');
    List<SObject> records = new List<SObject>{ new LogEntry__c(Id = entryId, LoggingLevel__c = 'ERROR') };
    LoggerNotifiableContext context = new LoggerNotifiableContext(
      rule,
      new LoggerNotificationRecipient__c(),
      new LoggerNotificationService__c(Name = 'pd'),
      records
    );

    String key = notifier.buildDedupKey(context);

    System.Assert.isTrue(key.startsWith('nebula-logger:'));
    System.Assert.isTrue(key.contains(String.valueOf(ruleId)));
    System.Assert.isTrue(key.contains(String.valueOf(entryId)));
  }

  @IsTest
  static void it_should_use_a_custom_event_action_when_supplied() {
    PagerDutyLoggerNotifier notifier = new PagerDutyLoggerNotifier();
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(202);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    LoggerNotifiableContext context = buildContext(
      null,
      null,
      new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"routingKey": "abc", "eventAction": "resolve"}')
    );

    notifier.sendNotification(context);

    System.Assert.isTrue(calloutMock.request.getBody().contains('"resolve"'), 'Body should include the custom event_action');
  }

  @IsTest
  static void it_should_include_summary_severity_source_and_customDetails_in_payload() {
    PagerDutyLoggerNotifier notifier = new PagerDutyLoggerNotifier();
    LoggerNotifiableContext context = buildContext(null, null, new LoggerNotificationRecipient__c());

    String payload = notifier.buildPayload(context, 'abc', null);

    System.Assert.isTrue(payload.contains('"summary"'));
    System.Assert.isTrue(payload.contains('"severity"'));
    System.Assert.isTrue(payload.contains('"error"'), 'Severity should be error (ERROR record present)');
    System.Assert.isTrue(payload.contains('"source"'));
    System.Assert.isTrue(payload.contains('"custom_details"'));
    System.Assert.isTrue(payload.contains('"dedup_key"'));
    System.Assert.isTrue(payload.contains('Nebula Logger'));
  }

  private static LoggerNotifiableContext buildContext(String webhookUrl, String namedCredentialDeveloperName, LoggerNotificationRecipient__c recipient) {
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(
      Name = 'Prod ERROR alerts',
      SourceSObjectType__c = 'LogEntry__c',
      SourceSObjectFilter__c = 'ISPICKVAL(LoggingLevel__c, \'ERROR\')'
    );
    LoggerNotificationService__c service = new LoggerNotificationService__c(
      Name = 'PagerDuty',
      NotifierApexClassName__c = 'PagerDutyLoggerNotifier',
      IsEnabled__c = true,
      WebhookUrl__c = webhookUrl,
      NamedCredentialDeveloperName__c = namedCredentialDeveloperName
    );
    List<SObject> matchingRecords = new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR', Message__c = 'Something went wrong') };
    return new LoggerNotifiableContext(rule, recipient, service, matchingRecords);
  }
}
