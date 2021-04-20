//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class LogBatchPurgeScheduler_Tests {
    private static final String TEST_CRON_EXPRESSION = '0 0 23 * * ?';

    @isTest
    static void it_should_schedule_job() {
        Test.startTest();

        Id jobId = System.schedule('Test schedule of LogBatchPurgeScheduler', TEST_CRON_EXPRESSION, new LogBatchPurgeScheduler());

        Test.stopTest();

        CronTrigger cronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(TEST_CRON_EXPRESSION, cronTrigger.CronExpression);
        System.assertEquals(0, cronTrigger.TimesTriggered);
    }
}
