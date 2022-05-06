//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LogEntryEventHandler_Tests {
    private static final String MOCK_RELEASE_NUMBER = '230.12.2';
    private static final String MOCK_RELEASE_VERSION = 'Spring \'21 Patch 12.2';

    @IsTest
    static void it_should_return_the_logEntryEvent_sobjectType() {
        System.assertEquals(Schema.LogEntryEvent__e.SObjectType, new LogEntryEventHandler().getSObjectType());
    }

    @IsTest
    static void it_should_not_run_when_disabled_via_configuration() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntryEvent__e.SObjectType).IsEnabled__c = false;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();

        LoggerDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.assertEquals(
            0,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should not have executed'
        );
    }

    @IsTest
    static void it_should_gracefully_skip_execution_when_logEntryEvents_list_is_empty() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        Integer countOfLogs = [SELECT COUNT() FROM Log__c];
        System.assertEquals(0, countOfLogs);
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        List<Database.SaveResult> saveResults = LoggerMockDataStore.getEventBus().publishRecords(new List<LogEntryEvent__e>());
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.assertEquals(true, saveResults.isEmpty());
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        countOfLogs = [SELECT COUNT() FROM Log__c];
        System.assertEquals(0, countOfLogs);
        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);
    }

    @IsTest
    static void it_should_not_create_log_or_log_entry_data_when_platform_event_storage_is_disabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        Integer countOfLogs = [SELECT COUNT() FROM Log__c];
        System.assertEquals(0, countOfLogs);
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);
        LoggerSettings__c settings = Logger.getUserSettings();
        settings.IsEnabled__c = true;
        settings.IsSavingEnabled__c = true;
        settings.DefaultPlatformEventStorageLocation__c = null;
        upsert settings;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        countOfLogs = [SELECT COUNT() FROM Log__c];
        System.assertEquals(0, countOfLogs);
        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);
    }

    @IsTest
    static void it_should_normalize_event_data_into_log_and_log_entry() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @IsTest
    static void it_should_normalize_event_data_for_multiple_transactions_into_multiple_logs() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        List<String> transactionIds = new List<String>{ '123-456', '789-0' };
        System.assertEquals(2, transactionIds.size());
        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        for (Integer i = 0; i < transactionIds.size(); i++) {
            LogEntryEvent__e logEntryEvent = createLogEntryEvent();
            logEntryEvent.TransactionEntryNumber__c = i;
            logEntryEvent.TransactionId__c = transactionIds.get(i);
            logEntryEvents.add(logEntryEvent);
        }
        System.assertEquals(transactionIds.size(), logEntryEvents.size());

        List<Database.SaveResult> saveResults = LoggerMockDataStore.getEventBus().publishRecords(logEntryEvents);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.assertEquals(transactionIds.size(), saveResults.size());
        for (Database.SaveResult saveResult : saveResults) {
            System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        }
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        List<Log__c> logs = [SELECT Id, TransactionId__c, (SELECT Id FROM LogEntries__r) FROM Log__c];
        System.assertEquals(2, logs.size(), logs);
        Set<String> uniqueTransactionIds = new Set<String>(transactionIds);
        for (Log__c log : logs) {
            System.assert(uniqueTransactionIds.contains(log.TransactionId__c), log.TransactionId__c);
            System.assertEquals(1, log.LogEntries__r.size());
        }
    }

    // TODO - testing topics is tricky. Within the unlocked package, we can test it,
    // but for people that prefer using the unpackaged metadata + don't use topics,
    // the tests would fail. Need to further investigate ways to handle this
    // @IsTest
    // static void it_should_create_topic_and_topicAssignment_records_when_enabled() {
    //     String transactionId = '123-456-789-0';

    //     List<String> tags = new List<String>{ 'test-tag-1', 'test-tag-2' };
    //     LogEntryEvent__e logEntryEvent = new LogEntryEvent__e(
    //         EpochTimestamp__c = System.now().getTime(),
    //         Message__c = 'my message',
    //         Timestamp__c = System.now(),
    //         Tags__c = String.join(tags, '\n'),
    //         TransactionEntryNumber__c = 1,
    //         TransactionId__c = transactionId
    //     );

    //     System.Test.startTest();
    //     LogEntryEventHandler.TAGGING_IS_ENABLED = true;
    //     LogEntryEventHandler.TAG_USING_TOPICS = true;
    //     Database.SaveResult saveResult = EventBus.publish(logEntryEvent);
    //     System.Test.stopTest();

    //     System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());

    //     Log__c log = getLog();
    //     System.assertEquals(1, log.LogEntries__r.size());
    //     LogEntry__c logEntry = log.LogEntries__r.get(0);

    //     System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
    //     validateLogFields(logEntryEvent, log);
    //     validateLogEntryFields(logEntryEvent, logEntry);

    //     Set<String> tagsSet = new Set<String>(tags);
    //     List<TopicAssignment> topicAssignments = [SELECT Id, EntityId, TopicId, Topic.Name FROM TopicAssignment WHERE EntityId = :logEntry.Id];
    //     for (TopicAssignment topicAssignment : topicAssignments) {
    //         System.assert(tagsSet.contains(topicAssignment.Topic.Name));
    //     }
    // }

    @IsTest
    static void it_should_create_tag_records_when_enabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.assertEquals(true, LoggerParameter.TAGGING_IS_ENABLED, 'Tagging is not enabled within test context, cannot execute tagging test');
        List<String> tags = new List<String>{ 'test-tag-1', 'test-tag-2' };
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.Tags__c = String.join(tags, '\n');

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
        List<LogEntryTag__c> logEntryTags = [SELECT Id, LogEntry__c, Tag__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        System.assertEquals(tags.size(), logEntryTags.size());
        Set<String> tagsSet = new Set<String>(tags);
        for (LogEntryTag__c logEntryTag : logEntryTags) {
            System.assert(tagsSet.contains(logEntryTag.Tag__r.Name));
        }
    }

    @IsTest
    static void it_should_reuse_existing_tag_records() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.assertEquals(true, LoggerParameter.TAGGING_IS_ENABLED, 'Tagging is not enabled within test context, cannot execute tagging test');
        String testTagName = 'Some tag!';
        LoggerTag__c tag = new LoggerTag__c(Name = testTagName);
        insert tag;
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.Tags__c = testTagName;

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
        Integer countOfTagsWithTagName = [SELECT COUNT() FROM LoggerTag__c WHERE Name = :testTagName];
        System.assertEquals(1, countOfTagsWithTagName);
        LogEntryTag__c logEntryTag = [SELECT Id, LogEntry__c, Tag__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        System.assertEquals(tag.Id, logEntryTag.Tag__c);
        System.assertEquals(tag.Name, logEntryTag.Tag__r.Name);
    }

    @IsTest
    static void it_should_append_tags_for_contains_rule() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.assertEquals(true, LoggerParameter.TAGGING_IS_ENABLED, 'Tagging is not enabled within test context, cannot execute tagging test');
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.Message__c = 'my message';
        logEntryEvent.Tags__c = null;
        String configuredTagName = 'CMDT Tag';
        LoggerTestConfigurator.setMock(
            new LogEntryTagRule__mdt(
                SObjectField__c = Schema.LogEntry__c.Message__c.getDescribe().getName(),
                ComparisonType__c = 'CONTAINS',
                ComparisonValue__c = logEntryEvent.Message__c.substring(1, 4),
                Tags__c = configuredTagName
            )
        );

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
        Integer countOfTagsWithTagName = [SELECT COUNT() FROM LoggerTag__c WHERE Name = :configuredTagName];
        System.assertEquals(1, countOfTagsWithTagName);
        LogEntryTag__c logEntryTag = [SELECT Id, LogEntry__c, Tag__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        System.assertEquals(configuredTagName, logEntryTag.Tag__r.Name);
    }

    @IsTest
    static void it_should_append_tags_for_equals_rule() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.assertEquals(true, LoggerParameter.TAGGING_IS_ENABLED, 'Tagging is not enabled within test context, cannot execute tagging test');
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.Tags__c = null;
        String configuredTagName = 'CMDT Tag';
        LoggerTestConfigurator.setMock(
            new LogEntryTagRule__mdt(
                SObjectField__c = Schema.LogEntry__c.Message__c.getDescribe().getName(),
                ComparisonType__c = 'EQUALS',
                ComparisonValue__c = logEntryEvent.Message__c,
                Tags__c = configuredTagName
            )
        );

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
        Integer countOfTagsWithTagName = [SELECT COUNT() FROM LoggerTag__c WHERE Name = :configuredTagName];
        System.assertEquals(1, countOfTagsWithTagName);
        LogEntryTag__c logEntryTag = [SELECT Id, LogEntry__c, Tag__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        System.assertEquals(configuredTagName, logEntryTag.Tag__r.Name);
    }

    @IsTest
    static void it_should_append_tags_for_regex_rule() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.assertEquals(true, LoggerParameter.TAGGING_IS_ENABLED, 'Tagging is not enabled within test context, cannot execute tagging test');
        String zipCodeRegEx = '(^[0-9]{4}?[0-9]$|^[0-9]{4}?[0-9]-[0-9]{4}$)';
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.Message__c = '94541';
        logEntryEvent.Tags__c = null;
        String configuredTagName = 'CMDT Tag';
        LoggerTestConfigurator.setMock(
            new LogEntryTagRule__mdt(
                SObjectField__c = Schema.LogEntry__c.Message__c.getDescribe().getName(),
                ComparisonType__c = 'MATCHES_REGEX',
                ComparisonValue__c = zipCodeRegEx,
                Tags__c = configuredTagName
            )
        );

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
        Integer countOfTagsWithTagName = [SELECT COUNT() FROM LoggerTag__c WHERE Name = :configuredTagName];
        System.assertEquals(1, countOfTagsWithTagName);
        LogEntryTag__c logEntryTag = [SELECT Id, LogEntry__c, Tag__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        System.assertEquals(configuredTagName, logEntryTag.Tag__r.Name);
    }

    @IsTest
    static void it_should_append_tags_for_startsWith_rule() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.assertEquals(true, LoggerParameter.TAGGING_IS_ENABLED, 'Tagging is not enabled within test context, cannot execute tagging test');
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        logEntryEvent.Message__c = 'my message';
        logEntryEvent.Tags__c = null;
        String configuredTagName = 'CMDT Tag';
        LoggerTestConfigurator.setMock(
            new LogEntryTagRule__mdt(
                SObjectField__c = Schema.LogEntry__c.Message__c.getDescribe().getName(),
                ComparisonType__c = 'STARTS_WITH',
                ComparisonValue__c = logEntryEvent.Message__c.left(3),
                Tags__c = configuredTagName
            )
        );

        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
        Integer countOfTagsWithTagName = [SELECT COUNT() FROM LoggerTag__c WHERE Name = :configuredTagName];
        System.assertEquals(1, countOfTagsWithTagName);
        LogEntryTag__c logEntryTag = [SELECT Id, LogEntry__c, Tag__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        System.assertEquals(configuredTagName, logEntryTag.Tag__r.Name);
    }

    @IsTest
    static void it_should_set_api_release_number_and_api_release_version_from_callout_when_enabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.Test.setMock(HttpCalloutMock.class, LoggerMockDataCreator.createHttpCallout().setStatusCode(200).setResponseBody(createStatusApiResponseJson()));
        LoggerParameter__mdt mockCallStatusApiParameter = new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = 'true');
        LoggerTestConfigurator.setMock(mockCallStatusApiParameter);
        System.assertEquals(true, LoggerParameter.CALL_STATUS_API);
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();

        // TODO System.Test.startTest() & stopTest() are still being used so that the callout in LogEntryEventHandler executes,
        // but it be nice if this was instead mocked via LoggerMockDataStore (? or some other similar class?)
        System.Test.startTest();
        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());
        System.Test.stopTest();

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.assertEquals(MOCK_RELEASE_NUMBER, log.ApiReleaseNumber__c);
        System.assertEquals(MOCK_RELEASE_VERSION, log.ApiReleaseVersion__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @IsTest
    static void it_should_set_api_release_number_and_api_release_version_from_recent_record() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        Log__c recentLog = new Log__c(ApiReleaseNumber__c = 'QWERTY', ApiReleaseVersion__c = 'ASDF', TransactionId__c = 'ABC-XYZ');
        insert recentLog;
        insert new LogEntry__c(Log__c = recentLog.Id, Timestamp__c = System.now().addHours(-1));
        LoggerParameter__mdt mockCallStatusApiParameter = new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = 'true');
        LoggerTestConfigurator.setMock(mockCallStatusApiParameter);
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();

        // TODO System.Test.startTest() & stopTest() are still being used so that the callout in LogEntryEventHandler executes,
        // but it be nice if this was instead mocked via LoggerMockDataStore (? or some other similar class?)
        System.Test.startTest();
        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());
        System.Test.stopTest();

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        System.assertEquals(0, Limits.getCallouts());
        Log__c log = getLog();
        System.assertNotEquals(recentLog.Id, log.Id, log.StartTime__c);
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.assertEquals(recentLog.ApiReleaseNumber__c, log.ApiReleaseNumber__c);
        System.assertEquals(recentLog.ApiReleaseVersion__c, log.ApiReleaseVersion__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @IsTest
    static void it_should_set_not_api_release_number_or_api_release_version_from_callout_when_disabled() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.Test.setMock(HttpCalloutMock.class, LoggerMockDataCreator.createHttpCallout().setStatusCode(400).setResponseBody(createStatusApiResponseJson()));
        LoggerParameter__mdt mockCallStatusApiParameter = new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = 'false');
        LoggerTestConfigurator.setMock(mockCallStatusApiParameter);
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();

        // TODO System.Test.startTest() & stopTest() are still being used so that the callout in LogEntryEventHandler executes,
        // but it be nice if this was instead mocked via LoggerMockDataStore (? or some other similar class?)
        System.Test.startTest();
        Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
        LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());
        System.Test.stopTest();

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        System.assertEquals(0, Limits.getCallouts());
        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        System.assertEquals(null, log.ApiReleaseNumber__c);
        System.assertEquals(null, log.ApiReleaseVersion__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @IsTest
    static void it_should_skip_setting_api_release_number_and_api_release_version_when_callout_fails() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
        System.Test.setMock(HttpCalloutMock.class, LoggerMockDataCreator.createHttpCallout().setStatusCode(400).setResponseBody(createStatusApiResponseJson()));
        LoggerParameter__mdt mockCallStatusApiParameter = new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = 'true');
        LoggerTestConfigurator.setMock(mockCallStatusApiParameter);
        LogEntryEvent__e logEntryEvent = createLogEntryEvent();
        Database.SaveResult saveResult;

        try {
            // TODO System.Test.startTest() & stopTest() are still being used so that the callout in LogEntryEventHandler executes,
            // but it be nice if this was instead mocked via LoggerMockDataStore (? or some other similar class?)
            System.Test.startTest();
            saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
            LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());
            System.Test.stopTest();
            System.assert(false, 'Exception expected, this assert should not run');
        } catch (Exception ex) {
            System.assertEquals(CalloutException.class.getName(), ex.getTypeName());
            String expectedErrorMessage = 'Callout failed for https://api.status.salesforce.com/v1/instances/';
            System.assert(ex.getMessage().contains(expectedErrorMessage));
        }

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());
        System.assertEquals(
            1,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
            'Handler class should have executed one time for AFTER_INSERT'
        );
        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);
        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        System.assertEquals(null, log.ApiReleaseNumber__c);
        System.assertEquals(null, log.ApiReleaseVersion__c);
        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    private static LogEntryEvent__e createLogEntryEvent() {
        // The data builder class handles populating field values, but for some fields,
        // certain values are expected (e.g., LoggedById__c should have a valid user ID),
        // so this method handles any additional manipulation to the field values
        LogEntryEvent__e logEntryEvent = (LogEntryEvent__e) LoggerMockDataCreator.createDataBuilder(Schema.LogEntryEvent__e.SObjectType)
            .populateAllFields()
            .getRecord();
        logEntryEvent.LoggedById__c = UserInfo.getUserId();
        logEntryEvent.LoggingLevel__c = LoggingLevel.INFO.name();
        logEntryEvent.LoggingLevelOrdinal__c = LoggingLevel.INFO.ordinal();
        logEntryEvent.UserLoggingLevel__c = LoggingLevel.INFO.name();
        logEntryEvent.UserLoggingLevelOrdinal__c = LoggingLevel.INFO.ordinal();
        logEntryEvent.ProfileId__c = UserInfo.getProfileId();
        logEntryEvent.TimestampString__c = String.valueOf(logEntryEvent.Timestamp__c.getTime());
        logEntryEvent.RecordId__c = UserInfo.getUserId();
        logEntryEvent.RecordCollectionSize__c = 1;
        logEntryEvent.RecordCollectionType__c = 'Single';

        return logEntryEvent;
    }

    private static String createStatusApiResponseJson() {
        LogEntryEventHandler.StatusApiResponse apiResponse = new LogEntryEventHandler.StatusApiResponse();
        apiResponse.releaseNumber = MOCK_RELEASE_NUMBER;
        apiResponse.releaseVersion = MOCK_RELEASE_VERSION;
        return JSON.serialize(apiResponse);
    }

    private static Log__c getLog() {
        return [
            SELECT
                ApiReleaseNumber__c,
                ApiReleaseVersion__c,
                ApiVersion__c,
                Id,
                Locale__c,
                LoggedBy__c,
                LoggedByUsername__c,
                LoggerVersionNumber__c,
                LoginDomain__c,
                LoginHistoryId__c,
                LoginType__c,
                LogoutUrl__c,
                NetworkId__c,
                OrganizationDomainUrl__c,
                OrganizationEnvironmentType__c,
                OrganizationId__c,
                OrganizationInstanceName__c,
                OrganizationName__c,
                OrganizationNamespacePrefix__c,
                OrganizationType__c,
                OwnerId,
                ParentLogTransactionId__c,
                ProfileId__c,
                ProfileName__c,
                Scenario__c,
                SessionId__c,
                SessionSecurityLevel__c,
                SessionType__c,
                SourceIp__c,
                StartTime__c,
                SystemMode__c,
                ThemeDisplayed__c,
                TimeZoneId__c,
                TimeZoneName__c,
                TransactionId__c,
                UserLicenseDefinitionKey__c,
                UserLicenseId__c,
                UserLicenseName__c,
                UserLoggingLevel__c,
                UserLoggingLevelOrdinal__c,
                UserRoleId__c,
                UserRoleName__c,
                UserType__c,
                (
                    SELECT
                        ComponentType__c,
                        DatabaseResultCollectionSize__c,
                        DatabaseResultCollectionType__c,
                        DatabaseResultJson__c,
                        DatabaseResultType__c,
                        EpochTimestamp__c,
                        ExceptionStackTrace__c,
                        ExceptionType__c,
                        HttpRequestBody__c,
                        HttpRequestBodyMasked__c,
                        HttpRequestCompressed__c,
                        HttpRequestEndpoint__c,
                        HttpRequestMethod__c,
                        HttpResponseBody__c,
                        HttpResponseBodyMasked__c,
                        HttpResponseHeaderKeys__c,
                        HttpResponseStatus__c,
                        HttpResponseStatusCode__c,
                        LimitsAggregateQueriesMax__c,
                        LimitsAggregateQueriesUsed__c,
                        LimitsAsyncCallsMax__c,
                        LimitsAsyncCallsUsed__c,
                        LimitsCalloutsMax__c,
                        LimitsCalloutsUsed__c,
                        LimitsCpuTimeMax__c,
                        LimitsCpuTimeUsed__c,
                        LimitsDmlRowsMax__c,
                        LimitsDmlRowsUsed__c,
                        LimitsDmlStatementsMax__c,
                        LimitsDmlStatementsUsed__c,
                        LimitsEmailInvocationsMax__c,
                        LimitsEmailInvocationsUsed__c,
                        LimitsFutureCallsMax__c,
                        LimitsFutureCallsUsed__c,
                        LimitsHeapSizeMax__c,
                        LimitsHeapSizeUsed__c,
                        LimitsMobilePushApexCallsMax__c,
                        LimitsMobilePushApexCallsUsed__c,
                        LimitsPublishImmediateDmlStatementsMax__c,
                        LimitsPublishImmediateDmlStatementsUsed__c,
                        LimitsQueueableJobsMax__c,
                        LimitsQueueableJobsUsed__c,
                        LimitsSoqlQueriesMax__c,
                        LimitsSoqlQueriesUsed__c,
                        LimitsSoqlQueryLocatorRowsMax__c,
                        LimitsSoqlQueryLocatorRowsUsed__c,
                        LimitsSoqlQueryRowsMax__c,
                        LimitsSoqlQueryRowsUsed__c,
                        LimitsSoslSearchesUsed__c,
                        LimitsSoslSearchesMax__c,
                        Log__c,
                        LoggingLevel__c,
                        LoggingLevelOrdinal__c,
                        Message__c,
                        MessageTruncated__c,
                        Id,
                        Name,
                        OriginType__c,
                        OriginLocation__c,
                        RecordCollectionSize__c,
                        RecordCollectionType__c,
                        RecordId__c,
                        RecordJson__c,
                        RecordJsonMasked__c,
                        RecordSObjectClassification__c,
                        RecordSObjectType__c,
                        RecordSObjectTypeNamespace__c,
                        StackTrace__c,
                        Timestamp__c,
                        TransactionEntryNumber__c,
                        TriggerIsExecuting__c,
                        TriggerOperationType__c,
                        TriggerSObjectType__c
                    FROM LogEntries__r
                )
            FROM Log__c
            ORDER BY StartTime__c DESC
            LIMIT 1
        ];
    }

    private static void validateLogFields(LogEntryEvent__e logEntryEvent, Log__c log) {
        Organization org = [SELECT Id, Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization];
        String orgEnvironmentType;
        if (org.IsSandbox == true && org.TrialExpirationDate != null) {
            orgEnvironmentType = 'Scratch Org';
        } else if (org.IsSandbox == true) {
            orgEnvironmentType = 'Sandbox';
        } else {
            orgEnvironmentType = 'Production';
        }

        Id logOwnerId = logEntryEvent.LoggedById__c == null ? UserInfo.getUserId() : logEntryEvent.LoggedById__c;

        System.assertEquals(logEntryEvent.ApiVersion__c, log.ApiVersion__c, 'log.ApiVersion__c was not properly set');
        System.assertEquals(logEntryEvent.Locale__c, log.Locale__c, 'log.Locale__c was not properly set');
        System.assertEquals(logEntryEvent.LoggedById__c, log.LoggedBy__c, 'log.LoggedBy__c was not properly set');
        System.assertEquals(logEntryEvent.LoggedByUsername__c, log.LoggedByUsername__c, 'log.LoggedByUsername__c was not properly set');
        System.assertEquals(logEntryEvent.LoggerVersionNumber__c, log.LoggerVersionNumber__c, 'log.LoggerVersionNumber__c was not properly set');
        System.assertEquals(logEntryEvent.LoginDomain__c, log.LoginDomain__c, 'log.LoginDomain__c was not properly set');
        System.assertEquals(logEntryEvent.LoginHistoryId__c, log.LoginHistoryId__c, 'log.LoginHistoryId__c was not properly set');
        System.assertEquals(logEntryEvent.LoginType__c, log.LoginType__c, 'log.LoginType__c was not properly set');
        System.assertEquals(logEntryEvent.LogoutUrl__c, log.LogoutUrl__c, 'log.LogoutUrl__c was not properly set');
        System.assertEquals(logEntryEvent.NetworkId__c, log.NetworkId__c, 'log.NetworkId__c was not properly set');
        System.assertEquals(logOwnerId, log.OwnerId, 'log.OwnerId was not properly set');
        System.assertEquals(logEntryEvent.ParentLogTransactionId__c, log.ParentLogTransactionId__c, 'log.ParentLogTransactionId__c was not properly set');
        System.assertEquals(logEntryEvent.ProfileId__c, log.ProfileId__c, 'log.ProfileId__c was not properly set');
        System.assertEquals(logEntryEvent.ProfileName__c, log.ProfileName__c, 'log.ProfileName__c was not properly set');
        System.assertEquals(logEntryEvent.Scenario__c, log.Scenario__c, 'log.Scenario__c was not properly set');
        System.assertEquals(logEntryEvent.SessionId__c, log.SessionId__c, 'log.SessionId__c was not properly set');
        System.assertEquals(logEntryEvent.SessionId__c, log.SessionId__c, 'log.SessionId__c was not properly set');
        System.assertEquals(logEntryEvent.SessionSecurityLevel__c, log.SessionSecurityLevel__c, 'log.SessionSecurityLevel__c was not properly set');
        System.assertEquals(logEntryEvent.SessionType__c, log.SessionType__c, 'log.SessionType__c was not properly set');
        System.assertEquals(logEntryEvent.SourceIp__c, log.SourceIp__c, 'log.SourceIp__c was not properly set');
        System.assertEquals(logEntryEvent.SystemMode__c, log.SystemMode__c, 'log.SystemMode__c was not properly set');
        System.assertEquals(logEntryEvent.ThemeDisplayed__c, log.ThemeDisplayed__c, 'log.ThemeDisplayed__c was not properly set');
        System.assertEquals(logEntryEvent.TimeZoneId__c, log.TimeZoneId__c, 'log.TimeZoneId__c was not properly set');
        System.assertEquals(logEntryEvent.TimeZoneName__c, log.TimeZoneName__c, 'log.TimeZoneName__c was not properly set');
        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c, 'log.TransactionId__c was not properly set');
        System.assertEquals(logEntryEvent.UserLoggingLevel__c, log.UserLoggingLevel__c, 'log.UserLoggingLevel__c was not properly set');
        System.assertEquals(logEntryEvent.UserLoggingLevelOrdinal__c, log.UserLoggingLevelOrdinal__c, 'log.UserLoggingLevelOrdinal__c was not properly set');
        // System.assertEquals(currentUser.UserRoleId, log.UserRoleId__c, 'log.UserRoleId__c was not properly set');
        // System.assertEquals(currentUser.UserRoleId == null ? null : currentUser.UserRole.Name, log.UserRoleName__c, 'log.UserRoleName__c was not properly set');
        System.assertEquals(logEntryEvent.UserType__c, log.UserType__c, 'log.UserType__c was not properly set');

        // Org fields
        System.assertEquals(logEntryEvent.OrganizationDomainUrl__c, log.OrganizationDomainUrl__c, 'log.OrganizationDomainUrl__c was not properly set');
        System.assertEquals(
            logEntryEvent.OrganizationEnvironmentType__c,
            log.OrganizationEnvironmentType__c,
            'log.OrganizationEnvironmentType__c was not properly set'
        );
        System.assertEquals(logEntryEvent.OrganizationId__c, log.OrganizationId__c, 'log.OrganizationId__c was not properly set');
        System.assertEquals(logEntryEvent.OrganizationInstanceName__c, log.OrganizationInstanceName__c, 'log.OrganizationInstanceName__c was not properly set');
        System.assertEquals(logEntryEvent.OrganizationName__c, log.OrganizationName__c, 'log.OrganizationName__c was not properly set');
        System.assertEquals(
            logEntryEvent.OrganizationNamespacePrefix__c,
            log.OrganizationNamespacePrefix__c,
            'log.OrganizationNamespacePrefix__c was not properly set'
        );
        System.assertEquals(logEntryEvent.OrganizationType__c, log.OrganizationType__c, 'log.OrganizationType__c was not properly set');

        // Profile fields
        System.assertEquals(logEntryEvent.UserLicenseDefinitionKey__c, log.UserLicenseDefinitionKey__c, 'log.UserLicenseDefinitionKey__c was not properly set');
        System.assertEquals(logEntryEvent.UserLicenseId__c, log.UserLicenseId__c, 'log.UserLicenseId__c was not properly set');
        System.assertEquals(logEntryEvent.UserLicenseName__c, log.UserLicenseName__c, 'log.UserLicenseName__c was not properly set');
    }

    private static void validateLogEntryFields(LogEntryEvent__e logEntryEvent, LogEntry__c logEntry) {
        System.assertEquals(logEntryEvent.ComponentType__c, logEntry.ComponentType__c, 'logEntry.ComponentType__c was not properly set');
        System.assertEquals(
            logEntryEvent.DatabaseResultCollectionSize__c,
            logEntry.DatabaseResultCollectionSize__c,
            'logEntry.DatabaseResultCollectionSize__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.DatabaseResultCollectionType__c,
            logEntry.DatabaseResultCollectionType__c,
            'logEntry.DatabaseResultCollectionType__c was not properly set'
        );
        System.assertEquals(logEntryEvent.DatabaseResultJson__c, logEntry.DatabaseResultJson__c, 'logEntry.DatabaseResultJson__c was not properly set');
        System.assertEquals(logEntryEvent.DatabaseResultType__c, logEntry.DatabaseResultType__c, 'logEntry.DatabaseResultType__c was not properly set');
        System.assertEquals(logEntryEvent.EpochTimestamp__c, logEntry.EpochTimestamp__c, 'logEntry.EpochTimestamp__c was not properly set');
        System.assertEquals(logEntryEvent.ExceptionStackTrace__c, logEntry.ExceptionStackTrace__c, 'logEntry.ExceptionStackTrace__c was not properly set');
        System.assertEquals(logEntryEvent.ExceptionType__c, logEntry.ExceptionType__c, 'logEntry.ExceptionType__c was not properly set');
        System.assertEquals(logEntryEvent.HttpRequestBody__c, logEntry.HttpRequestBody__c, 'logEntry.HttpRequestBody__c was not properly set');
        System.assertEquals(
            logEntryEvent.HttpRequestBodyMasked__c,
            logEntry.HttpRequestBodyMasked__c,
            'logEntry.HttpRequestBodyMasked__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.HttpRequestCompressed__c,
            logEntry.HttpRequestCompressed__c,
            'logEntry.HttpRequestCompressed__c was not properly set'
        );
        System.assertEquals(logEntryEvent.HttpRequestEndpoint__c, logEntry.HttpRequestEndpoint__c, 'logEntry.HttpRequestEndpoint__c was not properly set');
        System.assertEquals(logEntryEvent.HttpRequestMethod__c, logEntry.HttpRequestMethod__c, 'logEntry.HttpRequestMethod__c was not properly set');
        System.assertEquals(logEntryEvent.HttpResponseBody__c, logEntry.HttpResponseBody__c, 'logEntry.HttpResponseBody__c was not properly set');
        System.assertEquals(
            logEntryEvent.HttpResponseBodyMasked__c,
            logEntry.HttpResponseBodyMasked__c,
            'logEntry.HttpResponseBodyMasked__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.HttpResponseHeaderKeys__c,
            logEntry.HttpResponseHeaderKeys__c,
            'logEntry.HttpResponseHeaderKeys__c was not properly set'
        );
        System.assertEquals(logEntryEvent.HttpResponseStatus__c, logEntry.HttpResponseStatus__c, 'logEntry.HttpResponseStatus__c was not properly set');
        System.assertEquals(
            logEntryEvent.HttpResponseStatusCode__c,
            logEntry.HttpResponseStatusCode__c,
            'logEntry.HttpResponseStatusCode__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsAggregateQueriesMax__c,
            logEntry.LimitsAggregateQueriesMax__c,
            'logEntry.LimitsAggregateQueriesMax__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsAggregateQueriesUsed__c,
            logEntry.LimitsAggregateQueriesUsed__c,
            'logEntry.LimitsAggregateQueriesUsed__c was not properly set'
        );
        System.assertEquals(logEntryEvent.LimitsAsyncCallsMax__c, logEntry.LimitsAsyncCallsMax__c, 'logEntry.LimitsAsyncCallsMax__c was not properly set');
        System.assertEquals(logEntryEvent.LimitsAsyncCallsUsed__c, logEntry.LimitsAsyncCallsUsed__c, 'logEntry.LimitsAsyncCallsUsed__c was not properly set');
        System.assertEquals(logEntryEvent.LimitsCalloutsMax__c, logEntry.LimitsCalloutsMax__c, 'logEntry.LimitsCalloutsMax__c was not properly set');
        System.assertEquals(logEntryEvent.LimitsCalloutsUsed__c, logEntry.LimitsCalloutsUsed__c, 'logEntry.LimitsCalloutsUsed__c was not properly set');
        System.assertEquals(logEntryEvent.LimitsCpuTimeMax__c, logEntry.LimitsCpuTimeMax__c, 'logEntry.LimitsCpuTimeMax__c was not properly set');
        System.assertEquals(logEntryEvent.LimitsCpuTimeUsed__c, logEntry.LimitsCpuTimeUsed__c, 'logEntry.LimitsCpuTimeUsed__c was not properly set');
        System.assertEquals(logEntryEvent.LimitsDmlRowsMax__c, logEntry.LimitsDmlRowsMax__c, 'logEntry.LimitsDmlRowsMax__c was not properly set');
        System.assertEquals(logEntryEvent.LimitsDmlRowsUsed__c, logEntry.LimitsDmlRowsUsed__c, 'logEntry.LimitsDmlRowsUsed__c was not properly set');
        System.assertEquals(
            logEntryEvent.LimitsDmlStatementsMax__c,
            logEntry.LimitsDmlStatementsMax__c,
            'logEntry.LimitsDmlStatementsMax__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsDmlStatementsUsed__c,
            logEntry.LimitsDmlStatementsUsed__c,
            'logEntry.LimitsDmlStatementsUsed__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsEmailInvocationsMax__c,
            logEntry.LimitsEmailInvocationsMax__c,
            'logEntry.LimitsEmailInvocationsMax__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsEmailInvocationsUsed__c,
            logEntry.LimitsEmailInvocationsUsed__c,
            'logEntry.LimitsEmailInvocationsUsed__c was not properly set'
        );
        System.assertEquals(logEntryEvent.LimitsFutureCallsMax__c, logEntry.LimitsFutureCallsMax__c, 'logEntry.LimitsFutureCallsMax__c was not properly set');
        System.assertEquals(
            logEntryEvent.LimitsFutureCallsUsed__c,
            logEntry.LimitsFutureCallsUsed__c,
            'logEntry.LimitsFutureCallsUsed__c was not properly set'
        );
        System.assertEquals(logEntryEvent.LimitsHeapSizeMax__c, logEntry.LimitsHeapSizeMax__c, 'logEntry.LimitsHeapSizeMax__c was not properly set');
        System.assertEquals(logEntryEvent.LimitsHeapSizeUsed__c, logEntry.LimitsHeapSizeUsed__c, 'logEntry.LimitsHeapSizeUsed__c was not properly set');
        System.assertEquals(
            logEntryEvent.LimitsMobilePushApexCallsMax__c,
            logEntry.LimitsMobilePushApexCallsMax__c,
            'logEntry.LimitsMobilePushApexCallsMax__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsMobilePushApexCallsUsed__c,
            logEntry.LimitsMobilePushApexCallsUsed__c,
            'logEntry.LimitsMobilePushApexCallsUsed__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsPublishImmediateDmlStatementsMax__c,
            logEntry.LimitsPublishImmediateDmlStatementsMax__c,
            'logEntry.LimitsPublishImmediateDmlStatementsMax__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsPublishImmediateDmlStatementsUsed__c,
            logEntry.LimitsPublishImmediateDmlStatementsUsed__c,
            'logEntry.LimitsPublishImmediateDmlStatementsUsed__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsQueueableJobsMax__c,
            logEntry.LimitsQueueableJobsMax__c,
            'logEntry.LimitsQueueableJobsMax__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsQueueableJobsUsed__c,
            logEntry.LimitsQueueableJobsUsed__c,
            'logEntry.LimitsQueueableJobsUsed__c was not properly set'
        );
        System.assertEquals(logEntryEvent.LimitsSoqlQueriesMax__c, logEntry.LimitsSoqlQueriesMax__c, 'logEntry.LimitsSoqlQueriesMax__c was not properly set');
        System.assertEquals(
            logEntryEvent.LimitsSoqlQueriesUsed__c,
            logEntry.LimitsSoqlQueriesUsed__c,
            'logEntry.LimitsSoqlQueriesUsed__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c,
            logEntry.LimitsSoqlQueryLocatorRowsMax__c,
            'logEntry.LimitsSoqlQueryLocatorRowsMax__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c,
            logEntry.LimitsSoqlQueryLocatorRowsUsed__c,
            'logEntry.LimitsSoqlQueryLocatorRowsUsed__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsSoqlQueryRowsMax__c,
            logEntry.LimitsSoqlQueryRowsMax__c,
            'logEntry.LimitsSoqlQueryRowsMax__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsSoqlQueryRowsUsed__c,
            logEntry.LimitsSoqlQueryRowsUsed__c,
            'logEntry.LimitsSoqlQueryRowsUsed__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsSoslSearchesUsed__c,
            logEntry.LimitsSoslSearchesUsed__c,
            'logEntry.LimitsSoslSearchesUsed__c was not properly set'
        );
        System.assertEquals(
            logEntryEvent.LimitsSoslSearchesMax__c,
            logEntry.LimitsSoslSearchesMax__c,
            'logEntry.LimitsSoslSearchesMax__c was not properly set'
        );
        System.assertEquals(logEntryEvent.LoggingLevel__c, logEntry.LoggingLevel__c, 'logEntry.LoggingLevel__c was not properly set');
        System.assertEquals(logEntryEvent.LoggingLevelOrdinal__c, logEntry.LoggingLevelOrdinal__c, 'logEntry.LoggingLevelOrdinal__c was not properly set');
        System.assertEquals(logEntryEvent.Message__c, logEntry.Message__c, 'logEntry.Message__c was not properly set');
        System.assertEquals(logEntryEvent.MessageTruncated__c, logEntry.MessageTruncated__c, 'logEntry.MessageTruncated__c was not properly set');
        System.assertEquals(logEntry.Id, logEntry.Name, 'logEntry.Name was not properly set');
        System.assertEquals(logEntryEvent.OriginType__c, logEntry.OriginType__c, 'logEntry.OriginType__c was not properly set');
        System.assertEquals(logEntryEvent.OriginLocation__c, logEntry.OriginLocation__c, 'logEntry.OriginLocation__c was not properly set');
        System.assertEquals(logEntryEvent.RecordCollectionSize__c, logEntry.RecordCollectionSize__c, 'logEntry.RecordCollectionSize__c was not properly set');
        System.assertEquals(logEntryEvent.RecordCollectionType__c, logEntry.RecordCollectionType__c, 'logEntry.RecordCollectionType__c was not properly set');
        System.assertEquals(logEntryEvent.RecordId__c, logEntry.RecordId__c, 'logEntry.RecordId__c was not properly set');
        System.assertEquals(logEntryEvent.RecordJson__c, logEntry.RecordJson__c, 'logEntry.RecordJson__c was not properly set');
        System.assertEquals(logEntryEvent.RecordJsonMasked__c, logEntry.RecordJsonMasked__c, 'logEntry.RecordJsonMasked__c was not properly set');
        System.assertEquals(
            logEntryEvent.RecordSObjectClassification__c,
            logEntry.RecordSObjectClassification__c,
            'logEntry.RecordSObjectClassification__c was not properly set'
        );
        System.assertEquals(logEntryEvent.RecordSObjectType__c, logEntry.RecordSObjectType__c, 'logEntry.RecordSObjectType__c was not properly set');
        System.assertEquals(
            logEntryEvent.RecordSObjectTypeNamespace__c,
            logEntry.RecordSObjectTypeNamespace__c,
            'logEntry.RecordSObjectTypeNamespace__c was not properly set'
        );
        System.assertEquals(logEntryEvent.RecordId__c, logEntry.RecordId__c, 'logEntry.RecordId__c was not properly set');
        System.assertEquals(logEntryEvent.RecordJson__c, logEntry.RecordJson__c, 'logEntry.RecordJson__c was not properly set');
        System.assertEquals(
            logEntryEvent.RecordSObjectClassification__c,
            logEntry.RecordSObjectClassification__c,
            'logEntry.RecordSObjectClassification__c was not properly set'
        );
        System.assertEquals(logEntryEvent.RecordSObjectType__c, logEntry.RecordSObjectType__c, 'logEntry.RecordSObjectType__c was not properly set');
        System.assertEquals(
            logEntryEvent.RecordSObjectTypeNamespace__c,
            logEntry.RecordSObjectTypeNamespace__c,
            'logEntry.RecordSObjectTypeNamespace__c was not properly set'
        );
        System.assertEquals(logEntryEvent.StackTrace__c, logEntry.StackTrace__c, 'logEntry.StackTrace__c was not properly set');
        System.assertEquals(logEntryEvent.Timestamp__c, logEntry.Timestamp__c, 'logEntry.Timestamp__c was not properly set');
        System.assertEquals(
            logEntryEvent.TransactionEntryNumber__c,
            logEntry.TransactionEntryNumber__c,
            'logEntry.TransactionEntryNumber__c was not properly set'
        );
        System.assertEquals(logEntryEvent.TriggerIsExecuting__c, logEntry.TriggerIsExecuting__c, 'logEntry.TriggerIsExecuting__c was not properly set');
        System.assertEquals(logEntryEvent.TriggerOperationType__c, logEntry.TriggerOperationType__c, 'logEntry.TriggerOperationType__c was not properly set');
        System.assertEquals(logEntryEvent.TriggerSObjectType__c, logEntry.TriggerSObjectType__c, 'logEntry.TriggerSObjectType__c was not properly set');
    }
}
