public without sharing class LogEntryArchiveBuilder extends LoggerSObjectHandlerPlugin {
    @TestVisible
    private static final String BIG_OBJECT_SAVE_METHOD = 'BIG_OBJECT';
    @TestVisible
    private static List<LogEntryArchive__b> bigObjectsToInsert = new List<LogEntryArchive__b>();

    public override void execute(LoggerPlugin__mdt configuration, LoggerSObjectHandler.SObjectHandlerInput input) {
        if (Logger.getUserSettings().DefaultSaveMethod__c != BIG_OBJECT_SAVE_METHOD) {
            return;
        }

        List<LogEntryEvent__e> logEntryEvents = (List<LogEntryEvent__e>) input.triggerNew;
        for (LogEntryEvent__e logEntryEvent : logEntryEvents) {
            bigObjectsToInsert.add(this.getLogEntryArchive(logEntryEvent));
        }
        if (!Test.isRunningTest()) {
            Database.insertImmediate(bigObjectsToInsert);
            bigObjectsToInsert.clear();
        }
        Logger.flushBuffer();
    }

    public LogEntryArchive__b getLogEntryArchive(LogEntryEvent__e logEntryEvent) {
        return new LogEntryArchive__b(
            ApiVersion__c = logEntryEvent.ApiVersion__c,
            DatabaseResultCollectionType__c = logEntryEvent.DatabaseResultCollectionType__c,
            DatabaseResultJson__c = logEntryEvent.DatabaseResultJson__c,
            DatabaseResultType__c = logEntryEvent.DatabaseResultType__c,
            ExceptionMessage__c = logEntryEvent.ExceptionMessage__c,
            ExceptionStackTrace__c = logEntryEvent.ExceptionStackTrace__c,
            ExceptionType__c = logEntryEvent.ExceptionType__c,
            LimitsAggregateQueriesMax__c = logEntryEvent.LimitsAggregateQueriesMax__c,
            LimitsAggregateQueriesUsed__c = logEntryEvent.LimitsAggregateQueriesUsed__c,
            LimitsAsyncCallsMax__c = logEntryEvent.LimitsAsyncCallsMax__c,
            LimitsAsyncCallsUsed__c = logEntryEvent.LimitsAsyncCallsUsed__c,
            LimitsCalloutsUsed__c = logEntryEvent.LimitsCalloutsUsed__c,
            LimitsCpuTimeMax__c = logEntryEvent.LimitsCpuTimeMax__c,
            LimitsCpuTimeUsed__c = logEntryEvent.LimitsCpuTimeUsed__c,
            LimitsDmlRowsMax__c = logEntryEvent.LimitsDmlRowsMax__c,
            LimitsDmlRowsUsed__c = logEntryEvent.LimitsDmlRowsUsed__c,
            LimitsDmlStatementsMax__c = logEntryEvent.LimitsDmlStatementsMax__c,
            LimitsDmlStatementsUsed__c = logEntryEvent.LimitsDmlStatementsUsed__c,
            LimitsEmailInvocationsMax__c = logEntryEvent.LimitsEmailInvocationsMax__c,
            LimitsEmailInvocationsUsed__c = logEntryEvent.LimitsEmailInvocationsUsed__c,
            LimitsFutureCallsMax__c = logEntryEvent.LimitsFutureCallsMax__c,
            LimitsFutureCallsUsed__c = logEntryEvent.LimitsFutureCallsUsed__c,
            LimitsHeapSizeMax__c = logEntryEvent.LimitsHeapSizeMax__c,
            LimitsHeapSizeUsed__c = logEntryEvent.LimitsHeapSizeUsed__c,
            LimitsMobilePushApexCallsMax__c = logEntryEvent.LimitsMobilePushApexCallsMax__c,
            LimitsMobilePushApexCallsUsed__c = logEntryEvent.LimitsMobilePushApexCallsUsed__c,
            LimitsQueueableJobsMax__c = logEntryEvent.LimitsQueueableJobsMax__c,
            LimitsQueueableJobsUsed__c = logEntryEvent.LimitsQueueableJobsUsed__c,
            LimitsSoqlQueriesMax__c = logEntryEvent.LimitsSoqlQueriesMax__c,
            LimitsSoqlQueriesUsed__c = logEntryEvent.LimitsSoqlQueriesUsed__c,
            LimitsSoqlQueryLocatorRowsMax__c = logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c,
            LimitsSoqlQueryLocatorRowsUsed__c = logEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c,
            LimitsSoqlQueryRowsMax__c = logEntryEvent.LimitsSoqlQueryRowsMax__c,
            LimitsSoqlQueryRowsUsed__c = logEntryEvent.LimitsSoqlQueryRowsUsed__c,
            LimitsSoslSearchesMax__c = logEntryEvent.LimitsSoslSearchesMax__c,
            LimitsSoslSearchesUsed__c = logEntryEvent.LimitsSoslSearchesUsed__c,
            Locale__c = logEntryEvent.Locale__c,
            LoggedBy__c = UserInfo.getUserId(),
            LoggedByString__c = UserInfo.getUserId(),
            LoggedByUsername__c = logEntryEvent.LoggedByUsername__c,
            LoggingLevel__c = logEntryEvent.LoggingLevel__c,
            LoggingLevelOrdinal__c = logEntryEvent.LoggingLevelOrdinal__c,
            LoginApplication__c = logEntryEvent.LoginApplication__c,
            LoginBrowser__c = logEntryEvent.LoginBrowser__c,
            LoginHistoryId__c = logEntryEvent.LoginHistoryId__c,
            LoginPlatform__c = logEntryEvent.LoginPlatform__c,
            LoginType__c = logEntryEvent.LoginType__c,
            LogoutUrl__c = logEntryEvent.LogoutUrl__c,
            Message__c = logEntryEvent.Message__c,
            NetworkId__c = logEntryEvent.NetworkId__c,
            NetworkLoginUrl__c = logEntryEvent.NetworkLoginUrl__c,
            NetworkLogoutUrl__c = logEntryEvent.NetworkLogoutUrl__c,
            NetworkSelfRegistrationUrl__c = logEntryEvent.NetworkSelfRegistrationUrl__c,
            NetworkUrlPathPrefix__c = logEntryEvent.NetworkUrlPathPrefix__c,
            OrganizationDomainUrl__c = logEntryEvent.OrganizationDomainUrl__c,
            OrganizationEnvironmentType__c = logEntryEvent.OrganizationEnvironmentType__c,
            OrganizationId__c = logEntryEvent.OrganizationId__c,
            OrganizationInstanceName__c = logEntryEvent.OrganizationInstanceName__c,
            OrganizationName__c = logEntryEvent.OrganizationName__c,
            OrganizationNamespacePrefix__c = logEntryEvent.OrganizationNamespacePrefix__c,
            OrganizationType__c = logEntryEvent.OrganizationType__c,
            OriginLocation__c = logEntryEvent.OriginLocation__c,
            OriginType__c = logEntryEvent.OriginType__c,
            ParentLogTransactionId__c = logEntryEvent.ParentLogTransactionId__c,
            ProfileId__c = logEntryEvent.ProfileId__c,
            ProfileName__c = logEntryEvent.ProfileName__c,
            RecordCollectionType__c = logEntryEvent.RecordCollectionType__c,
            RecordId__c = logEntryEvent.RecordId__c,
            RecordJson__c = logEntryEvent.RecordJson__c,
            RecordSObjectClassification__c = logEntryEvent.RecordSObjectClassification__c,
            RecordSObjectType__c = logEntryEvent.RecordSObjectType__c,
            RecordSObjectTypeNamespace__c = logEntryEvent.RecordSObjectTypeNamespace__c,
            SessionId__c = logEntryEvent.SessionId__c,
            SessionSecurityLevel__c = logEntryEvent.SessionSecurityLevel__c,
            SessionType__c = logEntryEvent.SessionType__c,
            SourceIp__c = logEntryEvent.SourceIp__c,
            StackTrace__c = logEntryEvent.StackTrace__c,
            SystemMode__c = logEntryEvent.SystemMode__c,
            ThemeDisplayed__c = logEntryEvent.ThemeDisplayed__c,
            Timestamp__c = logEntryEvent.Timestamp__c,
            TimestampString__c = logEntryEvent.TimestampString__c,
            TimeZoneId__c = logEntryEvent.TimeZoneId__c,
            Topics__c = logEntryEvent.Topics__c,
            TransactionEntryNumber__c = logEntryEvent.TransactionEntryNumber__c,
            TransactionId__c = logEntryEvent.TransactionId__c,
            TriggerOperationType__c = logEntryEvent.TriggerOperationType__c,
            TriggerSObjectType__c = logEntryEvent.TriggerSObjectType__c,
            UserLicenseDefinitionKey__c = logEntryEvent.UserLicenseDefinitionKey__c,
            UserLicenseName__c = logEntryEvent.UserLicenseName__c,
            UserLoggingLevel__c = logEntryEvent.UserLoggingLevel__c,
            UserLoggingLevelOrdinal__c = logEntryEvent.UserLoggingLevelOrdinal__c,
            UserRoleId__c = logEntryEvent.UserRoleId__c,
            UserRoleName__c = logEntryEvent.UserRoleName__c,
            UserType__c = logEntryEvent.UserType__c
        );
    }
}
