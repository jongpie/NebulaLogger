//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class SlackLoggerPlugin_Tests {
    @IsTest
    static void it_should_not_push_log_when_logging_level_is_not_met() {
        verifyLogEntryCountEquals(0);
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), SendSlackNotification__c = false, TransactionId__c = '1234');
        insert log;
        LoggingLevel logEntryLoggingLevel = LoggingLevel.WARN;
        LogEntry__c logEntry = new LogEntry__c(
            ExceptionStackTrace__c = 'Some exception stack trace',
            Log__c = log.Id,
            LoggingLevel__c = logEntryLoggingLevel.name(),
            LoggingLevelOrdinal__c = logEntryLoggingLevel.ordinal(),
            StackTrace__c = 'A stack trace',
            Timestamp__c = System.now()
        );
        insert logEntry;
        verifyLogEntryCountEquals(1);
        List<Log__c> logs = queryLogs(logEntryLoggingLevel);
        System.assertEquals(1, logs.size(), 'Logs size did not match expected value of 1.');
        log = logs.get(0);
        System.assertEquals(1, log.LogEntries__r.size(), 'Log entries size was not equal to 1.');
        System.assertEquals(false, log.SendSlackNotification__c, 'SendSlackNotification was incorrectly set to true.');
        System.assertEquals(null, log.SlackNotificationDate__c, 'SlackNotificationDate was not null.');
        System.Test.startTest();
        LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
        System.Test.setMock(HttpCalloutMock.class, calloutMock);
        // Load the mock configurations - the plugin framework won't load actual CMDT records during tests
        LoggingLevel slackLoggingLevel = LoggingLevel.ERROR;
        System.assert(logEntryLoggingLevel.ordinal() < slackLoggingLevel.ordinal(), 'Slack logging level ordinal was incorrect.');
        mockConfigurations(slackLoggingLevel);
        System.assert(logEntryLoggingLevel.ordinal() < SlackLoggerPlugin.NOTIFICATION_LOGGING_LEVEL.ordinal(), 'Slack logging level ordinal was incorrect.');
        LoggerSObjectHandler.shouldExecute(true);
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();

        // Update the records to trigger the handler framework, which will then run the Slack plugin
        update log;

        // Verify that the internal queueable job has been enqueued
        System.assertEquals(0, System.Limits.getAsyncCalls(), 'The queueable job should not have been enqueued');
        // Stop the test so the internal queueable job runs
        System.Test.stopTest();
        log = queryLogs(logEntryLoggingLevel).get(0);
        System.assertEquals(1, log.LogEntries__r.size(), 'Log entries size was not equal to 1.');
        System.assertEquals(false, log.SendSlackNotification__c, 'SendSlackNotification incorrectly set to true.');
        System.assertEquals(null, log.SlackNotificationDate__c, 'SlackNotificationDate was not null.');
    }

    @IsTest
    static void it_should_push_log_when_logging_level_is_met_for_error() {
        verifyLogEntryCountEquals(0);
        LoggerSObjectHandler.shouldExecute(false);
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), SendSlackNotification__c = false, TransactionId__c = '1234');
        insert log;
        LoggingLevel logEntryLoggingLevel = LoggingLevel.ERROR;
        LogEntry__c logEntry = new LogEntry__c(
            ExceptionStackTrace__c = 'Some exception stack trace',
            Log__c = log.Id,
            LoggingLevel__c = logEntryLoggingLevel.name(),
            LoggingLevelOrdinal__c = logEntryLoggingLevel.ordinal(),
            StackTrace__c = 'A stack trace',
            Timestamp__c = System.now()
        );
        insert logEntry;
        verifyLogEntryCountEquals(1);
        List<Log__c> logs = queryLogs(logEntryLoggingLevel);
        System.assertEquals(1, logs.size(), 'Logs size did not match expected value of 1.');
        log = logs.get(0);
        System.assertEquals(1, log.LogEntries__r.size(), 'Log entries did not match the expected count of 1.');
        System.assertEquals(false, log.SendSlackNotification__c, 'SendSlackNotification was incorrectly set to true.');
        System.assertEquals(null, log.SlackNotificationDate__c, 'SlackNotificationDate was not null.');
        System.Test.startTest();
        LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
        System.Test.setMock(HttpCalloutMock.class, calloutMock);
        // Load the mock configurations - the plugin framework won't load actual CMDT records during tests
        mockConfigurations(logEntryLoggingLevel);
        System.assert(
            logEntryLoggingLevel.ordinal() >= SlackLoggerPlugin.NOTIFICATION_LOGGING_LEVEL.ordinal(),
            'The notification logging level ordinal was incorrect.'
        );
        LoggerSObjectHandler.shouldExecute(true);
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();

        // Update the records to trigger the handler framework, which will then run the Slack plugin
        update log;

        // Verify that the internal queueable job has been enqueued
        System.assertEquals(1, System.Limits.getAsyncCalls(), 'The queueable job should have been enqueued');
        // Stop the test so the internal queueable job runs
        System.Test.stopTest();
        log = [SELECT Id, MaxLogEntryLoggingLevelOrdinal__c, SendSlackNotification__c, SlackNotificationDate__c FROM Log__c];
        System.assertEquals(true, log.SendSlackNotification__c, 'SendSlackNotification was incorrectly set to false.');
        System.assertNotEquals(null, log.SlackNotificationDate__c, 'SlackNotificationDate was null.');
        System.assertEquals(System.today(), log.SlackNotificationDate__c.date(), 'SlackNotificationDate was not set to TODAY.');
    }

    @IsTest
    static void it_should_push_log_when_logging_level_is_met_for_warn() {
        verifyLogEntryCountEquals(0);
        LoggerSObjectHandler.shouldExecute(false);
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), SendSlackNotification__c = false, TransactionId__c = '1234');
        insert log;
        LoggingLevel logEntryLoggingLevel = LoggingLevel.WARN;
        LogEntry__c logEntry = new LogEntry__c(
            ExceptionStackTrace__c = 'Some exception stack trace',
            Log__c = log.Id,
            LoggingLevel__c = logEntryLoggingLevel.name(),
            LoggingLevelOrdinal__c = logEntryLoggingLevel.ordinal(),
            StackTrace__c = 'A stack trace',
            Timestamp__c = System.now()
        );
        insert logEntry;
        verifyLogEntryCountEquals(1);
        List<Log__c> logs = queryLogs(logEntryLoggingLevel);
        System.assertEquals(1, logs.size(), 'Logs size did not match expected value of 1.');
        log = logs.get(0);
        System.assertEquals(1, log.LogEntries__r.size(), 'Log entries did not match the expected count of 1.');
        System.assertEquals(false, log.SendSlackNotification__c, 'SendSlackNotification was incorrectly set to true.');
        System.assertEquals(null, log.SlackNotificationDate__c, 'SlackNotificationDate was not null.');
        System.Test.startTest();
        LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
        System.Test.setMock(HttpCalloutMock.class, calloutMock);
        // Load the mock configurations - the plugin framework won't load actual CMDT records during tests
        mockConfigurations(logEntryLoggingLevel);
        System.assert(
            logEntryLoggingLevel.ordinal() >= SlackLoggerPlugin.NOTIFICATION_LOGGING_LEVEL.ordinal(),
            'The notification logging level ordinal was incorrect.'
        );
        LoggerSObjectHandler.shouldExecute(true);
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();

        // Update the records to trigger the handler framework, which will then run the Slack plugin
        update log;

        // Verify that the internal queueable job has been enqueued
        System.assertEquals(1, System.Limits.getAsyncCalls(), 'The queueable job should have been enqueued');
        // Stop the test so the internal queueable job runs
        System.Test.stopTest();
        log = [SELECT Id, MaxLogEntryLoggingLevelOrdinal__c, SendSlackNotification__c, SlackNotificationDate__c FROM Log__c];
        System.assertEquals(true, log.SendSlackNotification__c, 'SendSlackNotification was incorrectly set to false.');
        System.assertNotEquals(null, log.SlackNotificationDate__c, 'SlackNotificationDate was null.');
        System.assertEquals(System.today(), log.SlackNotificationDate__c.date(), 'SlackNotificationDate was not set to TODAY.');
    }

    @IsTest
    static void it_should_push_log_when_logging_level_is_met_for_info() {
        verifyLogEntryCountEquals(0);
        LoggerSObjectHandler.shouldExecute(false);
        Log__c log = new Log__c(LoggedBy__c = UserInfo.getUserId(), SendSlackNotification__c = false, TransactionId__c = '1234');
        insert log;
        LoggingLevel logEntryLoggingLevel = LoggingLevel.INFO;
        LogEntry__c logEntry = new LogEntry__c(
            ExceptionStackTrace__c = 'Some exception stack trace',
            Log__c = log.Id,
            LoggingLevel__c = logEntryLoggingLevel.name(),
            LoggingLevelOrdinal__c = logEntryLoggingLevel.ordinal(),
            StackTrace__c = 'A stack trace',
            Timestamp__c = System.now()
        );
        insert logEntry;
        verifyLogEntryCountEquals(1);
        List<Log__c> logs = queryLogs(logEntryLoggingLevel);
        System.assertEquals(1, logs.size(), 'Logs size did not match expected value of 1.');
        log = logs.get(0);
        System.assertEquals(1, log.LogEntries__r.size(), 'Log entries did not match the expected count of 1.');
        System.assertEquals(false, log.SendSlackNotification__c, 'SendSlackNotification was incorrectly set to true.');
        System.assertEquals(null, log.SlackNotificationDate__c, 'SlackNotificationDate was not null.');
        System.Test.startTest();
        LoggerMockDataCreator.MockHttpCallout calloutMock = LoggerMockDataCreator.createHttpCallout().setStatusCode(200);
        System.Test.setMock(HttpCalloutMock.class, calloutMock);
        // Load the mock configurations - the plugin framework won't load actual CMDT records during tests
        mockConfigurations(logEntryLoggingLevel);
        System.assert(
            logEntryLoggingLevel.ordinal() >= SlackLoggerPlugin.NOTIFICATION_LOGGING_LEVEL.ordinal(),
            'The notification logging level ordinal was incorrect.'
        );
        LoggerSObjectHandler.shouldExecute(true);
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();

        // Update the records to trigger the handler framework, which will then run the Slack plugin
        update log;

        // Verify that the internal queueable job has been enqueued
        System.assertEquals(1, System.Limits.getAsyncCalls(), 'The queueable job should have been enqueued');
        // Stop the test so the internal queueable job runs
        System.Test.stopTest();
        log = [SELECT Id, MaxLogEntryLoggingLevelOrdinal__c, SendSlackNotification__c, SlackNotificationDate__c FROM Log__c];
        System.assertEquals(true, log.SendSlackNotification__c, 'SendSlackNotification was incorrectly set to false.');
        System.assertNotEquals(null, log.SlackNotificationDate__c, 'SlackNotificationDate was null.');
        System.assertEquals(System.today(), log.SlackNotificationDate__c.date(), 'SlackNotificationDate was not set to TODAY.');
    }

    static void mockConfigurations(LoggingLevel notificationLoggingLevel) {
        LoggerTestConfigurator.setMock(
            new LoggerPlugin__mdt(DeveloperName = 'SlackPlugin', IsEnabled__c = true, SObjectHandlerApexClass__c = SlackLoggerPlugin.class.getName())
        );
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'SlackEndpoint', Value__c = 'https://fake.slack.com/'));
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'SlackNotificationLoggingLevel', Value__c = notificationLoggingLevel.name()));
    }

    static void verifyLogEntryCountEquals(Integer expectedCount) {
        Integer existingLogEntriesCount = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(expectedCount, existingLogEntriesCount, 'Existing log entries did NOT match the expected count.');
    }

    static List<Log__c> queryLogs(LoggingLevel notificationLoggingLevel) {
        return [
            SELECT
                Id,
                MaxLogEntryLoggingLevelOrdinal__c,
                SendSlackNotification__c,
                SlackNotificationDate__c,
                (
                    SELECT Id, LoggingLevel__c, Message__c, ExceptionStackTrace__c, StackTrace__c
                    FROM LogEntries__r
                    WHERE LoggingLevelOrdinal__c >= :notificationLoggingLevel.ordinal()
                    ORDER BY Timestamp__c DESC
                    LIMIT 1
                )
            FROM Log__c
        ];
    }
}
