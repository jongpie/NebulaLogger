/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
global without sharing class ComponentLogEntry {
    @AuraEnabled
    global String componentName { get; set; }
    @AuraEnabled
    global String loggingLevelName { get; set; }
    @AuraEnabled
    global String message { get; set; }
    @AuraEnabled
    global Error error { get; set; }
    @AuraEnabled
    global String originLocation { get; set; }
    @AuraEnabled
    global Datetime timestamp { get; set; }
    @AuraEnabled
    global List<String> topics { get; set; }

    global class Error {
        @AuraEnabled
        global Integer columnNumber { get; set; }
        @AuraEnabled
        global Integer lineNumber { get; set; }
        @AuraEnabled
        global String message { get; set; }
        @AuraEnabled
        global String stack { get; set; }
    }

    @AuraEnabled
    global static void saveComponentLogEntries(List<ComponentLogEntry> componentLogEntries) {
        for (ComponentLogEntry componentLogEntry : componentLogEntries) {
            LoggingLevel loggingLevel = Logger.getLoggingLevel(componentLogEntry.loggingLevelName);

            LogEntryBuilder logEntryBuilder = Logger.createLogEntryBuilder(loggingLevel)
                .setMessage(componentLogEntry.message)
                .setTopics(componentLogEntry.topics);

            if (componentLogEntry.error != null) {
                logEntryBuilder.setExceptionDetails('ComponentLogEntryException', componentLogEntry.error.stack);
            }

            LogEntryEvent__e logEntryEvent = logEntryBuilder.getLogEntryEvent();

            if (logEntryEvent == null) {
                continue;
            }

            logEntryEvent.ContextIsLightningComponent__c = componentLogEntry.componentName != null;
            logEntryEvent.ContextLightningComponentName__c = componentLogEntry.componentName;
            logEntryEvent.LoggingLevel__c = componentLogEntry.loggingLevelName;
            logEntryEvent.OriginLocation__c = componentLogEntry.originLocation;
            logEntryEvent.OriginType__c = 'Component';
            logEntryEvent.Timestamp__c = componentLogEntry.timestamp;
        }

        Logger.saveLog();
    }
}
