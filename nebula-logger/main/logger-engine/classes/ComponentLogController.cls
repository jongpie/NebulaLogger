public inherited sharing class ComponentLogController {
    public class ComponentLogEntry {
        @AuraEnabled
        public String componentName { get; set; }
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

        private ComponentLogEntry() {
        }
    }

    public class ComponentError {
        public Integer columnNumber;
        public Integer fileName;
        public Integer lineNumber;
        public Integer message;
        public Integer stack;

        private ComponentError() {
        }
    }

    @AuraEnabled
    public static String saveComponentLogEntries(List<ComponentLogEntry> componentLogEntries) {
        try {
            for (ComponentLogEntry componentLogEntry : componentLogEntries) {
                LoggingLevel loggingLevel = Logger.getLoggingLevel(componentLogEntry.loggingLevel);

                LogEntryEventBuilder logEntryEventBuilder = Logger.createLogEntryEventBuilder(loggingLevel)
                    .setMessage(componentLogEntry.message)
                    .setRecordId(componentLogEntry.recordId)
                    .setRecordId(componentLogEntry.record)
                    .parseStackTrace(componentLogEntry.stack)
                    .setTopics(componentLogEntry.topics);

                if (logEntryEventBuilder.shouldSave()) {
                    logEntryEventBuilder.getLogEntryEvent().OriginLocation__c = componentLogEntry.componentName;
                    logEntryEventBuilder.getLogEntryEvent().OriginType__c = 'Component';
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
