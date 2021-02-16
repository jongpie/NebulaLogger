//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group logger-engine
 * @description Handles adding new log entryies in Flow
 * @see FlowRecordLogEntry
 * @see Logger
 * @see LogEntryEventBuilder
 */
global inherited sharing class FlowLogEntry {
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
     * @description Optionally choose to save any pending log entries.
     */
    @InvocableVariable(required=false label='(Optional) Save Log')
    global Boolean saveLog = true;

    /**
     * @description Optionally relate the log entry to a particular record ID.
     */
    @InvocableVariable(required=false label='(Optional) Record ID')
    global Id recordId;

    /**
     * @description Optionally specify a logging level. The default is 'DEBUG'
     */
    @InvocableVariable(required=false label='(Optional) Logging Level')
    global String loggingLevelName = 'DEBUG';

    /**
     * @description Optionally provide a list of topics to dynamically assign to the log entry.
     */
    @InvocableVariable(required=false label='(Optional) Topics')
    global List<String> topics;

    private DateTime timestamp = System.now();

    /**
     * addFlowEntries description
     * @param  flowLogEntries The list of FlowLogEntry instances to save
     * @return                The current transaction's ID (based on Logger.getTransactionId())
     */
    @InvocableMethod(category='Logging' label='Add Log Entry' description='Creates a log entry for a flow or process builder')
    global static List<String> addFlowEntries(List<FlowLogEntry> flowLogEntries) {
        Boolean saveLog = false;
        for (FlowLogEntry flowLogEntry : flowLogEntries) {
            LoggingLevel loggingLevel = Logger.getLoggingLevel(flowLogEntry.loggingLevelName);

            LogEntryEventBuilder logEntryBuilder = Logger.newEntry(loggingLevel, flowLogEntry.message)
                .setRecordId(flowLogEntry.recordId)
                .setTopics(flowLogEntry.topics);

            LogEntryEvent__e logEntryEvent = logEntryBuilder.getLogEntryEvent();

            if (logEntryEvent == null) {
                continue;
            }

            logEntryEvent.OriginLocation__c = flowLogEntry.flowName;
            logEntryEvent.OriginType__c = 'Flow';
            logEntryEvent.Timestamp__c = flowLogEntry.timestamp;

            if (flowLogEntry.saveLog) {
                saveLog = flowLogEntry.saveLog;
            }
        }

        if (saveLog) {
            Logger.saveLog();
        }

        return new List<String>{ Logger.getTransactionId() };
    }
}
