//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerEngineDataSelector_Tests {
  static {
    // Don't use the org's actual custom metadata records when running tests
    LoggerConfigurationSelector.useMocks();
  }

  @IsTest
  static void it_loads_mock_instance() {
    MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
    System.Assert.areNotEqual(mockSelector, LoggerEngineDataSelector.getInstance());

    LoggerEngineDataSelector.setMock(mockSelector);

    System.Assert.areEqual(mockSelector, LoggerEngineDataSelector.getInstance());
  }

  @IsTest
  static void it_returns_empty_map_for_list_of_user_ids_when_querying_auth_session_is_disabled() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryAuthSessionData', Value__c = String.valueOf(false)));
    System.Assert.isFalse(LoggerParameter.QUERY_AUTH_SESSION_DATA, 'Test has started under the wrong conditions');

    Map<Id, LoggerSObjectProxy.AuthSession> returnedAuthSessionProxyMap = LoggerEngineDataSelector.getInstance()
      .getAuthSessionProxies(new List<Id>{ System.UserInfo.getUserId() });

    System.Assert.areEqual(0, System.Limits.getQueries());
    System.Assert.isNotNull(returnedAuthSessionProxyMap);
    System.Assert.areEqual(0, returnedAuthSessionProxyMap.size());
  }

  @IsTest
  static void it_returns_null_for_current_user_cached_auth_session_when_querying_auth_session_is_disabled() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryAuthSessionData', Value__c = String.valueOf(false)));
    System.Assert.isFalse(LoggerParameter.QUERY_AUTH_SESSION_DATA, 'Test has started under the wrong conditions');

    LoggerSObjectProxy.AuthSession returnedAuthSessionProxy = LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();

    System.Assert.areEqual(0, System.Limits.getQueries());
    System.Assert.isNull(returnedAuthSessionProxy);
  }

  @IsTest
  static void it_returns_cached_auth_session_proxy_from_database() {
    List<Schema.AuthSession> queriedAuthSessions = [
      SELECT
        Id,
        LoginHistory.Application,
        LoginHistory.Browser,
        LoginHistory.Platform,
        LoginHistoryId,
        LoginType,
        LogoutUrl,
        ParentId,
        SessionSecurityLevel,
        SessionType,
        SourceIp
      FROM AuthSession
      WHERE UsersId = :System.UserInfo.getUserId() AND IsCurrent = TRUE
    ];
    LoggerSObjectProxy.AuthSession expectedAuthSessionProxy = queriedAuthSessions.isEmpty()
      ? null
      : (LoggerSObjectProxy.AuthSession) System.JSON.deserialize(System.JSON.serialize(queriedAuthSessions.get(0)), LoggerSObjectProxy.AuthSession.class);
    System.Assert.areEqual(1, System.Limits.getQueries());

    LoggerSObjectProxy.AuthSession returnedAuthSessionProxy = LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();

    System.Assert.areEqual(2, System.Limits.getQueries());
    LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();
    System.Assert.areEqual(2, System.Limits.getQueries(), 'Query results should have been cached');
    System.Assert.areEqual(expectedAuthSessionProxy, returnedAuthSessionProxy);
  }

  @IsTest
  static void it_returns_cached_auth_session_proxy_from_provided_mocks() {
    // Since Schema.AuthSession can't be mocked directly, ensure that a mock proxy record can be substituted
    LoggerSObjectProxy.AuthSession mockAuthSessionProxy = new LoggerSObjectProxy.AuthSession();
    mockAuthSessionProxy.UsersId = System.UserInfo.getUserId();
    LoggerEngineDataSelector.useMocks();
    LoggerEngineDataSelector.mockAuthSessionProxies.add(mockAuthSessionProxy);
    System.Assert.areEqual(0, System.Limits.getQueries());

    LoggerSObjectProxy.AuthSession returnedAuthSessionProxy = LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();

    System.Assert.areEqual(1, System.Limits.getQueries(), 'Query should still be executed, even when using mock records');
    LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();
    System.Assert.areEqual(1, System.Limits.getQueries(), 'Query results should have been cached');
    System.Assert.areEqual(mockAuthSessionProxy, returnedAuthSessionProxy);
  }

  @IsTest
  static void it_returns_null_when_querying_auth_session_is_disabled() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryAuthSessionData', Value__c = String.valueOf(false)));
    System.Assert.isFalse(LoggerParameter.QUERY_AUTH_SESSION_DATA);

    LoggerSObjectProxy.AuthSession returnedAuthSessionProxy = LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();

    System.Assert.areEqual(0, System.Limits.getQueries());
    System.Assert.isNull(returnedAuthSessionProxy);
  }

  @IsTest
  static void it_does_not_query_auth_session_when_disabled_via_logger_parameter() {
    MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
    LoggerEngineDataSelector.setMock(mockSelector);
    System.Assert.areEqual(mockSelector, LoggerEngineDataSelector.getInstance());
    System.Assert.areEqual(0, mockSelector.getCachedAuthSessionQueryCount());
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryAuthSessionData', Value__c = String.valueOf(false)));

    LoggerSObjectProxy.AuthSession returnedAuthSessionProxy = LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();

    System.Assert.areEqual(0, mockSelector.getCachedAuthSessionQueryCount());
    System.Assert.isNull(returnedAuthSessionProxy);
  }

  @IsTest
  static void it_returns_null_for_cached_network_when_provided_network_id_is_null() {
    Id nullNetworkId = null;

    LoggerSObjectProxy.Network returnedNetworkProxy = LoggerEngineDataSelector.getInstance().getCachedNetworkProxy(nullNetworkId);

    System.Assert.isNull(returnedNetworkProxy);
    System.Assert.areEqual(0, System.Limits.getQueries());
  }

  @IsTest
  static void it_returns_cached_network_from_database() {
    if (LoggerEngineDataSelector.IS_EXPERIENCE_CLOUD_ENABLED == false) {
      return;
    }
    List<SObject> networkRecords = getExperienceCloudNetworks();
    if (networkRecords.isEmpty()) {
      return;
    }
    Id expectedNetworkId = (Id) networkRecords.get(0).get('Id');
    System.Assert.isNotNull(expectedNetworkId);
    System.Assert.areEqual(1, System.Limits.getQueries());
    Integer expectedQueryCount = System.Limits.getQueries() + 1;

    LoggerSObjectProxy.Network returnedNetworkProxy = LoggerEngineDataSelector.getInstance().getCachedNetworkProxy(expectedNetworkId);

    System.Assert.isNotNull(returnedNetworkProxy);
    System.Assert.areEqual(expectedQueryCount, System.Limits.getQueries());
    LoggerEngineDataSelector.getInstance().getCachedNetworkProxy(expectedNetworkId);
    System.Assert.areEqual(expectedQueryCount, System.Limits.getQueries(), 'Query results should have been cached');
    System.Assert.areEqual(expectedNetworkId, returnedNetworkProxy?.Id);
  }

  @IsTest
  static void it_returns_cached_network_from_provided_mock_records() {
    // Since Schema.Network doesn't exist in all orgs, ensure that a mock proxy record can be substituted
    LoggerSObjectProxy.Network mockNetworkProxy = new LoggerSObjectProxy.Network();
    mockNetworkProxy.Id = LoggerMockDataCreator.createId(Schema.Account.getSObjectType());
    mockNetworkProxy.Name = 'Some mock network';
    mockNetworkProxy.UrlPathPrefix = 'some-url-prefix';
    LoggerEngineDataSelector.useMocks();
    LoggerEngineDataSelector.mockNetworkProxies.add(mockNetworkProxy);
    System.Assert.areEqual(0, System.Limits.getQueries());

    LoggerSObjectProxy.Network returnedNetworkProxy = LoggerEngineDataSelector.getInstance().getCachedNetworkProxy(mockNetworkProxy.Id);

    System.Assert.isNotNull(returnedNetworkProxy);
    Integer expectedQueryCount;
    if (LoggerEngineDataSelector.IS_EXPERIENCE_CLOUD_ENABLED) {
      expectedQueryCount = 1;
      System.Assert.areEqual(
        expectedQueryCount,
        System.Limits.getQueries(),
        'Query should still be executed, even when using mock records (and when Network object is available)'
      );
    } else {
      expectedQueryCount = 0;
      System.Assert.areEqual(expectedQueryCount, System.Limits.getQueries(), 'Query should not have been executed (when Network object is not available)');
    }
    LoggerEngineDataSelector.getInstance().getCachedNetworkProxy(mockNetworkProxy.Id);
    System.Assert.areEqual(expectedQueryCount, System.Limits.getQueries(), 'Query results should have been cached');
    System.Assert.areEqual(mockNetworkProxy.Id, returnedNetworkProxy.Id);
    System.Assert.areEqual(mockNetworkProxy.Name, returnedNetworkProxy.Name);
    System.Assert.areEqual(mockNetworkProxy.UrlPathPrefix, returnedNetworkProxy.UrlPathPrefix);
  }

  @IsTest
  static void it_returns_null_when_network_id_is_null() {
    if (LoggerEngineDataSelector.IS_EXPERIENCE_CLOUD_ENABLED == false) {
      return;
    }

    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryNetworkData', Value__c = String.valueOf(false)));
    System.Assert.isFalse(LoggerParameter.QUERY_NETWORK_DATA);
    Id expectedNetworkId = null;
    System.Assert.areEqual(0, System.Limits.getQueries());

    LoggerSObjectProxy.Network returnedNetworkProxy = LoggerEngineDataSelector.getInstance().getCachedNetworkProxy(expectedNetworkId);

    System.Assert.areEqual(0, System.Limits.getQueries());
    System.Assert.isNull(returnedNetworkProxy);
  }

  @IsTest
  static void it_returns_null_when_querying_network_is_disabled() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryNetworkData', Value__c = String.valueOf(false)));
    System.Assert.isFalse(LoggerParameter.QUERY_NETWORK_DATA);
    Id someRecordId = System.UserInfo.getUserId();
    System.Assert.areEqual(0, System.Limits.getQueries());

    Map<Id, LoggerSObjectProxy.Network> returnedNetworkProxies = LoggerEngineDataSelector.getInstance().getNetworkProxies(new List<Id>{ someRecordId });

    System.Assert.areEqual(0, System.Limits.getQueries());
    System.Assert.isNull(returnedNetworkProxies);
  }

  @IsTest
  static void it_returns_cached_organization() {
    Schema.Organization expectedOrganization = [
      SELECT
        Id,
        CreatedById,
        CreatedBy.Name,
        CreatedBy.Username,
        CreatedDate,
        InstanceName,
        IsSandbox,
        Name,
        NamespacePrefix,
        OrganizationType,
        TrialExpirationDate
      FROM Organization
    ];
    MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
    LoggerEngineDataSelector.setMock(mockSelector);
    System.Assert.areEqual(mockSelector, LoggerEngineDataSelector.getInstance());
    System.Assert.areEqual(0, mockSelector.getCachedOrganizationQueryCount());

    Schema.Organization returnedOrganization = LoggerEngineDataSelector.getInstance().getCachedOrganization();

    System.Assert.areEqual(1, mockSelector.getCachedOrganizationQueryCount());
    LoggerEngineDataSelector.getInstance().getCachedOrganization();
    System.Assert.areEqual(1, mockSelector.getCachedOrganizationQueryCount(), 'Query results should have been cached');
    System.Assert.areEqual(expectedOrganization, returnedOrganization);
  }

  @IsTest
  static void it_does_not_query_organization_when_disabled_via_logger_parameter() {
    MockLoggerEngineDataSelector mockSelector = new MockLoggerEngineDataSelector();
    System.Assert.areNotEqual(mockSelector, LoggerEngineDataSelector.getInstance());
    System.Assert.areEqual(0, mockSelector.getCachedOrganizationQueryCount());
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryOrganizationData', Value__c = String.valueOf(false)));

    Schema.Organization returnedOrganization = LoggerEngineDataSelector.getInstance().getCachedOrganization();

    System.Assert.areEqual(0, mockSelector.getCachedOrganizationQueryCount());
    System.Assert.isNull(returnedOrganization);
  }

  @IsTest
  static void it_returns_cached_user() {
    Schema.User expectedUser = [
      SELECT
        FederationIdentifier,
        Id,
        Profile.Name,
        Profile.UserLicenseId,
        Profile.UserLicense.LicenseDefinitionKey,
        Profile.UserLicense.Name,
        Username,
        UserRole.Name
      FROM User
      WHERE Id = :System.UserInfo.getUserId()
    ];
    System.Assert.areEqual(1, System.Limits.getQueries());

    Schema.User returnedUser = LoggerEngineDataSelector.getInstance().getCachedUser();

    System.Assert.areEqual(2, System.Limits.getQueries());
    LoggerEngineDataSelector.getInstance().getCachedUser();
    System.Assert.areEqual(2, System.Limits.getQueries(), 'Query results should have been cached');
    System.Assert.areEqual(expectedUser, returnedUser);
  }

  @IsTest
  static void it_returns_null_when_querying_cached_user_is_disabled() {
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryUserData', Value__c = String.valueOf(false)));
    System.Assert.isFalse(LoggerParameter.QUERY_USER_DATA);

    Schema.User returnedUser = LoggerEngineDataSelector.getInstance().getCachedUser();

    System.Assert.areEqual(0, System.Limits.getQueries());
    System.Assert.isNull(returnedUser);
  }

  static List<SObject> getExperienceCloudNetworks() {
    return System.Database.query('SELECT Id, Name, UrlPathPrefix FROM Network LIMIT 1');
  }

  private class MockLoggerEngineDataSelector extends LoggerEngineDataSelector {
    private Integer authSessionQueryCount = 0;
    private Integer organizationQueryCount = 0;

    public override LoggerSObjectProxy.AuthSession getCachedAuthSessionProxy() {
      Integer originalQueryCount = System.Limits.getQueries();
      LoggerSObjectProxy.AuthSession result = super.getCachedAuthSessionProxy();
      if (System.Limits.getQueries() != originalQueryCount) {
        authSessionQueryCount = System.Limits.getQueries() - originalQueryCount;
      }
      return result;
    }

    public Integer getCachedAuthSessionQueryCount() {
      return authSessionQueryCount;
    }

    public override Schema.Organization getCachedOrganization() {
      Integer originalQueryCount = System.Limits.getQueries();
      Schema.Organization result = super.getCachedOrganization();
      if (System.Limits.getQueries() != originalQueryCount) {
        organizationQueryCount = System.Limits.getQueries() - originalQueryCount;
      }
      return result;
    }

    public Integer getCachedOrganizationQueryCount() {
      return organizationQueryCount;
    }
  }
}
