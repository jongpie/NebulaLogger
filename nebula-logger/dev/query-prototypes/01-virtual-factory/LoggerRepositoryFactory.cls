//------------------------------------------------------------------------------------------------//
// Prototype 1: virtual factory + virtual repos. Tests subclass either the factory or a repo
// and override the methods they need to stub.
//------------------------------------------------------------------------------------------------//

/**
 * @description Single entry point for every repository in the codebase. Production callers go
 *              through `LoggerRepositoryFactory.getInstance().getLogRepository()` (etc.). Tests
 *              call `LoggerRepositoryFactory.setMock(myMockFactory)` and provide a subclass of
 *              this class with overridden `getXxxRepository()` methods that return mock repos.
 */
@SuppressWarnings('PMD.ApexDoc')
public virtual without sharing class LoggerRepositoryFactory {
  private static LoggerRepositoryFactory instance = new LoggerRepositoryFactory();

  @TestVisible
  protected LoggerRepositoryFactory() {
  }

  public static LoggerRepositoryFactory getInstance() {
    return instance;
  }

  @TestVisible
  private static void setMock(LoggerRepositoryFactory mockFactory) {
    instance = mockFactory;
  }

  // Each accessor is virtual so a test can either:
  //   (a) subclass LoggerRepositoryFactory and override getLogRepository() to return a mock repo, OR
  //   (b) subclass the concrete repo (e.g. LogRepository) and override the specific query method,
  //       then have the factory subclass return that custom subclass.
  // Lazy init so we don't construct repos that aren't used in a given transaction.

  private LogRepository logRepositoryInstance;
  public virtual LogRepository getLogRepository() {
    if (this.logRepositoryInstance == null) {
      this.logRepositoryInstance = new LogRepository();
    }
    return this.logRepositoryInstance;
  }

  private GroupRepository groupRepositoryInstance;
  public virtual GroupRepository getGroupRepository() {
    if (this.groupRepositoryInstance == null) {
      this.groupRepositoryInstance = new GroupRepository();
    }
    return this.groupRepositoryInstance;
  }

  private UserRepository userRepositoryInstance;
  public virtual UserRepository getUserRepository() {
    if (this.userRepositoryInstance == null) {
      this.userRepositoryInstance = new UserRepository();
    }
    return this.userRepositoryInstance;
  }

  // ---------------------------------------------------------------------------------------------
  // Repositories
  // ---------------------------------------------------------------------------------------------
  // Inner classes so the public top-level surface stays at 1 class. Each is virtual so tests can
  // subclass + override individual query methods. Long-term these would compose with LoggerQuery
  // for typed query building; for the prototype, hand-written queries are fine.

  public virtual class LogRepository {
    @TestVisible
    protected LogRepository() {
    }

    public virtual List<Log__c> getLogsByTransactionId(List<String> transactionIds) {
      return [SELECT Id, TransactionId__c FROM Log__c WHERE TransactionId__c IN :transactionIds];
    }

    public virtual List<Log__c> getLogsWithoutParentLogByParentTransactionId(List<String> parentTransactionIds) {
      return [
        SELECT Id, ParentLogTransactionId__c, ParentLog__c, TransactionId__c
        FROM Log__c
        WHERE ParentLogTransactionId__c IN :parentTransactionIds AND ParentLog__c = NULL
      ];
    }
  }

  public virtual class GroupRepository {
    @TestVisible
    protected GroupRepository() {
    }

    public virtual List<Schema.Group> getQueuesByDeveloperName(List<String> developerNames) {
      return [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :developerNames];
    }
  }

  public virtual class UserRepository {
    @TestVisible
    protected UserRepository() {
    }

    public virtual List<Schema.User> getUsersByUsername(List<String> usernames) {
      return [SELECT Id, Username FROM User WHERE Username IN :usernames];
    }
  }
}
