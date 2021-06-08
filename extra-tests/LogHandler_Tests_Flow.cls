//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@isTest
private class LogHandler_Tests_Flow {
    private static LoggerSObjectHandlerConfiguration__mdt getMockConfiguration() {
        // Mocking entity deefinition fields on CMDT is not properly supported, so here's some goofy workarounds for mocking an instance
        EntityDefinition logEntityDefinition = [SELECT QualifiedApiName, DeveloperName FROM EntityDefinition WHERE QualifiedApiName = :LogEntry__c.getSObjectType().getDescribe().getName()];
        LoggerSObjectHandlerConfiguration__mdt configuration =  new LoggerSObjectHandlerConfiguration__mdt();
        configuration.IsEnabled__c = true;

        Map<String, Object> configurationUntyped = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(configuration));
        configurationUntyped.put('LoggerSObject__r', logEntityDefinition);

        return (LoggerSObjectHandlerConfiguration__mdt) JSON.deserialize(JSON.serialize(configurationUntyped), LoggerSObjectHandlerConfiguration__mdt.class);
    }

    @isTest
    static void it_should_run_flow_post_processor_when_configured() {
        // Assumption: the Flow LogHandler_Tests_Flow makes an update to the current user's FirstName
        // The specific action within the Flow isn't that important - we just want to make sure...
        // ...that that Flow is dynamically executed
        String postProcessorFlowApiName = 'LogHandler_Tests_Flow';
        String expectedUserFirstName = 'Logger-Flow-Test';

        LoggerSObjectHandlerConfiguration__mdt logHandlerConfiguration = getMockConfiguration();
        logHandlerConfiguration.IsEnabled__c = true;
        logHandlerConfiguration.PostProcessorFlowApiName__c = postProcessorFlowApiName;

        Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt> configurationsBySObjectType = new Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt>{
            Schema.Log__c.SObjectType => logHandlerConfiguration
        };

        Test.startTest();

        // Use the mock configurations
        LoggerSObjectHandler.configurationsBySObjectType = configurationsBySObjectType;

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        Test.stopTest();

        // Assumption: the FLow
        User currentUser = [SELECT Id, FirstName FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertEquals(expectedUserFirstName, currentUser.FirstName);
    }
}
