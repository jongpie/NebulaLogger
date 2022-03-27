//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Utility class used to help with writing Apex tests Nebula Logger.
 *              These methods can be used when writing Apex tests for plugins.
 * @see LoggerSObjectTestDataGenerator
 */
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.ExcessivePublicCount, PMD.MethodNamingConventions, PMD.PropertyNamingConventions')
@IsTest
public class LoggerTestUtils {
    private static final Map<Schema.SObjectType, Integer> SOBJECT_TYPE_TO_MOCK_ID_COUNT = new Map<Schema.SObjectType, Integer>();
    private static Integer userMockUsernameCount = 0;

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

    /**
     * @description Assigns the permission set `LoggerAdmin` to the specified user ID
     * @param  userId The ID of the user that should be assigned the permission set
     */
    public static void assignAdminPermissionSet(Id userId) {
        assignPermissionSet(userId, PERMISSION_SETS_BY_NAME.get('LoggerAdmin'));
    }

    /**
     * @description Assigns the permission set `LoggerLogViewer` to the specified user ID
     * @param  userId The ID of the user that should be assigned the permission set
     */
    public static void assignLogViewerPermissionSet(Id userId) {
        assignPermissionSet(userId, PERMISSION_SETS_BY_NAME.get('LoggerLogViewer'));
    }

    /**
     * @description Assigns the permission set `LoggerEndUser` to the specified user ID
     * @param  userId The ID of the user that should be assigned the permission set
     */
    public static void assignEndUserPermissionSet(Id userId) {
        assignPermissionSet(userId, PERMISSION_SETS_BY_NAME.get('LoggerEndUser'));
    }

    /**
     * @description Assigns the permission set `LoggerLogCreator` to the specified user ID
     * @param  userId The ID of the user that should be assigned the permission set
     */
    public static void assignLogCreatorPermissionSet(Id userId) {
        assignPermissionSet(userId, PERMISSION_SETS_BY_NAME.get('LoggerLogCreator'));
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
     * @description Creates a mock instance of `Database.DeleteResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests). A fake
     *              record ID is automatically included.
     * @param  isSuccess Indicates if the generated mock should have `isSuccess` == true
     * @return   The mock instance of `Database.DeleteResult`
     */
    public static Database.DeleteResult createMockDatabaseDeleteResult(Boolean isSuccess) {
        return createMockDatabaseDeleteResult(isSuccess, createMockId(Schema.Account.SObjectType));
    }

    /**
     * @description Creates a mock instance of `Database.DeleteResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests)
     * @param  isSuccess Indicates if the generated mock should have `isSuccess` == true
     * @param  recordId  The record ID to use within the mock result
     * @return   The mock instance of `Database.DeleteResult`
     */
    public static Database.DeleteResult createMockDatabaseDeleteResult(Boolean isSuccess, Id recordId) {
        if (isSuccess == true) {
            return (Database.DeleteResult) JSON.deserialize('{"success": true, "id": "' + recordId + '"}', Database.DeleteResult.class);
        } else {
            return (Database.DeleteResult) JSON.deserialize(
                '{"success":false,"errors":[{"message": "Could not delete...", "statusCode": "DELETE_FAILED"}]}',
                Database.DeleteResult.class
            );
        }
    }

    /**
     * @description Creates a mock instance of `Database.MergeResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests). A fake
     *              record ID is automatically included.
     * @param  isSuccess Indicates if the generated mock should have `isSuccess` == true
     * @return   The mock instance of `Database.MergeResult`
     */
    public static Database.MergeResult createMockDatabaseMergeResult(Boolean isSuccess) {
        return createMockDatabaseMergeResult(isSuccess, createMockId(Schema.Account.SObjectType));
    }

    /**
     * @description Creates a mock instance of `Database.MergeResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests)
     * @param  isSuccess Indicates if the generated mock should have `isSuccess` == true
     * @param  recordId  The record ID to use within the mock result
     * @return   The mock instance of `Database.MergeResult`
     */
    public static Database.MergeResult createMockDatabaseMergeResult(Boolean isSuccess, Id recordId) {
        if (isSuccess == true) {
            return (Database.MergeResult) JSON.deserialize('{"success": true, "id": "' + recordId + '"}', Database.MergeResult.class);
        } else {
            return (Database.MergeResult) JSON.deserialize(
                '{"success":false,"errors":[{"message": "Could not merge...", "statusCode": "MERGE_FAILED"}]}',
                Database.MergeResult.class
            );
        }
    }

    /**
     * @description Creates a mock instance of `Database.SaveResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests). A fake
     *              record ID is automatically included.
     * @param  isSuccess Indicates if the generated mock should have `isSuccess` == true
     * @return   The mock instance of `Database.SaveResult`
     */
    public static Database.SaveResult createMockDatabaseSaveResult(Boolean isSuccess) {
        return createMockDatabaseSaveResult(isSuccess, createMockId(Schema.Account.SObjectType));
    }

    /**
     * @description Creates a mock instance of `Database.SaveResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests)
     * @param  isSuccess Indicates if the generated mock should have `isSuccess` == true
     * @param  recordId  The record ID to use within the mock result
     * @return   The mock instance of `Database.SaveResult`
     */
    public static Database.SaveResult createMockDatabaseSaveResult(Boolean isSuccess, Id recordId) {
        if (isSuccess == true) {
            return (Database.SaveResult) JSON.deserialize('{"success": true, "id": "' + recordId + '"}', Database.SaveResult.class);
        } else {
            return (Database.SaveResult) JSON.deserialize(
                '{"success":false,"errors":[{"message": "Could not save...", "statusCode": "FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}',
                Database.SaveResult.class
            );
        }
    }

