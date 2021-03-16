//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
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
    static void it_should_populate_related_record_fields_on_log_entry_with_related_user_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        User currentUser = [SELECT Id, Username FROM User WHERE Id = :UserInfo.getUserId()];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = currentUser.Id);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(currentUser.Id, logEntry.RecordId__c);
        System.assertEquals(currentUser.Username, logEntry.RecordName__c);
    }

    @isTest
    static void it_should_populate_related_record_fields_on_log_entry_with_related_profile_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        Profile currentProfile = [SELECT Id, Name, Description FROM Profile WHERE Id = :UserInfo.getProfileId()];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = currentProfile.Id);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(currentProfile.Id, logEntry.RecordId__c);
        System.assertEquals(currentProfile.Name, logEntry.RecordName__c);
    }

    @isTest
    static void it_should_set_hasRecordJson_to_true_when_populated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        String recordJson = '{}';
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordJson__c = recordJson);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, HasRecordJson__c, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasRecordJson__c);
        System.assertEquals(recordJson, logEntry.RecordJson__c);
    }

    @isTest
    static void it_should_set_hasRecordJson_to_true_when_updated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordJson__c = null);
        insert logEntry;
        logEntry = [SELECT Id, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(null, logEntry.RecordJson__c);

        Test.startTest();

        String recordJson = '{}';
        logEntry.RecordJson__c = recordJson;
        update logEntry;

        Test.stopTest();

        logEntry = [SELECT Id, HasRecordJson__c, RecordJson__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasRecordJson__c);
        System.assertEquals(recordJson, logEntry.RecordJson__c);
    }

    @isTest
    static void it_should_set_hasExceptionStackTrace_to_false_when_null() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, ExceptionStackTrace__c = null);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, HasExceptionStackTrace__c, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(!logEntry.HasExceptionStackTrace__c);
        System.assertEquals(null, logEntry.ExceptionStackTrace__c);
    }

    @isTest
    static void it_should_set_hasExceptionStackTrace_to_true_when_populated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        String stackTrace = 'something';
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, ExceptionStackTrace__c = stackTrace);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, HasExceptionStackTrace__c, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasExceptionStackTrace__c);
        System.assertEquals(stackTrace, logEntry.ExceptionStackTrace__c);
    }

    @isTest
    static void it_should_set_hasExceptionStackTrace_to_true_when_updated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, ExceptionStackTrace__c = null);
        insert logEntry;
        logEntry = [SELECT Id, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(null, logEntry.ExceptionStackTrace__c);

        Test.startTest();

        String stackTrace = 'something';
        logEntry.ExceptionStackTrace__c = stackTrace;
        update logEntry;

        Test.stopTest();

        logEntry = [SELECT Id, HasExceptionStackTrace__c, ExceptionStackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasExceptionStackTrace__c);
        System.assertEquals(stackTrace, logEntry.ExceptionStackTrace__c);
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
    static void it_should_set_hasStackTrace_to_true_when_updated() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, StackTrace__c = null);
        insert logEntry;
        logEntry = [SELECT Id, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(null, logEntry.StackTrace__c);

        Test.startTest();

        String stackTrace = 'something';
        logEntry.StackTrace__c = stackTrace;
        update logEntry;

        Test.stopTest();

        logEntry = [SELECT Id, HasStackTrace__c, StackTrace__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assert(logEntry.HasStackTrace__c);
        System.assertEquals(stackTrace, logEntry.StackTrace__c);
    }
}
