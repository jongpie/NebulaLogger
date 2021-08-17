//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Controller classs used by the light web component `c/logger`
 * @see Logger
 * @see LogEntryEventBuilder
 */
public inherited sharing class ComponentLogger {
    @TestVisible
    private static final String EXCEPTION_TYPE_PREFIX = 'JavaScript.';

    /**
     * @description Provides data to the frontend about `LoggerSettings__c` & server-supported logging details
     * @return   return The instance of `ComponentLoggerSettings` for the current user
     */
    @AuraEnabled(cacheable=true)
    public static ComponentLoggerSettings getSettings() {
        return new ComponentLoggerSettings();
    }

    /**
     * @description saveComponentLogEntries Saves log entries created via lwc or aura components
     * @param  componentLogEntries The list of `ComponentLogEntry` objects to save via `Logger`
     * @return                     return The transaction ID (based on `Logger.getTransactionId())`
     */
    @AuraEnabled
    public static String saveComponentLogEntries(List<ComponentLogEntry> componentLogEntries) {
        System.debug('componentLogEntries=' + componentLogEntries);

        try {
            for (ComponentLogEntry componentLogEntry : componentLogEntries) {
                LoggingLevel loggingLevel = Logger.getLoggingLevel(componentLogEntry.loggingLevel);
                LogEntryEventBuilder logEntryEventBuilder = Logger.newEntry(loggingLevel, componentLogEntry.message)
                    .setRecord(componentLogEntry.recordId)
                    .setRecord(componentLogEntry.record)
                    .addTags(componentLogEntry.tags);

                setComponentErrorDetails(logEntryEventBuilder, componentLogEntry.error);
                setStackTraceDetails(logEntryEventBuilder, componentLogEntry.stack);
                if (logEntryEventBuilder.shouldSave() == true) {
                    // Set some additional fields - these fields don't have setter methods in LogEntryEventBuilder

                    logEntryEventBuilder.getLogEntryEvent().Timestamp__c = componentLogEntry.timestamp;
                }
            }
            Logger.saveLog();
            return Logger.getTransactionId();
        } catch (Exception apexException) {
            throw new AuraHandledException(apexException.getMessage());
        }
    }

    private static void setComponentErrorDetails(LogEntryEventBuilder logEntryEventBuilder, ComponentError componentError) {
        if (componentError == null) {
            return;
        }

        logEntryEventBuilder.getLogEntryEvent().ExceptionMessage__c = componentError.message;
        logEntryEventBuilder.getLogEntryEvent().ExceptionStackTrace__c = componentError.stack;
        logEntryEventBuilder.getLogEntryEvent().ExceptionType__c = EXCEPTION_TYPE_PREFIX + componentError.type;
    }

    private static void setStackTraceDetails(LogEntryEventBuilder logEntryEventBuilder, String stackTraceString) {
        String originLocation;
        String originType;
        Boolean isAuraComponent = false;

        if (String.isNotBlank(stackTraceString) == true) {
            String loggerComponentReferenceToIgnore = '/c/logger.js';
            String auraComponentContent = '/n/components/';
            String lwcModuleContent = '/n/modules/';
            Boolean parentComponentFound = false;

            List<String> stackTraceLines = new List<String>();
            for (String currentStackTraceLine : stackTraceString.split('\n')) {
                if (currentStackTraceLine.contains(loggerComponentReferenceToIgnore) == true) {
                    continue;
                } else if (parentComponentFound == false && currentStackTraceLine.contains(auraComponentContent) == true) {
                    isAuraComponent = true;
                    parentComponentFound = true;
                } else if (parentComponentFound == false && currentStackTraceLine.contains(lwcModuleContent) == true) {
                    parentComponentFound = true;
                }

                if (parentComponentFound == true) {
                    stackTraceLines.add(currentStackTraceLine);
                }
            }

            stackTraceString = String.join(stackTraceLines, '\n');
            if (String.isNotBlank(stackTraceString)) {
                String componentName;
                String componentFunction;
                if (isAuraComponent == true) {
                    componentName = stackTraceLines.get(0).substringAfterLast(auraComponentContent).substringBefore('.js');
                    componentFunction = stackTraceLines.get(0).substringBefore(' (').substringAfter('at ');
                } else {
                    componentName = stackTraceLines.get(0).substringAfterLast(lwcModuleContent).substringBefore('.js');
                    componentFunction = stackTraceLines.get(0).substringBefore(' (').substringAfter('at ').substringAfter('.');
                }

                originLocation = componentName + '.' + componentFunction;
            }
        }

        logEntryEventBuilder.getLogEntryEvent().ComponentType__c = isAuraComponent == true ? 'Aura' : 'Web';
        logEntryEventBuilder.getLogEntryEvent().OriginType__c = 'Component';
        logEntryEventBuilder.getLogEntryEvent().OriginLocation__c = originLocation;
        logEntryEventBuilder.getLogEntryEvent().StackTrace__c = truncateFieldValue(Schema.LogEntryEvent__e.StackTrace__c, stackTraceString);
    }

    private static String truncateFieldValue(Schema.SObjectField field, String value) {
        Integer fieldMaxLength = field.getDescribe().getLength();
        if (String.isEmpty(value)) {
            return value;
        } else if (value.length() <= fieldMaxLength) {
            return value;
        }

        return value.left(fieldMaxLength);
    }

    /**
     * @description A DTO object used for passing `LoggerSettings__c` details to lightning components
     */
    public class ComponentLoggerSettings {
        /**
         * @description Indicates if logging is enabled for the current user, based on `Logger.isEnabled()`
         */
        @AuraEnabled
        public Boolean isEnabled { get; set; }

        /**
         * @description A map of the supported `LoggingLevel` enum values
         */
        @AuraEnabled
        public Map<String, Integer> supportedLoggingLevels { get; set; }

        /**
         * @description The configured `LoggingLevel` for the current user, based on `Logger.getUserLoggingLevel()`
         */
        @AuraEnabled
        public ComponentLoggingLevel userLoggingLevel { get; set; }

        private ComponentLoggerSettings() {
            this.isEnabled = Logger.isEnabled();
            this.supportedLoggingLevels = getSupportedLoggingLevels();
            this.userLoggingLevel = getUserLoggingLevel();
        }

        private Map<String, Integer> getSupportedLoggingLevels() {
            return new Map<String, Integer>{
                LoggingLevel.ERROR.name() => LoggingLevel.ERROR.ordinal(),
                LoggingLevel.WARN.name() => LoggingLevel.WARN.ordinal(),
                LoggingLevel.INFO.name() => LoggingLevel.INFO.ordinal(),
                LoggingLevel.DEBUG.name() => LoggingLevel.DEBUG.ordinal(),
                LoggingLevel.FINE.name() => LoggingLevel.FINE.ordinal(),
                LoggingLevel.FINER.name() => LoggingLevel.FINER.ordinal(),
                LoggingLevel.FINEST.name() => LoggingLevel.FINEST.ordinal()
            };
        }

        private ComponentLoggingLevel getUserLoggingLevel() {
            return new ComponentLoggingLevel(Logger.getUserLoggingLevel());
        }
    }

    /**
     * @description A DTO object used for passing `LoggingLevel` details to lightning components
     */
    public class ComponentLoggingLevel {
        /**
         * @description The name of the `LoggingLevel` enum value
         */
        @AuraEnabled
        public String name { get; set; }

        /**
         * @description The ordinal of the `LoggingLevel` enum value
         */
        @AuraEnabled
        public Integer ordinal { get; set; }

        private ComponentLoggingLevel(LoggingLevel loggingLevel) {
            this.name = loggingLevel.name();
            this.ordinal = loggingLevel.ordinal();
        }
    }

    /**
     * @description A DTO object used to create log entries for lightning components
     */
    public class ComponentLogEntry {
        /**
         * @description The name of the `LoggingLevel` enum value
         */
        @AuraEnabled
        public String loggingLevel { get; set; }

        /**
         * @description The value to use as the log entry's message
         */
        @AuraEnabled
        public String message { get; set; }

        /**
         * @description (Optional) The record ID to relate to the log entry
         */
        @AuraEnabled
        public Id recordId { get; set; }

        /**
         * @description (Optional) The record to relate to the log entry - the record's JSON is also stored
         */
        @AuraEnabled
        public SObject record { get; set; }

        /**
         * @description The JavaScript stack trace from when the log entry was created
         */
        @AuraEnabled
        public String stack { get; set; }

        /**
         * @description The datetime that the log entry was created in the lightning component
         */
        @AuraEnabled
        public Datetime timestamp { get; set; }

        /**
         * @description (Optional) A JavaScript Error to log
         */
        @AuraEnabled
        public ComponentError error { get; set; }

        /**
         * @description (Optional) A list of tags to associate with the log entry
         */
        @AuraEnabled
        public List<String> tags { get; set; }
    }

    /**
     * @description A DTO object used to log details about a JavaScript error
     */
    public class ComponentError {
        /**
         * @description The error's message
         */
        @AuraEnabled
        public String message { get; set; }

        /**
         * @description The error's stack trace
         */
        @AuraEnabled
        public String stack { get; set; }

        /**
         * @description The type of JavaScript error
         */
        @AuraEnabled
        public String type { get; set; }
    }
}