    /**
     * @description Creates a mock instance of `Database.UndeleteResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests). A fake
     *              record ID is automatically included.
     * @param  isSuccess Indicates if the generated mock should have `isSuccess` == true
     * @return   The mock instance of `Database.UndeleteResult`
     */
    public static Database.UndeleteResult createMockDatabaseUndeleteResult(Boolean isSuccess) {
        return createMockDatabaseUndeleteResult(isSuccess, createMockId(Schema.Account.SObjectType));
    }

    /**
     * @description Creates a mock instance of `Database.UndeleteResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests)
     * @param  isSuccess Indicates if the generated mock should have `isSuccess` == true
     * @param  recordId  The record ID to use within the mock result
     * @return   The mock instance of `Database.UndeleteResult`
     */
    public static Database.UndeleteResult createMockDatabaseUndeleteResult(Boolean isSuccess, Id recordId) {
        if (isSuccess == true) {
            return (Database.UndeleteResult) JSON.deserialize('{"success": true, "id": "' + recordId + '"}', Database.UndeleteResult.class);
        } else {
            return (Database.UndeleteResult) JSON.deserialize(
                '{"success":false,"errors":[{"message": "Could not undelete...", "statusCode": "FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}',
                Database.UndeleteResult.class
            );
        }
    }

    /**
     * @description Creates a mock instance of `Database.UpsertResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests). A fake
     *              record ID is automatically included.
     * @param  isSuccess Indicates if the generated mock should have `isSuccess` == true
     * @return   The mock instance of `Database.UpsertResult`
     */
    public static Database.UpsertResult createMockDatabaseUpsertResult(Boolean isSuccess) {
        return createMockDatabaseUpsertResult(isSuccess, createMockId(Schema.Account.SObjectType));
    }

    /**
     * @description Creates a mock instance of `Database.UpsertResult` - a mock is used instead of an actual instance
     *              to help speed up tests, and to support writing unit tests (instead of integration tests)
     * @param  isSuccess Indicates if the generated mock should have `isSuccess` == true
     * @param  recordId  The record ID to use within the mock result
     * @return   The mock instance of `Database.UpsertResult`
     */
    public static Database.UpsertResult createMockDatabaseUpsertResult(Boolean isSuccess, Id recordId) {
        if (isSuccess == true) {
            return (Database.UpsertResult) JSON.deserialize('{"success": true, "created": true, "id": "' + recordId + '"}', Database.UpsertResult.class);
        } else {
            return (Database.UpsertResult) JSON.deserialize(
                '{"success":false,"errors":[{"message": "Could not upsert...", "statusCode": "FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}',
                Database.UpsertResult.class
            );
        }
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
            Username = 'logger_xyz' + (userMockUsernameCount++) + '@test.com.net.org'
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
        if (Network.getNetworkId() == null || Type.forName('Network') == null) {
            return null;
        }

        String query = 'SELECT Id, Name, UrlPathPrefix FROM Network WHERE Id = :Network.getNetworkId()';
        return Database.query(String.escapeSingleQuotes(query));
    }

    /**
     * @description Returns the current user
     * @return   The matching `User` record
     */
    public static User getUser() {
        return getUser(UserInfo.getUserId());
    }

    /**
     * @description Returns the specified user
     * @param  userId The ID of the `User` record to query
     * @return   The matching `User` record
     */
    public static User getUser(Id userId) {
        return [
            SELECT Id, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.LicenseDefinitionKey, Profile.UserLicense.Name, Username, UserRole.Name
            FROM User
            WHERE Id = :userId
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

    /**
     * @description Loads the mock `LogEntryDataMaskRule__mdt` during test execution
     * @param  mock The mock instance of `LogEntryDataMaskRule__mdt` to load
     */
    public static void setMock(LogEntryDataMaskRule__mdt mock) {
        LogEntryEventBuilder.setMockDataMaskRule(mock);
    }

    /**
     * @description Loads the mock `LogEntryTagRule__mdt` during test execution
     * @param  mock The mock instance of `LogEntryTagRule__mdt` to load
     */
    public static void setMock(LogEntryTagRule__mdt mock) {
        LogEntryEventHandler.TAG_ASSIGNMENT_RULES.add(mock);
    }

    /**
     * @description Loads the mock `LoggerParameter__mdt` during test execution
     * @param  mock The mock instance of `LoggerParameter__mdt` to load
     */
    public static void setMock(LoggerParameter__mdt mock) {
        LoggerParameter.setMock(mock);
    }

    /**
     * @description Loads the mock `LoggerPlugin__mdt` during test execution
     * @param  mock The mock instance of `LoggerPlugin__mdt` to load
     */
    public static void setMock(LoggerPlugin__mdt mock) {
        LoggerPlugin.setMock(mock);
    }

    /**
     * @description Loads the mock `LogScenarioRule__mdt` during test execution
     * @param  mock The mock instance of `LogScenarioRule__mdt` to load
     */
    public static void setMock(LogScenarioRule__mdt mock) {
        Logger.setMockScenarioRule(mock);
        LogHandler.setMockScenarioRule(mock);
    }

    /**
     * @description Loads the mock `LogStatus__mdt` during test execution
     * @param  mock The mock instance of `LogStatus__mdt` to load
     */
    public static void setMock(LogStatus__mdt mock) {
        LogHandler.setMockLogStatus(mock);
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
