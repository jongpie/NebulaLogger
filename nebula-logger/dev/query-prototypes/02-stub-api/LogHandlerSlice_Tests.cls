//------------------------------------------------------------------------------------------------//
// Prototype 2 — Tests stub repos by creating a Test.createStub() against the per-repo interface,
// then injecting it via LoggerRepositoryFactory.setMock(IXxx.class, stub). LoggerStubHandler
// turns the bare-bones System.StubProvider API into a fluent .whenCalled(...).whenCalled(...)
// builder, and tracks call counts so tests can assert behavior.
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

    LoggerStubHandler logRepoStub = new LoggerStubHandler().whenCalled('getLogsByTransactionId', new List<Log__c>{ mockParentLog });
    LoggerRepositoryFactory.setMock(
      LoggerRepositoryFactory.ILogRepository.class,
      System.Test.createStub(LoggerRepositoryFactory.ILogRepository.class, logRepoStub)
    );

    new LogHandlerSlice(new List<Log__c>{ childLog }, new Map<Id, String>()).run();

    System.Assert.areEqual(parentLogId, childLog.ParentLog__c);
    System.Assert.areEqual(1, logRepoStub.callCountFor('getLogsByTransactionId'));
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

    LoggerStubHandler logRepoStub = new LoggerStubHandler().whenCalled('getLogsByTransactionId', new List<Log__c>{ mockParentLog });
    LoggerStubHandler groupRepoStub = new LoggerStubHandler().whenCalled('getQueuesByDeveloperName', new List<Schema.Group>{ mockQueue });
    LoggerStubHandler userRepoStub = new LoggerStubHandler().whenCalled('getUsersByUsername', new List<Schema.User>());
    LoggerRepositoryFactory.setMock(
      LoggerRepositoryFactory.ILogRepository.class,
      System.Test.createStub(LoggerRepositoryFactory.ILogRepository.class, logRepoStub)
    );
    LoggerRepositoryFactory.setMock(
      LoggerRepositoryFactory.IGroupRepository.class,
      System.Test.createStub(LoggerRepositoryFactory.IGroupRepository.class, groupRepoStub)
    );
    LoggerRepositoryFactory.setMock(
      LoggerRepositoryFactory.IUserRepository.class,
      System.Test.createStub(LoggerRepositoryFactory.IUserRepository.class, userRepoStub)
    );

    new LogHandlerSlice(new List<Log__c>{ childLog }, new Map<Id, String>{ childLogId => 'Some_Queue' }).run();

    System.Assert.areEqual(queueId, childLog.OwnerId);
    System.Assert.areEqual(1, groupRepoStub.callCountFor('getQueuesByDeveloperName'));
    System.Assert.areEqual(1, userRepoStub.callCountFor('getUsersByUsername'));
  }
}
