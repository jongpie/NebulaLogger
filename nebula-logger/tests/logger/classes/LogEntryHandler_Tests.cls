/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
@isTest
private class LogEntryHandler_Tests {
    @testSetup
    static void setupData() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        Test.setCreatedDate(log.Id, System.now().addDays(-8));
    }

    @isTest
    static void it_should_save_log_entry_without_related_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = null);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, RecordId__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(null, logEntry.RecordId__c);
    }

    @isTest
    static void it_should_populate_related_fields_on_log_entry_with_related_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        User currentUser = [SELECT Id, Username FROM User WHERE Id = :UserInfo.getUserId()];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = currentUser.Id);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [
            SELECT Id, RecordId__c, RecordName__c, RecordSObjectType__c
            FROM LogEntry__c
            WHERE Id = :logEntry.Id
        ];
        System.assertEquals(currentUser.Id, logEntry.RecordId__c);
        System.assertEquals(currentUser.Username, logEntry.RecordName__c);
        System.assertEquals('User', logEntry.RecordSObjectType__c);
    }

    @isTest
    static void it_should_set_hasStackTrace_to_true_when_populated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        String stackTrace = 'something';
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, StackTrace__c = stackTrace);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, HasStackTrace__c, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasStackTrace__c);
        System.assertEquals(stackTrace, logEntry.StackTrace__c);
    }

    @isTest
    static void it_should_set_hasStackTrace_to_false_when_null() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, StackTrace__c = null);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, HasStackTrace__c, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(!logEntry.HasStackTrace__c);
        System.assertEquals(null, logEntry.StackTrace__c);
    }
}
