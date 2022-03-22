//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest
private class LogEntryArchivePlugin_Tests {
    @IsTest
    static void it_archives_log_entry_records_in_log_batch_purger_when_purge_action_is_archive() {
        LoggerParameter.setMockParameter(new LoggerParameter__mdt(DeveloperName = 'CustomSaveMethodBigObject', Value__c = 'BIG_OBJECT'));
        LoggerParameter.setMockParameter(new LoggerParameter__mdt(DeveloperName = 'CustomLogPurgeActionArchive', Value__c = 'Archive'));
        LoggerPlugin__mdt pluginConfiguration = createPluginConfiguration();
        LogBatchPurger batchPurger = new LogBatchPurger();
        Log__c log = new Log__c(
            LogPurgeAction__c = LogEntryArchivePlugin.BIG_OBJECT_LOG_PURGE_ACTION,
            LogRetentionDate__c = System.today().addDays(-1),
            TransactionId__c = '1234'
        );
        insert log;
        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        for (Integer i = 0; i < 10; i++) {
            logEntries.add(new LogEntry__c(Log__c = log.Id, Message__c = 'Some message for ' + i, TransactionEntryNumber__c = i));
        }
        insert logEntries;
        Test.startTest();

        Database.executeBatch(batchPurger);

        System.assertEquals(0, Limits.getPublishImmediateDml());
        Test.stopTest();
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(logEntries.size(), LogEntryArchivePlugin.LOG_ENTRY_ARCHIVES_TO_SAVE.size());
        List<Log__c> existingLogs = [SELECT Id FROM Log__c];
        System.assertEquals(0, existingLogs.size());
    }

    @IsTest
    static void it_skips_log_entry_records_in_log_batch_purger_when_purge_action_is_not_archive() {
        LoggerParameter.setMockParameter(new LoggerParameter__mdt(DeveloperName = 'CustomSaveMethodBigObject', Value__c = 'BIG_OBJECT'));
        LoggerParameter.setMockParameter(new LoggerParameter__mdt(DeveloperName = 'CustomLogPurgeActionArchive', Value__c = 'Archive'));
        LoggerPlugin__mdt pluginConfiguration = createPluginConfiguration();
        LogBatchPurger batchPurger = new LogBatchPurger();
        Log__c logToArchive = new Log__c(
            LogPurgeAction__c = LogEntryArchivePlugin.BIG_OBJECT_LOG_PURGE_ACTION,
            LogRetentionDate__c = System.today().addDays(-1),
            TransactionId__c = '1234'
        );
        Log__c logToSkip = new Log__c(LogPurgeAction__c = 'Delete', LogRetentionDate__c = System.today().addDays(-1), TransactionId__c = '5678');
        insert new List<Log__c>{ logToArchive, logToSkip };
        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        for (Integer i = 0; i < 10; i++) {
            logEntries.add(new LogEntry__c(Log__c = logToArchive.Id, Message__c = 'Some message to archive for ' + i, TransactionEntryNumber__c = i));
            logEntries.add(new LogEntry__c(Log__c = logToSkip.Id, Message__c = 'Some message to skip for ' + i, TransactionEntryNumber__c = i));
        }
        insert logEntries;
        Test.startTest();

        Database.executeBatch(batchPurger);

        System.assertEquals(0, Limits.getPublishImmediateDml());
        Test.stopTest();
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(
            logEntries.size() / 2,
            LogEntryArchivePlugin.LOG_ENTRY_ARCHIVES_TO_SAVE.size(),
            'Only half of the log entries should have been archived'
        );
        List<Log__c> existingLogs = [SELECT Id FROM Log__c];
        System.assertEquals(0, existingLogs.size());
    }

