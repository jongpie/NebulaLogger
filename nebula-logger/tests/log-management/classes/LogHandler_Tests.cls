//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class LogHandler_Tests {
    private static final String HIGH_PRIORITY = Schema.Log__c.Priority__c.getDescribe().getPicklistValues().get(0).getValue();
    private static final String MEDIUM_PRIORITY = Schema.Log__c.Priority__c.getDescribe().getPicklistValues().get(1).getValue();
    private static final String LOW_PRIORITY = Schema.Log__c.Priority__c.getDescribe().getPicklistValues().get(2).getValue();

    private static final String FIRST_STATUS = Schema.Log__c.Status__c.getDescribe().getPicklistValues().get(0).getValue();
    private static final String SECOND_STATUS = Schema.Log__c.Status__c.getDescribe().getPicklistValues().get(1).getValue();

    public class LogPluginTest extends LoggerSObjectHandlerPlugin {
        public override void execute(
            TriggerOperation triggerOperationType,
            List<SObject> triggerNew,
            Map<Id, SObject> triggerNewMap,
            List<SObject> triggerOld,
            Map<Id, SObject> triggerOldMap
        ) {
            if (triggerOperationType == TriggerOperation.BEFORE_INSERT) {
                for (Log__c log : (List<Log__c>) triggerNew) {
                    // The specific field changed doesn't really matter - we just want to ensure that whatever
                    // logic implemented in the instance of LoggerSObjectHandlerPlugin is executed
                    log.ProfileName__c = 'Some String';
                }
            }
        }
    }

    @TestSetup
    static void setupData() {
        Map<String, LogStatus__mdt> logStatusByName = new Map<String, LogStatus__mdt>();
        LogStatus__mdt openStatus = new LogStatus__mdt(IsActive__c = true, MasterLabel = FIRST_STATUS, IsClosed__c = false, IsResolved__c = false);
        logStatusByName.put(openStatus.MasterLabel, openStatus);

        LogStatus__mdt closedStatus = new LogStatus__mdt(IsActive__c = true, MasterLabel = SECOND_STATUS, IsClosed__c = true, IsResolved__c = true);
        logStatusByName.put(closedStatus.MasterLabel, closedStatus);

        LogHandler.logStatusByName = logStatusByName;
    }

    @IsTest
    static void it_should_return_the_log_sobjectType() {
        Test.startTest();
        System.assertEquals(Schema.Log__c.SObjectType, new LogHandler().getSObjectType());
        Test.stopTest();
    }

    @IsTest
    static void it_should_clear_closed_status_fields_when_open() {
        Log__c log = new Log__c(
            ClosedBy__c = UserInfo.getUserId(),
            ClosedDate__c = System.now(),
            IsClosed__c = true,
            IsResolved__c = true,
            Status__c = FIRST_STATUS,
            TransactionId__c = '1234'
        );

        Test.startTest();
        insert log;
        Test.stopTest();

        log = [SELECT Id, ClosedBy__c, ClosedDate__c, IsClosed__c, IsResolved__c, Status__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(null, log.ClosedBy__c);
        System.assertEquals(null, log.ClosedDate__c);
        System.assertEquals(false, log.IsClosed__c);
        System.assertEquals(false, log.IsResolved__c);
    }

    @IsTest
    static void it_should_set_closed_status_fields_when_closed() {
        Log__c log = new Log__c(
            ClosedBy__c = null,
            ClosedDate__c = null,
            IsClosed__c = false,
            IsResolved__c = false,
            Status__c = SECOND_STATUS,
            TransactionId__c = '1234'
        );

        Test.startTest();
        insert log;
        Test.stopTest();

        log = [SELECT Id, ClosedBy__c, ClosedDate__c, IsClosed__c, IsResolved__c, Status__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(UserInfo.getUserId(), log.ClosedBy__c);
        System.assertEquals(System.today(), log.ClosedDate__c.date());
        System.assertEquals(true, log.IsClosed__c);
    }

    @IsTest
    static void it_should_keep_existing_retention_date_when_populated() {
        Integer defaultDaysToRetainLog = 10;

        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultNumberOfDaysToRetainLogs__c = defaultDaysToRetainLog;
        upsert settings;

        Test.startTest();

        Integer specifiedDaysToRetainLog = 50;
        Date retentionDate = System.today().addDays(specifiedDaysToRetainLog);
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), LogRetentionDate__c = retentionDate, TransactionId__c = '1234');
        insert log;

        Test.stopTest();

        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.assertNotEquals(defaultDaysToRetainLog, specifiedDaysToRetainLog);
        System.assertEquals(retentionDate, log.LogRetentionDate__c);
    }

    @IsTest
    static void it_should_set_retention_date_when_configured() {
        Integer daysToRetainLog = 90;
        Date expectedRetentionDate = System.today().addDays(daysToRetainLog);

        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultNumberOfDaysToRetainLogs__c = daysToRetainLog;
        upsert settings;

        Test.startTest();

        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), TransactionId__c = '1234');
        insert log;

        Test.stopTest();

        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(expectedRetentionDate, log.LogRetentionDate__c);
    }

    @IsTest
    static void it_should_have_null_retention_date_when_no_retention_configured() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultNumberOfDaysToRetainLogs__c = null;
        upsert settings;

        Test.startTest();

        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), TransactionId__c = '1234');
        insert log;

        Test.stopTest();

        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(null, log.LogRetentionDate__c);
    }

    @IsTest
    static void it_should_set_priority_to_high_when_there_are_errors() {
        Log__c log = new Log__c(Priority__c = LOW_PRIORITY, TransactionId__c = '1234');
        insert log;
        log = [SELECT Id, Priority__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(LOW_PRIORITY, log.Priority__c);

        Test.startTest();
        insert new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'ERROR');
        Test.stopTest();

        log = [SELECT Id, Priority__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(HIGH_PRIORITY, log.Priority__c);
    }

    @IsTest
    static void it_should_set_priority_to_medium_when_there_are_warnings() {
        Log__c log = new Log__c(Priority__c = LOW_PRIORITY, TransactionId__c = '1234');
        insert log;
        log = [SELECT Id, Priority__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(LOW_PRIORITY, log.Priority__c);

        Test.startTest();
        insert new LogEntry__c(Log__c = log.Id, LoggingLevel__c = 'WARN');
        Test.stopTest();

        log = [SELECT Id, Priority__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(MEDIUM_PRIORITY, log.Priority__c);
    }

    @IsTest
    static void it_should_grant_read_access_to_user_when_access_level_is_read() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultLogShareAccessLevel__c = 'Read';
        upsert settings;

        Test.startTest();
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), TransactionId__c = '1234');
        insert log;
        Test.stopTest();

        List<Log__Share> logShares = [SELECT AccessLevel, ParentId, RowCause, UserOrGroupId FROM Log__Share WHERE ParentId = :log.Id AND AccessLevel != 'All'];

        System.assertEquals(1, logShares.size(), logShares);
        System.assertEquals('Read', logShares.get(0).AccessLevel);
        System.assertEquals(log.Id, logShares.get(0).ParentId);
        System.assertEquals(Schema.Log__Share.RowCause.LoggedByUser__c, logShares.get(0).RowCause);
        System.assertEquals(log.LoggedBy__c, logShares.get(0).UserOrGroupId);
    }

    @IsTest
    static void it_should_grant_edit_access_to_user_when_access_level_is_edit() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultLogShareAccessLevel__c = 'Edit';
        upsert settings;

        Test.startTest();
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), TransactionId__c = '1234');
        insert log;
        Test.stopTest();

        List<Log__Share> logShares = [SELECT AccessLevel, ParentId, RowCause, UserOrGroupId FROM Log__Share WHERE ParentId = :log.Id AND AccessLevel != 'All'];

        System.assertEquals(1, logShares.size(), logShares);
        System.assertEquals('Edit', logShares.get(0).AccessLevel);
        System.assertEquals(log.Id, logShares.get(0).ParentId);
        System.assertEquals(Schema.Log__Share.RowCause.LoggedByUser__c, logShares.get(0).RowCause);
        System.assertEquals(log.LoggedBy__c, logShares.get(0).UserOrGroupId);
    }

    @IsTest
    static void it_should_not_grant_access_to_user_when_access_level_is_null() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultLogShareAccessLevel__c = null;
        upsert settings;

        Test.startTest();
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), TransactionId__c = '1234');
        insert log;
        Test.stopTest();

        List<Log__Share> logShares = [SELECT AccessLevel, ParentId, RowCause, UserOrGroupId FROM Log__Share WHERE ParentId = :log.Id AND AccessLevel != 'All'];

        System.assertEquals(0, logShares.size(), logShares);
    }

    @IsTest
    static void it_should_not_grant_access_to_user_when_access_level_is_an_unknown_string() {
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.DefaultLogShareAccessLevel__c = 'FAKE LEVEL';
        upsert settings;

        Test.startTest();
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), TransactionId__c = '1234');
        insert log;
        Test.stopTest();

        List<Log__Share> logShares = [SELECT AccessLevel, ParentId, RowCause, UserOrGroupId FROM Log__Share WHERE ParentId = :log.Id AND AccessLevel != 'All'];

        System.assertEquals(0, logShares.size(), logShares);
    }

    @IsTest
    static void it_should_run_apex_plugin_when_configured() {
        String expectedProfileName = 'Some String';

        Test.startTest();

        // Use the mock configurations
        LoggerPlugin__mdt plugin = new LoggerPlugin__mdt(PluginType__c = 'Apex', PluginApiName__c = LogPluginTest.class.getName());
        LoggerSObjectHandler.setMockPlugin(Schema.Log__c.SObjectType, plugin);

        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), TransactionId__c = '1234');
        insert log;

        log = [SELECT Id, ProfileName__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(expectedProfileName, log.ProfileName__c);

        Test.stopTest();
    }
}
