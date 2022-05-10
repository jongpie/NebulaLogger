//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class FlowLogEntry_Tests {
    static FlowLogEntry createFlowLogEntry() {
        FlowLogEntry flowEntry = new FlowLogEntry();
        flowEntry.flowName = 'MyFlowOrProcessBuilder';
        flowEntry.message = 'my test message';
        flowEntry.saveLog = false;

        return flowEntry;
    }

    @IsTest
    static void it_should_save_entry_when_logging_level_met() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.assertEquals(1, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals(flowEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_auto_save_entry_when_saveLog_is_true() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        flowEntry.saveLog = true;
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals(flowEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_auto_save_entry_with_save_method_when_saveMethodName_specified() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerDataStore.setMock(LoggerMockDataStore.getJobQueue());
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        flowEntry.saveLog = true;
        flowEntry.saveMethodName = Logger.SaveMethod.QUEUEABLE.name();
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        System.assertEquals(0, LoggerMockDataStore.getJobQueue().getEnqueuedJobs().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.assertEquals(1, LoggerMockDataStore.getJobQueue().getEnqueuedJobs().size());
        LoggerMockDataStore.getJobQueue().executeJobs();

        System.assertEquals(Logger.SaveMethod.QUEUEABLE.name(), Logger.lastSaveMethodNameUsed);
        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals(flowEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_not_save_entry_when_logging_level_not_met() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel userLoggingLevel = LoggingLevel.ERROR;
        LoggingLevel flowEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() > flowEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
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
        FlowLogEntry flowEntry = createFlowLogEntry();
        System.assertEquals(null, flowEntry.faultMessage);
        System.assertEquals(null, flowEntry.loggingLevelName);
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
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
        System.assertEquals(flowEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_use_error_as_default_level_when_faultMessage_is_not_null() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel expectedEntryLoggingLevel = LoggingLevel.ERROR;
        Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.faultMessage = 'Whoops, a Flow error has occurred.';
        System.assertEquals(null, flowEntry.loggingLevelName);
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.assertEquals(1, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals(flowEntry.faultMessage, publishedLogEntryEvent.ExceptionMessage__c);
        System.assertEquals('Flow.FaultError', publishedLogEntryEvent.ExceptionType__c);
        System.assertEquals(expectedEntryLoggingLevel.name(), publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_set_log_scenario() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        System.Test.startTest();
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = userLoggingLevel.name();
        flowEntry.scenario = 'Some scenario';
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.assertEquals(1, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals(flowEntry.scenario, publishedLogEntryEvent.Scenario__c);
    }

    @IsTest
    static void it_should_add_tags_to_log_entry() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel userLoggingLevel = LoggingLevel.FINEST;
        LoggingLevel flowEntryLoggingLevel = LoggingLevel.DEBUG;
        System.assert(userLoggingLevel.ordinal() < flowEntryLoggingLevel.ordinal());
        System.Test.startTest();
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        List<String> tags = new List<String>{ 'first tag', 'SECOND TAG' };
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        flowEntry.tagsString = String.join(tags, ', ');
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.assertEquals(1, Logger.getBufferSize());
        Logger.saveLog();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals(flowEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowEntry.message, publishedLogEntryEvent.Message__c);
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
