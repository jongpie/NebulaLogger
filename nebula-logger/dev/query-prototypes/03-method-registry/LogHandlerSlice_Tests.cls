//------------------------------------------------------------------------------------------------//
// Prototype 3 — Tests configure stubs by calling whenCalled(...).thenReturn(...) directly on
// the repo instance returned by the factory. No factory subclass, no Test.createStub(), no
// interfaces — but every repo method body has an extra "if stub-registered, return stub" line.
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LogHandlerSlice_Tests {
  // ---------------------------------------------------------------------------------------------
  // Common case: stub ONE method on ONE repo
  // ---------------------------------------------------------------------------------------------
  @IsTest
  static void it_links_child_log_to_parent_log_when_parent_already_exists() {
    Id parentLogId = LoggerMockDataCreator.createId(Schema.Log__c.SObjectType);
    Log__c mockParentLog = new Log__c(Id = parentLogId, TransactionId__c = 'PARENT-TX');
    Log__c childLog = new Log__c(ParentLogTransactionId__c = 'PARENT-TX', TransactionId__c = 'CHILD-TX');

    LoggerRepositoryFactory.getInstance().getLogRepository().whenCalled('getLogsByTransactionId').thenReturn(new List<Log__c>{ mockParentLog });

    new LogHandlerSlice(new List<Log__c>{ childLog }, new Map<Id, String>()).run();

    System.Assert.areEqual(parentLogId, childLog.ParentLog__c);
    System.Assert.areEqual(1, LoggerRepositoryFactory.getInstance().getLogRepository().stubs.callCountFor('getLogsByTransactionId'));
  }

  // ---------------------------------------------------------------------------------------------
  // Complex case: stub THREE methods across THREE repos
  // ---------------------------------------------------------------------------------------------
  @IsTest
  static void it_sets_owner_id_to_queue_id_when_owner_name_matches_queue_developer_name() {
    Id childLogId = LoggerMockDataCreator.createId(Schema.Log__c.SObjectType);
    Id queueId = LoggerMockDataCreator.createId(Schema.Group.SObjectType);
    Log__c childLog = new Log__c(Id = childLogId, ParentLogTransactionId__c = 'PARENT-TX', TransactionId__c = 'CHILD-TX');
    Log__c mockParentLog = new Log__c(Id = LoggerMockDataCreator.createId(Schema.Log__c.SObjectType), TransactionId__c = 'PARENT-TX');
    Schema.Group mockQueue = new Schema.Group(Id = queueId, DeveloperName = 'Some_Queue', Type = 'Queue');

    LoggerRepositoryFactory factory = LoggerRepositoryFactory.getInstance();
    factory.getLogRepository().whenCalled('getLogsByTransactionId').thenReturn(new List<Log__c>{ mockParentLog });
    factory.getGroupRepository().whenCalled('getQueuesByDeveloperName').thenReturn(new List<Schema.Group>{ mockQueue });
    factory.getUserRepository().whenCalled('getUsersByUsername').thenReturn(new List<Schema.User>());

    new LogHandlerSlice(new List<Log__c>{ childLog }, new Map<Id, String>{ childLogId => 'Some_Queue' }).run();

    System.Assert.areEqual(queueId, childLog.OwnerId);
    System.Assert.areEqual(1, factory.getGroupRepository().stubs.callCountFor('getQueuesByDeveloperName'));
    System.Assert.areEqual(1, factory.getUserRepository().stubs.callCountFor('getUsersByUsername'));
  }
}
