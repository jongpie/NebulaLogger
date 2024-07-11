//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.MethodNamingConventions')
@IsTest(IsParallel=false)
private class LogManagementDataSelector_Tests {
    @IsTest
    static void it_dynamically_queries_all_records_for_specified_sobject_type_and_fields() {
        Schema.SObjectType targetSObjectType = Schema.Organization.SObjectType;
        Set<String> targetFieldNames = new Set<String>{ Schema.Organization.Id.getDescribe().getName(), Schema.Organization.Name.getDescribe().getName() };
        List<Schema.Organization> expectedResults = System.Database.query('SELECT ' + String.join(targetFieldNames, ', ') + ' FROM ' + targetSObjectType);

        List<SObject> returnedResults = LogManagementDataSelector.getInstance().getAll(targetSObjectType, targetFieldNames);

        System.Assert.areEqual(1, returnedResults.size());
        System.Assert.areEqual(expectedResults, returnedResults);
    }

    @IsTest
    static void it_dynamically_queries_records_for_specified_sobject_type_and_fields_and_ids() {
        Schema.SObjectType targetSObjectType = Schema.User.SObjectType;
        Set<String> targetFieldNames = new Set<String>{ Schema.User.Id.getDescribe().getName(), Schema.User.Name.getDescribe().getName() };
        List<Id> targetIds = new List<Id>(new Map<Id, Schema.User>([SELECT Id FROM User LIMIT 3]).keySet());
        List<Schema.User> expectedResults = System.Database.query(
            'SELECT ' + String.join(targetFieldNames, ', ') + ' FROM ' + targetSObjectType + ' WHERE Id IN :targetIds'
        );

        List<SObject> returnedResults = LogManagementDataSelector.getInstance().getById(targetSObjectType, targetFieldNames, targetIds);

        System.Assert.areEqual(expectedResults, returnedResults);
    }

    @IsTest
    static void it_returns_matching_apex_classes_for_specified_class_names() {
        Set<String> targetApexClassNames = new Set<String>{ Logger.class.getName(), LogEntryEventBuilder.class.getName() };
        List<Schema.ApexClass> expectedResults = [
            SELECT ApiVersion, Body, CreatedById, CreatedBy.Username, CreatedDate, Id, LastModifiedById, LastModifiedBy.Username, LastModifiedDate, Name
            FROM ApexClass
            WHERE Name IN :targetApexClassNames
            ORDER BY NamespacePrefix NULLS LAST
        ];

        List<Schema.ApexClass> returnedResults = LogManagementDataSelector.getInstance().getApexClasses(targetApexClassNames);

        System.Assert.areEqual(expectedResults, returnedResults);
    }

    @IsTest
    static void it_does_not_query_apex_classes_when_disabled_via_logger_parameter() {
        // The class names used in the query don't particularly matter here - the main concern is checking that the query does not execute at all
        Set<String> targetApexClassNames = new Set<String>{ 'SomeClass', 'AnotherClass' };
        Integer originalQueryCount = System.Limits.getQueries();
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryApexClassData', Value__c = String.valueOf(false)));

        List<Schema.ApexClass> returnedResults = LogManagementDataSelector.getInstance().getApexClasses(targetApexClassNames);

        System.Assert.areEqual(originalQueryCount, System.Limits.getQueries());
        System.Assert.areEqual(0, returnedResults.size());
    }

    @IsTest
    static void it_returns_matching_apex_triggers_for_specified_class_names() {
        Set<String> targetApexTriggerNames = new Set<String>{ Logger.class.getName(), LogEntryEventBuilder.class.getName() };
        List<Schema.ApexTrigger> expectedResults = [
            SELECT ApiVersion, Body, CreatedById, CreatedBy.Username, CreatedDate, Id, LastModifiedById, LastModifiedBy.Username, LastModifiedDate, Name
            FROM ApexTrigger
            WHERE Name IN :targetApexTriggerNames
            ORDER BY NamespacePrefix NULLS LAST
        ];

        List<Schema.ApexTrigger> returnedResults = LogManagementDataSelector.getInstance().getApexTriggers(targetApexTriggerNames);

        System.Assert.areEqual(expectedResults, returnedResults);
    }

