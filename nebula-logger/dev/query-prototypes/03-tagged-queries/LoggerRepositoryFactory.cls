//------------------------------------------------------------------------------------------------//
// Prototype 3 — Repository facade. Same shape as Prototypes 1 and 2: thin, with most queries
// living inline at call sites via LoggerQuery.of(...). Only domain helpers that genuinely don't
// fit at a call site survive here.
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
  // through LoggerQuery.mockResult(tag, ...).

  private LogRepository logRepositoryInstance;
  public LogRepository getLogRepository() {
    if (this.logRepositoryInstance == null) {
      this.logRepositoryInstance = new LogRepository();
    }
    return this.logRepositoryInstance;
  }

  // ---------------------------------------------------------------------------------------------
  // Repos. Only one query survives as a domain helper — see Prototype 1's notes for the rationale.
  // ---------------------------------------------------------------------------------------------

  public class LogRepository {
    /**
     * @description Loads a single Log__c by Id with every field on the object plus a few
     *              parent-relationship fields. The query is tagged so tests can stub it without
     *              depending on internal field selection.
     */
    public Log__c getByIdWithAllFields(Id logId) {
      List<String> fieldPaths = new List<String>(Schema.Log__c.SObjectType.getDescribe().fields.getMap().keySet());
      fieldPaths.add('Owner.Name');
      fieldPaths.add('Owner.Type');
      LoggerQuery query = LoggerQuery.of(Schema.Log__c.SObjectType)
        .tag('LogRepository.getByIdWithAllFields')
        .whereField(Schema.Log__c.Id)
        .equals(logId)
        .setLimit(1);
      for (String fieldPath : fieldPaths) {
        query.selectFieldPath(fieldPath);
      }
      return (Log__c) query.toRecord();
    }
  }
}
