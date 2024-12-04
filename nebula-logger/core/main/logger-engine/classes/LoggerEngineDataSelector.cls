//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Selector class used for all queries that are specific to the logger engine layer
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ExcessivePublicCount')
public without sharing virtual class LoggerEngineDataSelector {
  @TestVisible
  private static final Boolean IS_EXPERIENCE_CLOUD_ENABLED = System.Type.forName('Schema.Network') != null;

  @TestVisible
  private static List<LoggerSObjectProxy.AuthSession> mockAuthSessionProxies;
  @TestVisible
  private static List<LoggerSObjectProxy.Network> mockNetworkProxies;

  private static LoggerEngineDataSelector instance = new LoggerEngineDataSelector();

  @SuppressWarnings('PMD.EmptyStatementBlock')
  @TestVisible
  private LoggerEngineDataSelector() {
  }

  /**
   * @description The instance `LoggerEngineDataSelector` used for any querying specific to the logger engine layer
   * @return   The singleton instance of `LoggerEngineDataSelector`
   */
  public static LoggerEngineDataSelector getInstance() {
    return instance;
  }

  /**
   * @description Returns a `Map<Id, LoggerSObjectProxy.AuthSession>` for the specified user IDs & their matching active sessions,
   *              or `null` if there is not a current session
   * @param  userIds userIds description
   * @return The instance of `Map<Id, LoggerSObjectProxy.AuthSession>` containing any matching `Schema.AuthSession` records
   */
  public virtual Map<Id, LoggerSObjectProxy.AuthSession> getAuthSessionProxies(List<Id> userIds) {
    Map<Id, LoggerSObjectProxy.AuthSession> userIdToAuthSessionProxy = new Map<Id, LoggerSObjectProxy.AuthSession>();

    if (LoggerParameter.QUERY_AUTH_SESSION_DATA == false) {
      return userIdToAuthSessionProxy;
    }

    List<SObject> authSessionRecords = [
      SELECT
        Id,
        LoginType,
        LoginHistoryId,
        LoginHistory.Application,
        LoginHistory.Browser,
        LoginHistory.Platform,
        LoginHistory.UserId,
        LogoutUrl,
        ParentId,
        SessionSecurityLevel,
        SessionType,
        SourceIp,
        UsersId
      FROM AuthSession
      WHERE UsersId IN :userIds AND IsCurrent = TRUE
      ORDER BY ParentId NULLS FIRST
    ];

    List<LoggerSObjectProxy.AuthSession> authSessionProxies = (List<LoggerSObjectProxy.AuthSession>) System.JSON.deserialize(
      System.JSON.serialize(authSessionRecords),
      List<LoggerSObjectProxy.AuthSession>.class
    );

    if (mockAuthSessionProxies != null) {
      authSessionProxies = mockAuthSessionProxies;
    }

    for (LoggerSObjectProxy.AuthSession authSessionProxy : authSessionProxies) {
      userIdToAuthSessionProxy.put(authSessionProxy.UsersId, authSessionProxy);
    }
    return userIdToAuthSessionProxy;
  }

  /**
   * @description Returns a cached copy of `LoggerSObjectProxy.AuthSession` for the current user's current session,
   *              or `null` if there is not a current session
   * @return   The cached `LoggerSObjectProxy.AuthSession` record
   */
  public virtual LoggerSObjectProxy.AuthSession getCachedAuthSessionProxy() {
    Id userId = System.UserInfo.getUserId();
    String cacheKey = 'AuthSession' + userId;
    if (LoggerCache.getSessionCache().contains(cacheKey)) {
      return (LoggerSObjectProxy.AuthSession) LoggerCache.getSessionCache().get(cacheKey);
    }

    LoggerSObjectProxy.AuthSession authSessionProxy;
    if (LoggerParameter.QUERY_AUTH_SESSION_DATA) {
      authSessionProxy = getAuthSessionProxies(new List<Id>{ userId }).get(userId);
      LoggerCache.getSessionCache().put(cacheKey, authSessionProxy);
    }
    return authSessionProxy;
  }

  /**
   * @description Returns a cached copy of the current user's `Schema.Network` site, or `null` if the current user is not associated
   *              with a `Schema.Network` site
   * @param  networkId The record ID of the `Schema.Network` to query
   * @return           The cached `Schema.Network` record
   */
  public virtual LoggerSObjectProxy.Network getCachedNetworkProxy(Id networkId) {
    if (networkId == null || (IS_EXPERIENCE_CLOUD_ENABLED == false && mockNetworkProxies == null)) {
      return null;
    }

    String cacheKey = 'Network' + networkId;
    if (LoggerCache.getOrganizationCache().contains(cacheKey)) {
      return (LoggerSObjectProxy.Network) LoggerCache.getOrganizationCache().get(cacheKey);
    }

    LoggerSObjectProxy.Network networkProxy;
    if (LoggerParameter.QUERY_NETWORK_DATA) {
      networkProxy = getNetworkProxies(new List<Id>{ networkId }).get(networkId);
      LoggerCache.getOrganizationCache().put(cacheKey, networkProxy);
    }
    return networkProxy;
  }

  /**
   * @description Returns a cached copy of the `Schema.Organization` record in the org, including some fields that cannot be accessed via `UserInfo`
   * @return   The cached `Schema.Organization` record
   */
  public virtual Schema.Organization getCachedOrganization() {
    String cacheKey = 'Organization';
    if (LoggerCache.getOrganizationCache().contains(cacheKey)) {
      return (Schema.Organization) LoggerCache.getOrganizationCache().get(cacheKey);
    }

    Schema.Organization organization;
    if (LoggerParameter.QUERY_ORGANIZATION_DATA) {
      organization = [
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
        LIMIT 1
      ];
      LoggerCache.getOrganizationCache().put(cacheKey, organization);
    }
    return organization;
  }

  /**
   * @description Returns a cached copy of the current user, including some profile fields that cannot be accessed via `UserInfo`
   * @return   The cached `Schema.User` record for the current user
   */
  public virtual Schema.User getCachedUser() {
    Id userId = System.UserInfo.getUserId();
    String cacheKey = 'User' + userId;
    if (LoggerCache.getSessionCache().contains(cacheKey)) {
      return (Schema.User) LoggerCache.getSessionCache().get(cacheKey);
    }

    Schema.User user = getUsers(new List<Id>{ userId }).get(userId);
    if (user != null) {
      LoggerCache.getSessionCache().put(cacheKey, user);
    }
    return user;
  }

  /**
   * @description Returns a list of matching `Schema.Network` records based on the provided list of network IDs
   * @param  networkIds The list of `Schema.Network` IDs to query
   * @return            The instance of `Map<Id, SObject>` containing any matching `Schema.Network` records
   */
  public Map<Id, LoggerSObjectProxy.Network> getNetworkProxies(List<Id> networkIds) {
    // TODO add caching in a future release
    if (LoggerParameter.QUERY_NETWORK_DATA == false) {
      return null;
    }

    // Networks (aka experience sites aka community sites aka portal sites ò_ô)
    // may not be enabled in the org (no Schema.Network object), so run everything dynamically
    Map<Id, LoggerSObjectProxy.Network> networkIdToNetworkProxy = new Map<Id, LoggerSObjectProxy.Network>();
    String query = 'SELECT Id, Name, UrlPathPrefix FROM Network WHERE Id IN :networkIds';
    List<SObject> networkRecords = IS_EXPERIENCE_CLOUD_ENABLED ? System.Database.query(String.escapeSingleQuotes(query)) : new List<SObject>();

    List<LoggerSObjectProxy.Network> networkProxies = (List<LoggerSObjectProxy.Network>) System.JSON.deserialize(
      System.JSON.serialize(networkRecords),
      List<LoggerSObjectProxy.Network>.class
    );

    if (mockNetworkProxies != null) {
      networkProxies = mockNetworkProxies;
    }

    for (LoggerSObjectProxy.Network networkProxy : networkProxies) {
      networkIdToNetworkProxy.put(networkProxy.Id, networkProxy);
    }
    return networkIdToNetworkProxy;
  }

  /**
   * @description Returns a list of matching `Schema.User` records based on the provided list of user IDs
   * @param  userIds The list of `Schema.User` IDs to query
   * @return         The instance of `Map<Id, Schema.User>` containing any matching `Schema.User` records
   */
  public Map<Id, Schema.User> getUsers(List<Id> userIds) {
    if (LoggerParameter.QUERY_USER_DATA == false) {
      return new Map<Id, Schema.User>();
    }

    return new Map<Id, Schema.User>(
      [
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
        WHERE Id IN :userIds
      ]
    );
  }

  // DELETEME Deprecated method, remove in a future release
  @TestVisible
  private static void setMock(LoggerEngineDataSelector mockSelectorInstance) {
    instance = mockSelectorInstance;
  }

  @TestVisible
  private static void useMocks() {
    // Avoid using the org's actual data records when running tests
    // by initializing all of the mock list variables.
    // And just in case there are multiple calls made to useMocks(),
    // only set the mock variables if they're null.
    mockAuthSessionProxies = mockAuthSessionProxies ?? new List<LoggerSObjectProxy.AuthSession>();
    mockNetworkProxies = mockNetworkProxies ?? new List<LoggerSObjectProxy.Network>();
  }
}
