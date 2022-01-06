//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class LoggerSObjectHandlerPlugin_Tests {
    private static final String PLUGIN_LOG_STATUS = 'On Hold';

    public class ExamplePlugin extends LoggerSObjectHandlerPlugin {
        public override void execute(
            TriggerOperation triggerOperationType,
            List<SObject> triggerNew,
            Map<Id, SObject> triggerNewMap,
            List<SObject> triggerOld,
            Map<Id, SObject> triggerOldMap
        ) {
            switch on triggerOperationType {
                when BEFORE_INSERT {
                    for (Log__c log : (List<Log__c>) triggerNew) {
                        log.Status__c = PLUGIN_LOG_STATUS;
                    }
                }
            }
        }
    }

    @IsTest
    static void it_should_execute_plugin_logic() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        System.assertEquals(null, log.Status__c);

        Test.startTest();

        ExamplePlugin plugin = new ExamplePlugin();
        plugin.execute(triggerOperation.BEFORE_INSERT, new List<Log__c>{ log }, null, null, null);

        Test.stopTest();

        System.assertEquals(PLUGIN_LOG_STATUS, log.Status__c);
    }
}
