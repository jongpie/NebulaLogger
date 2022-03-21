//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest
private class LogEntryArchiveBuilder_Tests {
    @IsTest
    static void it_should_write_all_fields_over_from_log_entry_event() {
        Datetime timestamp = System.now();
        LogEntryEvent__e mockEvent = LoggerTestUtils.createMockLogEntryEvent(timestamp);

        LogEntryArchive__b logEntryArchive = new LogEntryArchiveBuilder(mockEvent).getLogEntryArchive();

        assertAllFieldsMatch(timestamp, mockEvent, logEntryArchive);
    }

    @IsTest
    static void it_should_cache_instance_of_log_entry_archive() {
        Datetime timestamp = System.now();
        LogEntryEvent__e mockEvent = LoggerTestUtils.createMockLogEntryEvent(timestamp);
        LogEntryArchiveBuilder archiveBuilder = new LogEntryArchiveBuilder(mockEvent);
        LogEntryArchive__b originalLogEntryArchive = archiveBuilder.getLogEntryArchive();
        originalLogEntryArchive.Message__c = 'Some new value';

        LogEntryArchive__b secondLogEntryArchive = archiveBuilder.getLogEntryArchive();

        System.assertEquals(originalLogEntryArchive, secondLogEntryArchive);
    }

    @SuppressWarnings('PMD.NcssMethodCount')
    private static void assertAllFieldsMatch(Datetime timestamp, LogEntryEvent__e mockEvent, LogEntryArchive__b logEntryArchive) {
        System.assertEquals(mockEvent.ApiVersion__c, logEntryArchive.ApiVersion__c);
        System.assertEquals(mockEvent.ComponentType__c, logEntryArchive.ComponentType__c);
        System.assertEquals(mockEvent.DatabaseResultCollectionType__c, logEntryArchive.DatabaseResultCollectionType__c);
        System.assertEquals(mockEvent.DatabaseResultJson__c, logEntryArchive.DatabaseResultJson__c);
        System.assertEquals(mockEvent.DatabaseResultType__c, logEntryArchive.DatabaseResultType__c);
        System.assertEquals(mockEvent.EpochTimestamp__c, logEntryArchive.EpochTimestamp__c);
        System.assertEquals(mockEvent.ExceptionMessage__c, logEntryArchive.ExceptionMessage__c);
        System.assertEquals(mockEvent.ExceptionStackTrace__c, logEntryArchive.ExceptionStackTrace__c);
        System.assertEquals(mockEvent.ExceptionType__c, logEntryArchive.ExceptionType__c);
        System.assertEquals(mockEvent.LimitsAggregateQueriesMax__c, logEntryArchive.LimitsAggregateQueriesMax__c);
        System.assertEquals(mockEvent.LimitsAggregateQueriesUsed__c, logEntryArchive.LimitsAggregateQueriesUsed__c);
        System.assertEquals(mockEvent.LimitsAsyncCallsMax__c, logEntryArchive.LimitsAsyncCallsMax__c);
        System.assertEquals(mockEvent.LimitsAsyncCallsUsed__c, logEntryArchive.LimitsAsyncCallsUsed__c);
        System.assertEquals(mockEvent.LimitsCalloutsUsed__c, logEntryArchive.LimitsCalloutsUsed__c);
        System.assertEquals(mockEvent.LimitsCpuTimeMax__c, logEntryArchive.LimitsCpuTimeMax__c);
        System.assertEquals(mockEvent.LimitsCpuTimeUsed__c, logEntryArchive.LimitsCpuTimeUsed__c);
        System.assertEquals(mockEvent.LimitsDmlRowsMax__c, logEntryArchive.LimitsDmlRowsMax__c);
        System.assertEquals(mockEvent.LimitsDmlRowsUsed__c, logEntryArchive.LimitsDmlRowsUsed__c);
        System.assertEquals(mockEvent.LimitsDmlStatementsMax__c, logEntryArchive.LimitsDmlStatementsMax__c);
        System.assertEquals(mockEvent.LimitsDmlStatementsUsed__c, logEntryArchive.LimitsDmlStatementsUsed__c);
        System.assertEquals(mockEvent.LimitsEmailInvocationsMax__c, logEntryArchive.LimitsEmailInvocationsMax__c);
        System.assertEquals(mockEvent.LimitsEmailInvocationsUsed__c, logEntryArchive.LimitsEmailInvocationsUsed__c);
        System.assertEquals(mockEvent.LimitsFutureCallsMax__c, logEntryArchive.LimitsFutureCallsMax__c);
        System.assertEquals(mockEvent.LimitsFutureCallsUsed__c, logEntryArchive.LimitsFutureCallsUsed__c);
        System.assertEquals(mockEvent.LimitsHeapSizeMax__c, logEntryArchive.LimitsHeapSizeMax__c);
        System.assertEquals(mockEvent.LimitsHeapSizeUsed__c, logEntryArchive.LimitsHeapSizeUsed__c);
        System.assertEquals(mockEvent.LimitsPublishImmediateDmlStatementsMax__c, logEntryArchive.LimitsPublishImmediateDmlStatementsMax__c);
        System.assertEquals(mockEvent.LimitsPublishImmediateDmlStatementsUsed__c, logEntryArchive.LimitsPublishImmediateDmlStatementsUsed__c);
        System.assertEquals(mockEvent.LimitsMobilePushApexCallsMax__c, logEntryArchive.LimitsMobilePushApexCallsMax__c);
        System.assertEquals(mockEvent.LimitsMobilePushApexCallsUsed__c, logEntryArchive.LimitsMobilePushApexCallsUsed__c);
        System.assertEquals(mockEvent.LimitsQueueableJobsMax__c, logEntryArchive.LimitsQueueableJobsMax__c);
        System.assertEquals(mockEvent.LimitsQueueableJobsUsed__c, logEntryArchive.LimitsQueueableJobsUsed__c);
        System.assertEquals(mockEvent.LimitsSoqlQueriesMax__c, logEntryArchive.LimitsSoqlQueriesMax__c);
        System.assertEquals(mockEvent.LimitsSoqlQueriesUsed__c, logEntryArchive.LimitsSoqlQueriesUsed__c);
        System.assertEquals(mockEvent.LimitsSoqlQueryLocatorRowsMax__c, logEntryArchive.LimitsSoqlQueryLocatorRowsMax__c);
        System.assertEquals(mockEvent.LimitsSoqlQueryLocatorRowsUsed__c, logEntryArchive.LimitsSoqlQueryLocatorRowsUsed__c);
        System.assertEquals(mockEvent.LimitsSoqlQueryRowsMax__c, logEntryArchive.LimitsSoqlQueryRowsMax__c);
        System.assertEquals(mockEvent.LimitsSoqlQueryRowsUsed__c, logEntryArchive.LimitsSoqlQueryRowsUsed__c);
        System.assertEquals(mockEvent.LimitsSoslSearchesMax__c, logEntryArchive.LimitsSoslSearchesMax__c);
        System.assertEquals(mockEvent.LimitsSoslSearchesUsed__c, logEntryArchive.LimitsSoslSearchesUsed__c);
        System.assertEquals(mockEvent.Locale__c, logEntryArchive.Locale__c);
        System.assertEquals(String.isNotBlank(mockEvent.LoggedById__c) ? mockEvent.LoggedById__c : 'Anonymous', logEntryArchive.LoggedBy__c);
        System.assertEquals(mockEvent.LoggedById__c, logEntryArchive.LoggedById__c);
        System.assertEquals(mockEvent.LoggedByUsername__c, logEntryArchive.LoggedByUsername__c);
        System.assertEquals(mockEvent.LoggerVersionNumber__c, logEntryArchive.LoggerVersionNumber__c);
        System.assertEquals(mockEvent.LoggingLevel__c, logEntryArchive.LoggingLevel__c);
        System.assertEquals(mockEvent.LoggingLevelOrdinal__c, logEntryArchive.LoggingLevelOrdinal__c);
        System.assertEquals(mockEvent.LoginApplication__c, logEntryArchive.LoginApplication__c);
        System.assertEquals(mockEvent.LoginBrowser__c, logEntryArchive.LoginBrowser__c);
        System.assertEquals(mockEvent.LoginHistoryId__c, logEntryArchive.LoginHistoryId__c);
        System.assertEquals(mockEvent.LoginPlatform__c, logEntryArchive.LoginPlatform__c);
        System.assertEquals(mockEvent.LoginType__c, logEntryArchive.LoginType__c);
        System.assertEquals(mockEvent.LogoutUrl__c, logEntryArchive.LogoutUrl__c);
        System.assertEquals(mockEvent.Message__c, logEntryArchive.Message__c);
        System.assertEquals(mockEvent.NetworkId__c, logEntryArchive.NetworkId__c);
        System.assertEquals(mockEvent.NetworkLoginUrl__c, logEntryArchive.NetworkLoginUrl__c);
        System.assertEquals(mockEvent.NetworkLogoutUrl__c, logEntryArchive.NetworkLogoutUrl__c);
        System.assertEquals(mockEvent.NetworkSelfRegistrationUrl__c, logEntryArchive.NetworkSelfRegistrationUrl__c);
        System.assertEquals(mockEvent.NetworkUrlPathPrefix__c, logEntryArchive.NetworkUrlPathPrefix__c);
        System.assertEquals(mockEvent.OrganizationDomainUrl__c, logEntryArchive.OrganizationDomainUrl__c);
        System.assertEquals(mockEvent.OrganizationEnvironmentType__c, logEntryArchive.OrganizationEnvironmentType__c);
        System.assertEquals(mockEvent.OrganizationId__c, logEntryArchive.OrganizationId__c);
        System.assertEquals(mockEvent.OrganizationInstanceName__c, logEntryArchive.OrganizationInstanceName__c);
        System.assertEquals(mockEvent.OrganizationName__c, logEntryArchive.OrganizationName__c);
        System.assertEquals(mockEvent.OrganizationNamespacePrefix__c, logEntryArchive.OrganizationNamespacePrefix__c);
        System.assertEquals(mockEvent.OrganizationType__c, logEntryArchive.OrganizationType__c);
        System.assertEquals(mockEvent.OriginLocation__c, logEntryArchive.OriginLocation__c);
        System.assertEquals(mockEvent.OriginType__c, logEntryArchive.OriginType__c);
        System.assertEquals(mockEvent.ParentLogTransactionId__c, logEntryArchive.ParentLogTransactionId__c);
        System.assertEquals(mockEvent.ProfileId__c, logEntryArchive.ProfileId__c);
        System.assertEquals(mockEvent.ProfileName__c, logEntryArchive.ProfileName__c);
        System.assertEquals(mockEvent.RecordCollectionType__c, logEntryArchive.RecordCollectionType__c);
        System.assertEquals(mockEvent.RecordId__c, logEntryArchive.RecordId__c);
        System.assertEquals(mockEvent.RecordJson__c, logEntryArchive.RecordJson__c);
        System.assertEquals(mockEvent.RecordSObjectClassification__c, logEntryArchive.RecordSObjectClassification__c);
        System.assertEquals(mockEvent.RecordSObjectType__c, logEntryArchive.RecordSObjectType__c);
        System.assertEquals(mockEvent.RecordSObjectTypeNamespace__c, logEntryArchive.RecordSObjectTypeNamespace__c);
        System.assertEquals(mockEvent.SessionId__c, logEntryArchive.SessionId__c);
        System.assertEquals(mockEvent.SessionSecurityLevel__c, logEntryArchive.SessionSecurityLevel__c);
        System.assertEquals(mockEvent.SessionType__c, logEntryArchive.SessionType__c);
        System.assertEquals(mockEvent.SourceIp__c, logEntryArchive.SourceIp__c);
        System.assertEquals(mockEvent.StackTrace__c, logEntryArchive.StackTrace__c);
        System.assertEquals(mockEvent.SystemMode__c, logEntryArchive.SystemMode__c);
        System.assertEquals(mockEvent.Tags__c, logEntryArchive.Tags__c);
        System.assertEquals(mockEvent.ThemeDisplayed__c, logEntryArchive.ThemeDisplayed__c);
        System.assertEquals(timestamp, logEntryArchive.Timestamp__c);
        System.assertEquals(String.valueOf(timestamp.getTime()), logEntryArchive.TimestampString__c);
        System.assertEquals(mockEvent.TimeZoneId__c, logEntryArchive.TimeZoneId__c);
        System.assertEquals(mockEvent.TransactionEntryNumber__c, logEntryArchive.TransactionEntryNumber__c);
        System.assertEquals(mockEvent.TransactionId__c, logEntryArchive.TransactionId__c);
        System.assertEquals(mockEvent.TriggerOperationType__c, logEntryArchive.TriggerOperationType__c);
        System.assertEquals(mockEvent.TriggerSObjectType__c, logEntryArchive.TriggerSObjectType__c);
        System.assertEquals(mockEvent.UserLicenseDefinitionKey__c, logEntryArchive.UserLicenseDefinitionKey__c);
        System.assertEquals(mockEvent.UserLicenseName__c, logEntryArchive.UserLicenseName__c);
        System.assertEquals(mockEvent.UserLoggingLevel__c, logEntryArchive.UserLoggingLevel__c);
        System.assertEquals(mockEvent.UserLoggingLevelOrdinal__c, logEntryArchive.UserLoggingLevelOrdinal__c);
        System.assertEquals(mockEvent.UserRoleId__c, logEntryArchive.UserRoleId__c);
        System.assertEquals(mockEvent.UserRoleName__c, logEntryArchive.UserRoleName__c);
        System.assertEquals(mockEvent.UserType__c, logEntryArchive.UserType__c);
    }
}
