//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest
private class LoggerSObjectHandler_Tests {
    private static final String FAKE_PROFILE_NAME = 'Some String';

    @TestSetup
    static void setupData() {
        LoggerSObjectHandler.shouldExecute(false);
        insert new Log__c(TransactionId__c = '1234');
    }

    @IsTest
    static void it_should_not_run_when_disabled_via_logger_parameter() {
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.Log__c.SObjectType);
        mockHandler.handlerConfiguration = new LoggerSObjectHandler__mdt(IsEnabled__c = false);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        mockHandler.triggerNew = new List<Log__c>{ new Log__c(TransactionId__c = '1234') };
        mockHandler.triggerNewMap = null;
        mockHandler.triggerOldMap = null;

        mockHandler.execute();

        System.assertEquals(0, mockHandler.executionCount, mockHandler);
    }

    @IsTest
    static void it_should_run_before_insert_method() {
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.Log__c.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        mockHandler.triggerNew = new List<Log__c>{ new Log__c(TransactionId__c = '1234') };
        mockHandler.triggerNewMap = null;
        mockHandler.triggerOldMap = null;

        mockHandler.execute();

        System.assertEquals(1, mockHandler.executionCount);
        System.assertEquals(TriggerOperation.BEFORE_INSERT, mockHandler.executedTriggerOperationType);
        System.assertEquals(mockHandler.triggerNew, mockHandler.executedTriggerNew);
        System.assertEquals(null, mockHandler.executedTriggerNewMap);
        System.assertEquals(null, mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_before_update_method() {
        List<SObject> records = [SELECT Id, TransactionId__c FROM Log__c];
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.Log__c.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_UPDATE;
        mockHandler.triggerNew = null;
        mockHandler.triggerNewMap = new Map<Id, SObject>(records);
        mockHandler.triggerOldMap = new Map<Id, SObject>(records);

        mockHandler.execute();

        System.assertEquals(1, mockHandler.executionCount);
        System.assertEquals(TriggerOperation.BEFORE_UPDATE, mockHandler.executedTriggerOperationType);
        System.assertEquals(null, mockHandler.executedTriggerNew);
        System.assertEquals(mockHandler.triggerNewMap, mockHandler.executedTriggerNewMap);
        System.assertEquals(mockHandler.triggerOldMap, mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_before_delete_method() {
        List<SObject> records = [SELECT Id, TransactionId__c FROM Log__c];
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.Log__c.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_DELETE;
        mockHandler.triggerNew = null;
        mockHandler.triggerNewMap = new Map<Id, SObject>(records);
        mockHandler.triggerOldMap = null;

        mockHandler.execute();

        System.assertEquals(1, mockHandler.executionCount);
        System.assertEquals(TriggerOperation.BEFORE_DELETE, mockHandler.executedTriggerOperationType);
        System.assertEquals(null, mockHandler.executedTriggerNew);
        System.assertEquals(mockHandler.triggerNewMap, mockHandler.executedTriggerNewMap);
        System.assertEquals(null, mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_after_insert_methods() {
        // To handle AFTER_INSERT on LogEntryEvent__e, LoggerSObjectHandler has 2 methods - one with
        // a list of SObject records (triggerNew), and another with a map of SObject records (triggerNewMap)
        List<Log__c> records = [SELECT Id, TransactionId__c FROM Log__c];
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.Log__c.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.AFTER_INSERT;
        mockHandler.triggerNew = records;
        mockHandler.triggerNewMap = new Map<Id, SObject>(records);
        mockHandler.triggerOldMap = null;

        mockHandler.execute();

        System.assertEquals(2, mockHandler.executionCount);
        System.assertEquals(TriggerOperation.AFTER_INSERT, mockHandler.executedTriggerOperationType);
        System.assertEquals(mockHandler.triggerNew, mockHandler.executedTriggerNew);
        System.assertEquals(mockHandler.triggerNewMap, mockHandler.executedTriggerNewMap);
        System.assertEquals(null, mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_after_update_method() {
        List<SObject> records = [SELECT Id, TransactionId__c FROM Log__c];
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.Log__c.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.AFTER_UPDATE;
        mockHandler.triggerNew = null;
        mockHandler.triggerNewMap = new Map<Id, SObject>(records);
        mockHandler.triggerOldMap = new Map<Id, SObject>(records);

        mockHandler.execute();

        System.assertEquals(1, mockHandler.executionCount);
        System.assertEquals(TriggerOperation.AFTER_UPDATE, mockHandler.executedTriggerOperationType);
        System.assertEquals(null, mockHandler.executedTriggerNew);
        System.assertEquals(mockHandler.triggerNewMap, mockHandler.executedTriggerNewMap);
        System.assertEquals(mockHandler.triggerOldMap, mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_after_delete_method() {
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.Log__c.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.AFTER_DELETE;
        mockHandler.triggerNew = null;
        mockHandler.triggerNewMap = new Map<Id, SObject>([SELECT Id, TransactionId__c FROM Log__c]);
        mockHandler.triggerOldMap = null;

        mockHandler.execute();

        System.assertEquals(1, mockHandler.executionCount);
        System.assertEquals(TriggerOperation.AFTER_DELETE, mockHandler.executedTriggerOperationType);
        System.assertEquals(null, mockHandler.executedTriggerNew);
        System.assertEquals(mockHandler.triggerNewMap, mockHandler.executedTriggerNewMap);
        System.assertEquals(null, mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_after_undelete_method() {
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.Log__c.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.AFTER_UNDELETE;
        mockHandler.triggerNew = null;
        mockHandler.triggerNewMap = new Map<Id, SObject>([SELECT Id, TransactionId__c FROM Log__c]);
        mockHandler.triggerOldMap = null;

        mockHandler.execute();

        System.assertEquals(1, mockHandler.executionCount);
        System.assertEquals(TriggerOperation.AFTER_UNDELETE, mockHandler.executedTriggerOperationType);
        System.assertEquals(null, mockHandler.executedTriggerNew);
        System.assertEquals(mockHandler.triggerNewMap, mockHandler.executedTriggerNewMap);
        System.assertEquals(null, mockHandler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_gracefully_skip_non_existent_apex_plugin() {
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.Log__c.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        mockHandler.triggerNew = new List<Log__c>{ new Log__c(TransactionId__c = '1234') };
        mockHandler.triggerNewMap = null;
        mockHandler.triggerOldMap = null;
        LoggerPlugin__mdt pluginConfiguration = new LoggerPlugin__mdt(
            DeveloperName = 'Mock_Plugin',
            IsEnabled__c = true,
            SObjectHandlerApexClass__c = 'Some_Fake_Apex_Class'
        );
        mockHandler.getPluginConfigurations().add(pluginConfiguration);

        mockHandler.execute();

        System.assertEquals(1, mockHandler.executionCount);
        System.assertEquals(1, mockHandler.getPluginConfigurations().size(), mockHandler.getPluginConfigurations());
        System.assertEquals(0, mockHandler.getExecutedApexPlugins().size(), mockHandler.getExecutedApexPlugins());
    }

    @IsTest
    static void it_should_execute_apex_plugin() {
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.Log__c.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        mockHandler.triggerNew = new List<Log__c>{ new Log__c(TransactionId__c = '1234') };
        mockHandler.triggerNewMap = null;
        mockHandler.triggerOldMap = null;
        LoggerPlugin__mdt mockPluginConfiguration = new LoggerPlugin__mdt(
            DeveloperName = 'ExampleApexPlugin',
            IsEnabled__c = true,
            SObjectHandlerApexClass__c = MockTriggerablePlugin.class.getName()
        );
        mockHandler.getPluginConfigurations().add(mockPluginConfiguration);

        mockHandler.execute();

        System.assertEquals(1, mockHandler.executionCount);
        System.assertEquals(1, mockHandler.getPluginConfigurations().size(), mockHandler.getPluginConfigurations());
        System.assertEquals(1, mockHandler.getExecutedApexPlugins().size(), mockHandler.getExecutedApexPlugins());
        MockTriggerablePlugin executedApexPlugin = (MockTriggerablePlugin) mockHandler.getExecutedApexPlugins().get(0);
        System.assertEquals(mockPluginConfiguration, executedApexPlugin.configuration);
        System.assertEquals(mockHandler.input, executedApexPlugin.input);
    }

    @IsTest
    static void it_should_gracefully_skip_non_existent_flow_plugin() {
        MockSObjectHandler mockHandler = new MockSObjectHandler(Schema.Log__c.SObjectType);
        mockHandler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        mockHandler.triggerNew = new List<Log__c>{ new Log__c(TransactionId__c = '1234') };
        mockHandler.triggerNewMap = null;
        mockHandler.triggerOldMap = null;
        LoggerPlugin__mdt pluginConfiguration = new LoggerPlugin__mdt(
            DeveloperName = 'Mock_Plugin',
            IsEnabled__c = true,
            SObjectHandlerFlowName__c = 'Some_Fake_Flow'
        );
        mockHandler.getPluginConfigurations().add(pluginConfiguration);

        mockHandler.execute();

        System.assertEquals(1, mockHandler.executionCount);
        System.assertEquals(1, mockHandler.getPluginConfigurations().size(), mockHandler.getPluginConfigurations());
        System.assertEquals(0, mockHandler.getExecutedApexPlugins().size(), mockHandler.getExecutedApexPlugins());
    }

    public class MockSObjectHandler extends LoggerSObjectHandler {
        public Integer executionCount = 0;
        public TriggerOperation executedTriggerOperationType;
        public List<SObject> executedTriggerNew;
        public Map<Id, SObject> executedTriggerNewMap;
        public Map<Id, SObject> executedTriggerOldMap;

        private Schema.SObjectType sobjectType;

        public MockSObjectHandler(Schema.SObjectType sobjectType) {
            this.sobjectType = sobjectType;
        }

        public override SObjectType getSObjectType() {
            return this.sobjectType;
        }

        protected override void executeBeforeInsert(List<SObject> triggerNew) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.BEFORE_INSERT;
            this.executedTriggerNew = triggerNew;
        }

        protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.BEFORE_UPDATE;
            this.executedTriggerNewMap = triggerNewMap;
            this.executedTriggerOldMap = triggerOldMap;
        }

        protected override void executeBeforeDelete(Map<Id, SObject> triggerNewMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.BEFORE_DELETE;
            this.executedTriggerNewMap = triggerNewMap;
        }

        protected override void executeAfterInsert(List<SObject> triggerNew) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_INSERT;
            this.executedTriggerNew = triggerNew;
        }

        protected override void executeAfterInsert(Map<Id, SObject> triggerNewMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_INSERT;
            this.executedTriggerNewMap = triggerNewMap;
        }

        protected override void executeAfterUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_UPDATE;
            this.executedTriggerNewMap = triggerNewMap;
            this.executedTriggerOldMap = triggerOldMap;
        }

        protected override void executeAfterDelete(Map<Id, SObject> triggerNewMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_DELETE;
            this.executedTriggerNewMap = triggerNewMap;
        }

        protected override void executeAfterUndelete(Map<Id, SObject> triggerNewMap) {
            this.executionCount++;
            this.executedTriggerOperationType = TriggerOperation.AFTER_UNDELETE;
            this.executedTriggerNewMap = triggerNewMap;
        }
    }

    public class MockTriggerablePlugin implements LoggerPlugin.Triggerable {
        public Boolean hasExecuted { get; private set; }
        public LoggerPlugin__mdt configuration { get; private set; }
        public LoggerTriggerableContext input { get; private set; }

        public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input) {
            this.hasExecuted = true;
            this.configuration = configuration;
            this.input = input;
        }
    }
}
