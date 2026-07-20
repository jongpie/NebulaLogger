//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotifierRequest_Tests {
  @IsTest
  static void it_should_expose_all_constructor_arguments_as_readonly_properties() {
    LoggerNotificationService__c service = new LoggerNotificationService__c(
      Name = 'Slack',
      NotifierApexClassName__c = 'FakeSlackNotifier',
      WebhookUrl__c = 'https://example.com/webhook'
    );
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c();
    LoggerNotificationRule__c notificationRule = new LoggerNotificationRule__c(Name = 'Test rule', SourceSObjectType__c = 'LogEntry__c');
    List<SObject> matchingRecords = new List<SObject>{ new LogEntry__c() };

    LoggerNotifierRequest request = new LoggerNotifierRequest(notificationRule, recipient, service, matchingRecords);

    System.Assert.areEqual(notificationRule, request.notificationRule);
    System.Assert.areEqual(recipient, request.recipient);
    System.Assert.areEqual(service, request.service);
    System.Assert.areEqual(matchingRecords, request.matchingRecords);
    System.Assert.areEqual(1, request.matchingRecords.size());
  }

  @IsTest
  static void it_should_support_being_consumed_by_a_LoggerNotifier_implementation() {
    LoggerNotifierRequest request = new LoggerNotifierRequest(
      new LoggerNotificationRule__c(),
      new LoggerNotificationRecipient__c(),
      new LoggerNotificationService__c(),
      new List<SObject>()
    );
    LocalMockNotifier mockNotifier = new LocalMockNotifier();

    mockNotifier.sendNotification(request);

    System.Assert.areEqual(1, mockNotifier.invocationCount);
    System.Assert.areEqual(request, mockNotifier.lastRequest);
  }

  private class LocalMockNotifier implements LoggerNotifier {
    public Integer invocationCount = 0;
    public LoggerNotifierRequest lastRequest;

    public LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      this.invocationCount++;
      this.lastRequest = request;
      return null;
    }
  }
}
