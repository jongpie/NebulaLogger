//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class LoggerPlugin_Tests {
    private static final String PLUGIN_LOG_STATUS = 'On Hold';

    public class ExampleBatchablePlugin implements LoggerPlugin.Batchable {
        public void start(LoggerPlugin__mdt configuration, LogBatchPurger.BatchPurgerInput input) {
        }
        public void execute(LoggerPlugin__mdt configuration, LogBatchPurger.BatchPurgerInput input, List<SObject> scope) {
        }
        public void finish(LoggerPlugin__mdt configuration, LogBatchPurger.BatchPurgerInput input) {
        }
    }

    public class ExampleTriggerablePlugin implements LoggerPlugin.Triggerable {
        public void execute(LoggerPlugin__mdt configuration, LoggerSObjectHandler.SObjectHandlerInput input) {
            switch on input.triggerOperationType {
                when BEFORE_INSERT {
                    for (Log__c log : (List<Log__c>) input.triggerNew) {
                        log.Status__c = PLUGIN_LOG_STATUS;
                    }
                }
            }
        }
    }

    @IsTest
    static void it_should_return_batch_purger_apex_plugin_instance_for_valid_class() {
        LoggerPlugin.Batchable batchPurgerApexPlugin = LoggerPlugin.newBatchableInstance(
            new LoggerPlugin__mdt(IsEnabled__c = true, BatchPurgerApexClass__c = ExampleBatchablePlugin.class.getName())
        );
        System.assertNotEquals(null, batchPurgerApexPlugin);
        System.assertEquals(true, batchPurgerApexPlugin instanceof ExampleBatchablePlugin);
    }

    @IsTest
    static void it_should_return_null_batch_purger_apex_plugin_instance_for_invalid_class() {
        LoggerPlugin.Batchable batchPurgerApexPlugin = LoggerPlugin.newBatchableInstance(
            new LoggerPlugin__mdt(IsEnabled__c = true, BatchPurgerApexClass__c = 'Some fake class, this definitely doesn\'t exist')
        );
        System.assertEquals(null, batchPurgerApexPlugin);
    }

    @IsTest
    static void it_should_return_sobject_handler_apex_plugin_instance_for_valid_class() {
        LoggerPlugin.Triggerable sobjectHandlerApexPlugin = LoggerPlugin.newTriggerableInstance(
            new LoggerPlugin__mdt(IsEnabled__c = true, SObjectHandlerApexClass__c = ExampleTriggerablePlugin.class.getName())
        );
        System.assertNotEquals(null, sobjectHandlerApexPlugin);
        System.assertEquals(true, sobjectHandlerApexPlugin instanceof ExampleTriggerablePlugin);
    }

    @IsTest
    static void it_should_return_null_sobject_handler_apex_plugin_instance_for_invalid_class() {
        LoggerPlugin.Triggerable sobjectHandlerApexPlugin = LoggerPlugin.newTriggerableInstance(
            new LoggerPlugin__mdt(IsEnabled__c = true, SObjectHandlerApexClass__c = 'Some fake class, this definitely doesn\'t exist')
        );
        System.assertEquals(null, sobjectHandlerApexPlugin);
    }

    @IsTest
    static void todo_test_getBatchPurgerPluginConfigurations() {
        System.assert(false, 'TODO Determine testing approach for queries on CMDT');
    }

    @IsTest
    static void todo_test_getSObjectHandlerPluginConfigurations() {
        System.assert(false, 'TODO Determine testing approach for queries on CMDT');
    }
}
