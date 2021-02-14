public inherited sharing class LoggerComponentController {
    private LoggerComponentController() {
    }

    @AuraEnabled(cacheable=true)
    public static LoggerSettings getLoggerSettings() {
        try {
            return new LoggerSettings();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void addComponentEntries(List<ComponentLogEntry> componentLogEntries) {
        try {
            for (ComponentLogEntry componentLogEntry : componentLogEntries) {
                LoggingLevel loggingLevel = Logger.getLoggingLevel(componentLogEntry.loggingLevel);

                LogEntryEventBuilder logEntryBuilder = Logger.newEntry(loggingLevel)
                    .setMessage(componentLogEntry.message)
                    .setRecordId(componentLogEntry.recordId)
                    .setRecordId(componentLogEntry.record)
                    .parseStackTrace(componentLogEntry.stackTrace)
                    .setTopics(componentLogEntry.topics);

                LogEntryEvent__e logEntryEvent = logEntryBuilder.getLogEntryEvent();

                if (logEntryEvent == null) {
                    continue;
                }

                // TODO populate OriginLocation__c
                // logEntryEvent.OriginLocation__c = flowRecordLogEntry.flowName;
                logEntryEvent.OriginType__c = 'Component';
                logEntryEvent.Timestamp__c = componentLogEntry.timestamp;
            }
        } catch (Exception apexException) {
            throw new AuraHandledException(apexException.getMessage());
        }
    }

    @AuraEnabled
    public static void saveLog() {
        try {
            Logger.saveLog();
        } catch (Exception apexException) {
            throw new AuraHandledException(apexException.getMessage());
        }
    }

    public class LoggerSettings {
        @AuraEnabled
        public Boolean isEnabled { get; set; }
        @AuraEnabled
        public String userLoggingLevel { get; set; }
        @AuraEnabled
        public List<String> enabledLoggingLevels { get; set; }
        @AuraEnabled
        private LoggerSettings() {
            this.isEnabled = Logger.isEnabled();
            this.enabledLoggingLevels = getEnabledLoggingLevels();
            this.userLoggingLevel = Logger.getUserLoggingLevel().name();
        }

        private List<String> getEnabledLoggingLevels() {
            List<String> enabledLevels = new List<String>();
            for (LoggingLevel loggingLevel : LoggingLevel.values()) {
                if (Logger.isEnabled(loggingLevel)) {
                    enabledLevels.add(loggingLevel.name());
                }
            }
        }
    }

    public class ComponentLogEntry {
        @AuraEnabled
        public String loggingLevel { get; set; }
        @AuraEnabled
        public String message { get; set; }
        @AuraEnabled
        public String recordId { get; set; }
        @AuraEnabled
        public SObject record { get; set; }
        @AuraEnabled
        public String stackTrace { get; set; }
        @AuraEnabled
        public Datetime timestamp { get; set; }
        @AuraEnabled
        public List<String> topics { get; set; }

        private ComponentLogEntry() {
        }
    }
}
