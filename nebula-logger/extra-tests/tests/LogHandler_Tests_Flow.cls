//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class LogHandler_Tests_Flow {
    @IsTest
    static void runFlowPluginWhenConfigured() {
        // Assumption: the Flow LogHandler_Tests_Flow makes an update to the current user's FirstName
        // The specific action within the Flow isn't that important - we just want to make sure
        // that that Flow is dynamically executed
        String pluginFlowApiName = 'LogHandler_Tests_Flow';
        String expectedUserFirstName = 'Logger-Flow-Test';
        System.assertNotEquals(expectedUserFirstName, UserInfo.getFirstName(), 'Current user first name did not match expected user first name.');

        Test.startTest();

        // Use the mock configurations
        LoggerPlugin__mdt plugin = new LoggerPlugin__mdt(PluginType__c = 'SObject Handler - Flow', PluginApiName__c = pluginFlowApiName);
        LoggerSObjectHandler.setMockPlugin(Schema.Log__c.SObjectType, plugin);

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        Test.stopTest();

        // Verify that the Flow ran by checking if the user's FirstName was updated
        User currentUser = [SELECT Id, FirstName FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertEquals(expectedUserFirstName, currentUser.FirstName, 'Current user FirstName did not match expected user first name.');
    }
}
