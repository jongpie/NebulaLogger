/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
@isTest
private class LogHandler_Tests {
    private static final String HIGH_PRIORITY = Schema.Log__c.Priority__c.getDescribe()
        .getPicklistValues()
        .get(0)
        .getValue();
    private static final String MEDIUM_PRIORITY = Schema.Log__c.Priority__c.getDescribe()
        .getPicklistValues()
        .get(1)
        .getValue();
    private static final String LOW_PRIORITY = Schema.Log__c.Priority__c.getDescribe()
        .getPicklistValues()
        .get(2)
        .getValue();

    private static final String FIRST_STATUS = Schema.Log__c.Status__c.getDescribe()
        .getPicklistValues()
        .get(0)
        .getValue();
    private static final String SECOND_STATUS = Schema.Log__c.Status__c.getDescribe()
        .getPicklistValues()
        .get(1)
        .getValue();

    @testSetup
    static void setupData() {
        Map<String, LogStatus__mdt> logStatusByName = new Map<String, LogStatus__mdt>();
        LogStatus__mdt openStatus = new LogStatus__mdt(
            IsActive__c = true,
            MasterLabel = FIRST_STATUS,
            IsClosed__c = false,
            IsResolved__c = false
        );
        logStatusByName.put(openStatus.MasterLabel, openStatus);

        LogStatus__mdt closedStatus = new LogStatus__mdt(
            IsActive__c = true,
            MasterLabel = SECOND_STATUS,
            IsClosed__c = true,
            IsResolved__c = true
        );
        logStatusByName.put(closedStatus.MasterLabel, closedStatus);

        LogHandler.logStatusByName = logStatusByName;
    }

    @isTest
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

        log = [
            SELECT Id, ClosedBy__c, ClosedDate__c, IsClosed__c, IsResolved__c, Status__c
            FROM Log__c
            WHERE Id = :log.Id
        ];
        System.assertEquals(null, log.ClosedBy__c);
        System.assertEquals(null, log.ClosedDate__c);
        System.assertEquals(false, log.IsClosed__c);
        System.assertEquals(false, log.IsResolved__c);
    }

    @isTest
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

        log = [
            SELECT Id, ClosedBy__c, ClosedDate__c, IsClosed__c, IsResolved__c, Status__c
            FROM Log__c
            WHERE Id = :log.Id
        ];
        System.assertEquals(UserInfo.getUserId(), log.ClosedBy__c);
        System.assertEquals(System.today(), log.ClosedDate__c.date());
        System.assertEquals(true, log.IsClosed__c);
    }

    @isTest
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

    @isTest
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
}
