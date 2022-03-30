//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class LogBatchPurger_Tests_Flow {
    // This Flow simply returns a string variable called 'someExampleVariable'
    // that's used in tests below to verify if the Flow was dynamically executed
    private static final String MOCK_FLOW_NAME = 'MockLogBatchPurgerPlugin';
    private static final String MOCK_FLOW_OUTPUT_VARIABLE_NAME = 'someExampleVariable';
    private static final String MOCK_FLOW_OUTPUT_VARIABLE_VALUE = 'Hello, world';

    private static final Integer NUMBER_OF_LOG_ENTRIES_TO_CREATE = 10;

    // private static Boolean ranPluginStart = false;
    // private static Boolean ranPluginExecute = false;
    // private static Boolean ranPluginFinish = false;
    // private static LoggerPlugin__mdt pluginConfiguration;
    // private static LoggerBatchableContext batchInput;
    // private static List<SObject> pluginRecords;

    @TestSetup
    static void setupData() {
        LoggerSObjectHandler.shouldExecute(false);
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.IsEnabled__c = false;
        settings.LoggingLevel__c = LoggingLevel.FINEST.name();
        insert settings;

        Date scheduledDeletionDate = System.today().addDays(-7);
        Log__c log = new Log__c(LogRetentionDate__c = scheduledDeletionDate);
        new LoggerSObjectTestDataGenerator(log).populateRequiredFields();
        insert log;

        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        for (Integer i = 0; i < NUMBER_OF_LOG_ENTRIES_TO_CREATE; i++) {
            LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = LoggingLevel.INFO.name());
            new LoggerSObjectTestDataGenerator(logEntry).populateRequiredFields();
            logEntries.add(logEntry);
        }
        insert logEntries;

        LoggerTag__c tag = (LoggerTag__c) new LoggerSObjectTestDataGenerator(Schema.LoggerTag__c.SObjectType).populateRequiredFields();
        insert tag;

        List<LogEntryTag__c> logEntryTags = new List<LogEntryTag__c>();
        for (LogEntry__c logEntry : logEntries) {
            LogEntryTag__c logEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
            new LoggerSObjectTestDataGenerator(logEntryTag).populateRequiredFields();
            logEntryTags.add(logEntryTag);
        }
        insert logEntryTags;
    }

    @IsTest
    static void it_should_run_flow_plugin_in_start_method() {
        LoggerSObjectHandler.shouldExecute(false);
        LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
            DeveloperName = 'Mock_Plugin',
            IsEnabled__c = true,
            BatchPurgerFlowName__c = MOCK_FLOW_NAME
        );
        LoggerTestUtils.setMock(mockPluginConfiguration);
        LogBatchPurger batchJobInstance = new LogBatchPurger();
        batchJobInstance.currentSObjectType = Schema.LogEntry__c.SObjectType;
        Database.BatchableContext mockBatchableContext = LoggerTestUtils.createMockBatchableContext('some_fake_job_id');

        batchJobInstance.start(mockBatchableContext);

        LoggerBatchableContext expectedInput = new LoggerBatchableContext(mockBatchableContext, batchJobInstance.currentSObjectType);
        System.assertEquals(3, batchJobInstance.getExecutedFlowPlugins().size(), batchJobInstance.getExecutedFlowPlugins());
        System.assertEquals(
            1,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.START).size(),
            batchJobInstance.getExecutedFlowPlugins()
        );
        System.assertEquals(
            0,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.EXECUTE).size(),
            batchJobInstance.getExecutedFlowPlugins()
        );
        System.assertEquals(
            0,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.FINISH).size(),
            batchJobInstance.getExecutedFlowPlugins()
        );
        Flow.Interview flowStartPlugin = batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.START).get(0);
        System.assertEquals(MOCK_FLOW_OUTPUT_VARIABLE_VALUE, flowStartPlugin.getVariableValue(MOCK_FLOW_OUTPUT_VARIABLE_NAME), flowStartPlugin);
    }

    @IsTest
    static void it_should_run_flow_plugin_in_execute_method() {
        LoggerSObjectHandler.shouldExecute(false);
        LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
            DeveloperName = 'Mock_Plugin',
            IsEnabled__c = true,
            BatchPurgerFlowName__c = MOCK_FLOW_NAME
        );
        LoggerTestUtils.setMock(mockPluginConfiguration);
        LogBatchPurger batchJobInstance = new LogBatchPurger();
        List<Log__c> logsToDelete = [SELECT Id FROM Log__c];
        System.assertNotEquals(0, logsToDelete.size());
        Database.BatchableContext mockBatchableContext = LoggerTestUtils.createMockBatchableContext('some_fake_job_id');

        batchJobInstance.execute(mockBatchableContext, logsToDelete);

        LoggerBatchableContext expectedInput = new LoggerBatchableContext(mockBatchableContext, batchJobInstance.currentSObjectType);
        System.assertEquals(3, batchJobInstance.getExecutedFlowPlugins().size(), batchJobInstance.getExecutedFlowPlugins());
        System.assertEquals(
            0,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.START).size(),
            batchJobInstance.getExecutedFlowPlugins()
        );
        System.assertEquals(
            1,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.EXECUTE).size(),
            batchJobInstance.getExecutedFlowPlugins()
        );
        System.assertEquals(
            0,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.FINISH).size(),
            batchJobInstance.getExecutedFlowPlugins()
        );
        Flow.Interview flowExecutePlugin = batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.EXECUTE).get(0);
        System.assertEquals(MOCK_FLOW_OUTPUT_VARIABLE_VALUE, flowExecutePlugin.getVariableValue(MOCK_FLOW_OUTPUT_VARIABLE_NAME), flowExecutePlugin);
    }

    @IsTest
    static void it_should_run_flow_plugin_in_finish_method() {
        LoggerSObjectHandler.shouldExecute(false);
        LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
            DeveloperName = 'Mock_Plugin',
            IsEnabled__c = true,
            BatchPurgerFlowName__c = MOCK_FLOW_NAME
        );
        LoggerTestUtils.setMock(mockPluginConfiguration);
        LogBatchPurger batchJobInstance = new LogBatchPurger();
        List<Log__c> logsToDelete = [SELECT Id FROM Log__c];
        System.assertNotEquals(0, logsToDelete.size());
        Database.BatchableContext mockBatchableContext = LoggerTestUtils.createMockBatchableContext('some_fake_job_id');

        batchJobInstance.finish(mockBatchableContext);

        LoggerBatchableContext expectedInput = new LoggerBatchableContext(mockBatchableContext, batchJobInstance.currentSObjectType);
        System.assertEquals(3, batchJobInstance.getExecutedFlowPlugins().size(), batchJobInstance.getExecutedFlowPlugins());
        System.assertEquals(
            0,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.START).size(),
            batchJobInstance.getExecutedFlowPlugins()
        );
        System.assertEquals(
            0,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.EXECUTE).size(),
            batchJobInstance.getExecutedFlowPlugins()
        );
        System.assertEquals(
            1,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.FINISH).size(),
            batchJobInstance.getExecutedFlowPlugins()
        );
        Flow.Interview flowFinishPlugin = batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.FINISH).get(0);
        System.assertEquals(MOCK_FLOW_OUTPUT_VARIABLE_VALUE, flowFinishPlugin.getVariableValue(MOCK_FLOW_OUTPUT_VARIABLE_NAME), flowFinishPlugin);
    }
}
