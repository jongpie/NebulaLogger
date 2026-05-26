//------------------------------------------------------------------------------------------------//
// Prototype 3: factory returns concrete repos, but each public repo method consults a per-repo
// "stub registry" before running its real query. Tests configure the registry via
// repo.whenCalled('methodName').thenReturn(value); production never touches it.
//
// No interfaces, no subclassing — but every repo method body has one extra line at the top.
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CognitiveComplexity, PMD.CyclomaticComplexity')
public without sharing class LoggerRepositoryFactory {
  private static LoggerRepositoryFactory instance = new LoggerRepositoryFactory();

  private LoggerRepositoryFactory() {
  }

  public static LoggerRepositoryFactory getInstance() {
    return instance;
  }

  // No factory-level setMock(): each repo carries its own stub registry. Tests just call
  // factory.getLogRepository().whenCalled('methodName').thenReturn(value). Repos are still
  // singletons within the factory, so the stub config persists across calls in a transaction.

  private LogRepository logRepositoryInstance;
  public LogRepository getLogRepository() {
    if (this.logRepositoryInstance == null) {
      this.logRepositoryInstance = new LogRepository();
    }
    return this.logRepositoryInstance;
  }

  private GroupRepository groupRepositoryInstance;
  public GroupRepository getGroupRepository() {
    if (this.groupRepositoryInstance == null) {
      this.groupRepositoryInstance = new GroupRepository();
    }
    return this.groupRepositoryInstance;
  }

  private UserRepository userRepositoryInstance;
  public UserRepository getUserRepository() {
    if (this.userRepositoryInstance == null) {
      this.userRepositoryInstance = new UserRepository();
    }
    return this.userRepositoryInstance;
  }

  // ---------------------------------------------------------------------------------------------
  // StubRegistry — one per repo instance. Tests configure it; production reads from it.
  // ---------------------------------------------------------------------------------------------

  public class StubRegistry {
    private final Map<String, Object> returnValuesByMethodName = new Map<String, Object>();
    private final Map<String, Integer> callCountsByMethodName = new Map<String, Integer>();
    private String currentMethodName;

    /**
     * @description Begin configuring a stub for the given method name. Chain `.thenReturn(value)`.
     */
    public StubRegistry whenCalled(String methodName) {
      this.currentMethodName = methodName;
      return this;
    }

    public StubRegistry thenReturn(Object returnValue) {
      if (this.currentMethodName == null) {
        throw new System.IllegalArgumentException('thenReturn() must be preceded by whenCalled(methodName)');
      }
      this.returnValuesByMethodName.put(this.currentMethodName, returnValue);
      this.currentMethodName = null;
      return this;
    }

    public Boolean hasStubFor(String methodName) {
      this.recordCall(methodName);
      return this.returnValuesByMethodName.containsKey(methodName);
    }

    public Object stubResultFor(String methodName) {
      return this.returnValuesByMethodName.get(methodName);
    }

    public Integer callCountFor(String methodName) {
      return this.callCountsByMethodName.containsKey(methodName) ? this.callCountsByMethodName.get(methodName) : 0;
    }

    private void recordCall(String methodName) {
      Integer prior = this.callCountsByMethodName.containsKey(methodName) ? this.callCountsByMethodName.get(methodName) : 0;
      this.callCountsByMethodName.put(methodName, prior + 1);
    }
  }

  // ---------------------------------------------------------------------------------------------
  // Repositories. Each method body has the same shape:
  //   if (this.stubs.hasStubFor('methodName')) return (CastType) this.stubs.stubResultFor('methodName');
  //   …real SOQL…
  // ---------------------------------------------------------------------------------------------

  public class LogRepository {
    public final StubRegistry stubs = new StubRegistry();

    public StubRegistry whenCalled(String methodName) {
      return this.stubs.whenCalled(methodName);
    }

    public List<Log__c> getLogsByTransactionId(List<String> transactionIds) {
      if (this.stubs.hasStubFor('getLogsByTransactionId')) {
        return (List<Log__c>) this.stubs.stubResultFor('getLogsByTransactionId');
      }
      return [SELECT Id, TransactionId__c FROM Log__c WHERE TransactionId__c IN :transactionIds];
    }

    public List<Log__c> getLogsWithoutParentLogByParentTransactionId(List<String> parentTransactionIds) {
      if (this.stubs.hasStubFor('getLogsWithoutParentLogByParentTransactionId')) {
        return (List<Log__c>) this.stubs.stubResultFor('getLogsWithoutParentLogByParentTransactionId');
      }
      return [
        SELECT Id, ParentLogTransactionId__c, ParentLog__c, TransactionId__c
        FROM Log__c
        WHERE ParentLogTransactionId__c IN :parentTransactionIds AND ParentLog__c = NULL
      ];
    }
  }

  public class GroupRepository {
    public final StubRegistry stubs = new StubRegistry();

    public StubRegistry whenCalled(String methodName) {
      return this.stubs.whenCalled(methodName);
    }

    public List<Schema.Group> getQueuesByDeveloperName(List<String> developerNames) {
      if (this.stubs.hasStubFor('getQueuesByDeveloperName')) {
        return (List<Schema.Group>) this.stubs.stubResultFor('getQueuesByDeveloperName');
      }
      return [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :developerNames];
    }
  }

  public class UserRepository {
    public final StubRegistry stubs = new StubRegistry();

    public StubRegistry whenCalled(String methodName) {
      return this.stubs.whenCalled(methodName);
    }

    public List<Schema.User> getUsersByUsername(List<String> usernames) {
      if (this.stubs.hasStubFor('getUsersByUsername')) {
        return (List<Schema.User>) this.stubs.stubResultFor('getUsersByUsername');
      }
      return [SELECT Id, Username FROM User WHERE Username IN :usernames];
    }
  }
}
