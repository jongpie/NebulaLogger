//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest
private class LogEntryArchiveBuilder_Tests {
    private static final String FAKE_DATA_STRING = 'someFakeData';
    private static final Integer FAKE_DATA_NUMBER = 1;

    @IsTest
    static void it_should_write_all_fields_over_from_log_entry_event() {
        Datetime timestamp = System.now();
        LogEntryEvent__e mockEvent = getMockEvent(timestamp);

        LoggerPlugin__mdt pluginConfiguration = getPluginConfiguration();
        LoggerSObjectHandler.SObjectHandlerInput pluginInput = new LoggerSObjectHandler.SObjectHandlerInput();
        pluginInput.triggerNew = new List<LogEntryEvent__e>{ mockEvent };
        Logger.getUserSettings().DefaultSaveMethod__c = LogEntryArchiveBuilder.BIG_OBJECT_SAVE_METHOD;

        new LogEntryArchiveBuilder().execute(pluginConfiguration, pluginInput);

        List<LogEntryArchive__b> insertedBigObjects = LogEntryArchiveBuilder.bigObjectsToInsert;
        System.assertEquals(1, insertedBigObjects.size(), 'Should have been put into big object buffer');
        assertAllFieldsMatch(timestamp, mockEvent, insertedBigObjects[0]);
    }

    @IsTest
    static void it_should_not_create_big_object_with_other_save_methods() {
        Datetime timestamp = System.now();
        LogEntryEvent__e mockEvent = getMockEvent(timestamp);

        LoggerPlugin__mdt pluginConfiguration = getPluginConfiguration();
        LoggerSObjectHandler.SObjectHandlerInput pluginInput = new LoggerSObjectHandler.SObjectHandlerInput();
        pluginInput.triggerNew = new List<LogEntryEvent__e>{ mockEvent };
        Logger.getUserSettings().DefaultSaveMethod__c = Logger.SaveMethod.EVENT_BUS.name();

        new LogEntryArchiveBuilder().execute(pluginConfiguration, pluginInput);

        System.assertEquals(0, LogEntryArchiveBuilder.bigObjectsToInsert.size(), 'Should not have tried to create big object');
    }

    @IsTest
    static void it_integrates_with_logger() {
        Test.startTest();
        getPluginConfiguration();
        Logger.getUserSettings().DefaultSaveMethod__c = LogEntryArchiveBuilder.BIG_OBJECT_SAVE_METHOD;
        LogEntryEvent__e createdEvent = Logger.info('Testing big object creation').getLogEntryEvent();
        Logger.saveLog();
        System.assertEquals(
            0,
            Limits.getPublishImmediateDML(),
            'Should not have actually used the event bus in tests because big objects actually get inserted, yikes'
        );
        Test.stopTest();

        List<LogEntryArchive__b> insertedBigObjects = LogEntryArchiveBuilder.bigObjectsToInsert;
        System.assertEquals(1, insertedBigObjects.size(), 'Should have been put into big object buffer');
        assertAllFieldsMatch(createdEvent.Timestamp__c, createdEvent, insertedBigObjects[0]);
    }

    private static LogEntryEvent__e getMockEvent(Datetime timestamp) {
        return new LogEntryEvent__e(
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
            LogoutUrl__c = FAKE_DATA_STRING,
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
            Tags__c = FAKE_DATA_STRING,
            ThemeDisplayed__c = FAKE_DATA_STRING,
            Timestamp__c = timestamp,
            TimestampString__c = String.valueOf(timestamp.getTime()),
            TimeZoneId__c = FAKE_DATA_STRING,
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
    }

    private static LoggerPlugin__mdt getPluginConfiguration() {
        LoggerPlugin__mdt config = new LoggerPlugin__mdt(
            IsEnabled__c = true,
            IsLogEntryEventEnabled__c = true,
            PluginApiName__c = LogEntryArchiveBuilder.class.getName(),
            PluginType__c = 'SObject Handler - Apex'
        );
        LoggerSObjectHandler.setMockPlugin(Schema.LogEntryEvent__e.SObjectType, config);
        return config;
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
