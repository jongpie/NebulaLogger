//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class FlowCollectionLogEntry_Tests {
    static FlowCollectionLogEntry createFlowCollectionLogEntry() {
        FlowCollectionLogEntry flowCollectionEntry = new FlowCollectionLogEntry();
        flowCollectionEntry.flowName = 'MyFlowOrProcessBuilder';
        flowCollectionEntry.message = 'my test message';
        flowCollectionEntry.saveLog = false;

        return flowCollectionEntry;
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
        LoggingLevel flowCollectionEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowCollectionEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowCollectionLogEntry flowCollectionEntry = createFlowCollectionLogEntry();
        flowCollectionEntry.loggingLevelName = flowCollectionEntryLoggingLevel.name();
        flowCollectionEntry.records = new List<SObject>{ currentUser };
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowCollectionLogEntry.addFlowCollectionEntries(new List<FlowCollectionLogEntry>{ flowCollectionEntry });
        System.assertEquals(1, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        String expectedUserJson = JSON.serializePretty(new List<SObject>{ currentUser });
        System.assertEquals(flowCollectionEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowCollectionEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(null, publishedLogEntryEvent.RecordId__c);
        System.assertEquals('List', publishedLogEntryEvent.RecordCollectionType__c);
        System.assertEquals('User', publishedLogEntryEvent.RecordSObjectType__c);
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
        LoggingLevel flowCollectionEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowCollectionEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowCollectionLogEntry flowCollectionEntry = createFlowCollectionLogEntry();
        flowCollectionEntry.loggingLevelName = flowCollectionEntryLoggingLevel.name();
        flowCollectionEntry.records = new List<SObject>{ currentUser };
        flowCollectionEntry.saveLog = true;
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowCollectionLogEntry.addFlowCollectionEntries(new List<FlowCollectionLogEntry>{ flowCollectionEntry });

        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        String expectedUserJson = JSON.serializePretty(new List<SObject>{ currentUser });
        System.assertEquals(flowCollectionEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowCollectionEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(null, publishedLogEntryEvent.RecordId__c);
        System.assertEquals('List', publishedLogEntryEvent.RecordCollectionType__c);
        System.assertEquals('User', publishedLogEntryEvent.RecordSObjectType__c);
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
        LoggingLevel flowCollectionEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowCollectionEntryLoggingLevel.ordinal());
        System.Test.startTest();
        System.assertEquals(0, Limits.getQueueableJobs(), 'Test should start with 0 queueable jobs used');
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowCollectionLogEntry flowCollectionEntry = createFlowCollectionLogEntry();
        flowCollectionEntry.loggingLevelName = flowCollectionEntryLoggingLevel.name();
        flowCollectionEntry.records = new List<SObject>{ currentUser };
        flowCollectionEntry.saveLog = true;
        flowCollectionEntry.saveMethodName = Logger.SaveMethod.QUEUEABLE.name();
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        System.assertEquals(0, LoggerMockDataStore.getJobQueue().getEnqueuedJobs().size());

        FlowCollectionLogEntry.addFlowCollectionEntries(new List<FlowCollectionLogEntry>{ flowCollectionEntry });
        System.assertEquals(1, LoggerMockDataStore.getJobQueue().getEnqueuedJobs().size());
        LoggerMockDataStore.getJobQueue().executeJobs();

        System.assertEquals(Logger.SaveMethod.QUEUEABLE.name(), Logger.lastSaveMethodNameUsed);
        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        String expectedUserJson = JSON.serializePretty(new List<SObject>{ currentUser });
        System.assertEquals(flowCollectionEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowCollectionEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(null, publishedLogEntryEvent.RecordId__c);
        System.assertEquals('List', publishedLogEntryEvent.RecordCollectionType__c);
        System.assertEquals('User', publishedLogEntryEvent.RecordSObjectType__c);
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
        LoggingLevel flowCollectionEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() > flowCollectionEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowCollectionLogEntry flowCollectionEntry = createFlowCollectionLogEntry();
        flowCollectionEntry.loggingLevelName = flowCollectionEntryLoggingLevel.name();
        flowCollectionEntry.records = new List<SObject>{ currentUser };
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowCollectionLogEntry.addFlowCollectionEntries(new List<FlowCollectionLogEntry>{ flowCollectionEntry });
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
        FlowCollectionLogEntry flowCollectionEntry = createFlowCollectionLogEntry();
        System.assertEquals(null, flowCollectionEntry.faultMessage);
        System.assertEquals(null, flowCollectionEntry.loggingLevelName);
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowCollectionLogEntry.addFlowCollectionEntries(new List<FlowCollectionLogEntry>{ flowCollectionEntry });
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
        System.assertEquals(flowCollectionEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_use_error_as_default_level_when_faultMessage_is_not_null() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel expectedEntryLoggingLevel = LoggingLevel.ERROR;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowCollectionLogEntry flowCollectionEntry = createFlowCollectionLogEntry();
        flowCollectionEntry.faultMessage = 'Whoops, a Flow error has occurred.';
        System.assertEquals(null, flowCollectionEntry.loggingLevelName);
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowCollectionLogEntry.addFlowCollectionEntries(new List<FlowCollectionLogEntry>{ flowCollectionEntry });
        System.assertEquals(1, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals(flowCollectionEntry.faultMessage, publishedLogEntryEvent.ExceptionMessage__c);
        System.assertEquals('Flow.FaultError', publishedLogEntryEvent.ExceptionType__c);
        System.assertEquals(expectedEntryLoggingLevel.name(), publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowCollectionEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_set_log_scenario() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowCollectionLogEntry flowCollectionEntry = createFlowCollectionLogEntry();
        flowCollectionEntry.loggingLevelName = userLoggingLevel.name();
        flowCollectionEntry.scenario = 'Some scenario';
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowCollectionLogEntry.addFlowCollectionEntries(new List<FlowCollectionLogEntry>{ flowCollectionEntry });
        System.assertEquals(1, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals(flowCollectionEntry.scenario, publishedLogEntryEvent.Scenario__c);
    }

    @IsTest
    static void it_should_add_tags_to_log_entry() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowCollectionEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowCollectionEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        List<String> tags = new List<String>{ 'first tag', 'SECOND TAG' };
        FlowCollectionLogEntry flowCollectionEntry = createFlowCollectionLogEntry();
        flowCollectionEntry.loggingLevelName = flowCollectionEntryLoggingLevel.name();
        flowCollectionEntry.tagsString = String.join(tags, ', ');
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowCollectionLogEntry.addFlowCollectionEntries(new List<FlowCollectionLogEntry>{ flowCollectionEntry });
        System.assertEquals(1, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals(flowCollectionEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowCollectionEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
        List<String> publishedLogEntryEventTags = publishedLogEntryEvent.Tags__c.split('\n');
        System.assertEquals(tags.size(), publishedLogEntryEventTags.size(), publishedLogEntryEventTags);
        Set<String> tagsSet = new Set<String>(tags);
        for (String publishedTag : publishedLogEntryEventTags) {
            publishedTag = publishedTag.trim();
            System.assert(tagsSet.contains(publishedTag), publishedTag + ' not found in expected tags set: ' + tagsSet);
        }
    }
}
