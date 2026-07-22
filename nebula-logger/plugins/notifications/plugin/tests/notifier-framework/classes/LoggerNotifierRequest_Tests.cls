//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotifierRequest_Tests {
  @IsTest
  static void it_should_expose_constructor_arguments_and_derive_rule_and_service_from_the_recipient() {
    LoggerNotificationService__c service = new LoggerNotificationService__c(
      Name = 'Slack',
      NotifierApexClassName__c = 'FakeSlackNotifier',
      WebhookUrl__c = 'https://example.com/webhook'
    );
    LoggerNotificationRule__c notificationRule = new LoggerNotificationRule__c(Name = 'Test rule', SourceSObjectType__c = 'LogEntry__c');
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c();
    recipient.LoggerNotificationRule__r = notificationRule;
    recipient.LoggerNotificationService__r = service;
    List<SObject> matchingRecords = new List<SObject>{ new LogEntry__c() };

    LoggerNotifierRequest request = new LoggerNotifierRequest(recipient, matchingRecords);

    System.Assert.areEqual(recipient, request.recipient);
    System.Assert.areEqual(notificationRule, request.recipient.LoggerNotificationRule__r);
    System.Assert.areEqual(service, request.recipient.LoggerNotificationService__r);
    System.Assert.areEqual(matchingRecords, request.matchingRecords);
    System.Assert.areEqual(1, request.matchingRecords.size());
    System.Assert.isNotNull(request.configuration, 'Configuration should always be non-null');
  }

  @IsTest
  static void it_should_support_being_consumed_by_a_LoggerNotifier_implementation() {
    LoggerNotifierRequest request = new LoggerNotifierRequest(new LoggerNotificationRecipient__c(), new List<SObject>());
    LocalMockNotifier mockNotifier = new LocalMockNotifier();

    mockNotifier.sendNotification(request);

    System.Assert.areEqual(1, mockNotifier.invocationCount);
    System.Assert.areEqual(request, mockNotifier.lastRequest);
  }

  private class LocalMockNotifier extends LoggerNotifier {
    public Integer invocationCount = 0;
    public LoggerNotifierRequest lastRequest;

    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      this.invocationCount++;
      this.lastRequest = request;
      return null;
    }
  }
}
