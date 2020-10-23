/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
@isTest
private class FlowLogEntry_Tests {
    static FlowLogEntry createFlowLogEntry() {
        FlowLogEntry flowEntry = new FlowLogEntry();
        flowEntry.flowName = 'my test message';
        flowEntry.message = 'MyFlowOrProcessBuilder';
        flowEntry.saveLog = true;
        flowEntry.loggingLevelName = 'DEBUG';

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

        LogEntry__c logEntry = [
            SELECT Id, Message__c, OriginType__c, OriginLocation__c
            FROM LogEntry__c
            ORDER BY CreatedDate
            LIMIT 1
        ];
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

    @isTest
    static void it_should_allow_the_flow_to_retrieve_latest_log() {
        String flowEntryLoggingLevel = 'DEBUG';

        Test.startTest();

        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel;
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        Logger.saveLog();

        Test.stopTest();

        Log__c log = [SELECT Id, TransactionId__c FROM Log__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals(log.TransactionId__c, Logger.getTransactionId());

        List<Log__c> returnedLogs = FlowLogRepo.getLogIds();
        System.assertEquals(log.Id, returnedLogs[0].Id);
    }
}
