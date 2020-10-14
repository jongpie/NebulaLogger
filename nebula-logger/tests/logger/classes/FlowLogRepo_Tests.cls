/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
@isTest
private class FlowLogRepo_Tests {

    @isTest
    static void it_should_return_null_if_no_recent_log() {
        System.assertEquals(null, FlowLogRepo.getLogIds());
    }

    @isTest
    static void it_should_return_most_recent_log_in_flow_compatible_list() {
        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c      = true;
        upsert settings;

        Test.startTest();

        Logger.debug('Hi');
        Logger.saveLog();

        Test.stopTest();

        List<Log__c> logs = FlowLogRepo.getLogIds();
        System.assertEquals(1, logs.size());
        System.assertNotEquals(null, logs[0].Id);
    }
}