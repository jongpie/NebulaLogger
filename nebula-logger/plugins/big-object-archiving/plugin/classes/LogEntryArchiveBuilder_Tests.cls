//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LogEntryArchiveBuilder_Tests {
    @IsTest
    static void it_should_write_all_fields_over_from_log_entry_event() {
        Datetime timestamp = System.now();
        LogEntryEvent__e mockEvent = (LogEntryEvent__e) LoggerMockDataCreator.createDataBuilder(Schema.LogEntryEvent__e.SObjectType)
            .populateAllFields()
            .getRecord();
        mockEvent = (LogEntryEvent__e) LoggerMockDataCreator.setReadOnlyField(mockEvent, Schema.LogEntryEvent__e.EventUuid, 'abc-xyz-some-value');
        mockEvent.LoggingLevel__c = LoggingLevel.INFO.name();
        mockEvent.Timestamp__c = timestamp;
        mockEvent.TimestampString__c = String.valueOf(timestamp.getTime());

        LogEntryArchive__b logEntryArchive = new LogEntryArchiveBuilder(mockEvent).getLogEntryArchive();

        System.assertNotEquals(null, logEntryArchive);
        assertAllFieldsMatch(timestamp, mockEvent, logEntryArchive);
    }

    @IsTest
    static void it_should_cache_instance_of_log_entry_archive_for_log_entry_event() {
        LogEntryEvent__e mockEvent = (LogEntryEvent__e) LoggerMockDataCreator.createDataBuilder(Schema.LogEntryEvent__e.SObjectType)
            .populateAllFields()
            .getRecord();
        mockEvent = (LogEntryEvent__e) LoggerMockDataCreator.setReadOnlyField(mockEvent, Schema.LogEntryEvent__e.EventUuid, 'abc-xyz-some-value');
        LogEntryArchiveBuilder archiveBuilder = new LogEntryArchiveBuilder(mockEvent);
        LogEntryArchive__b originalLogEntryArchive = archiveBuilder.getLogEntryArchive();
        originalLogEntryArchive.Message__c = 'Some new value';

        LogEntryArchive__b secondLogEntryArchive = archiveBuilder.getLogEntryArchive();

        System.assertEquals(originalLogEntryArchive, secondLogEntryArchive);
    }

    @IsTest
    static void it_should_truncate_log_entry_archive_field_values_when_too_long() {
        LogEntryEvent__e mockEvent = (LogEntryEvent__e) LoggerMockDataCreator.createDataBuilder(Schema.LogEntryEvent__e.SObjectType)
            .populateAllFields()
            .getRecord();
        mockEvent = (LogEntryEvent__e) LoggerMockDataCreator.setReadOnlyField(mockEvent, Schema.LogEntryEvent__e.EventUuid, 'abc-xyz-some-value');
        mockEvent.Message__c = 'Z'.repeat(Schema.LogEntryArchive__b.Message__c.getDescribe().getLength() + 1);
        LogEntryArchive__b logEntryArchive = new LogEntryArchiveBuilder(mockEvent).getLogEntryArchive();

        System.assertNotEquals(mockEvent.Message__c, logEntryArchive.Message__c);
        System.assertEquals(mockEvent.Message__c.left(Schema.LogEntryArchive__b.Message__c.getDescribe().getLength()), logEntryArchive.Message__c);
    }

    @IsTest
    static void it_should_write_all_fields_over_from_log_entry() {
        LogEntry__c mockLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType).populateAllFields().getRecord();
        mockLogEntry.Log__r = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateAllFields().getRecord();
        mockLogEntry.LoggingLevel__c = LoggingLevel.INFO.name();

        LogEntryArchive__b logEntryArchive = new LogEntryArchiveBuilder(mockLogEntry).getLogEntryArchive();

        System.assertNotEquals(null, logEntryArchive);
        assertAllFieldsMatch(mockLogEntry, logEntryArchive);
    }

    @IsTest
    static void it_should_cache_instance_of_log_entry_archive_for_log_entry() {
        LogEntry__c mockLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType).populateRequiredFields().getRecord();
        mockLogEntry.Log__r = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        LogEntryArchiveBuilder archiveBuilder = new LogEntryArchiveBuilder(mockLogEntry);
        LogEntryArchive__b originalLogEntryArchive = archiveBuilder.getLogEntryArchive();
        originalLogEntryArchive.Message__c = 'Some new value';

        LogEntryArchive__b secondLogEntryArchive = archiveBuilder.getLogEntryArchive();

        System.assertEquals(originalLogEntryArchive, secondLogEntryArchive);
        System.assertEquals(originalLogEntryArchive.Message__c, secondLogEntryArchive.Message__c);
    }

    @IsTest
    static void it_should_truncate_log_entry_field_values_when_too_long() {
        LogEntry__c mockLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType).populateRequiredFields().getRecord();
        mockLogEntry.Message__c = 'Z'.repeat(Schema.LogEntryArchive__b.Message__c.getDescribe().getLength() + 1);
        LogEntryArchive__b logEntryArchive = new LogEntryArchiveBuilder(mockLogEntry).getLogEntryArchive();

        System.assertNotEquals(mockLogEntry.Message__c, logEntryArchive.Message__c);
        System.assertEquals(mockLogEntry.Message__c.left(Schema.LogEntryArchive__b.Message__c.getDescribe().getLength()), logEntryArchive.Message__c);
    }

    @SuppressWarnings('PMD.NcssMethodCount')
    private static void assertAllFieldsMatch(Datetime timestamp, LogEntryEvent__e mockEvent, LogEntryArchive__b logEntryArchive) {
        System.assertEquals(mockEvent.ApiVersion__c, logEntryArchive.ApiVersion__c, 'logEntryArchive.ApiVersion__c was not properly set');
        System.assertEquals(UserInfo.getUserId(), logEntryArchive.ArchivedById__c, 'logEntryArchive.ArchivedById__c was not properly set');
        System.assertNotEquals(null, logEntryArchive.ArchivedDate__c, 'logEntryArchive.ArchivedDate__c was not properly set');
        System.assertEquals(System.today(), logEntryArchive.ArchivedDate__c.date(), 'logEntryArchive.ArchivedDate__c was not properly set');
        System.assertEquals(UserInfo.getUsername(), logEntryArchive.ArchivedByUsername__c, 'logEntryArchive.ArchivedByUsername__c was not properly set');
        System.assertEquals(mockEvent.ComponentType__c, logEntryArchive.ComponentType__c, 'logEntryArchive.ComponentType__c was not properly set');
        System.assertEquals(
            mockEvent.DatabaseResultCollectionSize__c,
            logEntryArchive.DatabaseResultCollectionSize__c,
            'logEntryArchive.DatabaseResultCollectionSize__c was not properly set'
        );
        System.assertEquals(
            mockEvent.DatabaseResultCollectionType__c,
            logEntryArchive.DatabaseResultCollectionType__c,
            'logEntryArchive.DatabaseResultCollectionType__c was not properly set'
        );
        System.assertEquals(
            mockEvent.DatabaseResultJson__c,
            logEntryArchive.DatabaseResultJson__c,
            'logEntryArchive.DatabaseResultJson__c was not properly set'
        );
        System.assertEquals(
            mockEvent.DatabaseResultType__c,
            logEntryArchive.DatabaseResultType__c,
            'logEntryArchive.DatabaseResultType__c was not properly set'
        );
        System.assertEquals(mockEvent.EpochTimestamp__c, logEntryArchive.EpochTimestamp__c, 'logEntryArchive.EpochTimestamp__c was not properly set');
        System.assertEquals(mockEvent.EventUuid, logEntryArchive.EventUuid__c, 'logEntryArchive.EventUuid__c was not properly set');
        System.assertEquals(mockEvent.ExceptionMessage__c, logEntryArchive.ExceptionMessage__c, 'logEntryArchive.ExceptionMessage__c was not properly set');
        System.assertEquals(
            mockEvent.ExceptionStackTrace__c,
            logEntryArchive.ExceptionStackTrace__c,
            'logEntryArchive.ExceptionStackTrace__c was not properly set'
        );
        System.assertEquals(mockEvent.ExceptionType__c, logEntryArchive.ExceptionType__c, 'logEntryArchive.ExceptionType__c was not properly set');
        System.assertEquals(
            String.valueOf(mockEvent.HttpRequestBody__c),
            logEntryArchive.HttpRequestBody__c,
            'logEntryArchive.HttpRequestBody__c was not properly set'
        );
        System.assertEquals(
            String.valueOf(mockEvent.HttpRequestCompressed__c),
            logEntryArchive.HttpRequestCompressed__c,
            'logEntryArchive.HttpRequestCompressed__c was not properly set'
        );
        System.assertEquals(
            mockEvent.HttpRequestEndpoint__c,
            logEntryArchive.HttpRequestEndpoint__c,
            'logEntryArchive.HttpRequestEndpoint__c was not properly set'
        );
        System.assertEquals(mockEvent.HttpRequestMethod__c, logEntryArchive.HttpRequestMethod__c, 'logEntryArchive.HttpRequestMethod__c was not properly set');
        System.assertEquals(mockEvent.HttpResponseBody__c, logEntryArchive.HttpResponseBody__c, 'logEntryArchive.HttpResponseBody__c was not properly set');
        System.assertEquals(
            mockEvent.HttpResponseHeaderKeys__c,
            logEntryArchive.HttpResponseHeaderKeys__c,
            'logEntryArchive.HttpResponseHeaderKeys__c was not properly set'
        );
        System.assertEquals(
            mockEvent.HttpResponseStatus__c,
            logEntryArchive.HttpResponseStatus__c,
            'logEntryArchive.HttpResponseStatus__c was not properly set'
        );
        System.assertEquals(
            mockEvent.HttpResponseStatusCode__c,
            logEntryArchive.HttpResponseStatusCode__c,
            'logEntryArchive.HttpResponseStatusCode__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsAggregateQueriesMax__c,
            logEntryArchive.LimitsAggregateQueriesMax__c,
            'logEntryArchive.LimitsAggregateQueriesMax__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsAggregateQueriesUsed__c,
            logEntryArchive.LimitsAggregateQueriesUsed__c,
            'logEntryArchive.LimitsAggregateQueriesUsed__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsAsyncCallsMax__c,
            logEntryArchive.LimitsAsyncCallsMax__c,
            'logEntryArchive.LimitsAsyncCallsMax__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsAsyncCallsUsed__c,
            logEntryArchive.LimitsAsyncCallsUsed__c,
            'logEntryArchive.LimitsAsyncCallsUsed__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsCalloutsUsed__c,
            logEntryArchive.LimitsCalloutsUsed__c,
            'logEntryArchive.LimitsCalloutsUsed__c was not properly set'
        );
        System.assertEquals(mockEvent.LimitsCpuTimeMax__c, logEntryArchive.LimitsCpuTimeMax__c, 'logEntryArchive.LimitsCpuTimeMax__c was not properly set');
        System.assertEquals(mockEvent.LimitsCpuTimeUsed__c, logEntryArchive.LimitsCpuTimeUsed__c, 'logEntryArchive.LimitsCpuTimeUsed__c was not properly set');
        System.assertEquals(mockEvent.LimitsDmlRowsMax__c, logEntryArchive.LimitsDmlRowsMax__c, 'logEntryArchive.LimitsDmlRowsMax__c was not properly set');
        System.assertEquals(mockEvent.LimitsDmlRowsUsed__c, logEntryArchive.LimitsDmlRowsUsed__c, 'logEntryArchive.LimitsDmlRowsUsed__c was not properly set');
        System.assertEquals(
            mockEvent.LimitsDmlStatementsMax__c,
            logEntryArchive.LimitsDmlStatementsMax__c,
            'logEntryArchive.LimitsDmlStatementsMax__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsDmlStatementsUsed__c,
            logEntryArchive.LimitsDmlStatementsUsed__c,
            'logEntryArchive.LimitsDmlStatementsUsed__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsEmailInvocationsMax__c,
            logEntryArchive.LimitsEmailInvocationsMax__c,
            'logEntryArchive.LimitsEmailInvocationsMax__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsEmailInvocationsUsed__c,
            logEntryArchive.LimitsEmailInvocationsUsed__c,
            'logEntryArchive.LimitsEmailInvocationsUsed__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsFutureCallsMax__c,
            logEntryArchive.LimitsFutureCallsMax__c,
            'logEntryArchive.LimitsFutureCallsMax__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsFutureCallsUsed__c,
            logEntryArchive.LimitsFutureCallsUsed__c,
            'logEntryArchive.LimitsFutureCallsUsed__c was not properly set'
        );
        System.assertEquals(mockEvent.LimitsHeapSizeMax__c, logEntryArchive.LimitsHeapSizeMax__c, 'logEntryArchive.LimitsHeapSizeMax__c was not properly set');
        System.assertEquals(
            mockEvent.LimitsHeapSizeUsed__c,
            logEntryArchive.LimitsHeapSizeUsed__c,
            'logEntryArchive.LimitsHeapSizeUsed__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsPublishImmediateDmlStatementsMax__c,
            logEntryArchive.LimitsPublishImmediateDmlStatementsMax__c,
            'logEntryArchive.LimitsPublishImmediateDmlStatementsMax__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsPublishImmediateDmlStatementsUsed__c,
            logEntryArchive.LimitsPublishImmediateDmlStatementsUsed__c,
            'logEntryArchive.LimitsPublishImmediateDmlStatementsUsed__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsMobilePushApexCallsMax__c,
            logEntryArchive.LimitsMobilePushApexCallsMax__c,
            'logEntryArchive.LimitsMobilePushApexCallsMax__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsMobilePushApexCallsUsed__c,
            logEntryArchive.LimitsMobilePushApexCallsUsed__c,
            'logEntryArchive.LimitsMobilePushApexCallsUsed__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsQueueableJobsMax__c,
            logEntryArchive.LimitsQueueableJobsMax__c,
            'logEntryArchive.LimitsQueueableJobsMax__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsQueueableJobsUsed__c,
            logEntryArchive.LimitsQueueableJobsUsed__c,
            'logEntryArchive.LimitsQueueableJobsUsed__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsSoqlQueriesMax__c,
            logEntryArchive.LimitsSoqlQueriesMax__c,
            'logEntryArchive.LimitsSoqlQueriesMax__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsSoqlQueriesUsed__c,
            logEntryArchive.LimitsSoqlQueriesUsed__c,
            'logEntryArchive.LimitsSoqlQueriesUsed__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsSoqlQueryLocatorRowsMax__c,
            logEntryArchive.LimitsSoqlQueryLocatorRowsMax__c,
            'logEntryArchive.LimitsSoqlQueryLocatorRowsMax__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsSoqlQueryLocatorRowsUsed__c,
            logEntryArchive.LimitsSoqlQueryLocatorRowsUsed__c,
            'logEntryArchive.LimitsSoqlQueryLocatorRowsUsed__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsSoqlQueryRowsMax__c,
            logEntryArchive.LimitsSoqlQueryRowsMax__c,
            'logEntryArchive.LimitsSoqlQueryRowsMax__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsSoqlQueryRowsUsed__c,
            logEntryArchive.LimitsSoqlQueryRowsUsed__c,
            'logEntryArchive.LimitsSoqlQueryRowsUsed__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsSoslSearchesMax__c,
            logEntryArchive.LimitsSoslSearchesMax__c,
            'logEntryArchive.LimitsSoslSearchesMax__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LimitsSoslSearchesUsed__c,
            logEntryArchive.LimitsSoslSearchesUsed__c,
            'logEntryArchive.LimitsSoslSearchesUsed__c was not properly set'
        );
        System.assertEquals(mockEvent.Locale__c, logEntryArchive.Locale__c, 'logEntryArchive.Locale__c was not properly set');
        // System.assertEquals(String.isNotBlank(mockEvent.LoggedById__c) ? mockEvent.LoggedById__c : 'Anonymous', logEntryArchive.LoggedBy__c);
        System.assertEquals(mockEvent.LoggedById__c, logEntryArchive.LoggedById__c, 'logEntryArchive.LoggedById__c was not properly set');
        System.assertEquals(
            String.isNotBlank(mockEvent.LoggedByUsername__c) ? mockEvent.LoggedByUsername__c : 'Anonymous',
            logEntryArchive.LoggedByUsername__c,
            'logEntryArchive.LoggedByUsername__c was not properly set'
        );
        System.assertEquals(
            mockEvent.LoggerVersionNumber__c,
            logEntryArchive.LoggerVersionNumber__c,
            'logEntryArchive.LoggerVersionNumber__c was not properly set'
        );
        System.assertEquals(mockEvent.LoggingLevel__c, logEntryArchive.LoggingLevel__c, 'logEntryArchive.LoggingLevel__c was not properly set');
        System.assertEquals(
            mockEvent.LoggingLevelOrdinal__c,
            logEntryArchive.LoggingLevelOrdinal__c,
            'logEntryArchive.LoggingLevelOrdinal__c was not properly set'
        );
        System.assertEquals(mockEvent.LoginApplication__c, logEntryArchive.LoginApplication__c, 'logEntryArchive.LoginApplication__c was not properly set');
        System.assertEquals(mockEvent.LoginBrowser__c, logEntryArchive.LoginBrowser__c, 'logEntryArchive.LoginBrowser__c was not properly set');
        System.assertEquals(mockEvent.LoginHistoryId__c, logEntryArchive.LoginHistoryId__c, 'logEntryArchive.LoginHistoryId__c was not properly set');
        System.assertEquals(mockEvent.LoginPlatform__c, logEntryArchive.LoginPlatform__c, 'logEntryArchive.LoginPlatform__c was not properly set');
        System.assertEquals(mockEvent.LoginType__c, logEntryArchive.LoginType__c, 'logEntryArchive.LoginType__c was not properly set');
        System.assertEquals(mockEvent.LogoutUrl__c, logEntryArchive.LogoutUrl__c, 'logEntryArchive.LogoutUrl__c was not properly set');
        System.assertEquals(mockEvent.Message__c, logEntryArchive.Message__c, 'logEntryArchive.Message__c was not properly set');
        System.assertEquals(mockEvent.NetworkId__c, logEntryArchive.NetworkId__c, 'logEntryArchive.NetworkId__c was not properly set');
        System.assertEquals(mockEvent.NetworkLoginUrl__c, logEntryArchive.NetworkLoginUrl__c, 'logEntryArchive.NetworkLoginUrl__c was not properly set');
        System.assertEquals(mockEvent.NetworkLogoutUrl__c, logEntryArchive.NetworkLogoutUrl__c, 'logEntryArchive.NetworkLogoutUrl__c was not properly set');
        System.assertEquals(
            mockEvent.NetworkSelfRegistrationUrl__c,
            logEntryArchive.NetworkSelfRegistrationUrl__c,
            'logEntryArchive.NetworkSelfRegistrationUrl__c was not properly set'
        );
        System.assertEquals(
            mockEvent.NetworkUrlPathPrefix__c,
            logEntryArchive.NetworkUrlPathPrefix__c,
            'logEntryArchive.NetworkUrlPathPrefix__c was not properly set'
        );
        System.assertEquals(
            mockEvent.OrganizationDomainUrl__c,
            logEntryArchive.OrganizationDomainUrl__c,
            'logEntryArchive.OrganizationDomainUrl__c was not properly set'
        );
        System.assertEquals(
            mockEvent.OrganizationEnvironmentType__c,
            logEntryArchive.OrganizationEnvironmentType__c,
            'logEntryArchive.OrganizationEnvironmentType__c was not properly set'
        );
        System.assertEquals(mockEvent.OrganizationId__c, logEntryArchive.OrganizationId__c, 'logEntryArchive.OrganizationId__c was not properly set');
        System.assertEquals(
            mockEvent.OrganizationInstanceName__c,
            logEntryArchive.OrganizationInstanceName__c,
            'logEntryArchive.OrganizationInstanceName__c was not properly set'
        );
        System.assertEquals(mockEvent.OrganizationName__c, logEntryArchive.OrganizationName__c, 'logEntryArchive.OrganizationName__c was not properly set');
        System.assertEquals(
            mockEvent.OrganizationNamespacePrefix__c,
            logEntryArchive.OrganizationNamespacePrefix__c,
            'logEntryArchive.OrganizationNamespacePrefix__c was not properly set'
        );
        System.assertEquals(mockEvent.OrganizationType__c, logEntryArchive.OrganizationType__c, 'logEntryArchive.OrganizationType__c was not properly set');
        System.assertEquals(mockEvent.OriginLocation__c, logEntryArchive.OriginLocation__c, 'logEntryArchive.OriginLocation__c was not properly set');
        System.assertEquals(mockEvent.OriginType__c, logEntryArchive.OriginType__c, 'logEntryArchive.OriginType__c was not properly set');
        System.assertEquals(
            mockEvent.ParentLogTransactionId__c,
            logEntryArchive.ParentLogTransactionId__c,
            'logEntryArchive.ParentLogTransactionId__c was not properly set'
        );
        System.assertEquals(mockEvent.ProfileId__c, logEntryArchive.ProfileId__c, 'logEntryArchive.ProfileId__c was not properly set');
        System.assertEquals(mockEvent.ProfileName__c, logEntryArchive.ProfileName__c, 'logEntryArchive.ProfileName__c was not properly set');
        System.assertEquals(
            mockEvent.RecordCollectionSize__c,
            logEntryArchive.RecordCollectionSize__c,
            'logEntryArchive.RecordCollectionSize__c was not properly set'
        );
        System.assertEquals(
            mockEvent.RecordCollectionType__c,
            logEntryArchive.RecordCollectionType__c,
            'logEntryArchive.RecordCollectionType__c was not properly set'
        );
        System.assertEquals(mockEvent.RecordId__c, logEntryArchive.RecordId__c, 'logEntryArchive.RecordId__c was not properly set');
        System.assertEquals(mockEvent.RecordJson__c, logEntryArchive.RecordJson__c, 'logEntryArchive.RecordJson__c was not properly set');
        System.assertEquals(
            mockEvent.RecordSObjectClassification__c,
            logEntryArchive.RecordSObjectClassification__c,
            'logEntryArchive.RecordSObjectClassification__c was not properly set'
        );
        System.assertEquals(mockEvent.RecordSObjectType__c, logEntryArchive.RecordSObjectType__c, 'logEntryArchive.RecordSObjectType__c was not properly set');
        System.assertEquals(
            mockEvent.RecordSObjectTypeNamespace__c,
            logEntryArchive.RecordSObjectTypeNamespace__c,
            'logEntryArchive.RecordSObjectTypeNamespace__c was not properly set'
        );
        System.assertEquals(mockEvent.SessionId__c, logEntryArchive.SessionId__c, 'logEntryArchive.SessionId__c was not properly set');
        System.assertEquals(
            mockEvent.SessionSecurityLevel__c,
            logEntryArchive.SessionSecurityLevel__c,
            'logEntryArchive.SessionSecurityLevel__c was not properly set'
        );
        System.assertEquals(mockEvent.SessionType__c, logEntryArchive.SessionType__c, 'logEntryArchive.SessionType__c was not properly set');
        System.assertEquals(mockEvent.SourceIp__c, logEntryArchive.SourceIp__c, 'logEntryArchive.SourceIp__c was not properly set');
        System.assertEquals(mockEvent.StackTrace__c, logEntryArchive.StackTrace__c, 'logEntryArchive.StackTrace__c was not properly set');
        System.assertEquals(mockEvent.SystemMode__c, logEntryArchive.SystemMode__c, 'logEntryArchive.SystemMode__c was not properly set');
        System.assertEquals(mockEvent.Tags__c, logEntryArchive.Tags__c, 'logEntryArchive.Tags__c was not properly set');
        System.assertEquals(mockEvent.ThemeDisplayed__c, logEntryArchive.ThemeDisplayed__c, 'logEntryArchive.ThemeDisplayed__c was not properly set');
        System.assertEquals(timestamp, logEntryArchive.Timestamp__c, 'logEntryArchive.Timestamp__c was not properly set');
        System.assertEquals(String.valueOf(timestamp.getTime()), logEntryArchive.TimestampString__c, 'logEntryArchive.TimestampString__c was not properly set');
        System.assertEquals(mockEvent.TimeZoneId__c, logEntryArchive.TimeZoneId__c, 'logEntryArchive.TimeZoneId__c was not properly set');
        System.assertEquals(
            mockEvent.TransactionEntryNumber__c,
            logEntryArchive.TransactionEntryNumber__c,
            'logEntryArchive.TransactionEntryNumber__c was not properly set'
        );
        System.assertEquals(mockEvent.TransactionId__c, logEntryArchive.TransactionId__c, 'logEntryArchive.TransactionId__c was not properly set');
        System.assertEquals(
            mockEvent.TriggerOperationType__c,
            logEntryArchive.TriggerOperationType__c,
            'logEntryArchive.TriggerOperationType__c was not properly set'
        );
        System.assertEquals(
            mockEvent.TriggerSObjectType__c,
            logEntryArchive.TriggerSObjectType__c,
            'logEntryArchive.TriggerSObjectType__c was not properly set'
        );
        System.assertEquals(
            mockEvent.UserLicenseDefinitionKey__c,
            logEntryArchive.UserLicenseDefinitionKey__c,
            'logEntryArchive.UserLicenseDefinitionKey__c was not properly set'
        );
        System.assertEquals(mockEvent.UserLicenseName__c, logEntryArchive.UserLicenseName__c, 'logEntryArchive.UserLicenseName__c was not properly set');
        System.assertEquals(mockEvent.UserLoggingLevel__c, logEntryArchive.UserLoggingLevel__c, 'logEntryArchive.UserLoggingLevel__c was not properly set');
        System.assertEquals(
            mockEvent.UserLoggingLevelOrdinal__c,
            logEntryArchive.UserLoggingLevelOrdinal__c,
            'logEntryArchive.UserLoggingLevelOrdinal__c was not properly set'
        );
        System.assertEquals(mockEvent.UserRoleId__c, logEntryArchive.UserRoleId__c, 'logEntryArchive.UserRoleId__c was not properly set');
        System.assertEquals(mockEvent.UserRoleName__c, logEntryArchive.UserRoleName__c, 'logEntryArchive.UserRoleName__c was not properly set');
        System.assertEquals(mockEvent.UserType__c, logEntryArchive.UserType__c, 'logEntryArchive.UserType__c was not properly set');
    }

    @SuppressWarnings('PMD.NcssMethodCount')
    private static void assertAllFieldsMatch(LogEntry__c logEntry, LogEntryArchive__b logEntryArchive) {
        List<String> tagNames = new List<String>();
        for (LogEntryTag__c logEntryTag : logEntry.LogEntryTags__r) {
            tagNames.add(logEntryTag.Tag__r.Name);
        }
        tagNames = new List<String>(new Set<String>(tagNames));
        tagNames.sort();
        String tags = String.join(tagNames, '\n');

        System.assertEquals(
            logEntry.Log__r.ApiReleaseNumber__c,
            logEntryArchive.ApiReleaseNumber__c,
            'logEntryArchive.ApiReleaseNumber__c was not properly set'
        );
        System.assertEquals(
            logEntry.Log__r.ApiReleaseVersion__c,
            logEntryArchive.ApiReleaseVersion__c,
            'logEntryArchive.ApiReleaseVersion__c was not properly set'
        );
        System.assertEquals(logEntry.Log__r.ApiVersion__c, logEntryArchive.ApiVersion__c, 'logEntryArchive.ApiVersion__c was not properly set');
        System.assertEquals(UserInfo.getUserId(), logEntryArchive.ArchivedById__c, 'logEntryArchive.ArchivedById__c was not properly set');
        System.assertNotEquals(null, logEntryArchive.ArchivedDate__c, 'logEntryArchive.ArchivedDate__c was not properly set');
        System.assertEquals(System.today(), logEntryArchive.ArchivedDate__c.date(), 'logEntryArchive.ArchivedDate__c was not properly set');
        System.assertEquals(UserInfo.getUsername(), logEntryArchive.ArchivedByUsername__c, 'logEntryArchive.ArchivedByUsername__c was not properly set');
        System.assertEquals(logEntry.Log__r.ClosedBy__c, logEntryArchive.ClosedById__c, 'logEntryArchive.ClosedById__c was not properly set');
        System.assertEquals(
            logEntry.Log__r.ClosedBy__r?.Username,
            logEntryArchive.ClosedByUsername__c,
            'logEntryArchive.ClosedByUsername__c was not properly set'
        );
        System.assertEquals(logEntry.Log__r.ClosedDate__c, logEntryArchive.ClosedDate__c, 'logEntryArchive.ClosedDate__c was not properly set');
        System.assertEquals(logEntry.Log__r.Comments__c, logEntryArchive.Comments__c, 'logEntryArchive.Comments__c was not properly set');
        System.assertEquals(logEntry.ComponentType__c, logEntryArchive.ComponentType__c, 'logEntryArchive.ComponentType__c was not properly set');
        System.assertEquals(
            logEntry.DatabaseResultCollectionSize__c,
            logEntryArchive.DatabaseResultCollectionSize__c,
            'logEntryArchive.DatabaseResultCollectionSize__c was not properly set'
        );
        System.assertEquals(
            logEntry.DatabaseResultCollectionType__c,
            logEntryArchive.DatabaseResultCollectionType__c,
            'logEntryArchive.DatabaseResultCollectionType__c was not properly set'
        );
        System.assertEquals(
            logEntry.DatabaseResultJson__c,
            logEntryArchive.DatabaseResultJson__c,
            'logEntryArchive.DatabaseResultJson__c was not properly set'
        );
        System.assertEquals(
            logEntry.DatabaseResultType__c,
            logEntryArchive.DatabaseResultType__c,
            'logEntryArchive.DatabaseResultType__c was not properly set'
        );
        System.assertEquals(logEntry.EpochTimestamp__c, logEntryArchive.EpochTimestamp__c, 'logEntryArchive.EpochTimestamp__c was not properly set');
        System.assertEquals(logEntry.EventUuid__c, logEntryArchive.EventUuid__c, 'logEntryArchive.EventUuid__c was not properly set');
        System.assertEquals(logEntry.ExceptionMessage__c, logEntryArchive.ExceptionMessage__c, 'logEntryArchive.ExceptionMessage__c was not properly set');
        System.assertEquals(
            logEntry.ExceptionStackTrace__c,
            logEntryArchive.ExceptionStackTrace__c,
            'logEntryArchive.ExceptionStackTrace__c was not properly set'
        );
        System.assertEquals(logEntry.ExceptionType__c, logEntryArchive.ExceptionType__c, 'logEntryArchive.ExceptionType__c was not properly set');
        System.assertEquals(logEntry.HttpRequestBody__c, logEntryArchive.HttpRequestBody__c, 'logEntryArchive.HttpRequestBody__c was not properly set');
        System.assertEquals(
            logEntry.HttpRequestEndpoint__c,
            logEntryArchive.HttpRequestEndpoint__c,
            'logEntryArchive.HttpRequestEndpoint__c was not properly set'
        );
        System.assertEquals(logEntry.HttpRequestMethod__c, logEntryArchive.HttpRequestMethod__c, 'logEntryArchive.HttpRequestMethod__c was not properly set');
        System.assertEquals(logEntry.HttpResponseBody__c, logEntryArchive.HttpResponseBody__c, 'logEntryArchive.HttpResponseBody__c was not properly set');
        System.assertEquals(
            logEntry.HttpResponseHeaderKeys__c,
            logEntryArchive.HttpResponseHeaderKeys__c,
            'logEntryArchive.HttpResponseHeaderKeys__c was not properly set'
        );
        System.assertEquals(
            logEntry.HttpResponseStatus__c,
            logEntryArchive.HttpResponseStatus__c,
            'logEntryArchive.HttpResponseStatus__c was not properly set'
        );
        System.assertEquals(
            logEntry.HttpResponseStatusCode__c,
            logEntryArchive.HttpResponseStatusCode__c,
            'logEntryArchive.HttpResponseStatusCode__c was not properly set'
        );
        System.assertEquals(String.valueOf(logEntry.Log__r.IsClosed__c), logEntryArchive.IsClosed__c, 'logEntryArchive.IsClosed__c was not properly set');
        System.assertEquals(String.valueOf(logEntry.Log__r.IsResolved__c), logEntryArchive.IsResolved__c, 'logEntryArchive.IsResolved__c was not properly set');
        System.assertEquals(logEntry.Log__r.Issue__c, logEntryArchive.Issue__c, 'logEntryArchive.Issue__c was not properly set');
        System.assertEquals(
            logEntry.LimitsAggregateQueriesMax__c,
            logEntryArchive.LimitsAggregateQueriesMax__c,
            'logEntryArchive.LimitsAggregateQueriesMax__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsAggregateQueriesUsed__c,
            logEntryArchive.LimitsAggregateQueriesUsed__c,
            'logEntryArchive.LimitsAggregateQueriesUsed__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsAsyncCallsMax__c,
            logEntryArchive.LimitsAsyncCallsMax__c,
            'logEntryArchive.LimitsAsyncCallsMax__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsAsyncCallsUsed__c,
            logEntryArchive.LimitsAsyncCallsUsed__c,
            'logEntryArchive.LimitsAsyncCallsUsed__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsCalloutsUsed__c,
            logEntryArchive.LimitsCalloutsUsed__c,
            'logEntryArchive.LimitsCalloutsUsed__c was not properly set'
        );
        System.assertEquals(logEntry.LimitsCpuTimeMax__c, logEntryArchive.LimitsCpuTimeMax__c, 'logEntryArchive.LimitsCpuTimeMax__c was not properly set');
        System.assertEquals(logEntry.LimitsCpuTimeUsed__c, logEntryArchive.LimitsCpuTimeUsed__c, 'logEntryArchive.LimitsCpuTimeUsed__c was not properly set');
        System.assertEquals(logEntry.LimitsDmlRowsMax__c, logEntryArchive.LimitsDmlRowsMax__c, 'logEntryArchive.LimitsDmlRowsMax__c was not properly set');
        System.assertEquals(logEntry.LimitsDmlRowsUsed__c, logEntryArchive.LimitsDmlRowsUsed__c, 'logEntryArchive.LimitsDmlRowsUsed__c was not properly set');
        System.assertEquals(
            logEntry.LimitsDmlStatementsMax__c,
            logEntryArchive.LimitsDmlStatementsMax__c,
            'logEntryArchive.LimitsDmlStatementsMax__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsDmlStatementsUsed__c,
            logEntryArchive.LimitsDmlStatementsUsed__c,
            'logEntryArchive.LimitsDmlStatementsUsed__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsEmailInvocationsMax__c,
            logEntryArchive.LimitsEmailInvocationsMax__c,
            'logEntryArchive.LimitsEmailInvocationsMax__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsEmailInvocationsUsed__c,
            logEntryArchive.LimitsEmailInvocationsUsed__c,
            'logEntryArchive.LimitsEmailInvocationsUsed__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsFutureCallsMax__c,
            logEntryArchive.LimitsFutureCallsMax__c,
            'logEntryArchive.LimitsFutureCallsMax__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsFutureCallsUsed__c,
            logEntryArchive.LimitsFutureCallsUsed__c,
            'logEntryArchive.LimitsFutureCallsUsed__c was not properly set'
        );
        System.assertEquals(logEntry.LimitsHeapSizeMax__c, logEntryArchive.LimitsHeapSizeMax__c, 'logEntryArchive.LimitsHeapSizeMax__c was not properly set');
        System.assertEquals(
            logEntry.LimitsHeapSizeUsed__c,
            logEntryArchive.LimitsHeapSizeUsed__c,
            'logEntryArchive.LimitsHeapSizeUsed__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsMobilePushApexCallsMax__c,
            logEntryArchive.LimitsMobilePushApexCallsMax__c,
            'logEntryArchive.LimitsMobilePushApexCallsMax__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsMobilePushApexCallsUsed__c,
            logEntryArchive.LimitsMobilePushApexCallsUsed__c,
            'logEntryArchive.LimitsMobilePushApexCallsUsed__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsPublishImmediateDmlStatementsMax__c,
            logEntryArchive.LimitsPublishImmediateDmlStatementsMax__c,
            'logEntryArchive.LimitsPublishImmediateDmlStatementsMax__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsPublishImmediateDmlStatementsUsed__c,
            logEntryArchive.LimitsPublishImmediateDmlStatementsUsed__c,
            'logEntryArchive.LimitsPublishImmediateDmlStatementsUsed__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsQueueableJobsMax__c,
            logEntryArchive.LimitsQueueableJobsMax__c,
            'logEntryArchive.LimitsQueueableJobsMax__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsQueueableJobsUsed__c,
            logEntryArchive.LimitsQueueableJobsUsed__c,
            'logEntryArchive.LimitsQueueableJobsUsed__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsSoqlQueriesMax__c,
            logEntryArchive.LimitsSoqlQueriesMax__c,
            'logEntryArchive.LimitsSoqlQueriesMax__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsSoqlQueriesUsed__c,
            logEntryArchive.LimitsSoqlQueriesUsed__c,
            'logEntryArchive.LimitsSoqlQueriesUsed__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsSoqlQueryLocatorRowsMax__c,
            logEntryArchive.LimitsSoqlQueryLocatorRowsMax__c,
            'logEntryArchive.LimitsSoqlQueryLocatorRowsMax__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsSoqlQueryLocatorRowsUsed__c,
            logEntryArchive.LimitsSoqlQueryLocatorRowsUsed__c,
            'logEntryArchive.LimitsSoqlQueryLocatorRowsUsed__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsSoqlQueryRowsMax__c,
            logEntryArchive.LimitsSoqlQueryRowsMax__c,
            'logEntryArchive.LimitsSoqlQueryRowsMax__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsSoqlQueryRowsUsed__c,
            logEntryArchive.LimitsSoqlQueryRowsUsed__c,
            'logEntryArchive.LimitsSoqlQueryRowsUsed__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsSoslSearchesMax__c,
            logEntryArchive.LimitsSoslSearchesMax__c,
            'logEntryArchive.LimitsSoslSearchesMax__c was not properly set'
        );
        System.assertEquals(
            logEntry.LimitsSoslSearchesUsed__c,
            logEntryArchive.LimitsSoslSearchesUsed__c,
            'logEntryArchive.LimitsSoslSearchesUsed__c was not properly set'
        );
        System.assertEquals(logEntry.Log__r.Locale__c, logEntryArchive.Locale__c, 'logEntryArchive.Locale__c was not properly set');
        System.assertEquals(logEntry.Log__r.LoggedBy__c, logEntryArchive.LoggedById__c, 'logEntryArchive.LoggedById__c was not properly set');
        System.assertEquals(
            logEntry.Log__r.LoggedByUsername__c,
            logEntryArchive.LoggedByUsername__c,
            'logEntryArchive.LoggedByUsername__c was not properly set'
        );
        System.assertEquals(
            logEntry.Log__r.LoggerVersionNumber__c,
            logEntryArchive.LoggerVersionNumber__c,
            'logEntryArchive.LoggerVersionNumber__c was not properly set'
        );
        System.assertEquals(logEntry.LoggingLevel__c, logEntryArchive.LoggingLevel__c, 'logEntryArchive.LoggingLevel__c was not properly set');
        System.assertEquals(
            logEntry.LoggingLevelOrdinal__c,
            logEntryArchive.LoggingLevelOrdinal__c,
            'logEntryArchive.LoggingLevelOrdinal__c was not properly set'
        );
        System.assertEquals(
            logEntry.Log__r.LoginApplication__c,
            logEntryArchive.LoginApplication__c,
            'logEntryArchive.LoginApplication__c was not properly set'
        );
        System.assertEquals(logEntry.Log__r.LoginBrowser__c, logEntryArchive.LoginBrowser__c, 'logEntryArchive.LoginBrowser__c was not properly set');
        System.assertEquals(logEntry.Log__r.LoginHistoryId__c, logEntryArchive.LoginHistoryId__c, 'logEntryArchive.LoginHistoryId__c was not properly set');
        System.assertEquals(logEntry.Log__r.LoginPlatform__c, logEntryArchive.LoginPlatform__c, 'logEntryArchive.LoginPlatform__c was not properly set');
        System.assertEquals(logEntry.Log__r.LoginType__c, logEntryArchive.LoginType__c, 'logEntryArchive.LoginType__c was not properly set');
        System.assertEquals(logEntry.Log__r.LogoutUrl__c, logEntryArchive.LogoutUrl__c, 'logEntryArchive.LogoutUrl__c was not properly set');
        System.assertEquals(logEntry.Log__r.LogPurgeAction__c, logEntryArchive.LogPurgeAction__c, 'logEntryArchive.LogPurgeAction__c was not properly set');
        System.assertEquals(
            logEntry.Log__r.LogRetentionDate__c,
            logEntryArchive.LogRetentionDate__c,
            'logEntryArchive.LogRetentionDate__c was not properly set'
        );
        System.assertEquals(logEntry.Message__c, logEntryArchive.Message__c, 'logEntryArchive.Message__c was not properly set');
        System.assertEquals(
            String.valueOf(logEntry.MessageMasked__c),
            logEntryArchive.MessageMasked__c,
            'logEntryArchive.MessageMasked__c was not properly set'
        );
        System.assertEquals(
            String.valueOf(logEntry.MessageTruncated__c),
            logEntryArchive.MessageTruncated__c,
            'logEntryArchive.MessageTruncated__c was not properly set'
        );
        System.assertEquals(logEntry.Log__r.NetworkId__c, logEntryArchive.NetworkId__c, 'logEntryArchive.NetworkId__c was not properly set');
        System.assertEquals(logEntry.Log__r.NetworkLoginUrl__c, logEntryArchive.NetworkLoginUrl__c, 'logEntryArchive.NetworkLoginUrl__c was not properly set');
        System.assertEquals(
            logEntry.Log__r.NetworkLogoutUrl__c,
            logEntryArchive.NetworkLogoutUrl__c,
            'logEntryArchive.NetworkLogoutUrl__c was not properly set'
        );
        System.assertEquals(
            logEntry.Log__r.NetworkSelfRegistrationUrl__c,
            logEntryArchive.NetworkSelfRegistrationUrl__c,
            'logEntryArchive.NetworkSelfRegistrationUrl__c was not properly set'
        );
        System.assertEquals(
            logEntry.Log__r.NetworkUrlPathPrefix__c,
            logEntryArchive.NetworkUrlPathPrefix__c,
            'logEntryArchive.NetworkUrlPathPrefix__c was not properly set'
        );
        System.assertEquals(
            logEntry.Log__r.OrganizationDomainUrl__c,
            logEntryArchive.OrganizationDomainUrl__c,
            'logEntryArchive.OrganizationDomainUrl__c was not properly set'
        );
        System.assertEquals(
            logEntry.Log__r.OrganizationEnvironmentType__c,
            logEntryArchive.OrganizationEnvironmentType__c,
            'logEntryArchive.OrganizationEnvironmentType__c was not properly set'
        );
        System.assertEquals(logEntry.Log__r.OrganizationId__c, logEntryArchive.OrganizationId__c, 'logEntryArchive.OrganizationId__c was not properly set');
        System.assertEquals(
            logEntry.Log__r.OrganizationInstanceName__c,
            logEntryArchive.OrganizationInstanceName__c,
            'logEntryArchive.OrganizationInstanceName__c was not properly set'
        );
        System.assertEquals(
            logEntry.Log__r.OrganizationName__c,
            logEntryArchive.OrganizationName__c,
            'logEntryArchive.OrganizationName__c was not properly set'
        );
        System.assertEquals(
            logEntry.Log__r.OrganizationNamespacePrefix__c,
            logEntryArchive.OrganizationNamespacePrefix__c,
            'logEntryArchive.OrganizationNamespacePrefix__c was not properly set'
        );
        System.assertEquals(
            logEntry.Log__r.OrganizationType__c,
            logEntryArchive.OrganizationType__c,
            'logEntryArchive.OrganizationType__c was not properly set'
        );
        System.assertEquals(logEntry.OriginLocation__c, logEntryArchive.OriginLocation__c, 'logEntryArchive.OriginLocation__c was not properly set');
        System.assertEquals(logEntry.OriginType__c, logEntryArchive.OriginType__c, 'logEntryArchive.OriginType__c was not properly set');
        System.assertEquals(
            logEntry.Log__r.ParentLog__r?.TransactionId__c,
            logEntryArchive.ParentLogTransactionId__c,
            'logEntryArchive.ParentLogTransactionId__c was not properly set'
        );
        System.assertEquals(logEntry.Log__r.Priority__c, logEntryArchive.Priority__c, 'logEntryArchive.Priority__c was not properly set');
        System.assertEquals(logEntry.Log__r.ProfileId__c, logEntryArchive.ProfileId__c, 'logEntryArchive.ProfileId__c was not properly set');
        System.assertEquals(logEntry.Log__r.ProfileName__c, logEntryArchive.ProfileName__c, 'logEntryArchive.ProfileName__c was not properly set');
        System.assertEquals(
            logEntry.RecordCollectionSize__c,
            logEntryArchive.RecordCollectionSize__c,
            'logEntryArchive.RecordCollectionSize__c was not properly set'
        );
        System.assertEquals(
            logEntry.RecordCollectionType__c,
            logEntryArchive.RecordCollectionType__c,
            'logEntryArchive.RecordCollectionType__c was not properly set'
        );
        System.assertEquals(logEntry.RecordId__c, logEntryArchive.RecordId__c, 'logEntryArchive.RecordId__c was not properly set');
        System.assertEquals(logEntry.RecordJson__c, logEntryArchive.RecordJson__c, 'logEntryArchive.RecordJson__c was not properly set');
        System.assertEquals(logEntry.RecordName__c, logEntryArchive.RecordName__c, 'logEntryArchive.RecordName__c was not properly set');
        System.assertEquals(
            String.valueOf(logEntry.RecordJsonMasked__c),
            logEntryArchive.RecordJsonMasked__c,
            'logEntryArchive.RecordJsonMasked__c was not properly set'
        );
        System.assertEquals(
            logEntry.RecordSObjectClassification__c,
            logEntryArchive.RecordSObjectClassification__c,
            'logEntryArchive.RecordSObjectClassification__c was not properly set'
        );
        System.assertEquals(logEntry.RecordSObjectType__c, logEntryArchive.RecordSObjectType__c, 'logEntryArchive.RecordSObjectType__c was not properly set');
        System.assertEquals(
            logEntry.RecordSObjectTypeNamespace__c,
            logEntryArchive.RecordSObjectTypeNamespace__c,
            'logEntryArchive.RecordSObjectTypeNamespace__c was not properly set'
        );
        System.assertEquals(logEntry.Log__r.SessionId__c, logEntryArchive.SessionId__c, 'logEntryArchive.SessionId__c was not properly set');
        System.assertEquals(
            logEntry.Log__r.SessionSecurityLevel__c,
            logEntryArchive.SessionSecurityLevel__c,
            'logEntryArchive.SessionSecurityLevel__c was not properly set'
        );
        System.assertEquals(logEntry.Log__r.SessionType__c, logEntryArchive.SessionType__c, 'logEntryArchive.SessionType__c was not properly set');
        System.assertEquals(logEntry.Log__r.SourceIp__c, logEntryArchive.SourceIp__c, 'logEntryArchive.SourceIp__c was not properly set');
        System.assertEquals(logEntry.StackTrace__c, logEntryArchive.StackTrace__c, 'logEntryArchive.StackTrace__c was not properly set');
        System.assertEquals(logEntry.Log__r.Status__c, logEntryArchive.Status__c, 'logEntryArchive.Status__c was not properly set');
        System.assertEquals(logEntry.Log__r.SystemMode__c, logEntryArchive.SystemMode__c, 'logEntryArchive.SystemMode__c was not properly set');
        System.assertEquals(tags, logEntryArchive.Tags__c, 'logEntryArchive.Tags__c was not properly set');
        System.assertEquals(logEntry.Log__r.ThemeDisplayed__c, logEntryArchive.ThemeDisplayed__c, 'logEntryArchive.ThemeDisplayed__c was not properly set');
        System.assertEquals(logEntry.Timestamp__c, logEntryArchive.Timestamp__c, 'logEntryArchive.Timestamp__c was not properly set');
        System.assertEquals(
            String.valueOf(logEntry.Timestamp__c),
            logEntryArchive.TimestampString__c,
            'logEntryArchive.TimestampString__c was not properly set'
        );
        System.assertEquals(logEntry.Log__r.TimeZoneId__c, logEntryArchive.TimeZoneId__c, 'logEntryArchive.TimeZoneId__c was not properly set');
        System.assertEquals(
            logEntry.TransactionEntryNumber__c,
            logEntryArchive.TransactionEntryNumber__c,
            'logEntryArchive.TransactionEntryNumber__c was not properly set'
        );
        System.assertEquals(logEntry.Log__r.TransactionId__c, logEntryArchive.TransactionId__c, 'logEntryArchive.TransactionId__c was not properly set');
        System.assertEquals(
            String.valueOf(logEntry.TriggerIsExecuting__c),
            logEntryArchive.TriggerIsExecuting__c,
            'logEntryArchive.TriggerIsExecuting__c was not properly set'
        );
        System.assertEquals(
            logEntry.TriggerOperationType__c,
            logEntryArchive.TriggerOperationType__c,
            'logEntryArchive.TriggerOperationType__c was not properly set'
        );
        System.assertEquals(
            logEntry.TriggerSObjectType__c,
            logEntryArchive.TriggerSObjectType__c,
            'logEntryArchive.TriggerSObjectType__c was not properly set'
        );
        System.assertEquals(
            logEntry.Log__r.UserLicenseDefinitionKey__c,
            logEntryArchive.UserLicenseDefinitionKey__c,
            'logEntryArchive.UserLicenseDefinitionKey__c was not properly set'
        );
        System.assertEquals(logEntry.Log__r.UserLicenseName__c, logEntryArchive.UserLicenseName__c, 'logEntryArchive.UserLicenseName__c was not properly set');
        System.assertEquals(
            logEntry.Log__r.UserLoggingLevel__c,
            logEntryArchive.UserLoggingLevel__c,
            'logEntryArchive.UserLoggingLevel__c was not properly set'
        );
        System.assertEquals(
            logEntry.Log__r.UserLoggingLevelOrdinal__c,
            logEntryArchive.UserLoggingLevelOrdinal__c,
            'logEntryArchive.UserLoggingLevelOrdinal__c was not properly set'
        );
        System.assertEquals(logEntry.Log__r.UserRoleId__c, logEntryArchive.UserRoleId__c, 'logEntryArchive.UserRoleId__c was not properly set');
        System.assertEquals(logEntry.Log__r.UserRoleName__c, logEntryArchive.UserRoleName__c, 'logEntryArchive.UserRoleName__c was not properly set');
        System.assertEquals(logEntry.Log__r.UserType__c, logEntryArchive.UserType__c, 'logEntryArchive.UserType__c was not properly set');
    }
}
