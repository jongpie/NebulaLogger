/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
@isTest
private class LogBatchPurger_Tests {
    private static final Integer NUMBER_OF_LOG_ENTRIES = 10;

    @testSetup
    static void setupData() {
        insert LoggerSettings__c().getInstance();

        Date scheduledDeletionDate = System.today().addDays(-7);

        Log__c log = new Log__c(LogRetentionDate__c = scheduledDeletionDate, TransactionId__c = '1234');
        insert log;

        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        for (Integer i = 0; i < NUMBER_OF_LOG_ENTRIES; i++) {
            LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id);

            logEntries.add(logEntry);
        }
        insert logEntries;
    }

    @isTest
    static void it_should_delete_a_log_after_scheduled_deletion_date() {
        List<Log__c> logs = [SELECT Id, LogRetentionDate__c FROM Log__c];
        List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c];

        System.assertEquals(1, logs.size());
        System.assertEquals(NUMBER_OF_LOG_ENTRIES, logEntries.size());

        // Verify assumption that the log in the database has a deletion date in the past
        Log__c log = logs.get(0);
        System.assertNotEquals(null, log.LogRetentionDate__c);
        System.assert(log.LogRetentionDate__c < System.today());

        Test.startTest();
        Database.executeBatch(new LogBatchPurger());
        Test.stopTest();

        logs = [SELECT Id FROM Log__c];
        logEntries = [SELECT Id FROM LogEntry__c];
        System.assertEquals(0, logs.size(), logs);
        System.assertEquals(0, logEntries.size(), logEntries);
    }

    @isTest
    static void it_should_not_delete_a_log_before_scheduled_deletion_date() {
        List<Log__c> logs = [SELECT Id, LogRetentionDate__c FROM Log__c];
        List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c];

        System.assertEquals(1, logs.size());
        System.assertEquals(NUMBER_OF_LOG_ENTRIES, logEntries.size());

        // Set the log's deletion date to be in the future
        Log__c log = logs.get(0);
        log.LogRetentionDate__c = System.today().addDays(7);
        update log;
        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.assert(log.LogRetentionDate__c > System.today());

        Test.startTest();
        Database.executeBatch(new LogBatchPurger());
        Test.stopTest();

        logs = [SELECT Id FROM Log__c];
        logEntries = [SELECT Id FROM LogEntry__c];
        System.assertEquals(1, logs.size());
        System.assertEquals(NUMBER_OF_LOG_ENTRIES, logEntries.size());
    }

    @isTest
    static void it_should_not_delete_a_log_without_a_scheduled_deletion_date() {
        List<Log__c> logs = [SELECT Id, LogRetentionDate__c FROM Log__c];
        List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c];

        System.assertEquals(1, logs.size());
        System.assertEquals(NUMBER_OF_LOG_ENTRIES, logEntries.size());

        // Set the log's deletion date to be null
        Log__c log = logs.get(0);
        log.LogRetentionDate__c = null;
        update log;
        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(null, log.LogRetentionDate__c);

        Test.startTest();
        Database.executeBatch(new LogBatchPurger());
        Test.stopTest();

        logs = [SELECT Id FROM Log__c];
        logEntries = [SELECT Id FROM LogEntry__c];
        System.assertEquals(1, logs.size(), logs);
        System.assertEquals(NUMBER_OF_LOG_ENTRIES, logEntries.size(), logEntries);
    }
}