    @IsTest
    static void it_does_not_query_apex_triggers_when_disabled_via_logger_parameter() {
        // The trigger names used in the query don't particularly matter here - the main concern is checking that the query does not execute at all
        Set<String> targetApexTriggerNames = new Set<String>{ 'SomeTrigger', 'AnotherTrigger' };
        Integer originalQueryCount = System.Limits.getQueries();
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryApexTriggerData', Value__c = String.valueOf(false)));

        List<Schema.ApexTrigger> returnedResults = LogManagementDataSelector.getInstance().getApexTriggers(targetApexTriggerNames);

        System.Assert.areEqual(originalQueryCount, System.Limits.getQueries());
        System.Assert.areEqual(0, returnedResults.size());
    }

    @IsTest
    static void it_returns_cached_apex_email_notifications() {
        List<Schema.ApexEmailNotification> expectedResults = [SELECT Email, UserId FROM ApexEmailNotification WHERE Email != NULL OR User.IsActive = TRUE];
        System.Assert.areEqual(1, System.Limits.getQueries());

        List<Schema.ApexEmailNotification> returnedResults = LogManagementDataSelector.getInstance().getCachedApexEmailNotifications();

        System.Assert.areEqual(2, System.Limits.getQueries());
        LogManagementDataSelector.getInstance().getCachedApexEmailNotifications();
        System.Assert.areEqual(2, System.Limits.getQueries());
        System.Assert.areEqual(expectedResults, returnedResults);
    }

    // FIXME Querying AsyncApexJob in a test context doesn't seem to return results for @future methods,
    // and the @future method should be replaced with a queueable class anyway, so fix this test
    // when converting the @future method to a private queueable class
    // @IsTest
    // static void it_returns_count_of_async_apex_jobs_for_specified_class_method_and_statuses() {
    //     String apexClassName = LogManagementDataSelector_Tests.class.getName();
    //     String apexMethodName = 'executeSomeFutureMethod';
    //     List<String> jobStatuses = new List<String>{ 'Holding', 'Queued', 'Preparing', 'Processing' };
    //     System.Assert.areEqual(0, LogManagementDataSelector.getInstance().getCountOfAsyncApexJobs(apexClassName, apexMethodName, jobStatuses));

    //     System.Test.startTest();
    //     executeSomeFutureMethod();
    //     System.Test.stopTest();

    //     System.Assert.fail([SELECT status FROM AsyncApexJob]);
    //     Integer returnedCount = LogManagementDataSelector.getInstance().getCountOfAsyncApexJobs(apexClassName, apexMethodName, jobStatuses);

    //     System.Assert.areEqual(1, returnedCount);
    // }

