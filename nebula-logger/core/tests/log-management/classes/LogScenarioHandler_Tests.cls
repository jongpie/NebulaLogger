//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LogScenarioHandler_Tests {
    @IsTest
    static void it_should_return_the_logScenario_sobjectType() {
        System.assertEquals(Schema.LogScenario__c.SObjectType, new LogScenarioHandler().getSObjectType());
    }

    @IsTest
    static void it_should_not_run_when_disabled_via_configuration() {
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogScenario__c.SObjectType).IsEnabled__c = false;
        LogScenario__c logScenario = (LogScenario__c) LoggerMockDataCreator.createDataBuilder(Schema.LogScenario__c.SObjectType)
            .populateRequiredFields()
            .getRecord();

        LoggerDataStore.getDatabase().insertRecord(logScenario);

        System.assertEquals(
            0,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogScenario__c.SObjectType).size(),
            'Handler class should not have executed'
        );
    }

    @IsTest
    static void it_should_run_when_enabled_via_configuration() {
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogScenario__c.SObjectType).IsEnabled__c = true;
        LogScenario__c logScenario = (LogScenario__c) LoggerMockDataCreator.createDataBuilder(Schema.LogScenario__c.SObjectType)
            .populateRequiredFields()
            .getRecord();

        LoggerDataStore.getDatabase().insertRecord(logScenario);

        System.assertEquals(
            2,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogScenario__c.SObjectType).size(),
            'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
        );
    }

    @IsTest
    static void it_should_not_allow_duplicate_scenario_to_be_inserted() {
        LogScenario__c logScenario = (LogScenario__c) LoggerMockDataCreator.createDataBuilder(Schema.LogScenario__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        logScenario.Name = 'Some log scenario name';
        LoggerDataStore.getDatabase().insertRecord(logScenario);
        LogScenario__c duplicateScenario = (LogScenario__c) LoggerMockDataCreator.createDataBuilder(new LogScenario__c(Name = logScenario.Name))
            .populateRequiredFields()
            .getRecord();
        Exception thrownException;

        try {
            insert duplicateScenario;
            System.assert(false, 'Exception expected on previous line');
        } catch (Exception ex) {
            thrownException = ex;
        }

        System.assertEquals(
            3,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogScenario__c.SObjectType).size(),
            'Handler class should have executed three times - once for BEFORE_INSERT and once for AFTER_INSERT for the first record,' +
            ' and once for BEFORE_INSERT on the errored duplicate'
        );
        System.assertNotEquals(null, thrownException, 'An exception should have been thrown');
        String expectedDuplicateError = 'DUPLICATE_VALUE';
        System.assert(thrownException.getMessage().contains(expectedDuplicateError), thrownException.getMessage());
    }
}
