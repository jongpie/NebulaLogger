public inherited sharing class ComponentLogController {
    // TODO cleanup this class & inner classes, it's a mess
    public class LoggingLevelDto {
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public Integer ordinal { get; set; }

        private LoggingLevelDto(LoggingLevel loggingLevel) {
            this.name = loggingLevel.name();
            this.ordinal = loggingLevel.ordinal();
        }
    }

    public class LoggerSettingsDto {
        @AuraEnabled
        public Boolean isEnabled { get; set; }
        @AuraEnabled
        public LoggingLevelDto userLoggingLevel { get; set; }

        private LoggerSettingsDto() {
            this.isEnabled = Logger.isEnabled();
            this.userLoggingLevel = getUserLoggingLevel();
        }

        private LoggingLevelDto getUserLoggingLevel() {
            // return new Map<String, Integer>{
            //     Logger.getUserLoggingLevel().name() => Logger.getUserLoggingLevel().ordinal()
            // };
            return new LoggingLevelDto(Logger.getUserLoggingLevel());
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
        @AuraEnabled
        public ComponentError componentError { get; set; }
        @AuraEnabled
        public List<String> topics { get; set; }
    }

    public class ComponentError {
        public Integer columnNumber;
        public Integer fileName;
        public Integer lineNumber;
        public Integer message;
        public Integer stack;
    }

    @AuraEnabled(cacheable=true)
    public static LoggerSettingsDto getSettings() {
        try {
            return new LoggerSettingsDto();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String saveComponentLogEntries(List<ComponentLogEntry> componentLogEntries) {
        System.debug('componentLogEntries=' + componentLogEntries);

        try {
            for (ComponentLogEntry componentLogEntry : componentLogEntries) {
                LoggingLevel loggingLevel = Logger.getLoggingLevel(componentLogEntry.loggingLevel);

                LogEntryEventBuilder logEntryEventBuilder = Logger.createLogEntryEventBuilder(loggingLevel)
                    .setMessage(componentLogEntry.message);
                    // .setRecordId(componentLogEntry.recordId)
                    // .setRecordId(componentLogEntry.record)
                    //.setTopics(componentLogEntry.topics);

                if (logEntryEventBuilder.shouldSave()) {
                    logEntryEventBuilder.getLogEntryEvent().OriginType__c = 'Component';
                    //logEntryEventBuilder.parseStackTrace(componentLogEntry.stack);
                    logEntryEventBuilder.getLogEntryEvent().Timestamp__c = componentLogEntry.timestamp;
                }
            }
            Logger.saveLog();
            return Logger.getTransactionId();
        } catch (Exception apexException) {
            throw new AuraHandledException(apexException.getMessage());
        }
    }
}
