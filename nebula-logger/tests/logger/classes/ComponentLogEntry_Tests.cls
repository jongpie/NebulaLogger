/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
@isTest
private class ComponentLogEntry_Tests {
    static ComponentLogEntry createComponentLogEntry() {
        ComponentLogEntry cmpLogEntry = new ComponentLogEntry();
        cmpLogEntry.message = 'my test message';
        cmpLogEntry.componentName = 'myLightningComponent';
        cmpLogEntry.originLocation = 'helper.myFunction';
        cmpLogEntry.timestamp = System.now();

        return cmpLogEntry;
    }

    @testSetup
    static void setup() {
        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c = true;
        upsert settings;
    }

    @isTest
    static void it_should_not_save_entry_when_logging_level_not_met() {
        String userLoggingLevel = 'ERROR';
        String cmpLogEntryLoggingLevel = 'DEBUG';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        List<ComponentLogEntry> componentLogEntries = new List<ComponentLogEntry>();
        ComponentLogEntry cmpLogEntry = createComponentLogEntry();
        cmpLogEntry.loggingLevelName = cmpLogEntryLoggingLevel;

        ComponentLogEntry.saveComponentLogEntries(new List<ComponentLogEntry>{ cmpLogEntry });
        Logger.saveLog();

        Test.stopTest();

        List<LogEntry__c> logEntries = [SELECT Id, Message__c, OriginType__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(0, logEntries.size());
    }

    @isTest
    static void it_should_save_debug_entry_when_logging_level_met() {
        String userLoggingLevel = 'FINEST';
        String cmpLogEntryLoggingLevel = 'DEBUG';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        List<ComponentLogEntry> componentLogEntries = new List<ComponentLogEntry>();
        ComponentLogEntry cmpLogEntry = createComponentLogEntry();
        cmpLogEntry.loggingLevelName = cmpLogEntryLoggingLevel;
        ComponentLogEntry.saveComponentLogEntries(new List<ComponentLogEntry>{ cmpLogEntry });
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [
            SELECT Id, ContextLightningComponentName__c, Message__c, OriginType__c, OriginLocation__c
            FROM LogEntry__c
            ORDER BY CreatedDate
            LIMIT 1
        ];
        System.assertEquals(cmpLogEntry.message, logEntry.Message__c);
        System.assertEquals('Component', logEntry.OriginType__c);
        System.assertEquals(cmpLogEntry.componentName, logEntry.ContextLightningComponentName__c);
        System.assertEquals(cmpLogEntry.originLocation, logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_save_exception_entry_when_logging_level_met() {
        String userLoggingLevel = 'FINEST';
        String cmpLogEntryLoggingLevel = 'ERROR';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        List<ComponentLogEntry> componentLogEntries = new List<ComponentLogEntry>();
        ComponentLogEntry cmpLogEntry = createComponentLogEntry();
        cmpLogEntry.loggingLevelName = cmpLogEntryLoggingLevel;

        cmpLogEntry.error = new ComponentLogEntry.Error();
        cmpLogEntry.error.columnNumber = 1;
        cmpLogEntry.error.lineNumber = 4;
        cmpLogEntry.error.message = 'my error message';
        cmpLogEntry.error.stack = 'my stack trace\nsome more details';

        ComponentLogEntry.saveComponentLogEntries(new List<ComponentLogEntry>{ cmpLogEntry });
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [
            SELECT
                Id,
                ContextLightningComponentName__c,
                Message__c,
                OriginType__c,
                OriginLocation__c,
                ExceptionStackTrace__c,
                ExceptionType__c
            FROM LogEntry__c
            ORDER BY CreatedDate
            LIMIT 1
        ];
        System.assertEquals(cmpLogEntry.message, logEntry.Message__c);
        System.assertEquals('Component', logEntry.OriginType__c);
        System.assertEquals(cmpLogEntry.componentName, logEntry.ContextLightningComponentName__c);
        System.assertEquals(cmpLogEntry.originLocation, logEntry.OriginLocation__c);
        System.assertEquals('ComponentLogEntryException', logEntry.ExceptionType__c);
        System.assertEquals(cmpLogEntry.error.stack, logEntry.ExceptionStackTrace__c);
    }
}
