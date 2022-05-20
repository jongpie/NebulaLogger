//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Selector class used for all queries that are specific to the logger engine layer
 */
@SuppressWarnings('PMD.ApexCrudViolation, PMD.ExcessivePublicCount')
public without sharing class LoggerEngineDataSelector {
    private static final LoggerEngineDataSelector INSTANCE = new LoggerEngineDataSelector();

    @SuppressWarnings('PMD.EmptyStatementBlock')
    private LoggerEngineDataSelector() {
    }

    public static LoggerEngineDataSelector getInstance() {
        return INSTANCE;
    }

    public AuthSession getCachedAuthSession() {
        Id userId = UserInfo.getUserId();
        String cacheKeyName = 'AuthSession' + userId;
        if (LoggerCache.getTransactionCache().contains(cacheKeyName) == true) {
            return (AuthSession) LoggerCache.getTransactionCache().get(cacheKeyName);
        }

        List<AuthSession> sessions = [
            SELECT
                Id,
                LoginType,
                LoginHistoryId,
                LoginHistory.Application,
                LoginHistory.Browser,
                LoginHistory.Platform,
                LogoutUrl,
                SessionSecurityLevel,
                SessionType,
                SourceIp
            FROM AuthSession
            WHERE UsersId = :UserInfo.getUserId() AND IsCurrent = TRUE AND ParentId = NULL // TODO this won't work in an async context (when running as Automated Process)
        ];

        AuthSession session = sessions.isEmpty() ? null : sessions.get(0);
        LoggerCache.getTransactionCache().put(cacheKeyName, session);
        return session;
    }

    public List<LoggerSObjectHandler__mdt> getCachedLoggerSObjectHandlers() {
        String cacheKeyName = 'EnabledLoggerSObjectHandlers';
        if (LoggerCache.getTransactionCache().contains(cacheKeyName) == true) {
            return (List<LoggerSObjectHandler__mdt>) LoggerCache.getTransactionCache().get(cacheKeyName);
        }

        List<LoggerSObjectHandler__mdt> enabledSObjectHandlers = [
            SELECT IsEnabled__c, SObjectHandlerApexClass__c, SObjectType__r.QualifiedApiName, SObjectTypeOverride__c
            FROM LoggerSObjectHandler__mdt
            WHERE IsEnabled__c = TRUE
        ];
        LoggerCache.getTransactionCache().put(cacheKeyName, enabledSObjectHandlers);
        return enabledSObjectHandlers;
    }

    public SObject getCachedNetwork() {
        return getCachedNetworkById(System.Network.getNetworkId());
    }

    public SObject getCachedNetworkById(Id networkId) {
        if (networkId == null || Type.forName('System.Network') == null) {
            return null;
        }

        String cacheKeyName = 'Network' + networkId;
        if (LoggerCache.getTransactionCache().contains(cacheKeyName) == true) {
            return (SObject) LoggerCache.getTransactionCache().get(cacheKeyName);
        }

        // Networks (aka experience sites aka community sites aka portal sites ò_ô)
        // may not be enabled in the org (no Network object), so run everything dynamically
        String query = 'SELECT Id, Name, UrlPathPrefix FROM Network WHERE Id = :networkId';
        SObject networkSite = Database.query(String.escapeSingleQuotes(query));
        LoggerCache.getTransactionCache().put(cacheKeyName, networkSite);
        return networkSite;
    }

    public Organization getCachedOrganization() {
        String cacheKeyName = 'Organization';
        if (LoggerCache.getTransactionCache().contains(cacheKeyName) == true) {
            return (Organization) LoggerCache.getTransactionCache().get(cacheKeyName);
        }

        Organization organization = [SELECT Id, InstanceName, IsSandbox, Name, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization];
        LoggerCache.getTransactionCache().put(cacheKeyName, organization);
        return organization;
    }

    public List<LogEntryTagRule__mdt> getCachedTagAssignmentRules() {
        String cacheKeyName = 'TagAssignmentRules';
        if (LoggerCache.getTransactionCache().contains(cacheKeyName) == true) {
            return (List<LogEntryTagRule__mdt>) LoggerCache.getTransactionCache().get(cacheKeyName);
        }

        List<LogEntryTagRule__mdt> tagAssignmentRules = new List<LogEntryTagRule__mdt>();
        if (LogEntryTagRule__mdt.getAll().isEmpty() == false || System.Test.isRunningTest() == true) {
            tagAssignmentRules = [
                SELECT Id, SObjectField__r.QualifiedApiName, ComparisonType__c, ComparisonValue__c, Tags__c
                FROM LogEntryTagRule__mdt
                WHERE IsEnabled__c = TRUE AND SObjectType__r.DeveloperName = 'LogEntry'
            ];
        }
        LoggerCache.getTransactionCache().put(cacheKeyName, tagAssignmentRules);
        return tagAssignmentRules;
    }

    public User getCachedUser() {
        return getCachedUser(UserInfo.getUserId());
    }

    public User getCachedUser(Id userId) {
        String cacheKeyName = 'User' + userId;
        if (LoggerCache.getTransactionCache().contains(cacheKeyName) == true) {
            return (User) LoggerCache.getTransactionCache().get(cacheKeyName);
        }

        User user = [
            SELECT Id, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.LicenseDefinitionKey, Profile.UserLicense.Name, Username, UserRole.Name
            FROM User
            WHERE Id = :userId
        ];
        LoggerCache.getTransactionCache().put(cacheKeyName, user);
        return user;
    }
}
