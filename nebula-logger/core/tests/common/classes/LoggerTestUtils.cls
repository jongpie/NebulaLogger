//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions, PMD.PropertyNamingConventions')
@IsTest
public class LoggerTestUtils {
    private static final String FAKE_DATA_STRING = 'someFakeData';
    private static final Integer FAKE_DATA_NUMBER = 1;
    private static final Map<Schema.SObjectType, Integer> SOBJECT_TYPE_TO_MOCK_ID_COUNT = new Map<Schema.SObjectType, Integer>();

    // Lazy-load & cache permission sets & profiles
    private static final Map<String, PermissionSet> PERMISSION_SETS_BY_NAME {
        get {
            if (PERMISSION_SETS_BY_NAME == null) {
                PERMISSION_SETS_BY_NAME = queryPermissionSets();
            }
            return PERMISSION_SETS_BY_NAME;
        }
        private set;
    }

    private static final PermissionSet LOGGER_ADMIN_PERMISSION_SET {
        get {
            if (LOGGER_ADMIN_PERMISSION_SET == null) {
                LOGGER_ADMIN_PERMISSION_SET = PERMISSION_SETS_BY_NAME.get('LoggerAdmin');
            }
            return LOGGER_ADMIN_PERMISSION_SET;
        }
        private set;
    }

    private static final PermissionSet LOGGER_LOG_VIEWER_PERMISSION_SET {
        get {
            if (LOGGER_LOG_VIEWER_PERMISSION_SET == null) {
                LOGGER_LOG_VIEWER_PERMISSION_SET = PERMISSION_SETS_BY_NAME.get('LoggerLogViewer');
            }
            return LOGGER_LOG_VIEWER_PERMISSION_SET;
        }
        private set;
    }

    private static final PermissionSet LOGGER_END_USER_PERMISSION_SET {
        get {
            if (LOGGER_END_USER_PERMISSION_SET == null) {
                LOGGER_END_USER_PERMISSION_SET = PERMISSION_SETS_BY_NAME.get('LoggerEndUser');
            }
            return LOGGER_END_USER_PERMISSION_SET;
        }
        private set;
    }

    private static final PermissionSet LOGGER_LOG_CREATOR_PERMISSION_SET {
        get {
            if (LOGGER_LOG_CREATOR_PERMISSION_SET == null) {
                LOGGER_LOG_CREATOR_PERMISSION_SET = PERMISSION_SETS_BY_NAME.get('LoggerLogCreator');
            }
            return LOGGER_LOG_CREATOR_PERMISSION_SET;
        }
        private set;
    }

    /**
     * @description Assigns the permission set `LoggerAdmin` to the specified user ID
     * @param  userId The ID of the user that should be assigned the permission set
     */
    public static void assignAdminPermissionSet(Id userId) {
        assignPermissionSet(userId, LOGGER_ADMIN_PERMISSION_SET);
    }

    /**
     * @description Assigns the permission set `LoggerLogViewer` to the specified user ID
     * @param  userId The ID of the user that should be assigned the permission set
     */
    public static void assignLogViewerPermissionSet(Id userId) {
        assignPermissionSet(userId, LOGGER_LOG_VIEWER_PERMISSION_SET);
    }

    /**
     * @description Assigns the permission set `LoggerEndUser` to the specified user ID
     * @param  userId The ID of the user that should be assigned the permission set
     */
    public static void assignEndUserPermissionSet(Id userId) {
        assignPermissionSet(userId, LOGGER_END_USER_PERMISSION_SET);
    }

    /**
     * @description Assigns the permission set `LoggerLogCreator` to the specified user ID
     * @param  userId The ID of the user that should be assigned the permission set
     */
    public static void assignLogCreatorPermissionSet(Id userId) {
        assignPermissionSet(userId, LOGGER_LOG_CREATOR_PERMISSION_SET);
    }

