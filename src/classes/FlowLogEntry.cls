/*************************************************************************************************
* This file is part of the Nebula Framework project, released under the MIT License.             *
* See LICENSE file or go to https://github.com/jongpie/NebulaFramework for full license details. *
*************************************************************************************************/
public without sharing class FlowLogEntry {

    @InvocableMethod(label='Add Log Entry' description='Creates a log entry for a process builder or flow')
    public static void addFlowEntries(List<FlowLogEntry> flowLogEntries) {
        Logger.addFlowEntries(flowLogEntries);
    }

    @InvocableVariable(required=true label='Process Builder/Flow Name')
    public String flowName;

    @InvocableVariable(required=true label='Log Entry Message')
    public String message;

    @InvocableVariable(required=true label='Save Log')
    public Boolean saveLog;

    @InvocableVariable(label='(Optional) Logging Level')
    public String loggingLevelName;

    @InvocableVariable(label='(Optional) Topics')
    public List<String> topics;

    public DateTime timestamp;

    public FlowLogEntry() {
        this.saveLog   = true;
        this.timestamp = System.now();
    }

}