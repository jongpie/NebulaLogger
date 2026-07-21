//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class CustomNotificationLoggerNotifier_Tests {
  private static final String NOTIFICATION_TYPE_DEVELOPER_NAME = 'LoggerCustomNotification';

  @IsTest
  static void it_should_short_circuit_when_request_is_null_or_has_no_records() {
    MockSender mockSender = installMockSender();
    CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();

    LoggerNotifierResult nullResult = notifier.sendNotification(null);
    LoggerNotifierResult emptyRecordsResult = notifier.sendNotification(new LoggerNotifierRequest(new LoggerNotificationRecipient__c(), new List<SObject>()));

    System.Assert.isNull(nullResult);
    System.Assert.isNull(emptyRecordsResult);
    System.Assert.areEqual(0, mockSender.captured.size(), 'No payload should have been sent');
  }

  @IsTest
  static void it_should_skip_when_notification_type_developer_name_is_missing() {
    MockSender mockSender = installMockSender();
    LoggerNotifierRequest request = buildRequest(new LoggerNotificationRecipient__c(User__c = System.UserInfo.getUserId()), null);

    LoggerNotifierResult result = new CustomNotificationLoggerNotifier().sendNotification(request);

    System.Assert.areEqual(LoggerNotifierResult.STATUS_SKIPPED, result.status);
    System.Assert.areEqual('notificationTypeDeveloperName missing from ConfigurationJson__c', result.errorMessage);
    System.Assert.areEqual(0, mockSender.captured.size(), 'No payload should have been sent');
  }

  @IsTest
  static void it_should_skip_when_recipient_has_no_user() {
    MockSender mockSender = installMockSender();
    Map<String, Object> config = new Map<String, Object>{ 'notificationTypeDeveloperName' => NOTIFICATION_TYPE_DEVELOPER_NAME };
    LoggerNotifierRequest request = buildRequest(new LoggerNotificationRecipient__c(ConfigurationJson__c = System.JSON.serialize(config)), null);

    LoggerNotifierResult result = new CustomNotificationLoggerNotifier().sendNotification(request);

    System.Assert.areEqual(LoggerNotifierResult.STATUS_SKIPPED, result.status);
    System.Assert.areEqual('Recipient User__c is required', result.errorMessage);
    System.Assert.areEqual(0, mockSender.captured.size(), 'No payload should have been sent');
  }

  @IsTest
  static void it_should_skip_when_the_notification_type_developer_name_does_not_resolve() {
    MockSender mockSender = installMockSender();
    Map<String, Object> config = new Map<String, Object>{ 'notificationTypeDeveloperName' => 'DoesNotExist_' + System.UUID.randomUUID().toString() };
    LoggerNotifierRequest request = buildRequest(
      new LoggerNotificationRecipient__c(User__c = System.UserInfo.getUserId(), ConfigurationJson__c = System.JSON.serialize(config)),
      null
    );

    LoggerNotifierResult result = new CustomNotificationLoggerNotifier().sendNotification(request);

    System.Assert.areEqual(LoggerNotifierResult.STATUS_SKIPPED, result.status);
    System.Assert.isTrue(result.errorMessage.contains('not found'), 'Expected the not-found error, got: ' + result.errorMessage);
    System.Assert.areEqual(0, mockSender.captured.size(), 'No payload should have been sent');
  }

  @IsTest
  static void it_should_build_a_payload_with_the_defaults_when_no_templates_are_configured() {
    MockSender mockSender = installMockSender();
    Id userId = System.UserInfo.getUserId();
    LoggerNotifierRequest request = buildRequest(new LoggerNotificationRecipient__c(User__c = userId, ConfigurationJson__c = defaultConfigJson()), null);
    Id expectedTypeId = lookupNotificationTypeId(NOTIFICATION_TYPE_DEVELOPER_NAME);

    LoggerNotifierResult result = new CustomNotificationLoggerNotifier().sendNotification(request);

    System.Assert.areEqual(LoggerNotifierResult.STATUS_DELIVERED, result.status);
    System.Assert.areEqual(1, mockSender.captured.size());
    CustomNotificationLoggerNotifier.Payload payload = mockSender.captured.get(0);
    System.Assert.areEqual(expectedTypeId, payload.notificationTypeId);
    System.Assert.areEqual('Nebula Logger: Test rule', payload.title);
    // Default body falls back to the record's Name; the in-memory LogEntry__c has no Id and no Name,
    // so the notifier produces an empty string (which is what the Custom Notification service would receive).
    System.Assert.areEqual('', payload.body);
    System.Assert.areEqual(null, payload.targetId, 'The in-memory record has no Id, so targetId is null');
    System.Assert.areEqual(userId, payload.recipientUserId);
  }

  @IsTest
  static void it_should_render_configured_title_and_body_templates() {
    MockSender mockSender = installMockSender();
    Id userId = System.UserInfo.getUserId();
    Map<String, Object> config = new Map<String, Object>{
      'notificationTypeDeveloperName' => NOTIFICATION_TYPE_DEVELOPER_NAME,
      'titleTemplate' => '[Nebula] {RuleName} fired',
      'bodyTemplate' => '[{LoggingLevel__c}] {Message__c}'
    };
    LoggerNotifierRequest request = buildRequest(
      new LoggerNotificationRecipient__c(User__c = userId, ConfigurationJson__c = System.JSON.serialize(config)),
      null
    );

    new CustomNotificationLoggerNotifier().sendNotification(request);

    System.Assert.areEqual(1, mockSender.captured.size());
    CustomNotificationLoggerNotifier.Payload payload = mockSender.captured.get(0);
    System.Assert.areEqual('[Nebula] Test rule fired', payload.title);
    System.Assert.areEqual('[ERROR] Something went wrong', payload.body);
  }

  @IsTest
  static void it_should_render_unresolved_tokens_as_an_empty_string() {
    MockSender mockSender = installMockSender();
    Map<String, Object> config = new Map<String, Object>{
      'notificationTypeDeveloperName' => NOTIFICATION_TYPE_DEVELOPER_NAME,
      'titleTemplate' => '{MissingField__c} / {LoggingLevel__c}'
    };
    LoggerNotifierRequest request = buildRequest(
      new LoggerNotificationRecipient__c(User__c = System.UserInfo.getUserId(), ConfigurationJson__c = System.JSON.serialize(config)),
      null
    );

    new CustomNotificationLoggerNotifier().sendNotification(request);

    System.Assert.areEqual(' / ERROR', mockSender.captured.get(0).title);
  }

  @IsTest
  static void it_should_truncate_a_very_long_rendered_title() {
    MockSender mockSender = installMockSender();
    Map<String, Object> config = new Map<String, Object>{ 'notificationTypeDeveloperName' => NOTIFICATION_TYPE_DEVELOPER_NAME };
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      User__c = System.UserInfo.getUserId(),
      ConfigurationJson__c = System.JSON.serialize(config)
    );
    recipient.LoggerNotificationRule__r = new LoggerNotificationRule__c(Name = 'x'.repeat(200), SourceSObjectType__c = 'LogEntry__c');
    recipient.LoggerNotificationService__r = buildService();
    LoggerNotifierRequest request = new LoggerNotifierRequest(
      recipient,
      new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name(), Message__c = 'msg') }
    );

    new CustomNotificationLoggerNotifier().sendNotification(request);

    String title = mockSender.captured.get(0).title;
    System.Assert.isTrue(title.length() <= 80, 'Title should be truncated to <= 80 chars, got length ' + title.length());
    System.Assert.isTrue(title.endsWith('...'), 'Truncated title should end with the ellipsis marker: ' + title);
  }

  @IsTest
  static void it_should_emit_one_payload_per_matching_record() {
    MockSender mockSender = installMockSender();
    Id userId = System.UserInfo.getUserId();
    LoggerNotifierRequest request = buildRequest(
      new LoggerNotificationRecipient__c(User__c = userId, ConfigurationJson__c = defaultConfigJson()),
      new List<SObject>{
        new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name(), Message__c = 'one'),
        new LogEntry__c(LoggingLevel__c = System.LoggingLevel.WARN.name(), Message__c = 'two'),
        new LogEntry__c(LoggingLevel__c = System.LoggingLevel.INFO.name(), Message__c = 'three')
      }
    );

    new CustomNotificationLoggerNotifier().sendNotification(request);

    System.Assert.areEqual(3, mockSender.captured.size(), 'One payload per matching record');
    for (CustomNotificationLoggerNotifier.Payload payload : mockSender.captured) {
      System.Assert.areEqual(userId, payload.recipientUserId);
      System.Assert.areEqual('Nebula Logger: Test rule', payload.title);
    }
  }

  @IsTest
  static void it_should_return_a_failed_result_when_the_sender_throws_for_every_record() {
    MockSender mockSender = installMockSender();
    mockSender.throwOnSend = true;
    Id userId = System.UserInfo.getUserId();
    LoggerNotifierRequest request = buildRequest(
      new LoggerNotificationRecipient__c(User__c = userId, ConfigurationJson__c = defaultConfigJson()),
      new List<SObject>{
        new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name(), Message__c = 'one'),
        new LogEntry__c(LoggingLevel__c = System.LoggingLevel.WARN.name(), Message__c = 'two')
      }
    );

    LoggerNotifierResult result = new CustomNotificationLoggerNotifier().sendNotification(request);

    System.Assert.areEqual(LoggerNotifierResult.STATUS_FAILED, result.status);
    System.Assert.isTrue(result.errorMessage.startsWith('2 of 2 notifications failed'), 'Expected the aggregated failure message, got: ' + result.errorMessage);
  }

  private static MockSender installMockSender() {
    MockSender mockSender = new MockSender();
    CustomNotificationLoggerNotifier.sender = mockSender;
    return mockSender;
  }

  private static Id lookupNotificationTypeId(String developerName) {
    List<CustomNotificationType> results = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = :developerName WITH SYSTEM_MODE];
    return results.isEmpty() ? null : results.get(0).Id;
  }

  private static String defaultConfigJson() {
    return System.JSON.serialize(new Map<String, Object>{ 'notificationTypeDeveloperName' => NOTIFICATION_TYPE_DEVELOPER_NAME });
  }

  private static LoggerNotificationService__c buildService() {
    return new LoggerNotificationService__c(Name = 'Custom Notification', NotifierApexClassName__c = 'CustomNotificationLoggerNotifier', IsEnabled__c = true);
  }

  private static LoggerNotifierRequest buildRequest(LoggerNotificationRecipient__c recipient, List<SObject> matchingRecords) {
    recipient.LoggerNotificationRule__r = new LoggerNotificationRule__c(Name = 'Test rule', SourceSObjectType__c = 'LogEntry__c');
    recipient.LoggerNotificationService__r = buildService();
    List<SObject> effectiveRecords = matchingRecords != null
      ? matchingRecords
      : new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name(), Message__c = 'Something went wrong') };
    return new LoggerNotifierRequest(recipient, effectiveRecords);
  }

  private class MockSender implements CustomNotificationLoggerNotifier.Sender {
    public List<CustomNotificationLoggerNotifier.Payload> captured = new List<CustomNotificationLoggerNotifier.Payload>();
    public Boolean throwOnSend = false;

    public void send(CustomNotificationLoggerNotifier.Payload payload) {
      captured.add(payload);
      if (this.throwOnSend) {
        throw new System.CalloutException('Simulated send failure');
      }
    }
  }
}
