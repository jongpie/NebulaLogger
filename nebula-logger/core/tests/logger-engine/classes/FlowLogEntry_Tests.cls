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
        System.LoggingLevel userLoggingLevel = System.LoggingLevel.FINEST;
        System.LoggingLevel flowEntryLoggingLevel = System.LoggingLevel.DEBUG;
        System.Assert.isTrue(userLoggingLevel.ordinal() < flowEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        flowEntry.timestamp = System.now().addSeconds(-20);
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.Assert.areEqual(1, Logger.getBufferSize());
        Logger.saveLog();

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(flowEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(flowEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual(flowEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
        System.Assert.areEqual('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_auto_save_entry_when_saveLog_is_true() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.LoggingLevel userLoggingLevel = System.LoggingLevel.FINEST;
        System.LoggingLevel flowEntryLoggingLevel = System.LoggingLevel.DEBUG;
        System.Assert.isTrue(userLoggingLevel.ordinal() < flowEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        flowEntry.saveLog = true;
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(flowEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(flowEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_auto_save_entry_with_save_method_when_saveMethodName_specified() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerDataStore.setMock(LoggerMockDataStore.getJobQueue());
        System.LoggingLevel userLoggingLevel = System.LoggingLevel.FINEST;
        System.LoggingLevel flowEntryLoggingLevel = System.LoggingLevel.DEBUG;
        System.Assert.isTrue(userLoggingLevel.ordinal() < flowEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        flowEntry.saveLog = true;
        flowEntry.saveMethodName = Logger.SaveMethod.QUEUEABLE.name();
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        System.Assert.areEqual(0, LoggerMockDataStore.getJobQueue().getEnqueuedJobs().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.Assert.areEqual(1, LoggerMockDataStore.getJobQueue().getEnqueuedJobs().size());
        LoggerMockDataStore.getJobQueue().executeJobs();

        System.Assert.areEqual(Logger.SaveMethod.QUEUEABLE.name(), Logger.lastSaveMethodNameUsed);
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(flowEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(flowEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_not_save_entry_when_logging_level_not_met() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.LoggingLevel userLoggingLevel = System.LoggingLevel.ERROR;
        System.LoggingLevel flowEntryLoggingLevel = System.LoggingLevel.DEBUG;
        System.Assert.isTrue(userLoggingLevel.ordinal() > flowEntryLoggingLevel.ordinal());
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        Logger.saveLog();

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
    }

    @IsTest
    static void it_should_use_debug_as_default_level_when_faultMessage_is_null() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.LoggingLevel expectedEntryLoggingLevel = System.LoggingLevel.DEBUG;
        Logger.getUserSettings().LoggingLevel__c = expectedEntryLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowLogEntry flowEntry = createFlowLogEntry();
        System.Assert.isNull(flowEntry.faultMessage);
        System.Assert.isNull(flowEntry.loggingLevelName);
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.Assert.areEqual(1, Logger.getBufferSize());
        Logger.saveLog();

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.isNull(publishedLogEntryEvent.ExceptionMessage__c);
        System.Assert.isNull(publishedLogEntryEvent.ExceptionType__c);
        System.Assert.areEqual(expectedEntryLoggingLevel.name(), publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(flowEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_use_error_as_default_level_when_faultMessage_is_not_null() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.LoggingLevel expectedEntryLoggingLevel = System.LoggingLevel.ERROR;
        Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.FINEST.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.faultMessage = 'Whoops, a Flow error has occurred.';
        System.Assert.isNull(flowEntry.loggingLevelName);
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.Assert.areEqual(1, Logger.getBufferSize());
        Logger.saveLog();

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(flowEntry.faultMessage, publishedLogEntryEvent.ExceptionMessage__c);
        System.Assert.areEqual('Flow.FaultError', publishedLogEntryEvent.ExceptionType__c);
        System.Assert.areEqual(expectedEntryLoggingLevel.name(), publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(flowEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual('Flow', publishedLogEntryEvent.OriginType__c);
    }

    @IsTest
    static void it_should_throw_exception_when_shouldThrowFaultMessageException_is_set_to_true() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        String faultMessage = '';
        System.LoggingLevel entryLoggingLevel = System.LoggingLevel.ERROR;
        Logger.getUserSettings().LoggingLevel__c = entryLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(0, [SELECT COUNT() FROM LogEntry__c]);
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.flowName = 'MyFlow';
        flowEntry.message = 'hello from Flow';
        flowEntry.loggingLevelName = entryLoggingLevel.name();
        flowEntry.saveLog = true;
        flowEntry.faultMessage = 'Exception message';
        flowEntry.shouldThrowFaultMessageException = true;
        flowEntry.timestamp = System.now();
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        try {
            FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });

            System.Assert.areEqual(0, Logger.getBufferSize());
            System.Assert.areEqual(1, Logger.saveLogCallCount);
            System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
            System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
            LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
            System.Assert.areEqual(flowEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
            System.Assert.areEqual(flowEntry.message, publishedLogEntryEvent.Message__c);
            System.Assert.areEqual('Flow', publishedLogEntryEvent.OriginType__c);
            System.Assert.areEqual(flowEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
        } catch (Exception e) {
            faultMessage = e.getMessage();

            System.Assert.areEqual(flowEntry.faultMessage, faultMessage, 'fault message its not expected to be empty');
            System.Assert.areEqual('System.FlowException', e.getTypeName(), 'Exception type must match the one we are throwing');
        }
    }

    @IsTest
    static void it_should_set_logger_scenario() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.LoggingLevel userLoggingLevel = System.LoggingLevel.FINEST;
        System.Test.startTest();
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = userLoggingLevel.name();
        flowEntry.scenario = 'Some scenario';
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.Assert.areEqual(1, Logger.getBufferSize());
        Logger.saveLog();

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(flowEntry.scenario, publishedLogEntryEvent.TransactionScenario__c);
        System.Assert.areEqual(flowEntry.scenario, publishedLogEntryEvent.EntryScenario__c);
    }

    @IsTest
    static void it_should_add_tags_to_log_entry() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        System.LoggingLevel userLoggingLevel = System.LoggingLevel.FINEST;
        System.LoggingLevel flowEntryLoggingLevel = System.LoggingLevel.DEBUG;
        System.Assert.isTrue(userLoggingLevel.ordinal() < flowEntryLoggingLevel.ordinal());
        System.Test.startTest();
        Logger.getUserSettings().LoggingLevel__c = userLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        List<String> tags = new List<String>{ 'first tag', 'SECOND TAG' };
        FlowLogEntry flowEntry = createFlowLogEntry();
        flowEntry.loggingLevelName = flowEntryLoggingLevel.name();
        flowEntry.tagsString = String.join(tags, ', ');
        System.Assert.areEqual(0, Logger.saveLogCallCount);
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogEntry.addFlowEntries(new List<FlowLogEntry>{ flowEntry });
        System.Assert.areEqual(1, Logger.getBufferSize());
        Logger.saveLog();

        System.Assert.areEqual(0, Logger.getBufferSize());
        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(flowEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(flowEntry.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual('Flow', publishedLogEntryEvent.OriginType__c);
        List<String> publishedLogEntryEventTags = publishedLogEntryEvent.Tags__c.split('\n');
        System.Assert.areEqual(tags.size(), publishedLogEntryEventTags.size(), JSON.serializePretty(publishedLogEntryEventTags));
        Set<String> tagsSet = new Set<String>(tags);
        for (String publishedTag : publishedLogEntryEventTags) {
            publishedTag = publishedTag.trim();
            System.Assert.isTrue(tagsSet.contains(publishedTag), publishedTag + ' not found in expected tags set: ' + tagsSet);
        }
    }
}
