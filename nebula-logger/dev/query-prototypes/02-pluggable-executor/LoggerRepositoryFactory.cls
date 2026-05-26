//------------------------------------------------------------------------------------------------//
// Prototype 2 — Repository facade. Same shape as Prototype 1: thin, exists for DML pass-through
// to LoggerDataStore and a small handful of non-trivial domain helpers. Routine queries live at
// the call site as inline LoggerQuery builders.
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc')
public without sharing class LoggerRepositoryFactory {
  private static LoggerRepositoryFactory instance = new LoggerRepositoryFactory();

  private LoggerRepositoryFactory() {
  }

  public static LoggerRepositoryFactory getInstance() {
    return instance;
  }

  private LogRepository logRepositoryInstance;
  public LogRepository getLogRepository() {
    if (this.logRepositoryInstance == null) {
      this.logRepositoryInstance = new LogRepository();
    }
    return this.logRepositoryInstance;
  }

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
