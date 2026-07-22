//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotificationAsyncDispatcher_Tests {
  private static final String MOCK_NOTIFIER_CLASS = MockNotifier.class.getName();
  private static Integer mockNotifierInvocationCount = 0;
  private static Integer mockNotifierThrownCount = 0;
  private static Boolean mockNotifierShouldThrowNext = false;

  private static void resetMockNotifier() {
    mockNotifierInvocationCount = 0;
    mockNotifierThrownCount = 0;
    mockNotifierShouldThrowNext = false;
  }

  @IsTest
  static void it_should_handle_null_and_empty_dispatch_lists_without_error() {
    resetMockNotifier();
    LoggerNotificationAsyncDispatcher nullDispatcher = new LoggerNotificationAsyncDispatcher(null);
    LoggerNotificationAsyncDispatcher emptyDispatcher = new LoggerNotificationAsyncDispatcher(new List<LoggerNotificationAsyncDispatcher.PendingDispatch>());

    System.Test.startTest();
    nullDispatcher.execute(null);
    emptyDispatcher.execute(null);
    System.Test.stopTest();

    System.Assert.areEqual(0, mockNotifierInvocationCount);
  }

  @IsTest
  static void it_should_invoke_each_notifier_for_each_pending_dispatch() {
    resetMockNotifier();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(MOCK_NOTIFIER_CLASS),
      buildDispatch(MOCK_NOTIFIER_CLASS),
      buildDispatch(MOCK_NOTIFIER_CLASS)
    };
    LoggerNotificationAsyncDispatcher dispatcher = new LoggerNotificationAsyncDispatcher(dispatches);

    System.Test.startTest();
    dispatcher.execute(null);
    System.Test.stopTest();

    System.Assert.areEqual(3, mockNotifierInvocationCount);
  }

  @IsTest
  static void it_should_swallow_exceptions_thrown_by_a_notifier_and_continue() {
    resetMockNotifier();
    mockNotifierShouldThrowNext = true;
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(MOCK_NOTIFIER_CLASS),
      buildDispatch(MOCK_NOTIFIER_CLASS)
    };
    LoggerNotificationAsyncDispatcher dispatcher = new LoggerNotificationAsyncDispatcher(dispatches);

    System.Test.startTest();
    dispatcher.execute(null);
    System.Test.stopTest();

    System.Assert.areEqual(2, mockNotifierInvocationCount, 'Subsequent dispatch should still fire after a prior one throws');
    System.Assert.areEqual(1, mockNotifierThrownCount, 'The first dispatch should have thrown');
  }

  @IsTest
  static void it_should_skip_dispatch_when_notifier_class_cannot_be_instantiated() {
    resetMockNotifier();
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch('SomeApexClassThatDoesNotExist'),
      buildDispatch(MOCK_NOTIFIER_CLASS)
    };
    LoggerNotificationAsyncDispatcher dispatcher = new LoggerNotificationAsyncDispatcher(dispatches);

    System.Test.startTest();
    dispatcher.execute(null);
    System.Test.stopTest();

    System.Assert.areEqual(1, mockNotifierInvocationCount, 'Valid dispatch should still fire even if an earlier one failed to instantiate');
  }

  @IsTest
  static void it_should_expose_pending_dispatches_via_the_testVisible_field() {
    List<LoggerNotificationAsyncDispatcher.PendingDispatch> dispatches = new List<LoggerNotificationAsyncDispatcher.PendingDispatch>{
      buildDispatch(MOCK_NOTIFIER_CLASS)
    };

    LoggerNotificationAsyncDispatcher dispatcher = new LoggerNotificationAsyncDispatcher(dispatches);

    System.Assert.areEqual(1, dispatcher.pendingDispatches.size());
  }

  private static LoggerNotificationAsyncDispatcher.PendingDispatch buildDispatch(String apexClassName) {
    LoggerNotificationService__c service = new LoggerNotificationService__c(
      Name = 'Mock service',
      NotifierApexClassName__c = apexClassName,
      IsEnabled__c = true,
      OriginOrganizationId__c = System.UserInfo.getOrganizationId(),
      WebhookUrl__c = 'https://example.com/webhook'
    );
    LoggerNotificationRule__c rule = new LoggerNotificationRule__c(Name = 'Test rule', SourceSObjectType__c = 'LogEntry__c');
    // PendingDispatch snapshots rule + service from the recipient's parent relationships at construction
    // time, so both __r lookups have to be populated on the recipient. In-memory SObject relationships
    // aren't directly assignable in Apex; round-trip through JSON to attach them.
    LoggerNotificationRecipient__c recipient = (LoggerNotificationRecipient__c) System.JSON.deserialize(
      System.JSON.serialize(
        new Map<String, Object>{
          'attributes' => new Map<String, String>{ 'type' => 'LoggerNotificationRecipient__c' },
          'LoggerNotificationRule__r' => rule,
          'LoggerNotificationService__r' => service
        }
      ),
      LoggerNotificationRecipient__c.class
    );
    return new LoggerNotificationAsyncDispatcher.PendingDispatch(
      recipient,
      new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name()) },
      null
    );
  }

  public class MockNotifier extends LoggerNotifier {
    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      mockNotifierInvocationCount++;
      if (mockNotifierShouldThrowNext) {
        mockNotifierShouldThrowNext = false;
        mockNotifierThrownCount++;
        throw new System.CalloutException('Simulated notifier failure');
      }
      return null;
    }
  }
}
