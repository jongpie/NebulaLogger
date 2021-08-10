//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

public inherited sharing class ComponentLogger {
    @AuraEnabled(cacheable=true)
    public static LoggerSettings getSettings() {
        return new LoggerSettings();
    }

    @AuraEnabled
    public static String saveComponentLogEntries(List<ComponentLogEntry> componentLogEntries) {
        System.debug('componentLogEntries=' + componentLogEntries);

        try {
            for (ComponentLogEntry componentLogEntry : componentLogEntries) {
                LoggingLevel loggingLevel = Logger.getLoggingLevel(componentLogEntry.loggingLevel);
                LogEntryEventBuilder logEntryEventBuilder = Logger.newEntry(loggingLevel, componentLogEntry.message)
                    .setRecord(componentLogEntry.recordId)
                    .setRecord(componentLogEntry.record)
                    .parseStackTrace(componentLogEntry.stack)
                    .addTags(componentLogEntry.tags);

                // Set some additional fields - these fields don't have setter methods
                logEntryEventBuilder.getLogEntryEvent().OriginType__c = 'Component';
                logEntryEventBuilder.getLogEntryEvent().Timestamp__c = componentLogEntry.timestamp;
            }
            Logger.saveLog();
            return Logger.getTransactionId();
        } catch (Exception apexException) {
            throw new AuraHandledException(apexException.getMessage());
        }
    }

    public class LoggerSettings {
        @AuraEnabled
        public Boolean isEnabled { get; set; }
        @AuraEnabled
        public Map<String, Integer> supportedLoggingLevels { get; set; }
        @AuraEnabled
        public ComponentLoggingLevel userLoggingLevel { get; set; }

        private LoggerSettings() {
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

    public class ComponentLoggingLevel {
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public Integer ordinal { get; set; }

        private ComponentLoggingLevel(LoggingLevel loggingLevel) {
            this.name = loggingLevel.name();
            this.ordinal = loggingLevel.ordinal();
        }
    }

    public class ComponentLogEntry {
        @AuraEnabled
        public String loggingLevel { get; set; }
        @AuraEnabled
        public String message { get; set; }
        @AuraEnabled
        public Id recordId { get; set; }
        @AuraEnabled
        public SObject record { get; set; }
        @AuraEnabled
        public String stack { get; set; }
        @AuraEnabled
        public Datetime timestamp { get; set; }
        // @AuraEnabled
        // public ComponentError componentError { get; set; }
        @AuraEnabled
        public List<String> tags { get; set; }
    }

    // public class ComponentError {
    //     public Integer columnNumber;
    //     public Integer fileName;
    //     public Integer lineNumber;
    //     public Integer message;
    //     public Integer stack;
    // }
}
