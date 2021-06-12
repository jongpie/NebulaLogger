//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@isTest
private class SlackLoggerPlugin_Tests {
    public class SuccessCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setBody(request.getBody());
            response.setStatusCode(200);
            return response;
        }
    }

    public class FailureCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setBody(request.getBody());
            response.setStatusCode(400);
            return response;
        }
    }

    static void verifyLogEntryCountEquals(Integer expectedCount) {
        List<LogEntry__c> existingLogEntries = [SELECT Id FROM LogEntry__c];
        System.assertEquals(expectedCount, existingLogEntries.size());
    }

    @isTest
    static void it_should_push_a_debug_log_entry_and_update_push_date() {
        verifyLogEntryCountEquals(0);

        Log__c log = new Log__c(SendSlackNotification__c = false, TransactionId__c = '1234');
        insert log;

        LoggingLevel logEntryLoggingLevel = LoggingLevel.DEBUG;
        LogEntry__c logEntry = new LogEntry__c(
            Log__c = log.Id,
            LoggingLevel__c = logEntryLoggingLevel.name(),
            LoggingLevelOrdinal__c = logEntryLoggingLevel.ordinal()
        );
        insert logEntry;

        verifyLogEntryCountEquals(1);

        log = [SELECT Id, MaxLogEntryLoggingLevelOrdinal__c, SendSlackNotification__c, SlackNotificationDate__c FROM Log__c];
        System.assertEquals(false, log.SendSlackNotification__c);
        System.assertEquals(null, log.SlackNotificationDate__c);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        new SlackLoggerPlugin().execute(TriggerOperation.BEFORE_UPDATE, new List<Log__c>{ log }, null, null, null);
        System.assertEquals(true, log.SendSlackNotification__c);

        new SlackLoggerPlugin().execute(TriggerOperation.AFTER_UPDATE, new List<Log__c>{ log }, null, null, null);
        // log = [SELECT Id, MaxLogEntryLoggingLevelOrdinal__c, SendSlackNotification__c, SlackNotificationDate__c FROM Log__c];
        System.assertEquals(true, log.SendSlackNotification__c);
        System.assertNotEquals(null, log.SlackNotificationDate__c);
        System.assertEquals(System.today(), log.SlackNotificationDate__c.date());

        Test.stopTest();
    }

    // @isTest
    // static void it_should_not_push_a_log_entry_when_configured_level_not_met() {
    //     verifyLogEntryCountEquals(0);
    //     Logger.warn('testing Slack integration');
    //     Logger.saveLog();
    //     Test.getEventBus().deliver();
    //     verifyLogEntryCountEquals(1);

    //     // To make sure that Slack push is not triggered, we need to update a field on the parent Log__c
    //     Log__c log = [SELECT Id, SendSlackNotification__c FROM Log__c];
    //     log.SendSlackNotification__c = false;
    //     update log;

    //     LogEntry__c logEntry = [SELECT Id, Log__r.SendSlackNotification__c, Log__r.SlackNotificationDate__c FROM LogEntry__c];
    //     System.assertEquals(false, logEntry.Log__r.SendSlackNotification__c);
    //     System.assertEquals(null, logEntry.Log__r.SlackNotificationDate__c);

    //     Test.startTest();
    //     Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

    //     Database.executeBatch(new SlackLoggerPlugin());

    //     Test.stopTest();

    //     logEntry = [SELECT Id, Log__r.SendSlackNotification__c, Log__r.SlackNotificationDate__c FROM LogEntry__c];
    //     System.assertEquals(false, logEntry.Log__r.SendSlackNotification__c);
    //     System.assertEquals(null, logEntry.Log__r.SlackNotificationDate__c);
    // }
}
