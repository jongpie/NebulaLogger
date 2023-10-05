//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Handles adding new log entries in Flow for a particular `SObject` record
 * @see FlowLogEntry
 * @see FlowCollectionLogEntry
 * @see FlowLogger
 * @see Logger
 * @see LogEntryEventBuilder
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class FlowRecordLogEntry {
    /**
     * @description The API name of the Flow creating the log entry.
     *   Due to Salesforce limitations, this cannot be automatically determined
     */
    @InvocableVariable(required=true label='Flow API Name')
    global String flowName;

    /**
     * @description The message to log
     */
    @InvocableVariable(required=true label='Log Entry Message')
    global String message;

    /**
     * @description The record to relate to this log entry - the record's JSON is automatically added to the log entry
     */
    @InvocableVariable(required=false label='Record')
    global SObject record;

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

    public DateTime timestamp = System.now();

    /**
     * @description Invocable method for adding record entries via flow or process builder
     * @param flowRecordLogEntries The list of FlowRecordLogEntry instances to save
     * @return The current transaction's ID (based on `Logger.getTransactionId()`)
     */
    @InvocableMethod(
        category='Logging'
        label='Add Log Entry for an SObject Record'
        description='Creates a log entry for a flow or process builder and stores the record as JSON'
    )
    global static List<String> addFlowRecordEntries(List<FlowRecordLogEntry> flowRecordLogEntries) {
        List<FlowLogger.LogEntry> shadowLogEntries = new List<FlowLogger.LogEntry>();
        for (FlowRecordLogEntry flowRecordLogEntry : flowRecordLogEntries) {
            FlowLogger.LogEntry shadowLogEntry = (FlowLogger.LogEntry) JSON.deserialize(JSON.serialize(flowRecordLogEntry), FlowLogger.LogEntry.class);
            shadowLogEntry.addToLoggerBuffer()?.setRecord(flowRecordLogEntry.record);

            shadowLogEntries.add(shadowLogEntry);
        }

        return FlowLogger.addEntries(shadowLogEntries);
    }
}
