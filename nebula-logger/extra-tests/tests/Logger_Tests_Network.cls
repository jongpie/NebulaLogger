//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=false)
private class Logger_Tests_Network {
    private static final Boolean IS_EXPERIENCE_CLOUD_ENABLED = System.Type.forName('NetworkMember') != null;
    private static final String EXPERIENCE_CLOUD_GUEST_PROFILE_NAME = 'Logger Test LWR Site Guest Profile';
    private static final String GUEST_USER_TYPE = 'Guest';
    private static final String LOG_CREATOR_PERMISSION_SET_NAME = 'LoggerLogCreator';

    @TestSetup
    static void setupData() {
        if (IS_EXPERIENCE_CLOUD_ENABLED == false) {
            return;
        }

        List<Schema.Profile> matchingProfiles = [SELECT Id, UserLicense.Name FROM Profile WHERE Name = :EXPERIENCE_CLOUD_GUEST_PROFILE_NAME];

        if (matchingProfiles.isEmpty()) {
            return;
        }

        Schema.Profile loggerSiteProfile = matchingProfiles.get(0);
        System.Assert.areEqual('Guest User License', loggerSiteProfile.UserLicense.Name, 'User license did not match Guest User License.');

        // Even if Experience Cloud is enabled, the expected test site might not exist, so exit early if the guest user cannot be found
        List<Schema.User> guestUsers = [
            SELECT Id
            FROM User
            WHERE Profile.Name = :EXPERIENCE_CLOUD_GUEST_PROFILE_NAME AND Profile.UserType = :GUEST_USER_TYPE
        ];
        if (guestUsers.isEmpty()) {
            return;
        }

        Schema.User guestUser = guestUsers.get(0);
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
        List<Schema.User> guestUsers = [
            SELECT Id
            FROM User
            WHERE Profile.Name = :EXPERIENCE_CLOUD_GUEST_PROFILE_NAME AND Profile.UserType = :GUEST_USER_TYPE
        ];
        if (guestUsers.isEmpty()) {
            return;
        }

        Schema.User guestUser = guestUsers.get(0);
        try {
            log.OwnerId = guestUser.Id;
            update log;
            System.Assert.fail('Expected exception, this exception should not occur');
        } catch (System.Exception ex) {
            String expectedExceptionMessage = 'FIELD_INTEGRITY_EXCEPTION, field integrity exception (Guest users cannot be record owners.)';
            System.Assert.isTrue(ex.getMessage().contains(expectedExceptionMessage), 'System.Exception did not contain expected message.');
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
        List<Schema.User> guestUsers = [
            SELECT Id, Profile.UserType
            FROM User
            WHERE Profile.Name = :EXPERIENCE_CLOUD_GUEST_PROFILE_NAME AND Profile.UserType = :GUEST_USER_TYPE
        ];
        if (guestUsers.isEmpty()) {
            return;
        }

        Schema.User guestUser = guestUsers.get(0);
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
        System.Assert.areEqual(guestUser.Id, logEntry.Log__r.LoggedBy__c, 'LoggedBy was set to the wrong user ID');
        System.Assert.areNotEqual(guestUser.Id, logEntry.Log__r.OwnerId, 'Log owner ID was incorrect');
        System.Assert.areEqual(GUEST_USER_TYPE, logEntry.Log__r.UserType__c, 'UserType was incorrect');
        System.Assert.areEqual('PID_Guest_User', logEntry.Log__r.UserLicenseDefinitionKey__c, 'UserLicenseDefinitionKey was incorrect');
        System.Assert.areEqual(message, logEntry.Message__c, 'Log Entry message was incorrect');
    }
}
