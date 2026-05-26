//------------------------------------------------------------------------------------------------//
// Prototype 1 — Repository facade. Repos here are intentionally thin: most call sites build
// queries inline with LoggerQuery.of(...). Repos exist for (a) DML pass-through to
// LoggerDataStore, and (b) a small handful of genuinely non-trivial domain helpers (e.g. cached
// queries, queries that compose with feature flags). Routine `get X by Y` queries do NOT live
// here — the call site builds them with LoggerQuery directly.
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc')
public without sharing class LoggerRepositoryFactory {
  private static LoggerRepositoryFactory instance = new LoggerRepositoryFactory();

  private LoggerRepositoryFactory() {
  }

  public static LoggerRepositoryFactory getInstance() {
    return instance;
  }

  // No setMock at the factory level — there's nothing here that hides a query. All mocking goes
  // through LoggerQuery.mockResult().

  private LogRepository logRepositoryInstance;
  public LogRepository getLogRepository() {
    if (this.logRepositoryInstance == null) {
      this.logRepositoryInstance = new LogRepository();
    }
    return this.logRepositoryInstance;
  }

  // ---------------------------------------------------------------------------------------------
  // Repos. Note how few methods exist — the prior LogManagementDataSelector had ~25, this has 1.
  // The 1 method that survives is one that genuinely benefits from being centralized: the
  // "load all fields including parent fields" pattern. Routine filter-by-X queries are gone.
  // ---------------------------------------------------------------------------------------------

  public class LogRepository {
    /**
     * @description Loads a single Log__c by Id with every field on the object plus a few
     *              parent-relationship fields. This stays as a domain helper because the
     *              "every field" pattern is awkward to express inline at every call site.
     */
    public Log__c getByIdWithAllFields(Id logId) {
      List<String> fieldPaths = new List<String>(Schema.Log__c.SObjectType.getDescribe().fields.getMap().keySet());
      fieldPaths.add('Owner.Name');
      fieldPaths.add('Owner.Type');
      LoggerQuery query = LoggerQuery.of(Schema.Log__c.SObjectType).whereField(Schema.Log__c.Id).equals(logId).setLimit(1);
      for (String fieldPath : fieldPaths) {
        query.selectFieldPath(fieldPath);
      }
      return (Log__c) query.toRecord();
    }
  }
}
