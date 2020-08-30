/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class FlowLogEntry {

    @InvocableVariable(required=true label='Process Builder/Flow Name')
    public String flowName;

    @InvocableVariable(required=true label='Log Entry Message')
    public String message;

    @InvocableVariable(required=true label='Save Log')
    public Boolean saveLog = true;

    @InvocableVariable(label='(Optional) Record ID')
    public Id recordId;

    @InvocableVariable(label='(Optional) Logging Level')
    public String loggingLevelName = 'DEBUG';

    @InvocableVariable(label='(Optional) Topics')
    public List<String> topics;

    @InvocableVariable(label='(Optional) Timestamp')
    public DateTime timestamp = System.now();

    @InvocableMethod(label='Add Log Entry' description='Creates a log entry for a process builder or flow')
    public static void addFlowEntries(List<FlowLogEntry> flowLogEntries) {
        Boolean saveLog = false;
        for(FlowLogEntry flowLogEntry : flowLogEntries) {
            LoggingLevel loggingLevel = Logger.getLoggingLevel(flowLogEntry.loggingLevelName);

            Logger.createLogEntryBuilder(loggingLevel).parseFlowLogEntry(flowLogEntry);

            if(flowLogEntry.saveLog) saveLog = flowLogEntry.saveLog;
        }
        if(saveLog) Logger.saveLog();
    }

}