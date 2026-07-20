//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotifierAsyncDispatcher_Tests {
  private static final String MOCK_NOTIFIER_CLASS = MockNotifiable.class.getName();
  private static Integer mockNotifiableInvocationCount = 0;
  private static Integer mockNotifiableThrownCount = 0;
  private static Boolean mockNotifiableShouldThrowNext = false;

  private static void resetMockNotifiable() {
    mockNotifiableInvocationCount = 0;
    mockNotifiableThrownCount = 0;
    mockNotifiableShouldThrowNext = false;
  }

  @IsTest
  static void it_should_handle_null_and_empty_dispatch_lists_without_error() {
    resetMockNotifiable();
    LoggerNotifierAsyncDispatcher nullDispatcher = new LoggerNotifierAsyncDispatcher(null);
    LoggerNotifierAsyncDispatcher emptyDispatcher = new LoggerNotifierAsyncDispatcher(new List<LoggerNotifierAsyncDispatcher.PendingDispatch>());

    System.Test.startTest();
    nullDispatcher.execute(null);
    emptyDispatcher.execute(null);
    System.Test.stopTest();

    System.Assert.areEqual(0, mockNotifiableInvocationCount);
  }

  @IsTest
  static void it_should_invoke_each_notifier_for_each_pending_dispatch() {
    resetMockNotifiable();
    List<LoggerNotifierAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotifierAsyncDispatcher.PendingDispatch>{
      buildDispatch(MOCK_NOTIFIER_CLASS),
      buildDispatch(MOCK_NOTIFIER_CLASS),
      buildDispatch(MOCK_NOTIFIER_CLASS)
    };
    LoggerNotifierAsyncDispatcher dispatcher = new LoggerNotifierAsyncDispatcher(dispatches);

    System.Test.startTest();
    dispatcher.execute(null);
    System.Test.stopTest();

    System.Assert.areEqual(3, mockNotifiableInvocationCount);
  }

  @IsTest
  static void it_should_swallow_exceptions_thrown_by_a_notifier_and_continue() {
    resetMockNotifiable();
    mockNotifiableShouldThrowNext = true;
    List<LoggerNotifierAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotifierAsyncDispatcher.PendingDispatch>{
      buildDispatch(MOCK_NOTIFIER_CLASS),
      buildDispatch(MOCK_NOTIFIER_CLASS)
    };
    LoggerNotifierAsyncDispatcher dispatcher = new LoggerNotifierAsyncDispatcher(dispatches);

    System.Test.startTest();
    dispatcher.execute(null);
    System.Test.stopTest();

    System.Assert.areEqual(2, mockNotifiableInvocationCount, 'Subsequent dispatch should still fire after a prior one throws');
    System.Assert.areEqual(1, mockNotifiableThrownCount, 'The first dispatch should have thrown');
  }

  @IsTest
  static void it_should_skip_dispatch_when_notifier_class_cannot_be_instantiated() {
    resetMockNotifiable();
    List<LoggerNotifierAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotifierAsyncDispatcher.PendingDispatch>{
      buildDispatch('SomeApexClassThatDoesNotExist'),
      buildDispatch(MOCK_NOTIFIER_CLASS)
    };
    LoggerNotifierAsyncDispatcher dispatcher = new LoggerNotifierAsyncDispatcher(dispatches);

    System.Test.startTest();
    dispatcher.execute(null);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifiableInvocationCount, 'Valid dispatch should still fire even if an earlier one failed to instantiate');
  }

  @IsTest
  static void it_should_expose_pending_dispatches_via_the_testVisible_field() {
    List<LoggerNotifierAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotifierAsyncDispatcher.PendingDispatch>{
      buildDispatch(MOCK_NOTIFIER_CLASS)
    };

    LoggerNotifierAsyncDispatcher dispatcher = new LoggerNotifierAsyncDispatcher(dispatches);

    System.Assert.areEqual(1, dispatcher.pendingDispatches.size());
  }

  private static LoggerNotifierAsyncDispatcher.PendingDispatch buildDispatch(String apexClassName) {
    LoggerNotificationService__c service = new LoggerNotificationService__c(
      Name = 'Mock service',
      NotifierApexClassName__c = apexClassName,
      IsEnabled__c = true,
      OriginOrganizationId__c = System.UserInfo.getOrganizationId(),
      WebhookUrl__c = 'https://example.com/webhook'
    );
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c();
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(Name = 'Test rule', SourceSObjectType__c = 'LogEntry__c');
    return new LoggerNotifierAsyncDispatcher.PendingDispatch(rule, recipient, service, new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') });
  }

  public class MockNotifiable implements LoggerNotifiable {
    public LoggerNotifiableResult sendNotification(LoggerNotifiableContext context) {
      mockNotifiableInvocationCount++;
      if (mockNotifiableShouldThrowNext) {
        mockNotifiableShouldThrowNext = false;
        mockNotifiableThrownCount++;
        throw new System.CalloutException('Simulated notifier failure');
      }
      return null;
    }
  }
}
