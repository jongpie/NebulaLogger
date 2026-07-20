//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class EmailLoggerNotifier_Tests {
  @IsTest
  static void it_should_short_circuit_when_context_is_null_or_records_are_empty() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();

    notifier.sendNotification(null);
    notifier.sendNotification(
      new LoggerNotifiableContext(new LoggerNotificationRule__c(), new LoggerNotificationRecipient__c(), new LoggerNotificationService__c(), null)
    );
    notifier.sendNotification(
      new LoggerNotifiableContext(
        new LoggerNotificationRule__c(),
        new LoggerNotificationRecipient__c(),
        new LoggerNotificationService__c(),
        new List<SObject>()
      )
    );
  }

  @IsTest
  static void it_should_produce_null_email_when_recipient_has_no_target() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c());

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, defaultSpecs(), false, null);

    System.Assert.isNull(email, 'Email should be null when neither user nor address is set');
  }

  @IsTest
  static void it_should_use_the_user_lookup_when_populated() {
    Id currentUserId = System.UserInfo.getUserId();
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(User__c = currentUserId));

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, defaultSpecs(), false, null);

    System.Assert.isNotNull(email);
    System.Assert.areEqual(currentUserId, email.getTargetObjectId());
    System.Assert.isNull(email.getToAddresses(), 'When User is set, ToAddresses should not be populated');
  }

  @IsTest
  static void it_should_use_the_recipient_address_when_populated() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(EmailAddress__c = 'alerts@example.com'));

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, defaultSpecs(), false, null);

    System.Assert.isNotNull(email);
    System.Assert.areEqual(new List<String>{ 'alerts@example.com' }, email.getToAddresses());
    System.Assert.isNull(email.getTargetObjectId(), 'When EmailAddress is set, TargetObjectId should not be populated');
  }

  @IsTest
  static void it_should_prefer_user_lookup_over_recipient_address_when_both_are_set() {
    Id currentUserId = System.UserInfo.getUserId();
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(User__c = currentUserId, EmailAddress__c = 'alerts@example.com'));

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, defaultSpecs(), false, null);

    System.Assert.areEqual(currentUserId, email.getTargetObjectId());
    System.Assert.isNull(email.getToAddresses());
  }

  @IsTest
  static void it_should_render_the_default_source_fields_when_config_has_no_source_fields() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(EmailAddress__c = 'alerts@example.com'));

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, defaultSpecs(), false, null);

    String body = email.getPlainTextBody();
    System.Assert.isTrue(body.contains('Logging Level: ERROR'), 'Body should include LoggingLevel__c: ' + body);
    System.Assert.isTrue(body.contains('Message: Something went wrong'), 'Body should include Message__c: ' + body);
    System.Assert.isFalse(body.contains('Exception Type'), 'ExceptionType__c is not in the default set: ' + body);
  }

  @IsTest
  static void it_should_render_only_the_configured_source_fields_when_provided() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    LoggerNotifiableContext context = buildContext(
      new LoggerNotificationRecipient__c(EmailAddress__c = 'alerts@example.com', ConfigurationJson__c = '{"sourceFields":["Message__c"]}')
    );

    List<LoggerNotifiableConfiguration.SourceFieldSpec> specs = context.config.getSourceFieldSpecs();
    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, specs, false, null);

    String body = email.getPlainTextBody();
    System.Assert.isTrue(body.contains('Message: Something went wrong'), 'Body should include the configured field: ' + body);
    System.Assert.isFalse(body.contains('Logging Level'), 'Body should not include fields outside the configured list: ' + body);
    System.Assert.isFalse(body.contains('Stack Trace'), 'Body should not include fields outside the configured list: ' + body);
  }

  @IsTest
  static void it_should_apply_display_label_and_display_field_overrides() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    String json = '{"sourceFields":[{"field":"Message__c","displayLabel":"What Happened"}]}';
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(EmailAddress__c = 'alerts@example.com', ConfigurationJson__c = json));

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, context.config.getSourceFieldSpecs(), false, null);

    String body = email.getPlainTextBody();
    System.Assert.isTrue(body.contains('What Happened: Something went wrong'), 'displayLabel should replace the field label: ' + body);
    System.Assert.isFalse(body.contains('Message: '), 'The describe-provided label should not appear when overridden: ' + body);
  }

  @IsTest
  static void it_should_drop_blank_field_values_by_default() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    LoggerNotifiableContext context = buildContext(
      new LoggerNotificationRecipient__c(EmailAddress__c = 'alerts@example.com', ConfigurationJson__c = '{"sourceFields":["Message__c","StackTrace__c"]}')
    );

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, context.config.getSourceFieldSpecs(), false, null);

    String body = email.getPlainTextBody();
    System.Assert.isTrue(body.contains('Message: '), 'Populated fields should render: ' + body);
    System.Assert.isFalse(body.contains('Stack Trace'), 'Blank fields should be dropped when includeNullValues is false: ' + body);
  }

  @IsTest
  static void it_should_render_empty_placeholder_for_blank_values_when_include_null_values_is_true() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    String json = '{"sourceFields":["Message__c","StackTrace__c"],"includeNullValues":true}';
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(EmailAddress__c = 'alerts@example.com', ConfigurationJson__c = json));

    Messaging.SingleEmailMessage email = notifier.buildEmail(
      context,
      context.matchingRecords,
      context.config.getSourceFieldSpecs(),
      context.config.getBoolean('includeNullValues', false),
      null
    );

    String body = email.getPlainTextBody();
    System.Assert.isTrue(body.contains('Stack Trace: (empty)'), 'Blank fields should render the placeholder when opted in: ' + body);
  }

  @IsTest
  static void it_should_use_the_default_subject_when_no_template_is_configured() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(EmailAddress__c = 'alerts@example.com'));

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, defaultSpecs(), false, null);

    System.Assert.areEqual('Nebula Logger: 2 log records matched Test rule', email.getSubject());
  }

  @IsTest
  static void it_should_resolve_rule_name_and_match_count_tokens_in_the_subject_template() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    String template = '[{!matchCount}] {!ruleName}';
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(EmailAddress__c = 'alerts@example.com'));

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, defaultSpecs(), false, template);

    System.Assert.areEqual('[2] Test rule', email.getSubject());
  }

  @IsTest
  static void it_should_resolve_field_tokens_against_the_first_matching_record() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    String template = '{!LoggingLevel__c}: {!Message__c}';
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(EmailAddress__c = 'alerts@example.com'));

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, defaultSpecs(), false, template);

    System.Assert.areEqual('ERROR: Something went wrong', email.getSubject());
  }

  @IsTest
  static void it_should_render_unknown_tokens_as_empty_string() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    String template = '{!ruleName}|{!NotARealField__c}|{!matchCount}';
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(EmailAddress__c = 'alerts@example.com'));

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, defaultSpecs(), false, template);

    System.Assert.areEqual('Test rule||2', email.getSubject());
  }

  @IsTest
  static void it_should_fall_back_to_the_default_subject_when_template_resolves_to_blank() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    String template = '{!NotARealField__c}';
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(EmailAddress__c = 'alerts@example.com'));

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, defaultSpecs(), false, template);

    System.Assert.areEqual('Nebula Logger: 2 log records matched Test rule', email.getSubject());
  }

  @IsTest
  static void it_should_treat_token_names_case_insensitively() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    String template = '{!RULENAME} / {!MATCHCOUNT}';
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(EmailAddress__c = 'alerts@example.com'));

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, defaultSpecs(), false, template);

    System.Assert.areEqual('Test rule / 2', email.getSubject());
  }

  @IsTest
  static void it_should_return_a_skipped_result_from_send_notification_when_recipient_has_no_target() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c());

    LoggerNotifiableResult result = notifier.sendNotification(context);

    System.Assert.isNotNull(result);
    System.Assert.areEqual(LoggerNotifiableResult.STATUS_SKIPPED, result.status);
    System.Assert.areEqual('Recipient has neither User__c nor EmailAddress__c configured', result.errorMessage);
  }

  @IsTest
  static void it_should_return_a_delivered_result_from_send_notification_when_send_succeeds() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(User__c = System.UserInfo.getUserId()));

    System.Test.startTest();
    LoggerNotifiableResult result = notifier.sendNotification(context);
    System.Test.stopTest();

    System.Assert.isNotNull(result);
    System.Assert.areEqual(LoggerNotifiableResult.STATUS_DELIVERED, result.status);
    System.Assert.isNull(result.errorMessage);
  }

  @IsTest
  static void it_should_include_the_rule_metadata_and_record_link_placeholder_in_the_body() {
    EmailLoggerNotifier notifier = new EmailLoggerNotifier();
    LoggerNotifiableContext context = buildContext(new LoggerNotificationRecipient__c(EmailAddress__c = 'alerts@example.com'));

    Messaging.SingleEmailMessage email = notifier.buildEmail(context, context.matchingRecords, defaultSpecs(), false, null);

    String body = email.getPlainTextBody();
    System.Assert.isTrue(body.contains('Rule: Test rule'), 'Body should include the rule name: ' + body);
    System.Assert.isTrue(body.contains('Filter: ISPICKVAL(LoggingLevel__c'), 'Body should include the SOQL filter: ' + body);
    System.Assert.isTrue(body.contains('Matching records: 2'), 'Body should include the match count: ' + body);
  }

  private static LoggerNotifiableContext buildContext(LoggerNotificationRecipient__c recipient) {
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(
      Name = 'Test rule',
      SourceSObjectType__c = 'LogEntry__c',
      SourceSObjectFilter__c = 'ISPICKVAL(LoggingLevel__c, \'ERROR\')'
    );
    LoggerNotificationService__c service = new LoggerNotificationService__c(
      Name = 'Email',
      NotifierApexClassName__c = 'EmailLoggerNotifier',
      IsEnabled__c = true
    );
    List<SObject> matchingRecords = new List<SObject>{
      new LogEntry__c(LoggingLevel__c = 'ERROR', Message__c = 'Something went wrong'),
      new LogEntry__c(LoggingLevel__c = 'WARN', Message__c = 'Heads up')
    };
    return new LoggerNotifiableContext(rule, recipient, service, matchingRecords);
  }

  private static List<LoggerNotifiableConfiguration.SourceFieldSpec> defaultSpecs() {
    return new List<LoggerNotifiableConfiguration.SourceFieldSpec>{
      new LoggerNotifiableConfiguration.SourceFieldSpec('LoggingLevel__c', null, null),
      new LoggerNotifiableConfiguration.SourceFieldSpec('Origin__c', null, null),
      new LoggerNotifiableConfiguration.SourceFieldSpec('Message__c', null, null),
      new LoggerNotifiableConfiguration.SourceFieldSpec('StackTrace__c', null, null)
    };
  }
}