    @IsTest
    static void it_returns_cached_recent_log_with_api_release_details_when_call_status_api_callout_is_enabled() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = System.JSON.serialize(true)));
        System.Assert.isTrue(LoggerParameter.CALL_STATUS_API);
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        Log__c olderLog = new Log__c(
            ApiReleaseNumber__c = 'olderLog.ApiReleaseNumber__c',
            ApiReleaseVersion__c = 'olderLog.ApiReleaseVersion__c',
            OrganizationReleaseNumber__c = 'olderLog.OrganizationReleaseNumber__c',
            OrganizationReleaseVersion__c = 'olderLog.OrganizationReleaseVersion__c',
            TransactionId__c = 'olderLog.TransactionId__c'
        );
        Log__c expectedLog = new Log__c(
            ApiReleaseNumber__c = 'expectedLog.ApiReleaseNumber__c',
            ApiReleaseVersion__c = 'expectedLog.ApiReleaseVersion__c',
            OrganizationReleaseNumber__c = 'expectedLog.OrganizationReleaseNumber__c',
            OrganizationReleaseVersion__c = 'expectedLog.OrganizationReleaseVersion__c',
            TransactionId__c = 'expectedLog.TransactionId__c'
        );
        insert new List<Log__c>{ olderLog, expectedLog };
        System.Test.setCreatedDate(olderLog.Id, System.now().addMinutes(-5));
        System.Assert.areEqual(1, System.Limits.getQueries(), 'Expected 1 query to be used during test setup');

        for (Integer i = 0; i < 3; i++) {
            Log__c returnedLog = LogManagementDataSelector.getInstance().getCachedRecentLogWithApiReleaseDetails();

            System.Assert.areEqual(expectedLog.Id, returnedLog.Id);
            System.Assert.areEqual(System.JSON.serialize(expectedLog), System.JSON.serialize(expectedLog));
        }

        System.Assert.areEqual(2, System.Limits.getQueries());
    }

    @IsTest
    static void it_returns_null_when_no_recent_log_with_api_release_details_is_found() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = System.JSON.serialize(true)));
        System.Assert.isTrue(LoggerParameter.CALL_STATUS_API);
        System.Assert.areEqual(0, [SELECT COUNT() FROM Log__c]);
        System.Assert.areEqual(1, System.Limits.getQueries(), 'Expected 1 query to be used during test setup');

        for (Integer i = 0; i < 5; i++) {
            Log__c returnedLog = LogManagementDataSelector.getInstance().getCachedRecentLogWithApiReleaseDetails();

            System.Assert.isNull(returnedLog);
        }

        System.Assert.areEqual(2, System.Limits.getQueries());
    }

    @IsTest
    static void it_returns_null_for_cached_recent_log_with_api_release_details_when_status_api_callout_is_disabled() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'CallStatusApi', Value__c = System.JSON.serialize(false)));
        System.Assert.isFalse(LoggerParameter.CALL_STATUS_API);
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
        Log__c logWithApiReleaseDetails = new Log__c(
            ApiReleaseNumber__c = 'logWithApiReleaseDetails.ApiReleaseNumber__c',
            ApiReleaseVersion__c = 'logWithApiReleaseDetails.ApiReleaseVersion__c',
            OrganizationReleaseNumber__c = 'logWithApiReleaseDetails.OrganizationReleaseNumber__c',
            OrganizationReleaseVersion__c = 'logWithApiReleaseDetails.OrganizationReleaseVersion__c',
            TransactionId__c = '1234'
        );
        insert logWithApiReleaseDetails;
        System.Assert.areEqual(1, System.Limits.getQueries(), 'Expected 1 query to be used during test setup');

        for (Integer i = 0; i < 3; i++) {
            Log__c returnedLog = LogManagementDataSelector.getInstance().getCachedRecentLogWithApiReleaseDetails();

            System.Assert.isNull(returnedLog);
        }

        System.Assert.areEqual(1, System.Limits.getQueries());
    }

    @IsTest
    static void it_returns_count_of_related_record_log_entries() {
        Id targetRecordId = System.UserInfo.getUserId();
        LoggerSObjectHandler.shouldExecute(false);
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert log;
        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(Log__c = log.Id, TransactionEntryNumber__c = 1);
        nonMatchingLogEntry.Log__c = log.Id;
        logEntries.add(nonMatchingLogEntry);
        LogEntry__c matchingLogEntry = new LogEntry__c(Log__c = log.Id, TransactionEntryNumber__c = 2);
        matchingLogEntry.Log__c = log.Id;
        matchingLogEntry.RecordId__c = targetRecordId;
        logEntries.add(matchingLogEntry);
        insert logEntries;

        Integer returnedCount = LogManagementDataSelector.getInstance().getCountOfRelatedRecordLogEntries(targetRecordId);

        System.Assert.areEqual(1, returnedCount);
    }

    @IsTest
    static void it_returns_deleteable_user_record_access() {
        LoggerSObjectHandler.shouldExecute(false);
        Log__c deleteableRecord = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert deleteableRecord;
        Schema.User undeleteableRecord = new Schema.User(Id = System.UserInfo.getUserId());
        List<Id> recordIds = new List<Id>{ deleteableRecord.Id, undeleteableRecord.Id };

        List<Schema.UserRecordAccess> returnedResults = LogManagementDataSelector.getInstance().getDeleteableUserRecordAccess(recordIds);

        System.Assert.areEqual(1, returnedResults.size());
        System.Assert.areEqual(deleteableRecord.Id, returnedResults.get(0).RecordId);
    }

    @IsTest
    static void it_returns_log_for_specified_log_id() {
        LoggerSObjectHandler.shouldExecute(false);
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        Log__c anotherLog = log.clone();
        insert new List<Log__c>{ log, anotherLog };

        Log__c returnedLog = LogManagementDataSelector.getInstance().getLogById(log.Id);

        System.Assert.areEqual(log.Id, returnedLog.Id);
    }

    @IsTest
    static void it_returns_log_entry_for_specified_log_entry_id() {
        LoggerSObjectHandler.shouldExecute(false);
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert log;
        LogEntry__c logEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(new LogEntry__c(Log__c = log.Id)).populateRequiredFields().getRecord();
        LogEntry__c anotherLogEntry = logEntry.clone();
        insert new List<LogEntry__c>{ logEntry, anotherLogEntry };

        LogEntry__c returnedLogEntry = LogManagementDataSelector.getInstance().getLogEntryById(logEntry.Id);

        System.Assert.areEqual(logEntry.Id, returnedLogEntry.Id);
    }

    @IsTest
    static void it_returns_log_entries_for_specified_log_id() {
        LoggerSObjectHandler.shouldExecute(false);
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        Log__c anotherLog = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert new List<Log__c>{ log, anotherLog };
        List<LogEntry__c> expectedLogEntries = new List<LogEntry__c>();
        List<LogEntry__c> unrelatedlogEntries = new List<LogEntry__c>();
        for (Integer i = 0; i < 5; i++) {
            expectedLogEntries.add(new LogEntry__c(Log__c = log.Id, Message__c = 'some message, number ' + i));
            unrelatedlogEntries.add(new LogEntry__c(Log__c = anotherLog.Id, Message__c = 'some message, number ' + i));
        }
        List<LogEntry__c> allTestLogEntries = new List<LogEntry__c>();
        allTestLogEntries.addAll(expectedLogEntries);
        allTestLogEntries.addAll(unrelatedlogEntries);
        insert allTestLogEntries;

        List<LogEntry__c> returnedLogEnties = LogManagementDataSelector.getInstance().getLogEntriesByLogId(log.Id);

        System.Assert.areEqual(expectedLogEntries.size(), returnedLogEnties.size());
        Set<Id> logEntryIds = new Map<Id, LogEntry__c>(expectedLogEntries).keySet();
        for (LogEntry__c logEntry : returnedLogEnties) {
            System.Assert.isTrue(logEntryIds.contains(logEntry.Id));
            System.Assert.areEqual(log.Id, logEntry.Log__c);
        }
    }

    @IsTest
    static void it_returns_logs_for_specified_log_ids() {
        LoggerSObjectHandler.shouldExecute(false);
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
            log.TransactionId__c = 'some_fake_transaction_id_' + i;
            logs.add(log);
        }
        insert logs;
        List<Id> logIds = new List<Id>(new Map<Id, Log__c>(logs).keySet());

        List<Log__c> returnedResults = LogManagementDataSelector.getInstance().getLogsById(logIds);

        System.Assert.areEqual(logs.size(), returnedResults.size());
    }

    @IsTest
    static void it_returns_logs_for_specified_parent_log_transaction_ids_and_no_parent_log() {
        LoggerSObjectHandler.shouldExecute(false);
        Log__c parentLog = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        parentLog.TransactionId__c = 'some unique value for this log';
        insert parentLog;
        List<Log__c> logsToCreate = new List<Log__c>();
        List<Log__c> expectedLogs = new List<Log__c>();
        List<String> parentLogTransactionIds = new List<String>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
            log.TransactionId__c = 'some_fake_transaction_id_' + i;
            // Make 1 log with an actual an actual parent log
            if (i == 0) {
                log.ParentLog__c = parentLog.Id;
                log.ParentLogTransactionId__c = parentLog.TransactionId__c;
            }
            // Make a few logs with a parent transaction ID but no parent log
            if (i == 1 || i == 2 || i == 3) {
                log.ParentLog__c = null;
                log.ParentLogTransactionId__c = 'some other value';
                expectedLogs.add(log);
            }
            if (String.isNotBlank(log.ParentLogTransactionId__c)) {
                parentLogTransactionIds.add(log.ParentLogTransactionId__c);
            }
            logsToCreate.add(log);
        }
        System.Assert.areEqual(parentLogTransactionIds.size(), expectedLogs.size() + 1, 'Test has started under the wrong conditions');
        insert logsToCreate;

        List<Log__c> returnedResults = LogManagementDataSelector.getInstance().getLogsWithoutParentLogByParentTransactionId(parentLogTransactionIds);

        System.Assert.isFalse(returnedResults.isEmpty());
        System.Assert.areEqual(expectedLogs.size(), returnedResults.size());
        System.Assert.areEqual(new Map<Id, Log__c>(expectedLogs).keySet(), new Map<Id, Log__c>(returnedResults).keySet());
    }

    @IsTest
    static void it_returns_logs_for_specified_log_transaction_ids() {
        LoggerSObjectHandler.shouldExecute(false);
        List<Log__c> logs = new List<Log__c>();
        List<String> logTransactionIds = new List<String>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
            log.TransactionId__c = 'some_fake_transaction_id_' + i;
            logTransactionIds.add(log.TransactionId__c);
            logs.add(log);
        }
        insert logs;

        List<Log__c> returnedResults = LogManagementDataSelector.getInstance().getLogsByTransactionId(logTransactionIds);

        System.Assert.areEqual(logs.size(), returnedResults.size());
    }

    @IsTest
    static void it_returns_profiles_for_specified_profile_ids() {
        List<Schema.Profile> expectedResults = [SELECT Id, Name FROM Profile LIMIT 10];
        List<Id> targetProfileIds = new List<Id>(new Map<Id, Schema.Profile>(expectedResults).keySet());

        List<Schema.Profile> returnedResults = LogManagementDataSelector.getInstance().getProfilesById(targetProfileIds);

        expectedResults.sort();
        returnedResults.sort();
        System.Assert.areEqual(expectedResults, returnedResults);
    }

    @IsTest
    static void it_returns_profiles_for_specified_search_term() {
        String searchTerm = 'Admin';
        List<Schema.Profile> expectedResults = [SELECT Id, Name, UserLicense.Name FROM Profile WHERE Name LIKE :searchTerm];

        List<Schema.Profile> returnedResults = LogManagementDataSelector.getInstance().getProfilesByNameSearch(searchTerm);

        expectedResults.sort();
        returnedResults.sort();
        System.Assert.areEqual(expectedResults, returnedResults);
    }

    @IsTest
    static void it_returns_queues_for_specified_developer_names() {
        List<Schema.Group> queuesToInsert = new List<Schema.Group>();
        Schema.Group nonMatchingQueue = new Schema.Group(DeveloperName = 'non_matching_queue', Name = 'Non-Matching Queue', Type = 'Queue');
        queuesToInsert.add(nonMatchingQueue);
        List<String> targetQueueNames = new List<String>();
        for (Integer i = 0; i < 3; i++) {
            Schema.Group matchingQueue = new Schema.Group(DeveloperName = 'some_queue' + i, Name = 'Some Queue' + i, Type = 'Queue');
            targetQueueNames.add(matchingQueue.DeveloperName);
            queuesToInsert.add(matchingQueue);
        }
        insert queuesToInsert;
        List<Schema.Group> expectedResults = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :targetQueueNames];

        List<Schema.Group> returnedResults = LogManagementDataSelector.getInstance().getQueuesByDeveloperName(targetQueueNames);

        System.Assert.areEqual(expectedResults, returnedResults);
    }

    @IsTest
    static void it_returns_related_log_entries_for_specified_record_id() {
        Id targetRecordId = System.UserInfo.getUserId();
        LoggerSObjectHandler.shouldExecute(false);
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert log;
        List<LogEntry__c> logEntries = new List<LogEntry__c>();
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(Log__c = log.Id, TransactionEntryNumber__c = 1);
        nonMatchingLogEntry.Log__c = log.Id;
        logEntries.add(nonMatchingLogEntry);
        LogEntry__c matchingLogEntry = new LogEntry__c(Log__c = log.Id, TransactionEntryNumber__c = 2);
        matchingLogEntry.Log__c = log.Id;
        matchingLogEntry.RecordId__c = targetRecordId;
        logEntries.add(matchingLogEntry);
        insert logEntries;
        String fieldsClause = String.join(
            new List<String>{ Schema.LogEntry__c.Id.getDescribe().getName(), Schema.LogEntry__c.Timestamp__c.getDescribe().getName() },
            ', '
        );
        String orderByClause = Schema.LogEntry__c.Timestamp__c.getDescribe().getName();
        Integer rowLimit = 3;

        List<LogEntry__c> returnedResults = LogManagementDataSelector.getInstance().getRecordLogEntries(targetRecordId, fieldsClause, orderByClause, rowLimit);

        System.Assert.areEqual(1, returnedResults.size());
        System.Assert.areEqual(matchingLogEntry.Id, returnedResults.get(0).Id);
    }

    @IsTest
    static void it_returns_tags_for_specified_names() {
        List<LoggerTag__c> tags = new List<LoggerTag__c>();
        LoggerTag__c matchingTag = new LoggerTag__c(Name = 'some fake tag name');
        tags.add(matchingTag);
        LoggerTag__c nonMatchingTag = new LoggerTag__c(Name = 'another fake tag name');
        tags.add(nonMatchingTag);
        insert tags;
        Set<String> targetTagNames = new Set<String>{ matchingTag.Name };
        List<LoggerTag__c> expectedResults = [SELECT Id, Name FROM LoggerTag__c WHERE Name IN :targetTagNames];
        System.Assert.areEqual(1, expectedResults.size());

        List<LoggerTag__c> returnedResults = LogManagementDataSelector.getInstance().getTagsByName(targetTagNames);

        System.Assert.areEqual(expectedResults, returnedResults);
    }

    @IsTest
    static void it_returns_topics_for_specified_names() {
        List<Schema.Topic> topics = new List<Schema.Topic>();
        Schema.Topic matchingTopic = new Schema.Topic(Name = 'some fake topic name');
        topics.add(matchingTopic);
        Schema.Topic nonMatchingTopic = new Schema.Topic(Name = 'another fake topic name');
        topics.add(nonMatchingTopic);
        insert topics;
        Set<String> targetTopicNames = new Set<String>{ matchingTopic.Name };
        List<Schema.Topic> expectedResults = [SELECT Id, Name FROM Topic WHERE Name IN :targetTopicNames];
        System.Assert.areEqual(1, expectedResults.size());

        List<Schema.Topic> returnedResults = LogManagementDataSelector.getInstance().getTopicsByName(targetTopicNames);

        System.Assert.areEqual(expectedResults, returnedResults);
    }

    @IsTest
    static void it_returns_users_for_user_ids() {
        List<Schema.User> expectedResults = [SELECT Id, Username FROM User LIMIT 3];
        List<Id> targetUserIds = new List<Id>(new Map<Id, Schema.User>(expectedResults).keySet());

        List<Schema.User> returnedResults = LogManagementDataSelector.getInstance().getUsersById(targetUserIds);

        expectedResults.sort();
        returnedResults.sort();
        System.Assert.areEqual(expectedResults, returnedResults);
    }

    @IsTest
    static void it_returns_empty_list_without_querying_when_specified_search_term_is_blank() {
        String blankSearchTerm = '    \t \n \r    ';
        System.Assert.isTrue(String.isBlank(blankSearchTerm));
        List<Schema.User> expectedResults = new List<Schema.User>();

        List<Schema.User> returnedResults = LogManagementDataSelector.getInstance().getUsersByNameSearch(blankSearchTerm);

        System.Assert.areEqual(expectedResults, returnedResults);
        System.Assert.areEqual(0, System.Limits.getQueries());
    }

    @IsTest
    static void it_returns_user_for_specified_search_term() {
        String searchTerm = System.UserInfo.getLastName();
        List<Schema.User> expectedResults = [
            SELECT Id, Name, Username, SmallPhotoUrl
            FROM User
            WHERE Name LIKE :searchTerm OR Username LIKE :searchTerm
        ];

        List<Schema.User> returnedResults = LogManagementDataSelector.getInstance().getUsersByNameSearch(searchTerm);

        expectedResults.sort();
        returnedResults.sort();
        System.Assert.areEqual(expectedResults, returnedResults);
        System.Assert.areEqual(2, System.Limits.getQueries());
    }

    @IsTest
    static void it_returns_users_for_user_usernames() {
        List<Schema.User> expectedResults = [SELECT Id, Username FROM User LIMIT 3];
        List<String> targetUserUsernames = new List<String>();
        for (Schema.User user : expectedResults) {
            targetUserUsernames.add(user.Username);
        }

        List<Schema.User> returnedResults = LogManagementDataSelector.getInstance().getUsersByUsername(targetUserUsernames);

        expectedResults.sort();
        returnedResults.sort();
        System.Assert.areEqual(expectedResults, returnedResults);
        System.Assert.areEqual(2, System.Limits.getQueries());
    }

    @IsTest
    static void it_loads_mock_instance() {
        MockLogManagementDataSelector mockSelector = new MockLogManagementDataSelector();
        System.Assert.areNotEqual(mockSelector, LogManagementDataSelector.getInstance());

        LogManagementDataSelector.setMock(mockSelector);

        System.Assert.areEqual(mockSelector, LogManagementDataSelector.getInstance());
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    @future
    private static void executeSomeFutureMethod() {
        // This method intentionally does nothing - it\'s only used to help test queries on AsynxApexJob
    }

    private class MockLogManagementDataSelector extends LogManagementDataSelector {
    }
}
