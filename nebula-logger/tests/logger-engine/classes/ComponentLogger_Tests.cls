//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@isTest
private class ComponentLogger_Tests {
    @isTest
    static void it_should_return_logger_settings() {
        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.IsEnabled__c = true;
        loggerSettings.LoggingLevel__c = 'FINEST';
        upsert loggerSettings;

        Test.startTest();
        ComponentLogger.ComponentLoggerSettings componentLoggerSettings = ComponentLogger.getSettings();
        Test.stopTest();

        System.assertEquals(loggerSettings.IsEnabled__c, componentLoggerSettings.isEnabled);
        System.assertEquals(loggerSettings.LoggingLevel__c, componentLoggerSettings.userLoggingLevel.name);

        LoggingLevel userLoggingLevel = Logger.getLoggingLevel(loggerSettings.LoggingLevel__c);
        System.assertEquals(userLoggingLevel.name(), componentLoggerSettings.userLoggingLevel.name);
        System.assertEquals(userLoggingLevel.ordinal(), componentLoggerSettings.userLoggingLevel.ordinal);

        for(LoggingLevel currentLoggingLevel : LoggingLevel.values()) {
            // We don't care about logging level NONE, or the secret/undocumented INTERNAL logging level
            if(currentLoggingLevel == LoggingLevel.NONE || currentLoggingLevel == LoggingLevel.INTERNAL) {
                continue;
            }

            System.assert(componentLoggerSettings.supportedLoggingLevels.containsKey(currentLoggingLevel.name()), 'Cmp settings did not contain level: ' + currentLoggingLevel);

            Integer returnedOrdinal = componentLoggerSettings.supportedLoggingLevels.get(currentLoggingLevel.name());
            System.assertEquals(currentLoggingLevel.ordinal(), returnedOrdinal);
        }
    }

    @isTest
    static void it_should_return_save_componentLogEntries() {
        upsert LoggerSettings__c.getInstance();
        System.assertEquals(0, [SELECT COUNT() FROM Log__c]);

        List<ComponentLogger.ComponentLogEntry> componentLogEntries = new List<ComponentLogger.ComponentLogEntry>();

        User currentUser = new User(FirstName = UserInfo.getFirstName(), Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());

        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.recordId = currentUser.Id;
        componentLogEntry.record = currentUser;
        componentLogEntry.timestamp = System.now().addDays(- 1 / 24);
        componentLogEntry.tags = new List<String>{'some tag', 'one more tag'};

        componentLogEntries.add(componentLogEntry);

        Test.startTest();
        ComponentLogger.saveComponentLogEntries(componentLogEntries);
        Test.stopTest();

        List<LogEntry__c> logEntries = [SELECT Id, LoggingLevel__c, Message__c, RecordId__c, RecordJson__c, RecordSObjectType__c, Timestamp__c FROM LogEntry__c];
        System.assertEquals(1, logEntries.size());

        LogEntry__c logEntry = logEntries.get(0);

        System.assertEquals(componentLogEntry.loggingLevel, logEntry.LoggingLevel__c);
        System.assertEquals(componentLogEntry.message, logEntry.Message__c);
        System.assertEquals(componentLogEntry.recordId, logEntry.RecordId__c);
        System.assertEquals(JSON.serializePretty(currentUser), logEntry.RecordJson__c);
        System.assertEquals(Schema.SObjectType.User.getName(), logEntry.RecordSObjectType__c);
        System.assertEquals(componentLogEntry.timestamp, logEntry.Timestamp__c);
    }

    @isTest
    static void it_should_return_aura_exception_when_it_breaks() {
        Test.startTest();
        try {
            ComponentLogger.saveComponentLogEntries(null);
            System.assert(false, 'This assert shouldn\'t run since this is a negative test');
        } catch(Exception apexException) {
            System.assertEquals(AuraHandledException.class.getName(), apexException.getTypeName());
        }
        Test.stopTest();
    }

}
