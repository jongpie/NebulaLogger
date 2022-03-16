//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@IsTest
private class LoggerSObjectHandler_Tests {
    private class MockLogHandler extends LoggerSObjectHandler {
        public override SObjectType getSObjectType() {
            return Schema.Log__c.SObjectType;
        }

        public override String getHandlerControlParameterName() {
            return 'IsLogHandlerEnabled';
        }

        public override Schema.SObjectField getHandlerPluginControlField() {
            return Schema.LoggerPlugin__mdt.IsLogEnabled__c;
        }

        public override Schema.SObjectField getHandlerPluginSortField() {
            return Schema.LoggerPlugin__mdt.LogExecutionOrder__c;
        }
    }

    @IsTest
    static void it_should_gracefully_skip_non_existent_apex_plugin() {
        LoggerSObjectHandler.SObjectHandlerInput input = new LoggerSObjectHandler.SObjectHandlerInput();
        input.sobjectType = Schema.Log__c.SObjectType;
        input.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        input.triggerNew = new List<Log__c>{ new Log__c(TransactionId__c = '1234') };

        LoggerPlugin__mdt plugin = new LoggerPlugin__mdt(
            IsEnabled__c = true,
            IsLogEnabled__c = true,
            PluginApiName__c = 'Some_Fake_Apex_Class',
            PluginType__c = 'Apex'
        );

        LoggerSObjectHandler mockLogHandler = new MockLogHandler();
        mockLogHandler.setMockInput(input);
        mockLogHandler.addMockPlugin(plugin);
        mockLogHandler.execute();

        System.assertEquals(0, mockLogHandler.getExecutedApexPlugins().size());
    }

    @IsTest
    static void it_should_gracefully_skip_non_existent_flow_plugin() {
        LoggerSObjectHandler.SObjectHandlerInput input = new LoggerSObjectHandler.SObjectHandlerInput();
        input.sobjectType = Schema.Log__c.SObjectType;
        input.triggerOperationType = TriggerOperation.BEFORE_INSERT;
        input.triggerNew = new List<Log__c>{ new Log__c(TransactionId__c = '1234') };

        LoggerPlugin__mdt plugin = new LoggerPlugin__mdt(
            IsEnabled__c = true,
            IsLogEnabled__c = true,
            PluginApiName__c = 'Some_Fake_Flow',
            PluginType__c = 'Flow'
        );

        LoggerSObjectHandler mockLogHandler = new MockLogHandler();
        mockLogHandler.setMockInput(input);
        mockLogHandler.addMockPlugin(plugin);
        mockLogHandler.execute();
    }
}
