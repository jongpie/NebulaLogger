/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
public without sharing class FlowRecordLogEntry {

    @InvocableVariable(required=true label='Flow or Process Builder Name')
    public String flowName;

    @InvocableVariable(required=true label='Log Entry Message')
    public String message;

    @InvocableVariable(required=true label='Record')
    public SObject record;

    @InvocableVariable(required=false label='(Optional) Save Log')
    public Boolean saveLog = true;

    @InvocableVariable(required=false label='(Optional) Logging Level')
    public String loggingLevelName = 'DEBUG';

    @InvocableVariable(required=false label='(Optional) Topics')
    public List<String> topics;

    @InvocableVariable(required=false label='(Optional) Timestamp')
    public DateTime timestamp = System.now();

    @InvocableMethod(category='Logging' label='Add Log Entry for an SObject Record' description='Creates a log entry a flow or process builder and stores the record as JSON')
    public static List<String> addFlowRecordEntries(List<FlowRecordLogEntry> flowRecordLogEntries) {
        Boolean saveLog = false;
        for(FlowRecordLogEntry flowRecordLogEntry : flowRecordLogEntries) {
            LoggingLevel loggingLevel = Logger.getLoggingLevel(flowRecordLogEntry.loggingLevelName);

            LogEntryBuilder logEntryBuilder = Logger.createLogEntryBuilder(loggingLevel)
                .setMessage(flowRecordLogEntry.message)
                .setRecordId(flowRecordLogEntry.record)
                .setTopics(flowRecordLogEntry.topics);

            LogEntryEvent__e logEntryEvent = logEntryBuilder.getLogEntryEvent();

            if(logEntryEvent == null) {
                continue;
            }

            logEntryEvent.LoggingLevel__c    = flowRecordLogEntry.loggingLevelName;
            logEntryEvent.OriginLocation__c  = flowRecordLogEntry.flowName;
            logEntryEvent.OriginType__c      = 'Flow';
            logEntryEvent.Timestamp__c       = flowRecordLogEntry.timestamp;

            if(flowRecordLogEntry.saveLog) saveLog = flowRecordLogEntry.saveLog;
        }
        if(saveLog) Logger.saveLog();
        return new List<String>{ Logger.getTransactionId() };
    }

}