    @IsTest
    static void it_includes_tags_for_log_entry_in_log_batch_purger_when_tags_exist() {
        LoggerParameter.setMockParameter(new LoggerParameter__mdt(DeveloperName = 'CustomSaveMethodBigObject', Value__c = 'BIG_OBJECT'));
        LoggerParameter.setMockParameter(new LoggerParameter__mdt(DeveloperName = 'CustomLogPurgeActionArchive', Value__c = 'Archive'));
        LoggerPlugin__mdt pluginConfiguration = createPluginConfiguration();
        LogBatchPurger batchPurger = new LogBatchPurger();
        Log__c log = new Log__c(
            LogPurgeAction__c = LogEntryArchivePlugin.BIG_OBJECT_LOG_PURGE_ACTION,
            LogRetentionDate__c = System.today().addDays(-1),
            TransactionId__c = '1234'
        );
        insert log;
        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        for (Integer i = 0; i < 10; i++) {
            logEntries.add(new LogEntry__c(Log__c = log.Id, Message__c = 'Some message for ' + i, TransactionEntryNumber__c = i));
        }
        insert logEntries;
        LoggerTag__c tag = new LoggerTag__c(Name = 'Some tag');
        insert tag;
        List<LogEntryTag__c> logEntryTags = new List<LogEntryTag__c>();
        for (LogEntry__c logEntry : logEntries) {
            logEntryTags.add(new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id));
        }
        insert logEntryTags;
        Test.startTest();

        Database.executeBatch(batchPurger);

        System.assertEquals(0, Limits.getPublishImmediateDml());
        Test.stopTest();
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(logEntries.size(), LogEntryArchivePlugin.LOG_ENTRY_ARCHIVES_TO_SAVE.size());
        for (LogEntryArchive__b logEntryArchive : LogEntryArchivePlugin.LOG_ENTRY_ARCHIVES_TO_SAVE) {
            System.assertEquals(tag.Name, logEntryArchive.Tags__c);
        }
        List<Log__c> existingLogs = [SELECT Id FROM Log__c];
        System.assertEquals(0, existingLogs.size());
    }

    @IsTest
    static void it_should_not_create_archive_in_logger_when_save_method_is_not_big_object() {
        Datetime timestamp = System.now();
        LogEntryEvent__e mockEvent = LoggerTestUtils.createLogEntryEvent(timestamp);
        LoggerPlugin__mdt pluginConfiguration = createPluginConfiguration();
        LoggerSObjectHandler.SObjectHandlerInput pluginInput = new LoggerSObjectHandler.SObjectHandlerInput();
        pluginInput.triggerNew = new List<LogEntryEvent__e>{ mockEvent };
        Logger.getUserSettings().DefaultSaveMethod__c = Logger.SaveMethod.EVENT_BUS.name();

        new LogEntryArchivePlugin().execute(pluginConfiguration, pluginInput);

        System.assertEquals(0, LogEntryArchivePlugin.LOG_ENTRY_ARCHIVES_TO_SAVE.size(), 'Should not have tried to create big object');
    }

    @IsTest
    static void it_should_create_archive_in_logger_when_save_method_is_big_object() {
        Test.startTest();
        createPluginConfiguration();
        Logger.getUserSettings().DefaultSaveMethod__c = LogEntryArchivePlugin.BIG_OBJECT_LOGGER_SAVE_METHOD;
        LogEntryEvent__e createdEvent = Logger.info('Testing big object creation').getLogEntryEvent();

        Logger.saveLog();

        System.assertEquals(
            0,
            Limits.getPublishImmediateDml(),
            'Should not have actually used the event bus in tests because big objects actually get inserted, yikes'
        );
        Test.stopTest();
        System.assertEquals(1, LogEntryArchivePlugin.LOG_ENTRY_ARCHIVES_TO_SAVE.size(), 'Should have been put into big object buffer');
    }

    private static LoggerPlugin__mdt createPluginConfiguration() {
        LoggerPlugin__mdt configuration = new LoggerPlugin__mdt(
            BatchPurgerApexClass__c = LogEntryArchivePlugin.class.getName(),
            DeveloperName = 'LogEntryArchivePlugin',
            IsEnabled__c = true,
            SObjectHandlerApexClass__c = LogEntryArchivePlugin.class.getName()
        );
        LogBatchPurger.setMockPlugin(configuration);
        LoggerSObjectHandler.setMockPlugin(configuration);
        return configuration;
    }
}
