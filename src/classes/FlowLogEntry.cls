/*************************************************************************************************
* This file is part of the Nebula Framework project, released under the MIT License.             *
* See LICENSE file or go to https://github.com/jongpie/NebulaFramework for full license details. *
*************************************************************************************************/
public without sharing class FlowLogEntry {

    @InvocableMethod(label='Add Log Entry' description='Stores a log entry for a process builder or flow')
    public static void addFlowEntries(List<FlowLogEntry> flowLogEntries) {
        Logger.addFlowEntries(flowLogEntries);
    }

    @InvocableVariable(required=true label='Process Builder/Flow Name')
    public String FlowName;

    @InvocableVariable(required=true)
    public String Message;

    @InvocableVariable(label='(Optional) Parent Record ID')
    public Id ParentId;

    @InvocableVariable(label='(Optional) Logging Level')
    public String LoggingLevelName;

    public DateTime Timestamp;

    public FlowLogEntry() {
        this.Timestamp        = System.now();
    }

}