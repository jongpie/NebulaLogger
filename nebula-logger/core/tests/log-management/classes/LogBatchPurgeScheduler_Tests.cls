//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=false)
private class LogBatchPurgeScheduler_Tests {
    private static final String TEST_CRON_EXPRESSION = '0 0 23 * * ?';

    @IsTest
    static void it_should_use_specified_batch_size_when_specified_batch_size_is_not_null() {
        Integer batchSize = 123;

        LogBatchPurgeScheduler scheduler = new LogBatchPurgeScheduler(batchSize);
        scheduler.execute(null);

        System.assertEquals(batchSize, scheduler.batchSize);
    }

    @IsTest
    static void it_should_use_default_batch_size_when_specified_batch_size_is_null() {
        Integer batchSize = null;

        LogBatchPurgeScheduler scheduler = new LogBatchPurgeScheduler(batchSize);
        scheduler.execute(null);

        System.assertEquals(LogBatchPurgeScheduler.DEFAULT_BATCH_SIZE, scheduler.batchSize);
    }

    @IsTest
    static void it_should_schedule_job() {
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'EnableLoggerSystemMessages', Value__c = 'false'));

        System.Test.startTest();
        Id jobId = System.schedule('Test schedule of LogBatchPurgeScheduler', TEST_CRON_EXPRESSION, new LogBatchPurgeScheduler());
        System.Test.stopTest();

        CronTrigger cronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        List<LogEntry__c> logEntries = [SELECT Id, Message__c FROM LogEntry__c];
        System.assertEquals(TEST_CRON_EXPRESSION, cronTrigger.CronExpression);
        System.assertEquals(0, cronTrigger.TimesTriggered);
        System.assertEquals(0, logEntries.size());
    }

    @IsTest
    static void it_should_create_system_log_entry_when_enabled() {
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'EnableLoggerSystemMessages', Value__c = 'true'));

        System.Test.startTest();
        Id jobId = System.schedule('Test schedule of LogBatchPurgeScheduler', TEST_CRON_EXPRESSION, new LogBatchPurgeScheduler());
        System.Test.stopTest();

        CronTrigger cronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        List<LogEntry__c> logEntries = [SELECT Id, Message__c FROM LogEntry__c];
        System.assertEquals(TEST_CRON_EXPRESSION, cronTrigger.CronExpression);
        System.assertEquals(0, cronTrigger.TimesTriggered);
        System.assertEquals(1, logEntries.size());
    }
}
