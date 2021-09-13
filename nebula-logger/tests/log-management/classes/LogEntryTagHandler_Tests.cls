//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@IsTest
private class LogEntryTagHandler_Tests {
    @TestSetup
    static void setupData() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        for (Integer i = 0; i < 3; i++) {
            logEntries.add(new LogEntry__c(Log__c = log.Id, Message__c = 'log entry #' + i));
        }
        insert logEntries;

        insert new LoggerTag__c(Name = 'Some tag');
    }

    @IsTest
    static void it_should_set_unique_id_when_enabled() {
        LogEntry__c logEntry = [SELECT Id FROM LogEntry__c LIMIT 1];
        LoggerTag__c tag = [SELECT Id FROM LoggerTag__c LIMIT 1];

        LogEntryTag__c logEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
        insert logEntryTag;

        logEntryTag = [SELECT Id, LogEntry__c, Tag__c, UniqueId__c FROM LogEntryTag__c WHERE Id = :logEntryTag.Id];
        System.assertEquals(logEntry.Id + '' + tag.Id, logEntryTag.UniqueId__c);
    }

    @IsTest
    static void it_should_not_set_unique_id_when_disabled() {
        LoggerSObjectHandler__mdt loggerTagHandlerConfiguration = new LoggerSObjectHandler__mdt(
            IsEnabled__c = false,
            SObjectType__c = LogEntryTag__c.SObjectType.getDescribe().getName()
        );
        LoggerSObjectHandler.setMockConfiguration(Schema.LogEntryTag__c.SObjectType, loggerTagHandlerConfiguration);

        LogEntry__c logEntry = [SELECT Id FROM LogEntry__c LIMIT 1];
        LoggerTag__c tag = [SELECT Id FROM LoggerTag__c LIMIT 1];

        LogEntryTag__c logEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
        insert logEntryTag;

        logEntryTag = [SELECT Id, LogEntry__c, Tag__c, UniqueId__c FROM LogEntryTag__c WHERE Id = :logEntryTag.Id];
        System.assertEquals(null, logEntryTag.UniqueId__c);
    }

    @IsTest
    static void it_should_not_insert_duplicate_tag() {
        LogEntry__c logEntry = [SELECT Id FROM LogEntry__c LIMIT 1];
        LoggerTag__c tag = [SELECT Id FROM LoggerTag__c LIMIT 1];

        LogEntryTag__c logEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
        insert logEntryTag;

        LogEntryTag__c duplicateLogEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
        try {
            insert duplicateLogEntryTag;
            System.assert(false, 'Exception expected on previous line');
        } catch (Exception ex) {
            String expectedDuplicateError = 'DUPLICATE_VALUE, duplicate value found';
            System.assert(ex.getMessage().contains(expectedDuplicateError), ex.getMessage());
        }
    }
}
