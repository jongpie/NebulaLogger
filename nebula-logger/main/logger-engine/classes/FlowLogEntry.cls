/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
global inherited sharing class FlowLogEntry {
    @InvocableVariable(required=true label='Flow or Process Builder Name')
    global String flowName;

    @InvocableVariable(required=true label='Log Entry Message')
    global String message;

    @InvocableVariable(required=false label='(Optional) Save Log')
    global Boolean saveLog = true;

    @InvocableVariable(required=false label='(Optional) Record ID')
    global Id recordId;

    @InvocableVariable(required=false label='(Optional) Logging Level')
    global String loggingLevelName = 'DEBUG';

    @InvocableVariable(required=false label='(Optional) Topics')
    global List<String> topics;

    private DateTime timestamp = System.now();

    @InvocableMethod(category='Logging' label='Add Log Entry' description='Creates a log entry for a flow or process builder')
    global static List<String> addFlowEntries(List<FlowLogEntry> flowLogEntries) {
        Boolean saveLog = false;
        for (FlowLogEntry flowLogEntry : flowLogEntries) {
            LoggingLevel loggingLevel = Logger.getLoggingLevel(flowLogEntry.loggingLevelName);

            LogEntryEventBuilder logEntryBuilder = Logger.newEntry(loggingLevel)
                .setMessage(flowLogEntry.message)
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
