//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class FlowLogger_Tests {
    @IsTest
    static void it_should_add_entry_to_logger_buffer() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel entryLoggingLevel = LoggingLevel.DEBUG;
        Logger.getUserSettings().LoggingLevel__c = entryLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(0, [SELECT COUNT() FROM LogEntry__c]);
        FlowLogger.LogEntry flowEntry = new FlowLogger.LogEntry();
        flowEntry.flowName = 'MyFlow';
        flowEntry.message = 'hello from Flow';
        flowEntry.loggingLevelName = entryLoggingLevel.name();
        flowEntry.saveLog = false;
        flowEntry.timestamp = System.now();
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogger.addEntries(new List<FlowLogger.LogEntry>{ flowEntry });
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
        System.assertEquals(flowEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }

    @IsTest
    static void it_should_auto_save_entry_when_saveLog_is_true() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggingLevel entryLoggingLevel = LoggingLevel.DEBUG;
        System.Test.startTest();
        Logger.getUserSettings().LoggingLevel__c = entryLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(0, [SELECT COUNT() FROM LogEntry__c]);
        FlowLogger.LogEntry flowEntry = new FlowLogger.LogEntry();
        flowEntry.flowName = 'MyFlow';
        flowEntry.message = 'hello from Flow';
        flowEntry.loggingLevelName = entryLoggingLevel.name();
        flowEntry.saveLog = true;
        flowEntry.timestamp = System.now();
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogger.addEntries(new List<FlowLogger.LogEntry>{ flowEntry });

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(1, Logger.saveLogCallCount);
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.assertEquals(flowEntry.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.assertEquals(flowEntry.message, publishedLogEntryEvent.Message__c);
        System.assertEquals('Flow', publishedLogEntryEvent.OriginType__c);
        System.assertEquals(flowEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }

    @IsTest
    static void it_should_auto_save_entry_with_save_method_when_saveMethodName_specified() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerDataStore.setMock(LoggerMockDataStore.getJobQueue());
        LoggingLevel entryLoggingLevel = LoggingLevel.DEBUG;
        System.assertEquals(0, Limits.getQueueableJobs(), 'Test should start with 0 queueable jobs used');
        Logger.getUserSettings().LoggingLevel__c = entryLoggingLevel.name();
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(0, [SELECT COUNT() FROM LogEntry__c]);
        FlowLogger.LogEntry flowEntry = new FlowLogger.LogEntry();
        flowEntry.flowName = 'MyFlow';
        flowEntry.message = 'hello from Flow';
        flowEntry.loggingLevelName = entryLoggingLevel.name();
        flowEntry.saveLog = true;
        flowEntry.saveMethodName = Logger.SaveMethod.QUEUEABLE.name();
        flowEntry.timestamp = System.now();
        System.assertEquals(0, Logger.saveLogCallCount);
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.assertEquals(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());

        FlowLogger.addEntries(new List<FlowLogger.LogEntry>{ flowEntry });
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
        System.assertEquals(flowEntry.timestamp, publishedLogEntryEvent.Timestamp__c);
    }
}
