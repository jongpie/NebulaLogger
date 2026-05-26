//------------------------------------------------------------------------------------------------//
// Prototype 1 — Tests stub repositories by subclassing LoggerRepositoryFactory and the relevant
// inner repository classes, then injecting the subclass via setMock(). This is the most
// type-safe option (everything is compile-checked) but the most boilerplate-heavy: each method
// you stub needs an override.
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

    StubLogRepository stubLogRepo = new StubLogRepository();
    stubLogRepo.logsByTransactionIdResult = new List<Log__c>{ mockParentLog };
    LoggerRepositoryFactory.setMock(new StubFactory().withLogRepository(stubLogRepo));

    new LogHandlerSlice(new List<Log__c>{ childLog }, new Map<Id, String>()).run();

    System.Assert.areEqual(parentLogId, childLog.ParentLog__c);
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

    StubLogRepository stubLogRepo = new StubLogRepository();
    stubLogRepo.logsByTransactionIdResult = new List<Log__c>{ mockParentLog };
    StubGroupRepository stubGroupRepo = new StubGroupRepository();
    stubGroupRepo.queuesByDeveloperNameResult = new List<Schema.Group>{ mockQueue };
    StubUserRepository stubUserRepo = new StubUserRepository();
    stubUserRepo.usersByUsernameResult = new List<Schema.User>(); // no user matches the name -> queue wins
    LoggerRepositoryFactory.setMock(
      new StubFactory().withLogRepository(stubLogRepo).withGroupRepository(stubGroupRepo).withUserRepository(stubUserRepo)
    );

    new LogHandlerSlice(new List<Log__c>{ childLog }, new Map<Id, String>{ childLogId => 'Some_Queue' }).run();

    System.Assert.areEqual(queueId, childLog.OwnerId);
  }

  // ---------------------------------------------------------------------------------------------
  // Mock factory + per-repo subclasses
  // ---------------------------------------------------------------------------------------------
  // Factory subclass exposes setters for test-supplied repo overrides. Any repo not explicitly
  // stubbed falls through to the real one, so a test can stub the minimum it cares about.
  private class StubFactory extends LoggerRepositoryFactory {
    private LoggerRepositoryFactory.LogRepository logRepoOverride;
    private LoggerRepositoryFactory.GroupRepository groupRepoOverride;
    private LoggerRepositoryFactory.UserRepository userRepoOverride;

    public StubFactory withLogRepository(LoggerRepositoryFactory.LogRepository repo) {
      this.logRepoOverride = repo;
      return this;
    }
    public StubFactory withGroupRepository(LoggerRepositoryFactory.GroupRepository repo) {
      this.groupRepoOverride = repo;
      return this;
    }
    public StubFactory withUserRepository(LoggerRepositoryFactory.UserRepository repo) {
      this.userRepoOverride = repo;
      return this;
    }

    public override LoggerRepositoryFactory.LogRepository getLogRepository() {
      return this.logRepoOverride ?? super.getLogRepository();
    }
    public override LoggerRepositoryFactory.GroupRepository getGroupRepository() {
      return this.groupRepoOverride ?? super.getGroupRepository();
    }
    public override LoggerRepositoryFactory.UserRepository getUserRepository() {
      return this.userRepoOverride ?? super.getUserRepository();
    }
  }

  // Each stub repo holds a public field per query method. Tests set the field, the override
  // returns it. Compile-time safe — renaming a method on the base class breaks compilation here.
  private class StubLogRepository extends LoggerRepositoryFactory.LogRepository {
    public List<Log__c> logsByTransactionIdResult;
    public List<Log__c> logsWithoutParentLogResult;

    public override List<Log__c> getLogsByTransactionId(List<String> transactionIds) {
      return this.logsByTransactionIdResult ?? new List<Log__c>();
    }
    public override List<Log__c> getLogsWithoutParentLogByParentTransactionId(List<String> parentTransactionIds) {
      return this.logsWithoutParentLogResult ?? new List<Log__c>();
    }
  }

  private class StubGroupRepository extends LoggerRepositoryFactory.GroupRepository {
    public List<Schema.Group> queuesByDeveloperNameResult;

    public override List<Schema.Group> getQueuesByDeveloperName(List<String> developerNames) {
      return this.queuesByDeveloperNameResult ?? new List<Schema.Group>();
    }
  }

  private class StubUserRepository extends LoggerRepositoryFactory.UserRepository {
    public List<Schema.User> usersByUsernameResult;

    public override List<Schema.User> getUsersByUsername(List<String> usernames) {
      return this.usersByUsernameResult ?? new List<Schema.User>();
    }
  }
}
