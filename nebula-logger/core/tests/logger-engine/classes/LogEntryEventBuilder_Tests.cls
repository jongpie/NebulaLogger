//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings(
  'PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssCount, PMD.NcssMethodCount, PMD.NcssTypeCount'
)
@IsTest(IsParallel=false)
private class LogEntryEventBuilder_Tests {
  static {
    // Don't use the org's actual custom metadata records when running tests
    LoggerConfigurationSelector.useMocks();
    LoggerStackTrace.ignoreOrigin(LogEntryEventBuilder.class);
  }

  @IsTest
  static void it_should_short_circuit_when_disabled() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.DEBUG, false);

    // Run all public and global methods to make sure no errors occur when not enabled (it's happened before)
    System.Assert.isNull(builder.setMessage(getLogMessage()).getLogEntryEvent());
    System.Assert.isNull(builder.setMessage(getMessage()).getLogEntryEvent());
    System.Assert.isNull(builder.setExceptionDetails(new System.DmlException()).getLogEntryEvent());
    System.Assert.isNull(builder.setApprovalResult((Approval.LockResult) null).getLogEntryEvent());
    System.Assert.isNull(builder.setApprovalResult((Approval.ProcessResult) null).getLogEntryEvent());
    System.Assert.isNull(builder.setApprovalResult((Approval.UnlockResult) null).getLogEntryEvent());
    System.Assert.isNull(builder.setApprovalResult(new List<Approval.LockResult>()).getLogEntryEvent());
    System.Assert.isNull(builder.setApprovalResult(new List<Approval.ProcessResult>()).getLogEntryEvent());
    System.Assert.isNull(builder.setApprovalResult(new List<Approval.UnlockResult>()).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult((Database.DeleteResult) null).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult((Database.EmptyRecycleBinResult) null).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult((Database.LeadConvertResult) null).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult((Database.MergeResult) null).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult((Database.SaveResult) null).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult((Database.UpsertResult) null).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult((Database.UndeleteResult) null).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult(new List<Database.DeleteResult>()).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult(new List<Database.EmptyRecycleBinResult>()).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult(new List<Database.LeadConvertResult>()).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult(new List<Database.MergeResult>()).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult(new List<Database.SaveResult>()).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult(new List<Database.UpsertResult>()).getLogEntryEvent());
    System.Assert.isNull(builder.setDatabaseResult(new List<Database.UndeleteResult>()).getLogEntryEvent());
    System.Assert.isNull(builder.setRecordId(System.UserInfo.getUserId()).getLogEntryEvent());
    System.Assert.isNull(builder.setRecordId(new Schema.User(Id = System.UserInfo.getUserId())).getLogEntryEvent());
    System.Assert.isNull(builder.setRecord(System.UserInfo.getUserId()).getLogEntryEvent());
    System.Assert.isNull(builder.setRecord(new Schema.User(Id = System.UserInfo.getUserId())).getLogEntryEvent());
    System.Assert.isNull(builder.setRecord(new List<Schema.User>{ new Schema.User(Id = System.UserInfo.getUserId()) }).getLogEntryEvent());
    System.Assert.isNull(builder.setRecord(new Set<Id>{ System.UserInfo.getUserId() }).getLogEntryEvent());
    System.Assert.isNull(builder.addTags(new List<String>{ 'tag-1', 'tag-2' }).getLogEntryEvent());
    System.Assert.isNull(builder.parseStackTrace(new System.DmlException().getStackTraceString()).getLogEntryEvent());
  }

  @IsTest
  static void it_should_short_circuit_when_enabled_logging_level_above_called_level() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.FINE, false);
    System.Assert.isNull(builder.getLogEntryEvent());
  }

  @IsTest
  static void it_should_not_short_circuit_when_enabled() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.FINE, true);
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

    new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, userSettings.IsEnabled__c).setMessage('some message').getLogEntryEvent();

    System.Assert.areEqual(0, System.Limits.getQueries());
  }

  @IsTest
  static void it_should_set_transaction_limits_fields_when_enabled_via_logger_parameter() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'StoreTransactionLimits', Value__c = System.JSON.serialize(true)));
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'StoreHeapSizeLimit', Value__c = System.JSON.serialize(true)));
    System.Assert.isTrue(LoggerParameter.STORE_TRANSACTION_LIMITS);
    System.Assert.isTrue(LoggerParameter.STORE_HEAP_SIZE_LIMIT);
    // Capture these limits first, before creating an instance of LogEntryEventBuilder - the builder runs several queries internally,
    // so capturing afterwards leads to inaccurate numbers
    Integer expectedQueryCount = System.Limits.getQueries();
    Integer expectedQueryLocatorRows = System.Limits.getQueryLocatorRows();
    Integer expectedQueryRows = System.Limits.getQueryRows();

    LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true).getLogEntryEvent();

    System.Assert.areEqual(System.Limits.getAggregateQueries(), logEntryEvent.LimitsAggregateQueriesUsed__c);
    System.Assert.areEqual(System.Limits.getFetchCallsOnApexCursor(), logEntryEvent.LimitsApexCursorFetchCallsUsed__c);
    System.Assert.areEqual(System.Limits.getApexCursorRows(), logEntryEvent.LimitsApexCursorRowsUsed__c);
    System.Assert.areEqual(System.Limits.getAsyncCalls(), logEntryEvent.LimitsAsyncCallsUsed__c);
    System.Assert.areEqual(System.Limits.getCallouts(), logEntryEvent.LimitsCalloutsUsed__c);
    // For some limits, it's impossible to have an accurate expected value, so just validate that it's not null
    System.Assert.isNotNull(logEntryEvent.LimitsCpuTimeUsed__c);
    System.Assert.areEqual(System.Limits.getDmlRows(), logEntryEvent.LimitsDmlRowsUsed__c);
    System.Assert.areEqual(System.Limits.getDmlStatements(), logEntryEvent.LimitsDmlStatementsUsed__c);
    System.Assert.areEqual(System.Limits.getEmailInvocations(), logEntryEvent.LimitsEmailInvocationsUsed__c);
    System.Assert.areEqual(System.Limits.getFutureCalls(), logEntryEvent.LimitsFutureCallsUsed__c);
    // For some limits, it's impossible to have an accurate expected value, so just validate that it's not null
    System.Assert.isNotNull(logEntryEvent.LimitsHeapSizeUsed__c);
    System.Assert.areEqual(System.Limits.getMobilePushApexCalls(), logEntryEvent.LimitsMobilePushApexCallsUsed__c);
    System.Assert.areEqual(System.Limits.getQueueableJobs(), logEntryEvent.LimitsQueueableJobsUsed__c);
    System.Assert.areEqual(System.Limits.getPublishImmediateDML(), logEntryEvent.LimitsPublishImmediateDmlStatementsUsed__c);
    System.Assert.areEqual(expectedQueryCount, logEntryEvent.LimitsSoqlQueriesUsed__c);
    System.Assert.areEqual(expectedQueryLocatorRows, logEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c);
    System.Assert.areEqual(expectedQueryRows, logEntryEvent.LimitsSoqlQueryRowsUsed__c);
    System.Assert.areEqual(System.Limits.getSoslQueries(), logEntryEvent.LimitsSoslSearchesUsed__c);
    System.Assert.areEqual(System.Limits.getLimitAggregateQueries(), logEntryEvent.LimitsAggregateQueriesMax__c);
    System.Assert.areEqual(System.Limits.getLimitFetchCallsOnApexCursor(), logEntryEvent.LimitsApexCursorFetchCallsMax__c);
    System.Assert.areEqual(System.Limits.getLimitApexCursorRows(), logEntryEvent.LimitsApexCursorRowsMax__c);
    System.Assert.areEqual(System.Limits.getLimitAsyncCalls(), logEntryEvent.LimitsAsyncCallsMax__c);
    System.Assert.areEqual(System.Limits.getLimitCallouts(), logEntryEvent.LimitsCalloutsMax__c);
    System.Assert.areEqual(System.Limits.getLimitCpuTime(), logEntryEvent.LimitsCpuTimeMax__c);
    System.Assert.areEqual(System.Limits.getLimitDmlRows(), logEntryEvent.LimitsDmlRowsMax__c);
    System.Assert.areEqual(System.Limits.getLimitDmlStatements(), logEntryEvent.LimitsDmlStatementsMax__c);
    System.Assert.areEqual(System.Limits.getLimitEmailInvocations(), logEntryEvent.LimitsEmailInvocationsMax__c);
    System.Assert.areEqual(System.Limits.getLimitFutureCalls(), logEntryEvent.LimitsFutureCallsMax__c);
    System.Assert.areEqual(System.Limits.getLimitHeapSize(), logEntryEvent.LimitsHeapSizeMax__c);
    System.Assert.areEqual(System.Limits.getLimitMobilePushApexCalls(), logEntryEvent.LimitsMobilePushApexCallsMax__c);
    System.Assert.areEqual(System.Limits.getLimitPublishImmediateDML(), logEntryEvent.LimitsPublishImmediateDmlStatementsMax__c);
    System.Assert.areEqual(System.Limits.getLimitQueueableJobs(), logEntryEvent.LimitsQueueableJobsMax__c);
    System.Assert.areEqual(System.Limits.getLimitQueries(), logEntryEvent.LimitsSoqlQueriesMax__c);
    System.Assert.areEqual(System.Limits.getLimitQueryLocatorRows(), logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c);
    System.Assert.areEqual(System.Limits.getLimitQueryRows(), logEntryEvent.LimitsSoqlQueryRowsMax__c);
    System.Assert.areEqual(System.Limits.getLimitSoslQueries(), logEntryEvent.LimitsSoslSearchesMax__c);
  }

  @IsTest
  static void it_should_not_set_transaction_heap_limits_fields_when_disabled_via_logger_parameter() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'StoreTransactionLimits', Value__c = System.JSON.serialize(true)));
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'StoreHeapSizeLimit', Value__c = System.JSON.serialize(false)));
    System.Assert.isTrue(LoggerParameter.STORE_TRANSACTION_LIMITS);

    LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true).getLogEntryEvent();

    System.Assert.isNull(logEntryEvent.LimitsHeapSizeUsed__c);
  }

  @IsTest
  static void it_should_not_set_transaction_heap_limits_fields_when_transaction_limit_tracking_is_disabled_via_logger_parameter() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'StoreTransactionLimits', Value__c = System.JSON.serialize(false)));
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'StoreHeapSizeLimit', Value__c = System.JSON.serialize(true)));
    System.Assert.isFalse(LoggerParameter.STORE_TRANSACTION_LIMITS);

    LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true).getLogEntryEvent();

    System.Assert.isNull(logEntryEvent.LimitsHeapSizeUsed__c);
  }

  @IsTest
  static void it_should_not_set_transaction_limits_fields_when_disabled_via_logger_parameter() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'StoreTransactionLimits', Value__c = System.JSON.serialize(false)));
    System.Assert.isFalse(LoggerParameter.STORE_TRANSACTION_LIMITS);

    LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true).getLogEntryEvent();

    System.Assert.isNull(logEntryEvent.LimitsAggregateQueriesUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsApexCursorFetchCallsUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsApexCursorRowsUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsAsyncCallsUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsCalloutsUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsCpuTimeUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsDmlRowsUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsDmlStatementsUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsEmailInvocationsUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsFutureCallsUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsHeapSizeUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsMobilePushApexCallsUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsQueueableJobsUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsPublishImmediateDmlStatementsUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsSoqlQueriesUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsSoqlQueryRowsUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsSoslSearchesUsed__c);
    System.Assert.isNull(logEntryEvent.LimitsAggregateQueriesMax__c);
    System.Assert.isNull(logEntryEvent.LimitsApexCursorFetchCallsMax__c);
    System.Assert.isNull(logEntryEvent.LimitsApexCursorRowsMax__c);
    System.Assert.isNull(logEntryEvent.LimitsAsyncCallsMax__c);
    System.Assert.isNull(logEntryEvent.LimitsCalloutsMax__c);
    System.Assert.isNull(logEntryEvent.LimitsCpuTimeMax__c);
    System.Assert.isNull(logEntryEvent.LimitsDmlRowsMax__c);
    System.Assert.isNull(logEntryEvent.LimitsDmlStatementsMax__c);
    System.Assert.isNull(logEntryEvent.LimitsEmailInvocationsMax__c);
    System.Assert.isNull(logEntryEvent.LimitsFutureCallsMax__c);
    System.Assert.isNull(logEntryEvent.LimitsHeapSizeMax__c);
    System.Assert.isNull(logEntryEvent.LimitsMobilePushApexCallsMax__c);
    System.Assert.isNull(logEntryEvent.LimitsPublishImmediateDmlStatementsMax__c);
    System.Assert.isNull(logEntryEvent.LimitsQueueableJobsMax__c);
    System.Assert.isNull(logEntryEvent.LimitsSoqlQueriesMax__c);
    System.Assert.isNull(logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c);
    System.Assert.isNull(logEntryEvent.LimitsSoqlQueryRowsMax__c);
    System.Assert.isNull(logEntryEvent.LimitsSoslSearchesMax__c);
  }

  @IsTest
  static void it_should_not_run_authSession_query_when_disabled_via_logger_parameter() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryAuthSessionDataSynchronously', Value__c = String.valueOf(false)));
    System.Assert.isFalse(LoggerParameter.QUERY_AUTH_SESSION_DATA_SYNCHRONOUSLY);
    MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
    LoggerEngineDataSelector.setMock(mockSelector);
    Schema.User mockUser = LoggerMockDataCreator.createUser();
    mockSelector.setCachedUser(mockUser);
    System.Assert.areEqual(0, mockSelector.getCachedAuthSessionQueryCount());

    LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true).setMessage('some message').getLogEntryEvent();

    System.Assert.areEqual(0, mockSelector.getCachedAuthSessionQueryCount());
    System.Assert.isNull(logEntryEvent.LoginApplication__c);
    System.Assert.isNull(logEntryEvent.LoginBrowser__c);
    System.Assert.isNull(logEntryEvent.LoginHistoryId__c);
    System.Assert.isNull(logEntryEvent.LoginPlatform__c);
    System.Assert.isNull(logEntryEvent.LoginType__c);
    System.Assert.isNull(logEntryEvent.LogoutUrl__c);
    System.Assert.isNull(logEntryEvent.ParentSessionId__c);
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
    LoggerSObjectProxy.LoginHistory mockLoginHistoryProxy = new LoggerSObjectProxy.LoginHistory();
    mockLoginHistoryProxy.Application = 'Application';
    mockLoginHistoryProxy.Browser = 'Browser';
    mockLoginHistoryProxy.Platform = 'Platform';
    mockLoginHistoryProxy.UserId = System.UserInfo.getUserId();
    LoggerSObjectProxy.AuthSession mockAuthSessionProxy = new LoggerSObjectProxy.AuthSession();
    mockAuthSessionProxy.Id = LoggerMockDataCreator.createId(Schema.AuthSession.SObjectType);
    mockAuthSessionProxy.LoginHistory = mockLoginHistoryProxy;
    mockAuthSessionProxy.LoginHistoryId = LoggerMockDataCreator.createId(Schema.LoginHistory.SObjectType);
    mockAuthSessionProxy.LoginType = 'LoginType';
    mockAuthSessionProxy.LogoutUrl = 'LogoutUrl';
    mockAuthSessionProxy.ParentId = LoggerMockDataCreator.createId(Schema.AuthSession.SObjectType);
    mockAuthSessionProxy.SessionSecurityLevel = 'SessionSecurityLevel';
    mockAuthSessionProxy.SessionType = 'SessionType';
    mockAuthSessionProxy.SourceIp = 'SourceIp';
    mockAuthSessionProxy.UsersId = System.UserInfo.getUserId();
    mockSelector.setCachedAuthSessionProxy(mockAuthSessionProxy);
    System.Assert.areEqual(0, mockSelector.getCachedAuthSessionQueryCount());

    LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true).setMessage('some message').getLogEntryEvent();

    System.Assert.areEqual(1, mockSelector.getCachedAuthSessionQueryCount());
    System.Assert.areEqual(mockAuthSessionProxy.LoginHistory.Application, logEntryEvent.LoginApplication__c);
    System.Assert.areEqual(mockAuthSessionProxy.LoginHistory.Browser, logEntryEvent.LoginBrowser__c);
    System.Assert.areEqual(mockAuthSessionProxy.LoginHistory.Platform, logEntryEvent.LoginPlatform__c);
    System.Assert.areEqual(mockAuthSessionProxy.LoginHistoryId, logEntryEvent.LoginHistoryId__c);
    System.Assert.areEqual(mockAuthSessionProxy.LoginType, logEntryEvent.LoginType__c);
    System.Assert.areEqual(mockAuthSessionProxy.LogoutUrl, logEntryEvent.LogoutUrl__c);
    System.Assert.areEqual(mockAuthSessionProxy.ParentId, logEntryEvent.ParentSessionId__c);
    System.Assert.areEqual(mockAuthSessionProxy.Id, logEntryEvent.SessionId__c);
    System.Assert.areEqual(mockAuthSessionProxy.SessionSecurityLevel, logEntryEvent.SessionSecurityLevel__c);
    System.Assert.areEqual(mockAuthSessionProxy.SessionType, logEntryEvent.SessionType__c);
    System.Assert.areEqual(mockAuthSessionProxy.SourceIp, logEntryEvent.SourceIp__c);
  }

  @IsTest
  static void it_should_query_and_handle_authSession_when_logingHistory_is_null() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryAuthSessionDataSynchronously', Value__c = String.valueOf(true)));
    System.Assert.isTrue(LoggerParameter.QUERY_AUTH_SESSION_DATA_SYNCHRONOUSLY);
    MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
    LoggerEngineDataSelector.setMock(mockSelector);
    LoggerSObjectProxy.AuthSession mockAuthSessionProxy = new LoggerSObjectProxy.AuthSession();
    mockAuthSessionProxy.Id = LoggerMockDataCreator.createId(Schema.AuthSession.SObjectType);
    mockAuthSessionProxy.LoginHistory = null;
    mockAuthSessionProxy.LoginHistoryId = null;
    mockAuthSessionProxy.LoginType = 'LoginType';
    mockAuthSessionProxy.LogoutUrl = 'LogoutUrl';
    mockAuthSessionProxy.ParentId = LoggerMockDataCreator.createId(Schema.AuthSession.SObjectType);
    mockAuthSessionProxy.SessionSecurityLevel = 'SessionSecurityLevel';
    mockAuthSessionProxy.SessionType = 'SessionType';
    mockAuthSessionProxy.SourceIp = 'SourceIp';
    mockAuthSessionProxy.UsersId = System.UserInfo.getUserId();
    mockSelector.setCachedAuthSessionProxy(mockAuthSessionProxy);
    System.Assert.areEqual(0, mockSelector.getCachedAuthSessionQueryCount());

    LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true).setMessage('some message').getLogEntryEvent();

    System.Assert.areEqual(1, mockSelector.getCachedAuthSessionQueryCount());
    System.Assert.isNull(logEntryEvent.LoginApplication__c);
    System.Assert.isNull(logEntryEvent.LoginBrowser__c);
    System.Assert.isNull(logEntryEvent.LoginPlatform__c);
    System.Assert.isNull(logEntryEvent.LoginHistoryId__c);
    System.Assert.areEqual(mockAuthSessionProxy.LoginType, logEntryEvent.LoginType__c);
    System.Assert.areEqual(mockAuthSessionProxy.LogoutUrl, logEntryEvent.LogoutUrl__c);
    System.Assert.areEqual(mockAuthSessionProxy.ParentId, logEntryEvent.ParentSessionId__c);
    System.Assert.areEqual(mockAuthSessionProxy.Id, logEntryEvent.SessionId__c);
    System.Assert.areEqual(mockAuthSessionProxy.SessionSecurityLevel, logEntryEvent.SessionSecurityLevel__c);
    System.Assert.areEqual(mockAuthSessionProxy.SessionType, logEntryEvent.SessionType__c);
    System.Assert.areEqual(mockAuthSessionProxy.SourceIp, logEntryEvent.SourceIp__c);
  }

  @IsTest
  static void it_should_not_run_organization_query_when_disabled_via_logger_parameter() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryOrganizationDataSynchronously', Value__c = String.valueOf(false)));
    System.Assert.isFalse(LoggerParameter.QUERY_ORGANIZATION_DATA_SYNCHRONOUSLY);
    MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
    LoggerEngineDataSelector.setMock(mockSelector);
    System.Assert.areEqual(0, mockSelector.getCachedOrganizationQueryCount());

    LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true).setMessage('some message').getLogEntryEvent();

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

    LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true).setMessage('some message').getLogEntryEvent();

    System.Assert.areNotEqual(0, mockSelector.getCachedOrganizationQueryCount());
    Schema.Organization cachedOrganization = LoggerEngineDataSelector.getInstance().getCachedOrganization();
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
    Schema.User mockUser = LoggerMockDataCreator.createUser();
    mockSelector.setCachedUser(mockUser);
    System.Assert.areEqual(0, mockSelector.getCachedUserQueryCount());

    LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true).setMessage('some message').getLogEntryEvent();

    System.Assert.areEqual(0, mockSelector.getCachedUserQueryCount());
    System.Assert.isNull(logEntryEvent.LoggedByFederationIdentifier__c);
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
    Schema.User mockUser = LoggerMockDataCreator.createUser();
    mockSelector.setCachedUser(mockUser);
    System.Assert.areEqual(0, mockSelector.getCachedUserQueryCount());

    LogEntryEvent__e logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true).setMessage('some message').getLogEntryEvent();

    System.Assert.areNotEqual(0, mockSelector.getCachedUserQueryCount());
    Schema.User cachedUser = LoggerEngineDataSelector.getInstance().getCachedUser();
    System.Assert.areEqual(cachedUser.FederationIdentifier, logEntryEvent.LoggedByFederationIdentifier__c);
    System.Assert.areEqual(cachedUser.Profile.Name, logEntryEvent.ProfileName__c);
    System.Assert.areEqual(cachedUser.Profile.UserLicense.LicenseDefinitionKey, logEntryEvent.UserLicenseDefinitionKey__c);
    System.Assert.areEqual(cachedUser.Profile.UserLicenseId, logEntryEvent.UserLicenseId__c);
    System.Assert.areEqual(cachedUser.Profile.UserLicense.Name, logEntryEvent.UserLicenseName__c);
    System.Assert.areEqual(cachedUser.UserRole?.Name, logEntryEvent.UserRoleName__c);
  }

  @IsTest
  static void it_should_set_message_fields_for_logMessage() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
  static void it_should_truncate_message_field_when_string_is_too_long() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isFalse(builder.getLogEntryEvent().MessageTruncated__c);
    System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isNull(builder.getLogEntryEvent().Message__c);
    String excessivelyLongMessage = 'a'.repeat(Schema.LogEntryEvent__e.Message__c.getDescribe().getLength() + 1);

    builder.setMessage(excessivelyLongMessage);

    String expectedTruncatedMessage = excessivelyLongMessage.left(Schema.LogEntryEvent__e.Message__c.getDescribe().getLength());
    System.Assert.areNotEqual(expectedTruncatedMessage, excessivelyLongMessage);
    System.Assert.isTrue(builder.getLogEntryEvent().MessageTruncated__c);
    System.Assert.isFalse(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.areEqual(expectedTruncatedMessage, builder.getLogEntryEvent().Message__c);
  }

  @IsTest
  static void it_should_not_apply_data_mask_rule_when_rule_disabled() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = false;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    String message = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
    Schema.Account account = new Schema.Account(Name = message);
    String accountJson = System.JSON.serializePretty(account);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
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
    Schema.Account account = new Schema.Account(Name = message);
    String accountJson = System.JSON.serializePretty(account);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
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

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(sensitiveString);

    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.areNotEqual(sensitiveString, builder.getLogEntryEvent().Message__c);
    System.Assert.areEqual(expectedSanitizedString, builder.getLogEntryEvent().Message__c);
  }

  @IsTest
  static void it_should_properly_truncate_loooooong_message_when_data_mask_rule_is_applied() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    Integer fieldMaxLength = LogEntryEvent__e.Message__c.getDescribe().getLength();
    String sensitiveStringThatWillBeExpandedByDataMasking =
      'Here is my fake social 400119999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    String expectedSanitizedString =
      'Here is my fake social XXX-XX-9999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    System.Assert.isTrue(
      expectedSanitizedString.length() > sensitiveStringThatWillBeExpandedByDataMasking.length(),
      'Test has started under the wrong conditions!'
    );

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(sensitiveStringThatWillBeExpandedByDataMasking);

    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(builder.getLogEntryEvent().MessageTruncated__c);
    System.Assert.areNotEqual(sensitiveStringThatWillBeExpandedByDataMasking, builder.getLogEntryEvent().Message__c);
    System.Assert.areEqual(expectedSanitizedString.left(fieldMaxLength), builder.getLogEntryEvent().Message__c);
    System.Assert.areEqual(fieldMaxLength, builder.getLogEntryEvent().Message__c.length());
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
    Schema.Account account = new Schema.Account(Name = sensitiveString);
    String accountJson = System.JSON.serializePretty(account);
    String expectedSanitizedAccountJson = System.JSON.serializePretty(new Schema.Account(Name = expectedSanitizedString));

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setRecord(account);

    System.Assert.isTrue(builder.getLogEntryEvent().RecordJsonMasked__c);
    System.Assert.areNotEqual(accountJson, builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual(expectedSanitizedAccountJson, builder.getLogEntryEvent().RecordJson__c);
  }

  @IsTest
  static void it_should_properly_truncate_loooooong_record_json_when_data_mask_rule_is_applied() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    Integer fieldMaxLength = LogEntryEvent__e.RecordJson__c.getDescribe().getLength();
    String sensitiveStringThatWillBeExpandedByDataMasking =
      'Here is my fake social 400119999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    String expectedSanitizedString =
      'Here is my fake social XXX-XX-9999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    System.Assert.isTrue(
      expectedSanitizedString.length() > sensitiveStringThatWillBeExpandedByDataMasking.length(),
      'Test has started under the wrong conditions!'
    );
    Schema.Account account = new Schema.Account(Name = sensitiveStringThatWillBeExpandedByDataMasking);
    String expectedSanitizedAccountJson = System.JSON.serializePretty(new Schema.Account(Name = expectedSanitizedString));

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setRecord(account);

    System.Assert.isTrue(builder.getLogEntryEvent().RecordJsonMasked__c);
    System.Assert.isTrue(builder.getLogEntryEvent().RecordJsonTruncated__c);
    System.Assert.areNotEqual(sensitiveStringThatWillBeExpandedByDataMasking, builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual(expectedSanitizedAccountJson.left(fieldMaxLength), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual(fieldMaxLength, builder.getLogEntryEvent().RecordJson__c.length());
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
    List<Schema.Account> accounts = new List<Schema.Account>{ new Schema.Account(Name = sensitiveString) };
    String accountListJson = System.JSON.serializePretty(accounts);
    String expectedSanitizedAccountListJson = System.JSON.serializePretty(new List<Schema.Account>{ new Schema.Account(Name = expectedSanitizedString) });

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setRecord(accounts);

    System.Assert.isTrue(builder.getLogEntryEvent().RecordJsonMasked__c);
    System.Assert.areNotEqual(accountListJson, builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual(expectedSanitizedAccountListJson, builder.getLogEntryEvent().RecordJson__c);
  }

  @IsTest
  static void it_should_properly_truncate_loooooong_record_list_json_when_data_mask_rule_is_applied() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    Integer fieldMaxLength = LogEntryEvent__e.RecordJson__c.getDescribe().getLength();
    String sensitiveStringThatWillBeExpandedByDataMasking =
      'Here is my fake social 400119999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    String expectedSanitizedString =
      'Here is my fake social XXX-XX-9999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    System.Assert.isTrue(
      expectedSanitizedString.length() > sensitiveStringThatWillBeExpandedByDataMasking.length(),
      'Test has started under the wrong conditions!'
    );
    List<Schema.Account> accounts = new List<Schema.Account>{ new Schema.Account(Name = sensitiveStringThatWillBeExpandedByDataMasking) };
    String expectedSanitizedAccountListJson = System.JSON.serializePretty(new List<Schema.Account>{ new Schema.Account(Name = expectedSanitizedString) });

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setRecord(accounts);

    System.Assert.isTrue(builder.getLogEntryEvent().RecordJsonMasked__c);
    System.Assert.isTrue(builder.getLogEntryEvent().RecordJsonTruncated__c);
    System.Assert.areNotEqual(sensitiveStringThatWillBeExpandedByDataMasking, builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual(expectedSanitizedAccountListJson.left(fieldMaxLength), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual(fieldMaxLength, builder.getLogEntryEvent().RecordJson__c.length());
  }

  @IsTest
  static void it_should_apply_data_mask_rule_to_record_map_json_when_enabled() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    String sensitiveString = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
    String expectedSanitizedString = 'Something, something, and my social is XXX-XX-9999 in case you want to steal my identity';
    Id mockAccountId = LoggerMockDataCreator.createId(Schema.Account.SObjectType);
    Map<Id, Schema.Account> accountIdToAccount = new Map<Id, Schema.Account>{ mockAccountId => new Schema.Account(Name = sensitiveString) };
    String accountMapJson = System.JSON.serializePretty(accountIdToAccount);
    String expectedSanitizedAccountMapJson = System.JSON.serializePretty(
      new Map<Id, Schema.Account>{ mockAccountId => new Schema.Account(Name = expectedSanitizedString) }
    );

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setRecord(accountIdToAccount);

    System.Assert.isTrue(builder.getLogEntryEvent().RecordJsonMasked__c);
    System.Assert.areNotEqual(accountMapJson, builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual(expectedSanitizedAccountMapJson, builder.getLogEntryEvent().RecordJson__c);
  }

  @IsTest
  static void it_should_properly_truncate_loooooong_record_map_json_when_data_mask_rule_is_applied() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    Integer fieldMaxLength = LogEntryEvent__e.RecordJson__c.getDescribe().getLength();
    String sensitiveStringThatWillBeExpandedByDataMasking =
      'Here is my fake social 400119999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    String expectedSanitizedString =
      'Here is my fake social XXX-XX-9999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    System.Assert.isTrue(
      expectedSanitizedString.length() > sensitiveStringThatWillBeExpandedByDataMasking.length(),
      'Test has started under the wrong conditions!'
    );
    Id mockAccountId = LoggerMockDataCreator.createId(Schema.Account.SObjectType);
    Map<Id, Schema.Account> accountIdToAccount = new Map<Id, Schema.Account>{
      mockAccountId => new Schema.Account(Name = sensitiveStringThatWillBeExpandedByDataMasking)
    };
    String expectedSanitizedAccountMapJson = System.JSON.serializePretty(
      new Map<Id, Schema.Account>{ mockAccountId => new Schema.Account(Name = expectedSanitizedString) }
    );

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setRecord(accountIdToAccount);

    System.Assert.isTrue(builder.getLogEntryEvent().RecordJsonMasked__c);
    System.Assert.isTrue(builder.getLogEntryEvent().RecordJsonTruncated__c);
    System.Assert.areNotEqual(sensitiveStringThatWillBeExpandedByDataMasking, builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual(expectedSanitizedAccountMapJson.left(fieldMaxLength), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual(fieldMaxLength, builder.getLogEntryEvent().RecordJson__c.length());
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

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setHttpRequestDetails(httpRequest);

    System.Assert.isTrue(builder.getLogEntryEvent().HttpRequestBodyMasked__c);
    System.Assert.areNotEqual(sensitiveString, builder.getLogEntryEvent().HttpRequestBody__c);
    System.Assert.areEqual(expectedSanitizedString, builder.getLogEntryEvent().HttpRequestBody__c);
  }

  @IsTest
  static void it_should_properly_truncate_loooooong_record_http_request_body_when_data_mask_rule_is_applied() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    Integer fieldMaxLength = LogEntryEvent__e.HttpRequestBody__c.getDescribe().getLength();
    String sensitiveStringThatWillBeExpandedByDataMasking =
      'Here is my fake social 400119999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    String expectedSanitizedString =
      'Here is my fake social XXX-XX-9999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    System.Assert.isTrue(
      expectedSanitizedString.length() > sensitiveStringThatWillBeExpandedByDataMasking.length(),
      'Test has started under the wrong conditions!'
    );
    System.HttpRequest httpRequest = LoggerMockDataCreator.createHttpRequest();
    httpRequest.setBody(sensitiveStringThatWillBeExpandedByDataMasking);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setHttpRequestDetails(httpRequest);

    System.Assert.isTrue(builder.getLogEntryEvent().HttpRequestBodyMasked__c);
    System.Assert.isTrue(builder.getLogEntryEvent().HttpRequestBodyTruncated__c);
    System.Assert.areNotEqual(sensitiveStringThatWillBeExpandedByDataMasking, builder.getLogEntryEvent().HttpRequestBody__c);
    System.Assert.areEqual(expectedSanitizedString.left(fieldMaxLength), builder.getLogEntryEvent().HttpRequestBody__c);
    System.Assert.areEqual(fieldMaxLength, builder.getLogEntryEvent().HttpRequestBody__c.length());
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

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setHttpResponseDetails(httpResponse);

    System.Assert.isTrue(builder.getLogEntryEvent().HttpResponseBodyMasked__c);
    System.Assert.areNotEqual(sensitiveString, builder.getLogEntryEvent().HttpResponseBody__c);
    System.Assert.areEqual(expectedSanitizedString, builder.getLogEntryEvent().HttpResponseBody__c);
  }

  @IsTest
  static void it_should_properly_truncate_loooooong_record_http_response_body_when_data_mask_rule_is_applied() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    Integer fieldMaxLength = LogEntryEvent__e.HttpResponseBody__c.getDescribe().getLength();
    String sensitiveStringThatWillBeExpandedByDataMasking =
      'Here is my fake social 400119999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    String expectedSanitizedString =
      'Here is my fake social XXX-XX-9999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    System.Assert.isTrue(
      expectedSanitizedString.length() > sensitiveStringThatWillBeExpandedByDataMasking.length(),
      'Test has started under the wrong conditions!'
    );
    System.HttpResponse httpResponse = LoggerMockDataCreator.createHttpResponse();
    httpResponse.setBody(sensitiveStringThatWillBeExpandedByDataMasking);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setHttpResponseDetails(httpResponse);

    System.Assert.isTrue(builder.getLogEntryEvent().HttpResponseBodyMasked__c);
    System.Assert.isTrue(builder.getLogEntryEvent().HttpResponseBodyTruncated__c);
    System.Assert.areNotEqual(sensitiveStringThatWillBeExpandedByDataMasking, builder.getLogEntryEvent().HttpResponseBody__c);
    System.Assert.areEqual(expectedSanitizedString.left(fieldMaxLength), builder.getLogEntryEvent().HttpResponseBody__c);
    System.Assert.areEqual(fieldMaxLength, builder.getLogEntryEvent().HttpResponseBody__c.length());
  }

  @IsTest
  static void it_should_apply_data_mask_rule_to_rest_request_body_when_enabled() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    String sensitiveString = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
    String expectedSanitizedString = 'Something, something, and my social is XXX-XX-9999 in case you want to steal my identity';
    System.RestRequest restRequest = new System.RestRequest();
    restRequest.requestBody = Blob.valueOf(sensitiveString);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setRestRequestDetails(restRequest);

    System.Assert.isTrue(builder.getLogEntryEvent().RestRequestBodyMasked__c);
    System.Assert.areNotEqual(sensitiveString, builder.getLogEntryEvent().RestRequestBody__c);
    System.Assert.areEqual(expectedSanitizedString, builder.getLogEntryEvent().RestRequestBody__c);
  }

  @IsTest
  static void it_should_properly_truncate_loooooong_record_rest_request_body_when_data_mask_rule_is_applied() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    Integer fieldMaxLength = LogEntryEvent__e.RestRequestBody__c.getDescribe().getLength();
    String sensitiveStringThatWillBeExpandedByDataMasking =
      'Here is my fake social 400119999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    String expectedSanitizedString =
      'Here is my fake social XXX-XX-9999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    System.Assert.isTrue(
      expectedSanitizedString.length() > sensitiveStringThatWillBeExpandedByDataMasking.length(),
      'Test has started under the wrong conditions!'
    );
    System.RestRequest restRequest = new System.RestRequest();
    restRequest.requestBody = Blob.valueOf(sensitiveStringThatWillBeExpandedByDataMasking);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setRestRequestDetails(restRequest);

    System.Assert.isTrue(builder.getLogEntryEvent().RestRequestBodyMasked__c);
    System.Assert.isTrue(builder.getLogEntryEvent().RestRequestBodyTruncated__c);
    System.Assert.areNotEqual(sensitiveStringThatWillBeExpandedByDataMasking, builder.getLogEntryEvent().RestRequestBody__c);
    System.Assert.areEqual(expectedSanitizedString.left(fieldMaxLength), builder.getLogEntryEvent().RestRequestBody__c);
    System.Assert.areEqual(fieldMaxLength, builder.getLogEntryEvent().RestRequestBody__c.length());
  }

  @IsTest
  static void it_should_apply_data_mask_rule_to_rest_response_body_when_enabled() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    String sensitiveString = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
    String expectedSanitizedString = 'Something, something, and my social is XXX-XX-9999 in case you want to steal my identity';
    System.RestResponse restResponse = new System.RestResponse();
    restResponse.responseBody = Blob.valueOf(sensitiveString);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setRestResponseDetails(restResponse);

    System.Assert.isTrue(builder.getLogEntryEvent().RestResponseBodyMasked__c);
    System.Assert.areNotEqual(sensitiveString, builder.getLogEntryEvent().RestResponseBody__c);
    System.Assert.areEqual(expectedSanitizedString, builder.getLogEntryEvent().RestResponseBody__c);
  }

  @IsTest
  static void it_should_properly_truncate_loooooong_record_rest_response_body_when_data_mask_rule_is_applied() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    Integer fieldMaxLength = LogEntryEvent__e.RestResponseBody__c.getDescribe().getLength();
    String sensitiveStringThatWillBeExpandedByDataMasking =
      'Here is my fake social 400119999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    String expectedSanitizedString =
      'Here is my fake social XXX-XX-9999. Since it doesn\'t have dashes or spaces, and the regex will add dashes, the resulting string would have been too long in previous releases. ' +
      'A'.repeat(fieldMaxLength);
    System.Assert.isTrue(
      expectedSanitizedString.length() > sensitiveStringThatWillBeExpandedByDataMasking.length(),
      'Test has started under the wrong conditions!'
    );
    System.RestResponse restResponse = new System.RestResponse();
    restResponse.responseBody = Blob.valueOf(sensitiveStringThatWillBeExpandedByDataMasking);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setRestResponseDetails(restResponse);

    System.Assert.isTrue(builder.getLogEntryEvent().RestResponseBodyMasked__c);
    System.Assert.isTrue(builder.getLogEntryEvent().RestResponseBodyTruncated__c);
    System.Assert.areNotEqual(sensitiveStringThatWillBeExpandedByDataMasking, builder.getLogEntryEvent().RestResponseBody__c);
    System.Assert.areEqual(expectedSanitizedString.left(fieldMaxLength), builder.getLogEntryEvent().RestResponseBody__c);
    System.Assert.areEqual(fieldMaxLength, builder.getLogEntryEvent().RestResponseBody__c.length());
  }

  @IsTest
  static void it_should_truncate_message_for_long_logMessage() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().ExceptionMessage__c);
    System.Assert.isNull(builder.getLogEntryEvent().ExceptionType__c);

    System.Exception nullException;
    builder.setExceptionDetails(nullException);

    System.Assert.isNull(builder.getLogEntryEvent().ExceptionMessage__c);
    System.Assert.isNull(builder.getLogEntryEvent().ExceptionType__c);
  }

  @IsTest
  static void it_should_set_exception_fields_for_dmlException() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().ExceptionMessage__c);
    System.Assert.isNull(builder.getLogEntryEvent().ExceptionType__c);

    System.DmlException dmlException = new System.DmlException('Test DML exception');
    builder.setExceptionDetails(dmlException);

    System.Assert.areEqual(dmlException.getMessage(), builder.getLogEntryEvent().ExceptionMessage__c);
    System.Assert.areEqual(dmlException.getTypeName(), builder.getLogEntryEvent().ExceptionType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_approval_lockResult() {
    Approval.LockResult lockResult = LoggerMockDataCreator.createApprovalLockResult(true);
    System.Assert.isNotNull(lockResult);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setApprovalResult(lockResult);

    System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(lockResult), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Approval.LockResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_approval_processResult() {
    Approval.ProcessResult processResult = LoggerMockDataCreator.createApprovalProcessResult(true);
    System.Assert.isNotNull(processResult);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setApprovalResult(processResult);

    System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(processResult), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Approval.ProcessResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_approval_unlockResult() {
    Approval.UnlockResult unlockResult = LoggerMockDataCreator.createApprovalUnlockResult(true);
    System.Assert.isNotNull(unlockResult);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setApprovalResult(unlockResult);

    System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(unlockResult), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Approval.UnlockResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_list_of_approval_lockResult() {
    List<Approval.LockResult> lockResults = new List<Approval.LockResult>();
    for (Integer i = 0; i < 5; i++) {
      lockResults.add(LoggerMockDataCreator.createApprovalLockResult(false));
    }

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setApprovalResult(lockResults);

    System.Assert.areEqual(lockResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(lockResults), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Approval.LockResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_list_of_approval_processResult() {
    List<Approval.ProcessResult> processResults = new List<Approval.ProcessResult>();
    for (Integer i = 0; i < 5; i++) {
      processResults.add(LoggerMockDataCreator.createApprovalProcessResult(false));
    }

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setApprovalResult(processResults);

    System.Assert.areEqual(processResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(processResults), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Approval.ProcessResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_list_of_approval_unlockResult() {
    List<Approval.UnlockResult> unlockResults = new List<Approval.UnlockResult>();
    for (Integer i = 0; i < 5; i++) {
      unlockResults.add(LoggerMockDataCreator.createApprovalUnlockResult(false));
    }

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setApprovalResult(unlockResults);

    System.Assert.areEqual(unlockResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(unlockResults), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Approval.UnlockResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_deleteResult() {
    Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);
    System.Assert.isNotNull(deleteResult);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(deleteResult);

    System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(deleteResult), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.DeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_emptyRecycleBinResult() {
    Database.EmptyRecycleBinResult emptyRecycleBinResult = LoggerMockDataCreator.createDatabaseEmptyRecycleBinResult(true);
    System.Assert.isNotNull(emptyRecycleBinResult);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(emptyRecycleBinResult);

    System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(emptyRecycleBinResult), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.EmptyRecycleBinResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_leadConvertResult() {
    Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);
    System.Assert.isNotNull(leadConvertResult);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(leadConvertResult);

    System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(leadConvertResult), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.LeadConvertResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_mergeResult() {
    Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);
    System.Assert.isNotNull(mergeResult);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(mergeResult);

    System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(mergeResult), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.MergeResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_saveResult() {
    Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);
    System.Assert.isNotNull(saveResult);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(saveResult);

    System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(saveResult), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.SaveResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_undeleteResult() {
    Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);
    System.Assert.isNotNull(undeleteResult);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(undeleteResult);

    System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(undeleteResult), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.UndeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_upsertResult_when_insert() {
    Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);
    System.Assert.isNotNull(upsertResult);
    System.Assert.isTrue(upsertResult.isCreated());

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(upsertResult);

    System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(upsertResult), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_upsertResult_when_update() {
    Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);
    System.Assert.isNotNull(upsertResult);
    System.Assert.isFalse(upsertResult.isCreated());

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(upsertResult);

    System.Assert.areEqual(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(upsertResult), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Update', builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_list_of_deleteResult() {
    List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>();
    for (Integer i = 0; i < 5; i++) {
      deleteResults.add(LoggerMockDataCreator.createDatabaseDeleteResult(false));
    }

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(deleteResults);

    System.Assert.areEqual(deleteResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(deleteResults), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.DeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_list_of_emptyRecycleBinResult() {
    List<Database.EmptyRecycleBinResult> emptyRecycleBinResults = new List<Database.EmptyRecycleBinResult>();
    for (Integer i = 0; i < 5; i++) {
      emptyRecycleBinResults.add(LoggerMockDataCreator.createDatabaseEmptyRecycleBinResult(false));
    }

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(emptyRecycleBinResults);

    System.Assert.areEqual(emptyRecycleBinResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(emptyRecycleBinResults), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.EmptyRecycleBinResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_list_of_leadConvertResult() {
    List<Database.LeadConvertResult> leadConvertResults = new List<Database.LeadConvertResult>();
    for (Integer i = 0; i < 5; i++) {
      leadConvertResults.add(LoggerMockDataCreator.createDatabaseLeadConvertResult(false));
    }

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(leadConvertResults);

    System.Assert.areEqual(leadConvertResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(leadConvertResults), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.LeadConvertResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_list_of_mergeResult() {
    List<Database.MergeResult> mergeResults = new List<Database.MergeResult>();
    for (Integer i = 0; i < 5; i++) {
      mergeResults.add(LoggerMockDataCreator.createDatabaseMergeResult(false));
    }

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(mergeResults);

    System.Assert.areEqual(mergeResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(mergeResults), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.MergeResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_list_of_saveResult() {
    List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
    for (Integer i = 0; i < 5; i++) {
      saveResults.add(LoggerMockDataCreator.createDatabaseSaveResult(false));
    }

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(saveResults);

    System.Assert.areEqual(saveResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(saveResults), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.SaveResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_list_of_undeleteResult() {
    List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>();
    for (Integer i = 0; i < 5; i++) {
      undeleteResults.add(LoggerMockDataCreator.createDatabaseUndeleteResult(false));
    }

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(undeleteResults);

    System.Assert.areEqual(undeleteResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(undeleteResults), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.UndeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_database_result_fields_for_list_of_upsertResult() {
    List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>();
    for (Integer i = 0; i < 5; i++) {
      upsertResults.add(LoggerMockDataCreator.createDatabaseUpsertResult(false, false));
    }

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    builder.setDatabaseResult(upsertResults);

    System.Assert.areEqual(upsertResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(upsertResults), builder.getLogEntryEvent().DatabaseResultJson__c);
    System.Assert.areEqual(Database.UpsertResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_recordId_when_standard_object() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    System.Assert.areEqual(Log__c.SObjectType.toString(), builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_recordId_when_custom_metadata_type() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    System.Assert.areEqual(LogStatus__mdt.SObjectType.toString(), builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_record_when_null() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

    Schema.User nullUser;
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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

    Schema.User currentUser = [SELECT Id, Name, ProfileId, Profile.Name, IsActive FROM User WHERE Id = :System.UserInfo.getUserId()];
    builder.setRecordId(currentUser);

    System.Assert.areEqual(1, builder.getLogEntryEvent().RecordCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().RecordCollectionType__c);
    System.Assert.areEqual(currentUser.Id, builder.getLogEntryEvent().RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(currentUser), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual('User', builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_record_when_custom_object() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    System.Assert.areEqual(System.JSON.serializePretty(log), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Custom Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual(Log__c.SObjectType.toString(), builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_record_when_custom_metadata_type() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    System.Assert.areEqual(System.JSON.serializePretty(status), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Custom Metadata Type Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual(LogStatus__mdt.SObjectType.toString(), builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_record_when_unpublished_platform_event() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

    // To avoid creating a new platform event just for testing purposes, Nebula Logger's LogEntryEvent__e is reused
    LogEntryEvent__e unpublishedPlatformEvent = new LogEntryEvent__e();
    builder.setRecordId(unpublishedPlatformEvent);

    System.Assert.areEqual(1, builder.getLogEntryEvent().RecordCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().RecordCollectionType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(unpublishedPlatformEvent), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Platform Event Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual(LogEntryEvent__e.SObjectType.toString(), builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_record_when_published_platform_event() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

    // To avoid creating a new platform event just for testing purposes, Nebula Logger's LogEntryEvent__e is reused
    LogEntryEvent__e publishedPlatformEvent = new LogEntryEvent__e();
    LoggerMockDataCreator.createDataBuilder(publishedPlatformEvent).populateRequiredFields();
    System.EventBus.publish(publishedPlatformEvent);
    System.Test.getEventBus().deliver();
    builder.setRecordId(publishedPlatformEvent);

    System.Assert.areEqual(1, builder.getLogEntryEvent().RecordCollectionSize__c);
    System.Assert.areEqual('Single', builder.getLogEntryEvent().RecordCollectionType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(publishedPlatformEvent), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Platform Event Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual(LogEntryEvent__e.SObjectType.toString(), builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_skip_stripping_inaccessible_fields_for_aggregate_result() {
    Schema.User standardUser = LoggerMockDataCreator.createUser();
    AggregateResult mockAggregateResult = LoggerMockDataCreator.createAggregateResult();

    LogEntryEventBuilder builder;
    System.runAs(standardUser) {
      LoggerSettings__c userSettings = getUserSettings();
      userSettings.IsRecordFieldStrippingEnabled__c = true;
      builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true).setRecord(mockAggregateResult);
    }

    System.Assert.areEqual(System.JSON.serializePretty(mockAggregateResult), builder.getLogEntryEvent().RecordJson__c);
  }

  @IsTest
  static void it_should_skip_stripping_inaccessible_fields_for_aggregate_results() {
    Schema.User standardUser = LoggerMockDataCreator.createUser();
    List<AggregateResult> mockAggregateResults = new List<AggregateResult>{ LoggerMockDataCreator.createAggregateResult() };

    LogEntryEventBuilder builder;
    System.runAs(standardUser) {
      LoggerSettings__c userSettings = getUserSettings();
      userSettings.IsRecordFieldStrippingEnabled__c = true;
      builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true).setRecord(mockAggregateResults);
    }

    System.Assert.areEqual(System.JSON.serializePretty(mockAggregateResults), builder.getLogEntryEvent().RecordJson__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_list_of_records_when_list_is_null() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    System.Assert.areEqual(System.JSON.serializePretty(users), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_list_of_records_when_first_record_is_null() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

    List<SObject> users = new List<SObject>();
    Schema.User nullUser;
    users.add(nullUser);
    users.add(new Schema.User(Id = System.UserInfo.getUserId()));
    builder.setRecord(users);

    System.Assert.areEqual('List', builder.getLogEntryEvent().RecordCollectionType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(users), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_list_of_records_when_populated() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

    List<Schema.User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
    builder.setRecord(users);

    System.Assert.areEqual('List', builder.getLogEntryEvent().RecordCollectionType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(users), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual(Schema.User.SObjectType.toString(), builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_map_of_sobject_records_when_map_is_null() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    System.Assert.areEqual(System.JSON.serializePretty(userIdToUser), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_map_of_sobject_records_when_map_contains_null_key() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

    Map<Id, SObject> userIdToUser = new Map<Id, SObject>{ null => new Schema.User(Id = System.UserInfo.getUserId()) };
    builder.setRecord(userIdToUser);

    Map<String, SObject> userIdStringToUser = new Map<String, SObject>{ '' => userIdToUser.get(null) };
    System.Assert.areEqual(userIdToUser.size(), builder.getLogEntryEvent().RecordCollectionSize__c);
    System.Assert.areEqual('Map', builder.getLogEntryEvent().RecordCollectionType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(userIdStringToUser), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual('User', builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_map_of_sobject_records_when_first_record_is_null() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

    Id mockUserId = LoggerMockDataCreator.createId(Schema.User.SObjectType);
    Schema.User nullUser;
    Map<Id, SObject> userIdToUser = new Map<Id, SObject>{
      mockUserId => nullUser,
      System.UserInfo.getUserId() => new Schema.User(Id = System.UserInfo.getUserId(), Username = System.UserInfo.getUsername())
    };
    builder.setRecord(userIdToUser);

    String expectedJson = System.JSON.serializePretty(userIdToUser);
    System.Assert.areEqual(userIdToUser.size(), builder.getLogEntryEvent().RecordCollectionSize__c);
    System.Assert.areEqual('Map', builder.getLogEntryEvent().RecordCollectionType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.areEqual(expectedJson, builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_map_of_user_records_when_populated() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

    Map<Id, Schema.User> userIdToUser = new Map<Id, Schema.User>([SELECT Id, Name, Username, IsActive FROM User LIMIT 5]);
    builder.setRecord(userIdToUser);

    System.Assert.areEqual(userIdToUser.size(), builder.getLogEntryEvent().RecordCollectionSize__c);
    System.Assert.areEqual('Map', builder.getLogEntryEvent().RecordCollectionType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(userIdToUser), builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual(Schema.User.SObjectType.toString(), builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_iterable_ids_when_null() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

    System.Iterable<Id> nullIterableIds = null;
    builder.setRecord(nullIterableIds);

    System.Assert.isNull(builder.getLogEntryEvent().RecordCollectionSize__c);
    System.Assert.areEqual('List', builder.getLogEntryEvent().RecordCollectionType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.areEqual('null', builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_list_of_id_records_when_populated() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

    List<Id> userIdList = new List<Id>(new Map<Id, Schema.User>([SELECT Id, Name, Username, IsActive FROM User LIMIT 5]).keySet());
    builder.setRecord(userIdList);

    System.Assert.areEqual(userIdList.size(), builder.getLogEntryEvent().RecordCollectionSize__c);
    System.Assert.areEqual('List', builder.getLogEntryEvent().RecordCollectionType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNotNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_set_record_fields_for_set_of_id_records_when_populated() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

    Set<Id> userIdSet = new Map<Id, Schema.User>([SELECT Id, Name, Username, IsActive FROM User LIMIT 5]).keySet();
    builder.setRecord(userIdSet);

    System.Assert.areEqual(userIdSet.size(), builder.getLogEntryEvent().RecordCollectionSize__c);
    System.Assert.areEqual('List', builder.getLogEntryEvent().RecordCollectionType__c);
    System.Assert.isNull(builder.getLogEntryEvent().RecordId__c);
    System.Assert.isNotNull(builder.getLogEntryEvent().RecordJson__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
    System.Assert.areEqual('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
  }

  @IsTest
  static void it_should_skip_setting_http_request_fields_when_request_is_null() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    LogEntryEvent__e event = builder.getLogEntryEvent();
    System.Assert.isNull(event.HttpRequestBody__c);
    System.Assert.isNull(event.HttpRequestEndpoint__c);
    System.Assert.isNull(event.HttpRequestHeaderKeys__c);
    System.Assert.isNull(event.HttpRequestHeaders__c);
    System.Assert.isNull(event.HttpRequestMethod__c);
    System.HttpRequest request = new System.HttpRequest();
    request.setBody('Hello, world!');
    request.setCompressed(true);

    String reallyLongEndpointAddress = 'https://fake.salesforce.com/' + 'A'.repeat(LogEntryEvent__e.HttpRequestEndpoint__c.getDescribe().getLength() + 1);
    request.setEndpoint(reallyLongEndpointAddress);
    request.setMethod('GET');

    builder.setHttpRequestDetails(request);

    System.Assert.areEqual(request.getBody(), event.HttpRequestBody__c);
    System.Assert.areEqual(request.getCompressed(), event.HttpRequestCompressed__c);
    System.Assert.areEqual(reallyLongEndpointAddress.left(LogEntryEvent__e.HttpRequestEndpoint__c.getDescribe().getLength()), event.HttpRequestEndpoint__c);
    System.Assert.areEqual(
      reallyLongEndpointAddress.left(LogEntryEvent__e.HttpRequestEndpointAddress__c.getDescribe().getLength()),
      event.HttpRequestEndpointAddress__c
    );
    System.Assert.isNull(event.HttpRequestHeaderKeys__c);
    System.Assert.isNull(event.HttpRequestHeaders__c);
    System.Assert.areEqual(request.getMethod(), event.HttpRequestMethod__c);
  }

  @IsTest
  static void it_should_set_http_request_fields_when_header_keys_are_provided_and_storing_header_values_is_enabled() {
    LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'StoreHttpRequestHeaderValues', Value__c = String.valueOf(true));
    LoggerParameter.setMock(mockParameter);
    System.Assert.isTrue(LoggerParameter.STORE_HTTP_REQUEST_HEADER_VALUES);
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    LogEntryEvent__e event = builder.getLogEntryEvent();
    System.Assert.isNull(event.HttpRequestBody__c);
    System.Assert.isNull(event.HttpRequestEndpoint__c);
    System.Assert.isNull(event.HttpRequestHeaderKeys__c);
    System.Assert.isNull(event.HttpRequestHeaders__c);
    System.Assert.isNull(event.HttpRequestMethod__c);
    System.HttpRequest request = new System.HttpRequest();
    request.setBody('Hello, world!');
    request.setCompressed(true);
    request.setEndpoint('https://fake.salesforce.com');
    request.setHeader('header-1-to-log', 'some value to log');
    request.setHeader('a-header-to-ignore', 'ignore this value, it won\'t be logged');
    request.setHeader('header-2-to-log', 'another value to log');
    request.setHeader('another-header-to-ignore', 'ignore this too');
    request.setMethod('GET');

    builder.setHttpRequestDetails(request, new List<String>{ 'header-1-to-log', 'header-2-to-log' });

    System.Assert.areEqual(request.getBody(), event.HttpRequestBody__c);
    System.Assert.areEqual(request.getCompressed(), event.HttpRequestCompressed__c);
    System.Assert.areEqual(request.getEndpoint(), event.HttpRequestEndpoint__c);
    System.Assert.areEqual('header-1-to-log\nheader-2-to-log', event.HttpRequestHeaderKeys__c);
    System.Assert.areEqual('header-1-to-log: some value to log\nheader-2-to-log: another value to log', event.HttpRequestHeaders__c);
    System.Assert.areEqual(request.getMethod(), event.HttpRequestMethod__c);
  }

  @IsTest
  static void it_should_set_http_request_fields_when_header_keys_are_provided_and_storing_header_values_is_disabled() {
    LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'StoreHttpRequestHeaderValues', Value__c = String.valueOf(false));
    LoggerParameter.setMock(mockParameter);
    System.Assert.isFalse(LoggerParameter.STORE_HTTP_REQUEST_HEADER_VALUES);
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    LogEntryEvent__e event = builder.getLogEntryEvent();
    System.Assert.isNull(event.HttpRequestBody__c);
    System.Assert.isNull(event.HttpRequestEndpoint__c);
    System.Assert.isNull(event.HttpRequestHeaderKeys__c);
    System.Assert.isNull(event.HttpRequestHeaders__c);
    System.Assert.isNull(event.HttpRequestMethod__c);
    System.HttpRequest request = new System.HttpRequest();
    request.setBody('Hello, world!');
    request.setCompressed(true);
    request.setEndpoint('https://fake.salesforce.com');
    request.setHeader('header-1-to-log', 'some value to log');
    request.setHeader('a-header-to-ignore', 'ignore this value, it won\'t be logged');
    request.setHeader('header-2-to-log', 'another value to log');
    request.setHeader('another-header-to-ignore', 'ignore this too');
    request.setMethod('GET');

    builder.setHttpRequestDetails(request, new List<String>{ 'header-1-to-log', 'header-2-to-log' });

    System.Assert.areEqual(request.getBody(), event.HttpRequestBody__c);
    System.Assert.areEqual(request.getCompressed(), event.HttpRequestCompressed__c);
    System.Assert.areEqual(request.getEndpoint(), event.HttpRequestEndpoint__c);
    System.Assert.areEqual('header-1-to-log\nheader-2-to-log', event.HttpRequestHeaderKeys__c);
    System.Assert.isNull(event.HttpRequestHeaders__c);
    System.Assert.areEqual(request.getMethod(), event.HttpRequestMethod__c);
  }

  @IsTest
  static void it_should_truncate_http_request_body_field_when_string_is_too_long() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().HttpRequestBody__c);
    String excessivelyLongRequestBody = 'a'.repeat(Schema.LogEntryEvent__e.HttpRequestBody__c.getDescribe().getLength() + 1);
    System.HttpRequest request = new System.HttpRequest();
    request.setBody(excessivelyLongRequestBody);

    builder.setHttpRequestDetails(request);

    System.Assert.areEqual(
      excessivelyLongRequestBody.left(Schema.LogEntryEvent__e.HttpRequestBody__c.getDescribe().getLength()),
      builder.getLogEntryEvent().HttpRequestBody__c,
      'Expected string length ' +
        Schema.LogEntryEvent__e.HttpRequestBody__c.getDescribe().getLength() +
        ' for field HttpRequestBody__c, actual length is ' +
        builder.getLogEntryEvent().HttpRequestBody__c.length()
    );
  }

  @IsTest
  static void it_should_skip_setting_http_response_fields_when_response_is_null() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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
  static void it_should_truncate_http_response_body_field_when_string_is_too_long() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().HttpResponseBody__c);
    String excessivelyLongResponseBody = 'a'.repeat(Schema.LogEntryEvent__e.HttpResponseBody__c.getDescribe().getLength() + 1);
    System.HttpResponse response = new System.HttpResponse();
    response.setBody(excessivelyLongResponseBody);

    builder.setHttpResponseDetails(response);

    System.Assert.areEqual(
      excessivelyLongResponseBody.left(Schema.LogEntryEvent__e.HttpResponseBody__c.getDescribe().getLength()),
      builder.getLogEntryEvent().HttpResponseBody__c,
      'Expected string length ' +
        Schema.LogEntryEvent__e.HttpResponseBody__c.getDescribe().getLength() +
        ' for field HttpResponseBody__c, actual length is ' +
        builder.getLogEntryEvent().HttpResponseBody__c.length()
    );
  }

  @IsTest
  static void it_should_skip_setting_rest_response_fields_when_response_is_null() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseBody__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseHeaderKeys__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseHeaders__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseStatusCode__c);
    System.RestResponse response = null;

    builder.setRestResponseDetails(response);

    System.Assert.isNull(builder.getLogEntryEvent().RestResponseBody__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseHeaderKeys__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseHeaders__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseStatusCode__c);
  }

  @IsTest
  static void it_should_set_rest_request_fields_when_storing_header_values_is_enabled() {
    LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'StoreRestRequestHeaderValues', Value__c = String.valueOf(true));
    LoggerParameter.setMock(mockParameter);
    System.Assert.isTrue(LoggerParameter.STORE_Rest_REQUEST_HEADER_VALUES);
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestBody__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestHeaderKeys__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestHeaders__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestMethod__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestParameters__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestRemoteAddress__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestResourcePath__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestUri__c);
    System.RestRequest request = new System.RestRequest();
    request.httpMethod = 'GET';
    request.remoteAddress = '1.1.1.1';
    request.requestBody = Blob.valueOf('{hello:"world"}');
    request.requestURI = 'some-uri-value';
    request.resourcePath = '/some/resource/path';
    request.addHeader('some-header', 'some value');
    request.addParameter('some-parameter', 'some value');

    builder.setRestRequestDetails(request);

    List<String> formattedHeaders = new List<String>();
    for (String headerKey : request.headers.keySet()) {
      formattedHeaders.add(headerKey + ': ' + request.headers.get(headerKey));
    }
    List<String> formattedParameters = new List<String>();
    for (String parameterKey : request.params.keySet()) {
      formattedParameters.add(parameterKey + ': ' + request.params.get(parameterKey));
    }
    System.Assert.areEqual(request.requestBody.toString(), builder.getLogEntryEvent().RestRequestBody__c);
    System.Assert.areEqual(String.join(request.headers.keySet(), '\n'), builder.getLogEntryEvent().RestRequestHeaderKeys__c);
    System.Assert.areEqual(String.join(formattedHeaders, '\n'), builder.getLogEntryEvent().RestRequestHeaders__c);
    System.Assert.areEqual(request.httpMethod, builder.getLogEntryEvent().RestRequestMethod__c);
    System.Assert.areEqual(String.join(formattedParameters, '\n'), builder.getLogEntryEvent().RestRequestParameters__c);
    System.Assert.areEqual(request.remoteAddress, builder.getLogEntryEvent().RestRequestRemoteAddress__c);
    System.Assert.areEqual(request.resourcePath, builder.getLogEntryEvent().RestRequestResourcePath__c);
    System.Assert.areEqual(request.requestUri, builder.getLogEntryEvent().RestRequestUri__c);
  }

  @IsTest
  static void it_should_set_rest_request_fields_when_storing_header_values_is_disabled() {
    LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'StoreRestRequestHeaderValues', Value__c = String.valueOf(false));
    LoggerParameter.setMock(mockParameter);
    System.Assert.isFalse(LoggerParameter.STORE_REST_REQUEST_HEADER_VALUES);
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestBody__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestHeaderKeys__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestHeaders__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestMethod__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestParameters__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestRemoteAddress__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestResourcePath__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestUri__c);
    System.RestRequest request = new System.RestRequest();
    request.httpMethod = 'GET';
    request.remoteAddress = '1.1.1.1';
    request.requestBody = Blob.valueOf('{hello:"world"}');
    request.requestURI = 'some-uri-value';
    request.resourcePath = '/some/resource/path';
    request.addHeader('some-header', 'some value');
    request.addParameter('some-parameter', 'some value');

    builder.setRestRequestDetails(request);

    List<String> formattedParameters = new List<String>();
    for (String parameterKey : request.params.keySet()) {
      formattedParameters.add(parameterKey + ': ' + request.params.get(parameterKey));
    }
    System.Assert.areEqual(request.requestBody.toString(), builder.getLogEntryEvent().RestRequestBody__c);
    System.Assert.areEqual(String.join(request.headers.keySet(), '\n'), builder.getLogEntryEvent().RestRequestHeaderKeys__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestHeaders__c);
    System.Assert.areEqual(request.httpMethod, builder.getLogEntryEvent().RestRequestMethod__c);
    System.Assert.areEqual(String.join(formattedParameters, '\n'), builder.getLogEntryEvent().RestRequestParameters__c);
    System.Assert.areEqual(request.remoteAddress, builder.getLogEntryEvent().RestRequestRemoteAddress__c);
    System.Assert.areEqual(request.resourcePath, builder.getLogEntryEvent().RestRequestResourcePath__c);
    System.Assert.areEqual(request.requestUri, builder.getLogEntryEvent().RestRequestUri__c);
  }

  @IsTest
  static void it_should_truncate_rest_request_body_field_when_string_is_too_long() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RestRequestBody__c);
    String excessivelyLongRequestBody = 'a'.repeat(Schema.LogEntryEvent__e.RestRequestBody__c.getDescribe().getLength() + 1);
    System.RestRequest request = new System.RestRequest();
    request.requestBody = Blob.valueOf(excessivelyLongRequestBody);

    builder.setRestRequestDetails(request);

    System.Assert.areEqual(
      excessivelyLongRequestBody.left(Schema.LogEntryEvent__e.RestRequestBody__c.getDescribe().getLength()),
      builder.getLogEntryEvent().RestRequestBody__c,
      'Expected string length ' +
        Schema.LogEntryEvent__e.RestRequestBody__c.getDescribe().getLength() +
        ' for field RestRequestBody__c, actual length is ' +
        builder.getLogEntryEvent().RestRequestBody__c.length()
    );
  }

  @IsTest
  static void it_should_set_rest_response_fields_when_storing_header_values_is_enabled() {
    LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'StoreRestResponseHeaderValues', Value__c = String.valueOf(true));
    LoggerParameter.setMock(mockParameter);
    System.Assert.isTrue(LoggerParameter.STORE_Rest_RESPONSE_HEADER_VALUES);
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseBody__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseHeaderKeys__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseHeaders__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseStatusCode__c);
    System.RestResponse response = new System.RestResponse();
    response.addHeader('some-header', 'some value');
    response.responseBody = Blob.valueOf('{hello:"world"}');
    response.statusCode = 200;

    builder.setRestResponseDetails(response);

    List<String> formattedHeaders = new List<String>();
    for (String headerKey : response.headers.keySet()) {
      formattedHeaders.add(headerKey + ': ' + response.headers.get(headerKey));
    }
    System.Assert.areEqual(response.responseBody.toString(), builder.getLogEntryEvent().RestResponseBody__c);
    System.Assert.areEqual(String.join(response.headers.keySet(), '\n'), builder.getLogEntryEvent().RestResponseHeaderKeys__c);
    System.Assert.areEqual(String.join(formattedHeaders, '\n'), builder.getLogEntryEvent().RestResponseHeaders__c);
    System.Assert.areEqual(response.statusCode, builder.getLogEntryEvent().RestResponseStatusCode__c);
  }

  @IsTest
  static void it_should_set_rest_response_fields_when_storing_header_values_is_disabled() {
    LoggerParameter__mdt mockParameter = new LoggerParameter__mdt(DeveloperName = 'StoreRestResponseHeaderValues', Value__c = String.valueOf(false));
    LoggerParameter.setMock(mockParameter);
    System.Assert.isFalse(LoggerParameter.STORE_REST_RESPONSE_HEADER_VALUES);
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseBody__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseHeaderKeys__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseHeaders__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseStatusCode__c);
    System.RestResponse response = new System.RestResponse();
    response.responseBody = Blob.valueOf('Hello, world!');
    response.addHeader('someKey', 'some string value');
    response.addHeader('anotherKey', 'an amazing example value, wow');
    response.statusCode = 201;

    builder.setRestResponseDetails(response);

    System.Assert.areEqual(response.responseBody.toString(), builder.getLogEntryEvent().RestResponseBody__c);
    System.Assert.areEqual(String.join(response.headers.keySet(), '\n'), builder.getLogEntryEvent().RestResponseHeaderKeys__c);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseHeaders__c);
    System.Assert.areEqual(response.statusCode, builder.getLogEntryEvent().RestResponseStatusCode__c);
  }

  @IsTest
  static void it_should_truncate_rest_response_body_field_when_string_is_too_long() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().RestResponseBody__c);
    String excessivelyLongResponseBody = 'a'.repeat(Schema.LogEntryEvent__e.RestResponseBody__c.getDescribe().getLength() + 1);
    System.RestResponse response = new System.RestResponse();
    response.responseBody = Blob.valueOf(excessivelyLongResponseBody);

    builder.setRestResponseDetails(response);

    System.Assert.areEqual(
      excessivelyLongResponseBody.left(Schema.LogEntryEvent__e.RestResponseBody__c.getDescribe().getLength()),
      builder.getLogEntryEvent().RestResponseBody__c,
      'Expected string length ' +
        Schema.LogEntryEvent__e.RestResponseBody__c.getDescribe().getLength() +
        ' for field RestResponseBody__c, actual length is ' +
        builder.getLogEntryEvent().RestResponseBody__c.length()
    );
  }

  @IsTest
  static void it_should_set_tags_string_for_list_of_tags() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    System.Assert.isNull(builder.getLogEntryEvent().Tags__c);

    List<String> tags = new List<String>{ 'some-tag', 'another One', 'here\'s one more!' };
    builder.addTags(tags);

    tags.sort();
    String expectedTagsString = String.escapeSingleQuotes(String.join(tags, '\n'));
    System.Assert.areEqual(expectedTagsString, builder.getLogEntryEvent().Tags__c);
  }

  @IsTest
  static void it_should_deduplicate_and_sort_tags() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
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

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);

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
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);

    builder.parseStackTrace('AnonymousBlock: line 1, column 1');

    System.Assert.isNull(builder.getLogEntryEvent().OriginLocation__c);
    System.Assert.isNull(builder.getLogEntryEvent().StackTrace__c);
  }

  @IsTest
  static void it_should_use_logger_stack_trace_class_to_set_origin_fields() {
    // Don't bother testing stack trace logic when using a namespace prefix - there are
    // some platform limitations that prevent these tests from behaving as expected
    if (LogEntryEventBuilder.class.getName().contains('.')) {
      return;
    }

    DebugStringExample constructedClass = new DebugStringExample();
    LoggerStackTrace originStackTrace = new LoggerStackTrace(constructedClass.getStackTraceString());
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.FINE, true);
    builder.getLogEntryEvent().OriginLocation__c = null;
    builder.getLogEntryEvent().OriginSourceActionName__c = null;
    builder.getLogEntryEvent().OriginSourceApiName__c = null;
    builder.getLogEntryEvent().OriginSourceMetadataType__c = null;
    builder.getLogEntryEvent().StackTrace__c = null;

    builder.parseStackTrace(constructedClass.getStackTraceString());

    System.Assert.areEqual(originStackTrace.Location, builder.getLogEntryEvent().OriginLocation__c);
    System.Assert.areEqual(originStackTrace.Source.ActionName, builder.getLogEntryEvent().OriginSourceActionName__c);
    System.Assert.areEqual(originStackTrace.Source.ApiName, builder.getLogEntryEvent().OriginSourceApiName__c);
    System.Assert.areEqual(originStackTrace.Source.MetadataType.name(), builder.getLogEntryEvent().OriginSourceMetadataType__c);
    System.Assert.areEqual(originStackTrace.ParsedStackTraceString, builder.getLogEntryEvent().StackTrace__c);
  }

  @IsTest
  static void it_should_use_logger_stack_trace_class_to_set_exception_fields() {
    // Don't bother testing stack trace logic when using a namespace prefix - there are
    // some platform limitations that prevent these tests from behaving as expected
    if (LogEntryEventBuilder.class.getName().contains('.')) {
      return;
    }

    System.DmlException someException = new System.DmlException('Whoops, it broke 😭');
    LoggerStackTrace exceptionStackTrace = new LoggerStackTrace(someException);
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.FINE, true);
    builder.getLogEntryEvent().ExceptionLocation__c = null;
    builder.getLogEntryEvent().ExceptionSourceActionName__c = null;
    builder.getLogEntryEvent().ExceptionSourceApiName__c = null;
    builder.getLogEntryEvent().ExceptionSourceMetadataType__c = null;
    builder.getLogEntryEvent().ExceptionStackTrace__c = null;

    builder.setExceptionDetails(someException);

    System.Assert.areEqual(exceptionStackTrace.Location, builder.getLogEntryEvent().ExceptionLocation__c);
    System.Assert.areEqual(exceptionStackTrace.Source.ActionName, builder.getLogEntryEvent().ExceptionSourceActionName__c);
    System.Assert.areEqual(exceptionStackTrace.Source.ApiName, builder.getLogEntryEvent().ExceptionSourceApiName__c);
    System.Assert.areEqual(exceptionStackTrace.Source.MetadataType.name(), builder.getLogEntryEvent().ExceptionSourceMetadataType__c);
    System.Assert.areEqual(exceptionStackTrace.ParsedStackTraceString, builder.getLogEntryEvent().ExceptionStackTrace__c);
  }

  @IsTest
  static void it_should_return_value_of_shouldSave_when_true() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);

    System.Assert.isTrue(builder.shouldSave());
    System.Assert.isNotNull(builder.getLogEntryEvent().EntrySaveReason__c);
  }

  @IsTest
  static void it_should_return_value_of_shouldSave_when_false() {
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, false);

    System.Assert.isFalse(builder.shouldSave());
    System.Assert.isNull(builder.getLogEntryEvent());
  }

  @IsTest
  static void it_should_set_save_reason_when_user_logging_level_met() {
    System.LoggingLevel userLoggingLevel = System.LoggingLevel.INFO;
    System.LoggingLevel entryLoggingLevel = System.LoggingLevel.WARN;
    System.Assert.isTrue(
      entryLoggingLevel.ordinal() > userLoggingLevel.ordinal(),
      'Test has started under the wrong conditions, the entry logging level should meet the user logging level'
    );
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.LoggingLevel__c = userLoggingLevel.name();

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, entryLoggingLevel, true);

    System.Assert.isTrue(builder.shouldSave());
    System.Assert.areEqual('Logging Level Met', builder.getLogEntryEvent().EntrySaveReason__c);
  }

  @IsTest
  static void it_should_set_save_reason_when_entry_saving_is_overridden() {
    System.LoggingLevel userLoggingLevel = System.LoggingLevel.INFO;
    System.LoggingLevel entryLoggingLevel = System.LoggingLevel.FINE;
    System.Assert.isTrue(
      entryLoggingLevel.ordinal() < userLoggingLevel.ordinal(),
      'Test has started under the wrong conditions, the entry logging level should NOT meet the user logging level'
    );
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.LoggingLevel__c = userLoggingLevel.name();

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, entryLoggingLevel, true);

    System.Assert.isTrue(builder.shouldSave());
    System.Assert.areEqual('Save Overridden', builder.getLogEntryEvent().EntrySaveReason__c);
  }

  @IsTest
  static void it_should_set_user_fields_when_anonymous_mode_disabled() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryOrganizationDataSynchronously', Value__c = String.valueOf(true)));
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryUserDataSynchronously', Value__c = String.valueOf(true)));
    Schema.Organization organization = LoggerMockDataCreator.getOrganization();
    String organizationEnvironmentType = LoggerMockDataCreator.getOrganizationEnvironmentType();
    MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
    LoggerEngineDataSelector.setMock(mockSelector);
    Schema.User mockUser = LoggerMockDataCreator.createUser();
    mockSelector.setCachedUser(mockUser);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);

    // Verify organization fields
    System.Assert.areEqual(organizationEnvironmentType, builder.getLogEntryEvent().OrganizationEnvironmentType__c);
    System.Assert.areEqual(organization.Id, builder.getLogEntryEvent().OrganizationId__c);
    System.Assert.areEqual(organization.InstanceName, builder.getLogEntryEvent().OrganizationInstanceName__c);
    System.Assert.areEqual(organization.Name, builder.getLogEntryEvent().OrganizationName__c);
    System.Assert.areEqual(organization.NamespacePrefix, builder.getLogEntryEvent().OrganizationNamespacePrefix__c);
    System.Assert.areEqual(organization.OrganizationType, builder.getLogEntryEvent().OrganizationType__c);
    // Verify user fields set from System.UserInfo
    System.Assert.areEqual(System.UserInfo.getUserId(), builder.getLogEntryEvent().LoggedById__c);
    System.Assert.areEqual(System.UserInfo.getLocale(), builder.getLogEntryEvent().Locale__c);
    System.Assert.areEqual(System.UserInfo.getUserId(), builder.getLogEntryEvent().LoggedById__c);
    System.Assert.areEqual(System.UserInfo.getUsername(), builder.getLogEntryEvent().LoggedByUsername__c);
    System.Assert.areEqual(System.UserInfo.getProfileId(), builder.getLogEntryEvent().ProfileId__c);
    System.Assert.areEqual(System.UserInfo.getUiThemeDisplayed(), builder.getLogEntryEvent().ThemeDisplayed__c);
    System.Assert.areEqual(System.UserInfo.getTimeZone().getId(), builder.getLogEntryEvent().TimeZoneId__c);
    System.Assert.areEqual(System.UserInfo.getTimeZone().getDisplayName(), builder.getLogEntryEvent().TimeZoneName__c);
    System.Assert.areEqual(System.UserInfo.getUserRoleId(), builder.getLogEntryEvent().UserRoleId__c);
    System.Assert.areEqual(System.UserInfo.getUserType(), builder.getLogEntryEvent().UserType__c);
    // Verify user fields set from queried User
    System.Assert.areEqual(mockUser.FederationIdentifier, builder.getLogEntryEvent().LoggedByFederationIdentifier__c);
    System.Assert.areEqual(mockUser.Profile.Name, builder.getLogEntryEvent().ProfileName__c);
    System.Assert.areEqual(mockUser.Profile.UserLicense.LicenseDefinitionKey, builder.getLogEntryEvent().UserLicenseDefinitionKey__c);
    System.Assert.areEqual(mockUser.Profile.UserLicense.Name, builder.getLogEntryEvent().UserLicenseName__c);
    System.Assert.areEqual(mockUser.Profile.UserLicenseId, builder.getLogEntryEvent().UserLicenseId__c);
    System.Assert.areEqual(mockUser.UserRole?.Name, builder.getLogEntryEvent().UserRoleName__c);
  }

  @IsTest
  static void it_should_not_set_user_fields_when_anonymous_mode_is_enabled() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsAnonymousModeEnabled__c = true;

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.DEBUG, true);

    System.Assert.isNull(builder.getLogEntryEvent().Locale__c);
    System.Assert.isNull(builder.getLogEntryEvent().LoggedByFederationIdentifier__c);
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
  static void it_should_set_single_field_with_specified_value() {
    Schema.SObjectField field = Schema.LogEntryEvent__e.OrganizationId__c;
    String fieldValue = 'Some_value';
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    // Wipe out any pre-populated field value to avoid a false-positive on the asserts below
    builder.getLogEntryEvent().put(field, null);

    builder.setField(field, fieldValue);

    System.Assert.areEqual(fieldValue, builder.getLogEntryEvent().get(field));
  }

  @IsTest
  static void it_should_set_map_of_fields_with_specified_values() {
    Map<Schema.SObjectField, Object> fieldToValue = new Map<Schema.SObjectField, Object>{
      Schema.LogEntryEvent__e.OrganizationId__c => 'Some_value',
      Schema.LogEntryEvent__e.ProfileId__c => 'Some Profile Name'
    };
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    // Wipe out any pre-populated fields values to avoid a false-positive on the asserts below
    for (Schema.SObjectField field : fieldToValue.keySet()) {
      builder.getLogEntryEvent().put(field, null);
    }

    builder.setField(fieldToValue);

    for (Schema.SObjectField field : fieldToValue.keySet()) {
      Object fieldValue = fieldToValue.get(field);
      System.Assert.areEqual(fieldValue, builder.getLogEntryEvent().get(field));
    }
  }

  @IsTest
  static void it_should_set_single_field_with_truncated_string_value() {
    Schema.SObjectField stringField = Schema.LogEntryEvent__e.OrganizationId__c;
    Integer maxLength = stringField.getDescribe().getLength();
    String fieldValue = 'A'.repeat(maxLength + 1);
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    // Wipe out any pre-populated field value to avoid a false-positive on the asserts below
    builder.getLogEntryEvent().put(stringField, null);

    builder.setField(stringField, fieldValue);

    System.Assert.areEqual(fieldValue.left(maxLength), builder.getLogEntryEvent().get(stringField));
  }

  @IsTest
  static void it_gracefully_handles_invalid_value_for_field() {
    Schema.SObjectField datetimeField = Schema.LogEntryEvent__e.Timestamp__c;
    String thingThatIsNotADatetime = 'this is DEFINITELY not a valid datetime, surely 🤷';
    LogEntryEventBuilder builder = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true);
    // Wipe out any pre-populated field value to avoid a false-positive on the asserts below
    builder.getLogEntryEvent().put(datetimeField, null);

    builder.setField(datetimeField, thingThatIsNotADatetime);

    System.Assert.isNull(builder.getLogEntryEvent().get(datetimeField));
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

  @IsTest
  static void it_should_apply_data_mask_rule_to_large_multiline_message() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // Build a large multi-line string that exceeds the chunk threshold, with SSNs at start, middle, and end
    String paddingLine = 'A'.repeat(LogEntryEventBuilder.DATA_MASK_REGEX_CHUNK_SIZE);
    String message = 'SSN at start: 400 11 9999\n' + paddingLine + '\nSSN in middle: 123 45 6789\n' + paddingLine + '\nSSN at end: 987 65 4321';

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('XXX-XX-9999'), 'SSN at start should be masked');
    System.Assert.isTrue(result.contains('XXX-XX-6789'), 'SSN in middle should be masked');
    System.Assert.isTrue(result.contains('XXX-XX-4321'), 'SSN at end should be masked');
    System.Assert.isFalse(result.contains('400 11 9999'), 'Original SSN at start should not appear');
    System.Assert.isFalse(result.contains('123 45 6789'), 'Original SSN in middle should not appear');
    System.Assert.isFalse(result.contains('987 65 4321'), 'Original SSN at end should not appear');
  }

  @IsTest
  static void it_should_apply_data_mask_rule_to_large_single_line_message() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // Build a large single-line string (no newlines) that exceeds the chunk threshold
    String padding = 'A'.repeat(LogEntryEventBuilder.DATA_MASK_REGEX_CHUNK_SIZE);
    String message = 'SSN here: 400 11 9999 ' + padding + ' another SSN: 123 45 6789';

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('XXX-XX-9999'), 'First SSN should be masked');
    System.Assert.isTrue(result.contains('XXX-XX-6789'), 'Second SSN should be masked');
    System.Assert.isFalse(result.contains('400 11 9999'), 'Original first SSN should not appear');
    System.Assert.isFalse(result.contains('123 45 6789'), 'Original second SSN should not appear');
  }

  @IsTest
  static void it_should_apply_data_mask_rule_when_ssn_is_near_chunk_boundary() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // Place a space-separated SSN so it straddles a chunk boundary.
    // The overlapping-chunk Matcher approach ensures the full pattern is found
    // even when it spans two adjacent chunks.
    Integer ssnPosition = LogEntryEventBuilder.DATA_MASK_REGEX_CHUNK_SIZE - 5;
    String message = 'B'.repeat(ssnPosition) + ' 400 11 9999 ' + 'C'.repeat(100);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('XXX-XX-9999'), 'SSN near chunk boundary should be masked');
    System.Assert.isFalse(result.contains('400 11 9999'), 'Original SSN near chunk boundary should not appear');
  }

  @IsTest
  static void it_should_mask_serialized_record_json_without_limit_exception() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    // Register all 4 bundled data mask rules — in production all enabled rules run sequentially
    LogEntryEventBuilder.setMockDataMaskRule(getSocialSecurityNumberDataMaskRule());
    LogEntryEventBuilder.setMockDataMaskRule(getVisaCreditCardNumberDataMaskRule());
    LogEntryEventBuilder.setMockDataMaskRule(getMastercardCreditCardNumberDataMaskRule());
    LogEntryEventBuilder.setMockDataMaskRule(getAmericanExpressCreditCardNumberDataMaskRule());
    // Simulate serialized SObject JSON — the scenario from issue #639 where a 35K+ string
    // of serialized Asset records triggered System.LimitException: Regex too complicated.
    // Each fake record mimics a real Asset with multiple fields, Salesforce IDs, dates, and numbers.
    String fakeAssetRecord = '{"attributes":{"type":"Asset","url":"/services/data/v64.0/sobjects/Asset/02iDm00000ABCdEFG"},'
      + '"Id":"02iDm00000ABCdEFG","AccountId":"001Dm00000XYZ1234","ContactId":"003Dm00000LMN5678",'
      + '"Name":"Asset-2024-09-001","Status":"Installed","Quantity":250.00,"Price":14999.95,'
      + '"PurchaseDate":"2024-09-15","InstallDate":"2024-09-20","UsageEndDate":"2025-09-15",'
      + '"SerialNumber":"SN-8842719305","Description":"Enterprise license  unit 42 of 250"}';
    Integer fieldMaxLength = LogEntryEvent__e.Message__c.getDescribe().getLength();
    Integer repetitions = fieldMaxLength / fakeAssetRecord.length();
    String message = fakeAssetRecord.repeat(repetitions) + ' 400 11 9999';

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('XXX-XX-9999'), 'Real SSN in serialized record JSON should be masked');
    System.Assert.isFalse(result.contains('400 11 9999'), 'Original SSN in serialized record JSON should not appear');
  }

  @IsTest
  static void it_should_not_double_mask_when_match_is_inside_overlap_zone() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // Place compact SSN "400119999" (9 chars) starting at position 3985
    // — fully inside overlap zone [3980, 4000), found by both chunk 0 and chunk 1.
    // The seenStarts dedup must prevent it from being masked twice.
    Integer ssnPosition = LogEntryEventBuilder.DATA_MASK_REGEX_CHUNK_SIZE - LogEntryEventBuilder.DATA_MASK_REGEX_OVERLAP_SIZE + 5;
    String message = 'B'.repeat(ssnPosition) + ' 400119999 ' + 'C'.repeat(100);
    Integer originalLength = message.length();

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('XXX-XX-9999'), 'SSN inside overlap zone should be masked');
    System.Assert.isFalse(result.contains('400119999'), 'Original SSN inside overlap zone should not appear');
    // If the SSN were double-masked, the result length would differ from a single replacement
    Integer expectedLengthDelta = 'XXX-XX-9999'.length() - '400119999'.length();
    System.Assert.areEqual(originalLength + expectedLengthDelta, result.length(), 'Result length should reflect exactly one replacement (no double-masking)');
  }

  @IsTest
  static void it_should_mask_multiple_ssns_near_same_chunk_boundary() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // Place first SSN ending just before the overlap zone, second SSN starting inside the overlap zone.
    // Both are near the chunk boundary — verifies multiple matches in the boundary region are all masked.
    Integer firstSsnPosition = LogEntryEventBuilder.DATA_MASK_REGEX_CHUNK_SIZE - LogEntryEventBuilder.DATA_MASK_REGEX_OVERLAP_SIZE - 12;
    String message = 'B'.repeat(firstSsnPosition) + ' 400119999 ' + ' 123456789 ' + 'C'.repeat(100);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('XXX-XX-9999'), 'First SSN near chunk boundary should be masked');
    System.Assert.isTrue(result.contains('XXX-XX-6789'), 'Second SSN near chunk boundary should be masked');
    System.Assert.isFalse(result.contains('400119999'), 'Original first SSN should not appear');
    System.Assert.isFalse(result.contains('123456789'), 'Original second SSN should not appear');
  }

  @IsTest
  static void it_should_mask_ssn_at_end_of_long_string() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // Build string just over chunk size, SSN at the very end with no trailing chars.
    // The final chunk will be shorter than DATA_MASK_REGEX_CHUNK_SIZE — verifies the tail chunk processes correctly.
    String message = 'B'.repeat(LogEntryEventBuilder.DATA_MASK_REGEX_CHUNK_SIZE + 100) + ' 400119999';

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('XXX-XX-9999'), 'SSN at end of long string should be masked');
    System.Assert.isFalse(result.contains('400119999'), 'Original SSN at end should not appear');
    System.Assert.isTrue(result.endsWith('XXX-XX-9999'), 'Masked SSN should be at the very end of the result');
  }

  @IsTest
  static void it_should_mask_ssn_starting_exactly_at_chunk_step_position() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // Place SSN starting exactly at position step (3980) — the exact start of chunk 1
    // and the exact start of the overlap zone for chunk 0.
    // Tests the boundary arithmetic at the most sensitive position.
    Integer step = LogEntryEventBuilder.DATA_MASK_REGEX_CHUNK_SIZE - LogEntryEventBuilder.DATA_MASK_REGEX_OVERLAP_SIZE;
    String message = 'B'.repeat(step) + ' 400119999 ' + 'C'.repeat(100);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('XXX-XX-9999'), 'SSN at exact chunk step position should be masked');
    System.Assert.isFalse(result.contains('400119999'), 'Original SSN at chunk step position should not appear');
  }

  @IsTest
  static void it_should_mask_credit_card_straddling_chunk_boundary() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getVisaCreditCardNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // Place a Visa CC " 4111-1111-1111-1111" (20 chars with leading space) starting at position 3981,
    // so it ends at 4001 — beyond chunk 0's boundary. Chunk 0 can't match it (only 19 chars visible).
    // Chunk 1 finds it correctly.
    Integer ccPosition = LogEntryEventBuilder.DATA_MASK_REGEX_CHUNK_SIZE - LogEntryEventBuilder.DATA_MASK_REGEX_OVERLAP_SIZE + 1;
    String message = 'B'.repeat(ccPosition) + ' 4111-1111-1111-1111 ' + 'C'.repeat(100);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('****-****-****-1111'), 'Visa CC straddling chunk boundary should be masked');
    System.Assert.isFalse(result.contains('4111-1111-1111-1111'), 'Original Visa CC should not appear');
  }

  @IsTest
  static void it_should_mask_long_value_straddling_chunk_boundary_when_overlap_is_overridden() {
    // A custom rule whose match is 40 chars long — longer than the default
    // DATA_MASK_REGEX_OVERLAP_SIZE (20). Positioned so it straddles the chunk-0 boundary
    // and begins before the default chunk-1 start (4000 - 20 = 3980): with the default
    // overlap neither chunk contains it whole, so it could not be masked. Raising the
    // overlap via the LoggerParameter__mdt override widens chunk 1 enough to capture it.
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'DataMaskRegexOverlapSize', Value__c = '60'));
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = new LogEntryDataMaskRule__mdt(
      DeveloperName = 'LongCustomSecret',
      IsEnabled__c = true,
      SensitiveDataRegEx__c = 'SECRET\\d{34}',
      ReplacementRegEx__c = 'REDACTED'
    );
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // Secret occupies [3970, 4010): truncated in chunk 0 and in the default-overlap
    // chunk 1 (starts 3980), but fully inside chunk 1 once overlap is raised to 60
    // (chunk 1 then starts at 3940).
    String secret = 'SECRET' + '0'.repeat(34);
    String message = 'B'.repeat(3970) + secret + 'C'.repeat(100);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('REDACTED'), 'Long value should be masked once overlap override widens the chunk');
    System.Assert.isFalse(result.contains(secret), 'Original long secret should not appear');
  }

  @IsTest
  static void it_should_mask_ssn_in_string_of_exactly_chunk_size() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // 4000-char string with SSN — verifies the <= guard routes to replaceAll directly (no chunking)
    String ssn = ' 400 11 9999 ';
    String message = 'A'.repeat(LogEntryEventBuilder.DATA_MASK_REGEX_CHUNK_SIZE - ssn.length()) + ssn;

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('XXX-XX-9999'), 'SSN in exactly chunk-size string should be masked');
    System.Assert.isFalse(result.contains('400 11 9999'), 'Original SSN should not appear');
  }

  @IsTest
  static void it_should_mask_ssn_in_string_of_chunk_size_plus_one() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // 4001-char string with SSN — verifies the chunking path activates at the minimum qualifying length
    String ssn = ' 400 11 9999 ';
    String message = 'A'.repeat(LogEntryEventBuilder.DATA_MASK_REGEX_CHUNK_SIZE + 1 - ssn.length()) + ssn;

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('XXX-XX-9999'), 'SSN in chunk-size+1 string should be masked');
    System.Assert.isFalse(result.contains('400 11 9999'), 'Original SSN should not appear');
  }

  @IsTest
  static void it_should_mask_ssn_in_multiline_where_one_line_is_exactly_chunk_size() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // Multi-line input where one line is exactly 4000 chars with an SSN.
    // Verifies the per-line <= check works at the boundary.
    String ssn = ' 400 11 9999 ';
    String exactLine = 'A'.repeat(LogEntryEventBuilder.DATA_MASK_REGEX_CHUNK_SIZE - ssn.length()) + ssn;
    String message = 'First line\n' + exactLine + '\nLast line';

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('XXX-XX-9999'), 'SSN in exactly chunk-size line should be masked');
    System.Assert.isFalse(result.contains('400 11 9999'), 'Original SSN should not appear');
  }

  @IsTest
  static void it_should_mask_ssn_at_start_of_long_string() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
    rule.IsEnabled__c = true;
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // SSN at the very start of a string that exceeds chunk size.
    // Tests the first-chunk handling when pos=0 and the first match starts at a small offset.
    String message = '400 11 9999 ' + 'B'.repeat(LogEntryEventBuilder.DATA_MASK_REGEX_CHUNK_SIZE);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('XXX-XX-9999'), 'SSN at start of long string should be masked');
    System.Assert.isFalse(result.contains('400 11 9999'), 'Original SSN at start should not appear');
    System.Assert.isTrue(result.startsWith('XXX-XX-9999'), 'Masked SSN should be at the very start of the result');
  }

  @IsTest
  static void it_should_keep_longer_match_when_same_start_found_by_two_chunks() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = new LogEntryDataMaskRule__mdt(
      DeveloperName = 'SyntheticLongerMatch',
      IsEnabled__c = true,
      SensitiveDataRegEx__c = '(X+)',
      ReplacementRegEx__c = '[MASKED]'
    );
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // 30 X's starting at position 3985 straddle the chunk boundary (chunk size = 4000).
    // Chunk 0 [0,4000) sees 15 X's → match (3985,4000).
    // Chunk 1 [3980,...) sees all 30 → match (3985,4015).
    // The longer-match branch (absEnd > endByStart.get(absStart)) keeps the 30-char match.
    String message = 'A'.repeat(3985) + 'X'.repeat(30) + 'B'.repeat(100);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isFalse(result.contains('X'), 'All X chars should be masked — longer match must win');
    System.Assert.areEqual(3985 + '[MASKED]'.length() + 100, result.length(), 'Result length should reflect single replacement');
  }

  @IsTest
  static void it_should_apply_matches_from_multiple_chunks_in_left_to_right_order() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = new LogEntryDataMaskRule__mdt(
      DeveloperName = 'SyntheticSortOrder',
      IsEnabled__c = true,
      SensitiveDataRegEx__c = '(X{5})',
      ReplacementRegEx__c = '[M]'
    );
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // Match A at position 100 (chunk 0 only), match B at position 4080 (chunk 1 only).
    // Map.keySet() has no guaranteed order in Apex — the sort ensures left-to-right processing.
    String message = 'A'.repeat(100) + 'XXXXX' + 'A'.repeat(3975) + 'XXXXX' + 'B'.repeat(100);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isFalse(result.contains('XXXXX'), 'Both XXXXX runs should be replaced');
    // Original: 100 + 5 + 3975 + 5 + 100 = 4185. Two replacements: 5→3 each, saving 4 total.
    System.Assert.areEqual(4181, result.length(), 'Result length should reflect two replacements');
    System.Assert.isTrue(result.startsWith('A'.repeat(100) + '[M]'), 'First match should be at position 100');
    System.Assert.isTrue(result.endsWith('[M]' + 'B'.repeat(100)), 'Second match should be near the end');
  }

  @IsTest
  static void it_should_skip_overlapping_match_consumed_by_previous_replacement() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = new LogEntryDataMaskRule__mdt(
      DeveloperName = 'SyntheticOverlapSkip',
      IsEnabled__c = true,
      SensitiveDataRegEx__c = '(X{10,})',
      ReplacementRegEx__c = '[MASKED]'
    );
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // 30 X's starting at position 3970. Chunk 0 matches (3970,4000)=30 X's.
    // Chunk 1 matches (3980,4000)=20 X's — a subset. After processing the first match
    // (pos=4000), the second match's start (3980) < pos, triggering the `continue` skip.
    String message = 'A'.repeat(3970) + 'X'.repeat(30) + 'B'.repeat(200);

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isFalse(result.contains('X'), 'All X chars should be masked');
    Integer maskedCount = result.split('\\[MASKED\\]', -1).size() - 1;
    System.Assert.areEqual(1, maskedCount, 'Exactly one [MASKED] token should appear');
    System.Assert.areEqual(3970 + '[MASKED]'.length() + 200, result.length(), 'Result length should reflect single replacement');
  }

  @IsTest
  static void it_should_not_reinterpret_dollar_signs_in_captured_group_values() {
    LoggerSettings__c userSettings = getUserSettings();
    userSettings.IsDataMaskingEnabled__c = true;
    LogEntryDataMaskRule__mdt rule = new LogEntryDataMaskRule__mdt(
      DeveloperName = 'SyntheticDollarSign',
      IsEnabled__c = true,
      SensitiveDataRegEx__c = '(\\w+:\\$\\d+)(DONE)( ?)',
      ReplacementRegEx__c = '[$1/$2]'
    );
    LogEntryEventBuilder.setMockDataMaskRule(rule);
    // Group 1 = 'PRICE:$3', group 2 = 'DONE', group 3 = ' '.
    // The old iterative String.replace() would process $3 inside group 1's value,
    // replacing it with group 3 (space) → '[PRICE: /DONE]'. The new single-pass
    // expandReplacement processes $N only in the template, preserving the literal $3.
    String fakeAssetRecord = '{"attributes":{"type":"Asset","url":"/services/data/v64.0/sobjects/Asset/02iDm00000ABCdEFG"},'
      + '"Id":"02iDm00000ABCdEFG","AccountId":"001Dm00000XYZ1234","ContactId":"003Dm00000LMN5678",'
      + '"Name":"Asset-2024-09-001","Status":"Installed","Quantity":250.00,"Price":14999.95,'
      + '"PurchaseDate":"2024-09-15","InstallDate":"2024-09-20","UsageEndDate":"2025-09-15",'
      + '"SerialNumber":"SN-8842719305","Description":"Enterprise license  unit 42 of 250"}';
    Integer repetitions = (LogEntryEventBuilder.DATA_MASK_REGEX_CHUNK_SIZE / fakeAssetRecord.length()) + 1;
    String message = fakeAssetRecord.repeat(repetitions) + ' PRICE:$3DONE ';

    LogEntryEventBuilder builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true);
    builder.setMessage(message);

    String result = builder.getLogEntryEvent().Message__c;
    System.Assert.isTrue(builder.getLogEntryEvent().MessageMasked__c);
    System.Assert.isTrue(result.contains('[PRICE:$3/DONE]'), 'Literal $3 in captured value should be preserved');
    System.Assert.isFalse(result.contains('[PRICE: /DONE]'), '$3 in captured value must not be reinterpreted as group 3');
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
      SensitiveDataRegEx__c = '(?<!\\d)(\\d{3})[- ]?(\\d{2})[- ]?(\\d{4})(?!\\d)',
      ReplacementRegEx__c = 'XXX-XX-$3'
    );
  }

  static LogEntryDataMaskRule__mdt getVisaCreditCardNumberDataMaskRule() {
    return new LogEntryDataMaskRule__mdt(
      DeveloperName = 'VisaCreditCardNumber',
      IsEnabled__c = true,
      SensitiveDataRegEx__c = '(^|[^0-9])(4\\d{3})([- ]?)\\d{4}\\3\\d{4}\\3(\\d{4})(?!\\d)',
      ReplacementRegEx__c = '$1****-****-****-$4'
    );
  }

  static LogEntryDataMaskRule__mdt getMastercardCreditCardNumberDataMaskRule() {
    return new LogEntryDataMaskRule__mdt(
      DeveloperName = 'MastercardCreditCardNumber',
      IsEnabled__c = true,
      SensitiveDataRegEx__c = '(^|[^0-9])(5[1-5]\\d{2}|222[1-9]|22[3-9]\\d|2[3-6]\\d{2}|27[01]\\d|2720)([- ]?)\\d{4}\\3\\d{4}\\3(\\d{4})(?!\\d)',
      ReplacementRegEx__c = '$1****-****-****-$4'
    );
  }

  static LogEntryDataMaskRule__mdt getAmericanExpressCreditCardNumberDataMaskRule() {
    return new LogEntryDataMaskRule__mdt(
      DeveloperName = 'AmericanExpressCreditCardNumber',
      IsEnabled__c = true,
      SensitiveDataRegEx__c = '(^|[^0-9A-Za-z])(3[47]\\d{2})([- ]?)\\d{6}\\3(\\d{5})(?=[^0-9A-Za-z]|$)',
      ReplacementRegEx__c = '$1****-******-$4'
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
      return new LogEntryEventBuilder(userSettings, System.LoggingLevel.DEBUG, true)
        .parseStackTrace(new System.DmlException().getStackTraceString())
        .setMessage(loggingString);
    }
  }

  private class MockLoggerEngineDataSelector extends LoggerEngineDataSelector {
    private Integer cachedAuthSessionQueryCount = 0;
    private Integer cachedOrganizationQueryCount = 0;
    private Integer cachedUserQueryCount = 0;
    private Schema.User cachedUser;
    private LoggerSObjectProxy.AuthSession mockAuthSessionProxy;

    public Integer getCachedAuthSessionQueryCount() {
      return cachedAuthSessionQueryCount;
    }

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

    public override Schema.Organization getCachedOrganization() {
      this.cachedOrganizationQueryCount++;
      return super.getCachedOrganization();
    }

    public Integer getCachedOrganizationQueryCount() {
      return cachedOrganizationQueryCount;
    }

    public override Schema.User getCachedUser() {
      this.cachedUserQueryCount++;
      if (this.cachedUser != null) {
        return this.cachedUser;
      }
      return super.getCachedUser();
    }

    public void setCachedUser(Schema.User user) {
      this.cachedUser = user;
    }

    public Integer getCachedUserQueryCount() {
      return cachedUserQueryCount;
    }
  }
}
