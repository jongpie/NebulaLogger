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

    @isTest
    static void it_should_return_save_componentLogEntries() {
        upsert LoggerSettings__c.getInstance();
        System.assertEquals(0, [SELECT COUNT() FROM Log__c]);

        User currentUser = new User(FirstName = UserInfo.getFirstName(), Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());

        List<ComponentLogger.ComponentLogEntry> componentLogEntries = new List<ComponentLogger.ComponentLogEntry>();
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
    static void it_should_parse_component_stack_trace() {
        String expectedComponentApiName = 'c/loggerDemo';
        String expectedComponentFunctionName = 'logInfo';

        List<ComponentLogger.ComponentLogEntry> componentLogEntries = new List<ComponentLogger.ComponentLogEntry>();
        ComponentLogger.ComponentLogEntry componentLogEntry = new ComponentLogger.ComponentLogEntry();
        componentLogEntry.loggingLevel = LoggingLevel.INFO.name();
        componentLogEntry.message = 'hello, world';
        componentLogEntry.stack = getMockComponentStackTrace();
        componentLogEntry.timestamp = System.now().addDays(- 1 / 24);
        componentLogEntries.add(componentLogEntry);

        Test.startTest();
        Logger.getUserSettings().EnableSystemMessages__c = false;
        ComponentLogger.saveComponentLogEntries(componentLogEntries);
        Test.stopTest();

        List<LogEntry__c> logEntries = [SELECT Id, LoggingLevel__c, Message__c, ComponentApiName__c, ComponentFunctionName__c, OriginLocation__c, OriginType__c, Timestamp__c FROM LogEntry__c];
        System.assertEquals(1, logEntries.size());

        LogEntry__c logEntry = logEntries.get(0);

        System.assertEquals(componentLogEntry.loggingLevel, logEntry.LoggingLevel__c, logEntry);
        System.assertEquals(componentLogEntry.message, logEntry.Message__c, logEntry);
        System.assertEquals('Component', logEntry.OriginType__c, logEntry);
        System.assertEquals(expectedComponentApiName + '.' + expectedComponentFunctionName, logEntry.OriginLocation__c, logEntry);
        System.assertEquals(expectedComponentApiName, logEntry.ComponentApiName__c, logEntry);
        System.assertEquals(expectedComponentFunctionName, logEntry.ComponentFunctionName__c, logEntry);
        System.assertEquals(componentLogEntry.timestamp, logEntry.Timestamp__c, logEntry);
    }

    private static String getMockComponentStackTrace() {
        // This is a copy of an actual stack trace generated from c/loggerDemo
        return 'LogEntryBuilder@https://enterprise-customization-3023.lightning.force.com/lightning/n/modules/c/logger.js:20:22'
            + '\nnewLogEntry@https://enterprise-customization-3023.lightning.force.com/lightning/n/modules/c/logger.js:52:14'
            + '\n_registerNewLogEntry@https://enterprise-customization-3023.lightning.force.com/lightning/n/modules/c/logger.js:217:44'
            + '\ninfo@https://enterprise-customization-3023.lightning.force.com/lightning/n/modules/c/logger.js:106:40'
            + '\ncallHook@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:20075:37'
            + '\ncreateMethodCaller/<@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:8551:14'
            + '\ncreateFilteredMethodStateless/<.value<@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:25688:49'
            + '\nlogInfo@https://enterprise-customization-3023.lightning.force.com/lightning/n/modules/c/loggerDemo.js:180:16'
            + '\ncallHook@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:20075:37'
            + '\ninvokeEventListener/<@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:10653:15'
            + '\nrunWithBoundaryProtection@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:11346:7'
            + '\ninvokeEventListener@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:10647:30'
            + '\nb/<@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:9937:26'
            + '\nhandleEvent@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:5490:15'
            + '\nhandler@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:5496:18'
            + '\ncustomElementWrappedListener@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:472:20'
            + '\ninvokeListenersByPlacement/<@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:520:22'
            + '\ninvokeListenersByPlacement@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:517:15'
            + '\ndomListener@https://static.lightning.force.com/cs1/auraFW/javascript/YeF9IbuOAuhiq8yQ65xJFA/aura_proddebug.js:531:33';
    }
}
