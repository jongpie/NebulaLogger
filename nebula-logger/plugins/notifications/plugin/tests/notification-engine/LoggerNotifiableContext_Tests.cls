//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotifiableContext_Tests {
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

    LoggerNotifiableContext context = new LoggerNotifiableContext(notificationRule, recipient, service, matchingRecords);

    System.Assert.areEqual(notificationRule, context.notificationRule);
    System.Assert.areEqual(recipient, context.recipient);
    System.Assert.areEqual(service, context.service);
    System.Assert.areEqual(matchingRecords, context.matchingRecords);
    System.Assert.areEqual(1, context.matchingRecords.size());
  }

  @IsTest
  static void it_should_support_being_consumed_by_a_LoggerNotifiable_implementation() {
    LoggerNotifiableContext context = new LoggerNotifiableContext(
      new LoggerNotificationRule__c(),
      new LoggerNotificationRecipient__c(),
      new LoggerNotificationService__c(),
      new List<SObject>()
    );
    LocalMockNotifiable mockNotifier = new LocalMockNotifiable();

    mockNotifier.sendNotification(context);

    System.Assert.areEqual(1, mockNotifier.invocationCount);
    System.Assert.areEqual(context, mockNotifier.lastContext);
  }

  private class LocalMockNotifiable implements LoggerNotifiable {
    public Integer invocationCount = 0;
    public LoggerNotifiableContext lastContext;

    public LoggerNotifiableResult sendNotification(LoggerNotifiableContext context) {
      this.invocationCount++;
      this.lastContext = context;
      return null;
    }
  }
}
