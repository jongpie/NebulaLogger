//------------------------------------------------------------------------------------------------//
// Prototype 3 — production-side slice. Identical to Prototypes 1 & 2; the call sites read the
// same way. The "method registry" complexity is hidden inside the repo classes, so callers
// don't have to know it exists.
//------------------------------------------------------------------------------------------------//

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
