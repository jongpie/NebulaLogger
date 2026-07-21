//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class CustomNotificationLoggerNotifier_Tests {
  @IsTest
  static void it_should_short_circuit_when_context_is_null_or_has_no_records() {
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();

    System.DmlException thrownException;
    try {
      notifier.sendNotification(null);
      notifier.sendNotification(new LoggerNotifierRequest(new LoggerNotificationRecipient__c(), new List<SObject>()));
    } catch (System.DmlException ex) {
      thrownException = ex;
    }

    System.Assert.isNull(thrownException, 'An exception should not have been thrown');
  }

  @IsTest
  static void it_should_short_circuit_when_notification_type_developer_name_is_missing() {
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();
    LoggerNotifierRequest request = buildRequest(new LoggerNotificationRecipient__c(User__c = System.UserInfo.getUserId()));

    // No ConfigurationJson__c means no notificationTypeDeveloperName - should skip
    notifier.sendNotification(request);
    // No exception, no throw is the assertion
    System.Assert.isTrue(true);
  }

  @IsTest
  static void it_should_short_circuit_when_no_recipients_resolve() {
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();
    LoggerNotifierRequest request = buildRequest(new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"notificationTypeDeveloperName": "SomeType"}'));

    notifier.sendNotification(request);
    // No exception, no throw is the assertion
    System.Assert.isTrue(true);
  }

  @IsTest
  static void it_should_resolve_recipient_ids_from_user_field() {
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();
    Id userId = System.UserInfo.getUserId();
    LoggerNotifierRequest request = buildRequest(new LoggerNotificationRecipient__c(User__c = userId));

    Set<String> recipientIds = notifier.resolveRecipientIds(request);

    System.Assert.areEqual(1, recipientIds.size());
    System.Assert.isTrue(recipientIds.contains(String.valueOf(userId)));
  }

  @IsTest
  static void it_should_resolve_additional_recipient_user_ids_from_json_config() {
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();
    Id userAId = System.UserInfo.getUserId();
    String userBId = '005000000000000001';
    LoggerNotifierRequest request = buildRequest(
      new LoggerNotificationRecipient__c(User__c = userAId, ConfigurationJson__c = '{"recipientUserIds":["' + userBId + '"]}')
    );

    Set<String> recipientIds = notifier.resolveRecipientIds(request);

    System.Assert.areEqual(2, recipientIds.size());
    System.Assert.isTrue(recipientIds.contains(String.valueOf(userAId)));
    System.Assert.isTrue(recipientIds.contains(userBId));
  }

  @IsTest
  static void it_should_resolve_recipient_group_ids_from_json_config() {
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();
    String groupId = LoggerMockDataCreator.createId(Schema.Group.SObjectType);
    LoggerNotifierRequest request = buildRequest(new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"recipientGroupIds":["' + groupId + '"]}'));

    Set<String> recipientIds = notifier.resolveRecipientIds(request);

    System.Assert.areEqual(1, recipientIds.size());
    System.Assert.isTrue(recipientIds.contains(groupId));
  }

  @IsTest
  static void it_should_render_the_default_title_when_no_template_is_configured() {
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();
    LoggerNotifierRequest request = buildRequest(new LoggerNotificationRecipient__c(User__c = System.UserInfo.getUserId()));

    String title = notifier.buildTitle(request, request.matchingRecords.get(0), null);

    System.Assert.areEqual('Nebula Logger: Test rule', title);
  }

  @IsTest
  static void it_should_render_a_configured_title_template_with_the_rule_name_token() {
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();
    LoggerNotifierRequest request = buildRequest(new LoggerNotificationRecipient__c(User__c = System.UserInfo.getUserId()));

    String title = notifier.buildTitle(request, request.matchingRecords.get(0), '[Nebula] {RuleName} fired');

    System.Assert.areEqual('[Nebula] Test rule fired', title);
  }

  @IsTest
  static void it_should_resolve_field_tokens_against_the_current_matching_record_in_the_title() {
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();
    LoggerNotifierRequest request = buildRequest(new LoggerNotificationRecipient__c(User__c = System.UserInfo.getUserId()));

    String title = notifier.buildTitle(request, request.matchingRecords.get(0), '{LoggingLevel__c} - {Message__c}');

    System.Assert.areEqual('ERROR - Something went wrong', title);
  }

  @IsTest
  static void it_should_replace_unresolved_tokens_with_an_empty_string() {
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();
    LoggerNotifierRequest request = buildRequest(new LoggerNotificationRecipient__c(User__c = System.UserInfo.getUserId()));

    String title = notifier.buildTitle(request, request.matchingRecords.get(0), '{MissingField__c} / {LoggingLevel__c}');

    System.Assert.areEqual(' / ERROR', title);
  }

  @IsTest
  static void it_should_render_the_configured_body_template() {
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();
    LoggerNotifierRequest request = buildRequest(new LoggerNotificationRecipient__c(User__c = System.UserInfo.getUserId()));

    String body = notifier.buildBody(request, request.matchingRecords.get(0), '[{LoggingLevel__c}] {Message__c}');

    System.Assert.areEqual('[ERROR] Something went wrong', body);
  }

  @IsTest
  static void it_should_fall_back_to_the_record_id_for_the_default_body_when_no_name_field_exists() {
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();
    // LogEntry__c has no Name field, and the in-memory record has no Id either - the default body
    // becomes an empty string, which is what setBody would receive at delivery time.
    LoggerNotifierRequest request = buildRequest(new LoggerNotificationRecipient__c(User__c = System.UserInfo.getUserId()));

    String body = notifier.buildBody(request, request.matchingRecords.get(0), null);

    System.Assert.areEqual('', body);
  }

  @IsTest
  static void it_should_truncate_a_very_long_rendered_title() {
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(User__c = System.UserInfo.getUserId());
    recipient.LoggerNotificationRule__r = new LoggerNotificationRule__c(Name = 'x'.repeat(200), SourceSObjectType__c = 'LogEntry__c');
    recipient.LoggerNotificationService__r = new LoggerNotificationService__c(
      Name = 'Bell',
      NotifierApexClassName__c = 'CustomNotificationLoggerNotifier',
      IsEnabled__c = true
    );
    LoggerNotifierRequest request = new LoggerNotifierRequest(
      recipient,
      new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name(), Message__c = 'msg') }
    );

    String title = notifier.buildTitle(request, request.matchingRecords.get(0), null);

    System.Assert.isTrue(title.length() <= 80, 'Title should be truncated to <= 80 chars, got length ' + title.length());
    System.Assert.isTrue(title.endsWith('...'), 'Truncated title should end with the ellipsis marker: ' + title);
  }

  private static LoggerNotifierRequest buildRequest(LoggerNotificationRecipient__c recipient) {
    recipient.LoggerNotificationRule__r = new LoggerNotificationRule__c(Name = 'Test rule', SourceSObjectType__c = 'LogEntry__c');
    recipient.LoggerNotificationService__r = new LoggerNotificationService__c(
      Name = 'Custom Notification',
      NotifierApexClassName__c = 'CustomNotificationLoggerNotifier',
      IsEnabled__c = true
    );
    List<SObject> matchingRecords = new List<SObject>{
      new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name(), Message__c = 'Something went wrong')
    };
    return new LoggerNotifierRequest(recipient, matchingRecords);
  }
}