    /**
     * @description Creates a `Log__c` record that can be used in tests
     * @return   An instance of `Log__c` with sample data populated
     */
    public static Log__c createLog() {
        return new Log__c(
            ApiVersion__c = '52',
            Locale__c = FAKE_DATA_STRING,
            LoggedBy__c = UserInfo.getUserId(),
            LoggedByUsername__c = FAKE_DATA_STRING,
            LoginApplication__c = FAKE_DATA_STRING,
            LoginBrowser__c = FAKE_DATA_STRING,
            LoginHistoryId__c = FAKE_DATA_STRING,
            LoginPlatform__c = FAKE_DATA_STRING,
            LoginType__c = FAKE_DATA_STRING,
            LogoutUrl__c = FAKE_DATA_STRING,
            NetworkId__c = FAKE_DATA_STRING,
            NetworkLoginUrl__c = FAKE_DATA_STRING,
            NetworkLogoutUrl__c = FAKE_DATA_STRING,
            NetworkSelfRegistrationUrl__c = FAKE_DATA_STRING,
            NetworkUrlPathPrefix__c = FAKE_DATA_STRING,
            OrganizationDomainUrl__c = FAKE_DATA_STRING,
            OrganizationEnvironmentType__c = FAKE_DATA_STRING,
            OrganizationId__c = FAKE_DATA_STRING,
            OrganizationInstanceName__c = FAKE_DATA_STRING,
            OrganizationName__c = FAKE_DATA_STRING,
            OrganizationNamespacePrefix__c = FAKE_DATA_STRING,
            OrganizationType__c = FAKE_DATA_STRING,
            ProfileId__c = FAKE_DATA_STRING,
            ProfileName__c = FAKE_DATA_STRING,
            SessionId__c = FAKE_DATA_STRING,
            SessionSecurityLevel__c = FAKE_DATA_STRING,
            SessionType__c = FAKE_DATA_STRING,
            SourceIp__c = FAKE_DATA_STRING,
            SystemMode__c = FAKE_DATA_STRING,
            ThemeDisplayed__c = FAKE_DATA_STRING,
            TimeZoneId__c = FAKE_DATA_STRING,
            UserLicenseDefinitionKey__c = FAKE_DATA_STRING,
            UserLicenseName__c = FAKE_DATA_STRING,
            UserLoggingLevel__c = FAKE_DATA_STRING,
            UserLoggingLevelOrdinal__c = FAKE_DATA_NUMBER,
            UserRoleId__c = FAKE_DATA_STRING,
            UserRoleName__c = FAKE_DATA_STRING,
            UserType__c = FAKE_DATA_STRING,
            TransactionId__c = '1234'
        );
    }

    /**
     * @description Creates a `LogEntry__c` record that can be used in tests
     * @return   An instance of `LogEntry__c` with sample data populated
     */
    public static LogEntry__c createLogEntry() {
        return new LogEntry__c(
            DatabaseResultCollectionType__c = FAKE_DATA_STRING,
            DatabaseResultJson__c = FAKE_DATA_STRING,
            DatabaseResultType__c = FAKE_DATA_STRING,
            ExceptionMessage__c = FAKE_DATA_STRING,
            ExceptionStackTrace__c = FAKE_DATA_STRING,
            ExceptionType__c = FAKE_DATA_STRING,
            LimitsAggregateQueriesMax__c = FAKE_DATA_NUMBER,
            LimitsAggregateQueriesUsed__c = FAKE_DATA_NUMBER,
            LimitsAsyncCallsMax__c = FAKE_DATA_NUMBER,
            LimitsAsyncCallsUsed__c = FAKE_DATA_NUMBER,
            LimitsCalloutsUsed__c = FAKE_DATA_NUMBER,
            LimitsCpuTimeMax__c = FAKE_DATA_NUMBER,
            LimitsCpuTimeUsed__c = FAKE_DATA_NUMBER,
            LimitsDmlRowsMax__c = FAKE_DATA_NUMBER,
            LimitsDmlRowsUsed__c = FAKE_DATA_NUMBER,
            LimitsDmlStatementsMax__c = FAKE_DATA_NUMBER,
            LimitsDmlStatementsUsed__c = FAKE_DATA_NUMBER,
            LimitsEmailInvocationsMax__c = FAKE_DATA_NUMBER,
            LimitsEmailInvocationsUsed__c = FAKE_DATA_NUMBER,
            LimitsFutureCallsMax__c = FAKE_DATA_NUMBER,
            LimitsFutureCallsUsed__c = FAKE_DATA_NUMBER,
            LimitsHeapSizeMax__c = FAKE_DATA_NUMBER,
            LimitsHeapSizeUsed__c = FAKE_DATA_NUMBER,
            LimitsMobilePushApexCallsMax__c = FAKE_DATA_NUMBER,
            LimitsMobilePushApexCallsUsed__c = FAKE_DATA_NUMBER,
            LimitsQueueableJobsMax__c = FAKE_DATA_NUMBER,
            LimitsQueueableJobsUsed__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueriesMax__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueriesUsed__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueryLocatorRowsMax__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueryLocatorRowsUsed__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueryRowsMax__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueryRowsUsed__c = FAKE_DATA_NUMBER,
            LimitsSoslSearchesMax__c = FAKE_DATA_NUMBER,
            LimitsSoslSearchesUsed__c = FAKE_DATA_NUMBER,
            LoggingLevel__c = FAKE_DATA_STRING,
            LoggingLevelOrdinal__c = FAKE_DATA_NUMBER,
            Message__c = FAKE_DATA_STRING,
            OriginLocation__c = FAKE_DATA_STRING,
            OriginType__c = FAKE_DATA_STRING,
            RecordCollectionType__c = FAKE_DATA_STRING,
            RecordId__c = FAKE_DATA_STRING,
            RecordJson__c = FAKE_DATA_STRING,
            RecordSObjectClassification__c = FAKE_DATA_STRING,
            RecordSObjectType__c = FAKE_DATA_STRING,
            RecordSObjectTypeNamespace__c = FAKE_DATA_STRING,
            StackTrace__c = FAKE_DATA_STRING,
            Timestamp__c = System.now(),
            TransactionEntryNumber__c = FAKE_DATA_NUMBER,
            TriggerOperationType__c = FAKE_DATA_STRING,
            TriggerSObjectType__c = FAKE_DATA_STRING
        );
    }

