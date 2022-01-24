//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions, PMD.PropertyNamingConventions')
@IsTest
public class LoggerTestUtils {
    private static final Map<Schema.SObjectType, Integer> SOBJECT_TYPE_TO_MOCK_ID_COUNT = new Map<Schema.SObjectType, Integer>();

    private static Boolean cacheQueries = true;

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

    private static final Profile STANDARD_USER_PROFILE {
        get {
            if (STANDARD_USER_PROFILE == null || cacheQueries == false) {
                STANDARD_USER_PROFILE = queryStandardUserProfile();
            }
            return STANDARD_USER_PROFILE;
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
     * @description Creates a `User` record for testing purposes, using the 'Standard User' profile
     * @return   The generated `User` record - it is not automatically inserted into the database.
     */
    public static User createStandardUser() {
        return new User(
            Alias = 'log_xyz',
            Email = 'logger_xyz@test.com.net.org',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            LastName = 'Logger test user',
            LocaleSidKey = 'en_US',
            ProfileId = STANDARD_USER_PROFILE.Id,
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

        String queryString = 'SELECT Id, Name, UrlPathPrefix FROM Network WHERE Id = :Network.getNetworkId()';

        return Database.query(queryString);
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

    private static Profile queryStandardUserProfile() {
        // The Profile object does not have a DeveloperName field, and tandard profile names are (annoyingly) translated
        // to the current user's language - to ensure that this query works for all languages, the translated names
        // have been as part of the query's filter.
        // And no, this doesn't have to be a map (only .values() is used below), but it makes maintenance & readability easier
        Map<String, String> profileNamesByLanguageLocaleKey = new Map<String, String>{
            'da' => 'Standardbruger',
            'de' => 'Standardbenutzer',
            'en_US' => 'Standard User',
            'es_MX' => 'Usuario estándar',
            'es' => 'Usuario estándar',
            'fi' => 'Vakiokäyttäjä',
            'fr' => 'Utilisateur standard',
            'it' => 'Utente standard',
            'ja' => '標準ユーザ',
            'ko' => '표준 사용자',
            'nl_NL' => 'Standaardgebruiker',
            'no' => 'Standardbruker',
            'pt_BR' => 'Usuário Padrão',
            'ru' => 'Стандартный пользователь',
            'sv' => 'Standardanvändare',
            'th' => 'ผู้ใช้มาตรฐาน',
            'zh_CN' => '标准用户',
            'zh_TW' => '標準使用者'
        };
        return [SELECT Id, Name FROM Profile WHERE Name IN :profileNamesByLanguageLocaleKey.values() LIMIT 1];
    }

    // Actual test methods for LoggerTestUtils - the goal of this class is to be a utility class for other test classes
    // (instead of actually containing tests), but this verifies that this utility class is working as expected.
    // Yes, this does DML in a for-loop, which is HORRIBLE to do, but in this case, it's within the governor limits,
    // it's only in a test class, and it ensures that the current user's language has been updated
    // so that the profile's name is using the expected language
    @SuppressWarnings('PMD.OperationWithLimitsInLoop')
    @IsTest
    static void it_should_return_standard_user_profile_in_all_languages() {
        User testUser = createStandardUser();
        testUser.LanguageLocaleKey = 'en_US';
        insert testUser;
        Profile expectedProfile;
        // Using 'en_US', get the expected profile using the name 'Standard Profile'
        System.runAs(testUser) {
            testUser = [SELECT Id, LanguageLocaleKey FROM User WHERE Id = :testUser.Id];
            System.assertEquals('en_US', testUser.LanguageLocaleKey);
            expectedProfile = [SELECT Id, Name FROM Profile WHERE Name = 'Standard User'];
        }
        // Test that each value of LanguageLocaleKey returns a value for STANDARD_USER_PROFILE
        for (PicklistEntry picklistEntry : Schema.User.LanguageLocaleKey.getDescribe().getPickListValues()) {
            testUser.LanguageLocaleKey = picklistEntry.getValue();
            update testUser;
            System.runAs(testUser) {
                cacheQueries = false;
                testUser = [SELECT Id, LanguageLocaleKey FROM User WHERE Id = :testUser.Id];
                System.assertEquals(picklistEntry.getValue(), testUser.LanguageLocaleKey);
                System.assertEquals(expectedProfile.Id, STANDARD_USER_PROFILE.Id);
            }
        }
    }
}
