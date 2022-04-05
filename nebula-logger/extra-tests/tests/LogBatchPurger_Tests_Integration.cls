//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class LogBatchPurger_Tests_Integration {
    private static final Integer NUMBER_OF_LOG_ENTRIES = 10;
    private static final Profile STANDARD_USER_PROFILE = [SELECT Id FROM Profile WHERE Name IN ('Standard User', 'Usuario estándar')];

    @TestSetup
    static void setupData() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.IsEnabled__c = false;
        settings.LoggingLevel__c = LoggingLevel.FINEST.name();
        insert settings;

        Date scheduledDeletionDate = System.today().addDays(-7);
        Log__c log = new Log__c(LogRetentionDate__c = scheduledDeletionDate, TransactionId__c = '1234');
        insert log;

        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        for (Integer i = 0; i < NUMBER_OF_LOG_ENTRIES; i++) {
            LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = LoggingLevel.INFO.name());

            logEntries.add(logEntry);
        }
        insert logEntries;

        LoggerTag__c tag = new LoggerTag__c(Name = 'My important tag');
        insert tag;

        List<LogEntryTag__c> logEntryTags = new List<LogEntryTag__c>();
        for (LogEntry__c logEntry : logEntries) {
            LogEntryTag__c logEntryTag = new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id);
            logEntryTags.add(logEntryTag);
        }
        insert logEntryTags;
    }

    @IsTest
    static void it_should_throw_exception_when_user_does_not_have_delete_access() {
        Integer originalCountOfLogEntries = [SELECT COUNT() FROM LogEntry__c];

        User standardUser = LoggerMockDataCreator.createUser(STANDARD_USER_PROFILE.Id);
        System.runAs(standardUser) {
            System.assertEquals(false, Schema.Log__c.SObjectType.getDescribe().isDeletable());

            try {
                Test.startTest();
                Database.executeBatch(new LogBatchPurger());
                Test.stopTest();
            } catch (NoAccessException ex) {
                System.assertEquals(LogBatchPurger.NO_DELETE_ACCESS_EXCEPTION_MESSAGE, ex.getMessage());
            }
        }
        Integer updatedCountOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(originalCountOfLogEntries, updatedCountOfLogEntries);
    }
}