    /**
     * @description Creates a `LogEntryEvent__e` record that can be used in tests
     * @param  timestamp The `Datetime` value to use for the `Timestamp__c` field on `LogEntryEvent__e`
     * @return   An instance of `LogEntryEvent__e` with sample data populated
     */
    public static LogEntryEvent__e createLogEntryEvent(Datetime timestamp) {
        return new LogEntryEvent__e(
            ApiVersion__c = '52',
            DatabaseResultCollectionType__c = FAKE_DATA_STRING,
            DatabaseResultJson__c = FAKE_DATA_STRING,
            DatabaseResultType__c = FAKE_DATA_STRING,
            ExceptionMessage__c = FAKE_DATA_STRING,
            ExceptionStackTrace__c = FAKE_DATA_STRING,
            ExceptionType__c = FAKE_DATA_STRING,
            LimitsAggregateQueriesMax__c = FAKE_DATA_NUMBER,
            LimitsAggregateQueriesUsed__c = FAKE_DATA_NUMBER,
            LimitsAsyncCallsMax__c = FAKE_DATA_NUMBER,
            LimitsAsyncCallsUsed__c = FAKE_DATA_NUMBER,
            LimitsCalloutsUsed__c = FAKE_DATA_NUMBER,
            LimitsCpuTimeMax__c = FAKE_DATA_NUMBER,
            LimitsCpuTimeUsed__c = FAKE_DATA_NUMBER,
            LimitsDmlRowsMax__c = FAKE_DATA_NUMBER,
            LimitsDmlRowsUsed__c = FAKE_DATA_NUMBER,
            LimitsDmlStatementsMax__c = FAKE_DATA_NUMBER,
            LimitsDmlStatementsUsed__c = FAKE_DATA_NUMBER,
            LimitsEmailInvocationsMax__c = FAKE_DATA_NUMBER,
            LimitsEmailInvocationsUsed__c = FAKE_DATA_NUMBER,
            LimitsFutureCallsMax__c = FAKE_DATA_NUMBER,
            LimitsFutureCallsUsed__c = FAKE_DATA_NUMBER,
            LimitsHeapSizeMax__c = FAKE_DATA_NUMBER,
            LimitsHeapSizeUsed__c = FAKE_DATA_NUMBER,
            LimitsMobilePushApexCallsMax__c = FAKE_DATA_NUMBER,
            LimitsMobilePushApexCallsUsed__c = FAKE_DATA_NUMBER,
            LimitsQueueableJobsMax__c = FAKE_DATA_NUMBER,
            LimitsQueueableJobsUsed__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueriesMax__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueriesUsed__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueryLocatorRowsMax__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueryLocatorRowsUsed__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueryRowsMax__c = FAKE_DATA_NUMBER,
            LimitsSoqlQueryRowsUsed__c = FAKE_DATA_NUMBER,
            LimitsSoslSearchesMax__c = FAKE_DATA_NUMBER,
            LimitsSoslSearchesUsed__c = FAKE_DATA_NUMBER,
            Locale__c = FAKE_DATA_STRING,
            LoggedByUsername__c = FAKE_DATA_STRING,
            LoggingLevel__c = FAKE_DATA_STRING,
            LoggingLevelOrdinal__c = FAKE_DATA_NUMBER,
            LoginApplication__c = FAKE_DATA_STRING,
            LoginBrowser__c = FAKE_DATA_STRING,
            LoginHistoryId__c = FAKE_DATA_STRING,
            LoginPlatform__c = FAKE_DATA_STRING,
            LoginType__c = FAKE_DATA_STRING,
            LogoutUrl__c = FAKE_DATA_STRING,
            Message__c = FAKE_DATA_STRING,
            NetworkId__c = FAKE_DATA_STRING,
            NetworkLoginUrl__c = FAKE_DATA_STRING,
            NetworkLogoutUrl__c = FAKE_DATA_STRING,
            NetworkSelfRegistrationUrl__c = FAKE_DATA_STRING,
            NetworkUrlPathPrefix__c = FAKE_DATA_STRING,
            OrganizationDomainUrl__c = FAKE_DATA_STRING,
            OrganizationEnvironmentType__c = FAKE_DATA_STRING,
            OrganizationId__c = FAKE_DATA_STRING,
            OrganizationInstanceName__c = FAKE_DATA_STRING,
            OrganizationName__c = FAKE_DATA_STRING,
            OrganizationNamespacePrefix__c = FAKE_DATA_STRING,
            OrganizationType__c = FAKE_DATA_STRING,
            OriginLocation__c = FAKE_DATA_STRING,
            OriginType__c = FAKE_DATA_STRING,
            ProfileId__c = FAKE_DATA_STRING,
            ProfileName__c = FAKE_DATA_STRING,
            RecordCollectionType__c = FAKE_DATA_STRING,
            RecordId__c = FAKE_DATA_STRING,
            RecordJson__c = FAKE_DATA_STRING,
            RecordSObjectClassification__c = FAKE_DATA_STRING,
            RecordSObjectType__c = FAKE_DATA_STRING,
            RecordSObjectTypeNamespace__c = FAKE_DATA_STRING,
            SessionId__c = FAKE_DATA_STRING,
            SessionSecurityLevel__c = FAKE_DATA_STRING,
            SessionType__c = FAKE_DATA_STRING,
            SourceIp__c = FAKE_DATA_STRING,
            StackTrace__c = FAKE_DATA_STRING,
            Tags__c = FAKE_DATA_STRING,
            ThemeDisplayed__c = FAKE_DATA_STRING,
            Timestamp__c = timestamp,
            TimestampString__c = String.valueOf(timestamp.getTime()),
            TimeZoneId__c = FAKE_DATA_STRING,
            TransactionEntryNumber__c = FAKE_DATA_NUMBER,
            TransactionId__c = FAKE_DATA_STRING,
            TriggerOperationType__c = FAKE_DATA_STRING,
            TriggerSObjectType__c = FAKE_DATA_STRING,
            UserLicenseDefinitionKey__c = FAKE_DATA_STRING,
            UserLicenseName__c = FAKE_DATA_STRING,
            UserLoggingLevel__c = FAKE_DATA_STRING,
            UserLoggingLevelOrdinal__c = FAKE_DATA_NUMBER,
            UserRoleId__c = FAKE_DATA_STRING,
            UserRoleName__c = FAKE_DATA_STRING,
            UserType__c = FAKE_DATA_STRING
        );
    }

