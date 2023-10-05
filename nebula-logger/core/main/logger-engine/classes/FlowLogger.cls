//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Handles some common logic used by `FlowLogEntry`, `FlowRecordLogEntry` and `FlowCollectionLogEntry`
 * @see FlowLogEntry
 * @see FlowRecordLogEntry
 * @see FlowCollectionLogEntry
 * @see Logger
 * @see LogEntryEventBuilder
 */
public inherited sharing class FlowLogger {
    private static final String FLOW_EXCEPTION_TYPE_NAME = 'Flow.FaultError';
    @TestVisible
    private static final String FLOW_FAULT_ERROR_DEFAULT_EXCEPTION_MESSAGE = 'An unknown Flow exception has occurred';

    static {
        Logger.ignoreOrigin(FlowLogger.class);
    }

    // Invocable methods and properties are goofy, but we can be goofier
    // Properties goofiness: you can’t keep common properties in a parent class & extend properties in other classes,
    //                       which also causes issues with sharing logic between classes (via abstract and virtual classes)
    // +3 goofiness points: if we duplicate properties between classes, we can convert all other classes
    //                      to one common class (FlowLogger.LogEntry), and use it for shared logic.
    //                      For maximum goofiness, the conversion between classes happens using JSON.deserialize()
    /**
     * @description Inner, wrapper class containing Log Entry information.
     */
    public class LogEntry {
        // Public member variables - all other Flow classes should duplicate these public variables

        /**
         * @description API name of the flow
         */
        public String flowName;

        /**
         * @description General message to log
         */
        public String message;

        /**
         * @description String name of the entry's logging level
         */
        public String loggingLevelName;

        /**
         * @description String containing fault message, if applicable
         */
        public String faultMessage;

        /**
         * @description Optionally throws an exception when value is set to True (Use it on Fault connectors of your flow).
         */
        public Boolean shouldThrowFaultMessageException = false;

        /**
         * @description Optionally specify the scenario to use for the current transaction
         */
        @InvocableVariable(required=false label='(Optional) Scenario')
        public String scenario;

        /**
         * @description Comma-separated string of tags
         */
        public String tagsString;

        /**
         * @description List of tags / topics
         */
        public List<String> topics; // TODO: deprecated, remove in a future release

        /**
         * @description Boolean used to determine if logs are saved to Salesforce
         */
        public Boolean saveLog = false;

        /**
         * @description String name of the instance of Logger.SaveMethod to use when 'Save Log' is set to `true`
         */
        public String saveMethodName;

        /**
         * @description timestamp of the log
         */
        public DateTime timestamp;

        // Private member variables
        private System.LoggingLevel entryLoggingLevel;
        private LogEntryEventBuilder logEntryEventBuilder;
        private LogEntryEvent__e logEntryEvent;

        /**
         * @description Adds the logger to the buffer
         * @return An instance of LogEntryEventBuilder
         */
        public LogEntryEventBuilder addToLoggerBuffer() {
            if (this.logEntryEventBuilder != null) {
                return this.logEntryEventBuilder;
            }

            // Set the logging level if it's blank
            if (String.isBlank(this.loggingLevelName)) {
                if (String.isNotBlank(this.faultMessage)) {
                    this.loggingLevelName = System.LoggingLevel.ERROR.name();
                } else {
                    this.loggingLevelName = System.LoggingLevel.DEBUG.name();
                }
            }

            // In Flow, using comma-separated String is easier than List<String>
            // but LogEntryEventBuilder.addTags() uses List<String>, so FlowLogger handles the conversion work
            List<String> parsedTags = this.tagsString?.replaceAll('( ,)|(,)|(, )', ',').split(',');

            Logger.setScenario(this.scenario);
            this.entryLoggingLevel = Logger.getLoggingLevel(this.loggingLevelName);
            this.logEntryEventBuilder = Logger.newEntry(this.entryLoggingLevel, this.message).addTags(this.topics).addTags(parsedTags);

            if (this.logEntryEventBuilder.shouldSave() == false) {
                return this.logEntryEventBuilder;
            }

            this.logEntryEvent = logEntryEventBuilder.getLogEntryEvent();
            this.logEntryEvent.OriginLocation__c = this.flowName;
            this.logEntryEvent.OriginType__c = 'Flow';
            this.logEntryEvent.StackTrace__c = null;
            this.logEntryEvent.Timestamp__c = this.timestamp;

            if (String.isNotBlank(this.faultMessage)) {
                this.logEntryEvent.ExceptionMessage__c = this.faultMessage;
                this.logEntryEvent.ExceptionType__c = FLOW_EXCEPTION_TYPE_NAME;
            }

            return this.logEntryEventBuilder;
        }
    }

    // Static methods

    /**
     * @description Adds logging entries
     * @param flowEntries The log entry instances to add.
     * @return A list of transaction ids.
     */
    public static List<String> addEntries(List<LogEntry> flowEntries) {
        Boolean saveLog = false;
        Logger.SaveMethod saveMethod = Logger.getSaveMethod();
        Boolean shouldThrowFaultMessageException = false;
        String faultMessage = FLOW_FAULT_ERROR_DEFAULT_EXCEPTION_MESSAGE;

        for (LogEntry flowEntry : flowEntries) {
            flowEntry.addToLoggerBuffer();

            if (flowEntry.saveLog) {
                saveLog = flowEntry.saveLog;
                if (String.isNotBlank(flowEntry.saveMethodName)) {
                    saveMethod = Logger.SaveMethod.valueOf(flowEntry.saveMethodName);
                }
            }
            if (String.isNotBlank(flowEntry.faultMessage)) {
                faultMessage = flowEntry.faultMessage;
            }
            if (flowEntry.shouldThrowFaultMessageException) {
                shouldThrowFaultMessageException = flowEntry.shouldThrowFaultMessageException;
            }
        }

        if (saveLog) {
            Logger.saveLog(saveMethod);
        }

        // Here we throw an exception so we stop synchronous database updates from happening,
        // avoiding inconsistencies in the data
        if (shouldThrowFaultMessageException) {
            Logger.saveLog(Logger.SaveMethod.EVENT_BUS);
            throw new System.FlowException(faultMessage);
        }

        return setTransactionIds(flowEntries.size());
    }

    private static List<String> setTransactionIds(Integer size) {
        // Event though it's the same transaction ID, Salesforce expects the returned list...
        // to have the same number of items as the initial input.
        // When there's a mismatch, Salesforce throws an error:
        // FLOW_ELEMENT_ERROR The number of results does not match the number of interviews that were executed in a single bulk execution request.|FlowActionCall
        List<String> transactionIds = new List<String>();
        for (Integer i = 0; i < size; i++) {
            transactionIds.add(Logger.getTransactionId());
        }
        return transactionIds;
    }
}
