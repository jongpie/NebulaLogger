//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class SlackLoggerNotifier_Tests {
  private static final String NOTIFICATION_COLOR_RED = '#FF7373';
  private static final String NOTIFICATION_COLOR_ORANGE = '#FFC873';
  private static final String NOTIFICATION_COLOR_GREEN = '#7CD197';

  @IsTest
  static void it_should_short_circuit_when_context_is_null_or_has_no_matching_records() {
    LoggerMockDataCreator.MockHttpCallout calloutMock = installCalloutMock();
    SlackLoggerNotifier notifier = new SlackLoggerNotifier();

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

    System.Assert.isNull(calloutMock.request, 'No callout should have been made');
  }

  @IsTest
  static void it_should_skip_delivery_when_service_has_no_endpoint_configured() {
    LoggerMockDataCreator.MockHttpCallout calloutMock = installCalloutMock();
    LoggerNotifierRequest request = buildRequest(buildService(null, null), new LoggerNotificationRecipient__c());

    new SlackLoggerNotifier().sendNotification(request);

    System.Assert.isNull(calloutMock.request, 'No callout should have been made when neither WebhookUrl__c nor NamedCredentialDeveloperName__c is set');
  }

  @IsTest
  static void it_should_send_a_callout_to_the_webhook_url() {
    LoggerMockDataCreator.MockHttpCallout calloutMock = installCalloutMock();
    LoggerNotifierRequest request = buildRequest(buildService('https://example.com/webhook/xyz', null), new LoggerNotificationRecipient__c());

    new SlackLoggerNotifier().sendNotification(request);

    System.Assert.isNotNull(calloutMock.request);
    System.Assert.areEqual('https://example.com/webhook/xyz', calloutMock.request.getEndpoint());
    System.Assert.areEqual('POST', calloutMock.request.getMethod());
    System.Assert.areEqual('application/json', calloutMock.request.getHeader('Content-Type'));
  }

  @IsTest
  static void it_should_route_through_the_named_credential_when_configured() {
    LoggerMockDataCreator.MockHttpCallout calloutMock = installCalloutMock();
    LoggerNotifierRequest request = buildRequest(buildService(null, 'SlackWebApi'), new LoggerNotificationRecipient__c(ChannelIdentifier__c = '#alerts'));

    new SlackLoggerNotifier().sendNotification(request);

    System.Assert.isNotNull(calloutMock.request);
    System.Assert.areEqual('callout:SlackWebApi/chat.postMessage', calloutMock.request.getEndpoint());
  }

  @IsTest
  static void it_should_include_channel_in_payload_when_using_named_credential_mode() {
    String payload = capturePayload(buildService(null, 'SlackWebApi'), new LoggerNotificationRecipient__c(ChannelIdentifier__c = '#alerts'));

    System.Assert.isTrue(payload.contains('"channel" : "#alerts"') || payload.contains('"channel":"#alerts"'), 'Payload should include channel: ' + payload);
  }

  @IsTest
  static void it_should_omit_channel_from_payload_when_using_webhook_mode() {
    String payload = capturePayload(buildService('https://example.com/hook', null), new LoggerNotificationRecipient__c(ChannelIdentifier__c = '#ignored'));

    System.Assert.isFalse(payload.contains('"channel"'), 'Webhook payload should not include a channel field: ' + payload);
  }

  @IsTest
  static void it_should_convert_isShort_field_to_short_in_json() {
    String payload = capturePayload(buildService('https://example.com/hook', null), new LoggerNotificationRecipient__c());

    System.Assert.isFalse(payload.contains('isShort'), 'JSON should not contain the Apex-side isShort field name: ' + payload);
    System.Assert.isTrue(payload.contains('"short"'), 'JSON should contain the Slack-side short field name: ' + payload);
  }

  @IsTest
  static void it_should_color_error_entries_red() {
    String payload = capturePayloadForLoggingLevel('ERROR');
    System.Assert.isTrue(payload.contains(NOTIFICATION_COLOR_RED), 'ERROR attachments should be red: ' + payload);
  }

  @IsTest
  static void it_should_color_warn_entries_orange() {
    String payload = capturePayloadForLoggingLevel('WARN');
    System.Assert.isTrue(payload.contains(NOTIFICATION_COLOR_ORANGE), 'WARN attachments should be orange: ' + payload);
  }

  @IsTest
  static void it_should_color_non_error_non_warn_entries_green() {
    String payload = capturePayloadForLoggingLevel('INFO');
    System.Assert.isTrue(payload.contains(NOTIFICATION_COLOR_GREEN), 'Non-error/non-warn attachments should be green: ' + payload);
  }

  @IsTest
  static void it_should_render_default_source_fields_when_recipient_has_no_config() {
    String payload = capturePayload(buildService('https://example.com/hook', null), new LoggerNotificationRecipient__c());

    // The default set includes LoggingLevel__c, Origin__c, Message__c, StackTrace__c, ExceptionType__c;
    // labels come from describe, so we assert the human-readable label appears rather than the API name.
    System.Assert.isTrue(payload.contains('Logging Level'), 'Payload should include the Logging Level label: ' + payload);
    System.Assert.isTrue(payload.contains('Message'), 'Payload should include the Message label: ' + payload);
    System.Assert.isTrue(payload.contains('Stack Trace'), 'Payload should include the Stack Trace label: ' + payload);
  }

  @IsTest
  static void it_should_render_only_configured_source_fields_when_recipient_supplies_them() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"sourceFields":["LoggingLevel__c"]}');

    String payload = capturePayload(buildService('https://example.com/hook', null), recipient);

    System.Assert.isTrue(payload.contains('Logging Level'), 'Payload should include the configured field label: ' + payload);
    System.Assert.isFalse(payload.contains('Stack Trace'), 'Payload should NOT include un-configured field labels: ' + payload);
    System.Assert.isFalse(payload.contains('"Message"'), 'Payload should NOT include un-configured field labels: ' + payload);
  }

  @IsTest
  static void it_should_render_no_source_fields_when_config_supplies_an_empty_list() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"sourceFields":[]}');

    String payload = capturePayload(buildService('https://example.com/hook', null), recipient);

    System.Assert.isFalse(payload.contains('Logging Level'), 'Payload should skip all source-record fields when the list is empty: ' + payload);
  }

  @IsTest
  static void it_should_fall_back_to_defaults_when_configuration_json_is_malformed() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = 'not json');

    String payload = capturePayload(buildService('https://example.com/hook', null), recipient);

    System.Assert.isTrue(payload.contains('Logging Level'), 'Malformed JSON should fall back to the default field set: ' + payload);
  }

  @IsTest
  static void it_should_render_long_text_area_fields_as_wide_and_scalars_as_half_width() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"sourceFields":["LoggingLevel__c","Message__c"]}');

    String payload = capturePayload(buildService('https://example.com/hook', null), recipient);

    // Message__c is a Long Text Area so it should render wide and inside a triple-backtick code block.
    // LoggingLevel__c is a Picklist (scalar) so it should render half-width wrapped in single backticks.
    System.Assert.isTrue(payload.contains('```Something went wrong```'), 'Long text fields should be wrapped in a triple-backtick code block: ' + payload);
    System.Assert.isTrue(payload.contains('`ERROR`'), 'Scalar fields should be wrapped in single backticks for inline code rendering: ' + payload);
  }

  @IsTest
  static void it_should_render_the_rule_name_as_a_slack_markdown_link_in_the_top_level_text() {
    LoggerNotifierRequest request = buildRequest(buildService('https://example.com/hook', null), new LoggerNotificationRecipient__c());

    String payload = sendAndCapture(request);

    // The top-level text field uses <url|text> mrkdwn syntax natively (no mrkdwn_in opt-in needed at that level).
    String expectedLinkSuffix = '|' + request.notificationRule.Name + '>';
    System.Assert.isTrue(payload.contains(expectedLinkSuffix), 'The rule should render as a Slack mrkdwn link ending with |<rule name>>: ' + payload);
    System.Assert.isTrue(payload.contains(request.notificationRule.Id), 'The link should point at the notification record Id: ' + payload);
    System.Assert.isFalse(payload.contains('"Rule"'), 'The rule should no longer appear as an attachment field: ' + payload);
  }

  @IsTest
  static void it_should_render_the_rule_name_as_plain_text_when_the_rule_has_no_id() {
    LoggerNotifierRequest request = new LoggerNotifierRequest(
      new LoggerNotificationRule__c(Name = 'In-memory rule'),
      new LoggerNotificationRecipient__c(),
      buildService('https://example.com/hook', null),
      new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') }
    );

    String payload = sendAndCapture(request);

    System.Assert.isTrue(payload.contains('In-memory rule'), 'A rule without an Id should still render its name in the top-level text: ' + payload);
    System.Assert.isFalse(payload.contains('<In-memory rule|'), 'A rule without an Id should not be wrapped in a mrkdwn link: ' + payload);
  }

  @IsTest
  static void it_should_render_parent_relationship_fields_when_the_configured_path_is_dotted() {
    // Set up a real Log__c + LogEntry__c so the hydration SOQL can requery the entry with Log__r.Name populated.
    Log__c log = new Log__c(TransactionId__c = 'txn-' + System.now().getTime());
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now(), Message__c = 'Something broke');
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    log = [SELECT Id, Name FROM Log__c WHERE Id = :log.Id];

    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"sourceFields":["LoggingLevel__c","Log__r.Name"]}');
    LoggerNotifierRequest request = new LoggerNotifierRequest(
      buildRule(),
      recipient,
      buildService('https://example.com/hook', null),
      new List<SObject>{ logEntry }
    );

    String payload = sendAndCapture(request);

    System.Assert.isTrue(payload.contains('Logging Level'), 'The flat field should still render: ' + payload);
    // Log__c uses an auto-number Name, so we assert the actual parent name appears in the payload rather than the field label alone.
    System.Assert.isTrue(payload.contains(log.Name), 'The parent Log Name value should appear in the payload: ' + payload);
    // Parent-Name paths should also be rendered as a link to the parent record.
    System.Assert.isTrue(payload.contains('/' + log.Id + '|'), 'Parent-Name field should be linked to the parent record: ' + payload);
  }

  @IsTest
  static void it_should_render_the_source_records_own_name_as_a_field_and_link_to_the_source_record() {
    Log__c log = new Log__c(TransactionId__c = 'txn-source-name-' + System.now().getTime());
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    logEntry = [SELECT Id, Name FROM LogEntry__c WHERE Id = :logEntry.Id];

    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"sourceFields":["Name"]}');
    LoggerNotifierRequest request = new LoggerNotifierRequest(
      buildRule(),
      recipient,
      buildService('https://example.com/hook', null),
      new List<SObject>{ logEntry }
    );

    String payload = sendAndCapture(request);

    System.Assert.isTrue(
      payload.contains('/' + logEntry.Id + '|`' + logEntry.Name + '`>'),
      'Source Name should render linked to the source record and wrapped in inline-code backticks: ' + payload
    );
  }

  @IsTest
  static void it_should_render_a_reference_field_as_the_parents_name_when_no_display_field_is_specified() {
    Log__c log = new Log__c(TransactionId__c = 'txn-ref-fallback-' + System.now().getTime());
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    log = [SELECT Id, Name FROM Log__c WHERE Id = :log.Id];

    // Configure the raw lookup (Log__c) with no displayField - the runtime should auto-fall-back to Log__r.Name.
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"sourceFields":["Log__c"]}');
    LoggerNotifierRequest request = new LoggerNotifierRequest(
      buildRule(),
      recipient,
      buildService('https://example.com/hook', null),
      new List<SObject>{ logEntry }
    );

    String payload = sendAndCapture(request);

    System.Assert.isTrue(payload.contains(log.Name), 'REFERENCE field should render the parent Name: ' + payload);
    System.Assert.isTrue(
      payload.contains('/' + log.Id + '|`' + log.Name + '`>'),
      'REFERENCE field value should be linked to the parent record and wrapped in inline-code backticks: ' + payload
    );
  }

  @IsTest
  static void it_should_use_the_display_field_value_when_provided() {
    Log__c log = new Log__c(TransactionId__c = 'txn-displayfield-' + System.now().getTime(), LoggedByUsername__c = 'run-anon@example.com');
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);

    String json = '{"sourceFields":[{"field":"Log__c","displayField":"Log__r.LoggedByUsername__c"}]}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);
    LoggerNotifierRequest request = new LoggerNotifierRequest(
      buildRule(),
      recipient,
      buildService('https://example.com/hook', null),
      new List<SObject>{ logEntry }
    );

    String payload = sendAndCapture(request);

    System.Assert.isTrue(payload.contains('run-anon@example.com'), 'displayField value should replace the underlying REFERENCE value: ' + payload);
    // The primary field is still a REFERENCE so we still linkify to the parent record.
    System.Assert.isTrue(payload.contains('/' + log.Id + '|'), 'Linkification still points at the primary REFERENCE target: ' + payload);
  }

  @IsTest
  static void it_should_use_the_display_label_when_provided() {
    Log__c log = new Log__c(TransactionId__c = 'txn-displaylabel-' + System.now().getTime());
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);

    String json = '{"sourceFields":[{"field":"LoggingLevel__c","displayLabel":"Severity"}]}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);
    LoggerNotifierRequest request = new LoggerNotifierRequest(
      buildRule(),
      recipient,
      buildService('https://example.com/hook', null),
      new List<SObject>{ logEntry }
    );

    String payload = sendAndCapture(request);

    System.Assert.isTrue(payload.contains('"Severity"'), 'displayLabel should override the describe-provided label: ' + payload);
    System.Assert.isFalse(payload.contains('"Logging Level"'), 'The describe-provided label should not appear when overridden: ' + payload);
  }

  @IsTest
  static void it_should_prefix_the_attachment_title_with_the_source_objects_label() {
    Log__c log = new Log__c(TransactionId__c = 'txn-title-' + System.now().getTime());
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    logEntry = [SELECT Id, Name FROM LogEntry__c WHERE Id = :logEntry.Id];

    LoggerNotifierRequest request = new LoggerNotifierRequest(
      buildRule(),
      new LoggerNotificationRecipient__c(),
      buildService('https://example.com/hook', null),
      new List<SObject>{ logEntry }
    );

    String payload = sendAndCapture(request);

    String objectLabel = Schema.LogEntry__c.SObjectType.getDescribe().getLabel();
    System.Assert.isTrue(
      payload.contains('"title":"' + objectLabel + ' ' + logEntry.Name + '"'),
      'Attachment title should be "<Object Label> <Name>": ' + payload
    );
  }

  @IsTest
  static void it_should_fall_back_to_just_the_object_label_when_the_source_record_has_no_name() {
    LoggerNotifierRequest request = buildRequest(buildService('https://example.com/hook', null), new LoggerNotificationRecipient__c());

    String payload = sendAndCapture(request);

    // buildRequest uses in-memory LogEntry records with no Id or Name, so the title should collapse to
    // just the object's describe label.
    String objectLabel = Schema.LogEntry__c.SObjectType.getDescribe().getLabel();
    System.Assert.isTrue(payload.contains('"title":"' + objectLabel + '"'), 'Nameless records should render just the object label: ' + payload);
  }

  @IsTest
  static void it_should_capture_slack_message_ts_and_permalink_when_chat_post_message_returns_ok() {
    // chat.postMessage happy path: HTTP 200 + {"ok":true, "channel":"...", "ts":"..."}. We should stamp
    // the ts on externalReferenceId and build a Slack app-redirect permalink on externalReferenceUrl.
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout()
      .setStatusCode(200)
      .setResponseBody('{"ok":true,"channel":"C0BGA9N781G","ts":"1720000000.000100","message":{}}');
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    LoggerNotifierRequest request = buildRequest(buildService(null, 'SlackWebApi'), new LoggerNotificationRecipient__c(ChannelIdentifier__c = 'C0BGA9N781G'));

    LoggerNotifierResult result;
    System.Test.startTest();
    result = new SlackLoggerNotifier().sendNotification(request);
    System.Test.stopTest();

    System.Assert.areEqual(LoggerNotifierResult.STATUS_DELIVERED, result.status, 'ok:true response should stay Delivered');
    System.Assert.areEqual('1720000000.000100', result.externalReferenceId, 'ts should be captured on externalReferenceId');
    System.Assert.areEqual(
      'https://slack.com/app_redirect?channel=C0BGA9N781G&message_ts=1720000000.000100',
      result.externalReferenceUrl,
      'externalReferenceUrl should be the Slack app-redirect deep link'
    );
  }

  @IsTest
  static void it_should_flip_status_to_failed_when_chat_post_message_returns_ok_false() {
    // Slack Web API returns HTTP 200 even for logical failures - the "ok" flag in the body is the real
    // outcome. Notifier must override the 2xx-means-success default when ok:false.
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout()
      .setStatusCode(200)
      .setResponseBody('{"ok":false,"error":"channel_not_found"}');
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    LoggerNotifierRequest request = buildRequest(buildService(null, 'SlackWebApi'), new LoggerNotificationRecipient__c(ChannelIdentifier__c = 'C_INVALID'));

    LoggerNotifierResult result;
    System.Test.startTest();
    result = new SlackLoggerNotifier().sendNotification(request);
    System.Test.stopTest();

    System.Assert.areEqual(LoggerNotifierResult.STATUS_FAILED, result.status, 'ok:false response should be Failed even though HTTP status was 200');
    System.Assert.areEqual('Slack error: channel_not_found', result.errorMessage, 'Slack error code should surface on the error message');
    System.Assert.isNull(result.externalReferenceId, 'No ts to capture on failed responses');
  }

  @IsTest
  static void it_should_leave_external_reference_blank_for_webhook_mode_where_response_body_is_just_ok() {
    // Webhook mode returns HTTP 200 with the plaintext body "ok" - not JSON, no ts, no channel. Nothing
    // to capture; the delivery just stays Delivered without external reference details.
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200).setResponseBody('ok');
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    LoggerNotifierRequest request = buildRequest(buildService('https://example.com/hook', null), new LoggerNotificationRecipient__c());

    LoggerNotifierResult result;
    System.Test.startTest();
    result = new SlackLoggerNotifier().sendNotification(request);
    System.Test.stopTest();

    System.Assert.areEqual(LoggerNotifierResult.STATUS_DELIVERED, result.status);
    System.Assert.isNull(result.externalReferenceId, 'Webhook-mode response has no ts to capture');
    System.Assert.isNull(result.externalReferenceUrl, 'Webhook-mode response has no channel to build a permalink from');
  }

  @IsTest
  static void it_should_ignore_configured_fields_that_do_not_exist_on_the_source_object() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"sourceFields":["ThisFieldDoesNotExist__c","LoggingLevel__c"]}'
    );

    String payload = capturePayload(buildService('https://example.com/hook', null), recipient);

    System.Assert.isTrue(payload.contains('Logging Level'), 'Valid configured fields should still render: ' + payload);
    System.Assert.isFalse(payload.contains('ThisFieldDoesNotExist'), 'Missing fields should be silently dropped, not surfaced in the payload: ' + payload);
  }

  @IsTest
  static void it_should_still_hydrate_valid_fields_when_a_configured_field_does_not_exist_on_the_source_object() {
    // Reproduction for the reported bug: when a single configured source field is misspelled or missing,
    // the hydration SOQL used to throw QueryException, which fell back to un-hydrated records and made
    // every OTHER configured field render as the null placeholder. Filtering unresolvable paths out of
    // the SELECT lets the good ones still hydrate. This test uses a real inserted record (unlike the
    // sibling test above, which uses in-memory records with no Ids and short-circuits before SOQL).
    Log__c log = new Log__c(TransactionId__c = 'txn-bad-path-' + System.now().getTime());
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR', Timestamp__c = System.now(), Message__c = 'Something broke');
    LoggerDataStore.getDatabase().insertRecord(logEntry);

    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"sourceFields":["ThisFieldDoesNotExist__c","Log__r.Name","LoggingLevel__c","Message__c"],"includeNullValues":true}'
    );
    LoggerNotifierRequest request = new LoggerNotifierRequest(
      buildRule(),
      recipient,
      buildService('https://example.com/hook', null),
      new List<SObject>{ logEntry }
    );

    String payload = sendAndCapture(request);

    // The good fields should render with their actual values, not the null placeholder.
    System.Assert.isTrue(
      payload.contains('`ERROR`'),
      'LoggingLevel__c should still render its real value even though another configured field is invalid: ' + payload
    );
    System.Assert.isTrue(
      payload.contains('```Something broke```'),
      'Message__c should still render its real value even though another configured field is invalid: ' + payload
    );
    log = [SELECT Id, Name FROM Log__c WHERE Id = :log.Id];
    System.Assert.isTrue(payload.contains(log.Name), 'Log__r.Name should still hydrate and render even though another configured field is invalid: ' + payload);
  }

  @IsTest
  static void it_should_suppress_null_valued_fields_by_default() {
    // StackTrace__c is left null on the record; the default field set includes it, so it should be dropped
    // from the rendered payload when the recipient has no config.
    LoggerNotifierRequest request = new LoggerNotifierRequest(
      buildRule(),
      new LoggerNotificationRecipient__c(),
      buildService('https://example.com/hook', null),
      new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR', Message__c = 'Only a message') }
    );

    String payload = sendAndCapture(request);

    System.Assert.isFalse(payload.contains('"Stack Trace"'), 'Null Stack Trace should be suppressed by default: ' + payload);
    System.Assert.isFalse(payload.contains('(null/no value)'), 'Default rendering should not emit the null placeholder: ' + payload);
  }

  @IsTest
  static void it_should_render_null_valued_fields_as_the_placeholder_when_configured_to_include_them() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"sourceFields":["LoggingLevel__c","StackTrace__c"],"includeNullValues":true}'
    );
    LoggerNotifierRequest request = new LoggerNotifierRequest(
      buildRule(),
      recipient,
      buildService('https://example.com/hook', null),
      new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') }
    );

    String payload = sendAndCapture(request);

    System.Assert.isTrue(payload.contains('"Stack Trace"'), 'Null Stack Trace should still render its label when includeNullValues is true: ' + payload);
    System.Assert.isTrue(payload.contains('`(null/no value)`'), 'Null values should render as the backtick-wrapped placeholder: ' + payload);
  }

  // Test helpers

  private static LoggerMockDataCreator.MockHttpCallout installCalloutMock() {
    LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
    System.Test.setMock(System.HttpCalloutMock.class, calloutMock);
    return calloutMock;
  }

  private static String capturePayload(LoggerNotificationService__c service, LoggerNotificationRecipient__c recipient) {
    return sendAndCapture(buildRequest(service, recipient));
  }

  private static String capturePayloadForLoggingLevel(String loggingLevel) {
    LoggerNotifierRequest request = new LoggerNotifierRequest(
      buildRule(),
      new LoggerNotificationRecipient__c(),
      buildService('https://example.com/hook', null),
      new List<SObject>{ new LogEntry__c(LoggingLevel__c = loggingLevel) }
    );
    return sendAndCapture(request);
  }

  private static String sendAndCapture(LoggerNotifierRequest request) {
    LoggerMockDataCreator.MockHttpCallout calloutMock = installCalloutMock();
    // Callouts can't follow uncommitted DML in the same context; the callout runs inside Test.startTest so
    // any real inserts test setup performed are committed before the notifier makes its HTTP call.
    System.Test.startTest();
    new SlackLoggerNotifier().sendNotification(request);
    System.Test.stopTest();
    System.Assert.isNotNull(calloutMock.request, 'Notifier should have made an HTTP callout to capture the payload from');
    return calloutMock.request.getBody();
  }

  private static LoggerNotificationRule__c buildRule() {
    return new LoggerNotificationRule__c(
      Id = LoggerMockDataCreator.createId(Schema.LoggerNotificationRule__c.SObjectType),
      Name = 'Test rule',
      SourceSObjectType__c = 'LogEntry__c'
    );
  }

  private static LoggerNotificationService__c buildService(String webhookUrl, String namedCredentialDeveloperName) {
    return new LoggerNotificationService__c(
      Name = 'Slack',
      NotifierApexClassName__c = 'SlackLoggerNotifier',
      IsEnabled__c = true,
      WebhookUrl__c = webhookUrl,
      NamedCredentialDeveloperName__c = namedCredentialDeveloperName
    );
  }

  private static LoggerNotifierRequest buildRequest(LoggerNotificationService__c service, LoggerNotificationRecipient__c recipient) {
    List<SObject> matchingRecords = new List<SObject>{
      new LogEntry__c(LoggingLevel__c = 'ERROR', Message__c = 'Something went wrong', StackTrace__c = 'Line 1\nLine 2'),
      new LogEntry__c(LoggingLevel__c = 'WARN', Message__c = 'Heads up')
    };
    return new LoggerNotifierRequest(buildRule(), recipient, service, matchingRecords);
  }
}
