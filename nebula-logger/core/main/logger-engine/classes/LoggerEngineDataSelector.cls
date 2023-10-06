//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Selector class used for all queries that are specific to the logger engine layer
 */
@SuppressWarnings('PMD.ApexCrudViolation, PMD.ExcessivePublicCount')
public without sharing virtual class LoggerEngineDataSelector {
    @TestVisible
    private static final Boolean IS_EXPERIENCE_CLOUD_ENABLED = System.Type.forName('NetworkMember') != null;

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
     * @description Returns a `Map<Id, AuthSession>` for the specified user IDs & their matching active sessions,
     *              or `null` if there is not a current session
     * @param  userIds userIds description
     * @return The instance of `Map<Id, AuthSession>` containing any matching `AuthSession` records
     */
    public virtual Map<Id, LoggerSObjectProxy.AuthSession> getAuthSessionProxies(List<Id> userIds) {
        Map<Id, LoggerSObjectProxy.AuthSession> userIdToAuthSessionProxy = new Map<Id, LoggerSObjectProxy.AuthSession>();

        if (LoggerParameter.QUERY_AUTH_SESSION_DATA == false) {
            return userIdToAuthSessionProxy;
        }

        for (AuthSession authSession : [
            SELECT
                Id,
                LoginType,
                LoginHistoryId,
                LoginHistory.Application,
                LoginHistory.Browser,
                LoginHistory.Platform,
                LoginHistory.UserId,
                LogoutUrl,
                SessionSecurityLevel,
                SessionType,
                SourceIp,
                UsersId
            FROM AuthSession
            WHERE UsersId IN :userIds AND IsCurrent = TRUE AND ParentId = NULL
        ]) {
            LoggerSObjectProxy.AuthSession authSessionProxy = new LoggerSObjectProxy.AuthSession(authSession);
            userIdToAuthSessionProxy.put(authSessionProxy.UsersId, authSessionProxy);
        }
        return userIdToAuthSessionProxy;
    }

    /**
     * @description Returns a cached copy of `AuthSession` for the current user's current session,
     *              or `null` if there is not a current session
     * @return   The cached `AuthSession` record
     */
    public virtual LoggerSObjectProxy.AuthSession getCachedAuthSessionProxy() {
        Id userId = System.UserInfo.getUserId();
        String cacheKey = 'AuthSession' + userId;
        if (LoggerCache.getSessionCache().contains(cacheKey)) {
            return (LoggerSObjectProxy.AuthSession) LoggerCache.getSessionCache().get(cacheKey);
        }

        LoggerSObjectProxy.AuthSession authSession;
        if (LoggerParameter.QUERY_AUTH_SESSION_DATA) {
            authSession = getAuthSessionProxies(new List<Id>{ userId }).get(userId);
            LoggerCache.getSessionCache().put(cacheKey, authSession);
        }
        return authSession;
    }

    /**
     * @description Returns a cached copy of the `LoggerSObjectHandler__mdt` records in the org,
     *              including the field `SObjectType__r.QualifiedApiName` that cannot be accessed via `LoggerSObjectHandler__mdt.getAll()`
     * @return   The cached `List<LoggerSObjectHandler__mdt>` records
     */
    public virtual List<LoggerSObjectHandler__mdt> getCachedLoggerSObjectHandlers() {
        String cacheKey = 'EnabledLoggerSObjectHandlers';
        if (LoggerCache.getOrganizationCache().contains(cacheKey)) {
            return (List<LoggerSObjectHandler__mdt>) LoggerCache.getOrganizationCache().get(cacheKey);
        }

        List<LoggerSObjectHandler__mdt> enabledSObjectHandlers = [
            SELECT IsEnabled__c, SObjectHandlerApexClass__c, SObjectType__r.QualifiedApiName, SObjectTypeOverride__c
            FROM LoggerSObjectHandler__mdt
            WHERE IsEnabled__c = TRUE
        ];
        LoggerCache.getOrganizationCache().put(cacheKey, enabledSObjectHandlers);
        return enabledSObjectHandlers;
    }

    /**
     * @description Returns a cached copy of the current user's `Network` site, or `null` if the current user is not associated
     *              with a `Network` site
     * @param  networkId The record ID of the `Network` to query
     * @return           The cached `Network` record
     */
    public virtual LoggerSObjectProxy.Network getCachedNetworkProxy(Id networkId) {
        if (networkId == null || IS_EXPERIENCE_CLOUD_ENABLED == false) {
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
     * @description Returns a cached copy of the `Organization` record in the org, including some fields that cannot be accessed via `UserInfo`
     * @return   The cached `Organization` record
     */
    public virtual Organization getCachedOrganization() {
        String cacheKey = 'Organization';
        if (LoggerCache.getOrganizationCache().contains(cacheKey)) {
            return (Organization) LoggerCache.getOrganizationCache().get(cacheKey);
        }

        Organization organization;
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
            ];
            LoggerCache.getOrganizationCache().put(cacheKey, organization);
        }
        return organization;
    }

    /**
     * @description Returns a cached copy of the `LogEntryTagRule__mdt` records in the org,
     *              including the field `SObjectField__r.QualifiedApiName` that cannot be accessed via `LogEntryTagRule__mdt.getAll()`
     * @return   The cached `List<LogEntryTagRule__mdt>` records
     */
    public virtual List<LogEntryTagRule__mdt> getCachedTagAssignmentRules() {
        String cacheKey = 'TagAssignmentRules';
        if (LoggerCache.getOrganizationCache().contains(cacheKey)) {
            return (List<LogEntryTagRule__mdt>) LoggerCache.getOrganizationCache().get(cacheKey);
        }

        List<LogEntryTagRule__mdt> tagAssignmentRules = new List<LogEntryTagRule__mdt>();
        if (LogEntryTagRule__mdt.getAll().isEmpty() == false || System.Test.isRunningTest()) {
            for (LogEntryTagRule__mdt rule : [
                SELECT Id, SObjectField__r.QualifiedApiName, ComparisonType__c, ComparisonValue__c, Tags__c
                FROM LogEntryTagRule__mdt
                WHERE IsEnabled__c = TRUE AND SObjectType__r.DeveloperName = 'LogEntry'
            ]) {
                rule.SObjectField__c = rule.SObjectField__r.QualifiedApiName;
                tagAssignmentRules.add(rule);
            }
        }
        LoggerCache.getOrganizationCache().put(cacheKey, tagAssignmentRules);
        return tagAssignmentRules;
    }

    /**
     * @description Returns a cached copy of the current user, including some profile fields that cannot be accessed via `UserInfo`
     * @return   The cached `User` record for the current user
     */
    public virtual User getCachedUser() {
        Id userId = System.UserInfo.getUserId();
        String cacheKey = 'User' + userId;
        if (LoggerCache.getSessionCache().contains(cacheKey)) {
            return (User) LoggerCache.getSessionCache().get(cacheKey);
        }

        User user;
        if (LoggerParameter.QUERY_USER_DATA) {
            user = getUsers(new List<Id>{ userId }).get(userId);
            LoggerCache.getSessionCache().put(cacheKey, user);
        }
        return user;
    }

    /**
     * @description Returns a list of matching `Network` records based on the provided list of network IDs
     * @param  networkIds The list of `Network` IDs to query
     * @return            The instance of `Map<Id, SObject>` containing any matching `Network` records
     */
    public Map<Id, LoggerSObjectProxy.Network> getNetworkProxies(List<Id> networkIds) {
        // TODO add caching in a future release
        if (LoggerParameter.QUERY_NETWORK_DATA == false) {
            return null;
        }

        // Networks (aka experience sites aka community sites aka portal sites ò_ô)
        // may not be enabled in the org (no Network object), so run everything dynamically
        // return new Map<Id, SObject>(Database.query(String.escapeSingleQuotes(query)));
        Map<Id, LoggerSObjectProxy.Network> networkIdToNetworkProxy = new Map<Id, LoggerSObjectProxy.Network>();
        String query = 'SELECT Id, Name, UrlPathPrefix FROM Network WHERE Id IN :networkIds';
        for (SObject networkRecord : Database.query(String.escapeSingleQuotes(query))) {
            LoggerSObjectProxy.Network networkProxy = new LoggerSObjectProxy.Network(networkRecord);
            networkIdToNetworkProxy.put(networkProxy.Id, networkProxy);
        }
        return networkIdToNetworkProxy;
    }

    /**
     * @description Returns a list of matching `User` records based on the provided list of user IDs
     * @param  userIds The list of `User` IDs to query
     * @return         The instance of `Map<Id, User>` containing any matching `User` records
     */
    public Map<Id, User> getUsers(List<Id> userIds) {
        if (LoggerParameter.QUERY_USER_DATA == false) {
            return new Map<Id, User>();
        }

        return new Map<Id, User>(
            [
                SELECT Id, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.LicenseDefinitionKey, Profile.UserLicense.Name, Username, UserRole.Name
                FROM User
                WHERE Id IN :userIds
            ]
        );
    }

    @TestVisible
    private static void setMock(LoggerEngineDataSelector mockSelectorInstance) {
        instance = mockSelectorInstance;
    }
}
