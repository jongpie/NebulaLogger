@isTest
private class LogEntryArchiveBuilder_Tests {
    private static String FAKE_DATA_STRING = 'someFakeData';
    private static Integer FAKE_DATA_NUMBER = 1;

    @isTest
    static void it_should_write_all_fields_over_from_log_entry_event() {
        Datetime now = System.now();
        LogEntryEvent__e mockEvent = new LogEntryEvent__e(
            ApiVersion__c = '52',
            DatabaseResultCollectionType__c = FAKE_DATA_STRING,
            DatabaseResultJson__c = FAKE_DATA_STRING,
            DatabaseResultType__c = FAKE_DATA_STRING,
            ExceptionMessage__c = FAKE_DATA_STRING,
            ExceptionStackTrace__c = FAKE_DATA_STRING,
            ExceptionType__c = FAKE_DATA_STRING,
            LimitsAggregateQueriesMax__c = FAKE_DATA_NUMBER,
            LimitsAggregateQueriesUsed__c = FAKE_DATA_NUMBER,
            LimitsAsyncCallsMax__c = FAKE_DATA_NUMBER,
            LimitsAsyncCallsUsed__c = FAKE_DATA_NUMBER,
            LimitsCalloutsUsed__c = FAKE_DATA_NUMBER,
            LimitsCpuTimeMax__c = FAKE_DATA_NUMBER,
            LimitsCpuTimeUsed__c = FAKE_DATA_NUMBER,
            LimitsDmlRowsMax__c = FAKE_DATA_NUMBER,
            LimitsDmlRowsUsed__c = FAKE_DATA_NUMBER,
            LimitsDmlStatementsMax__c = FAKE_DATA_NUMBER,
            LimitsDmlStatementsUsed__c = FAKE_DATA_NUMBER,
            LimitsEmailInvocationsMax__c = FAKE_DATA_NUMBER,
            LimitsEmailInvocationsUsed__c = FAKE_DATA_NUMBER,
            LimitsFutureCallsMax__c = FAKE_DATA_NUMBER,
            LimitsFutureCallsUsed__c = FAKE_DATA_NUMBER,
            LimitsHeapSizeMax__c = FAKE_DATA_NUMBER,
            LimitsHeapSizeUsed__c = FAKE_DATA_NUMBER,
            LimitsMobilePushApexCallsMax__c = FAKE_DATA_NUMBER,
            LimitsMobilePushApexCallsUsed__c = FAKE_DATA_NUMBER,
            LimitsQueueableJobsMax__c = FAKE_DATA_NUMBER,
            LimitsQueueableJobsUsed__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueriesMax__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueriesUsed__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueryLocatorRowsMax__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueryLocatorRowsUsed__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueryRowsMax__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueryRowsUsed__c = FAKE_DATA_NUMBER,
            LimitsSoslSearchesMax__c = FAKE_DATA_NUMBER,
            LimitsSoslSearchesUsed__c = FAKE_DATA_NUMBER,
            Locale__c = FAKE_DATA_STRING,
            LoggedByUsername__c = FAKE_DATA_STRING,
            LoggingLevel__c = FAKE_DATA_STRING,
            LoggingLevelOrdinal__c = FAKE_DATA_NUMBER,
            LoginApplication__c = FAKE_DATA_STRING,
            LoginBrowser__c = FAKE_DATA_STRING,
            LoginHistoryId__c = FAKE_DATA_STRING,
            LoginPlatform__c = FAKE_DATA_STRING,
            LoginType__c = FAKE_DATA_STRING,
            LogoutUrl__c =  FAKE_DATA_STRING,
            Message__c = FAKE_DATA_STRING,
            NetworkId__c = FAKE_DATA_STRING,
            NetworkLoginUrl__c = FAKE_DATA_STRING,
            NetworkLogoutUrl__c = FAKE_DATA_STRING,
            NetworkSelfRegistrationUrl__c = FAKE_DATA_STRING,
            NetworkUrlPathPrefix__c = FAKE_DATA_STRING,
            OrganizationDomainUrl__c = FAKE_DATA_STRING,
            OrganizationEnvironmentType__c = FAKE_DATA_STRING,
            OrganizationId__c = FAKE_DATA_STRING,
            OrganizationInstanceName__c = FAKE_DATA_STRING,
            OrganizationName__c = FAKE_DATA_STRING,
            OrganizationNamespacePrefix__c = FAKE_DATA_STRING,
            OrganizationType__c = FAKE_DATA_STRING,
            OriginLocation__c = FAKE_DATA_STRING,
            OriginType__c = FAKE_DATA_STRING,
            ParentLogTransactionId__c = FAKE_DATA_STRING,
            ProfileId__c = FAKE_DATA_STRING,
            ProfileName__c = FAKE_DATA_STRING,
            RecordCollectionType__c = FAKE_DATA_STRING,
            RecordId__c = FAKE_DATA_STRING,
            RecordJson__c = FAKE_DATA_STRING,
            RecordSObjectClassification__c = FAKE_DATA_STRING,
            RecordSObjectType__c = FAKE_DATA_STRING,
            RecordSObjectTypeNamespace__c = FAKE_DATA_STRING,
            SessionId__c = FAKE_DATA_STRING,
            SessionSecurityLevel__c = FAKE_DATA_STRING,
            SessionType__c = FAKE_DATA_STRING,
            SourceIp__c = FAKE_DATA_STRING,
            StackTrace__c = FAKE_DATA_STRING,
            SystemMode__c = FAKE_DATA_STRING,
            ThemeDisplayed__c = FAKE_DATA_STRING,
            Timestamp__c = now,
            TimestampString__c = now.format(),
            TimeZoneId__c = FAKE_DATA_STRING,
            Topics__c = FAKE_DATA_STRING,
            TransactionEntryNumber__c = FAKE_DATA_NUMBER,
            TransactionId__c = FAKE_DATA_STRING,
            TriggerOperationType__c = FAKE_DATA_STRING,
            TriggerSObjectType__c = FAKE_DATA_STRING,
            UserLicenseDefinitionKey__c = FAKE_DATA_STRING,
            UserLicenseName__c = FAKE_DATA_STRING,
            UserLoggingLevel__c = FAKE_DATA_STRING,
            UserLoggingLevelOrdinal__c = FAKE_DATA_NUMBER,
            UserRoleId__c = FAKE_DATA_STRING,
            UserRoleName__c = FAKE_DATA_STRING,
            UserType__c = FAKE_DATA_STRING
        );

        LogEntryArchiveBuilder.mockEvent = mockEvent;

        LogArchive__b logArchive = new LogEntryArchiveBuilder(LoggingLevel.DEBUG, true).getLogEntryArchive();

        System.assertEquals(mockEvent.ApiVersion__c, logArchive.ApiVersion__c);
        System.assertEquals(mockEvent.DatabaseResultCollectionType__c, logArchive.DatabaseResultCollectionType__c);
        System.assertEquals(mockEvent.DatabaseResultJson__c, logArchive.DatabaseResultJson__c);
        System.assertEquals(mockEvent.DatabaseResultType__c, logArchive.DatabaseResultType__c);
        System.assertEquals(mockEvent.ExceptionMessage__c, logArchive.ExceptionMessage__c);
        System.assertEquals(mockEvent.ExceptionStackTrace__c, logArchive.ExceptionStackTrace__c);
        System.assertEquals(mockEvent.ExceptionType__c, logArchive.ExceptionType__c);
        System.assertEquals(mockEvent.LimitsAggregateQueriesMax__c, logArchive.LimitsAggregateQueriesMax__c);
        System.assertEquals(mockEvent.LimitsAggregateQueriesUsed__c, logArchive.LimitsAggregateQueriesUsed__c);
        System.assertEquals(mockEvent.LimitsAsyncCallsMax__c, logArchive.LimitsAsyncCallsMax__c);
        System.assertEquals(mockEvent.LimitsAsyncCallsUsed__c, logArchive.LimitsAsyncCallsUsed__c);
        System.assertEquals(mockEvent.LimitsCalloutsUsed__c, logArchive.LimitsCalloutsUsed__c);
        System.assertEquals(mockEvent.LimitsCpuTimeMax__c, logArchive.LimitsCpuTimeMax__c);
        System.assertEquals(mockEvent.LimitsCpuTimeUsed__c, logArchive.LimitsCpuTimeUsed__c);
        System.assertEquals(mockEvent.LimitsDmlRowsMax__c, logArchive.LimitsDmlRowsMax__c);
        System.assertEquals(mockEvent.LimitsDmlRowsUsed__c, logArchive.LimitsDmlRowsUsed__c);
        System.assertEquals(mockEvent.LimitsDmlStatementsMax__c, logArchive.LimitsDmlStatementsMax__c);
        System.assertEquals(mockEvent.LimitsDmlStatementsUsed__c, logArchive.LimitsDmlStatementsUsed__c);
        System.assertEquals(mockEvent.LimitsEmailInvocationsMax__c, logArchive.LimitsEmailInvocationsMax__c);
        System.assertEquals(mockEvent.LimitsEmailInvocationsUsed__c, logArchive.LimitsEmailInvocationsUsed__c);
        System.assertEquals(mockEvent.LimitsFutureCallsMax__c, logArchive.LimitsFutureCallsMax__c);
        System.assertEquals(mockEvent.LimitsFutureCallsUsed__c, logArchive.LimitsFutureCallsUsed__c);
        System.assertEquals(mockEvent.LimitsHeapSizeMax__c, logArchive.LimitsHeapSizeMax__c);
        System.assertEquals(mockEvent.LimitsHeapSizeUsed__c, logArchive.LimitsHeapSizeUsed__c);
        System.assertEquals(mockEvent.LimitsMobilePushApexCallsMax__c, logArchive.LimitsMobilePushApexCallsMax__c);
        System.assertEquals(mockEvent.LimitsMobilePushApexCallsUsed__c, logArchive.LimitsMobilePushApexCallsUsed__c);
        System.assertEquals(mockEvent.LimitsQueueableJobsMax__c, logArchive.LimitsQueueableJobsMax__c);
        System.assertEquals(mockEvent.LimitsQueueableJobsUsed__c, logArchive.LimitsQueueableJobsUsed__c);
        System.assertEquals(mockEvent.LimitsSoqlQueriesMax__c, logArchive.LimitsSoqlQueriesMax__c);
        System.assertEquals(mockEvent.LimitsSoqlQueriesUsed__c, logArchive.LimitsSoqlQueriesUsed__c);
        System.assertEquals(mockEvent.LimitsSoqlQueryLocatorRowsMax__c, logArchive.LimitsSoqlQueryLocatorRowsMax__c);
        System.assertEquals(mockEvent.LimitsSoqlQueryLocatorRowsUsed__c, logArchive.LimitsSoqlQueryLocatorRowsUsed__c);
        System.assertEquals(mockEvent.LimitsSoqlQueryRowsMax__c, logArchive.LimitsSoqlQueryRowsMax__c);
        System.assertEquals(mockEvent.LimitsSoqlQueryRowsUsed__c, logArchive.LimitsSoqlQueryRowsUsed__c);
        System.assertEquals(mockEvent.LimitsSoslSearchesMax__c, logArchive.LimitsSoslSearchesMax__c);
        System.assertEquals(mockEvent.LimitsSoslSearchesUsed__c, logArchive.LimitsSoslSearchesUsed__c);
        System.assertEquals(mockEvent.Locale__c, logArchive.Locale__c);
        System.assertEquals(UserInfo.getUserId(), logArchive.LoggedBy__c);
        System.assertEquals(UserInfo.getUserId(), logArchive.LoggedByString__c);
        System.assertEquals(mockEvent.LoggedByUsername__c, logArchive.LoggedByUsername__c);
        System.assertEquals(mockEvent.LoggingLevel__c, logArchive.LoggingLevel__c);
        System.assertEquals(mockEvent.LoggingLevelOrdinal__c, logArchive.LoggingLevelOrdinal__c);
        System.assertEquals(mockEvent.LoginApplication__c, logArchive.LoginApplication__c);
        System.assertEquals(mockEvent.LoginBrowser__c, logArchive.LoginBrowser__c);
        System.assertEquals(mockEvent.LoginHistoryId__c, logArchive.LoginHistoryId__c);
        System.assertEquals(mockEvent.LoginPlatform__c, logArchive.LoginPlatform__c);
        System.assertEquals(mockEvent.LoginType__c, logArchive.LoginType__c);
        System.assertEquals(mockEvent.LogoutUrl__c, logArchive.LogoutUrl__c);
        System.assertEquals(mockEvent.Message__c, logArchive.Message__c);
        System.assertEquals(mockEvent.NetworkId__c, logArchive.NetworkId__c);
        System.assertEquals(mockEvent.NetworkLoginUrl__c, logArchive.NetworkLoginUrl__c);
        System.assertEquals(mockEvent.NetworkLogoutUrl__c, logArchive.NetworkLogoutUrl__c);
        System.assertEquals(mockEvent.NetworkSelfRegistrationUrl__c, logArchive.NetworkSelfRegistrationUrl__c);
        System.assertEquals(mockEvent.NetworkUrlPathPrefix__c, logArchive.NetworkUrlPathPrefix__c);
        System.assertEquals(mockEvent.OrganizationDomainUrl__c, logArchive.OrganizationDomainUrl__c);
        System.assertEquals(mockEvent.OrganizationEnvironmentType__c, logArchive.OrganizationEnvironmentType__c);
        System.assertEquals(mockEvent.OrganizationId__c, logArchive.OrganizationId__c);
        System.assertEquals(mockEvent.OrganizationInstanceName__c, logArchive.OrganizationInstanceName__c);
        System.assertEquals(mockEvent.OrganizationName__c, logArchive.OrganizationName__c);
        System.assertEquals(mockEvent.OrganizationNamespacePrefix__c, logArchive.OrganizationNamespacePrefix__c);
        System.assertEquals(mockEvent.OrganizationType__c, logArchive.OrganizationType__c);
        System.assertEquals(mockEvent.OriginLocation__c, logArchive.OriginLocation__c);
        System.assertEquals(mockEvent.OriginType__c, logArchive.OriginType__c);
        System.assertEquals(mockEvent.ParentLogTransactionId__c, logArchive.ParentLogTransactionId__c);
        System.assertEquals(mockEvent.ProfileId__c, logArchive.ProfileId__c);
        System.assertEquals(mockEvent.ProfileName__c, logArchive.ProfileName__c);
        System.assertEquals(mockEvent.RecordCollectionType__c, logArchive.RecordCollectionType__c);
        System.assertEquals(mockEvent.RecordId__c, logArchive.RecordId__c);
        System.assertEquals(mockEvent.RecordJson__c, logArchive.RecordJson__c);
        System.assertEquals(mockEvent.RecordSObjectClassification__c, logArchive.RecordSObjectClassification__c);
        System.assertEquals(mockEvent.RecordSObjectType__c, logArchive.RecordSObjectType__c);
        System.assertEquals(mockEvent.RecordSObjectTypeNamespace__c, logArchive.RecordSObjectTypeNamespace__c);
        System.assertEquals(mockEvent.SessionId__c, logArchive.SessionId__c);
        System.assertEquals(mockEvent.SessionSecurityLevel__c, logArchive.SessionSecurityLevel__c);
        System.assertEquals(mockEvent.SessionType__c, logArchive.SessionType__c);
        System.assertEquals(mockEvent.SourceIp__c, logArchive.SourceIp__c);
        System.assertEquals(mockEvent.StackTrace__c, logArchive.StackTrace__c);
        System.assertEquals(mockEvent.SystemMode__c, logArchive.SystemMode__c);
        System.assertEquals(mockEvent.ThemeDisplayed__c, logArchive.ThemeDisplayed__c);
        System.assertEquals(now, logArchive.Timestamp__c);
        System.assertEquals(now.format(), logArchive.TimestampString__c);
        System.assertEquals(mockEvent.TimeZoneId__c, logArchive.TimeZoneId__c);
        System.assertEquals(mockEvent.Topics__c, logArchive.Topics__c);
        System.assertEquals(mockEvent.TransactionEntryNumber__c, logArchive.TransactionEntryNumber__c);
        System.assertEquals(mockEvent.TransactionId__c, logArchive.TransactionId__c);
        System.assertEquals(mockEvent.TriggerOperationType__c, logArchive.TriggerOperationType__c);
        System.assertEquals(mockEvent.TriggerSObjectType__c, logArchive.TriggerSObjectType__c);
        System.assertEquals(mockEvent.UserLicenseDefinitionKey__c, logArchive.UserLicenseDefinitionKey__c);
        System.assertEquals(mockEvent.UserLicenseName__c, logArchive.UserLicenseName__c);
        System.assertEquals(mockEvent.UserLoggingLevel__c, logArchive.UserLoggingLevel__c);
        System.assertEquals(mockEvent.UserLoggingLevelOrdinal__c, logArchive.UserLoggingLevelOrdinal__c);
        System.assertEquals(mockEvent.UserRoleId__c, logArchive.UserRoleId__c);
        System.assertEquals(mockEvent.UserRoleName__c, logArchive.UserRoleName__c);
        System.assertEquals(mockEvent.UserType__c, logArchive.UserType__c);
    }
}
