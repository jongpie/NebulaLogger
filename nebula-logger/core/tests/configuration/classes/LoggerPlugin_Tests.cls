//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LoggerPlugin_Tests {
    private static final String PLUGIN_LOG_STATUS = 'On Hold';

    @IsTest
    static void it_should_returned_filtered_plugin_configurations_in_sorted_order() {
        // The mock LoggerPlugin__mdt records are purposeful being added to LoggerPlugin.setMock()
        // in an order that's different from the order when sorting on SObjectHandlerExecutionOrder__c.
        // This helps ensure that the returned results are truly being sorted, instead of just being returned
        // in the same order that they're added via LoggerPlugin.setMock()
        LoggerPlugin__mdt secondPluginConfiguration = createMockPluginConfiguration('secondPluginConfiguration');
        secondPluginConfiguration.SObjectHandlerApexClass__c = 'Also_A_Fake_Apex_Class';
        secondPluginConfiguration.SObjectHandlerExecutionOrder__c = 2;
        LoggerPlugin.setMock(secondPluginConfiguration);
        LoggerPlugin__mdt fifthPluginConfiguration = createMockPluginConfiguration('zzzzz_sort_me_last_alphabetically_fifthPluginConfiguration');
        fifthPluginConfiguration.SObjectHandlerApexClass__c = 'Yeah_This_Is_A_Fake_Apex_Class';
        fifthPluginConfiguration.SObjectHandlerExecutionOrder__c = null;
        LoggerPlugin.setMock(fifthPluginConfiguration);
        LoggerPlugin__mdt fourthPluginConfiguration = createMockPluginConfiguration('fourthPluginConfiguration');
        fourthPluginConfiguration.SObjectHandlerApexClass__c = 'Yeah_This_Is_A_Fake_Apex_Class';
        fourthPluginConfiguration.SObjectHandlerExecutionOrder__c = null;
        LoggerPlugin.setMock(fourthPluginConfiguration);
        LoggerPlugin__mdt thirdPluginConfiguration = createMockPluginConfiguration('thirdPluginConfiguration');
        thirdPluginConfiguration.SObjectHandlerApexClass__c = 'Yeah_This_Is_A_Fake_Apex_Class';
        thirdPluginConfiguration.SObjectHandlerExecutionOrder__c = 3;
        LoggerPlugin.setMock(thirdPluginConfiguration);
        LoggerPlugin__mdt firstPluginConfiguration = createMockPluginConfiguration('firstPluginConfiguration');
        firstPluginConfiguration.SObjectHandlerApexClass__c = 'Some_Fake_Apex_Class';
        firstPluginConfiguration.SObjectHandlerExecutionOrder__c = 1;
        LoggerPlugin.setMock(firstPluginConfiguration);
        List<LoggerPlugin__mdt> expectedSortedPluginConfigurations = new List<LoggerPlugin__mdt>{
            firstPluginConfiguration,
            secondPluginConfiguration,
            thirdPluginConfiguration,
            fourthPluginConfiguration,
            fifthPluginConfiguration
        };
        LoggerPlugin__mdt disabledPluginConfiguration = createMockPluginConfiguration('disabledPluginConfiguration');
        secondPluginConfiguration.IsEnabled__c = false;
        secondPluginConfiguration.SObjectHandlerApexClass__c = 'Also_A_Fake_Apex_Class';
        secondPluginConfiguration.SObjectHandlerExecutionOrder__c = 2;
        LoggerPlugin.setMock(disabledPluginConfiguration);
        LoggerPlugin__mdt nonMatchingPluginConfiguration = createMockPluginConfiguration('nonMatchingPluginConfiguration');
        nonMatchingPluginConfiguration.SObjectHandlerApexClass__c = null;
        nonMatchingPluginConfiguration.SObjectHandlerExecutionOrder__c = 1;
        LoggerPlugin.setMock(nonMatchingPluginConfiguration);

        List<LoggerPlugin__mdt> returnedPluginConfigurations = LoggerPlugin.getFilteredPluginConfigurations(
            new List<Schema.SObjectField>{ Schema.LoggerPlugin__mdt.SObjectHandlerApexClass__c },
            Schema.LoggerPlugin__mdt.SObjectHandlerExecutionOrder__c
        );

        System.assertEquals(expectedSortedPluginConfigurations.size(), returnedPluginConfigurations.size());
        for (Integer i = 0; i < returnedPluginConfigurations.size(); i++) {
            LoggerPlugin__mdt expectedSortedPluginConfiguration = expectedSortedPluginConfigurations.get(i);
            LoggerPlugin__mdt returnedPluginConfiguration = returnedPluginConfigurations.get(i);
            System.assertEquals(expectedSortedPluginConfiguration, returnedPluginConfiguration, 'Records at index ' + i + ' don\'t match');
        }
    }

    @IsTest
    static void it_should_return_batchable_apex_plugin_instance_for_valid_class() {
        LoggerPlugin.Batchable batchableApexPlugin = LoggerPlugin.newBatchableInstance(ExampleBatchPurgerPlugin.class.getName());

        System.assertNotEquals(null, batchableApexPlugin, ExampleBatchPurgerPlugin.class.getName());
        System.assertEquals(true, batchableApexPlugin instanceof ExampleBatchPurgerPlugin);
    }

    @IsTest
    static void it_should_return_null_batchable_apex_plugin_instance_for_invalid_class() {
        LoggerPlugin.Batchable batchableApexPlugin = LoggerPlugin.newBatchableInstance('Some fake class, this definitely doesn\'t exist');

        System.assertEquals(null, batchableApexPlugin);
    }

    @IsTest
    static void it_should_return_triggerable_apex_plugin_instance_for_valid_class() {
        LoggerPlugin.Triggerable triggerableApexPlugin = LoggerPlugin.newTriggerableInstance(ExampleTriggerablePlugin.class.getName());

        System.assertNotEquals(null, triggerableApexPlugin, ExampleTriggerablePlugin.class.getName());
        System.assertEquals(true, triggerableApexPlugin instanceof ExampleTriggerablePlugin);
    }

    @IsTest
    static void it_should_return_null_triggerable_apex_plugin_instance_for_invalid_class() {
        LoggerPlugin.Triggerable triggerableApexPlugin = LoggerPlugin.newTriggerableInstance('Some fake class, this definitely doesn\'t exist');

        System.assertEquals(null, triggerableApexPlugin);
    }

    private static LoggerPlugin__mdt createMockPluginConfiguration(String developerName) {
        return new LoggerPlugin__mdt(DeveloperName = developerName, IsEnabled__c = true);
    }

    @SuppressWarnings('PMD.ApexDoc, PMD.EmptyStatementBlock')
    public class ExampleBatchPurgerPlugin implements LoggerPlugin.Batchable {
        public void start(LoggerPlugin__mdt configuration, LoggerBatchableContext input) {
        }
        public void execute(LoggerPlugin__mdt configuration, LoggerBatchableContext input, List<SObject> scope) {
        }
        public void finish(LoggerPlugin__mdt configuration, LoggerBatchableContext input) {
        }
    }

    @SuppressWarnings('PMD.ApexDoc, PMD.EmptyStatementBlock')
    public class ExampleTriggerablePlugin implements LoggerPlugin.Triggerable {
        public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input) {
            switch on input.triggerOperationType {
                when BEFORE_INSERT {
                    for (Log__c log : (List<Log__c>) input.triggerNew) {
                        log.Status__c = PLUGIN_LOG_STATUS;
                    }
                }
            }
        }
    }
}
