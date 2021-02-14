/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
global inherited sharing class FlowRecordLogEntry {
    @InvocableVariable(required=true label='Flow or Process Builder Name')
    global String flowName;

    @InvocableVariable(required=true label='Log Entry Message')
    global String message;

    @InvocableVariable(required=true label='Record')
    global SObject record;

    @InvocableVariable(required=false label='(Optional) Save Log')
    global Boolean saveLog = true;

    @InvocableVariable(required=false label='(Optional) Logging Level')
    global String loggingLevelName = 'DEBUG';

    @InvocableVariable(required=false label='(Optional) Topics')
    global List<String> topics;

    private DateTime timestamp = System.now();

    @InvocableMethod(
        category='Logging'
        label='Add Log Entry for an SObject Record'
        description='Creates a log entry for a flow or process builder and stores the record as JSON'
    )
    global static List<String> addFlowRecordEntries(List<FlowRecordLogEntry> flowRecordLogEntries) {
        Boolean saveLog = false;
        for (FlowRecordLogEntry flowRecordLogEntry : flowRecordLogEntries) {
            LoggingLevel loggingLevel = Logger.getLoggingLevel(flowRecordLogEntry.loggingLevelName);

            LogEntryEventBuilder logEntryBuilder = Logger.newEntry(loggingLevel)
                .setMessage(flowRecordLogEntry.message)
                .setRecordId(flowRecordLogEntry.record)
                .setTopics(flowRecordLogEntry.topics);

            LogEntryEvent__e logEntryEvent = logEntryBuilder.getLogEntryEvent();

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
