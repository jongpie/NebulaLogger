//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Extra Tests
 * @description Additional integration tests for orgs with Experience Sites (Communities) enabled
 */
@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=false)
private class Logger_Tests_ExperienceSite {
    private static final Boolean IS_EXPERIENCE_CLOUD_ENABLED = Schema.getGlobalDescribe().containsKey('Network');
    private static final String GUEST_USER_PROFILE_NAME = 'Logger Test Site Profile';
    private static final String GUEST_USER_TYPE = 'Guest';
    private static final String LOG_CREATOR_PERMISSION_SET_NAME = 'LoggerLogCreator';

    @TestSetup
    static void setupData() {
        if (IS_EXPERIENCE_CLOUD_ENABLED == false) {
            return;
        }

        List<Profile> matchingProfiles = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = :GUEST_USER_PROFILE_NAME];

        if (matchingProfiles.isEmpty() == true) {
            return;
        }

        Profile loggerSiteProfile = matchingProfiles.get(0);
        System.assertEquals('Guest User License', loggerSiteProfile.UserLicense.Name, 'User license did not match Guest User License.');

        // Even if Experience Cloud is enabled, the expected test site might not exist, so exit early if the guest user cannot be found
        List<User> guestUsers = [SELECT Id FROM User WHERE Profile.Name = :GUEST_USER_PROFILE_NAME AND Profile.UserType = :GUEST_USER_TYPE];
        if (guestUsers.isEmpty() == true) {
            return;
        }

        User guestUser = guestUsers.get(0);
        LoggerTestConfigurator.assignLogCreatorPermissionSet(guestUser.Id);
    }

    @IsTest
    private static void it_fails_to_save_log_when_assigned_to_guest_user() {
        // No need to fail the test if it's running in an org that does not have Experience Cloud enabled
        if (IS_EXPERIENCE_CLOUD_ENABLED == false) {
            return;
        }

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        System.Test.startTest();

        // Even if Experience Cloud is enabled, the expected test site might not exist, so exit early if the guest user cannot be found
        List<User> guestUsers = [SELECT Id FROM User WHERE Profile.Name = :GUEST_USER_PROFILE_NAME AND Profile.UserType = :GUEST_USER_TYPE];
        if (guestUsers.isEmpty() == true) {
            return;
        }

        User guestUser = guestUsers.get(0);
        try {
            log.OwnerId = guestUser.Id;
            update log;
            System.assert(false, 'Expected exception, this exception should not occur');
        } catch (Exception ex) {
            String expectedExceptionMessage = 'FIELD_INTEGRITY_EXCEPTION, field integrity exception (Guest users cannot be record owners.)';
            System.assert(ex.getMessage().contains(expectedExceptionMessage), 'Exception did not contain expected message.');
        }
        System.Test.stopTest();
    }

    @IsTest
    private static void it_saves_log_for_guest_user() {
        // No need to fail the test if it's running in an org that does not have Experience Cloud enabled
        if (IS_EXPERIENCE_CLOUD_ENABLED == false) {
            return;
        }

        // Even if Experience Cloud is enabled, the expected test site might not exist, so exit early if the guest user cannot be found
        List<User> guestUsers = [SELECT Id, Profile.UserType FROM User WHERE Profile.Name = :GUEST_USER_PROFILE_NAME AND Profile.UserType = :GUEST_USER_TYPE];
        if (guestUsers.isEmpty() == true) {
            return;
        }

        User guestUser = guestUsers.get(0);
        String message = 'testing logging as a guest user';

        System.runAs(guestUser) {
            Logger.debug(message);
            Logger.saveLog();

            System.Test.getEventBus().deliver();
        }

        LogEntry__c logEntry = [
            SELECT Id, Log__r.LoggedBy__c, Log__r.OwnerId, Log__r.UserLicenseDefinitionKey__c, Log__r.UserType__c, Message__c
            FROM LogEntry__c
        ];
        System.assertEquals(guestUser.Id, logEntry.Log__r.LoggedBy__c, 'LoggedBy was set to the wrong user ID');
        System.assertNotEquals(guestUser.Id, logEntry.Log__r.OwnerId, 'Log owner ID was incorrect');
        System.assertEquals(GUEST_USER_TYPE, logEntry.Log__r.UserType__c, 'UserType was incorrect');
        System.assertEquals('PID_Guest_User', logEntry.Log__r.UserLicenseDefinitionKey__c, 'UserLicenseDefinitionKey was incorrect');
        System.assertEquals(message, logEntry.Message__c, 'Log Entry message was incorrect');
    }
}
