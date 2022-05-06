//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class FlowRecordLogEntry_Tests {
    static FlowRecordLogEntry createFlowRecordLogEntry() {
        FlowRecordLogEntry flowRecordEntry = new FlowRecordLogEntry();
        flowRecordEntry.flowName = 'MyFlowOrProcessBuilder';
        flowRecordEntry.message = 'my test message';
        flowRecordEntry.saveLog = false;

        return flowRecordEntry;
    }

    @IsTest
    static void it_should_save_entry_when_logging_level_met() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        User currentUser = new User(
            Id = UserInfo.getUserId(),
            FirstName = UserInfo.getFirstName(),
            LastName = UserInfo.getLastName(),
            Username = UserInfo.getUserName()
        );
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowRecordEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowRecordEntryLoggingLevel.ordinal());
        System.Test.startTest();
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowRecordLogEntry flowRecordEntry = createFlowRecordLogEntry();
        flowRecordEntry.loggingLevelName = flowRecordEntryLoggingLevel.name();
        flowRecordEntry.record = currentUser;
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowRecordEntry });
        System.assertEquals(1, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        String expectedUserJson = JSON.serializePretty(currentUser);
        System.assertEquals(flowRecordEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowRecordEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(currentUser.Id, publishedLogEntryEvent.RecordId__c);
        System.assertEquals(expectedUserJson, publishedLogEntryEvent.RecordJson__c);
    }

    @IsTest
    static void it_should_auto_save_entry_with_save_method_when_saveMethodName_specified() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerDataStore.setMock(LoggerMockDataStore.getJobQueue());
        User currentUser = new User(
            Id = UserInfo.getUserId(),
            FirstName = UserInfo.getFirstName(),
            LastName = UserInfo.getLastName(),
            Username = UserInfo.getUserName()
        );
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowRecordEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowRecordEntryLoggingLevel.ordinal());
        System.assertEquals(0, Limits.getQueueableJobs(), 'Test should start with 0 queueable jobs used');
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowRecordLogEntry flowRecordEntry = createFlowRecordLogEntry();
        flowRecordEntry.loggingLevelName = flowRecordEntryLoggingLevel.name();
        flowRecordEntry.record = currentUser;
        flowRecordEntry.saveLog = true;
        flowRecordEntry.saveMethodName = Logger.SaveMethod.QUEUEABLE.name();
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        System.assertEquals(0, LoggerMockDataStore.getJobQueue().getEnqueuedJobs().size());

        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowRecordEntry });
        System.assertEquals(1, LoggerMockDataStore.getJobQueue().getEnqueuedJobs().size());
        LoggerMockDataStore.getJobQueue().executeJobs();

        System.assertEquals(Logger.SaveMethod.QUEUEABLE.name(), Logger.lastSaveMethodNameUsed);
        System.assertEquals(1, LoggerMockDataStore.getJobQueue().getEnqueuedJobs().size());
        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        String expectedUserJson = JSON.serializePretty(currentUser);
        System.assertEquals(flowRecordEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowRecordEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(currentUser.Id, publishedLogEntryEvent.RecordId__c);
        System.assertEquals(expectedUserJson, publishedLogEntryEvent.RecordJson__c);
    }

    @IsTest
    static void it_should_auto_save_entry_when_saveLog_is_true() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        User currentUser = new User(
            Id = UserInfo.getUserId(),
            FirstName = UserInfo.getFirstName(),
            LastName = UserInfo.getLastName(),
            Username = UserInfo.getUserName()
        );
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowRecordEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowRecordEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowRecordLogEntry flowRecordEntry = createFlowRecordLogEntry();
        flowRecordEntry.loggingLevelName = flowRecordEntryLoggingLevel.name();
        flowRecordEntry.record = currentUser;
        flowRecordEntry.saveLog = true;
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowRecordEntry });

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        String expectedUserJson = JSON.serializePretty(currentUser);
        System.assertEquals(flowRecordEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowRecordEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(currentUser.Id, publishedLogEntryEvent.RecordId__c);
        System.assertEquals(expectedUserJson, publishedLogEntryEvent.RecordJson__c);
    }

    @IsTest
    static void it_should_not_save_entry_when_logging_level_not_met() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        User currentUser = new User(
            Id = UserInfo.getUserId(),
            FirstName = UserInfo.getFirstName(),
            LastName = UserInfo.getLastName(),
            Username = UserInfo.getUserName()
        );
        LoggingLevel userLoggingLevel = LoggingLevel.ERROR;
        LoggingLevel flowRecordEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() > flowRecordEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowRecordLogEntry flowRecordEntry = createFlowRecordLogEntry();
        flowRecordEntry.loggingLevelName = flowRecordEntryLoggingLevel.name();
        flowRecordEntry.record = currentUser;
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowRecordEntry });
        System.assertEquals(0, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
    }

    @IsTest
    static void it_should_use_debug_as_default_level_when_faultMessage_is_null() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel expectedEntryLoggingLevel = LoggingLevel.DEBUG;
        Logger.getUserSettings().LoggingLevel__c = expectedEntryLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowRecordLogEntry flowRecordEntry = createFlowRecordLogEntry();
        System.assertEquals(null, flowRecordEntry.faultMessage);
        System.assertEquals(null, flowRecordEntry.loggingLevelName);
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowRecordEntry });
        System.assertEquals(1, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals(null, publishedLogEntryEvent.ExceptionMessage__c);
        System.assertEquals(null, publishedLogEntryEvent.ExceptionType__c);
        System.assertEquals(expectedEntryLoggingLevel.name(), publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowRecordEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_use_error_as_default_level_when_faultMessage_is_not_null() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel expectedEntryLoggingLevel = LoggingLevel.ERROR;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowRecordLogEntry flowRecordEntry = createFlowRecordLogEntry();
        flowRecordEntry.faultMessage = 'Whoops, a Flow error has occurred.';
        System.assertEquals(null, flowRecordEntry.loggingLevelName);
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowRecordEntry });
        System.assertEquals(1, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals(flowRecordEntry.faultMessage, publishedLogEntryEvent.ExceptionMessage__c);
        System.assertEquals('Flow.FaultError', publishedLogEntryEvent.ExceptionType__c);
        System.assertEquals(expectedEntryLoggingLevel.name(), publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowRecordEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_set_log_scenario() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowRecordLogEntry flowRecordEntry = createFlowRecordLogEntry();
        flowRecordEntry.loggingLevelName = userLoggingLevel.name();
        flowRecordEntry.scenario = 'Some scenario';
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowRecordEntry });
        System.assertEquals(1, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals(flowRecordEntry.scenario, publishedLogEntryEvent.Scenario__c);
    }

    @IsTest
    static void it_should_add_tags_to_log_entry() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowRecordEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowRecordEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        List<String> tags = new List<String>{ 'first tag', 'SECOND TAG' };
        FlowRecordLogEntry flowRecordEntry = createFlowRecordLogEntry();
        flowRecordEntry.loggingLevelName = flowRecordEntryLoggingLevel.name();
        flowRecordEntry.tagsString = String.join(tags, ', ');
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowRecordLogEntry.addFlowRecordEntries(new List<FlowRecordLogEntry>{ flowRecordEntry });
        System.assertEquals(1, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        List<String> publishedLogEntryEventTags = publishedLogEntryEvent.Tags__c.split('\n');
        System.assertEquals(tags.size(), publishedLogEntryEventTags.size(), publishedLogEntryEventTags);
        Set<String> tagsSet = new Set<String>(tags);
        for (String publishedTag : publishedLogEntryEventTags) {
            publishedTag = publishedTag.trim();
            System.assert(tagsSet.contains(publishedTag), publishedTag + ' not found in expected tags set: ' + tagsSet);
        }
    }
}
