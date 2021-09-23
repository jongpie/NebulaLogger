//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

// TODO: need to improve plugin framework to make it easier for plugins to test by making it easier
//       to mock CMDT records & instances of LoggerSObjectHandlerPlugin
@IsTest
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

    static void mockConfigurations(LoggingLevel notificationLoggingLevel) {
        // Set the plugin's parameters
        LoggerPlugin__mdt slackPluginConfig = new LoggerPlugin__mdt(
            IsEnabled__c = true,
            PluginApiName__c = SlackLoggerPlugin.class.getName(),
            PluginType__c = 'Apex'
        );
        LoggerSObjectHandler.setMockPlugin(Schema.Log__c.SObjectType, slackPluginConfig);

        // Set the plugin's internal variables
        SlackLoggerPlugin.endpoint = 'https://fake.slack.com/';
        SlackLoggerPlugin.notificationLoggingLevel = notificationLoggingLevel;
    }

    static void verifyLogEntryCountEquals(Integer expectedCount) {
        List<LogEntry__c> existingLogEntries = [SELECT Id FROM LogEntry__c];
        System.assertEquals(expectedCount, existingLogEntries.size());
    }

    static List<Log__c> queryLogs() {
        return [
            SELECT
                Id,
                MaxLogEntryLoggingLevelOrdinal__c,
                SendSlackNotification__c,
                SlackNotificationDate__c,
                (
                    SELECT Id, LoggingLevel__c, Message__c
                    FROM LogEntries__r
                    WHERE LoggingLevelOrdinal__c >= :LoggingLevel.WARN.ordinal()
                    ORDER BY Timestamp__c DESC
                    LIMIT 1
                )
            FROM Log__c
        ];
    }

    @IsTest
    static void it_should_push_a_log_when_logging_level_is_met() {
        SuccessCalloutMock calloutMock = new SuccessCalloutMock();

        verifyLogEntryCountEquals(0);

        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), SendSlackNotification__c = false, TransactionId__c = '1234');
        insert log;

        LoggingLevel logEntryLoggingLevel = LoggingLevel.WARN;
        LogEntry__c logEntry = new LogEntry__c(
            Log__c = log.Id,
            LoggingLevel__c = logEntryLoggingLevel.name(),
            LoggingLevelOrdinal__c = logEntryLoggingLevel.ordinal(),
            Timestamp__c = System.now()
        );
        insert logEntry;

        verifyLogEntryCountEquals(1);

        List<Log__c> logs = queryLogs();
        System.assertEquals(1, logs.size());
        log = logs.get(0);

        System.assertEquals(1, log.LogEntries__r.size());
        System.assertEquals(false, log.SendSlackNotification__c);
        System.assertEquals(null, log.SlackNotificationDate__c);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, calloutMock);

        // Load the mock configurations - the plugin framework won't load actual CMDT records during tests
        mockConfigurations(logEntryLoggingLevel);
        System.assert(logEntryLoggingLevel.ordinal() >= SlackLoggerPlugin.notificationLoggingLevel.ordinal());

        // Update the records to trigger the handler framework, which will then run the Slack plugin
        update log;

        // Verify that the internal queueable job has been enqueued
        System.assertEquals(1, Limits.getAsyncCalls());

        // Stop the test so the internal queueable job runs
        Test.stopTest();

        log = [SELECT Id, MaxLogEntryLoggingLevelOrdinal__c, SendSlackNotification__c, SlackNotificationDate__c FROM Log__c];
        System.assertEquals(true, log.SendSlackNotification__c);
        System.assertNotEquals(null, log.SlackNotificationDate__c);
        System.assertEquals(System.today(), log.SlackNotificationDate__c.date());
    }

    @IsTest
    static void it_should_not_push_a_log_when_logging_level_is_not_met() {
        SuccessCalloutMock calloutMock = new SuccessCalloutMock();

        verifyLogEntryCountEquals(0);

        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), SendSlackNotification__c = false, TransactionId__c = '1234');
        insert log;

        LoggingLevel logEntryLoggingLevel = LoggingLevel.WARN;
        LogEntry__c logEntry = new LogEntry__c(
            Log__c = log.Id,
            LoggingLevel__c = logEntryLoggingLevel.name(),
            LoggingLevelOrdinal__c = logEntryLoggingLevel.ordinal(),
            Timestamp__c = System.now()
        );
        insert logEntry;

        verifyLogEntryCountEquals(1);

        List<Log__c> logs = queryLogs();
        System.assertEquals(1, logs.size());
        log = logs.get(0);

        System.assertEquals(1, log.LogEntries__r.size());
        System.assertEquals(false, log.SendSlackNotification__c);
        System.assertEquals(null, log.SlackNotificationDate__c);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, calloutMock);

        // Load the mock configurations - the plugin framework won't load actual CMDT records during tests
        LoggingLevel slackLoggingLevel = LoggingLevel.ERROR;
        System.assert(logEntryLoggingLevel.ordinal() < slackLoggingLevel.ordinal());
        mockConfigurations(slackLoggingLevel);
        System.assert(logEntryLoggingLevel.ordinal() < SlackLoggerPlugin.notificationLoggingLevel.ordinal());

        // Update the records to trigger the handler framework, which will then run the Slack plugin
        update log;

        // Verify that the internal queueable job has been enqueued
        System.assertEquals(0, Limits.getAsyncCalls());

        // Stop the test so the internal queueable job runs
        Test.stopTest();

        log = queryLogs().get(0);
        System.assertEquals(1, log.LogEntries__r.size());
        System.assertEquals(false, log.SendSlackNotification__c);
        System.assertEquals(null, log.SlackNotificationDate__c);
    }
}
