/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
@isTest
private class TrelloLogPushScheduler_Tests {

    @isTest
    static void it_should_schedule_the_batch_job() {
        String cronExpression = '0 0 0 15 3 ? 2022';
        Integer numberOfScheduledJobs = [SELECT COUNT() FROM CronTrigger];
        System.assertEquals(0, numberOfScheduledJobs);

        Test.startTest();
        String jobId = System.schedule('TrelloLogPushScheduler', cronExpression, new TrelloLogPushScheduler());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExpression, ct.CronExpression);
    }

    @isTest
    static void it_should_schedule_the_batch_job_schedule_every_5_minutes() {
        Integer numberOfScheduledJobs = [SELECT COUNT() FROM CronTrigger];
        System.assertEquals(0, numberOfScheduledJobs);

        Test.startTest();
        TrelloLogPushScheduler.scheduleEveryXMinutes(5);
        Test.stopTest();
    }

    @isTest
    static void it_should_schedule_the_batch_job_schedule_hourly() {
        Integer numberOfScheduledJobs = [SELECT COUNT() FROM CronTrigger];
        System.assertEquals(0, numberOfScheduledJobs);

        Test.startTest();
        TrelloLogPushScheduler.scheduleHourly(0);
        Test.stopTest();
    }

}