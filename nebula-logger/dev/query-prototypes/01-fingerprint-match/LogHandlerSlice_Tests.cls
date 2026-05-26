//------------------------------------------------------------------------------------------------//
// Prototype 1 — Tests register mock results by SObjectType + filter-field fingerprint. Each
// LoggerQuery in production checks the registry before executing SOQL; if the query's
// SObjectType matches AND the registered filter fields are a subset of the query's filter
// fields, the registered result is returned instead of running the query.
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

    LoggerQuery.mockResult()
      .forSObjectType(Schema.Log__c.SObjectType)
      .withFilterOn(Schema.Log__c.TransactionId__c)
      .thenReturn(new List<Log__c>{ mockParentLog });

    new LogHandlerSlice(new List<Log__c>{ childLog }, new Map<Id, String>()).run();

    System.Assert.areEqual(parentLogId, childLog.ParentLog__c);
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

    LoggerQuery.mockResult()
      .forSObjectType(Schema.Log__c.SObjectType)
      .withFilterOn(Schema.Log__c.TransactionId__c)
      .thenReturn(new List<Log__c>{ mockParentLog });
    LoggerQuery.mockResult()
      .forSObjectType(Schema.Group.SObjectType)
      .withFilterOn(Schema.Group.DeveloperName)
      .thenReturn(new List<Schema.Group>{ mockQueue });
    LoggerQuery.mockResult()
      .forSObjectType(Schema.User.SObjectType)
      .withFilterOn(Schema.User.Username)
      .thenReturn(new List<Schema.User>());

    new LogHandlerSlice(new List<Log__c>{ childLog }, new Map<Id, String>{ childLogId => 'Some_Queue' }).run();

    System.Assert.areEqual(queueId, childLog.OwnerId);
  }

  // ---------------------------------------------------------------------------------------------
  // Demonstrates the fingerprint-specificity tradeoff: a registration with NO filter fields
  // matches every query for that SObjectType. Useful as a "catch-all" but easy to misuse.
  // ---------------------------------------------------------------------------------------------
  @IsTest
  static void it_returns_empty_for_any_user_query_when_catch_all_is_registered() {
    LoggerQuery.mockResult().forSObjectType(Schema.User.SObjectType).thenReturn(new List<Schema.User>());

    List<Schema.User> result = (List<Schema.User>) LoggerQuery.of(Schema.User.SObjectType)
      .selectField(Schema.User.Id)
      .whereField(Schema.User.Username)
      .inCollection(new List<String>{ 'whatever@example.com' })
      .toList();

    System.Assert.areEqual(0, result.size());
  }
}
