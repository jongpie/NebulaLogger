//------------------------------------------------------------------------------------------------//
// Prototype 2: factory exposes interfaces. Tests use System.Test.createStub() against the
// interfaces with a small reusable LoggerStubHandler helper that turns Apex's bare-bones
// StubProvider into a fluent .when('method').thenReturn(value) API.
//------------------------------------------------------------------------------------------------//

/**
 * @description Single entry point for every repository in the codebase. Production callers go
 *              through `LoggerRepositoryFactory.getInstance().getLogRepository()`. Tests build
 *              stub instances via `System.Test.createStub(...)` and inject them per-interface
 *              with `LoggerRepositoryFactory.setMock(ILogRepository.class, mock)`.
 */
@SuppressWarnings('PMD.ApexDoc, PMD.CognitiveComplexity')
public without sharing class LoggerRepositoryFactory {
  private static LoggerRepositoryFactory instance = new LoggerRepositoryFactory();

  // Interface -> stub instance. Test-only; production never populates this.
  private static final Map<System.Type, Object> MOCK_OVERRIDES = new Map<System.Type, Object>();

  private LoggerRepositoryFactory() {
  }

  public static LoggerRepositoryFactory getInstance() {
    return instance;
  }

  @TestVisible
  private static void setMock(System.Type interfaceType, Object stubInstance) {
    MOCK_OVERRIDES.put(interfaceType, stubInstance);
  }

  // Each accessor returns the interface, not the concrete class. Tests inject by interface
  // type. Production receives the concrete (lazily-instantiated) repo.

  private LogRepositoryImpl logRepositoryInstance;
  public ILogRepository getLogRepository() {
    Object stub = MOCK_OVERRIDES.get(ILogRepository.class);
    if (stub != null) {
      return (ILogRepository) stub;
    }
    if (this.logRepositoryInstance == null) {
      this.logRepositoryInstance = new LogRepositoryImpl();
    }
    return this.logRepositoryInstance;
  }

  private GroupRepositoryImpl groupRepositoryInstance;
  public IGroupRepository getGroupRepository() {
    Object stub = MOCK_OVERRIDES.get(IGroupRepository.class);
    if (stub != null) {
      return (IGroupRepository) stub;
    }
    if (this.groupRepositoryInstance == null) {
      this.groupRepositoryInstance = new GroupRepositoryImpl();
    }
    return this.groupRepositoryInstance;
  }

  private UserRepositoryImpl userRepositoryInstance;
  public IUserRepository getUserRepository() {
    Object stub = MOCK_OVERRIDES.get(IUserRepository.class);
    if (stub != null) {
      return (IUserRepository) stub;
    }
    if (this.userRepositoryInstance == null) {
      this.userRepositoryInstance = new UserRepositoryImpl();
    }
    return this.userRepositoryInstance;
  }

  // ---------------------------------------------------------------------------------------------
  // Interfaces — what the production code & tests both depend on
  // ---------------------------------------------------------------------------------------------
  // These are the only contract the prototype exposes. Stub API requires interfaces (or virtual
  // classes) for createStub(); interfaces are cleaner because they prevent accidental "fall
  // through to real method" if a stub forgets to handle a call.

  public interface ILogRepository {
    List<Log__c> getLogsByTransactionId(List<String> transactionIds);
    List<Log__c> getLogsWithoutParentLogByParentTransactionId(List<String> parentTransactionIds);
  }

  public interface IGroupRepository {
    List<Schema.Group> getQueuesByDeveloperName(List<String> developerNames);
  }

  public interface IUserRepository {
    List<Schema.User> getUsersByUsername(List<String> usernames);
  }

  // ---------------------------------------------------------------------------------------------
  // Concrete implementations — same SOQL as today, just inside inner classes implementing the
  // interfaces. These are private so tests can't accidentally instantiate them.
  // ---------------------------------------------------------------------------------------------

  private class LogRepositoryImpl implements ILogRepository {
    public List<Log__c> getLogsByTransactionId(List<String> transactionIds) {
      return [SELECT Id, TransactionId__c FROM Log__c WHERE TransactionId__c IN :transactionIds];
    }
    public List<Log__c> getLogsWithoutParentLogByParentTransactionId(List<String> parentTransactionIds) {
      return [
        SELECT Id, ParentLogTransactionId__c, ParentLog__c, TransactionId__c
        FROM Log__c
        WHERE ParentLogTransactionId__c IN :parentTransactionIds AND ParentLog__c = NULL
      ];
    }
  }

  private class GroupRepositoryImpl implements IGroupRepository {
    public List<Schema.Group> getQueuesByDeveloperName(List<String> developerNames) {
      return [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :developerNames];
    }
  }

  private class UserRepositoryImpl implements IUserRepository {
    public List<Schema.User> getUsersByUsername(List<String> usernames) {
      return [SELECT Id, Username FROM User WHERE Username IN :usernames];
    }
  }
}
