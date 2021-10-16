//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@IsTest
public class LoggerTestUtils {
    private static final Map<Schema.SObjectType, Integer> SOBJECT_TYPE_TO_MOCK_ID_COUNT = new Map<Schema.SObjectType, Integer>();
    private static final Profile STANDARD_USER_PROFILE = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

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
}
