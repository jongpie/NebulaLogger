//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group logger-engine
 * @description Handles adding new log entries in Flow for a particular SObject record
 * @see FlowLogEntry
 * @see Logger
 * @see LogEntryEventBuilder
 */
global inherited sharing class FlowRecordLogEntry {
    /**
     * @description The name of the Flow creating the log entry.
     * Due to Salesforce limitations, this cannot be automatically determined.
     */
    @InvocableVariable(required=true label='Flow or Process Builder Name')
    global String flowName;

    /**
     * @description The message to log.
     */
    @InvocableVariable(required=true label='Log Entry Message')
    global String message;

    /**
     * @description The record to relate to this log entry. The record's JSON will be automatically added to the entry.
     */
    @InvocableVariable(required=true label='Record')
    global SObject record;

    /**
     * @description Optionally choose to save any pending log entries.
     */
    @InvocableVariable(required=false label='(Optional) Save Log')
    global Boolean saveLog = true;

    /**
     * @description Optionally specify a logging level. The default is 'DEBUG'
     */
    @InvocableVariable(required=false label='(Optional) Logging Level')
    global String loggingLevelName = 'DEBUG';

    /**
     * @description Optionally provide a list of topics to dynamically assign to the log entry.
     */
    @InvocableVariable(required=false label='(Optional) Topics')
    public List<String> topics;

    private DateTime timestamp = System.now();

    /**
     * addFlowRecordEntries description
     * @param  flowRecordLogEntries The list of FlowRecordLogEntry instances to save
     * @return                      The current transaction's ID (based on Logger.getTransactionId())
     */
    @InvocableMethod(
        category='Logging'
        label='Add Log Entry for an SObject Record'
        description='Creates a log entry for a flow or process builder and stores the record as JSON'
    )
    global static List<String> addFlowRecordEntries(List<FlowRecordLogEntry> flowRecordLogEntries) {
        Boolean saveLog = false;
        for (FlowRecordLogEntry flowRecordLogEntry : flowRecordLogEntries) {
            LoggingLevel loggingLevel = Logger.getLoggingLevel(flowRecordLogEntry.loggingLevelName);

            LogEntryEventBuilder logEntryEventBuilder = Logger.newEntry(loggingLevel, flowRecordLogEntry.message)
                .setRecordId(flowRecordLogEntry.record)
                .setTopics(flowRecordLogEntry.topics);

            LogEntryEvent__e logEntryEvent = logEntryEventBuilder.getLogEntryEvent();

            if (logEntryEvent == null) {
                continue;
            }

            logEntryEvent.OriginLocation__c = flowRecordLogEntry.flowName;
            logEntryEvent.OriginType__c = 'Flow';
            logEntryEvent.Timestamp__c = flowRecordLogEntry.timestamp;

            if (flowRecordLogEntry.saveLog) {
                saveLog = flowRecordLogEntry.saveLog;
            }
        }
        if (saveLog) {
            Logger.saveLog();
        }
        return new List<String>{ Logger.getTransactionId() };
    }
}
