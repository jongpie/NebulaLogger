//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LogBatchPurger_Tests {
  private static final Integer NUMBER_OF_LOG_ENTRIES_TO_CREATE = 3;

  private static Boolean ranPluginStart = false;
  private static Boolean ranPluginExecute = false;
  private static Boolean ranPluginFinish = false;
  private static LoggerPlugin__mdt pluginConfiguration;
  private static LoggerBatchableContext batchInput;
  private static List<SObject> pluginRecords;

  static {
    // Don't use the org's actual custom metadata records when running tests
    LoggerConfigurationSelector.useMocks();
  }

  @TestSetup
  static void setupData() {
    LoggerSObjectHandler.shouldExecute(false);
    LoggerSettings__c settings = Logger.getUserSettings();
    settings.IsEnabled__c = false;
    settings.LoggingLevel__c = System.LoggingLevel.FINEST.name();
    insert settings;

    Date scheduledDeletionDate = System.today().addDays(-7);
    Log__c log = new Log__c(LogRetentionDate__c = scheduledDeletionDate);
    LoggerMockDataCreator.createDataBuilder(log).populateRequiredFields();
    insert log;

    List<LogEntry__c> logEntries = new List<LogEntry__c>();
    for (Integer i = 0; i < NUMBER_OF_LOG_ENTRIES_TO_CREATE; i++) {
      LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.INFO.name());
      LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields();
      logEntries.add(logEntry);
    }
    insert logEntries;

    LoggerTag__c tag = (LoggerTag__c) LoggerMockDataCreator.createDataBuilder(Schema.LoggerTag__c.SObjectType).populateRequiredFields().getRecord();
    insert tag;

    List<LogEntryTag__c> logEntryTags = new List<LogEntryTag__c>();
    for (LogEntry__c logEntry : logEntries) {
      LogEntryTag__c logEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
      LoggerMockDataCreator.createDataBuilder(logEntryTag).populateRequiredFields();
      logEntryTags.add(logEntryTag);
    }
    insert logEntryTags;
  }

  @IsTest
  static void it_returns_configured_logger_parameter_value_for_the_default_batch_size() {
    Integer mockValue = 1234;
    LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(
      DeveloperName = 'LogBatchPurgerDefaultBatchSize',
      Value__c = System.JSON.serialize(mockValue)
    );
    LoggerParameter.setMock(mockParameter);

    Integer returnedValue = LogBatchPurger.getDefaultBatchSize();

    System.Assert.areEqual(mockValue, returnedValue);
  }

  @IsTest
  static void it_should_throw_an_exception_when_data_cannot_be_purged() {
    LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'EnableLoggerSystemMessages', Value__c = 'true'));
    LogBatchPurger batchJobInstance = new LogBatchPurger();
    batchJobInstance.currentSObjectType = Schema.Log__c.SObjectType;
    List<Log__c> nullLogsList = null;
    Database.BatchableContext mockBatchableContext = new LoggerMockDataCreator.MockBatchableContext();
    System.Exception thrownNullPointerException;

    try {
      batchJobInstance.execute(mockBatchableContext, nullLogsList);
    } catch (NullPointerException ex) {
      thrownNullPointerException = ex;
    }

    System.Assert.isNotNull(thrownNullPointerException);
  }

  @IsTest
  static void it_should_default_batch_size_for_chained_job_batch_size() {
    LogBatchPurger batchJobInstance = new LogBatchPurger();

    System.Assert.areEqual(LogBatchPurger.getDefaultBatchSize(), batchJobInstance.chainedBatchSize);
  }

  @IsTest
  static void it_should_set_chained_job_batch_size() {
    LogBatchPurger batchJobInstance = new LogBatchPurger();
    Integer specifiedBatchSize = 123;

    batchJobInstance.setChainedBatchSize(specifiedBatchSize);

    System.Assert.areEqual(specifiedBatchSize, batchJobInstance.chainedBatchSize);
  }

  @IsTest
  static void it_should_delete_a_log_after_scheduled_deletion_date_when_system_messages_enabled() {
    LoggerSettings__c settings = Logger.getUserSettings();
    settings.IsEnabled__c = true;
    settings.LoggingLevel__c = System.LoggingLevel.FINEST.name();
    upsert settings;
    LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'EnableLoggerSystemMessages', Value__c = 'true'));
    System.Assert.isTrue(Logger.getUserSettings().IsEnabled__c);
    System.Assert.isTrue(LoggerParameter.getBoolean('EnableLoggerSystemMessages', null));
    System.Assert.areEqual(System.LoggingLevel.FINEST.name(), Logger.getUserSettings().LoggingLevel__c);
    List<Log__c> logs = [SELECT Id, LogRetentionDate__c FROM Log__c];
    List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c];
    System.Assert.areEqual(1, logs.size());
    System.Assert.areEqual(NUMBER_OF_LOG_ENTRIES_TO_CREATE, logEntries.size());
    // Verify assumption that the log in the database has a deletion date in the past
    Log__c log = logs.get(0);
    System.Assert.isNotNull(log.LogRetentionDate__c);
    System.Assert.isTrue(log.LogRetentionDate__c < System.today());
    System.Test.startTest();
    LoggerSObjectHandler.shouldExecute(true);
    LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();

    System.Database.executeBatch(new LogBatchPurger());

    System.Test.stopTest();
    logs = [SELECT Id FROM Log__c WHERE Id IN :logs];
    logEntries = [SELECT Id FROM LogEntry__c WHERE Id IN :logEntries];
    System.Assert.areEqual(0, logs.size(), System.JSON.serializePretty(logs));
    System.Assert.areEqual(0, logEntries.size(), System.JSON.serializePretty(logEntries));
  }

  @IsTest
  static void it_should_delete_a_log_after_scheduled_deletion_date_when_system_messages_disabled() {
    LoggerSettings__c settings = Logger.getUserSettings();
    settings.IsEnabled__c = true;
    upsert settings;
    LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'EnableLoggerSystemMessages', Value__c = String.valueOf(false)));
    System.Assert.isTrue(Logger.getUserSettings().IsEnabled__c);
    System.Assert.isFalse(LoggerParameter.getBoolean('EnableLoggerSystemMessages', null));
    System.Assert.areEqual(System.LoggingLevel.FINEST.name(), Logger.getUserSettings().LoggingLevel__c);
    List<Log__c> logs = [SELECT Id, LogRetentionDate__c FROM Log__c];
    List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c];
    System.Assert.areEqual(1, logs.size());
    System.Assert.areEqual(NUMBER_OF_LOG_ENTRIES_TO_CREATE, logEntries.size());
    // Verify assumption that the log in the database has a deletion date in the past
    Log__c log = logs.get(0);
    System.Assert.isNotNull(log.LogRetentionDate__c);
    System.Assert.isTrue(log.LogRetentionDate__c < System.today());
    System.Test.startTest();
    LoggerSObjectHandler.shouldExecute(false);
    LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();

    System.Database.executeBatch(new LogBatchPurger());

    System.Test.stopTest();
    logs = [SELECT Id FROM Log__c WHERE Id IN :logs];
    logEntries = [SELECT Id FROM LogEntry__c WHERE Id IN :logEntries];
    System.Assert.areEqual(0, logs.size(), System.JSON.serializePretty(logs));
    System.Assert.areEqual(0, logEntries.size(), System.JSON.serializePretty(logEntries));
  }

  @IsTest
  static void it_should_not_delete_a_log_before_scheduled_deletion_date() {
    LoggerSObjectHandler.shouldExecute(false);
    List<Log__c> logs = [SELECT Id, LogRetentionDate__c FROM Log__c];
    List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c];
    System.Assert.areEqual(1, logs.size());
    System.Assert.areEqual(NUMBER_OF_LOG_ENTRIES_TO_CREATE, logEntries.size());
    // Set the log's deletion date to be in the future
    Log__c log = logs.get(0);
    log.LogRetentionDate__c = System.today().addDays(7);
    update log;
    log = [SELECT Id, LogRetentionDate__c FROM Log__c];
    System.Assert.isTrue(log.LogRetentionDate__c > System.today());
    System.Test.startTest();
    LoggerSObjectHandler.shouldExecute(false);
    LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();

    System.Database.executeBatch(new LogBatchPurger());

    System.Test.stopTest();
    logs = [SELECT Id FROM Log__c WHERE Id IN :logs];
    logEntries = [SELECT Id FROM LogEntry__c WHERE Id IN :logEntries];
    System.Assert.areEqual(1, logs.size());
    System.Assert.areEqual(NUMBER_OF_LOG_ENTRIES_TO_CREATE, logEntries.size());
  }

  @IsTest
  static void it_should_not_delete_a_log_without_a_scheduled_deletion_date_and_with_log_entries() {
    LoggerSObjectHandler.shouldExecute(false);
    List<Log__c> logs = [SELECT Id, TotalLogEntries__c, LogRetentionDate__c FROM Log__c];
    List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c];
    System.Assert.areEqual(1, logs.size());
    System.Assert.areEqual(NUMBER_OF_LOG_ENTRIES_TO_CREATE, logs.get(0).TotalLogEntries__c);
    System.Assert.areEqual(NUMBER_OF_LOG_ENTRIES_TO_CREATE, logEntries.size());
    // Set the log's deletion date to be null
    Log__c log = logs.get(0);
    log.LogRetentionDate__c = null;
    update log;
    log = [SELECT Id, LogRetentionDate__c FROM Log__c];
    System.Assert.isNull(log.LogRetentionDate__c);
    System.Test.startTest();
    LoggerSObjectHandler.shouldExecute(false);
    LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();

    System.Database.executeBatch(new LogBatchPurger());

    System.Test.stopTest();
    logs = [SELECT Id FROM Log__c WHERE Id IN :logs];
    logEntries = [SELECT Id FROM LogEntry__c WHERE Id IN :logEntries];
    System.Assert.areEqual(1, logs.size(), System.JSON.serializePretty(logs));
    System.Assert.areEqual(NUMBER_OF_LOG_ENTRIES_TO_CREATE, logEntries.size(), System.JSON.serializePretty(logEntries));
  }

  @IsTest
  static void it_should_delete_a_log_with_a_scheduled_deletion_date_and_without_log_entries() {
    LoggerSObjectHandler.shouldExecute(false);
    Date retentionDate = System.today().addDays(-1);
    Log__c log = new Log__c(TransactionId__c = '5678');
    insert log;
    log.LogRetentionDate__c = retentionDate;
    update log;
    log = [SELECT Id, LogRetentionDate__c, TotalLogEntries__c FROM Log__c WHERE Id = :log.Id];
    System.Assert.areEqual(retentionDate, log.LogRetentionDate__c, 'Log should not have a retention date');
    System.Assert.areEqual(0, log.TotalLogEntries__c, 'Log should not have any related log entries');
    System.Test.startTest();
    LoggerSObjectHandler.shouldExecute(false);
    LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();

    System.Database.executeBatch(new LogBatchPurger());

    System.Test.stopTest();
    List<Log__c> matchingLogs = [SELECT Id FROM Log__c WHERE Id = :log.Id];
    System.Assert.areEqual(0, matchingLogs.size(), 'Test log should have been deleted');
  }

  @IsTest
  static void it_should_delete_a_log_without_a_scheduled_deletion_date_and_without_log_entries() {
    LoggerSObjectHandler.shouldExecute(false);
    Log__c log = new Log__c(TransactionId__c = '5678');
    insert log;
    log.LogRetentionDate__c = null;
    update log;
    log = [SELECT Id, LogRetentionDate__c, TotalLogEntries__c FROM Log__c WHERE Id = :log.Id];
    System.Assert.isNull(log.LogRetentionDate__c, 'Log should not have a retention date');
    System.Assert.areEqual(0, log.TotalLogEntries__c, 'Log should not have any related log entries');
    System.Test.startTest();
    LoggerSObjectHandler.shouldExecute(false);
    LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();

    System.Database.executeBatch(new LogBatchPurger());

    System.Test.stopTest();
    List<Log__c> matchingLogs = [SELECT Id FROM Log__c WHERE Id = :log.Id];
    System.Assert.areEqual(0, matchingLogs.size(), 'Test log should have been deleted');
  }

  @IsTest
  static void it_should_run_apex_plugin_in_start_method() {
    LoggerSObjectHandler.shouldExecute(false);
    LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
    LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
      DeveloperName = 'Mock_Plugin',
      IsEnabled__c = true,
      BatchPurgerApexClass__c = MockBatchPurgerPlugin.class.getName()
    );
    LoggerTestConfigurator.setMock(mockPluginConfiguration);
    LogBatchPurger batchJobInstance = new LogBatchPurger();
    batchJobInstance.currentSObjectType = Schema.LogEntry__c.SObjectType;
    System.Assert.isFalse(ranPluginStart);
    System.Assert.isFalse(ranPluginExecute);
    System.Assert.isFalse(ranPluginFinish);
    System.Assert.isNull(pluginConfiguration);
    System.Assert.isNull(batchInput);
    Database.BatchableContext mockBatchableContext = new LoggerMockDataCreator.MockBatchableContext();

    batchJobInstance.start(mockBatchableContext);

    LoggerBatchableContext expectedInput = new LoggerBatchableContext(mockBatchableContext, batchJobInstance.currentSObjectType);
    System.Assert.isTrue(ranPluginStart, 'The plugin should have been dispatched to via its start() method');
    System.Assert.isFalse(ranPluginExecute, 'The plugin should not have been dispatched to via its execute() method');
    System.Assert.isFalse(ranPluginFinish, 'The plugin should not have been dispatched to via its finish() method');
    System.Assert.areEqual(mockPluginConfiguration, pluginConfiguration);
    System.Assert.areEqual(expectedInput.batchableContext, batchInput.batchableContext);
    System.Assert.areEqual(expectedInput.sobjectType, batchInput.sobjectType);
  }

  @IsTest
  static void it_should_run_apex_plugin_in_execute_method() {
    LoggerSObjectHandler.shouldExecute(false);
    LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
      DeveloperName = 'Mock_Plugin',
      IsEnabled__c = true,
      BatchPurgerApexClass__c = MockBatchPurgerPlugin.class.getName()
    );
    LoggerTestConfigurator.setMock(mockPluginConfiguration);
    LogBatchPurger batchJobInstance = new LogBatchPurger();
    batchJobInstance.currentSObjectType = Schema.LogEntry__c.SObjectType;
    System.Assert.isFalse(ranPluginStart);
    System.Assert.isFalse(ranPluginExecute);
    System.Assert.isFalse(ranPluginFinish);
    System.Assert.isNull(pluginConfiguration);
    System.Assert.isNull(batchInput);
    List<Log__c> logsToDelete = [SELECT Id FROM Log__c];
    System.Assert.areNotEqual(0, logsToDelete.size());
    Database.BatchableContext mockBatchableContext = new LoggerMockDataCreator.MockBatchableContext();

    batchJobInstance.execute(mockBatchableContext, logsToDelete);

    LoggerBatchableContext expectedInput = new LoggerBatchableContext(mockBatchableContext, batchJobInstance.currentSObjectType);
    System.Assert.isFalse(ranPluginStart, 'The plugin should not have been dispatched to via its start() method');
    System.Assert.isTrue(ranPluginExecute, 'The plugin should have been dispatched to via its execute() method');
    System.Assert.isFalse(ranPluginFinish, 'The plugin should not have been dispatched to via its finish() method');
    System.Assert.areEqual(mockPluginConfiguration, pluginConfiguration);
    System.Assert.areEqual(expectedInput.batchableContext, batchInput.batchableContext);
    logsToDelete = [SELECT Id FROM Log__c WHERE Id IN :logsToDelete];
    System.Assert.areEqual(0, logsToDelete.size(), 'All logs should have still been deleted by LogBatchPurger after running plugins: ' + logsToDelete);
  }

  @IsTest
  static void it_should_run_apex_plugin_in_finish_method() {
    LoggerSObjectHandler.shouldExecute(false);
    LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
      DeveloperName = 'Mock_Plugin',
      IsEnabled__c = true,
      BatchPurgerApexClass__c = MockBatchPurgerPlugin.class.getName()
    );
    LoggerTestConfigurator.setMock(mockPluginConfiguration);
    LogBatchPurger batchJobInstance = new LogBatchPurger();
    batchJobInstance.currentSObjectType = Schema.LogEntry__c.SObjectType;
    System.Assert.isFalse(ranPluginStart);
    System.Assert.isFalse(ranPluginExecute);
    System.Assert.isFalse(ranPluginFinish);
    System.Assert.isNull(pluginConfiguration);
    System.Assert.isNull(batchInput);
    Database.BatchableContext mockBatchableContext = new LoggerMockDataCreator.MockBatchableContext();

    batchJobInstance.finish(mockBatchableContext);

    LoggerBatchableContext expectedInput = new LoggerBatchableContext(mockBatchableContext, batchJobInstance.currentSObjectType);
    System.Assert.isFalse(ranPluginStart, 'The plugin should not have been dispatched to via its start() method');
    System.Assert.isFalse(ranPluginExecute, 'The plugin should not have been dispatched to via its execute() method');
    System.Assert.isTrue(ranPluginFinish, 'The plugin should have been dispatched to via its finish() method');
    System.Assert.areEqual(mockPluginConfiguration, pluginConfiguration);
    System.Assert.areEqual(expectedInput.sobjectType, batchInput.sobjectType);
  }

  // Registrar-driven registration flow (happy path, guardrails, ordering) is covered in
  // LogBatchPurger_Tests_Registrar under nebula-logger/extra-tests, where a test-only custom
  // SObject (LoggerTestPurgeable__c) is available for use as a non-core registration target -
  // every custom SObject in the core package is on the purger's blocklist and cannot be used
  // in a happy-path registration test from here.

  @IsTest
  static void it_should_skip_an_unknown_purgeable_registrar_apex_class_without_throwing() {
    LoggerTestConfigurator.setMock(
      new LoggerPlugin__mdt(BatchPurgeRegistrarApexClass__c = 'ThisApexClassDoesNotExist', DeveloperName = 'Bogus_Registrar_Plugin', IsEnabled__c = true)
    );

    System.Exception thrown;
    try {
      new LogBatchPurger();
    } catch (System.Exception ex) {
      thrown = ex;
    }

    System.Assert.isNull(thrown, 'An unknown registrar class should be skipped, not blow up the batch job');
  }

  public class MockBatchPurgerPlugin implements LoggerPlugin.Batchable {
    public void start(LoggerPlugin__mdt configuration, LoggerBatchableContext input) {
      ranPluginStart = true;
      pluginConfiguration = configuration;
      batchInput = input;
    }

    public void execute(LoggerPlugin__mdt configuration, LoggerBatchableContext input, List<SObject> scope) {
      ranPluginExecute = true;
      pluginConfiguration = configuration;
      batchInput = input;
      pluginRecords = scope;
    }

    public void finish(LoggerPlugin__mdt configuration, LoggerBatchableContext input) {
      ranPluginFinish = true;
      pluginConfiguration = configuration;
      batchInput = input;
    }
  }
}
