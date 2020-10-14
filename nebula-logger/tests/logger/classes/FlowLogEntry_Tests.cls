/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
@isTest
private class FlowLogEntry_Tests {

    static FlowLogEntry createFlowLogEntry() {
        FlowLogEntry flowEntry     = new FlowLogEntry();
        flowEntry.flowName         = 'my test message';
        flowEntry.message          = 'MyFlowOrProcessBuilder';
        flowEntry.saveLog          = true;
        flowEntry.loggingLevelName = 'DEBUG';

        return flowEntry;
    }

    @testSetup
    static void setup() {
        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c      = true;
        upsert settings;
    }

    @isTest
    static void it_should_save_entry_when_logging_level_met() {
        String userLoggingLevel      = 'FINEST';
        String flowEntryLoggingLevel = 'DEBUG';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c   = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        List<FlowLogEntry> flowLogEntries = new List<FlowLogEntry>();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel;
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{flowEntry});
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, Message__c, OriginType__c, OriginLocation__c FROM LogEntry__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals(flowEntry.message, logEntry.Message__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
        System.assertEquals(flowEntry.flowName, logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_not_save_entry_when_logging_level_not_met() {
        String userLoggingLevel      = 'ERROR';
        String flowEntryLoggingLevel = 'DEBUG';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c   = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        List<FlowLogEntry> flowLogEntries = new List<FlowLogEntry>();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel;
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{flowEntry});
        Logger.saveLog();

        Test.stopTest();

        List<LogEntry__c> logEntries = [SELECT Id, Message__c, OriginType__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(0, logEntries.size());
    }

    @isTest
    static void it_should_set_related_record_id_when_id_parameter_is_used() {
        String userLoggingLevel      = 'FINEST';
        String flowEntryLoggingLevel = 'DEBUG';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c   = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        List<FlowLogEntry> flowLogEntries = new List<FlowLogEntry>();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel;
        flowEntry.recordId = UserInfo.getUserId();
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{flowEntry});
        Logger.saveLog();

        Test.stopTest();


        LogEntry__c logEntry = [SELECT Id, RelatedRecordId__c, RelatedRecordJson__c FROM LogEntry__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals(UserInfo.getUserId(), logEntry.RelatedRecordId__c);
        System.assertEquals(null, logEntry.RelatedRecordJson__c);
    }

    @isTest
    static void it_should_store_record_json_when_sobject_parameter_is_used() {
        String userLoggingLevel      = 'FINEST';
        String flowEntryLoggingLevel = 'DEBUG';

        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();
        loggerSettings.LoggingLevel__c   = userLoggingLevel;
        update loggerSettings;

        Test.startTest();

        User currentUser = [SELECT Id, Name, Username FROM User WHERE Id = :UserInfo.getUserId()];

        List<FlowLogEntry> flowLogEntries = new List<FlowLogEntry>();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel;
        flowEntry.record = currentUser;
        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{flowEntry});
        Logger.saveLog();

        Test.stopTest();

        String expectedUserJson = Json.serializePretty(currentUser);

        LogEntry__c logEntry = [SELECT Id, RelatedRecordId__c, RelatedRecordJson__c FROM LogEntry__c ORDER BY CreatedDate LIMIT 1];
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
        System.assertEquals(expectedUserJson, logEntry.RelatedRecordJson__c);
    }

}