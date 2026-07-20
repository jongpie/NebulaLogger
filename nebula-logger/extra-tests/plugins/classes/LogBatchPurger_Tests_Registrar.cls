//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LogBatchPurger_Tests_Registrar {
  private static Integer mockTestPurgeableRegistrarInvocationCount = 0;

  static {
    LoggerConfigurationSelector.useMocks();
  }

  @IsTest
  static void it_should_invoke_purgeable_registrars_configured_via_logger_plugin_mdt() {
    LoggerTestConfigurator.setMock(
      new LoggerPlugin__mdt(
        BatchPurgeRegistrarApexClass__c = MockTestPurgeableRegistrar.class.getName(),
        DeveloperName = 'Mock_Purgeable_Plugin',
        IsEnabled__c = true
      )
    );
    mockTestPurgeableRegistrarInvocationCount = 0;

    LogBatchPurger purger = new LogBatchPurger();

    System.Assert.areEqual(
      1,
      mockTestPurgeableRegistrarInvocationCount,
      'Purgeable registrar should have been invoked exactly once from the purger constructor'
    );
    System.Assert.isTrue(
      purger.getRegisteredSObjectTypes().contains(Schema.LoggerTestPurgeable__c.SObjectType),
      'The registrar should have added its declared SObject type to the purger instance registry'
    );
  }

  @IsTest
  static void it_should_build_registered_query_from_the_declared_retention_date_field() {
    // The purger owns query construction so retention semantics (WHERE <= today AND != NULL,
    // ORDER BY retention date) stay consistent across every purgeable SObject. This is the
    // integration point that catches a regression where a plugin's declaration would silently be
    // dropped or where the purger built a broken query around the wrong field.
    LoggerTestConfigurator.setMock(
      new LoggerPlugin__mdt(
        BatchPurgeRegistrarApexClass__c = MockTestPurgeableRegistrar.class.getName(),
        DeveloperName = 'Mock_Purgeable_Plugin_Query_Build',
        IsEnabled__c = true
      )
    );

    LogBatchPurger purger = new LogBatchPurger();

    String actualQuery = purger.getRegisteredQuery(Schema.LoggerTestPurgeable__c.SObjectType);
    System.Assert.isNotNull(actualQuery, 'The purger should have built + stored a query for the declared SObject type');
    System.Assert.isTrue(actualQuery.contains('FROM LoggerTestPurgeable__c'), 'Query should target the declared SObject type: ' + actualQuery);
    System.Assert.isTrue(
      actualQuery.contains('RetentionDate__c <= :RETENTION_END_DATE'),
      'Query should compare the declared retention date field: ' + actualQuery
    );
    System.Assert.isTrue(
      actualQuery.contains('RetentionDate__c != NULL'),
      'Query should skip records opted out of purging via a null retention date: ' + actualQuery
    );
    System.Assert.isTrue(
      actualQuery.contains('ORDER BY RetentionDate__c'),
      'Query should sort by the retention date so oldest records delete first: ' + actualQuery
    );
  }

  @IsTest
  static void it_should_fall_back_from_registered_types_with_no_records_to_the_log_entry_tag_chain() {
    // A LoggerTestPurgeable__c record has to exist for the registered type to have records to purge; with
    // no records in the table, start() should skip the registered type and fall back to the core
    // LogEntryTag__c chain. Setup inserts no LoggerTestPurgeable__c records, so the registered queue
    // is empty at start().
    LoggerTestConfigurator.setMock(
      new LoggerPlugin__mdt(
        BatchPurgeRegistrarApexClass__c = MockTestPurgeableRegistrar.class.getName(),
        DeveloperName = 'Mock_Purgeable_Plugin_Fallback',
        IsEnabled__c = true
      )
    );
    Date scheduledDeletionDate = System.today().addDays(-7);
    Log__c log = new Log__c(LogRetentionDate__c = scheduledDeletionDate);
    LoggerMockDataCreator.createDataBuilder(log).populateRequiredFields();
    insert log;
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.INFO.name());
    LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields();
    insert logEntry;
    LoggerTag__c tag = (LoggerTag__c) LoggerMockDataCreator.createDataBuilder(Schema.LoggerTag__c.SObjectType).populateRequiredFields().getRecord();
    insert tag;
    LogEntryTag__c logEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
    LoggerMockDataCreator.createDataBuilder(logEntryTag).populateRequiredFields();
    insert logEntryTag;
    LogBatchPurger purger = new LogBatchPurger();
    Database.BatchableContext mockContext = new LoggerMockDataCreator.MockBatchableContext();

    purger.start(mockContext);

    System.Assert.areEqual(Schema.LogEntryTag__c.SObjectType, purger.currentSObjectType, 'Empty registered queue should fall back to LogEntryTag__c');
  }

  @IsTest
  static void it_should_route_a_registered_sobject_type_through_the_registered_query() {
    LoggerTestConfigurator.setMock(
      new LoggerPlugin__mdt(
        BatchPurgeRegistrarApexClass__c = MockTestPurgeableRegistrar.class.getName(),
        DeveloperName = 'Mock_Purgeable_Plugin_Routing',
        IsEnabled__c = true
      )
    );
    // Insert a purgeable record so the registered query returns a record - otherwise start() detects the
    // registered queue is empty and falls back to LogEntryTag__c.
    LoggerTestPurgeable__c purgeable = new LoggerTestPurgeable__c(Name = 'Routing test', RetentionDate__c = System.today().addDays(-1));
    insert purgeable;
    LogBatchPurger purger = new LogBatchPurger();
    Database.BatchableContext mockContext = new LoggerMockDataCreator.MockBatchableContext();

    Database.QueryLocator locator = purger.start(mockContext);

    System.Assert.isNotNull(locator, 'Registered SObject type should have produced a QueryLocator via the registered SOQL string');
    System.Assert.areEqual(
      Schema.LoggerTestPurgeable__c.SObjectType,
      purger.currentSObjectType,
      'start() should have picked the registered type since it has records to purge'
    );
  }

  @IsTest
  static void it_should_reject_a_registrar_that_declares_a_core_log_sobject_type() {
    LoggerTestConfigurator.setMock(
      new LoggerPlugin__mdt(
        BatchPurgeRegistrarApexClass__c = MockCoreLogSObjectRegistrar.class.getName(),
        DeveloperName = 'Mock_Core_Log_Registrar',
        IsEnabled__c = true
      )
    );

    LogBatchPurger purger = new LogBatchPurger();

    System.Assert.isFalse(
      purger.getRegisteredSObjectTypes().contains(Schema.Log__c.SObjectType),
      'Registrars must not be able to schedule the core Log__c SObject for purging - the built-in cascade owns it'
    );
    System.Assert.areEqual(0, purger.getRegisteredSObjectTypes().size(), 'A rejected registration should not appear in the registry');
  }

  @IsTest
  static void it_should_reject_a_registrar_that_declares_the_logger_scenario_sobject() {
    LoggerTestConfigurator.setMock(
      new LoggerPlugin__mdt(
        BatchPurgeRegistrarApexClass__c = MockLoggerScenarioRegistrar.class.getName(),
        DeveloperName = 'Mock_LoggerScenario_Registrar',
        IsEnabled__c = true
      )
    );

    LogBatchPurger purger = new LogBatchPurger();

    System.Assert.isFalse(
      purger.getRegisteredSObjectTypes().contains(Schema.LoggerScenario__c.SObjectType),
      'Registrars must not be able to sneak LoggerScenario__c into the purge chain - it holds long-lived reference data and is intentionally never purged'
    );
    System.Assert.areEqual(0, purger.getRegisteredSObjectTypes().size(), 'A rejected registration should not appear in the registry');
  }

  @IsTest
  static void it_should_reject_a_registrar_that_declares_the_logger_tag_sobject() {
    LoggerTestConfigurator.setMock(
      new LoggerPlugin__mdt(
        BatchPurgeRegistrarApexClass__c = MockLoggerTagRegistrar.class.getName(),
        DeveloperName = 'Mock_LoggerTag_Registrar',
        IsEnabled__c = true
      )
    );

    LogBatchPurger purger = new LogBatchPurger();

    System.Assert.isFalse(
      purger.getRegisteredSObjectTypes().contains(Schema.LoggerTag__c.SObjectType),
      'Registrars must not be able to sneak LoggerTag__c into the purge chain - it holds long-lived reference data and is intentionally never purged'
    );
    System.Assert.areEqual(0, purger.getRegisteredSObjectTypes().size(), 'A rejected registration should not appear in the registry');
  }

  @IsTest
  static void it_should_reject_a_registrar_that_declares_a_standard_sobject() {
    LoggerTestConfigurator.setMock(
      new LoggerPlugin__mdt(
        BatchPurgeRegistrarApexClass__c = MockStandardSObjectRegistrar.class.getName(),
        DeveloperName = 'Mock_Standard_Registrar',
        IsEnabled__c = true
      )
    );

    LogBatchPurger purger = new LogBatchPurger();

    System.Assert.isFalse(purger.getRegisteredSObjectTypes().contains(Schema.Account.SObjectType), 'Standard SObjects must not be registrable for purging');
    System.Assert.areEqual(0, purger.getRegisteredSObjectTypes().size(), 'A rejected registration should not appear in the registry');
  }

  @IsTest
  static void it_should_reject_a_duplicate_registration_for_the_same_sobject_type() {
    // A registrar that returns two registrations for the same SObject type - the first should
    // succeed, the second should be rejected as a duplicate. The purger surfaces the rejection
    // via Logger.warn but does not crash the constructor, so we observe the outcome via the
    // registry: exactly one entry for the type.
    LoggerTestConfigurator.setMock(
      new LoggerPlugin__mdt(
        BatchPurgeRegistrarApexClass__c = MockDuplicateRegistrar.class.getName(),
        DeveloperName = 'Mock_Duplicate_Registrar',
        IsEnabled__c = true
      )
    );

    LogBatchPurger purger = new LogBatchPurger();

    System.Assert.areEqual(
      1,
      purger.getRegisteredSObjectTypes().size(),
      'Only the first registration for a given SObject type should be accepted; the duplicate is rejected'
    );
    System.Assert.areEqual(
      Schema.LoggerTestPurgeable__c.SObjectType,
      purger.getRegisteredSObjectTypes().get(0),
      'The first registration should be the one preserved in the registry'
    );
  }

  public class MockTestPurgeableRegistrar implements LoggerPlugin.Purgeable {
    public List<LoggerPurgeRegistration> getPurgeRegistrations() {
      mockTestPurgeableRegistrarInvocationCount++;
      return new List<LoggerPurgeRegistration>{
        new LoggerPurgeRegistration(
          Schema.LoggerTestPurgeable__c.SObjectType,
          Schema.LoggerTestPurgeable__c.RetentionDate__c,
          Schema.LoggerTestPurgeable__c.RetentionDate__c
        )
      };
    }
  }

  public class MockCoreLogSObjectRegistrar implements LoggerPlugin.Purgeable {
    public List<LoggerPurgeRegistration> getPurgeRegistrations() {
      return new List<LoggerPurgeRegistration>{
        new LoggerPurgeRegistration(Schema.Log__c.SObjectType, Schema.Log__c.LogRetentionDate__c, Schema.Log__c.LogRetentionDate__c)
      };
    }
  }

  public class MockLoggerScenarioRegistrar implements LoggerPlugin.Purgeable {
    public List<LoggerPurgeRegistration> getPurgeRegistrations() {
      // LoggerScenario__c has no Date field so a plugin author would probably pick SystemModstamp
      // or CreatedDate - both are Date/Datetime fields that describe fine even if the plugin's
      // intent is questionable. The guardrail here is on the SObject type, not the field.
      return new List<LoggerPurgeRegistration>{
        new LoggerPurgeRegistration(Schema.LoggerScenario__c.SObjectType, Schema.LoggerScenario__c.LastModifiedDate, Schema.LoggerScenario__c.LastModifiedDate)
      };
    }
  }

  public class MockLoggerTagRegistrar implements LoggerPlugin.Purgeable {
    public List<LoggerPurgeRegistration> getPurgeRegistrations() {
      return new List<LoggerPurgeRegistration>{
        new LoggerPurgeRegistration(Schema.LoggerTag__c.SObjectType, Schema.LoggerTag__c.LastModifiedDate, Schema.LoggerTag__c.LastModifiedDate)
      };
    }
  }

  public class MockStandardSObjectRegistrar implements LoggerPlugin.Purgeable {
    public List<LoggerPurgeRegistration> getPurgeRegistrations() {
      return new List<LoggerPurgeRegistration>{
        new LoggerPurgeRegistration(Schema.Account.SObjectType, Schema.Account.LastModifiedDate, Schema.Account.LastModifiedDate)
      };
    }
  }

  public class MockDuplicateRegistrar implements LoggerPlugin.Purgeable {
    public List<LoggerPurgeRegistration> getPurgeRegistrations() {
      return new List<LoggerPurgeRegistration>{
        new LoggerPurgeRegistration(
          Schema.LoggerTestPurgeable__c.SObjectType,
          Schema.LoggerTestPurgeable__c.RetentionDate__c,
          Schema.LoggerTestPurgeable__c.RetentionDate__c
        ),
        new LoggerPurgeRegistration(
          Schema.LoggerTestPurgeable__c.SObjectType,
          Schema.LoggerTestPurgeable__c.RetentionDate__c,
          Schema.LoggerTestPurgeable__c.RetentionDate__c
        )
      };
    }
  }
}
