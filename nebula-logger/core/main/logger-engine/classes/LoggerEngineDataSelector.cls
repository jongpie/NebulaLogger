@SuppressWarnings('PMD.ApexCrudViolation, PMD.ApexDoc, PMD.ExcessivePublicCount')
public without sharing class LoggerEngineDataSelector {
    public static List<SObject> queryAll(Schema.SObjectType sobjectType, Set<String> fieldNames) {
        // fieldNames.add('Id');
        String query = String.format('SELECT {0} FROM {1}', new List<Object>{ String.join(new List<String>(fieldNames), ', '), sobjectType });
        return Database.query(String.escapeSingleQuotes(query));
    }

    public static List<SObject> queryById(Schema.SObjectType sobjectType, Set<String> fieldNames, List<Id> recordIds) {
        // fieldNames.add('Id');
        String query = String.format(
            'SELECT {0} FROM {1} WHERE Id IN :recordIds',
            new List<Object>{ String.join(new List<String>(fieldNames), ', '), sobjectType }
        );
        return Database.query(String.escapeSingleQuotes(query));
    }

    public static AuthSession queryAuthSession() {
        return queryAuthSession(UserInfo.getUserId());
    }

    public static AuthSession queryAuthSession(Id userId) {
        String cacheKeyName = 'AuthSession' + userId;
        if (LoggerCache.getSessionCache().containsKey(cacheKeyName) == true) {
            return (AuthSession) LoggerCache.getSessionCache().get(cacheKeyName);
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
        LoggerCache.getSessionCache().put(cacheKeyName, session);
        return session;
    }

    public static List<LoggerSObjectHandler__mdt> queryEnabledLoggerSObjectHandlers() {
        String cacheKeyName = 'EnabledLoggerSObjectHandlers';
        if (LoggerCache.getTransactionCache().containsKey(cacheKeyName) == true) {
            return (List<LoggerSObjectHandler__mdt>) LoggerCache.getTransactionCache().get(cacheKeyName);
        }

        List<LoggerSObjectHandler__mdt> enabledSObjectHandlers = [
            SELECT IsEnabled__c, SObjectHandlerApexClass__c, SObjectType__r.QualifiedApiName
            FROM LoggerSObjectHandler__mdt
            WHERE IsEnabled__c = TRUE
        ];
        LoggerCache.getTransactionCache().put(cacheKeyName, enabledSObjectHandlers);
        return enabledSObjectHandlers;
    }

    public static SObject queryNetwork() {
        if (Network.getNetworkId() == null || Type.forName('System.Network') == null) {
            return null;
        }

        return queryNetworkById(Network.getNetworkId());
    }

    public static SObject queryNetworkById(Id networkId) {
        String cacheKeyName = 'Network' + networkId;
        if (LoggerCache.getOrganizationCache().containsKey(cacheKeyName) == true) {
            return (SObject) LoggerCache.getOrganizationCache().get(cacheKeyName);
        }

        // Networks (aka experience sites aka community sites aka portal sites ò_ô)
        // may not be enabled in the org (no Network object), so run everything dynamically
        String query = 'SELECT Id, Name, UrlPathPrefix FROM Network WHERE Id = :networkId';
        SObject network = Database.query(String.escapeSingleQuotes(query));
        LoggerCache.getOrganizationCache().put(cacheKeyName, network);
        return network;
    }

    public static Organization queryOrganization() {
        String cacheKeyName = 'Organization';
        if (LoggerCache.getOrganizationCache().containsKey(cacheKeyName) == true) {
            return (Organization) LoggerCache.getOrganizationCache().get(cacheKeyName);
        }

        Organization organization = [SELECT Id, InstanceName, IsSandbox, Name, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization];
        LoggerCache.getOrganizationCache().put(cacheKeyName, organization);
        return organization;
    }

    public static List<LogEntryTagRule__mdt> queryTagAssignmentRules() {
        String cacheKeyName = 'TagAssignmentRules';
        if (LoggerCache.getOrganizationCache().containsKey(cacheKeyName) == true) {
            return (List<LogEntryTagRule__mdt>) LoggerCache.getOrganizationCache().get(cacheKeyName);
        }

        List<LogEntryTagRule__mdt> tagAssignmentRules = [
            SELECT Id, SObjectField__r.QualifiedApiName, ComparisonType__c, ComparisonValue__c, Tags__c
            FROM LogEntryTagRule__mdt
            WHERE IsEnabled__c = TRUE AND SObjectType__r.DeveloperName = 'LogEntry'
        ];
        LoggerCache.getOrganizationCache().put(cacheKeyName, tagAssignmentRules);
        return tagAssignmentRules;
    }

    public static User queryUser() {
        return queryUser(UserInfo.getUserId());
    }

    public static User queryUser(Id userId) {
        String cacheKeyName = 'User' + userId;
        if (LoggerCache.getSessionCache().containsKey(cacheKeyName) == true) {
            return (User) LoggerCache.getSessionCache().get(cacheKeyName);
        }

        User user = [
            SELECT Id, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.LicenseDefinitionKey, Profile.UserLicense.Name, Username, UserRole.Name
            FROM User
            WHERE Id = :userId
        ];
        LoggerCache.getSessionCache().put(cacheKeyName, user);
        return user;
    }
}
