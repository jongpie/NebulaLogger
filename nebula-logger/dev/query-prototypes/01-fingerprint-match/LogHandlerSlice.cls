//------------------------------------------------------------------------------------------------//
// Prototype 1 — production-side slice. Note that NO Selector / Repository methods are called for
// the routine queries — they're built inline with LoggerQuery. The repo only shows up when
// something genuinely worth abstracting (e.g. getByIdWithAllFields) is needed; this slice
// doesn't need it.
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

    // Inline dynamic query — no Selector / Repository method needed.
    List<Log__c> parentLogs = (List<Log__c>) LoggerQuery.of(Schema.Log__c.SObjectType)
      .selectFields(new List<Schema.SObjectField>{ Schema.Log__c.Id, Schema.Log__c.TransactionId__c })
      .whereField(Schema.Log__c.TransactionId__c)
      .inCollection(parentLogTransactionIds)
      .toList();

    Map<String, Id> txIdToParentRecordId = new Map<String, Id>();
    for (Log__c parentLog : parentLogs) {
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

    List<Schema.Group> queues = (List<Schema.Group>) LoggerQuery.of(Schema.Group.SObjectType)
      .selectFields(new List<Schema.SObjectField>{ Schema.Group.Id, Schema.Group.DeveloperName })
      .whereField(Schema.Group.Type)
      .equals('Queue')
      .whereField(Schema.Group.DeveloperName)
      .inCollection(possibleOwnerNames)
      .toList();

    List<Schema.User> users = (List<Schema.User>) LoggerQuery.of(Schema.User.SObjectType)
      .selectFields(new List<Schema.SObjectField>{ Schema.User.Id, Schema.User.Username })
      .whereField(Schema.User.Username)
      .inCollection(possibleOwnerNames)
      .toList();

    Map<String, Id> ownerIdByName = new Map<String, Id>();
    for (Schema.Group queue : queues) {
      ownerIdByName.put(queue.DeveloperName, queue.Id);
    }
    for (Schema.User user : users) {
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
