/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
@isTest
private class LogglyLogPusher_Tests {

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
        Logger.addDebugEntry(LoggingLevel.DEBUG, 'testing', 'MyClass.myMethodName()');
        Logger.saveLog();
        Test.getEventBus().deliver();
        verifyLogEntryCountEquals(1);

        // To trigger Loggly push, we need to update a field on the parent Log__c
        Log__c log = [SELECT Id, PushToLoggly__c FROM Log__c];
        log.PushToLoggly__c = true;
        update log;

        LogEntry__c logEntry = [SELECT Id, Log__r.PushToLoggly__c, Log__r.PushedToLogglyDate__c FROM LogEntry__c];
        System.assertEquals(true, logEntry.Log__r.PushToLoggly__c);
        System.assertEquals(null, logEntry.Log__r.PushedToLogglyDate__c);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Database.executeBatch(new LogglyLogPusher());

        Test.stopTest();

        logEntry = [SELECT Id, Log__r.PushToLoggly__c, Log__r.PushedToLogglyDate__c FROM LogEntry__c];
        System.assertEquals(true, logEntry.Log__r.PushToLoggly__c);
        System.assertEquals(System.today(), logEntry.Log__r.PushedToLogglyDate__c.date());
    }

    @isTest
    static void it_should_not_push_a_debug_log_entry_when_push_field_is_false() {
        verifyLogEntryCountEquals(0);
        Logger.addDebugEntry(LoggingLevel.DEBUG, 'testing', 'MyClass.myMethodName()');
        Logger.saveLog();
        Test.getEventBus().deliver();
        verifyLogEntryCountEquals(1);

        // To make sure that Loggly push is not triggered, we need to update a field on the parent Log__c
        Log__c log = [SELECT Id, PushToLoggly__c FROM Log__c];
        log.PushToLoggly__c = false;
        update log;

        LogEntry__c logEntry = [SELECT Id, Log__r.PushToLoggly__c, Log__r.PushedToLogglyDate__c FROM LogEntry__c];
        System.assertEquals(false, logEntry.Log__r.PushToLoggly__c);
        System.assertEquals(null, logEntry.Log__r.PushedToLogglyDate__c);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Database.executeBatch(new LogglyLogPusher());

        Test.stopTest();

        logEntry = [SELECT Id, Log__r.PushToLoggly__c, Log__r.PushedToLogglyDate__c FROM LogEntry__c];
        System.assertEquals(false, logEntry.Log__r.PushToLoggly__c);
        System.assertEquals(null, logEntry.Log__r.PushedToLogglyDate__c);
    }

}