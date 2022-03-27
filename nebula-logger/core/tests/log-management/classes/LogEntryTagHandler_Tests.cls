//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class LogEntryTagHandler_Tests {
    @TestSetup
    static void setupData() {
        LoggerSObjectHandler.shouldExecute(false);

        Log__c log = (Log__c) new LoggerSObjectTestDataGenerator(Schema.Log__c.SObjectType).populateRequiredFields();
        insert log;

        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        for (Integer i = 0; i < 3; i++) {
            LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, TransactionEntryNumber__c = i + 1);
            new LoggerSObjectTestDataGenerator(logEntry).populateRequiredFields();
            logEntries.add(logEntry);
        }
        insert logEntries;

        insert new LoggerSObjectTestDataGenerator(Schema.LoggerTag__c.SObjectType).populateRequiredFields();
    }

    @IsTest
    static void it_should_return_the_logEntryTag_sobjectType() {
        System.assertEquals(Schema.LogEntryTag__c.SObjectType, new LogEntryTagHandler().getSObjectType());
    }

    @IsTest
    static void it_should_not_run_when_disabled_via_configuration() {
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'IsLogEntryTagHandlerEnabled', Value__c = 'false');
        LoggerTestUtils.setMock(mockParameter);
        LogEntry__c logEntry = [SELECT Id FROM LogEntry__c LIMIT 1];
        LoggerTag__c tag = [SELECT Id FROM LoggerTag__c LIMIT 1];

        LogEntryTag__c logEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
        insert logEntryTag;

        System.assertEquals(
            null,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryTag__c.SObjectType),
            LoggerSObjectHandler.getExecutedHandlers()
        );
    }

    @IsTest
    static void it_should_set_unique_id_on_insert() {
        LogEntry__c logEntry = [SELECT Id FROM LogEntry__c LIMIT 1];
        LoggerTag__c tag = [SELECT Id FROM LoggerTag__c LIMIT 1];

        LogEntryTag__c logEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
        insert logEntryTag;

        logEntryTag = [SELECT Id, LogEntry__c, Tag__c, UniqueId__c FROM LogEntryTag__c WHERE Id = :logEntryTag.Id];
        System.assertEquals(logEntry.Id + '' + tag.Id, logEntryTag.UniqueId__c);
    }

    @IsTest
    static void it_should_set_unique_id_on_update() {
        LogEntry__c logEntry = [SELECT Id FROM LogEntry__c LIMIT 1];
        LoggerTag__c tag = [SELECT Id FROM LoggerTag__c LIMIT 1];

        LogEntryTag__c logEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
        insert logEntryTag;
        logEntryTag.UniqueId__c = 'something else';
        update logEntryTag;

        logEntryTag = [SELECT Id, LogEntry__c, Tag__c, UniqueId__c FROM LogEntryTag__c WHERE Id = :logEntryTag.Id];
        System.assertEquals(logEntry.Id + '' + tag.Id, logEntryTag.UniqueId__c);
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
            String expectedDuplicateError = 'DUPLICATE_VALUE';
            System.assert(ex.getMessage().contains(expectedDuplicateError), ex.getMessage());
        }
    }
}
