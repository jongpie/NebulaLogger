//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Selector class used for all queries that are specific to the log management layer
 */
@SuppressWarnings('PMD.ApexCrudViolation, PMD.ExcessivePublicCount')
public without sharing class LogManagementDataSelector {
    private static final LogManagementDataSelector INSTANCE = new LogManagementDataSelector();

    @SuppressWarnings('PMD.EmptyStatementBlock')
    private LogManagementDataSelector() {
    }

    public static LogManagementDataSelector getInstance() {
        return INSTANCE;
    }

    public List<SObject> getAll(Schema.SObjectType sobjectType, Set<String> fieldNames) {
        // fieldNames.add('Id');
        String query = String.format('SELECT {0} FROM {1}', new List<Object>{ String.join(new List<String>(fieldNames), ', '), sobjectType });
        return Database.query(String.escapeSingleQuotes(query));
    }

    public List<SObject> getById(Schema.SObjectType sobjectType, Set<String> fieldNames, List<Id> recordIds) {
        // fieldNames.add('Id');
        String query = String.format(
            'SELECT {0} FROM {1} WHERE Id IN :recordIds',
            new List<Object>{ String.join(new List<String>(fieldNames), ', '), sobjectType }
        );
        return Database.query(String.escapeSingleQuotes(query));
    }

    public List<ApexClass> getApexClasses(List<String> apexClassNames) {
        return [
            SELECT ApiVersion, CreatedById, CreatedDate, Id, LastModifiedById, LastModifiedDate, Name
            FROM ApexClass
            WHERE Name IN :apexClassNames
            ORDER BY NamespacePrefix NULLS LAST
        ];
    }

    public List<ApexEmailNotification> getCachedApexEmailNotifications() {
        String cacheKeyName = 'ApexEmailNotifications';
        if (LoggerCache.getTransactionCache().contains(cacheKeyName) == true) {
            return (List<ApexEmailNotification>) LoggerCache.getTransactionCache().get(cacheKeyName);
        }

        List<ApexEmailNotification> apexEmailNotifications = [SELECT Email, UserId FROM ApexEmailNotification WHERE Email != NULL OR User.IsActive = TRUE];
        LoggerCache.getTransactionCache().put(cacheKeyName, apexEmailNotifications);
        return apexEmailNotifications;
    }

    public Integer getCountOfAsyncApexJobs(String apexClassName, String apexMethodName, List<String> jobStatuses) {
        return [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :apexClassName AND MethodName = :apexMethodName AND Status IN :jobStatuses];
    }

    public Integer getCountOfRelatedRecordLogEntries(Id recordId) {
        return [SELECT COUNT() FROM LogEntry__c WHERE RecordId__c = :recordId];
    }

    public List<UserRecordAccess> getDeleteableUserRecordAccess(List<Id> recordIds) {
        return [SELECT RecordId FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId IN :recordIds AND HasDeleteAccess = TRUE];
    }

    public List<FlowDefinitionView> getFlowDefinitionViewsByFlowApiName(List<String> flowApiNames) {
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

    public List<FlowVersionView> getFlowVersionViewsByDurableId(List<String> durableIds) {
        return [SELECT ApiVersionRuntime, FlowDefinitionViewId, RunInMode, Status, VersionNumber FROM FlowVersionView WHERE DurableId IN :durableIds];
    }

    public Log__c getLogById(String logId) {
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

    public List<Log__c> getLogsById(List<Id> logIds) {
        return [SELECT Id, Name, LoggedBy__c, LoggedBy__r.Name, StartTime__c, TotalLogEntries__c, TransactionId__c FROM Log__c WHERE Id IN :logIds];
    }

    public List<Log__c> getLogsByTransactionId(Set<String> transactionIds) {
        return [SELECT Id, TransactionId__c FROM Log__c WHERE TransactionId__c IN :transactionIds];
    }

    public List<Profile> getProfilesById(List<Id> profileIds) {
        return [SELECT Id, Name FROM Profile WHERE Id IN :profileIds ORDER BY Name];
    }

    public List<Profile> getProfilesByNameSearch(String searchTerm) {
        return [SELECT Id, Name, UserLicense.Name FROM Profile WHERE Name LIKE :searchTerm ORDER BY Name];
    }

    public List<Group> getQueuesByDeveloperName(List<String> queueDeveloperNames) {
        return [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueDeveloperNames];
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public List<LogEntry__c> getRecordLogEntries(Id recordId, String fieldsClause, String orderByClause, Integer rowLimit) {
        List<Object> queryTextReplacements = new List<Object>{
            fieldsClause,
            Schema.LogEntry__c.SObjectType.getDescribe().getName(),
            Schema.LogEntry__c.RecordId__c.getDescribe().getName(),
            orderByClause,
            rowLimit
        };
        String logEntryQuery = 'SELECT {0} FROM {1} WHERE {2} = :recordId ORDER BY {3} LIMIT {4}';
        logEntryQuery = String.format(logEntryQuery, queryTextReplacements);

        return (List<LogEntry__c>) Database.query(String.escapeSingleQuotes(logEntryQuery));
    }

    public List<LoggerTag__c> getTagsByName(Set<String> tagNames) {
        return [SELECT Id, Name FROM LoggerTag__c WHERE Name IN :tagNames];
    }

    public List<Topic> getTopicsByName(Set<String> topicNames) {
        return [SELECT Id, Name FROM Topic WHERE Name IN :topicNames];
    }

    public List<User> getUsersById(List<Id> userIds) {
        return [SELECT Id, Username FROM User WHERE Id IN :userIds ORDER BY Username];
    }

    public List<User> getUsersByNameSearch(String searchTerm) {
        return [SELECT Id, Name, Username, SmallPhotoUrl FROM User WHERE Name LIKE :searchTerm OR Username LIKE :searchTerm ORDER BY Username];
    }

    public List<User> getUsersByUsername(List<String> usernames) {
        return [SELECT Id, Username FROM User WHERE Username IN :userNames ORDER BY Username];
    }
}
