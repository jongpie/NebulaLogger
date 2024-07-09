//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=false)
private class LogBatchPurger_Tests_Flow {
    // This Flow simply returns a string variable called 'someExampleVariable'
    // that's used in tests below to verify if the Flow was dynamically executed
    private static final String MOCK_FLOW_NAME = 'MockLogBatchPurgerPlugin';
    private static final String MOCK_FLOW_OUTPUT_VARIABLE_NAME = 'someExampleVariable';
    private static final String MOCK_FLOW_OUTPUT_VARIABLE_VALUE = 'Hello, world';

    private static final Integer NUMBER_OF_LOG_ENTRIES_TO_CREATE = 10;

    @TestSetup
    static void setupData() {
        LoggerSObjectHandler.shouldExecute(false);
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.IsEnabled__c = false;
        settings.LoggingLevel__c = System.LoggingLevel.FINEST.name();
        insert settings;

        Date scheduledDeletionDate = System.today().addDays(-7);
        Log__c log = new Log__c(LogRetentionDate__c = scheduledDeletionDate);
        LoggerMockDataCreator.createDataBuilder(log).populateRequiredFields().getRecord();
        insert log;

        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        for (Integer i = 0; i < NUMBER_OF_LOG_ENTRIES_TO_CREATE; i++) {
            LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.INFO.name());
            LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();
            logEntries.add(logEntry);
        }
        insert logEntries;

        LoggerTag__c tag = (LoggerTag__c) LoggerMockDataCreator.createDataBuilder(Schema.LoggerTag__c.SObjectType).populateRequiredFields().getRecord();
        insert tag;

