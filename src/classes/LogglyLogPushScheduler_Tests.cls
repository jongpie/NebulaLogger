/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
@isTest
private class LogglyLogPushScheduler_Tests {

    @testSetup
    static void testSetup() {
        for(CronTrigger ct : [SELECT Id FROM CronTrigger]) {
            System.abortJob(ct.Id);
        }
    }

    @isTest
    static void it_should_schedule_the_batch_job() {
        String cronExpression = '0 0 0 15 3 ? 2022';
        Integer numberOfScheduledJobs = [SELECT COUNT() FROM CronTrigger];
        System.assertEquals(0, numberOfScheduledJobs);

        Test.startTest();
        Id jobId = System.schedule('LogglyLogPushScheduler', cronExpression, new LogglyLogPushScheduler());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExpression, ct.CronExpression);
    }

    @isTest
    static void it_should_schedule_the_batch_job_schedule_every_5_minutes() {
        List<String> cronExpressionsForEvery5Minutes = new List<String>{
            '0 0 * * * ?',
            '0 5 * * * ?',
            '0 10 * * * ?',
            '0 15 * * * ?',
            '0 20 * * * ?',
            '0 25 * * * ?',
            '0 30 * * * ?',
            '0 35 * * * ?',
            '0 40 * * * ?',
            '0 45 * * * ?',
            '0 50 * * * ?',
            '0 55 * * * ?'
        };

        Integer numberOfScheduledJobs = [SELECT COUNT() FROM CronTrigger];
        System.assertEquals(0, numberOfScheduledJobs);

        Test.startTest();
        List<Id> jobIds = LogglyLogPushScheduler.scheduleEveryXMinutes(5);
        Test.stopTest();

        List<CronTrigger> cts = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id IN :jobIds];
        System.assertEquals(cronExpressionsForEvery5Minutes.size(), cts.size());
        for(CronTrigger ct : cts) {
            System.assert(cronExpressionsForEvery5Minutes.contains(ct.cronExpression), ct.CronExpression);
        }
    }

    @isTest
    static void it_should_schedule_the_batch_job_schedule_hourly() {
        Integer startingMinuteInHour = 0;
        String expectedCronExpression = '0 ' + startingMinuteInHour + ' * * * ?';

        Integer numberOfScheduledJobs = [SELECT COUNT() FROM CronTrigger];
        System.assertEquals(0, numberOfScheduledJobs);

        Test.startTest();
        Id jobId = LogglyLogPushScheduler.scheduleHourly(0);
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(expectedCronExpression, ct.CronExpression);
    }

}