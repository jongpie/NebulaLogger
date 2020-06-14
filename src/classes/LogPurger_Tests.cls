/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
@isTest
private class LogPurger_Tests {

    @testSetup
    static void setupData() {
        Log__c log = new Log__c();
        new TestDataFactory(log).populateRequiredFields();
        insert log;
        Test.setCreatedDate(log.Id, System.now().addDays(-8));

        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        for(Integer i = 0; i < 10; i++) {
            LogEntry__c logEntry = new LogEntry__c();
            logEntry.Log__c = log.Id;
            new TestDataFactory(log).populateRequiredFields();

            logEntries.add(logEntry);
        }
        insert logEntries;
    }

    @isTest
    static void it_should_delete_logs_and_log_entries() {
        List<Log__c> logs = [SELECT Id FROM Log__c];
        List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c];
        System.assertNotEquals(0, logs.size());
        System.assertNotEquals(0, logEntries.size());

        Test.startTest();
        Database.executeBatch(new LogPurger(7));
        Test.stopTest();

        logs = [SELECT Id FROM Log__c];
        logEntries = [SELECT Id FROM LogEntry__c];
        System.assertEquals(0, logs.size());
        System.assertEquals(0, logEntries.size());
    }

}