public inherited sharing class ComponentLogController {
    // TODO cleanup this class & inner classes, it's a mess
    public class ComponentLoggerSettings {
        @AuraEnabled
        public Boolean isEnabled { get; set; }
        @AuraEnabled
        public Map<String, Integer> supportedLoggingLevels { get; set; }
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
    public static ComponentLoggerSettings getSettings() {
        try {
            return new ComponentLoggerSettings();
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

                if (logEntryEventBuilder.shouldSave()) {
                    if (componentLogEntry.recordId != null) {
                        logEntryEventBuilder.setRecordId(componentLogEntry.recordId);
                    }
                    if (componentLogEntry.record != null) {
                        logEntryEventBuilder.setRecordId(componentLogEntry.record);
                    }
                    if (componentLogEntry.topics != null) {
                        logEntryEventBuilder.setTopics(componentLogEntry.topics);
                    }

                    logEntryEventBuilder.getLogEntryEvent().OriginType__c = 'Component';
                    logEntryEventBuilder.parseStackTrace(componentLogEntry.stack);
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
