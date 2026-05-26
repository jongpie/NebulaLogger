//------------------------------------------------------------------------------------------------//
// Prototype 2 — Tests provide their own Executor, which receives each LoggerQuery and decides
// what to return. The test executor in this file uses a small "match by SObjectType + filter
// fields" rule set, but the test author is free to match on whatever they want — filter values,
// limit, exact SOQL string, or even "always return X for the Nth call".
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

    StubExecutor stub = new StubExecutor()
      .when(Schema.Log__c.SObjectType, Schema.Log__c.TransactionId__c, new List<Log__c>{ mockParentLog });
    LoggerQuery.setExecutor(stub);

    new LogHandlerSlice(new List<Log__c>{ childLog }, new Map<Id, String>()).run();

    System.Assert.areEqual(parentLogId, childLog.ParentLog__c);
    System.Assert.areEqual(1, stub.executedQueries.size());
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

    StubExecutor stub = new StubExecutor()
      .when(Schema.Log__c.SObjectType, Schema.Log__c.TransactionId__c, new List<Log__c>{ mockParentLog })
      .when(Schema.Group.SObjectType, Schema.Group.DeveloperName, new List<Schema.Group>{ mockQueue })
      .when(Schema.User.SObjectType, Schema.User.Username, new List<Schema.User>());
    LoggerQuery.setExecutor(stub);

    new LogHandlerSlice(new List<Log__c>{ childLog }, new Map<Id, String>{ childLogId => 'Some_Queue' }).run();

    System.Assert.areEqual(queueId, childLog.OwnerId);
    System.Assert.areEqual(3, stub.executedQueries.size());
  }

  // ---------------------------------------------------------------------------------------------
  // Demonstrates the executor's flexibility: the test can match on ANYTHING about the query.
  // Here, we match on the actual filter VALUES (not just fields) to return different results
  // for two queries that share the same SObjectType and filter field.
  // ---------------------------------------------------------------------------------------------
  @IsTest
  static void it_routes_queries_to_different_results_based_on_filter_values() {
    Log__c logForTxA = new Log__c(Id = LoggerMockDataCreator.createId(Schema.Log__c.SObjectType), TransactionId__c = 'TX-A');
    Log__c logForTxB = new Log__c(Id = LoggerMockDataCreator.createId(Schema.Log__c.SObjectType), TransactionId__c = 'TX-B');

    LoggerQuery.setExecutor(new ValueAwareStubExecutor(logForTxA, logForTxB));

    List<Log__c> resultsA = (List<Log__c>) LoggerQuery.of(Schema.Log__c.SObjectType)
      .selectField(Schema.Log__c.Id)
      .whereField(Schema.Log__c.TransactionId__c)
      .inCollection(new List<String>{ 'TX-A' })
      .toList();
    List<Log__c> resultsB = (List<Log__c>) LoggerQuery.of(Schema.Log__c.SObjectType)
      .selectField(Schema.Log__c.Id)
      .whereField(Schema.Log__c.TransactionId__c)
      .inCollection(new List<String>{ 'TX-B' })
      .toList();

    System.Assert.areEqual(logForTxA.Id, resultsA.get(0).Id);
    System.Assert.areEqual(logForTxB.Id, resultsB.get(0).Id);
  }

  // ---------------------------------------------------------------------------------------------
  // Reusable stub executor — most tests would extract this into a shared test utility class.
  // ---------------------------------------------------------------------------------------------
  private class StubExecutor implements LoggerQuery.Executor {
    private final List<Registration> registrations = new List<Registration>();
    public final List<LoggerQuery> executedQueries = new List<LoggerQuery>();

    public StubExecutor when(Schema.SObjectType sobjectType, Schema.SObjectField filterField, Object result) {
      this.registrations.add(new Registration(sobjectType, filterField, result));
      return this;
    }

    public Object execute(LoggerQuery query) {
      this.executedQueries.add(query);
      for (Registration registration : this.registrations) {
        if (registration.matches(query)) {
          return registration.result;
        }
      }
      throw new System.IllegalArgumentException('No stub registered for query: ' + query.toSoql());
    }

    private class Registration {
      private final Schema.SObjectType sobjectType;
      private final Schema.SObjectField filterField;
      private final Object result;

      private Registration(Schema.SObjectType sobjectType, Schema.SObjectField filterField, Object result) {
        this.sobjectType = sobjectType;
        this.filterField = filterField;
        this.result = result;
      }

      public Boolean matches(LoggerQuery query) {
        return query.sobjectType == this.sobjectType && query.filterFields.contains(this.filterField);
      }
    }
  }

  // Demonstrates that the executor can match on whatever the test cares about — here, the actual
  // filter values, which the registration-based prototypes can't easily express.
  private class ValueAwareStubExecutor implements LoggerQuery.Executor {
    private final Log__c logForTxA;
    private final Log__c logForTxB;

    public ValueAwareStubExecutor(Log__c logForTxA, Log__c logForTxB) {
      this.logForTxA = logForTxA;
      this.logForTxB = logForTxB;
    }

    public Object execute(LoggerQuery query) {
      List<Object> firstFilterValue = (List<Object>) query.filterValues.get(0);
      String txId = String.valueOf(firstFilterValue.get(0));
      if (txId == 'TX-A') {
        return new List<Log__c>{ this.logForTxA };
      }
      if (txId == 'TX-B') {
        return new List<Log__c>{ this.logForTxB };
      }
      return new List<Log__c>();
    }
  }
}