    /**
     * @description Instances of `AggregateResult` can not be created directly in Apex.
     *              This method uses a workaround to generate a mock.
     * @return   The mock instance of `AggregateResult`
     */
    public static AggregateResult createMockAggregateResult() {
        Map<String, Object> defaultMockAggregateKeyValues = new Map<String, Object>{
            'fieldAvg' => 62.5,
            'fieldMax' => 100,
            'fieldMin' => 25,
            'fieldCount' => 4
        };
        return createMockAggregateResult(defaultMockAggregateKeyValues);
    }

    /**
     * @description Instances of `AggregateResult` can not be created directly in Apex.
     *              This method uses a workaround to generate a mock, using the provided map of aliases & aggregate values
     * @param  mockAggregateKeyValues A map of aliases & aggregate values to use when creating the mock `AggregateResult`
     * @return   The mock instance of `AggregateResult`
     */
    public static AggregateResult createMockAggregateResult(Map<String, Object> mockAggregateKeyValues) {
        return (AggregateResult) JSON.deserialize(JSON.serialize(mockAggregateKeyValues), AggregateResult.class);
    }

    /**
     * @description Generates a mock record ID for the provided SObject Type
     * @param  sobjectType The SObject Type for the generated mock record ID
     * @return   The mock record ID for the specified SObject Type
     */
    public static String createMockId(Schema.SObjectType sobjectType) {
        Integer recordIdNumber = 1;
        if (SOBJECT_TYPE_TO_MOCK_ID_COUNT.containsKey(sobjectType)) {
            recordIdNumber = SOBJECT_TYPE_TO_MOCK_ID_COUNT.get(sobjectType);
        }
        String recordIdSuffix = String.valueOf(recordIdNumber++);
        SOBJECT_TYPE_TO_MOCK_ID_COUNT.put(sobjectType, recordIdNumber);

        String recordIdKeyPrefix = sobjectType.getDescribe().getKeyPrefix();
        Integer idFieldLength = sobjectType.getDescribe().fields.getMap().get('Id').getDescribe().getLength();
        Integer recordIdCenterLength = idFieldLength - recordIdKeyPrefix.length() - recordIdSuffix.length();
        return recordIdKeyPrefix + '0'.repeat(recordIdCenterLength) + recordIdSuffix;
    }

