//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Handles adding new log entries in Flow
 * @see FlowRecordLogEntry
 * @see FlowCollectionLogEntry
 * @see FlowLogger
 * @see Logger
 * @see LogEntryEventBuilder
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class FlowLogEntry {
    /**
     * @description The API name of the Flow creating the log entry.
     *   Due to Salesforce limitations, this cannot be automatically determined.
     */
    @InvocableVariable(required=true label='Flow API Name')
    global String flowName;

    /**
     * @description The message to log
     */
    @InvocableVariable(required=true label='Log Entry Message')
    global String message;

    /**
     * @description Optionally specify a logging level - the default is 'DEBUG'
     */
    @InvocableVariable(required=false label='(Optional) Logging Level')
    global String loggingLevelName;

    /**
     * @description Optionally log a Flow fault error message
     */
    @InvocableVariable(required=false label='(Optional) Flow Fault Error Message')
    global String faultMessage;

    /**
     * @description Optionally rollback Database operations executed until Apex action was called and save the log entry.
     */
    @InvocableVariable(required=false label='(Optional) Throw FlowException for Fault Error Message')
    global Boolean shouldThrowFaultMessageException = false;

    /**
     * @description Optionally choose to save any pending log entries
     */
    @InvocableVariable(required=false label='(Optional) Save Log')
    global Boolean saveLog = false;

    /**
     * @description Optionally choose the save method to use when 'Save Log' is true
     */
    @InvocableVariable(required=false label='(Optional) Save Method')
    global String saveMethodName;

    /**
     * @description Optionally relate the log entry to a particular record ID
     */
    @InvocableVariable(required=false label='(Optional) Record ID')
    global Id recordId;

    /**
     * @description Optionally specify the name to use for the current transaction's scenario
     */
    @InvocableVariable(required=false label='(Optional) Scenario')
    global String scenario;

    /**
     * @description Optionally provide a comma-separated String of tags to dynamically assign to the log entry
     */
    @InvocableVariable(required=false label='(Optional) Tags (comma-separated)')
    global String tagsString;

    /**
     * @description Optionally provide a comma-separated String of tags to dynamically assign to the log entry
     */
    @InvocableVariable(required=false label='DEPRECATED: Use \'Tags\' Instead')
    public List<String> topics;

    /**
     * @description Current system timestamp.
     */
    public DateTime timestamp = System.now();

    /**
     * @description Invocable method, that can be called via flow.
     * @param flowLogEntries The list of FlowLogEntry instances to save
     * @return The current transaction's ID (based on `Logger.getTransactionId()`)
     */
    @InvocableMethod(category='Logging' label='Add Log Entry' description='Creates a log entry for a flow or process builder')
    global static List<String> addFlowEntries(List<FlowLogEntry> flowLogEntries) {
        List<FlowLogger.LogEntry> shadowLogEntries = new List<FlowLogger.LogEntry>();
        for (FlowLogEntry flowLogEntry : flowLogEntries) {
            FlowLogger.LogEntry shadowLogEntry = (FlowLogger.LogEntry) JSON.deserialize(JSON.serialize(flowLogEntry), FlowLogger.LogEntry.class);
            shadowLogEntry.addToLoggerBuffer()?.setRecordId(flowLogEntry.recordId);

            shadowLogEntries.add(shadowLogEntry);
        }

        return FlowLogger.addEntries(shadowLogEntries);
    }
}
