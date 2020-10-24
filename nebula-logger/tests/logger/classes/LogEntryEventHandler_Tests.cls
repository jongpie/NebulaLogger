/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
@isTest
private class LogEntryEventHandler_Tests {
    static User getCurrentUser() {
        return [
            SELECT
                Id,
                UserRoleId,
                UserRole.Name,
                ProfileId,
                Profile.Name,
                Profile.UserLicenseId,
                Profile.UserLicense.LicenseDefinitionKey,
                Profile.UserLicense.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
    }

    static Log__c getLog() {
        return [
            SELECT
                ApiVersion__c,
                ContextThemeDisplayed__c,
                Id,
                Locale__c,
                LoggedBy__c,
                LoginDomain__c,
                LoginHistoryId__c,
                LoginType__c,
                LogoutUrl__c,
                NetworkId__c,
                OwnerId,
                ParentLog__c,
                ProfileId__c,
                ProfileName__c,
                SessionId__c,
                SessionSecurityLevel__c,
                SessionType__c,
                SourceIp__c,
                SystemMode__c,
                TimeZoneId__c,
                TimeZoneName__c,
                TransactionId__c,
                UserLoggingLevel__c,
                UserLoggingLevelOrdinal__c,
                UserRoleId__c,
                UserRoleName__c,
                UserType__c,
                OrganizationDomainUrl__c,
                OrganizationId__c,
                OrganizationInstanceName__c,
                OrganizationIsSandbox__c,
                OrganizationName__c,
                OrganizationNamespacePrefix__c,
                OrganizationType__c,
                UserLicenseDefinitionKey__c,
                UserLicenseId__c,
                UserLicenseName__c,
                (
                    SELECT
                        ContextIsLightningComponent__c,
                        ContextIsTriggerExecuting__c,
                        ContextIsVisualforce__c,
                        ContextLightningComponentName__c,
                        ContextTriggerOperationType__c,
                        ContextTriggerSObjectType__c,
                        ContextVisualforcePage__c,
                        ExceptionStackTrace__c,
                        ExceptionType__c,
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
                        RecordId__c,
                        RecordJson__c,
                        StackTrace__c,
                        Timestamp__c,
                        Type__c
                    FROM LogEntries__r
                )
            FROM Log__c
        ];
    }

    static void validateLogFields(LogEntryEvent__e logEntryEvent, Log__c log) {
        Organization org = [
            SELECT Id, Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType
            FROM Organization
        ];
        User currentUser = getCurrentUser();

        System.assertEquals(logEntryEvent.ApiVersion__c, log.ApiVersion__c);
        System.assertEquals(logEntryEvent.ContextThemeDisplayed__c, log.ContextThemeDisplayed__c);
        System.assertEquals(logEntryEvent.Locale__c, log.Locale__c);
        System.assertEquals(UserInfo.getUserId(), log.LoggedBy__c);
        System.assertEquals(logEntryEvent.LoginDomain__c, log.LoginDomain__c);
        System.assertEquals(logEntryEvent.LoginHistoryId__c, log.LoginHistoryId__c);
        System.assertEquals(logEntryEvent.LoginType__c, log.LoginType__c);
        System.assertEquals(logEntryEvent.LogoutUrl__c, log.LogoutUrl__c);
        System.assertEquals(logEntryEvent.NetworkId__c, log.NetworkId__c);
        System.assertEquals(UserInfo.getUserId(), log.OwnerId);
        System.assertEquals(logEntryEvent.ProfileId__c, log.ProfileId__c);
        System.assertEquals(logEntryEvent.SessionId__c, log.SessionId__c);
        System.assertEquals(logEntryEvent.SessionId__c, log.SessionId__c);
        System.assertEquals(logEntryEvent.SessionSecurityLevel__c, log.SessionSecurityLevel__c);
        System.assertEquals(logEntryEvent.SessionType__c, log.SessionType__c);
        System.assertEquals(logEntryEvent.SourceIp__c, log.SourceIp__c);
        System.assertEquals(logEntryEvent.SystemMode__c, log.SystemMode__c);
        System.assertEquals(logEntryEvent.TimeZoneId__c, log.TimeZoneId__c);
        System.assertEquals(logEntryEvent.TimeZoneName__c, log.TimeZoneName__c);
        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        System.assertEquals(logEntryEvent.UserLoggingLevel__c, log.UserLoggingLevel__c);
        System.assertEquals(logEntryEvent.UserLoggingLevelOrdinal__c, log.UserLoggingLevelOrdinal__c);
        System.assertEquals(currentUser.UserRoleId, log.UserRoleId__c);
        System.assertEquals(currentUser.UserRoleId == null ? null : currentUser.UserRole.Name, log.UserRoleName__c);
        System.assertEquals(logEntryEvent.UserType__c, log.UserType__c);

        // Org fields
        System.assertEquals(Url.getOrgDomainUrl().toExternalForm(), LOG.OrganizationDomainUrl__c);
        System.assertEquals(org.Id, LOG.OrganizationId__c);
        System.assertEquals(org.InstanceName, LOG.OrganizationInstanceName__c);
        System.assertEquals(org.IsSandbox, LOG.OrganizationIsSandbox__c);
        System.assertEquals(org.Name, LOG.OrganizationName__c);
        System.assertEquals(org.NamespacePrefix, LOG.OrganizationNamespacePrefix__c);
        System.assertEquals(org.OrganizationType, LOG.OrganizationType__c);

        // Profile fields
        System.assertEquals(currentUser.Profile.UserLicense.LicenseDefinitionKey, log.UserLicenseDefinitionKey__c);
        System.assertEquals(currentUser.Profile.UserLicenseId, log.UserLicenseId__c);
        System.assertEquals(currentUser.Profile.UserLicense.Name, log.UserLicenseName__c);
    }

    static void validateLogEntryFields(LogEntryEvent__e logEntryEvent, LogEntry__c logEntry) {
        System.assertEquals(logEntryEvent.ContextIsLightningComponent__c, logEntry.ContextIsLightningComponent__c);
        System.assertEquals(logEntryEvent.ContextIsTriggerExecuting__c, logEntry.ContextIsTriggerExecuting__c);
        System.assertEquals(logEntryEvent.ContextIsVisualforce__c, logEntry.ContextIsVisualforce__c);
        System.assertEquals(logEntryEvent.ContextLightningComponentName__c, logEntry.ContextLightningComponentName__c);
        System.assertEquals(logEntryEvent.ContextTriggerOperationType__c, logEntry.ContextTriggerOperationType__c);
        System.assertEquals(logEntryEvent.ContextTriggerSObjectType__c, logEntry.ContextTriggerSObjectType__c);
        System.assertEquals(logEntryEvent.ContextVisualforcePage__c, logEntry.ContextVisualforcePage__c);
        System.assertEquals(logEntryEvent.ExceptionStackTrace__c, logEntry.ExceptionStackTrace__c);
        System.assertEquals(logEntryEvent.ExceptionType__c, logEntry.ExceptionType__c);
        System.assertEquals(logEntryEvent.LimitsAggregateQueriesMax__c, logEntry.LimitsAggregateQueriesMax__c);
        System.assertEquals(logEntryEvent.LimitsAggregateQueriesUsed__c, logEntry.LimitsAggregateQueriesUsed__c);
        System.assertEquals(logEntryEvent.LimitsAsyncCallsMax__c, logEntry.LimitsAsyncCallsMax__c);
        System.assertEquals(logEntryEvent.LimitsAsyncCallsUsed__c, logEntry.LimitsAsyncCallsUsed__c);
        System.assertEquals(logEntryEvent.LimitsCalloutsMax__c, logEntry.LimitsCalloutsMax__c);
        System.assertEquals(logEntryEvent.LimitsCalloutsUsed__c, logEntry.LimitsCalloutsUsed__c);
        System.assertEquals(logEntryEvent.LimitsCpuTimeMax__c, logEntry.LimitsCpuTimeMax__c);
        System.assertEquals(logEntryEvent.LimitsCpuTimeUsed__c, logEntry.LimitsCpuTimeUsed__c);
        System.assertEquals(logEntryEvent.LimitsDmlRowsMax__c, logEntry.LimitsDmlRowsMax__c);
        System.assertEquals(logEntryEvent.LimitsDmlRowsUsed__c, logEntry.LimitsDmlRowsUsed__c);
        System.assertEquals(logEntryEvent.LimitsDmlStatementsMax__c, logEntry.LimitsDmlStatementsMax__c);
        System.assertEquals(logEntryEvent.LimitsDmlStatementsUsed__c, logEntry.LimitsDmlStatementsUsed__c);
        System.assertEquals(logEntryEvent.LimitsEmailInvocationsMax__c, logEntry.LimitsEmailInvocationsMax__c);
        System.assertEquals(logEntryEvent.LimitsEmailInvocationsUsed__c, logEntry.LimitsEmailInvocationsUsed__c);
        System.assertEquals(logEntryEvent.LimitsFutureCallsMax__c, logEntry.LimitsFutureCallsMax__c);
        System.assertEquals(logEntryEvent.LimitsFutureCallsUsed__c, logEntry.LimitsFutureCallsUsed__c);
        System.assertEquals(logEntryEvent.LimitsHeapSizeMax__c, logEntry.LimitsHeapSizeMax__c);
        System.assertEquals(logEntryEvent.LimitsHeapSizeUsed__c, logEntry.LimitsHeapSizeUsed__c);
        System.assertEquals(logEntryEvent.LimitsMobilePushApexCallsMax__c, logEntry.LimitsMobilePushApexCallsMax__c);
        System.assertEquals(logEntryEvent.LimitsMobilePushApexCallsUsed__c, logEntry.LimitsMobilePushApexCallsUsed__c);
        System.assertEquals(logEntryEvent.LimitsQueueableJobsMax__c, logEntry.LimitsQueueableJobsMax__c);
        System.assertEquals(logEntryEvent.LimitsQueueableJobsUsed__c, logEntry.LimitsQueueableJobsUsed__c);
        System.assertEquals(logEntryEvent.LimitsSoqlQueriesMax__c, logEntry.LimitsSoqlQueriesMax__c);
        System.assertEquals(logEntryEvent.LimitsSoqlQueriesUsed__c, logEntry.LimitsSoqlQueriesUsed__c);
        System.assertEquals(logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c, logEntry.LimitsSoqlQueryLocatorRowsMax__c);
        System.assertEquals(
            logEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c,
            logEntry.LimitsSoqlQueryLocatorRowsUsed__c
        );
        System.assertEquals(logEntryEvent.LimitsSoqlQueryRowsMax__c, logEntry.LimitsSoqlQueryRowsMax__c);
        System.assertEquals(logEntryEvent.LimitsSoqlQueryRowsUsed__c, logEntry.LimitsSoqlQueryRowsUsed__c);
        System.assertEquals(logEntryEvent.LimitsSoslSearchesUsed__c, logEntry.LimitsSoslSearchesUsed__c);
        System.assertEquals(logEntryEvent.LimitsSoslSearchesMax__c, logEntry.LimitsSoslSearchesMax__c);
        System.assertEquals(logEntryEvent.LoggingLevel__c, logEntry.LoggingLevel__c);
        System.assertEquals(logEntryEvent.LoggingLevelOrdinal__c, logEntry.LoggingLevelOrdinal__c);
        System.assertEquals(logEntryEvent.Message__c, logEntry.Message__c);
        System.assertEquals(logEntryEvent.MessageTruncated__c, logEntry.MessageTruncated__c);
        System.assertEquals(logEntry.Id, logEntry.Name);
        System.assertEquals(logEntryEvent.OriginType__c, logEntry.OriginType__c);
        System.assertEquals(logEntryEvent.OriginLocation__c, logEntry.OriginLocation__c);
        System.assertEquals(logEntryEvent.RecordId__c, logEntry.RecordId__c);
        System.assertEquals(logEntryEvent.RecordJson__c, logEntry.RecordJson__c);
        System.assertEquals(logEntryEvent.StackTrace__c, logEntry.StackTrace__c);
        System.assertEquals(logEntryEvent.Timestamp__c, logEntry.Timestamp__c);
        System.assertEquals(logEntryEvent.Type__c, logEntry.Type__c);
    }

    @isTest
    static void it_should_normalize_simple_event_data_into_log_and_log_entry() {
        String transactionId = '123-456-789-0';

        LogEntryEvent__e logEntryEvent = new LogEntryEvent__e(
            Message__c = 'my message',
            Timestamp__c = System.now(),
            TransactionId__c = transactionId
        );

        Test.startTest();
        Database.SaveResult saveResult = EventBus.publish(logEntryEvent);
        Test.stopTest();

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());

        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);

