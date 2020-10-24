/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
@isTest
private class FlowRecordLogEntry_Tests {
    static FlowRecordLogEntry createFlowRecordLogEntry() {
        FlowRecordLogEntry flowRecordEntry = new FlowRecordLogEntry();
        flowRecordEntry.flowName = 'my test message';
        flowRecordEntry.message = 'MyFlowOrProcessBuilder';
        flowRecordEntry.saveLog = true;
        flowRecordEntry.loggingLevelName = 'DEBUG';

        return flowRecordEntry;
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
        User currentUser = [SELECT Id, Name, Username FROM User WHERE Id = :UserInfo.getUserId()];
        String userLoggingLevel = 'FINEST';
        String flowRecordEntryLoggingLevel = 'DEBUG';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        FlowRecordLogEntry flowRecordEntry = createFlowRecordLogEntry();
        flowRecordEntry.loggingLevelName = flowRecordEntryLoggingLevel;
        flowRecordEntry.record = currentUser;
        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowRecordEntry });
        Logger.saveLog();

        Test.stopTest();

        String expectedUserJson = Json.serializePretty(currentUser);

        LogEntry__c logEntry = [SELECT Id, RecordId__c, RecordJson__c FROM LogEntry__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals(currentUser.Id, logEntry.RecordId__c);
        System.assertEquals(expectedUserJson, logEntry.RecordJson__c);
    }

    @isTest
    static void it_should_not_save_entry_when_logging_level_not_met() {
        User currentUser = new User(Id = UserInfo.getUserId());
        String userLoggingLevel = 'ERROR';
        String flowRecordEntryLoggingLevel = 'DEBUG';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        FlowRecordLogEntry flowRecordEntry = createFlowRecordLogEntry();
        flowRecordEntry.loggingLevelName = flowRecordEntryLoggingLevel;
        flowRecordEntry.record = currentUser;
        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowRecordEntry });
        Logger.saveLog();

        Test.stopTest();

        List<LogEntry__c> logEntries = [SELECT Id FROM LogEntry__c];
        System.assertEquals(0, logEntries.size());
    }

    @isTest
    static void it_should_allow_the_flow_to_retrieve_latest_log() {
        User currentUser = new User(Id = UserInfo.getUserId());
        String flowRecordEntryLoggingLevel = 'DEBUG';

        Test.startTest();

        FlowRecordLogEntry flowRecordEntry = createFlowRecordLogEntry();
        flowRecordEntry.loggingLevelName = flowRecordEntryLoggingLevel;
        flowRecordEntry.record = currentUser;
        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowRecordEntry });
        Logger.saveLog();

        Test.stopTest();

        Log__c log = [SELECT Id, TransactionId__c FROM Log__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals(log.TransactionId__c, Logger.getTransactionId());

        List<Log__c> returnedLogs = FlowLogRepo.getLogIds();
        System.assertEquals(log.Id, returnedLogs[0].Id);
    }
}
