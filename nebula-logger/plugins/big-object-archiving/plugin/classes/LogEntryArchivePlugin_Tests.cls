//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest
private class LogEntryArchivePlugin_Tests {
    @IsTest
    static void todo_it_skips_logEntryTag_in_log_batch_purger_when_batchable() {
        System.assert(false, 'TODO');
    }

    @IsTest
    static void todo_it_archives_logEntry_records_in_log_batch_purger_when_batchable() {
        System.assert(false, 'TODO');
    }

    @IsTest
    static void todo_it_integrates_with_log_batch_purger_when_batchable() {
        System.assert(false, 'TODO');
    }

    @IsTest
    static void it_should_not_create_big_object_with_other_save_methods_when_triggerable() {
        Datetime timestamp = System.now();
        LogEntryEvent__e mockEvent = LoggerTestUtils.createMockLogEntryEvent(timestamp);
        LoggerPlugin__mdt pluginConfiguration = createPluginConfiguration();
        LoggerSObjectHandler.SObjectHandlerInput pluginInput = new LoggerSObjectHandler.SObjectHandlerInput();
        pluginInput.triggerNew = new List<LogEntryEvent__e>{ mockEvent };
        Logger.getUserSettings().DefaultSaveMethod__c = Logger.SaveMethod.EVENT_BUS.name();

        new LogEntryArchivePlugin().execute(pluginConfiguration, pluginInput);

        System.assertEquals(0, LogEntryArchivePlugin.LOG_ENTRY_ARCHIVES_TO_SAVE.size(), 'Should not have tried to create big object');
    }

    @IsTest
    static void it_integrates_with_logger_sobject_handler_when_triggerable() {
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
        LoggerPlugin__mdt config = new LoggerPlugin__mdt(IsEnabled__c = true, SObjectHandlerApexClass__c = LogEntryArchivePlugin.class.getName());
        LoggerSObjectHandler.setMockPlugin(Schema.LogEntryEvent__e.SObjectType, config);
        return config;
    }
}
