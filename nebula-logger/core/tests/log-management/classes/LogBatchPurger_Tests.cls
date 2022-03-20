//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class LogBatchPurger_Tests {
    private static final Integer NUMBER_OF_LOG_ENTRIES = 10;

    private static Boolean ranPluginStart = false;
    private static Boolean ranPluginExecute = false;
    private static Boolean ranPluginFinish = false;
    private static LoggerPlugin__mdt pluginConfiguration;
    private static LogBatchPurger.BatchPurgerInput pluginInput;
    private static List<SObject> pluginRecords;

    @TestSetup
    static void setupData() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.IsEnabled__c = false;
        settings.LoggingLevel__c = LoggingLevel.FINEST.name();
        insert settings;

        Date scheduledDeletionDate = System.today().addDays(-7);
        Log__c log = new Log__c(LogRetentionDate__c = scheduledDeletionDate, TransactionId__c = '1234');
        insert log;

        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        for (Integer i = 0; i < NUMBER_OF_LOG_ENTRIES; i++) {
            LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = LoggingLevel.INFO.name());

            logEntries.add(logEntry);
        }
        insert logEntries;

        LoggerTag__c tag = new LoggerTag__c(Name = 'My important tag');
        insert tag;

        List<LogEntryTag__c> logEntryTags = new List<LogEntryTag__c>();
        for (LogEntry__c logEntry : logEntries) {
            LogEntryTag__c logEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
            logEntryTags.add(logEntryTag);
        }
        insert logEntryTags;
    }

    @IsTest
    static void it_should_delete_a_log_after_scheduled_deletion_date_when_system_messages_enabled() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.IsEnabled__c = true;
        settings.LoggingLevel__c = LoggingLevel.FINEST.name();
        upsert settings;

        LoggerParameter.setMockParameter(new LoggerParameter__mdt(DeveloperName = 'EnableLoggerSystemMessages', Value__c = 'true'));

        System.assertEquals(true, Logger.getUserSettings().IsEnabled__c);
        System.assertEquals(true, LoggerParameter.getBoolean('EnableLoggerSystemMessages', null));
        System.assertEquals(LoggingLevel.FINEST.name(), Logger.getUserSettings().LoggingLevel__c);

        List<Log__c> logs = [SELECT Id, LogRetentionDate__c FROM Log__c];
        List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c];

        System.assertEquals(1, logs.size());
        System.assertEquals(NUMBER_OF_LOG_ENTRIES, logEntries.size());

        // Verify assumption that the log in the database has a deletion date in the past
        Log__c log = logs.get(0);
        System.assertNotEquals(null, log.LogRetentionDate__c);
        System.assert(log.LogRetentionDate__c < System.today());

        Test.startTest();
        Database.executeBatch(new LogBatchPurger());
        Test.stopTest();

        logs = [SELECT Id FROM Log__c WHERE Id IN :logs];
        logEntries = [SELECT Id FROM LogEntry__c WHERE Id IN :logEntries];
        System.assertEquals(0, logs.size(), logs);
        System.assertEquals(0, logEntries.size(), logEntries);
    }

    @IsTest
    static void it_should_delete_a_log_after_scheduled_deletion_date_when_system_messages_disabled() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.IsEnabled__c = true;
        upsert settings;
        LoggerParameter.setMockParameter(new LoggerParameter__mdt(DeveloperName = 'EnableLoggerSystemMessages', Value__c = String.valueOf(false)));

        System.assertEquals(true, Logger.getUserSettings().IsEnabled__c);
        System.assertEquals(false, LoggerParameter.getBoolean('EnableLoggerSystemMessages', null));
        System.assertEquals(LoggingLevel.FINEST.name(), Logger.getUserSettings().LoggingLevel__c);

        List<Log__c> logs = [SELECT Id, LogRetentionDate__c FROM Log__c];
        List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c];

        System.assertEquals(1, logs.size());
        System.assertEquals(NUMBER_OF_LOG_ENTRIES, logEntries.size());

        // Verify assumption that the log in the database has a deletion date in the past
        Log__c log = logs.get(0);
        System.assertNotEquals(null, log.LogRetentionDate__c);
        System.assert(log.LogRetentionDate__c < System.today());

        Test.startTest();
        Database.executeBatch(new LogBatchPurger());
        Test.stopTest();

        logs = [SELECT Id FROM Log__c WHERE Id IN :logs];
        logEntries = [SELECT Id FROM LogEntry__c WHERE Id IN :logEntries];
        System.assertEquals(0, logs.size(), logs);
        System.assertEquals(0, logEntries.size(), logEntries);
    }

    @IsTest
    static void it_should_not_delete_a_log_before_scheduled_deletion_date() {
        List<Log__c> logs = [SELECT Id, LogRetentionDate__c FROM Log__c];
        List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c];

        System.assertEquals(1, logs.size());
        System.assertEquals(NUMBER_OF_LOG_ENTRIES, logEntries.size());

        // Set the log's deletion date to be in the future
        Log__c log = logs.get(0);
        log.LogRetentionDate__c = System.today().addDays(7);
        update log;
        log = [SELECT Id, LogRetentionDate__c FROM Log__c];
        System.assert(log.LogRetentionDate__c > System.today());

        Test.startTest();
        Database.executeBatch(new LogBatchPurger());
        Test.stopTest();

        logs = [SELECT Id FROM Log__c WHERE Id IN :logs];
        logEntries = [SELECT Id FROM LogEntry__c WHERE Id IN :logEntries];
        System.assertEquals(1, logs.size());
        System.assertEquals(NUMBER_OF_LOG_ENTRIES, logEntries.size());
    }

    @IsTest
    static void it_should_not_delete_a_log_without_a_scheduled_deletion_date_and_with_log_entries() {
        List<Log__c> logs = [SELECT Id, TotalLogEntries__c, LogRetentionDate__c FROM Log__c];
        List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c];

        System.assertEquals(1, logs.size());
        System.assertEquals(NUMBER_OF_LOG_ENTRIES, logs.get(0).TotalLogEntries__c);
        System.assertEquals(NUMBER_OF_LOG_ENTRIES, logEntries.size());

        // Set the log's deletion date to be null
        Log__c log = logs.get(0);
        log.LogRetentionDate__c = null;
        update log;
        log = [SELECT Id, LogRetentionDate__c FROM Log__c];
        System.assertEquals(null, log.LogRetentionDate__c);

        Test.startTest();
        Database.executeBatch(new LogBatchPurger());
        Test.stopTest();

        logs = [SELECT Id FROM Log__c WHERE Id IN :logs];
        logEntries = [SELECT Id FROM LogEntry__c WHERE Id IN :logEntries];
        System.assertEquals(1, logs.size(), logs);
        System.assertEquals(NUMBER_OF_LOG_ENTRIES, logEntries.size(), logEntries);
    }

    @IsTest
    static void it_should_delete_a_log_with_a_scheduled_deletion_date_and_without_log_entries() {
        Date retentionDate = System.today().addDays(-1);
        Log__c log = new Log__c(TransactionId__c = '5678');
        insert log;
        log.LogRetentionDate__c = retentionDate;
        update log;
        log = [SELECT Id, LogRetentionDate__c, TotalLogEntries__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(retentionDate, log.LogRetentionDate__c, 'Log should not have a retention date');
        System.assertEquals(0, log.TotalLogEntries__c, 'Log should not have any related log entries');

        Test.startTest();
        Database.executeBatch(new LogBatchPurger());
        Test.stopTest();

        List<Log__c> matchingLogs = [SELECT Id FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(0, matchingLogs.size(), 'Test log should have been deleted');
    }

    @IsTest
    static void it_should_delete_a_log_without_a_scheduled_deletion_date_and_without_log_entries() {
        Log__c log = new Log__c(TransactionId__c = '5678');
        insert log;
        log.LogRetentionDate__c = null;
        update log;
        log = [SELECT Id, LogRetentionDate__c, TotalLogEntries__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(null, log.LogRetentionDate__c, 'Log should not have a retention date');
        System.assertEquals(0, log.TotalLogEntries__c, 'Log should not have any related log entries');

        Test.startTest();
        Database.executeBatch(new LogBatchPurger());
        Test.stopTest();

        List<Log__c> matchingLogs = [SELECT Id FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(0, matchingLogs.size(), 'Test log should have been deleted');
    }

    @IsTest
    static void it_should_run_plugin_start_method() {
        LogBatchPurger instance = new LogBatchPurger();
        LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
            IsEnabled__c = true,
            BatchPurgerApexClass__c = ExampleBatchPurgerPlugin.class.getName()
        );
        instance.currentSObjectType = Schema.LogEntry__c.SObjectType;
        instance.addMockPlugin(mockPluginConfiguration);
        System.assertEquals(false, ranPluginStart);
        System.assertEquals(false, ranPluginExecute);
        System.assertEquals(false, ranPluginFinish);
        System.assertEquals(null, pluginConfiguration);
        System.assertEquals(null, pluginInput);

        MockBatchableContext mockBatchableContext = new MockBatchableContext('some_fake_job_id');
        instance.start(mockBatchableContext);

        LogBatchPurger.BatchPurgerInput expectedInput = new LogBatchPurger.BatchPurgerInput(mockBatchableContext, instance.currentSObjectType);
        System.assertEquals(true, ranPluginStart);
        System.assertEquals(false, ranPluginExecute);
        System.assertEquals(false, ranPluginFinish);
        System.assertEquals(mockPluginConfiguration, pluginConfiguration);
        System.assertEquals(expectedInput.batchableContext, pluginInput.batchableContext);
        System.assertEquals(expectedInput.sobjectType, pluginInput.sobjectType);
    }

    @IsTest
    static void it_should_run_plugin_execute_method() {
        LogBatchPurger instance = new LogBatchPurger();
        LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
            IsEnabled__c = true,
            BatchPurgerApexClass__c = ExampleBatchPurgerPlugin.class.getName()
        );
        instance.currentSObjectType = Schema.LogEntry__c.SObjectType;
        instance.addMockPlugin(mockPluginConfiguration);
        System.assertEquals(false, ranPluginStart);
        System.assertEquals(false, ranPluginExecute);
        System.assertEquals(false, ranPluginFinish);
        System.assertEquals(null, pluginConfiguration);
        System.assertEquals(null, pluginInput);
        List<Log__c> logsToDelete = [SELECT Id FROM Log__c];
        System.assertNotEquals(0, logsToDelete.size());

        MockBatchableContext mockBatchableContext = new MockBatchableContext('some_fake_job_id');
        instance.execute(mockBatchableContext, logsToDelete);

        LogBatchPurger.BatchPurgerInput expectedInput = new LogBatchPurger.BatchPurgerInput(mockBatchableContext, instance.currentSObjectType);
        System.assertEquals(false, ranPluginStart);
        System.assertEquals(true, ranPluginExecute);
        System.assertEquals(false, ranPluginFinish);
        System.assertEquals(mockPluginConfiguration, pluginConfiguration);
        System.assertEquals(expectedInput.batchableContext, pluginInput.batchableContext);
        logsToDelete = [SELECT Id FROM Log__c WHERE Id IN :logsToDelete];
        System.assertEquals(0, logsToDelete.size(), 'All logs should have still been deleted by LogBatchPurger after running plugins: ' + logsToDelete);
    }

    @IsTest
    static void it_should_run_plugin_finish_method() {
        LogBatchPurger instance = new LogBatchPurger();
        LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
            IsEnabled__c = true,
            BatchPurgerApexClass__c = ExampleBatchPurgerPlugin.class.getName()
        );
        instance.currentSObjectType = Schema.LogEntry__c.SObjectType;
        instance.addMockPlugin(mockPluginConfiguration);
        System.assertEquals(false, ranPluginStart);
        System.assertEquals(false, ranPluginExecute);
        System.assertEquals(false, ranPluginFinish);
        System.assertEquals(null, pluginConfiguration);
        System.assertEquals(null, pluginInput);

        MockBatchableContext mockBatchableContext = new MockBatchableContext('some_fake_job_id');
        instance.finish(mockBatchableContext);

        LogBatchPurger.BatchPurgerInput expectedInput = new LogBatchPurger.BatchPurgerInput(mockBatchableContext, instance.currentSObjectType);
        System.assertEquals(false, ranPluginStart);
        System.assertEquals(false, ranPluginExecute);
        System.assertEquals(true, ranPluginFinish);
        System.assertEquals(mockPluginConfiguration, pluginConfiguration);
        System.assertEquals(expectedInput.sobjectType, pluginInput.sobjectType);
    }

    public class MockBatchableContext implements Database.BatchableContext {
        private String childJobId, jobId;

        public MockBatchableContext(String jobId) {
            this(jobId, null);
        }

        public MockBatchableContext(String jobId, Id childJobId) {
            this.jobId = jobId;
            this.childJobId = childJobId;
        }

        public String getChildJobId() {
            return childJobId;
        }

        public String getJobId() {
            return jobId;
        }
    }

    public class ExampleBatchPurgerPlugin implements LoggerPlugin.Batchable {
        public void start(LoggerPlugin__mdt configuration, LogBatchPurger.BatchPurgerInput input) {
            ranPluginStart = true;
            pluginConfiguration = configuration;
            pluginInput = input;
        }

        public void execute(LoggerPlugin__mdt configuration, LogBatchPurger.BatchPurgerInput input, List<SObject> scope) {
            ranPluginExecute = true;
            pluginConfiguration = configuration;
            pluginInput = input;
            pluginRecords = scope;
        }

        public void finish(LoggerPlugin__mdt configuration, LogBatchPurger.BatchPurgerInput input) {
            ranPluginFinish = true;
            pluginConfiguration = configuration;
            pluginInput = input;
        }
    }
}
