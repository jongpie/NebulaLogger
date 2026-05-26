//------------------------------------------------------------------------------------------------//
// Prototype 3 — Tests stub queries by their tag string. Each tag is a unique identifier the
// production code wrote into the query, so there's no fingerprint ambiguity and no executor to
// configure — just `LoggerQuery.mockResult(tag, result)`.
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LogHandlerSlice_Tests {
  // ---------------------------------------------------------------------------------------------
  // Common case: stub ONE query
  // ---------------------------------------------------------------------------------------------
  @IsTest
  static void it_links_child_log_to_parent_log_when_parent_already_exists() {
    Id parentLogId = LoggerMockDataCreator.createId(Schema.Log__c.SObjectType);
    Log__c mockParentLog = new Log__c(Id = parentLogId, TransactionId__c = 'PARENT-TX');
    Log__c childLog = new Log__c(ParentLogTransactionId__c = 'PARENT-TX', TransactionId__c = 'CHILD-TX');

    LoggerQuery.mockResult('LogHandler.parentLookup', new List<Log__c>{ mockParentLog });

    new LogHandlerSlice(new List<Log__c>{ childLog }, new Map<Id, String>()).run();

    System.Assert.areEqual(parentLogId, childLog.ParentLog__c);
    System.Assert.areEqual(1, LoggerQuery.callCountForTag('LogHandler.parentLookup'));
  }

  // ---------------------------------------------------------------------------------------------
  // Complex case: stub THREE queries across THREE SObjectTypes
  // ---------------------------------------------------------------------------------------------
  @IsTest
  static void it_sets_owner_id_to_queue_id_when_owner_name_matches_queue_developer_name() {
    Id childLogId = LoggerMockDataCreator.createId(Schema.Log__c.SObjectType);
    Id queueId = LoggerMockDataCreator.createId(Schema.Group.SObjectType);
    Log__c childLog = new Log__c(Id = childLogId, ParentLogTransactionId__c = 'PARENT-TX', TransactionId__c = 'CHILD-TX');
    Log__c mockParentLog = new Log__c(Id = LoggerMockDataCreator.createId(Schema.Log__c.SObjectType), TransactionId__c = 'PARENT-TX');
    Schema.Group mockQueue = new Schema.Group(Id = queueId, DeveloperName = 'Some_Queue', Type = 'Queue');

    LoggerQuery.mockResult('LogHandler.parentLookup', new List<Log__c>{ mockParentLog });
    LoggerQuery.mockResult('LogHandler.queueLookup', new List<Schema.Group>{ mockQueue });
    LoggerQuery.mockResult('LogHandler.userLookup', new List<Schema.User>());

    new LogHandlerSlice(new List<Log__c>{ childLog }, new Map<Id, String>{ childLogId => 'Some_Queue' }).run();

    System.Assert.areEqual(queueId, childLog.OwnerId);
  }

  // ---------------------------------------------------------------------------------------------
  // Demonstrates the call-count assertion: tags make it trivial to prove a code path was (or
  // wasn't) hit, without inspecting the SOQL string or wrapping the executor.
  // ---------------------------------------------------------------------------------------------
  @IsTest
  static void it_skips_parent_log_lookup_when_no_child_log_has_a_parent_transaction_id() {
    Log__c childLog = new Log__c(TransactionId__c = 'CHILD-TX');

    new LogHandlerSlice(new List<Log__c>{ childLog }, new Map<Id, String>()).run();

    System.Assert.areEqual(0, LoggerQuery.callCountForTag('LogHandler.parentLookup'));
    System.Assert.isNull(childLog.ParentLog__c);
  }
}