    /**
     * @description Creates a `User` record for testing purposes, using the current user's profile
     * @return   The generated `User` record - it is not automatically inserted into the database.
     */
    public static User createUser() {
        return createUser(UserInfo.getProfileId());
    }

    /**
     * @description Creates a `User` record for testing purposes, using the specified profile ID
     * @param  profileId The `Profile` ID to use for the created `User`
     * @return   The generated `User` record - it is not automatically inserted into the database.
     */
    public static User createUser(Id profileId) {
        return new User(
            Alias = 'log_xyz',
            Email = 'logger_xyz@test.com.net.org',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            LastName = 'Logger test user',
            LocaleSidKey = 'en_US',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'logger_xyz@test.com.net.org'
        );
    }

    /**
     * @description Queries for the `Organization` record for the current environment.
     * @return   The matching `Organization` record
     */
    public static Organization getOrganization() {
        return [SELECT Id, Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization];
    }

    /**
     * @description Returns the current environment's type - Scratch Org, Sandbox, or Production.
     * @return   The environment type
     */
    public static String getOrganizationEnvironmentType() {
        Organization organization = getOrganization();

        String orgEnvironmentType;
        if (organization.IsSandbox == true && organization.TrialExpirationDate != null) {
            orgEnvironmentType = 'Scratch Org';
        } else if (organization.IsSandbox == true) {
            orgEnvironmentType = 'Sandbox';
        } else {
            orgEnvironmentType = 'Production';
        }
        return orgEnvironmentType;
    }

    /**
     * @description Returns the current user's `Network` (Experience Cloud site)
     * @return   The matching `Network` record
     */
    public static SObject getNetwork() {
        if (Network.getNetworkId() == null) {
            return null;
        }

        String networkApiName = 'Network';
        // Networks (communities) may not be enabled in the org (no Network object), so run everything dynamically
        Boolean networksEnabled = Schema.getGlobalDescribe().containsKey(networkApiName);

        if (!networksEnabled) {
            return null;
        }

        String query = 'SELECT Id, Name, UrlPathPrefix FROM Network WHERE Id = :Network.getNetworkId()';
        return Database.query(String.escapeSingleQuotes(query));
    }

    /**
     * @description Returns the current user
     * @return   The matching `User` record
     */
    public static User getCurrentUser() {
        return [
            SELECT Id, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.LicenseDefinitionKey, Profile.UserLicense.Name, Username, UserRole.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
    }

    /**
     * @description Creates and inserts a `Group` record for testing queues, using the specified SObject Type
     * @param  sobjectType The SObjectType that the queue should be able to own (stored in `QueueSObject`)
     * @return   The inserted `Group` record - it is automatically inserted into the database, as well as 1 child `QueueSObject` record.
     */
    public static Group insertQueue(Schema.SObjectType sobjectType) {
        Group loggerQueue = new Group(DeveloperName = 'Some_Log_Queue', Name = 'Some Log Queue', Type = 'Queue');
        insert loggerQueue;

        // To avoid a MIXED_DML_OPERATION exception, use System.runs() for inserting the QueueSObject record
        System.runAs(new User(Id = UserInfo.getUserId())) {
            QueueSObject loggerQueueSObject = new QueueSObject(QueueId = loggerQueue.Id, SObjectType = sobjectType.getDescribe().getName());
            insert loggerQueueSObject;
        }

        return loggerQueue;
    }

    // Helper methods
    private static void assignPermissionSet(Id userId, PermissionSet permissionSet) {
        PermissionSetAssignment permissionSetAssignment = new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSet.Id);
        insert permissionSetAssignment;
    }

    private static Map<String, PermissionSet> queryPermissionSets() {
        List<String> permissionSetNames = new List<String>{ 'LoggerAdmin', 'LoggerLogViewer', 'LoggerEndUser', 'LoggerLogCreator' };
        Map<String, PermissionSet> results = new Map<String, PermissionSet>();
        for (PermissionSet permissionSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissionSetNames]) {
            results.put(permissionSet.Name, permissionSet);
        }
        return results;
    }
}
