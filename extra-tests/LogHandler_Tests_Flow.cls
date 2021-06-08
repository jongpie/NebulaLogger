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
        String expectedLoginApplication = 'Some Fake Application';

        LoggerSObjectHandlerConfiguration__mdt logHandlerConfiguration = getMockConfiguration();
        logHandlerConfiguration.PostProcessorFlowApiName__c = 'LogHandler_Tests_Flow';

        Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt> configurationsBySObjectType = new Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt>{
            Schema.LogEntry__c.SObjectType => logHandlerConfiguration
        };

        Test.startTest();

        // Use the mock configurations
        LoggerSObjectHandler.configurationsBySObjectType = configurationsBySObjectType;

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        // TODO
        // log = [SELECT Id, LoginApplication__c FROM Log__c WHERE Id = :log.Id];
        // System.assertEquals(expectedLoginApplication, log.LoginApplication__c);

        Test.stopTest();
    }
}
