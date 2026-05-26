//------------------------------------------------------------------------------------------------//
// Prototype 1 — production-side slice of LogHandler that exercises 3 repositories. The shape of
// the production code is identical across all 3 prototypes; only the test code differs.
//------------------------------------------------------------------------------------------------//

/**
 * @description Reduced version of `LogHandler.executeBeforeInsert` covering 3 repository calls:
 *              parent-log lookup, queue lookup, and user lookup. Used to compare prototype
 *              ergonomics against `LogHandlerSlice_Tests`.
 *
 * The real `LogHandler` reads owner names from `LoggerSettings__c`; the slice takes them in via
 * the constructor so the prototype stays self-contained and the tests can focus on repo mocking.
 */
@SuppressWarnings('PMD.ApexDoc')
public without sharing class LogHandlerSlice {
  private final List<Log__c> logs;
  private final Map<Id, String> ownerNameByLogId;

  public LogHandlerSlice(List<Log__c> logs, Map<Id, String> ownerNameByLogId) {
    this.logs = logs;
    this.ownerNameByLogId = ownerNameByLogId;
  }

  public void run() {
    this.setParentLog();
    this.setOwnerId();
  }

  private void setParentLog() {
    List<String> parentLogTransactionIds = new List<String>();
    for (Log__c log : this.logs) {
      if (String.isNotBlank(log.ParentLogTransactionId__c)) {
        parentLogTransactionIds.add(log.ParentLogTransactionId__c);
      }
    }
    if (parentLogTransactionIds.isEmpty()) {
      return;
    }

    Map<String, Id> txIdToParentRecordId = new Map<String, Id>();
    for (Log__c parentLog : LoggerRepositoryFactory.getInstance().getLogRepository().getLogsByTransactionId(parentLogTransactionIds)) {
      txIdToParentRecordId.put(parentLog.TransactionId__c, parentLog.Id);
    }
    for (Log__c log : this.logs) {
      if (String.isNotBlank(log.ParentLogTransactionId__c)) {
        log.ParentLog__c = txIdToParentRecordId.get(log.ParentLogTransactionId__c);
      }
    }
  }

  private void setOwnerId() {
    List<String> possibleOwnerNames = new List<String>();
    for (Log__c log : this.logs) {
      String ownerName = this.ownerNameByLogId.get(log.Id);
      if (String.isNotBlank(ownerName) && (ownerName instanceof Id) == false) {
        possibleOwnerNames.add(ownerName);
      }
    }
    if (possibleOwnerNames.isEmpty()) {
      return;
    }

    Map<String, Id> ownerIdByName = new Map<String, Id>();
    for (Schema.Group queue : LoggerRepositoryFactory.getInstance().getGroupRepository().getQueuesByDeveloperName(possibleOwnerNames)) {
      ownerIdByName.put(queue.DeveloperName, queue.Id);
    }
    for (Schema.User user : LoggerRepositoryFactory.getInstance().getUserRepository().getUsersByUsername(possibleOwnerNames)) {
      ownerIdByName.put(user.Username, user.Id);
    }

    for (Log__c log : this.logs) {
      String ownerName = this.ownerNameByLogId.get(log.Id);
      if (ownerIdByName.containsKey(ownerName)) {
        log.OwnerId = ownerIdByName.get(ownerName);
      }
    }
  }
}
