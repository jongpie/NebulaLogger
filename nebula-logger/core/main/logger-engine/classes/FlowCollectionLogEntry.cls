//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Handles adding new log entries in Flow for a particular `SObject` record collection
 * @see FlowLogEntry
 * @see FlowRecordLogEntry
 * @see FlowLogger
 * @see Logger
 * @see LogEntryEventBuilder
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class FlowCollectionLogEntry {
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
     * @description The records to relate to this log entry - the records' JSON is automatically added to the log entry
     */
    @InvocableVariable(required=false label='Records')
    global List<SObject> records;

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

    /**
     * @description Represents the current system time
     */
    public DateTime timestamp = System.now();

    /**
     * @description Invocable method for adding LogEntry records via flow or process builder
     * @param  flowCollectionLogEntries The list of FlowRecordLogEntry instances to save
     * @return The current transaction's ID (based on `Logger.getTransactionId()`)
     */
    @InvocableMethod(
        category='Logging'
        label='Add Log Entry for an SObject Record Collection'
        description='Creates a log entry for a flow or process builder and stores the record list as JSON'
    )
    global static List<String> addFlowCollectionEntries(List<FlowCollectionLogEntry> flowCollectionLogEntries) {
        List<FlowLogger.LogEntry> shadowLogEntries = new List<FlowLogger.LogEntry>();
        for (FlowCollectionLogEntry flowCollectionLogEntry : flowCollectionLogEntries) {
            FlowLogger.LogEntry shadowLogEntry = (FlowLogger.LogEntry) JSON.deserialize(JSON.serialize(flowCollectionLogEntry), FlowLogger.LogEntry.class);
            LogEntryEventBuilder builder = shadowLogEntry.addToLoggerBuffer()?.setRecord(flowCollectionLogEntry.records);
            if (builder.shouldSave() && flowCollectionLogEntry.records?.size() > 0) {
                builder.getLogEntryEvent().RecordSObjectType__c = flowCollectionLogEntry.records.get(0).getSObjectType().getDescribe().getName();
            }

            shadowLogEntries.add(shadowLogEntry);
        }

        return FlowLogger.addEntries(shadowLogEntries);
    }
}
