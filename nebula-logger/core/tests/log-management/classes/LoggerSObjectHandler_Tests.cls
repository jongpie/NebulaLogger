//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest
private class LoggerSObjectHandler_Tests {
    private static final String HANDLER_CONTROL_PARAMETER_NAME = 'IsMockLogHandlerEnabled';

    @TestSetup
    static void setupData() {
        insert new Log__c(TransactionId__c = '1234');
    }

    @IsTest
    static void it_should_not_run_when_disabled_via_logger_parameter() {
        LoggerParameter.setMockParameter(new LoggerParameter__mdt(DeveloperName = HANDLER_CONTROL_PARAMETER_NAME, Value__c = 'false'));
        MockLogHandler handler = new MockLogHandler();
        handler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        handler.triggerNew = new List<Log__c>{ new Log__c(TransactionId__c = '1234') };
        handler.triggerNewMap = null;
        handler.triggerOldMap = null;

        handler.execute();

        System.assertEquals(0, handler.executionCount);
    }

    @IsTest
    static void it_should_run_before_insert_method() {
        MockLogHandler handler = new MockLogHandler();
        handler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        handler.triggerNew = new List<Log__c>{ new Log__c(TransactionId__c = '1234') };
        handler.triggerNewMap = null;
        handler.triggerOldMap = null;

        handler.execute();

        System.assertEquals(1, handler.executionCount);
        System.assertEquals(TriggerOperation.BEFORE_INSERT, handler.executedTriggerOperationType);
        System.assertEquals(handler.triggerNew, handler.executedTriggerNew);
        System.assertEquals(null, handler.executedTriggerNewMap);
        System.assertEquals(null, handler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_before_update_method() {
        List<SObject> records = [SELECT Id, TransactionId__c FROM Log__c];
        MockLogHandler handler = new MockLogHandler();
        handler.triggerOperationType = TriggerOperation.BEFORE_UPDATE;
        handler.triggerNew = null;
        handler.triggerNewMap = new Map<Id, SObject>(records);
        handler.triggerOldMap = new Map<Id, SObject>(records);

        handler.execute();

        System.assertEquals(1, handler.executionCount);
        System.assertEquals(TriggerOperation.BEFORE_UPDATE, handler.executedTriggerOperationType);
        System.assertEquals(null, handler.executedTriggerNew);
        System.assertEquals(handler.triggerNewMap, handler.executedTriggerNewMap);
        System.assertEquals(handler.triggerOldMap, handler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_before_delete_method() {
        List<SObject> records = [SELECT Id, TransactionId__c FROM Log__c];
        MockLogHandler handler = new MockLogHandler();
        handler.triggerOperationType = TriggerOperation.BEFORE_DELETE;
        handler.triggerNew = null;
        handler.triggerNewMap = new Map<Id, SObject>(records);
        handler.triggerOldMap = null;

        handler.execute();

        System.assertEquals(1, handler.executionCount);
        System.assertEquals(TriggerOperation.BEFORE_DELETE, handler.executedTriggerOperationType);
        System.assertEquals(null, handler.executedTriggerNew);
        System.assertEquals(handler.triggerNewMap, handler.executedTriggerNewMap);
        System.assertEquals(null, handler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_after_insert_methods() {
        // To handle AFTER_INSERT on LogEntryEvent__e, LoggerSObjectHandler has 2 methods - one with
        // a list of SObject records (triggerNew), and another with a map of SObject records (triggerNewMap)
        List<Log__c> records = [SELECT Id, TransactionId__c FROM Log__c];
        MockLogHandler handler = new MockLogHandler();
        handler.triggerOperationType = TriggerOperation.AFTER_INSERT;
        handler.triggerNew = records;
        handler.triggerNewMap = new Map<Id, SObject>(records);
        handler.triggerOldMap = null;

        handler.execute();

        System.assertEquals(2, handler.executionCount);
        System.assertEquals(TriggerOperation.AFTER_INSERT, handler.executedTriggerOperationType);
        System.assertEquals(handler.triggerNew, handler.executedTriggerNew);
        System.assertEquals(handler.triggerNewMap, handler.executedTriggerNewMap);
        System.assertEquals(null, handler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_after_update_method() {
        List<SObject> records = [SELECT Id, TransactionId__c FROM Log__c];
        MockLogHandler handler = new MockLogHandler();
        handler.triggerOperationType = TriggerOperation.AFTER_UPDATE;
        handler.triggerNew = null;
        handler.triggerNewMap = new Map<Id, SObject>(records);
        handler.triggerOldMap = new Map<Id, SObject>(records);

        handler.execute();

        System.assertEquals(1, handler.executionCount);
        System.assertEquals(TriggerOperation.AFTER_UPDATE, handler.executedTriggerOperationType);
        System.assertEquals(null, handler.executedTriggerNew);
        System.assertEquals(handler.triggerNewMap, handler.executedTriggerNewMap);
        System.assertEquals(handler.triggerOldMap, handler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_after_delete_method() {
        MockLogHandler handler = new MockLogHandler();
        handler.triggerOperationType = TriggerOperation.AFTER_DELETE;
        handler.triggerNew = null;
        handler.triggerNewMap = new Map<Id, SObject>([SELECT Id, TransactionId__c FROM Log__c]);
        handler.triggerOldMap = null;

        handler.execute();

        System.assertEquals(1, handler.executionCount);
        System.assertEquals(TriggerOperation.AFTER_DELETE, handler.executedTriggerOperationType);
        System.assertEquals(null, handler.executedTriggerNew);
        System.assertEquals(handler.triggerNewMap, handler.executedTriggerNewMap);
        System.assertEquals(null, handler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_run_after_undelete_method() {
        MockLogHandler handler = new MockLogHandler();
        handler.triggerOperationType = TriggerOperation.AFTER_UNDELETE;
        handler.triggerNew = null;
        handler.triggerNewMap = new Map<Id, SObject>([SELECT Id, TransactionId__c FROM Log__c]);
        handler.triggerOldMap = null;

        handler.execute();

        System.assertEquals(1, handler.executionCount);
        System.assertEquals(TriggerOperation.AFTER_UNDELETE, handler.executedTriggerOperationType);
        System.assertEquals(null, handler.executedTriggerNew);
        System.assertEquals(handler.triggerNewMap, handler.executedTriggerNewMap);
        System.assertEquals(null, handler.executedTriggerOldMap);
    }

    @IsTest
    static void it_should_gracefully_skip_non_existent_apex_plugin() {
        MockLogHandler handler = new MockLogHandler();
        handler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        handler.triggerNew = new List<Log__c>{ new Log__c(TransactionId__c = '1234') };
        handler.triggerNewMap = null;
        handler.triggerOldMap = null;
        LoggerPlugin__mdt plugin = new LoggerPlugin__mdt(
            IsEnabled__c = true,
            IsLogEnabled__c = true,
            PluginApiName__c = 'Some_Fake_Apex_Class',
            PluginType__c = 'SObject Handler - Apex'
        );
        handler.addMockPlugin(plugin);

        handler.execute();

        System.assertEquals(1, handler.getPluginConfigurations().size());
        System.assertEquals(0, handler.getExecutedApexPlugins().size());
    }

    @IsTest
    static void it_should_gracefully_skip_non_existent_flow_plugin() {
        MockLogHandler handler = new MockLogHandler();
        handler.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        handler.triggerNew = new List<Log__c>{ new Log__c(TransactionId__c = '1234') };
        handler.triggerNewMap = null;
        handler.triggerOldMap = null;
        LoggerPlugin__mdt plugin = new LoggerPlugin__mdt(
            IsEnabled__c = true,
            IsLogEnabled__c = true,
            PluginApiName__c = 'Some_Fake_Flow',
            PluginType__c = 'SObject Handler - Flow'
        );
        handler.addMockPlugin(plugin);

        handler.execute();

        System.assertEquals(1, handler.getPluginConfigurations().size());
        System.assertEquals(0, handler.getExecutedApexPlugins().size());
    }

    public class MockLogHandler extends LoggerSObjectHandler {
        public Integer executionCount = 0;
        public TriggerOperation executedTriggerOperationType;
        public List<SObject> executedTriggerNew;
        public Map<Id, SObject> executedTriggerNewMap;
        public Map<Id, SObject> executedTriggerOldMap;

        public override SObjectType getSObjectType() {
            return Schema.Log__c.SObjectType;
        }

        public override String getHandlerControlParameterName() {
            return HANDLER_CONTROL_PARAMETER_NAME;
        }

        public override Schema.SObjectField getHandlerPluginControlField() {
            return Schema.LoggerPlugin__mdt.IsLogEnabled__c;
        }

        public override Schema.SObjectField getHandlerPluginSortField() {
            return Schema.LoggerPlugin__mdt.LogExecutionOrder__c;
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
}
