//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Selector class used for all queries that are specific to the log management layer
 */
@SuppressWarnings('PMD.ApexCrudViolation, PMD.ExcessivePublicCount')
public without sharing virtual class LogManagementDataSelector {
    private static LogManagementDataSelector instance = new LogManagementDataSelector();

    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    private LogManagementDataSelector() {
    }

    /**
     * @description The instance `LogManagementDataSelector` used for any querying specific to the log management layer
     * @return   The singleton instance of `LogManagementDataSelector`
     */
    public static LogManagementDataSelector getInstance() {
        return instance;
    }

    /**
     * @description Dynamically queries & returns all records in the specified `SObjectType`
     * @param  sobjectType The `SObjectType` to query
     * @param  fieldNames  `Set<String>` API names of any fields to include in the query
     * @return             `List<SObject>` containing any records in the specified `SObjectType`
     */
    public virtual List<SObject> getAll(Schema.SObjectType sobjectType, Set<String> fieldNames) {
        String query = String.format('SELECT {0} FROM {1}', new List<Object>{ String.join(fieldNames, ', '), sobjectType });
        return Database.query(String.escapeSingleQuotes(query));
    }

    /**
     * @description Dynamically queries & returns records in the specified `SObjectType` based on
     *              the specified record IDs
     * @param  sobjectType The `SObjectType` to query
     * @param  fieldNames  `Set<String>` API names of any fields to include in the query
     * @param  recordIds   `List<Id>` of record IDs to include in the query results
     * @return             `List<SObject>` containing any matching records in the specified `SObjectType`
     */
    public virtual List<SObject> getById(Schema.SObjectType sobjectType, Set<String> fieldNames, List<Id> recordIds) {
        String query = String.format('SELECT {0} FROM {1} WHERE Id IN :recordIds', new List<Object>{ String.join(fieldNames, ', '), sobjectType });
        return Database.query(String.escapeSingleQuotes(query));
    }

    /**
     * @description Returns a list of `ApexClass` records
     * @param  apexClassNames The names of the Apex classes to query
     * @return                `List<ApexClass>` containing any matching records
     */
    public virtual List<ApexClass> getApexClasses(List<String> apexClassNames) {
        if (LoggerParameter.QUERY_APEX_CLASS_DATA == false) {
            return new List<ApexClass>();
        }

        return [
            SELECT ApiVersion, CreatedById, CreatedDate, Id, LastModifiedById, LastModifiedDate, Name
            FROM ApexClass
            WHERE Name IN :apexClassNames
            ORDER BY NamespacePrefix NULLS LAST
        ];
    }

    /**
     * @description Returns a cached copy of the `ApexEmailNotification` records in the org
     * @return   The cached `List<ApexEmailNotification>` records
     */
    public virtual List<ApexEmailNotification> getCachedApexEmailNotifications() {
        String cacheKey = 'ApexEmailNotifications';
        if (LoggerCache.getOrganizationCache().contains(cacheKey)) {
            return (List<ApexEmailNotification>) LoggerCache.getOrganizationCache().get(cacheKey);
        }

        List<ApexEmailNotification> apexEmailNotifications = [SELECT Email, UserId FROM ApexEmailNotification WHERE Email != NULL OR User.IsActive = TRUE];
        LoggerCache.getOrganizationCache().put(cacheKey, apexEmailNotifications);
        return apexEmailNotifications;
    }

    /**
     * @description Returns a cached `Log__c` record that has been created within the last 4 hours
     *              that has API details populated from calling https://api.status.salesforce.com
     * @return   The cached `Log__c` record, or `null` if no match is found
     */
    public Log__c getCachedRecentLogWithApiReleaseDetails() {
        String cacheKey = 'RecentLogWithApiReleaseDetails';
        if (LoggerCache.getOrganizationCache().contains(cacheKey)) {
            return (Log__c) LoggerCache.getOrganizationCache().get(cacheKey);
        }

        // Query for recent logs created only today - the status API should be called
        // at least once per day to make sure that status details are still accurate.
        // This query should make a callout approximately every 4 hours.
        Datetime fourHoursAgo = System.now().addMinutes(-4 * 60);

        List<Log__c> logs = [
            SELECT Id, ApiReleaseNumber__c, ApiReleaseVersion__c, OrganizationReleaseNumber__c, OrganizationReleaseVersion__c
            FROM Log__c
            WHERE CreatedDate >= :fourHoursAgo AND CreatedDate = TODAY AND ApiReleaseNumber__c != NULL
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        Log__c log = logs.isEmpty() ? null : logs.get(0);
        LoggerCache.getOrganizationCache().put(cacheKey, log);
        return log;
    }

    /**
     * @description Returns the count of `AsyncApexJob` records with the specified Apex class name, method name & job status
     * @param  apexClassName  The fully-qualified name of the Apex class associated with `AsyncApexJob`
     * @param  apexMethodName The specific method (if any) within the Apex class associated with `AsyncApexJob`
     * @param  jobStatuses    The list of job statuses that should be used to filter `AsynxApexJob` records
     * @return                The `Integer` count of matching `AsynxApexJob` records
     */
    public virtual Integer getCountOfAsyncApexJobs(String apexClassName, String apexMethodName, List<String> jobStatuses) {
        return [SELECT COUNT() FROM AsyncApexJob WHERE ApexClass.Name = :apexClassName AND MethodName = :apexMethodName AND Status IN :jobStatuses];
    }

    /**
     * @description Returns the count of `LogEntry__c` records related to the specified record ID
     * @param  recordId The `ID` to use for filtering `LogEntry__c` records
     * @return          The `Integer` count of matching `LogEntry__c` records
     */
    public virtual Integer getCountOfRelatedRecordLogEntries(Id recordId) {
        return [SELECT COUNT() FROM LogEntry__c WHERE RecordId__c = :recordId];
    }

    /**
     * @description Returns the list of `UserRecordAccess` records for any of the specified record IDs that the current user can delete
     * @param  recordIds The list of `ID` for records to be deleted
     * @return           The matching `List<UserRecordAccess>` records
     */
    public virtual List<UserRecordAccess> getDeleteableUserRecordAccess(List<Id> recordIds) {
        return [SELECT RecordId FROM UserRecordAccess WHERE UserId = :System.UserInfo.getUserId() AND RecordId IN :recordIds AND HasDeleteAccess = TRUE];
    }

    /**
     * @description Returns a list of `FlowDefinitionView` records
     * @param  flowApiNames The names of the Apex classes to query
     * @return              `List<FlowDefinitionView>` containing any matching records
     */
    public virtual List<FlowDefinitionView> getFlowDefinitionViewsByFlowApiName(List<String> flowApiNames) {
        if (LoggerParameter.QUERY_FLOW_DEFINITION_VIEW_DATA == false) {
            return new List<FlowDefinitionView>();
        }

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
                RecordTriggerType,
                TriggerObjectOrEvent.QualifiedApiName,
                TriggerOrder,
                TriggerType,
                VersionNumber
            FROM FlowDefinitionView
            WHERE ApiName IN :flowApiNames AND IsActive = TRUE
        ];
    }

    /**
     * @description Returns a list of `FlowVersionView` records description
     * @param  durableIds The durable IDs of the Flows to query
     * @return            `List<FlowDefinitionView>` containing any matching records
     */
    public virtual List<FlowVersionView> getFlowVersionViewsByDurableId(List<String> durableIds) {
        return [SELECT ApiVersionRuntime, FlowDefinitionViewId, RunInMode, Status, VersionNumber FROM FlowVersionView WHERE DurableId IN :durableIds];
    }

    /**
     * @description Returns a `Log__c` record
     * @param  logId The `ID` of the `Log__c` record to query
     * @return       The matching `Log__c` record
     */
    public virtual Log__c getLogById(Id logId) {
        String queryTemplate = 'SELECT {0} FROM {1} WHERE Id = :logId';

        List<String> logFieldNames = new List<String>(Schema.Log__c.SObjectType.getDescribe().fields.getMap().keySet());
        logFieldNames.addAll(new List<String>{ 'Owner.Name', 'Owner.Type' });
        List<String> textReplacements = new List<String>{ String.join(logFieldNames, ','), Schema.Log__c.SObjectType.getDescribe().getName() };

        String query = String.format(queryTemplate, textReplacements);
        return (Log__c) Database.query(String.escapeSingleQuotes(query));
    }

    /**
     * @description Returns a `List<LogEntry__c>` records for the specified `Log__c` ID
     * @param  logId The `ID` of the `Log__c` record of the `LogEntry__c` records to query
     * @return       The matching `List<LogEntry__c>` records
     */
    public virtual List<LogEntry__c> getLogEntriesByLogId(Id logId) {
        String queryTemplate = 'SELECT {0} FROM {1} WHERE {2} = :logId ORDER BY {3}';

        List<String> logEntryFieldNames = new List<String>(Schema.LogEntry__c.SObjectType.getDescribe().fields.getMap().keySet());
        List<String> textReplacements = new List<String>{
            String.join(logEntryFieldNames, ', '),
            Schema.LogEntry__c.SObjectType.getDescribe().getName(),
            Schema.LogEntry__c.Log__c.getDescribe().getName(),
            Schema.LogEntry__c.TransactionEntryNumber__c.getDescribe().getName()
        };

        String query = String.format(queryTemplate, textReplacements);
        return (List<LogEntry__c>) Database.query(String.escapeSingleQuotes(query));
    }

    /**
     * @description Returns a `Log__c` record and its related `LogEntry__c` records
     * @param  logIds The list of `ID` of the `Log__c` records to query
     * @return        The list of matching `Log__c` records
     */
    public virtual List<Log__c> getLogsById(List<Id> logIds) {
        return [SELECT Id, Name, LoggedBy__c, LoggedBy__r.Name, StartTime__c, TotalLogEntries__c, TransactionId__c FROM Log__c WHERE Id IN :logIds];
    }

    /**
     * @description Returns a `List<Log__c>` of records with the specified transaction IDs
     * @param  transactionIds The list of `String` transaction IDs of the `Log__c` records to query
     * @return                The list of matching `Log__c` records
     */
    public virtual List<Log__c> getLogsByTransactionId(List<String> transactionIds) {
        return [SELECT Id, TransactionId__c FROM Log__c WHERE TransactionId__c IN :transactionIds];
    }

    /**
     * @description Returns a `List<LoggerScenario__c>` of records with the specified log scenario IDs
     * @param  logScenarioIds The list of `ID` of the `Log__c` records to query
     * @return                The list of matching `LoggerScenario__c` records
     */
    public virtual List<LoggerScenario__c> getLoggerScenariosById(List<Id> logScenarioIds) {
        return [SELECT Id, OwnerId, UniqueId__c FROM LoggerScenario__c WHERE Id IN :logScenarioIds];
    }

    /**
     * @description Returns a `List<Profile>` of records with the specified profile IDs
     * @param  profileIds The list of `ID` of the `Profile` records to query
     * @return            The list of matching `Profile` records
     */
    public virtual List<Profile> getProfilesById(List<Id> profileIds) {
        return [SELECT Id, Name FROM Profile WHERE Id IN :profileIds];
    }

    /**
     * @description Returns a `List<Profile>` of records where the profile's names partially matches the specified search term
     * @param  searchTerm The `String` search term to use for searching `Profile` records
     * @return            The list of matching `Profile` records
     */
    public virtual List<Profile> getProfilesByNameSearch(String searchTerm) {
        return [SELECT Id, Name, UserLicense.Name FROM Profile WHERE Name LIKE :searchTerm];
    }

    /**
     * @description Returns a `List<Group>` of records with the specified developer names and type == 'Queue'
     * @param  queueDeveloperNames The list of `String` queue developer names to query
     * @return                     The list of matching `Group` records
     */
    public virtual List<Group> getQueuesByDeveloperName(List<String> queueDeveloperNames) {
        return [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueDeveloperNames];
    }

    /**
     * @description Returns the list of `LogEntry__c` records related to the specified record ID
     * @param  recordId      The `ID` to use for filtering `LogEntry__c` records
     * @param  fieldsClause  A comma-separated `String` of field API names to include in the query
     * @param  orderByClause A comma-separated `String` of field API names to use for sorting the query results
     * @param  rowLimit      The maximum number of records to return
     * @return               The list of matching `LogEntry__c` records
     */
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

    /**
     * @description Returns a list of `LoggerTag__c` records with one of the specified tag names
     * @param  tagNames The set of `String` tag names to query
     * @return          The list of matching `LoggerTag__c` records
     */
    public virtual List<LoggerTag__c> getTagsByName(Set<String> tagNames) {
        return [SELECT Id, Name FROM LoggerTag__c WHERE Name IN :tagNames];
    }

    /**
     * @description Returns a list of `Topic` records with one of the specified topic names
     * @param  topicNames The set of `String` topic names to query
     * @return            The list of matching `Topic` records
     */
    public virtual List<Topic> getTopicsByName(Set<String> topicNames) {
        return [SELECT Id, Name FROM Topic WHERE Name IN :topicNames];
    }

    /**
     * @description Returns a `List<User>` of records with the specified user IDs
     * @param  userIds The list of `ID` of the `User` records to query
     * @return         The list of matching `User` records
     */
    public virtual List<User> getUsersById(List<Id> userIds) {
        return [SELECT Id, Username FROM User WHERE Id IN :userIds];
    }

    /**
     * @description Returns a `List<User>` of records where the User's names or username partially matches the specified search term
     * @param  searchTerm The `String` search term to use for searching `User` records
     * @return            The list of matching `User` records
     */
    public virtual List<User> getUsersByNameSearch(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            return new List<User>();
        }

        return [SELECT Id, Name, Username, SmallPhotoUrl FROM User WHERE Name LIKE :searchTerm OR Username LIKE :searchTerm ORDER BY Username LIMIT 20];
    }

    /**
     * @description Returns a `List<User>` of records with the specified usernames (`Schema.User.Username`)
     * @param  usernames The list of `String` user usernames to query
     * @return           Tje list of matching `User` records
     */
    public virtual List<User> getUsersByUsername(List<String> usernames) {
        return [SELECT Id, Username FROM User WHERE Username IN :userNames];
    }

    @TestVisible
    private static void setMock(LogManagementDataSelector mockSelectorInstance) {
        instance = mockSelectorInstance;
    }
}
