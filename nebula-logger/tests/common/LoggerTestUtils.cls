//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@IsTest
public class LoggerTestUtils {
    private static Map<Schema.SObjectType, Integer> SOBJECT_TYPE_TO_MOCK_ID_COUNT = new Map<Schema.SObjectType, Integer>();
    private static Profile STANDARD_USER_PROFILE = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

    public static String mockId(Schema.SObjectType sobjectType) {
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
}
