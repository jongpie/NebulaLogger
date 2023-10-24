//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings(
    'PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount'
)
@IsTest(IsParallel=false)
private class LogEntryEventBuilder_Tests {
    @IsTest
    static void it_should_short_circuit_when_disabled() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.DEBUG, false, new Set<String>());

        // Run all public and global methods to make sure no errors occur when not enabled (it's happened before)
        System.Assert.isNull(builder.setMessage(getLogMessage()).getLogEntryEvent());
        System.Assert.isNull(builder.setMessage(getMessage()).getLogEntryEvent());
        System.Assert.isNull(builder.setExceptionDetails(new System.DmlException()).getLogEntryEvent());
        System.Assert.isNull(builder.setDatabaseResult((Database.DeleteResult) null).getLogEntryEvent());
        System.Assert.isNull(builder.setDatabaseResult((Database.MergeResult) null).getLogEntryEvent());
        System.Assert.isNull(builder.setDatabaseResult((Database.SaveResult) null).getLogEntryEvent());
        System.Assert.isNull(builder.setDatabaseResult((Database.UpsertResult) null).getLogEntryEvent());
        System.Assert.isNull(builder.setDatabaseResult((Database.UndeleteResult) null).getLogEntryEvent());
        System.Assert.isNull(builder.setDatabaseResult(new List<Database.DeleteResult>()).getLogEntryEvent());
        System.Assert.isNull(builder.setDatabaseResult(new List<Database.MergeResult>()).getLogEntryEvent());
        System.Assert.isNull(builder.setDatabaseResult(new List<Database.SaveResult>()).getLogEntryEvent());
        System.Assert.isNull(builder.setDatabaseResult(new List<Database.UpsertResult>()).getLogEntryEvent());
        System.Assert.isNull(builder.setDatabaseResult(new List<Database.UndeleteResult>()).getLogEntryEvent());
        System.Assert.isNull(builder.setRecordId(System.UserInfo.getUserId()).getLogEntryEvent());
        System.Assert.isNull(builder.setRecordId(new User(Id = System.UserInfo.getUserId())).getLogEntryEvent());
        System.Assert.isNull(builder.setRecord(System.UserInfo.getUserId()).getLogEntryEvent());
        System.Assert.isNull(builder.setRecord(new User(Id = System.UserInfo.getUserId())).getLogEntryEvent());
        System.Assert.isNull(builder.setRecord(new List<User>{ new User(Id = System.UserInfo.getUserId()) }).getLogEntryEvent());
        System.Assert.isNull(builder.addTags(new List<String>{ 'tag-1', 'tag-2' }).getLogEntryEvent());
        System.Assert.isNull(builder.parseStackTrace(new System.DmlException().getStackTraceString()).getLogEntryEvent());
    }

    @IsTest
    static void it_should_short_circuit_when_enabled_logging_level_above_called_level() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.FINE, false, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent());
    }

    @IsTest
    static void it_should_not_short_circuit_when_enabled() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.FINE, true, new Set<String>());
        System.Assert.isNotNull(builder.getLogEntryEvent());
    }

    @IsTest
    static void it_should_not_run_queries_when_logging_is_disabled_via_logger_settings() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryAuthSessionDataSynchronously', Value__c = String.valueOf(true)));
        System.Assert.isTrue(LoggerParameter.QUERY_AUTH_SESSION_DATA_SYNCHRONOUSLY);
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryNetworkDataSynchronously', Value__c = String.valueOf(true)));
        System.Assert.isTrue(LoggerParameter.QUERY_NETWORK_DATA_SYNCHRONOUSLY);
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryOrganizationDataSynchronously', Value__c = String.valueOf(true)));
        System.Assert.isTrue(LoggerParameter.QUERY_ORGANIZATION_DATA_SYNCHRONOUSLY);
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryUserDataSynchronously', Value__c = String.valueOf(true)));
        System.Assert.isTrue(LoggerParameter.QUERY_USER_DATA_SYNCHRONOUSLY);
        LoggerSettings__c userSettings = getUserSettings();
        userSettings.IsEnabled__c = false;
        System.Assert.areEqual(0, System.Limits.getQueries());

        new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, userSettings.IsEnabled__c, new Set<String>())
            .setMessage('some message')
            .getLogEntryEvent();

        System.Assert.areEqual(0, System.Limits.getQueries());
    }

    @IsTest
    static void it_should_not_run_authSession_query_when_disabled_via_logger_parameter() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryAuthSessionDataSynchronously', Value__c = String.valueOf(false)));
        System.Assert.isFalse(LoggerParameter.QUERY_AUTH_SESSION_DATA_SYNCHRONOUSLY);
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        LoggerEngineDataSelector.setMock(mockSelector);
        System.Assert.areEqual(0, mockSelector.getCachedAuthSessionQueryCount());

        LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>())
            .setMessage('some message')
            .getLogEntryEvent();

        System.Assert.areEqual(0, mockSelector.getCachedAuthSessionQueryCount());
        System.Assert.isNull(logEntryEvent.LoginApplication__c);
        System.Assert.isNull(logEntryEvent.LoginBrowser__c);
        System.Assert.isNull(logEntryEvent.LoginHistoryId__c);
        System.Assert.isNull(logEntryEvent.LoginPlatform__c);
        System.Assert.isNull(logEntryEvent.LoginType__c);
        System.Assert.isNull(logEntryEvent.LogoutUrl__c);
        System.Assert.isNull(logEntryEvent.SessionId__c);
        System.Assert.isNull(logEntryEvent.SessionSecurityLevel__c);
        System.Assert.isNull(logEntryEvent.SessionType__c);
        System.Assert.isNull(logEntryEvent.SourceIp__c);
    }

    @IsTest
    static void it_should_run_authSession_query_when_enabled_via_logger_parameter() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryAuthSessionDataSynchronously', Value__c = String.valueOf(true)));
        System.Assert.isTrue(LoggerParameter.QUERY_AUTH_SESSION_DATA_SYNCHRONOUSLY);
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        LoggerEngineDataSelector.setMock(mockSelector);
        System.Assert.areEqual(0, mockSelector.getCachedAuthSessionQueryCount());

        LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>())
            .setMessage('some message')
            .getLogEntryEvent();

        System.Assert.areEqual(1, mockSelector.getCachedAuthSessionQueryCount());
        LoggerSObjectProxy.AuthSession cachedAuthSession = LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();
        System.Assert.areEqual(cachedAuthSession?.LoginHistory.Application, logEntryEvent.LoginApplication__c);
        System.Assert.areEqual(cachedAuthSession?.LoginHistory.Browser, logEntryEvent.LoginBrowser__c);
        System.Assert.areEqual(cachedAuthSession?.LoginHistoryId, logEntryEvent.LoginHistoryId__c);
        System.Assert.areEqual(cachedAuthSession?.LoginHistory.Platform, logEntryEvent.LoginPlatform__c);
        System.Assert.areEqual(cachedAuthSession?.LoginType, logEntryEvent.LoginType__c);
        System.Assert.areEqual(cachedAuthSession?.LogoutUrl, logEntryEvent.LogoutUrl__c);
        System.Assert.areEqual(cachedAuthSession?.Id, logEntryEvent.SessionId__c);
        System.Assert.areEqual(cachedAuthSession?.SessionSecurityLevel, logEntryEvent.SessionSecurityLevel__c);
        System.Assert.areEqual(cachedAuthSession?.SessionType, logEntryEvent.SessionType__c);
        System.Assert.areEqual(cachedAuthSession?.SourceIp, logEntryEvent.SourceIp__c);
    }

    @IsTest
    static void it_should_not_run_organization_query_when_disabled_via_logger_parameter() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryOrganizationDataSynchronously', Value__c = String.valueOf(false)));
        System.Assert.isFalse(LoggerParameter.QUERY_ORGANIZATION_DATA_SYNCHRONOUSLY);
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        LoggerEngineDataSelector.setMock(mockSelector);
        System.Assert.areEqual(0, mockSelector.getCachedOrganizationQueryCount());

        LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>())
            .setMessage('some message')
            .getLogEntryEvent();

        System.Assert.areEqual(0, mockSelector.getCachedOrganizationQueryCount());
        System.Assert.isNull(logEntryEvent.OrganizationId__c);
        System.Assert.isNull(logEntryEvent.OrganizationInstanceName__c);
        System.Assert.isNull(logEntryEvent.OrganizationName__c);
        System.Assert.isNull(logEntryEvent.OrganizationNamespacePrefix__c);
        System.Assert.isNull(logEntryEvent.OrganizationType__c);
    }

    @IsTest
    static void it_should_run_organization_query_when_enabled_via_logger_parameter() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryOrganizationDataSynchronously', Value__c = String.valueOf(true)));
        System.Assert.isTrue(LoggerParameter.QUERY_ORGANIZATION_DATA_SYNCHRONOUSLY);
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        LoggerEngineDataSelector.setMock(mockSelector);
        System.Assert.areEqual(0, mockSelector.getCachedOrganizationQueryCount());

        LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>())
            .setMessage('some message')
            .getLogEntryEvent();

        System.Assert.areNotEqual(0, mockSelector.getCachedOrganizationQueryCount());
        Organization cachedOrganization = LoggerEngineDataSelector.getInstance().getCachedOrganization();
        System.Assert.areEqual(cachedOrganization.Id, logEntryEvent.OrganizationId__c);
        System.Assert.areEqual(cachedOrganization.InstanceName, logEntryEvent.OrganizationInstanceName__c);
        System.Assert.areEqual(cachedOrganization.Name, logEntryEvent.OrganizationName__c);
        System.Assert.areEqual(cachedOrganization.NamespacePrefix, logEntryEvent.OrganizationNamespacePrefix__c);
        System.Assert.areEqual(cachedOrganization.OrganizationType, logEntryEvent.OrganizationType__c);
    }

    @IsTest
    static void it_should_not_run_user_query_when_disabled_via_logger_parameter() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryUserDataSynchronously', Value__c = String.valueOf(false)));
        System.Assert.isFalse(LoggerParameter.QUERY_USER_DATA_SYNCHRONOUSLY);
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        LoggerEngineDataSelector.setMock(mockSelector);
        System.Assert.areEqual(0, mockSelector.getCachedUserQueryCount());

        LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>())
            .setMessage('some message')
            .getLogEntryEvent();

        System.Assert.areEqual(0, mockSelector.getCachedUserQueryCount());
        System.Assert.isNull(logEntryEvent.LoggedByUsername__c);
        System.Assert.isNull(logEntryEvent.ProfileName__c);
        System.Assert.isNull(logEntryEvent.UserLicenseDefinitionKey__c);
        System.Assert.isNull(logEntryEvent.UserLicenseId__c);
        System.Assert.isNull(logEntryEvent.UserLicenseName__c);
        System.Assert.isNull(logEntryEvent.UserRoleName__c);
    }

    @IsTest
    static void it_should_run_user_query_when_enabled_via_logger_parameter() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryUserDataSynchronously', Value__c = String.valueOf(true)));
        System.Assert.isTrue(LoggerParameter.QUERY_USER_DATA_SYNCHRONOUSLY);
        MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
        LoggerEngineDataSelector.setMock(mockSelector);
        System.Assert.areEqual(0, mockSelector.getCachedUserQueryCount());

        LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>())
            .setMessage('some message')
            .getLogEntryEvent();

        System.Assert.areNotEqual(0, mockSelector.getCachedUserQueryCount());
        User cachedUser = LoggerEngineDataSelector.getInstance().getCachedUser();
        System.Assert.areEqual(cachedUser.Username, logEntryEvent.LoggedByUsername__c);
        System.Assert.areEqual(cachedUser.Profile.Name, logEntryEvent.ProfileName__c);
        System.Assert.areEqual(cachedUser.Profile.UserLicense.LicenseDefinitionKey, logEntryEvent.UserLicenseDefinitionKey__c);
        System.Assert.areEqual(cachedUser.Profile.UserLicenseId, logEntryEvent.UserLicenseId__c);
        System.Assert.areEqual(cachedUser.Profile.UserLicense.Name, logEntryEvent.UserLicenseName__c);
        System.Assert.areEqual(cachedUser.UserRole?.Name, logEntryEvent.UserRoleName__c);
    }

    @IsTest
    static void it_should_keep_timestamp_string_in_sync_with_timestamp() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>())
            .setMessage('some message');

        for (Integer i = 0; i < 5; i++) {
            builder.getLogEntryEvent().Timestamp__c = builder.getLogEntryEvent().Timestamp__c.addSeconds(i);

            System.Assert.areEqual(
                String.valueOf(builder.getLogEntryEvent().Timestamp__c.getTime()),
                builder.getLogEntryEvent().TimestampString__c,
                'Timestamp string was inaccurate when i ==' + i
            );
        }
    }

    @IsTest
    static void it_should_set_message_fields_for_logMessage() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isFalse(builder.getLogEntryEvent().MessageTruncated__c);
        System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c);
        System.Assert.isNull(builder.getLogEntryEvent().Message__c);

        LogMessage logMessage = new LogMessage('The time is {0}', System.now());
        builder.setMessage(logMessage);

        System.Assert.isFalse(builder.getLogEntryEvent().MessageTruncated__c);
        System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c);
        System.Assert.areEqual(logMessage.getMessage(), builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_set_message_fields_for_null_logMessage() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isFalse(builder.getLogEntryEvent().MessageTruncated__c);
        System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c);
        System.Assert.isNull(builder.getLogEntryEvent().Message__c);

        LogMessage logMessage = null;
        builder.setMessage(logMessage);

        System.Assert.isFalse(builder.getLogEntryEvent().MessageTruncated__c);
        System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c);
        System.Assert.isNull(builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_set_message_fields_for_string() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isFalse(builder.getLogEntryEvent().MessageTruncated__c);
        System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c);
        System.Assert.isNull(builder.getLogEntryEvent().Message__c);

        String message = 'The time is ' + String.valueOf(System.now());
        builder.setMessage(message);

        System.Assert.isFalse(builder.getLogEntryEvent().MessageTruncated__c);
        System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c);
        System.Assert.areEqual(message, builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_set_message_fields_for_null_string() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isFalse(builder.getLogEntryEvent().MessageTruncated__c);
        System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c);
        System.Assert.isNull(builder.getLogEntryEvent().Message__c);

        String message = null;
        builder.setMessage(message);

        System.Assert.isFalse(builder.getLogEntryEvent().MessageTruncated__c);
        System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c);
        System.Assert.areEqual(message, builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_not_apply_data_mask_rule_when_rule_disabled() {
        LoggerSettings__c userSettings = getUserSettings();
        userSettings.IsDataMaskingEnabled__c = true;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = false;
        LogEntryEventBuilder.setMockDataMaskRule(rule);
        String message = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        Account account = new Account(Name = message);
        String accountJson = JSON.serializePretty(account);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true, new Set<String>());
        builder.setMessage(message).setRecord(account);

        System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c, builder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(message, builder.getLogEntryEvent().Message__c);
        System.Assert.isFalse(builder.getLogEntryEvent().RecordJsonMasked__c);
        System.Assert.areEqual(accountJson, builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_not_apply_data_mask_rule_when_disabled_for_user() {
        LoggerSettings__c userSettings = getUserSettings();
        userSettings.IsDataMaskingEnabled__c = false;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = true;
        LogEntryEventBuilder.setMockDataMaskRule(rule);
        String message = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        Account account = new Account(Name = message);
        String accountJson = JSON.serializePretty(account);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true, new Set<String>());
        builder.setMessage(message).setRecord(account);

        System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c);
        System.Assert.areEqual(message, builder.getLogEntryEvent().Message__c);
        System.Assert.isFalse(builder.getLogEntryEvent().RecordJsonMasked__c);
        System.Assert.areEqual(accountJson, builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_apply_data_mask_rule_to_message_when_enabled() {
        LoggerSettings__c userSettings = getUserSettings();
        userSettings.IsDataMaskingEnabled__c = true;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = true;
        LogEntryEventBuilder.setMockDataMaskRule(rule);
        String sensitiveString = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        String expectedSanitizedString = 'Something, something, and my social is XXX-XX-9999 in case you want to steal my identity';

        LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true, new Set<String>());
        builder.setMessage(sensitiveString);

        System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
        System.Assert.areNotEqual(sensitiveString, builder.getLogEntryEvent().Message__c);
        System.Assert.areEqual(expectedSanitizedString, builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_apply_data_mask_rule_to_record_json_when_enabled() {
        LoggerSettings__c userSettings = getUserSettings();
        userSettings.IsDataMaskingEnabled__c = true;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = true;
        LogEntryEventBuilder.setMockDataMaskRule(rule);
        String sensitiveString = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        String expectedSanitizedString = 'Something, something, and my social is XXX-XX-9999 in case you want to steal my identity';
        Account account = new Account(Name = sensitiveString);
        String accountJson = JSON.serializePretty(account);
        String expectedSanitizedAccountJson = JSON.serializePretty(new Account(Name = expectedSanitizedString));

        LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true, new Set<String>());
        builder.setRecord(account);

        System.Assert.isTrue(builder.getLogEntryEvent().RecordJsonMasked__c);
        System.Assert.areNotEqual(accountJson, builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(expectedSanitizedAccountJson, builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_apply_data_mask_rule_to_record_list_json_when_enabled() {
        LoggerSettings__c userSettings = getUserSettings();
        userSettings.IsDataMaskingEnabled__c = true;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = true;
        LogEntryEventBuilder.setMockDataMaskRule(rule);

        String sensitiveString = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        String expectedSanitizedString = 'Something, something, and my social is XXX-XX-9999 in case you want to steal my identity';
        List<Account> accounts = new List<Account>{ new Account(Name = sensitiveString) };
        String accountListJson = JSON.serializePretty(accounts);
        String expectedSanitizedAccountListJson = JSON.serializePretty(new List<Account>{ new Account(Name = expectedSanitizedString) });
        LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true, new Set<String>());
        builder.setRecord(accounts);

        System.Assert.isTrue(builder.getLogEntryEvent().RecordJsonMasked__c);
        System.Assert.areNotEqual(accountListJson, builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual(expectedSanitizedAccountListJson, builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_apply_data_mask_rule_to_http_request_body_when_enabled() {
        LoggerSettings__c userSettings = getUserSettings();
        userSettings.IsDataMaskingEnabled__c = true;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = true;
        LogEntryEventBuilder.setMockDataMaskRule(rule);
        String sensitiveString = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        String expectedSanitizedString = 'Something, something, and my social is XXX-XX-9999 in case you want to steal my identity';
        System.HttpRequest httpRequest = LoggerMockDataCreator.createHttpRequest();
        httpRequest.setBody(sensitiveString);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true, new Set<String>());
        builder.setHttpRequestDetails(httpRequest);

        System.Assert.isTrue(builder.getLogEntryEvent().HttpRequestBodyMasked__c);
        System.Assert.areNotEqual(sensitiveString, builder.getLogEntryEvent().HttpRequestBody__c);
        System.Assert.areEqual(expectedSanitizedString, builder.getLogEntryEvent().HttpRequestBody__c);
    }

    @IsTest
    static void it_should_apply_data_mask_rule_to_http_response_body_when_enabled() {
        LoggerSettings__c userSettings = getUserSettings();
        userSettings.IsDataMaskingEnabled__c = true;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = true;
        LogEntryEventBuilder.setMockDataMaskRule(rule);
        String sensitiveString = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        String expectedSanitizedString = 'Something, something, and my social is XXX-XX-9999 in case you want to steal my identity';
        System.HttpResponse httpResponse = LoggerMockDataCreator.createHttpResponse();
        httpResponse.setBody(sensitiveString);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true, new Set<String>());
        builder.setHttpResponseDetails(httpResponse);

        System.Assert.isTrue(builder.getLogEntryEvent().HttpResponseBodyMasked__c);
        System.Assert.areNotEqual(sensitiveString, builder.getLogEntryEvent().HttpResponseBody__c);
        System.Assert.areEqual(expectedSanitizedString, builder.getLogEntryEvent().HttpResponseBody__c);
    }

    @IsTest
    static void it_should_truncate_message_for_long_logMessage() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isFalse(builder.getLogEntryEvent().MessageTruncated__c);
        System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c);
        System.Assert.isNull(builder.getLogEntryEvent().Message__c);

        Integer maxMessageLength = Schema.LogEntry__c.Message__c.getDescribe().getLength();
        String baseMessage = 'z'.repeat(LogEntryEvent__e.Message__c.getDescribe().getLength() + 1);
        LogMessage logMessage = new LogMessage(baseMessage, 'something else');
        builder.setMessage(logMessage);
        System.Assert.isTrue(logMessage.getMessage().length() > maxMessageLength, 'Test message length should exceed the field length');
        builder.setMessage(logMessage);

        System.Assert.isTrue(builder.getLogEntryEvent().MessageTruncated__c, 'Message should have been truncated');
        System.Assert.areEqual(logMessage.getMessage().left(maxMessageLength), builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_truncate_message_for_long_string() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isFalse(builder.getLogEntryEvent().MessageTruncated__c);
        System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c);
        System.Assert.isNull(builder.getLogEntryEvent().Message__c);

        Integer maxMessageLength = Schema.LogEntry__c.Message__c.getDescribe().getLength();
        String message = 'z'.repeat(LogEntryEvent__e.Message__c.getDescribe().getLength() + 1);
        System.Assert.isTrue(message.length() > maxMessageLength, 'Test message length should exceed the field length');
        builder.setMessage(message);

        System.Assert.isTrue(builder.getLogEntryEvent().MessageTruncated__c, 'Message should have been truncated');
        System.Assert.areEqual(message.left(maxMessageLength), builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_skip_setting_exception_fields_when_exception_is_null() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(builder.getLogEntryEvent().ExceptionType__c);

        System.Exception nullException;
        builder.setExceptionDetails(nullException);

        System.Assert.isNull(builder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(builder.getLogEntryEvent().ExceptionType__c);
    }

    @IsTest
    static void it_should_set_exception_fields_for_dmlException() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.isNull(builder.getLogEntryEvent().ExceptionType__c);

        System.DmlException dmlException = new System.DmlException('Test DML exception');
        builder.setExceptionDetails(dmlException);

        System.Assert.areEqual(dmlException.getMessage(), builder.getLogEntryEvent().ExceptionMessage__c);
        System.Assert.areEqual(dmlException.getTypeName(), builder.getLogEntryEvent().ExceptionType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_leadConvertResult() {
        Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);
        System.Assert.isNotNull(leadConvertResult);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        builder.setDatabaseResult(leadConvertResult);

        System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_deleteResult() {
        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);
        System.Assert.isNotNull(deleteResult);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        builder.setDatabaseResult(deleteResult);

        System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_mergeResult() {
        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);
        System.Assert.isNotNull(mergeResult);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        builder.setDatabaseResult(mergeResult);

        System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.Assert.areEqual(JSON.serializePretty(mergeResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.MergeResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_saveResult() {
        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);
        System.Assert.isNotNull(saveResult);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        builder.setDatabaseResult(saveResult);

        System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.Assert.areEqual(JSON.serializePretty(saveResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_undeleteResult() {
        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);
        System.Assert.isNotNull(undeleteResult);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        builder.setDatabaseResult(undeleteResult);

        System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_upsertResult_when_insert() {
        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);
        System.Assert.isNotNull(upsertResult);
        System.Assert.isTrue(upsertResult.isCreated());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        builder.setDatabaseResult(upsertResult);

        System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_upsertResult_when_update() {
        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);
        System.Assert.isNotNull(upsertResult);
        System.Assert.isFalse(upsertResult.isCreated());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        builder.setDatabaseResult(upsertResult);

        System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_leadConvertResult() {
        List<Database.LeadConvertResult> leadConvertResults = new List<Database.LeadConvertResult>();
        for (Integer i = 0; i < 5; i++) {
            leadConvertResults.add(LoggerMockDataCreator.createDatabaseLeadConvertResult(false));
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        builder.setDatabaseResult(leadConvertResults);

        System.Assert.areEqual(leadConvertResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.Assert.areEqual(JSON.serializePretty(leadConvertResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.LeadConvertResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_deleteResult() {
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>();
        for (Integer i = 0; i < 5; i++) {
            deleteResults.add(LoggerMockDataCreator.createDatabaseDeleteResult(false));
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        builder.setDatabaseResult(deleteResults);

        System.Assert.areEqual(deleteResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.Assert.areEqual(JSON.serializePretty(deleteResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.DeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_mergeResult() {
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>();
        for (Integer i = 0; i < 5; i++) {
            mergeResults.add(LoggerMockDataCreator.createDatabaseMergeResult(false));
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        builder.setDatabaseResult(mergeResults);

        System.Assert.areEqual(mergeResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.Assert.areEqual(JSON.serializePretty(mergeResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.MergeResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_saveResult() {
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        for (Integer i = 0; i < 5; i++) {
            saveResults.add(LoggerMockDataCreator.createDatabaseSaveResult(false));
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        builder.setDatabaseResult(saveResults);

        System.Assert.areEqual(saveResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.Assert.areEqual(JSON.serializePretty(saveResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.SaveResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_undeleteResult() {
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>();
        for (Integer i = 0; i < 5; i++) {
            undeleteResults.add(LoggerMockDataCreator.createDatabaseUndeleteResult(false));
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        builder.setDatabaseResult(undeleteResults);

        System.Assert.areEqual(undeleteResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.Assert.areEqual(JSON.serializePretty(undeleteResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UndeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_upsertResult() {
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>();
        for (Integer i = 0; i < 5; i++) {
            upsertResults.add(LoggerMockDataCreator.createDatabaseUpsertResult(false, false));
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        builder.setDatabaseResult(upsertResults);

        System.Assert.areEqual(upsertResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.Assert.areEqual(JSON.serializePretty(upsertResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.Assert.areEqual(Database.UpsertResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_recordId_when_standard_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Id currentUserId = System.UserInfo.getUserId();
        builder.setRecordId(currentUserId);

        System.Assert.areEqual(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.areEqual(currentUserId, builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual('User', builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_recordId_when_template_standard_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Id templateSObjectRecordId = LoggerMockDataCreator.createId(Schema.CaseComment.SObjectType);
        builder.setRecordId(templateSObjectRecordId);

        System.Assert.areEqual(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.areEqual(templateSObjectRecordId, builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_recordId_when_custom_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Id mockLogId = LoggerMockDataCreator.createId(Schema.Log__c.SObjectType);
        builder.setRecordId(mockLogId);

        System.Assert.areEqual(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.areEqual(mockLogId, builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Custom Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual(Log__c.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_recordId_when_custom_metadata_type() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        LogStatus__mdt status = [SELECT Id, MasterLabel, DeveloperName FROM LogStatus__mdt LIMIT 1];
        builder.setRecordId(status.Id);

        System.Assert.areEqual(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.areEqual(status.Id, builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Custom Metadata Type Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual(LogStatus__mdt.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_record_when_null() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        User nullUser;
        System.Assert.isNull(nullUser);
        builder.setRecordId(nullUser);

        System.Assert.areEqual(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual('null', builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_record_when_standard_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        User currentUser = [SELECT Id, Name, ProfileId, Profile.Name, IsActive FROM User WHERE Id = :System.UserInfo.getUserId()];
        builder.setRecordId(currentUser);

        System.Assert.areEqual(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.areEqual(currentUser.Id, builder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(currentUser), builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual('User', builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_record_when_custom_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        builder.setRecordId(log);

        System.Assert.areEqual(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.areEqual(log.Id, builder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(log), builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Custom Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual(Log__c.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_record_when_custom_metadata_type() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        LogStatus__mdt status = [SELECT Id, MasterLabel, DeveloperName FROM LogStatus__mdt LIMIT 1];
        builder.setRecordId(status);

        System.Assert.areEqual(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.areEqual(status.Id, builder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(status), builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Custom Metadata Type Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual(LogStatus__mdt.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_record_when_platform_event() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        // To avoid creating a new platform event just for testing purposes, Nebula Logger's LogEntryEvent__e is reused
        LogEntryEvent__e platformEvent = new LogEntryEvent__e();
        builder.setRecordId(platformEvent);

        System.Assert.areEqual(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(platformEvent), builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Platform Event Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual(LogEntryEvent__e.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_skip_stripping_inaccessible_fields_for_aggregate_result() {
        User standardUser = LoggerMockDataCreator.createUser();
        AggregateResult mockAggregateResult = LoggerMockDataCreator.createAggregateResult();

        LogEntryEventBuilder builder;
        System.runAs(standardUser) {
            LoggerSettings__c userSettings = getUserSettings();
            userSettings.IsRecordFieldStrippingEnabled__c = true;
            builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true, new Set<String>()).setRecord(mockAggregateResult);
        }

        System.Assert.areEqual(JSON.serializePretty(mockAggregateResult), builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_skip_stripping_inaccessible_fields_for_aggregate_results() {
        User standardUser = LoggerMockDataCreator.createUser();
        List<AggregateResult> mockAggregateResults = new List<AggregateResult>{ LoggerMockDataCreator.createAggregateResult() };

        LogEntryEventBuilder builder;
        System.runAs(standardUser) {
            LoggerSettings__c userSettings = getUserSettings();
            userSettings.IsRecordFieldStrippingEnabled__c = true;
            builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true, new Set<String>()).setRecord(mockAggregateResults);
        }

        System.Assert.areEqual(JSON.serializePretty(mockAggregateResults), builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_list_of_records_when_list_is_null() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        List<SObject> users;
        System.Assert.isNull(users);
        builder.setRecord(users);

        System.Assert.areEqual('List', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual('null', builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_list_of_records_when_list_is_empty() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        List<SObject> users = new List<SObject>();
        System.Assert.isTrue(users.isEmpty());
        builder.setRecord(users);

        System.Assert.areEqual('List', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_list_of_records_when_first_record_is_null() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        List<SObject> users = new List<SObject>();
        User nullUser;
        users.add(nullUser);
        users.add(new User(Id = System.UserInfo.getUserId()));
        builder.setRecord(users);

        System.Assert.areEqual('List', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_list_of_records_when_populated() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        builder.setRecord(users);

        System.Assert.areEqual('List', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(users), builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual(User.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_map_of_sobject_records_when_map_is_null() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Map<Id, SObject> userIdToUser;
        System.Assert.isNull(userIdToUser);
        builder.setRecord(userIdToUser);

        System.Assert.isNull(builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Map', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_map_of_sobject_records_when_map_is_empty() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Map<Id, SObject> userIdToUser = new Map<Id, SObject>();
        System.Assert.areEqual(true, userIdToUser.isEmpty());
        builder.setRecord(userIdToUser);

        System.Assert.areEqual(userIdToUser.size(), builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Map', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(userIdToUser), builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_map_of_sobject_records_when_map_contains_null_key() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Map<Id, SObject> userIdToUser = new Map<Id, SObject>{ null => new User(Id = System.UserInfo.getUserId()) };
        builder.setRecord(userIdToUser);

        Map<String, SObject> userIdStringToUser = new Map<String, SObject>{ '' => userIdToUser.get(null) };
        System.Assert.areEqual(userIdToUser.size(), builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Map', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(userIdStringToUser), builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual('User', builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_map_of_sobject_records_when_first_record_is_null() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Id mockUserId = LoggerMockDataCreator.createId(Schema.User.SObjectType);
        User nullUser;
        Map<Id, SObject> userIdToUser = new Map<Id, SObject>{
            mockUserId => nullUser,
            System.UserInfo.getUserId() => new User(Id = System.UserInfo.getUserId(), Username = System.UserInfo.getUsername())
        };
        builder.setRecord(userIdToUser);

        String expectedJson = JSON.serializePretty(userIdToUser);
        System.Assert.areEqual(userIdToUser.size(), builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Map', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(expectedJson, builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_map_of_user_records_when_populated() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Map<Id, User> userIdToUser = new Map<Id, User>([SELECT Id, Name, Username, IsActive FROM User LIMIT 5]);
        builder.setRecord(userIdToUser);

        System.Assert.areEqual(userIdToUser.size(), builder.getLogEntryEvent().RecordCollectionSize__c);
        System.Assert.areEqual('Map', builder.getLogEntryEvent().RecordCollectionType__c);
        System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
        System.Assert.areEqual(JSON.serializePretty(userIdToUser), builder.getLogEntryEvent().RecordJson__c);
        System.Assert.areEqual('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.Assert.areEqual(User.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_skip_setting_http_request_fields_when_request_is_null() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestBody__c);
        System.Assert.isFalse(builder.getLogEntryEvent().HttpRequestCompressed__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestEndpoint__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestMethod__c);
        System.HttpRequest request = null;

        builder.setHttpRequestDetails(request);

        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestBody__c);
        System.Assert.isFalse(builder.getLogEntryEvent().HttpRequestCompressed__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestEndpoint__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestMethod__c);
    }

    @IsTest
    static void it_should_set_http_request_fields_when_request_is_populated() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestBody__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestEndpoint__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestMethod__c);
        System.HttpRequest request = new System.HttpRequest();
        request.setBody('Hello, world!');
        request.setCompressed(true);
        request.setEndpoint('https://fake.salesforce.com');
        request.setMethod('GET');

        builder.setHttpRequestDetails(request);

        System.Assert.areEqual(request.getBody(), builder.getLogEntryEvent().HttpRequestBody__c);
        System.Assert.areEqual(request.getCompressed(), builder.getLogEntryEvent().HttpRequestCompressed__c);
        System.Assert.areEqual(request.getEndpoint(), builder.getLogEntryEvent().HttpRequestEndpoint__c);
        System.Assert.areEqual(request.getMethod(), builder.getLogEntryEvent().HttpRequestMethod__c);
    }

    @IsTest
    static void it_should_skip_setting_http_response_fields_when_response_is_null() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestBody__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestEndpoint__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestMethod__c);
        System.HttpResponse response = null;

        builder.setHttpResponseDetails(response);

        System.Assert.isNull(builder.getLogEntryEvent().HttpResponseBody__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpResponseHeaderKeys__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpResponseHeaders__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpResponseStatus__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpResponseStatusCode__c);
    }

    @IsTest
    static void it_should_set_http_response_fields_when_storing_header_values_is_enabled() {
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'StoreHttpResponseHeaderValues', Value__c = String.valueOf(true));
        LoggerParameter.setMock(mockParameter);
        System.Assert.isTrue(LoggerParameter.STORE_HTTP_RESPONSE_HEADER_VALUES);
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestBody__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestEndpoint__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestMethod__c);
        System.HttpResponse response = new System.HttpResponse();
        response.setBody('Hello, world!');
        response.setHeader('someKey', 'some string value');
        response.setHeader('anotherKey', 'an amazing example value, wow');
        response.setStatus('STATUS_GOOD_JOB_YOU_DID_IT');
        response.setStatusCode(201);

        builder.setHttpResponseDetails(response);

        List<String> formattedHeaders = new List<String>();
        for (String headerKey : response.getHeaderKeys()) {
            formattedHeaders.add(headerKey + ': ' + response.getHeader(headerKey));
        }
        System.Assert.areEqual(response.getBody(), builder.getLogEntryEvent().HttpResponseBody__c);
        System.Assert.areEqual(String.join(response.getHeaderKeys(), '\n'), builder.getLogEntryEvent().HttpResponseHeaderKeys__c);
        System.Assert.areEqual(String.join(formattedHeaders, '\n'), builder.getLogEntryEvent().HttpResponseHeaders__c);
        System.Assert.areEqual(response.getStatus(), builder.getLogEntryEvent().HttpResponseStatus__c);
        System.Assert.areEqual(response.getStatusCode(), builder.getLogEntryEvent().HttpResponseStatusCode__c);
    }

    @IsTest
    static void it_should_set_http_response_fields_when_storing_header_values_is_disabled() {
        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'StoreHttpResponseHeaderValues', Value__c = String.valueOf(false));
        LoggerParameter.setMock(mockParameter);
        System.Assert.isFalse(LoggerParameter.STORE_HTTP_RESPONSE_HEADER_VALUES);
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestBody__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestEndpoint__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpRequestMethod__c);
        System.HttpResponse response = new System.HttpResponse();
        response.setBody('Hello, world!');
        response.setHeader('someKey', 'some string value');
        response.setHeader('anotherKey', 'an amazing example value, wow');
        response.setStatus('STATUS_GOOD_JOB_YOU_DID_IT');
        response.setStatusCode(201);

        builder.setHttpResponseDetails(response);

        System.Assert.areEqual(response.getBody(), builder.getLogEntryEvent().HttpResponseBody__c);
        System.Assert.areEqual(String.join(response.getHeaderKeys(), '\n'), builder.getLogEntryEvent().HttpResponseHeaderKeys__c);
        System.Assert.isNull(builder.getLogEntryEvent().HttpResponseHeaders__c);
        System.Assert.areEqual(response.getStatus(), builder.getLogEntryEvent().HttpResponseStatus__c);
        System.Assert.areEqual(response.getStatusCode(), builder.getLogEntryEvent().HttpResponseStatusCode__c);
    }

    @IsTest
    static void it_should_set_tags_string_for_list_of_tags() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().Tags__c);

        List<String> tags = new List<String>{ 'some-tag', 'another One', 'here\'s one more!' };
        builder.addTags(tags);

        tags.sort();
        String expectedTagsString = String.escapeSingleQuotes(String.join(tags, '\n'));
        System.Assert.areEqual(expectedTagsString, builder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_deduplicate_and_sort_tags() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isNull(builder.getLogEntryEvent().Tags__c);

        List<String> tags = new List<String>{ 'duplicate-tag', 'duplicate-tag', 'another One' };
        builder.addTags(tags);

        String expectedTagsString = 'another One\nduplicate-tag';
        System.Assert.areEqual(expectedTagsString, builder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_not_set_stack_trace_for_new_builder_instance_when_disabled_via_logger_parameter() {
        // Don't bother testing stack trace logic when using a namespace prefix - there are
        // some platform limitations that prevent these tests from behaving as expected
        if (LogEntryEventBuilder.class.getName().contains('.')) {
            return;
        }

        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'EnableStackTraceParsing', Value__c = String.valueOf(false));
        LoggerParameter.setMock(mockParameter);
        System.Assert.isFalse(LoggerParameter.ENABLE_STACK_TRACE_PARSING);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());

        System.Assert.isNull(builder.getLogEntryEvent().OriginLocation__c);
        System.Assert.isNull(builder.getLogEntryEvent().StackTrace__c);
    }

    @IsTest
    static void it_should_not_set_stack_trace_for_parseStackTrace_method_when_disabled_via_logger_parameter() {
        // Don't bother testing stack trace logic when using a namespace prefix - there are
        // some platform limitations that prevent these tests from behaving as expected
        if (LogEntryEventBuilder.class.getName().contains('.')) {
            return;
        }

        LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'EnableStackTraceParsing', Value__c = String.valueOf(false));
        LoggerParameter.setMock(mockParameter);
        System.Assert.isFalse(LoggerParameter.ENABLE_STACK_TRACE_PARSING);
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());

        builder.parseStackTrace('AnonymousBlock: line 1, column 1');

        System.Assert.isNull(builder.getLogEntryEvent().OriginLocation__c);
        System.Assert.isNull(builder.getLogEntryEvent().StackTrace__c);
    }

    @IsTest
    static void it_should_set_stack_trace_and_origin_location_for_class_constructor_trace_string() {
        // Don't bother testing stack trace logic when using a namespace prefix - there are
        // some platform limitations that prevent these tests from behaving as expected
        if (LogEntryEventBuilder.class.getName().contains('.')) {
            return;
        }

        String qualifiedClassName = DebugStringExample.class.getName();
        String expectedOriginLocation = qualifiedClassName + '.<init>';
        DebugStringExample constructedClass = new DebugStringExample();
        String expectedStackTrace = constructedClass.getStackTraceString();
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.FINE, true, new Set<String>());
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;

        builder.parseStackTrace(constructedClass.getStackTraceString());

        System.Assert.isNotNull(builder.getLogEntryEvent().OriginLocation__c);
        System.Assert.areEqual(expectedOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
        System.Assert.isNotNull(builder.getLogEntryEvent().StackTrace__c);
        System.Assert.areEqual(expectedStackTrace, builder.getLogEntryEvent().StackTrace__c);
    }

    @IsTest
    static void it_should_set_stack_trace_and_origin_location_for_method_stack_trace_string() {
        // Don't bother testing stack trace logic when using a namespace prefix - there are
        // some platform limitations that prevent these tests from behaving as expected
        if (LogEntryEventBuilder.class.getName().contains('.')) {
            return;
        }

        System.DmlException stackTraceHandler = new System.DmlException();
        String qualifiedClassName = LogEntryEventBuilder_Tests.class.getName();
        String expectedOriginLocation = qualifiedClassName + '.it_should_set_stack_trace_and_origin_location_for_method_stack_trace_string';
        String expectedStackTrace = stackTraceHandler.getStackTraceString();
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.FINE, true, new Set<String>());
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;

        builder.parseStackTrace(stackTraceHandler.getStackTraceString());

        System.Assert.isNotNull(builder.getLogEntryEvent().OriginLocation__c);
        System.Assert.areEqual(expectedOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
        System.Assert.isNotNull(builder.getLogEntryEvent().StackTrace__c);
        System.Assert.areEqual(expectedStackTrace, builder.getLogEntryEvent().StackTrace__c);
    }

    @IsTest
    static void it_should_ignore_stack_trace_line_when_matching_class_type_is_specified() {
        String qualifiedClassName = LogEntryEventBuilder_Tests.class.getName();
        String mockStackTrace =
            'Class.' +
            qualifiedClassName +
            '.it_should_ignore_stack_trace_line_when_ignore_origin_location_method_is_called: line 99999, column 1' +
            '\nClass.ExampleClassWithLogging.doSomething: line 17, column 1' +
            '\nAnonymousBlock: line 1, column 1';
        String expectedStackTrace = 'Class.ExampleClassWithLogging.doSomething: line 17, column 1' + '\nAnonymousBlock: line 1, column 1';
        String expectedOriginLocation = 'ExampleClassWithLogging.doSomething';

        LogEntryEventBuilder builder = new LogEntryEventBuilder(
            getUserSettings(),
            System.LoggingLevel.FINE,
            true,
            new Set<String>{ LogEntryEventBuilder_Tests.class.getName() }
        );
        builder.parseStackTrace(mockStackTrace);

        System.Assert.isNotNull(builder.getLogEntryEvent().OriginLocation__c);
        System.Assert.areEqual(expectedOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
        System.Assert.isNotNull(builder.getLogEntryEvent().StackTrace__c);
        System.Assert.areEqual(expectedStackTrace, builder.getLogEntryEvent().StackTrace__c);
    }

    @IsTest
    static void it_should_set_stack_trace_and_origin_location_for_anonymous_apex_stack_trace_string() {
        String anonymousApexOriginLocation = 'AnonymousBlock';
        String anonymousApexStackTraceString = 'AnonymousBlock: line 9, column 1';

        LogEntryEventBuilder builder = new LogEntryEventBuilder(
            getUserSettings(),
            System.LoggingLevel.FINE,
            true,
            new Set<String>{ LogEntryEventBuilder_Tests.class.getName() }
        );
        builder.parseStackTrace(anonymousApexStackTraceString);

        System.Assert.isNotNull(builder.getLogEntryEvent().OriginLocation__c);
        System.Assert.areEqual(anonymousApexOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
        System.Assert.isNotNull(builder.getLogEntryEvent().StackTrace__c);
        System.Assert.areEqual(anonymousApexStackTraceString, builder.getLogEntryEvent().StackTrace__c);
    }

    @IsTest
    static void it_should_deduplicate_sequential_lines_when_setting_stack_trace() {
        String anonymousApexOriginLocation = 'AnonymousBlock';
        String deduplicatedStackTraceString = 'AnonymousBlock: line 9, column 1';
        String duplicatedStackTraceString = deduplicatedStackTraceString + '\n' + deduplicatedStackTraceString + '\n' + deduplicatedStackTraceString;

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.FINE, true, new Set<String>());
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;
        builder.parseStackTrace(duplicatedStackTraceString);

        System.Assert.isNotNull(builder.getLogEntryEvent().OriginLocation__c);
        System.Assert.areEqual(anonymousApexOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
        System.Assert.isNotNull(builder.getLogEntryEvent().StackTrace__c);
        System.Assert.areEqual(deduplicatedStackTraceString, builder.getLogEntryEvent().StackTrace__c);
    }

    @IsTest
    static void it_should_not_set_stack_trace_and_origin_location_for_invalid_stack_trace_string() {
        final String invalidStackTrace = '()';

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        // Clear out any auto-set values
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;
        builder.parseStackTrace(invalidStackTrace);

        System.Assert.isNull(builder.getLogEntryEvent().OriginLocation__c);
        System.Assert.isNull(builder.getLogEntryEvent().StackTrace__c);
    }

    @IsTest
    static void it_should_return_value_of_shouldSave_when_true() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());
        System.Assert.isTrue(builder.shouldSave());
    }

    @IsTest
    static void it_should_return_value_of_shouldSave_when_false() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, false, new Set<String>());
        System.Assert.isFalse(builder.shouldSave());
    }

    @IsTest
    static void it_should_set_user_fields_when_anonymous_mode_disabled() {
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryOrganizationDataSynchronously', Value__c = String.valueOf(true)));
        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryUserDataSynchronously', Value__c = String.valueOf(true)));
        Organization organization = LoggerMockDataCreator.getOrganization();
        String organizationEnvironmentType = LoggerMockDataCreator.getOrganizationEnvironmentType();
        User user = LoggerMockDataCreator.getUser();

        LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true, new Set<String>());

        // Verify organization fields
        System.Assert.areEqual(organizationEnvironmentType, builder.getLogEntryEvent().OrganizationEnvironmentType__c);
        System.Assert.areEqual(organization.Id, builder.getLogEntryEvent().OrganizationId__c);
        System.Assert.areEqual(organization.InstanceName, builder.getLogEntryEvent().OrganizationInstanceName__c);
        System.Assert.areEqual(organization.Name, builder.getLogEntryEvent().OrganizationName__c);
        System.Assert.areEqual(organization.NamespacePrefix, builder.getLogEntryEvent().OrganizationNamespacePrefix__c);
        System.Assert.areEqual(organization.OrganizationType, builder.getLogEntryEvent().OrganizationType__c);

        // Verify user fields
        System.Assert.areEqual(user.Id, builder.getLogEntryEvent().LoggedById__c);
        System.Assert.areEqual(user.Username, builder.getLogEntryEvent().LoggedByUsername__c);
        System.Assert.areEqual(user.Profile.Name, builder.getLogEntryEvent().ProfileName__c);
        System.Assert.areEqual(user.Profile.UserLicense.LicenseDefinitionKey, builder.getLogEntryEvent().UserLicenseDefinitionKey__c);
        System.Assert.areEqual(user.Profile.UserLicenseId, builder.getLogEntryEvent().UserLicenseId__c);
        System.Assert.areEqual(user.Profile.UserLicense.Name, builder.getLogEntryEvent().UserLicenseName__c);
        System.Assert.areEqual(user.UserRole?.Name, builder.getLogEntryEvent().UserRoleName__c);
    }

    @IsTest
    static void it_should_not_set_user_fields_when_anonymous_mode_is_enabled() {
        LoggerSettings__c userSettings = getUserSettings();
        userSettings.IsAnonymousModeEnabled__c = true;

        LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.DEBUG, true, new Set<String>());

        System.Assert.isNull(builder.getLogEntryEvent().Locale__c);
        System.Assert.isNull(builder.getLogEntryEvent().LoggedById__c);
        System.Assert.isNull(builder.getLogEntryEvent().LoggedByUsername__c);
        System.Assert.isNull(builder.getLogEntryEvent().LoginApplication__c);
        System.Assert.isNull(builder.getLogEntryEvent().LoginBrowser__c);
        System.Assert.isNull(builder.getLogEntryEvent().LoginHistoryId__c);
        System.Assert.isNull(builder.getLogEntryEvent().LoginPlatform__c);
        System.Assert.isNull(builder.getLogEntryEvent().LoginType__c);
        System.Assert.isNull(builder.getLogEntryEvent().LogoutUrl__c);
        System.Assert.isNull(builder.getLogEntryEvent().ProfileId__c);
        System.Assert.isNull(builder.getLogEntryEvent().ProfileName__c);
        System.Assert.isNull(builder.getLogEntryEvent().SessionId__c);
        System.Assert.isNull(builder.getLogEntryEvent().SessionSecurityLevel__c);
        System.Assert.isNull(builder.getLogEntryEvent().SessionType__c);
        System.Assert.isNull(builder.getLogEntryEvent().SourceIp__c);
        System.Assert.isNull(builder.getLogEntryEvent().ThemeDisplayed__c);
        System.Assert.isNull(builder.getLogEntryEvent().TimeZoneId__c);
        System.Assert.isNull(builder.getLogEntryEvent().TimeZoneName__c);
        System.Assert.isNull(builder.getLogEntryEvent().UserLicenseDefinitionKey__c);
        System.Assert.isNull(builder.getLogEntryEvent().UserLicenseId__c);
        System.Assert.isNull(builder.getLogEntryEvent().UserLicenseName__c);
        System.Assert.isNull(builder.getLogEntryEvent().UserRoleId__c);
        System.Assert.isNull(builder.getLogEntryEvent().UserRoleName__c);
        System.Assert.isNull(builder.getLogEntryEvent().UserType__c);
    }

    @IsTest
    static void it_should_use_configured_log_entry_event_fields_for_debug_string() {
        // Don't bother testing stack trace logic when using a namespace prefix - there are
        // some platform limitations that prevent these tests from behaving as expected
        if (LogEntryEventBuilder.class.getName().contains('.')) {
            return;
        }

        LoggerParameter.setMock(
            new LoggerParameter__mdt(DeveloperName = 'SystemDebugMessageFormat', Value__c = '{OriginLocation__c}\n{Message__c}: {LoggingLevel__c}')
        );

        DebugStringExample example = new DebugStringExample();
        LoggerSettings__c userSettings = getUserSettings();
        userSettings.IsApexSystemDebugLoggingEnabled__c = true;
        LogEntryEventBuilder builder = example.myMethod(userSettings);

        System.Assert.areEqual(
            DebugStringExample.class.getName() + '.myMethod' + '\n' + example.loggingString + ': ' + System.LoggingLevel.DEBUG.name(),
            builder.debugMessage
        );
    }

    static String getMessage() {
        return 'Hello, world';
    }

    static LogMessage getLogMessage() {
        return new LogMessage('The current date is {0}', System.today());
    }

    static String getNamespacePrefix() {
        String className = LogEntryEventBuilder_Tests.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

        return namespacePrefix;
    }

    static LogEntryDataMaskRule__mdt getSocialSecurityNumberDataMaskRule() {
        return new LogEntryDataMaskRule__mdt(
            DeveloperName = 'SocialSecurityNumber',
            IsEnabled__c = true,
            SensitiveDataRegEx__c = '(\\d{3})[- ]*(\\d{2})[- ]*(\\d{4})',
            ReplacementRegEx__c = 'XXX-XX-$3'
        );
    }

    static LoggerSettings__c getUserSettings() {
        LoggerSettings__c userSettings = (LoggerSettings__c) Schema.LoggerSettings__c.SObjectType.newSObject(null, true);
        userSettings.SetupOwnerId = System.UserInfo.getUserId();
        return userSettings;
    }

    private class DebugStringExample {
        public final String loggingString = 'Inside DebugStringExample.myMethod!';
        private System.Exception stackTraceHandler;

        public DebugStringExample() {
            this.stackTraceHandler = new System.DmlException();
        }

        public String getStackTraceString() {
            return this.stackTraceHandler.getStackTraceString();
        }

        public LogEntryEventBuilder myMethod(LoggerSettings__c userSettings) {
            return new LogEntryEventBuilder(userSettings, System.LoggingLevel.DEBUG, true, new Set<String>{ LogEntryEventBuilder.class.getName() })
                .setMessage(loggingString);
        }
    }

    private class MockLoggerEngineDataSelector extends LoggerEngineDataSelector {
        private Integer cachedAuthSessionQueryCount = 0;
        private Integer cachedOrganizationQueryCount = 0;
        private Integer cachedUserQueryCount = 0;
        private LoggerSObjectProxy.AuthSession mockAuthSessionProxy;

        public override LoggerSObjectProxy.AuthSession getCachedAuthSessionProxy() {
            this.cachedAuthSessionQueryCount++;
            if (this.mockAuthSessionProxy != null) {
                return mockAuthSessionProxy;
            }
            return super.getCachedAuthSessionProxy();
        }

        public void setCachedAuthSessionProxy(LoggerSObjectProxy.AuthSession mockAuthSessionProxy) {
            this.mockAuthSessionProxy = mockAuthSessionProxy;
        }

        public Integer getCachedAuthSessionQueryCount() {
            return cachedAuthSessionQueryCount;
        }

        public override Organization getCachedOrganization() {
            this.cachedOrganizationQueryCount++;
            return super.getCachedOrganization();
        }

        public Integer getCachedOrganizationQueryCount() {
            return cachedOrganizationQueryCount;
        }

        public override User getCachedUser() {
            this.cachedUserQueryCount++;
            return super.getCachedUser();
        }

        public Integer getCachedUserQueryCount() {
            return cachedUserQueryCount;
        }
    }
}
