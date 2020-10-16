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

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RelatedRecordId__c = null);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [SELECT Id, RelatedRecordId__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(null, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_populate_related_fields_on_log_entry_with_related_record_id() {
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        User currentUser = [SELECT Id, Username FROM User WHERE Id = :UserInfo.getUserId()];

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RelatedRecordId__c = currentUser.Id);

        Test.startTest();
        insert logEntry;
        Test.stopTest();

        logEntry = [
            SELECT Id, RelatedRecordId__c, RelatedRecordName__c, RelatedRecordSObject__c
            FROM LogEntry__c
            WHERE Id = :logEntry.Id
        ];
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
        System.assertEquals(currentUser.Username, logEntry.RelatedRecordName__c);
        System.assertEquals('User', logEntry.RelatedRecordSObject__c);
    }
}
