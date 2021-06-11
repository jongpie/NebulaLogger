//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@isTest
private class LogHandler_Tests_Flow {
    @isTest
    static void it_should_run_flow_post_processor_when_configured() {
        // Assumption: the Flow LogHandler_Tests_Flow makes an update to the current user's FirstName
        // The specific action within the Flow isn't that important - we just want to make sure...
        // ...that that Flow is dynamically executed
        String pluginFlowApiName = 'LogHandler_Tests_Flow';
        String expectedUserFirstName = 'Logger-Flow-Test';
        System.assertNotEquals(expectedUserFirstName, UserInfo.getFirstName());

        LoggerSObjectHandlerPlugin__mdt plugin = new LoggerSObjectHandlerPlugin__mdt(
             PluginType__c = 'Flow',
            PluginApiName__c = pluginFlowApiName
        );
        Map<SObjectType, List<LoggerSObjectHandlerPlugin__mdt>> pluginsBySObjectType = new Map<SObjectType, List<LoggerSObjectHandlerPlugin__mdt>>{
            Schema.Log__c.SObjectType => new List<LoggerSObjectHandlerPlugin__mdt>{ plugin }
        };

        Test.startTest();

        // Use the mock configurations
        LoggerSObjectHandler.pluginsBySObjectType = pluginsBySObjectType;

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        Test.stopTest();

        // Verify that the Flow ran by checking if the user's FirstName was updated
        User currentUser = [SELECT Id, FirstName FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertEquals(expectedUserFirstName, currentUser.FirstName);
    }
}
