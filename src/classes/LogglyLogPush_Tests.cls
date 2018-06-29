@isTest
private class LogglyLogPush_Tests {

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

    static void verifyLogEntryCount(Integer expectedCount) {
        List<LogEntry__c> existingLogEntries = [SELECT Id FROM LogEntry__c];
        System.assertEquals(expectedCount, existingLogEntries.size());
    }

    @isTest
    static void it_should_push_a_debug_log_entry_and_update_push_date() {
        verifyLogEntryCount(0);
        Logger.addDebugEntry('testing', 'ClassName', 'methodName');
        Logger.saveLog();
        Test.getEventBus().deliver();
        verifyLogEntryCount(1);

        LogEntry__c logEntry = [SELECT Id, Log__r.PushToLoggly__c, Log__r.PushedToLogglyDate__c FROM LogEntry__c];
        System.assertEquals(true, logEntry.Log__r.PushToLoggly__c);
        System.assertEquals(null, logEntry.Log__r.PushedToLogglyDate__c);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Database.executeBatch(new LogglyLogPush());

        Test.stopTest();

        logEntry = [SELECT Id, Log__r.PushToLoggly__c, Log__r.PushedToLogglyDate__c FROM LogEntry__c];
        System.assertEquals(true, logEntry.Log__r.PushToLoggly__c);
        System.assertEquals(System.today(), logEntry.Log__r.PushedToLogglyDate__c.date());
    }

}