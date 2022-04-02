//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest
private class LogEntryArchivePlugin_Tests {
    @TestSetup
    static void setupData() {
        LoggerSObjectHandler.shouldExecute(false);
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'CustomSaveMethodBigObject', Value__c = 'BIG_OBJECT'));
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'CustomLogPurgeActionArchive', Value__c = 'Archive'));
        createPluginConfiguration();

        Log__c logToArchive = new Log__c(
            LogPurgeAction__c = LogEntryArchivePlugin.BIG_OBJECT_LOG_PURGE_ACTION,
            LogRetentionDate__c = System.today().addDays(-1),
            TransactionId__c = '1234'
        );
        Log__c logToDelete = new Log__c(LogPurgeAction__c = 'Delete', LogRetentionDate__c = System.today().addDays(-1), TransactionId__c = '5678');
        insert new List<Log__c>{ logToArchive, logToDelete };

        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        for (Integer i = 0; i < 10; i++) {
            logEntries.add(new LogEntry__c(Log__c = logToArchive.Id, Message__c = 'Some message to archive for ' + i, TransactionEntryNumber__c = i));
            logEntries.add(new LogEntry__c(Log__c = logToDelete.Id, Message__c = 'Some message to skip for ' + i, TransactionEntryNumber__c = i));
        }
        insert logEntries;
    }

    @IsTest
    static void it_archives_log_entry_records_in_log_batch_purger_when_purge_action_is_archive() {
        LoggerSObjectHandler.shouldExecute(false);
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'CustomSaveMethodBigObject', Value__c = 'BIG_OBJECT'));
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'CustomLogPurgeActionArchive', Value__c = 'Archive'));
        createPluginConfiguration();
        LogBatchPurger batchPurger = new LogBatchPurger();
        Log__c log = [SELECT Id, (SELECT Id FROM LogEntries__r) FROM Log__c WHERE LogPurgeAction__c = :LogEntryArchivePlugin.BIG_OBJECT_LOG_PURGE_ACTION];
        Test.startTest();

        Database.executeBatch(batchPurger);

        Test.stopTest();
        System.assertEquals(log.LogEntries__r.size(), LogEntryArchivePlugin.LOG_ENTRY_ARCHIVES_TO_SAVE.size());
        List<Log__c> existingLogs = [SELECT Id FROM Log__c WHERE LogPurgeAction__c = :LogEntryArchivePlugin.BIG_OBJECT_LOG_PURGE_ACTION];
        System.assertEquals(0, existingLogs.size());
    }

    @IsTest
    static void it_skips_log_entry_records_in_log_batch_purger_when_purge_action_is_not_archive() {
        LoggerSObjectHandler.shouldExecute(false);
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'CustomSaveMethodBigObject', Value__c = 'BIG_OBJECT'));
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'CustomLogPurgeActionArchive', Value__c = 'Archive'));
        createPluginConfiguration();
        LogBatchPurger batchPurger = new LogBatchPurger();
        Log__c logToArchive = [
            SELECT Id, (SELECT Id FROM LogEntries__r)
            FROM Log__c
            WHERE LogPurgeAction__c = :LogEntryArchivePlugin.BIG_OBJECT_LOG_PURGE_ACTION
        ];
        System.assertNotEquals(
            true,
            logToArchive.LogEntries__r.isEmpty(),
            'Test has started under the wrong condiations - log record should have some related log entries'
        );
        Log__c logToSkip = [SELECT Id, (SELECT Id FROM LogEntries__r) FROM Log__c WHERE LogPurgeAction__c = 'Delete'];
        System.assertNotEquals(
            true,
            logToSkip.LogEntries__r.isEmpty(),
            'Test has started under the wrong condiations - log record should have some related log entries'
        );
        Test.startTest();

        Database.executeBatch(batchPurger);

        Test.stopTest();
        System.assertEquals(
            logToArchive.LogEntries__r.size(),
            LogEntryArchivePlugin.LOG_ENTRY_ARCHIVES_TO_SAVE.size(),
            'Only the log entries for logToArchive should have been archived'
        );
        List<Log__c> existingLogs = [SELECT Id FROM Log__c];
        System.assertEquals(0, existingLogs.size(), 'All logs should havve been deleted');
    }

    @IsTest
    static void it_includes_tags_for_log_entry_in_log_batch_purger_when_tags_exist() {
        LoggerSObjectHandler.shouldExecute(false);
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'CustomSaveMethodBigObject', Value__c = 'BIG_OBJECT'));
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'CustomLogPurgeActionArchive', Value__c = 'Archive'));
        createPluginConfiguration();
        LogBatchPurger batchPurger = new LogBatchPurger();
        Log__c logToArchive = [
            SELECT Id, (SELECT Id FROM LogEntries__r)
            FROM Log__c
            WHERE LogPurgeAction__c = :LogEntryArchivePlugin.BIG_OBJECT_LOG_PURGE_ACTION
        ];
        LoggerTag__c tag = new LoggerTag__c(Name = 'Some tag');
        insert tag;
        List<LogEntryTag__c> logEntryTags = new List<LogEntryTag__c>();
        for (LogEntry__c logEntry : logToArchive.LogEntries__r) {
            logEntryTags.add(new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tag.Id));
        }
        insert logEntryTags;
        Test.startTest();

        Database.executeBatch(batchPurger);

        System.assertEquals(0, Limits.getPublishImmediateDml());
        Test.stopTest();
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(logToArchive.LogEntries__r.size(), LogEntryArchivePlugin.LOG_ENTRY_ARCHIVES_TO_SAVE.size());
        for (LogEntryArchive__b logEntryArchive : LogEntryArchivePlugin.LOG_ENTRY_ARCHIVES_TO_SAVE) {
            System.assertEquals(tag.Name, logEntryArchive.Tags__c);
        }
        List<Log__c> existingLogs = [SELECT Id FROM Log__c];
        System.assertEquals(0, existingLogs.size());
    }

    @IsTest
    static void it_should_not_create_archive_in_logger_when_save_method_is_not_big_object() {
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        Logger.getUserSettings().DefaultSaveMethod__c = Logger.SaveMethod.EVENT_BUS.name();
        LogEntryEvent__e mockEvent = (LogEntryEvent__e) LoggerMockCreator.createDataBuilder(Schema.LogEntryEvent__e.SObjectType)
            .populateRequiredFields()
            .getRecord();
        LoggerPlugin__mdt pluginConfiguration = createPluginConfiguration();
        LoggerTriggerableContext pluginInput = new LoggerTriggerableContext(
            Schema.LogEntryEvent__e.SObjectType,
            TriggerOperation.BEFORE_INSERT,
            new List<LogEntryEvent__e>{ mockEvent },
            null,
            null
        );

        new LogEntryArchivePlugin().execute(pluginConfiguration, pluginInput);

        System.assertEquals(0, LogEntryArchivePlugin.LOG_ENTRY_ARCHIVES_TO_SAVE.size(), 'Should not have tried to create big object');
    }

    @IsTest
    static void it_should_create_archive_in_logger_when_save_method_is_big_object() {
        Test.startTest();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        Logger.getUserSettings().DefaultSaveMethod__c = LogEntryArchivePlugin.BIG_OBJECT_LOGGER_SAVE_METHOD;
        createPluginConfiguration();
        Logger.info('Testing big object creation').getLogEntryEvent();

        Logger.saveLog();

        System.assertEquals(
            0,
            Limits.getPublishImmediateDml(),
            'Should not have actually used the event bus in tests because big objects actually get inserted, yikes'
        );
        Test.stopTest();
        System.assertEquals(0, Logger.getBufferSize(), 'Should not have been put into Logger\'s platform event buffer');
        System.assertEquals(1, LogEntryArchivePlugin.LOG_ENTRY_ARCHIVES_TO_SAVE.size(), 'Should have been put into big object buffer');
    }

    private static LoggerPlugin__mdt createPluginConfiguration() {
        LoggerPlugin__mdt configuration = new LoggerPlugin__mdt(
            BatchPurgerApexClass__c = LogEntryArchivePlugin.class.getName(),
            DeveloperName = 'LogEntryArchivePlugin',
            IsEnabled__c = true,
            SObjectHandlerApexClass__c = LogEntryArchivePlugin.class.getName()
        );
        LoggerTestConfigurator.setMock(configuration);
        return configuration;
    }
}
