@SuppressWarnings('PMD.ApexCrudViolation, PMD.ApexDoc, PMD.ExcessivePublicCount')
public without sharing class LogManagementDataSelector {
    public static List<ApexClass> queryApexClasses(List<String> apexClassNames) {
        return [
            SELECT ApiVersion, CreatedById, CreatedDate, Id, LastModifiedById, LastModifiedDate, Name
            FROM ApexClass
            WHERE Name IN :apexClassNames
            ORDER BY NamespacePrefix NULLS LAST
        ];
    }

    public static List<ApexEmailNotification> queryApexEmailNotifications() {
        String cacheKeyName = 'ApexEmailNotifications';
        if (LoggerCache.getOrganizationCache().containsKey(cacheKeyName) == true) {
            return (List<ApexEmailNotification>) LoggerCache.getOrganizationCache().get(cacheKeyName);
        }
        List<ApexEmailNotification> apexEmailNotifications = [SELECT Email, UserId FROM ApexEmailNotification WHERE Email != NULL OR User.IsActive = TRUE];
        LoggerCache.getOrganizationCache().put(cacheKeyName, apexEmailNotifications);
        return apexEmailNotifications;
    }

    public static Integer queryCountOfOpenApexJobs() {
        return [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE
                ApexClass.Name = :LogEntryEventHandler.class.getName()
                AND MethodName = 'setStatusApiDetails'
                AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
        ];
    }

    public static Integer queryCountOfRelatedRecordLogEntries(Id recordId) {
        return [SELECT COUNT() FROM LogEntry__c WHERE RecordId__c = :recordId];
    }

    public static List<UserRecordAccess> queryDeleteableUserRecordAccess(List<Id> recordIds) {
        return [SELECT RecordId FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId IN :recordIds AND HasDeleteAccess = TRUE];
    }

    public static List<FlowDefinitionView> queryFlowDefinitionViewsByFlowApiName(List<String> flowApiNames) {
        return [
            SELECT
                ActiveVersionId,
                ApiName,
                Description,
                DurableId,
                Label,
                LastModifiedBy, // This is a text field of the person's name - it's NOT a lookup to User :'(
                LastModifiedDate,
                ManageableState,
                ProcessType,
                TriggerType
            FROM FlowDefinitionView
            WHERE ApiName IN :flowApiNames AND IsActive = TRUE
        ];
    }

    public static List<FlowVersionView> queryFlowVersionViewsByDurableId(List<String> durableIds) {
        return [SELECT ApiVersionRuntime, FlowDefinitionViewId, RunInMode, Status, VersionNumber FROM FlowVersionView WHERE DurableId IN :durableIds];
    }

    public static Log__c queryLogById(String logId) {
        List<String> logFieldNames = new List<String>(Schema.Log__c.SObjectType.getDescribe().fields.getMap().keySet());
        logFieldNames.addAll(new List<String>{ 'Owner.Name', 'Owner.Type' });
        List<String> logEntryFieldNames = new List<String>(Schema.LogEntry__c.SObjectType.getDescribe().fields.getMap().keySet());

        List<String> textReplacements = new List<String>{
            String.join(logFieldNames, ','),
            String.join(logEntryFieldNames, ','),
            Schema.LogEntry__c.TransactionEntryNumber__c.getDescribe().getName(),
            Schema.Log__c.SObjectType.getDescribe().getName()
        };
        String query = String.format(
            'SELECT {0}, (SELECT {1} FROM LogEntries__r ORDER BY {2}) FROM {3} WHERE Id = :logId OR TransactionId__c = :logId',
            textReplacements
        );

        return (Log__c) Database.query(String.escapeSingleQuotes(query));
    }

    public static List<Log__c> queryLogsById(List<Id> logIds) {
        return [SELECT Id, Name, LoggedBy__c, LoggedBy__r.Name, StartTime__c, TotalLogEntries__c, TransactionId__c FROM Log__c WHERE Id IN :logIds];
    }

    public static List<Log__c> queryLogsByTransactionId(Set<String> transactionIds) {
        return [SELECT Id, TransactionId__c FROM Log__c WHERE TransactionId__c IN :transactionIds];
    }

    public static List<Profile> queryProfilesById(List<Id> profileIds) {
        return [SELECT Id, Name FROM Profile WHERE Id IN :profileIds ORDER BY Name];
    }

    public static List<Profile> queryProfilesByNameSearch(String searchTerm) {
        return [SELECT Id, Name, UserLicense.Name FROM Profile WHERE Name LIKE :searchTerm ORDER BY Name];
    }

    public static List<Group> queryQueuesByDeveloperName(List<String> queueDeveloperNames) {
        return [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueDeveloperNames];
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static List<LogEntry__c> queryRecordLogEntries(Id recordId, String fieldsClause, String orderByClause, Integer rowLimit) {
        List<Object> queryTextReplacements = new List<Object>{
            fieldsClause,
            String.valueOf(Schema.LogEntry__c.SObjectType),
            String.valueOf(Schema.LogEntry__c.RecordId__c),
            orderByClause,
            rowLimit
        };
        String logEntryQuery = 'SELECT {0} FROM {1} WHERE {2} = :recordId ORDER BY {3} LIMIT {4}';
        logEntryQuery = String.format(logEntryQuery, queryTextReplacements);

        return (List<LogEntry__c>) Database.query(String.escapeSingleQuotes(logEntryQuery));
    }

    public static List<LoggerTag__c> queryTags(Set<String> tagNames) {
        return [SELECT Id, Name FROM LoggerTag__c WHERE Name IN :tagNames];
    }

    public static List<Topic> queryTopics(Set<String> topicNames) {
        return [SELECT Id, Name FROM Topic WHERE Name IN :topicNames];
    }

    public static List<User> queryUsersById(List<Id> userIds) {
        return [SELECT Id, Username FROM User WHERE Id IN :userIds ORDER BY Username];
    }

    public static List<User> queryUsersByNameSearch(String searchTerm) {
        return [SELECT Id, Name, Username, SmallPhotoUrl FROM User WHERE Name LIKE :searchTerm OR Username LIKE :searchTerm ORDER BY Username];
    }

    public static List<User> queryUsersByUsername(List<String> usernames) {
        return [SELECT Id, Username FROM User WHERE Username IN :userNames ORDER BY Username];
    }
}
