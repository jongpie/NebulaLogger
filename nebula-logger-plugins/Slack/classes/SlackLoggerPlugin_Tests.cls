//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

// TODO: need to improve plugin framework to make it easier for plugins to test by making it easier
//       to mock CMDT records & instances of LoggerSObjectHandlerPlugin
@IsTest
private class SlackLoggerPlugin_Tests {
    /**
     * @description Inner class for handling mock HTTP callouts.
     */
    public class SuccessCalloutMock implements HttpCalloutMock {
        /**
         * @description Returns the mock HTTP response.
         * @param request The HTTP request to "receive"
         * @return The resulting HTTP response
         */
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setBody(request.getBody());
            response.setStatusCode(200);
            return response;
        }
    }

    /**
     * @description Inner class for handling mock HTTP callouts that should end in errors / exceptions.
     */
    public class FailureCalloutMock implements HttpCalloutMock {
        /**
         * @description Returns the mock HTTP response.
         * @param request The HTTP request to "receive"
         * @return The resulting HTTP response
         */
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
        System.assertEquals(expectedCount, existingLogEntries.size(), 'Existing log entries did NOT match the expected count.');
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
    static void pushLogWhenLoggingLevelIsMet() {
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
        System.assertEquals(1, logs.size(), 'Logs size did not match expected value of 1.');
        log = logs.get(0);

        System.assertEquals(1, log.LogEntries__r.size(), 'Log entries did not match the expected count of 1.');
        System.assertEquals(false, log.SendSlackNotification__c, 'SendSlackNotification was incorrectly set to true.');
        System.assertEquals(null, log.SlackNotificationDate__c, 'SlackNotificationDate was not null.');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, calloutMock);

        // Load the mock configurations - the plugin framework won't load actual CMDT records during tests
        mockConfigurations(logEntryLoggingLevel);
        System.assert(
            logEntryLoggingLevel.ordinal() >= SlackLoggerPlugin.notificationLoggingLevel.ordinal(),
            'The notification logging level ordinal was incorrect.'
        );

        // Update the records to trigger the handler framework, which will then run the Slack plugin
        update log;

        // Verify that the internal queueable job has been enqueued
        System.assertEquals(1, Limits.getAsyncCalls(), 'The enqueueable job was not enqueued.');

        // Stop the test so the internal queueable job runs
        Test.stopTest();

        log = [SELECT Id, MaxLogEntryLoggingLevelOrdinal__c, SendSlackNotification__c, SlackNotificationDate__c FROM Log__c];
        System.assertEquals(true, log.SendSlackNotification__c, 'SendSlackNotification was incorrectly set to false.');
        System.assertNotEquals(null, log.SlackNotificationDate__c, 'SlackNotificationDate was null.');
        System.assertEquals(System.today(), log.SlackNotificationDate__c.date(), 'SlackNotificationDate was not set to TODAY.');
    }

    @IsTest
    static void doNotPushLogWhenLoggingLevelIsNotMet() {
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
        System.assertEquals(1, logs.size(), 'Logs size did not match expected value of 1.');
        log = logs.get(0);

        System.assertEquals(1, log.LogEntries__r.size(), 'Log entries size was not equal to 1.');
        System.assertEquals(false, log.SendSlackNotification__c, 'SendSlackNotification was incorrectly set to true.');
        System.assertEquals(null, log.SlackNotificationDate__c, 'SlackNotificationDate was not null.');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, calloutMock);

        // Load the mock configurations - the plugin framework won't load actual CMDT records during tests
        LoggingLevel slackLoggingLevel = LoggingLevel.ERROR;
        System.assert(logEntryLoggingLevel.ordinal() < slackLoggingLevel.ordinal(), 'Slack logging level ordinal was incorrect.');
        mockConfigurations(slackLoggingLevel);
        System.assert(logEntryLoggingLevel.ordinal() < SlackLoggerPlugin.notificationLoggingLevel.ordinal(), 'Slack logging level ordinal was incorrect.');

        // Update the records to trigger the handler framework, which will then run the Slack plugin
        update log;

        // Verify that the internal queueable job has been enqueued
        System.assertEquals(0, Limits.getAsyncCalls(), 'The queueable job has not been enqueued.');

        // Stop the test so the internal queueable job runs
        Test.stopTest();

        log = queryLogs().get(0);
        System.assertEquals(1, log.LogEntries__r.size(), 'Log entries size was not equal to 1.');
        System.assertEquals(false, log.SendSlackNotification__c, 'SendSlackNotification incorrectly set to true.');
        System.assertEquals(null, log.SlackNotificationDate__c, 'SlackNotificationDate was not null.');
    }
}
