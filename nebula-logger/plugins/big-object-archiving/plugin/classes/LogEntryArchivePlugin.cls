//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Optional plugin that provides a BigObject, `LogEntryArchive__b`, as an alternative option
 *              to the platform event `LogEntryEvent__e`
 * @see LoggerPlugin
 */
public without sharing class LogEntryArchivePlugin implements LoggerPlugin.Batchable, LoggerPlugin.Triggerable {
    @TestVisible
    private static final String BIG_OBJECT_LOGGER_SAVE_METHOD = LoggerParameter.getString('CustomSaveMethodBigObject', null);
    @TestVisible
    private static final String BIG_OBJECT_LOG_PURGE_ACTION = LoggerParameter.getString('CustomLogPurgeActionArchive', null);
    @TestVisible
    private static final List<LogEntryArchive__b> LOG_ENTRY_ARCHIVES_TO_SAVE = new List<LogEntryArchive__b>();

    /**
     * @description Default constructor
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public LogEntryArchivePlugin() {
    }

    // Batchable interface methods
    /**
     * @description Skips directly deleting `LogEntryTag__c` records in `LogBatchPurger` so that the tags
     *             can be included when `LogEntry__c` records are archived into `LogEntryArchive__b`
     * @param  configuration The instance of `LoggerPlugin__mdt` configured for this specific plugin
     * @param  input The instance of `LoggerBatchableContext`, provided by the logging system
     */
    public void start(LoggerPlugin__mdt configuration, LoggerBatchableContext input) {
        // Skip directly deleting LogEntryTag__c records so that the tags can be included when LogEntry__c records
        // are archived into LogEntryArchive__b
        if (input.sobjectType == Schema.LogEntryTag__c.SObjectType) {
            input.sobjectType = Schema.LogEntry__c.SObjectType;
        }
    }

    /**
     * @description Converts any `LogEntry__c` records into `LogEntryArchive__b` records
     * @param  configuration The instance of `LoggerPlugin__mdt` configured for this specific plugin
     * @param  input The instance of `LoggerBatchableContext`, provided by the logging system
     * @param  loggerRecords The list of `SObject` scope records provider by `LogBatchPurger`
     */
    public void execute(LoggerPlugin__mdt configuration, LoggerBatchableContext input, List<SObject> loggerRecords) {
        if (input.sobjectType != Schema.LogEntry__c.SObjectType) {
            return;
        }

        List<LogEntry__c> logEntries = this.requeryLogEntriesToArchive((List<LogEntry__c>) loggerRecords);
        for (LogEntry__c logEntry : logEntries) {
            LOG_ENTRY_ARCHIVES_TO_SAVE.add(new LogEntryArchiveBuilder(logEntry).getLogEntryArchive());
        }
        this.saveLogEntryArchives();
    }

    /**
     * @description No-op method, required by the interface `LoggerPlugin.Batchable`
     * @param  configuration The instance of `LoggerPlugin__mdt` configured for this specific plugin
     * @param  input The instance of `LoggerBatchableContext`, provided by the logging system
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void finish(LoggerPlugin__mdt configuration, LoggerBatchableContext input) {
        // No-op
    }

    // Triggerable interface method
    /**
     * @description Handles converting Logger's buffer of `LogEntryEvent__e` records into `LogEntryArchive__b` records
     *              for any user with the included custom save method 'BIG_OBJECT'
     * @param  configuration The instance of `LoggerPlugin__mdt` configured for this specific plugin
     * @param  input The instance of `LoggerTriggerableContext`, provided by the logging system
     */
    public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input) {
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
        String logLookupRelationshipName = Schema.LogEntry__c.Log__c.getDescribe().getName().removeEnd('__c') + '__r';
        List<String> logFieldsToQuery = new List<String>();
        for (String fieldName : Schema.Log__c.SObjectType.getDescribe().fields.getMap().keySet()) {
            logFieldsToQuery.add(logLookupRelationshipName + '.' + fieldName);
        }
        String parentLogTransactionIdField =
            logLookupRelationshipName +
            '.' +
            Schema.Log__c.ParentLog__c.getDescribe().getName().removeEnd('__c') +
            '__r' +
            '.' +
            Schema.Log__c.TransactionId__c.getDescribe().getName();
        logFieldsToQuery.add(parentLogTransactionIdField);
        List<String> logEntryFieldsToQuery = new List<String>(Schema.LogEntry__c.SObjectType.getDescribe().fields.getMap().keySet());
        logEntryFieldsToQuery.addAll(logFieldsToQuery);

        String tagLookupRelationshipName = Schema.LogEntryTag__c.Tag__c.getDescribe().getName().removeEnd('__c') + '__r';
        String tagNameField = tagLookupRelationshipName + '.' + Schema.LoggerTag__c.Name.getDescribe().getName();

        String logPurgeActionParentFieldName = logLookupRelationshipName + '.' + Schema.Log__c.LogPurgeAction__c.getDescribe().getName();
        String queryTemplate = 'SELECT {0}, (SELECT {1} FROM {2}) FROM {3} WHERE Id IN :logEntries AND {4} = :BIG_OBJECT_LOG_PURGE_ACTION';
        List<Object> queryInputs = new List<Object>{
            String.join(logEntryFieldsToQuery, ', '),
            tagNameField,
            'LogEntryTags__r', // TODO replace with strongly-typed reference or namespace-safe string
            Schema.LogEntry__c.SObjectType.getDescribe().getName(),
            logPurgeActionParentFieldName
        };
        String query = String.escapeSingleQuotes(String.format(queryTemplate, queryInputs));
        return (List<LogEntry__c>) Database.query(query);
    }

    private void saveLogEntryArchives() {
        if (System.Test.isRunningTest() == false) {
            Database.insertImmediate(LOG_ENTRY_ARCHIVES_TO_SAVE);
            LOG_ENTRY_ARCHIVES_TO_SAVE.clear();
        }
    }
}
