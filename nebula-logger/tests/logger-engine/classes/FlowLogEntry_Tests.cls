//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class FlowLogEntry_Tests {
    static FlowLogEntry createFlowLogEntry() {
        FlowLogEntry flowEntry = new FlowLogEntry();
        flowEntry.flowName = 'my test message';
        flowEntry.message = 'MyFlowOrProcessBuilder';
        flowEntry.saveLog = true;

        return flowEntry;
    }

    @testSetup
    static void setup() {
        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c = true;
        settings.EnableSystemMessages__c = false;
        upsert settings;
    }

    @isTest
    static void it_should_save_entry_when_logging_level_met() {
        String userLoggingLevel = 'FINEST';
        String flowEntryLoggingLevel = 'DEBUG';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel;
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, Message__c, OriginType__c, OriginLocation__c FROM LogEntry__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals(flowEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
        System.assertEquals(flowEntry.flowName, logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_not_save_entry_when_logging_level_not_met() {
        String userLoggingLevel = 'ERROR';
        String flowEntryLoggingLevel = 'DEBUG';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel;
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        Logger.saveLog();

        Test.stopTest();

        List<LogEntry__c> logEntries = [SELECT Id, Message__c, OriginType__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(0, logEntries.size());
    }

    @isTest
    static void it_should_use_debug_as_default_level_when_faultMessage_is_null() {
        String userLoggingLevel = 'FINEST';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        FlowLogEntry flowEntry = createFlowLogEntry();
        System.assertEquals(null, flowEntry.loggingLevelName);

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginType__c, OriginLocation__c FROM LogEntry__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals('DEBUG', logEntry.LoggingLevel__c);
        System.assertEquals(flowEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
        System.assertEquals(flowEntry.flowName, logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_use_error_as_default_level_when_faultMessage_is_not_null() {
        String userLoggingLevel = 'FINEST';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.faultMessage = 'Whoops, a Flow error has occurred.';
        System.assertEquals(null, flowEntry.loggingLevelName);

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [
            SELECT Id, ExceptionMessage__c, ExceptionType__c, LoggingLevel__c, Message__c, OriginType__c, OriginLocation__c
            FROM LogEntry__c
            ORDER BY CreatedDate
            LIMIT 1
        ];
        System.assertEquals('ERROR', logEntry.LoggingLevel__c);
        System.assertEquals(flowEntry.faultMessage, logEntry.ExceptionMessage__c);
        System.assertEquals('Flow.FaultError', logEntry.ExceptionType__c);
        System.assertEquals(flowEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
        System.assertEquals(flowEntry.flowName, logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_set_related_record_id_when_id_parameter_is_used() {
        String userLoggingLevel = 'FINEST';
        String flowEntryLoggingLevel = 'DEBUG';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel;
        flowEntry.recordId = UserInfo.getUserId();
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, RecordId__c, RecordJson__c FROM LogEntry__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals(UserInfo.getUserId(), logEntry.RecordId__c);
        System.assertEquals(null, logEntry.RecordJson__c);
    }
}
