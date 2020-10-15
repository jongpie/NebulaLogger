/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class FlowLogEntry {

    @InvocableVariable(required=true label='Flow or Process Builder Name')
    public String flowName;

    @InvocableVariable(required=true label='Log Entry Message')
    public String message;

    @InvocableVariable(required=false label='(Optional) Save Log')
    public Boolean saveLog = true;

    @InvocableVariable(required=false label='(Optional) Record ID')
    public Id recordId;

    @InvocableVariable(required=false label='(Optional) Logging Level')
    public String loggingLevelName = 'DEBUG';

    @InvocableVariable(required=false label='(Optional) Topics')
    public List<String> topics;

    @InvocableVariable(required=false label='(Optional) Timestamp')
    public DateTime timestamp = System.now();

    @InvocableMethod(category='Logging' label='Add Log Entry' description='Creates a log entry for a flow or process builder')
    public static List<String> addFlowEntries(List<FlowLogEntry> flowLogEntries) {
        Boolean saveLog = false;
        for(FlowLogEntry flowLogEntry : flowLogEntries) {
            LoggingLevel loggingLevel = Logger.getLoggingLevel(flowLogEntry.loggingLevelName);

            LogEntryBuilder logEntryBuilder = Logger.createLogEntryBuilder(loggingLevel)
                .setMessage(flowLogEntry.message)
                .setRecordId(flowLogEntry.recordId)
                .setTopics(flowLogEntry.topics);

            LogEntryEvent__e logEntryEvent = logEntryBuilder.getLogEntryEvent();

            if(logEntryEvent == null) {
                continue;
            }

            logEntryEvent.LoggingLevel__c    = flowLogEntry.loggingLevelName;
            logEntryEvent.OriginLocation__c  = flowLogEntry.flowName;
            logEntryEvent.OriginType__c      = 'Flow';
            logEntryEvent.Timestamp__c       = flowLogEntry.timestamp;

            if(flowLogEntry.saveLog) {
                saveLog = flowLogEntry.saveLog;
            }
        }

        if(saveLog) {
            Logger.saveLog();
        }

        return new List<String>{ Logger.getTransactionId() };
    }

}