        System.assertEquals(logEntryEvent.TransactionId__c, log.TransactionId__c);
        validateLogEntryFields(logEntryEvent, logEntry);
    }

    @isTest
    static void it_should_normalize_complex_event_data_into_log_and_log_entry() {
        String transactionId = '123-456-789-0';
        User currentUser = getCurrentUser();
        DmlException dmlException = new DmlException();

        LogEntryEvent__e logEntryEvent = new LogEntryEvent__e(
            ApiVersion__c = '99.0',
            ContextIsLightningComponent__c = false,
            ContextIsTriggerExecuting__c = false,
            ContextIsVisualforce__c = false,
            ContextLightningComponentName__c = 'myComponent',
            ContextThemeDisplayed__c = 'SomeTheme',
            ContextTriggerOperationType__c = 'SomeOperation',
            ContextTriggerSObjectType__c = 'Account',
            ContextVisualforcePage__c = 'MyPage',
            ExceptionStackTrace__c = dmlException.getStackTraceString(),
            ExceptionType__c = dmlException.getTypeName(),
            LimitsAggregateQueriesMax__c = 987,
            LimitsAggregateQueriesUsed__c = 123,
            LimitsAsyncCallsMax__c = 987,
            LimitsAsyncCallsUsed__c = 123,
            LimitsCalloutsMax__c = 987,
            LimitsCalloutsUsed__c = 123,
            LimitsCpuTimeMax__c = 987,
            LimitsCpuTimeUsed__c = 123,
            LimitsDmlRowsMax__c = 987,
            LimitsDmlRowsUsed__c = 123,
            LimitsDmlStatementsMax__c = 987,
            LimitsDmlStatementsUsed__c = 123,
            LimitsEmailInvocationsMax__c = 987,
            LimitsEmailInvocationsUsed__c = 123,
            LimitsFutureCallsMax__c = 987,
            LimitsFutureCallsUsed__c = 123,
            LimitsHeapSizeMax__c = 987,
            LimitsHeapSizeUsed__c = 123,
            LimitsMobilePushApexCallsMax__c = 987,
            LimitsMobilePushApexCallsUsed__c = 123,
            LimitsQueueableJobsMax__c = 987,
            LimitsQueueableJobsUsed__c = 123,
            LimitsSoqlQueriesMax__c = 987,
            LimitsSoqlQueriesUsed__c = 123,
            LimitsSoqlQueryLocatorRowsMax__c = 987,
            LimitsSoqlQueryLocatorRowsUsed__c = 123,
            LimitsSoqlQueryRowsMax__c = 987,
            LimitsSoqlQueryRowsUsed__c = 123,
            LimitsSoslSearchesMax__c = 987,
            LimitsSoslSearchesUsed__c = 123,
            Locale__c = 'es-ES',
            LoggingLevel__c = 'DEBUG',
            LoggingLevelOrdinal__c = 9,
            LoginDomain__c = 'https://fake.my.salesforce.com',
            LoginHistoryId__c = '255.255.255.255',
            LoginType__c = null,
            LogoutUrl__c = null,
            Message__c = 'My message',
            MessageTruncated__c = false,
            NetworkId__c = 'Fake-ID',
            OriginLocation__c = 'right here',
            OriginType__c = 'Apex',
            ProfileId__c = currentUser.ProfileId,
            RecordId__c = currentUser.Id,
            RecordJson__c = Json.serializePretty(currentUser),
            SessionId__c = null,
            SessionSecurityLevel__c = null,
            SessionType__c = null,
            SourceIp__c = null,
            StackTrace__c = 'I started here \nand then went there',
            SystemMode__c = System.Quiddity.SYNCHRONOUS.name(),
            Timestamp__c = System.now(),
            TimeZoneId__c = 'fake-id',
            TimeZoneName__c = 'My time zone name',
            TransactionId__c = transactionId,
            Type__c = 'Diagnostic',
            UserLoggingLevel__c = 'DEBUG',
            UserLoggingLevelOrdinal__c = 9,
            UserRoleId__c = currentUser.UserRoleId,
            UserType__c = null
        );

        Test.startTest();
        Database.SaveResult saveResult = EventBus.publish(logEntryEvent);
        Test.stopTest();

        System.assertEquals(true, saveResult.isSuccess(), saveResult.getErrors());

        Log__c log = getLog();
        System.assertEquals(1, log.LogEntries__r.size());
        LogEntry__c logEntry = log.LogEntries__r.get(0);

        validateLogFields(logEntryEvent, log);
        validateLogEntryFields(logEntryEvent, logEntry);
    }
}
