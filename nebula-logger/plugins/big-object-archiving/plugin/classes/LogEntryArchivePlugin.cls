//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Optional plugin that provides a BigObject, `LogEntryArchive__b`, as an alternative option
 *              to the platform event `LogEntryEvent__e`
 */
public without sharing class LogEntryArchivePlugin implements LoggerPlugin.Batchable, LoggerPlugin.Triggerable {
    @TestVisible
    private static final String BIG_OBJECT_LOGGER_SAVE_METHOD = LoggerParameter.getString('CustomSaveMethodBigObject', null);
    @TestVisible
    private static final String BIG_OBJECT_LOG_PURGE_ACTION = LoggerParameter.getString('CustomLogPurgeActionArchive', null);
    @TestVisible
    private static final List<LogEntryArchive__b> LOG_ENTRY_ARCHIVES_TO_SAVE = new List<LogEntryArchive__b>();

    public LogEntryArchivePlugin() {
    }

    // Batchable interface methods
    public void start(LoggerPlugin__mdt configuration, LogBatchPurger.BatchPurgerInput input) {
        // Skip directly deleting LogEntryTag__c records so that the tags can be included when LogEntry__c records
        // are archived into LogEntryArchive__b
        if (input.sobjectType == Schema.LogEntryTag__c.SObjectType) {
            input.sobjectType = Schema.LogEntry__c.SObjectType;
        }
    }

    public void execute(LoggerPlugin__mdt configuration, LogBatchPurger.BatchPurgerInput input, List<SObject> loggerRecords) {
        if (input.sobjectType != Schema.LogEntry__c.SObjectType) {
            return;
        }

        List<LogEntry__c> logEntries = this.requeryLogEntriesToArchive((List<LogEntry__c>) loggerRecords);
        for (LogEntry__c logEntry : logEntries) {
            LOG_ENTRY_ARCHIVES_TO_SAVE.add(new LogEntryArchiveBuilder(logEntry).getLogEntryArchive());
        }
        this.saveLogEntryArchives();
    }

    public void finish(LoggerPlugin__mdt configuration, LogBatchPurger.BatchPurgerInput input) {
        // No-op
    }

    // Triggerable interface method
    /**
     * @description Handles converting Logger's buffer of `LogEntryEvent__e` records into `LogEntryArchive__b` records
     *              for any user with the included custom save method 'BIG_OBJECT'
     * @param  configuration The instance of `LoggerPlugin__mdt` configured for this specific plugin
     * @param  input The instance of `LoggerPlugin.Triggerable.SObjectHandlerInput`, provided by the logging system
     */
    public void execute(LoggerPlugin__mdt configuration, LoggerSObjectHandler.SObjectHandlerInput input) {
        if (
            input.sobjectType != Schema.LogEntryEvent__e.SObjectType ||
            input.triggerOperationType != TriggerOperation.BEFORE_INSERT ||
            Logger.getUserSettings().DefaultSaveMethod__c != BIG_OBJECT_LOGGER_SAVE_METHOD
        ) {
            return;
        }

        List<LogEntryEvent__e> logEntryEvents = (List<LogEntryEvent__e>) input.triggerNew;
        for (LogEntryEvent__e logEntryEvent : logEntryEvents) {
            LOG_ENTRY_ARCHIVES_TO_SAVE.add(new LogEntryArchiveBuilder(logEntryEvent).getLogEntryArchive());
        }
        this.saveLogEntryArchives();
        Logger.flushBuffer();
    }

    private List<LogEntry__c> requeryLogEntriesToArchive(List<LogEntry__c> logEntries) {
        // TODO Query LogEntry__c records to include Log__c parent-level fields, and LogEntryTag__c + LoggerTag__c fields via child query
        List<LogEntry__c> logEntriesToArchive = [
            SELECT Id
            FROM LogEntry__c
            WHERE Id IN :logEntries AND Log__r.LogPurgeAction__c = :BIG_OBJECT_LOG_PURGE_ACTION
            ORDER BY Timestamp__c, Log__c
        ];
        return logEntriesToArchive;
    }

    private void saveLogEntryArchives() {
        if (!Test.isRunningTest()) {
            Database.insertImmediate(LOG_ENTRY_ARCHIVES_TO_SAVE);
            LOG_ENTRY_ARCHIVES_TO_SAVE.clear();
        }
    }
}