        List<LogEntryTag__c> logEntryTags = new List<LogEntryTag__c>();
        for (LogEntry__c logEntry : logEntries) {
            LogEntryTag__c logEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
            LoggerMockDataCreator.createDataBuilder(logEntryTag).populateRequiredFields().getRecord();
            logEntryTags.add(logEntryTag);
        }
        insert logEntryTags;
    }

    @IsTest
    static void it_should_run_flow_plugin_in_start_method() {
        LoggerSObjectHandler.shouldExecute(false);
        LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
            BatchPurgerExecutionOrder__c = 1,
            BatchPurgerFlowName__c = MOCK_FLOW_NAME,
            DeveloperName = 'Mock_Plugin',
            IsEnabled__c = true
        );
        LoggerTestConfigurator.setMock(mockPluginConfiguration);
        LogBatchPurger batchJobInstance = new LogBatchPurger();
        batchJobInstance.currentSObjectType = Schema.LogEntry__c.SObjectType;
        Database.BatchableContext mockBatchableContext = new LoggerMockDataCreator.MockBatchableContext();

        batchJobInstance.start(mockBatchableContext);

        LoggerBatchableContext expectedInput = new LoggerBatchableContext(mockBatchableContext, batchJobInstance.currentSObjectType);
        System.Assert.areEqual(
            3,
            batchJobInstance.getExecutedFlowPlugins().size(),
            'The map of executed Flow plugins should have 3 keys - one for each enum value in LogBatchPurger.BatchableMethod (START, EXECUTE, and FINISH)'
        );
        System.Assert.areEqual(
            1,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.START).size(),
            'One Flow plugin should have run in the batch job\'s start method'
        );
        System.Assert.areEqual(
            0,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.EXECUTE).size(),
            'No Flow plugins should have run in the batch job\'s execute method'
        );
        System.Assert.areEqual(
            0,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.FINISH).size(),
            'No Flow plugins should have run in the batch job\'s finish method'
        );
        Flow.Interview flowStartPlugin = batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.START).get(0);
        LoggerPlugin__mdt returnedPluginConfiguration = (LoggerPlugin__mdt) flowStartPlugin.getVariableValue('pluginConfiguration');
        System.Assert.areEqual(mockPluginConfiguration, returnedPluginConfiguration, 'LoggerPlugin__mdt records should match');
        LoggerBatchableContext returnedPluginInput = (LoggerBatchableContext) flowStartPlugin.getVariableValue('pluginInput');
        System.Assert.areEqual(System.JSON.serialize(expectedInput), System.JSON.serialize(returnedPluginInput), 'Plugin inputs should match');
        System.Assert.areEqual(
            MOCK_FLOW_OUTPUT_VARIABLE_VALUE,
            flowStartPlugin.getVariableValue(MOCK_FLOW_OUTPUT_VARIABLE_NAME),
            'Flow should have returned the variable ' + MOCK_FLOW_OUTPUT_VARIABLE_NAME + ' with the value + ' + MOCK_FLOW_OUTPUT_VARIABLE_VALUE
        );
    }

    @IsTest
    static void it_should_run_flow_plugin_in_execute_method() {
        LoggerSObjectHandler.shouldExecute(false);
        LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
            BatchPurgerExecutionOrder__c = 1,
            BatchPurgerFlowName__c = MOCK_FLOW_NAME,
            DeveloperName = 'Mock_Plugin',
            IsEnabled__c = true
        );
        LoggerTestConfigurator.setMock(mockPluginConfiguration);
        LogBatchPurger batchJobInstance = new LogBatchPurger();
        List<Log__c> logsToDelete = [SELECT Id FROM Log__c];
        System.Assert.areNotEqual(0, logsToDelete.size());
        Database.BatchableContext mockBatchableContext = new LoggerMockDataCreator.MockBatchableContext();

        batchJobInstance.execute(mockBatchableContext, logsToDelete);

        LoggerBatchableContext expectedInput = new LoggerBatchableContext(mockBatchableContext, batchJobInstance.currentSObjectType);
        System.Assert.areEqual(
            3,
            batchJobInstance.getExecutedFlowPlugins().size(),
            'The map of executed Flow plugins should have 3 keys - one for each enum value in LogBatchPurger.BatchableMethod (START, EXECUTE, and FINISH)'
        );
        System.Assert.areEqual(
            0,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.START).size(),
            'No Flow plugins should have run in the batch job\'s start method'
        );
        System.Assert.areEqual(
            1,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.EXECUTE).size(),
            'One Flow plugin should have run in the batch job\'s execute method'
        );
        System.Assert.areEqual(
            0,
            batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.FINISH).size(),
            'No Flow plugins should have run in the batch job\'s finish method'
        );
        Flow.Interview flowExecutePlugin = batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.EXECUTE).get(0);
        LoggerPlugin__mdt returnedPluginConfiguration = (LoggerPlugin__mdt) flowExecutePlugin.getVariableValue('pluginConfiguration');
        System.Assert.areEqual(mockPluginConfiguration, returnedPluginConfiguration, 'LoggerPlugin__mdt records should match');
        LoggerBatchableContext returnedPluginInput = (LoggerBatchableContext) flowExecutePlugin.getVariableValue('pluginInput');
        System.Assert.areEqual(System.JSON.serialize(expectedInput), System.JSON.serialize(returnedPluginInput), 'Plugin inputs should match');
        System.Assert.areEqual(
            MOCK_FLOW_OUTPUT_VARIABLE_VALUE,
            flowExecutePlugin.getVariableValue(MOCK_FLOW_OUTPUT_VARIABLE_NAME),
            'Flow should have returned the variable ' + MOCK_FLOW_OUTPUT_VARIABLE_NAME + ' with the value + ' + MOCK_FLOW_OUTPUT_VARIABLE_VALUE
        );
    }

    // FIXME this method consistently fails inconsistently, sometimes with a GACK, but appears to work when manually testing it. I'll revisit it a future release.
    // @IsTest
    // static void it_should_run_flow_plugin_in_finish_method() {
    //     LoggerSObjectHandler.shouldExecute(false);
    //     LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
    //         BatchPurgerExecutionOrder__c = 1,
    //         BatchPurgerFlowName__c = MOCK_FLOW_NAME,
    //         DeveloperName = 'Mock_Plugin',
    //         IsEnabled__c = true
    //     );
    //     LoggerTestConfigurator.setMock(mockPluginConfiguration);
    //     LogBatchPurger batchJobInstance = new LogBatchPurger();
    //     List<Log__c> logsToDelete = [SELECT Id FROM Log__c];
    //     System.Assert.areNotEqual(0, logsToDelete.size(), 'There should be some records to delete');
    //     Database.BatchableContext mockBatchableContext = new LoggerMockDataCreator.MockBatchableContext();

    //     batchJobInstance.finish(mockBatchableContext);

    //     LoggerBatchableContext expectedInput = new LoggerBatchableContext(mockBatchableContext, batchJobInstance.currentSObjectType);
    //     System.Assert.areEqual(
    //         3,
    //         batchJobInstance.getExecutedFlowPlugins().size(),
    //         'The map of executed Flow plugins should have 3 keys - one for each enum value in LogBatchPurger.BatchableMethod (START, EXECUTE, and FINISH)'
    //     );
    //     System.Assert.areEqual(
    //         0,
    //         batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.START).size(),
    //         'No Flow plugins should have run in the batch job\'s start method'
    //     );
    //     System.Assert.areEqual(
    //         0,
    //         batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.EXECUTE).size(),
    //         'No Flow plugins should have run in the batch job\'s execute method'
    //     );
    //     System.Assert.areEqual(
    //         1,
    //         batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.FINISH).size(),
    //         'One Flow plugin should have run in the batch job\'s finish method'
    //     );
    //     Flow.Interview flowFinishPlugin = batchJobInstance.getExecutedFlowPlugins().get(LogBatchPurger.BatchableMethod.FINISH).get(0);
    //     LoggerPlugin__mdt returnedPluginConfiguration = (LoggerPlugin__mdt) flowFinishPlugin.getVariableValue('pluginConfiguration');
    //     System.Assert.areEqual(mockPluginConfiguration, returnedPluginConfiguration, 'LoggerPlugin__mdt records should match');
    //     LoggerBatchableContext returnedPluginInput = (LoggerBatchableContext) flowFinishPlugin.getVariableValue('pluginInput');
    //     System.Assert.areEqual(System.JSON.serialize(expectedInput), System.JSON.serialize(returnedPluginInput), 'Plugin inputs should match');
    //     System.Assert.areEqual(
    //         MOCK_FLOW_OUTPUT_VARIABLE_VALUE,
    //         flowFinishPlugin.getVariableValue(MOCK_FLOW_OUTPUT_VARIABLE_NAME),
    //         'Flow should have returned the variable ' +
    //         MOCK_FLOW_OUTPUT_VARIABLE_NAME +
    //         ' with the value + ' +
    //         MOCK_FLOW_OUTPUT_VARIABLE_VALUE
    //     );
    // }
}
