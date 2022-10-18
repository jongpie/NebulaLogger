//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Extra Tests
 * @description Additional integration tests for security checks & orgs with Experience Sites (Communities) enabled
 */
@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=false)
private class LogEntryEventBuilder_Tests_Network {
    private static final Boolean IS_EXPERIENCE_CLOUD_ENABLED = Type.forName('System.Network') != null;
    private static final String EXPERIENCE_CLOUD_NETWORK_NAME = 'Logger Test Site';
    private static final String EXPERIENCE_CLOUD_USER_PROFILE_NAME = 'Logger Test Site User Profile';

    @IsTest
    static void it_should_set_network_fields_for_experience_site_user() {
        // No need to fail the test if it's running in an org that does not have Experience Cloud enabled
        if (IS_EXPERIENCE_CLOUD_ENABLED == false) {
            return;
        }

        System.assertEquals(true, LoggerParameter.QUERY_NETWORK_DATA);
        SObject networkRecord = getExperienceCloudNetwork();
        System.assertNotEquals(null, networkRecord.Id);
        LogEntryEventBuilder.networkId = networkRecord.Id;
        User experienceSiteUser = setupExperienceSiteUser();

        LogEntryEvent__e logEntryEvent;
        System.runAs(experienceSiteUser) {
            logEntryEvent = new LogEntryEventBuilder(getUserSettings(), LoggingLevel.INFO, true, new Set<String>()).getLogEntryEvent();
        }

        System.assertEquals(networkRecord.get('Id'), logEntryEvent.NetworkId__c);
        System.assertEquals((String) networkRecord.get('Name'), logEntryEvent.NetworkName__c);
        System.assertEquals(System.Network.getLoginUrl(networkRecord.Id), logEntryEvent.NetworkLoginUrl__c);
        System.assertEquals(System.Network.getLogoutUrl(networkRecord.Id), logEntryEvent.NetworkLogoutUrl__c);
        System.assertEquals(System.Network.getSelfRegUrl(networkRecord.Id), logEntryEvent.NetworkSelfRegistrationUrl__c);
        System.assertEquals((String) networkRecord.get('UrlPathPrefix'), logEntryEvent.NetworkUrlPathPrefix__c);
    }

    @IsTest
    static void it_should_not_set_network_fields_for_experience_site_user_when_disabled_via_logger_parameter() {
        // No need to fail the test if it's running in an org that does not have Experience Cloud enabled
        if (IS_EXPERIENCE_CLOUD_ENABLED == false) {
            return;
        }

        LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryNetworkData', Value__c = String.valueOf(false)));
        System.assertEquals(false, LoggerParameter.QUERY_NETWORK_DATA);
        SObject networkRecord = getExperienceCloudNetwork();
        System.assertNotEquals(null, networkRecord.Id);
        LogEntryEventBuilder.networkId = networkRecord.Id;
        User experienceSiteUser = setupExperienceSiteUser();

        LogEntryEvent__e logEntryEvent;
        System.runAs(experienceSiteUser) {
            logEntryEvent = new LogEntryEventBuilder(getUserSettings(), LoggingLevel.INFO, true, new Set<String>()).getLogEntryEvent();
        }

        System.assertEquals(null, logEntryEvent.NetworkName__c);
        System.assertEquals(null, logEntryEvent.NetworkLoginUrl__c);
        System.assertEquals(null, logEntryEvent.NetworkLogoutUrl__c);
        System.assertEquals(null, logEntryEvent.NetworkSelfRegistrationUrl__c);
        System.assertEquals(null, logEntryEvent.NetworkUrlPathPrefix__c);
    }

    static SObject getExperienceCloudNetwork() {
        return Database.query('SELECT Id, Name, UrlPathPrefix FROM Network WHERE Name = :EXPERIENCE_CLOUD_NETWORK_NAME');
    }

    static LoggerSettings__c getUserSettings() {
        LoggerSettings__c userSettings = (LoggerSettings__c) Schema.LoggerSettings__c.SObjectType.newSObject(null, true);
        userSettings.SetupOwnerId = UserInfo.getUserId();
        return userSettings;
    }

    static User setupExperienceSiteUser() {
        UserRole userRole = new UserRole(DeveloperName = 'LoggerTestRole', Name = 'Logger Test Role');
        insert userRole;
        User currentUser = new User(Id = UserInfo.getUserId(), UserRoleId = userRole.Id);
        update currentUser;
        User experienceSiteUser;
        System.runAs(currentUser) {
            Account account = new Account(Name = 'Test Account', OwnerId = currentUser.Id);
            insert account;
            Contact contact = new Contact(AccountId = account.Id, LastName = 'testcontact');
            insert contact;
            Id experienceSiteUserProfileId = [SELECT Id FROM Profile WHERE Name = :EXPERIENCE_CLOUD_USER_PROFILE_NAME LIMIT 1].Id;
            experienceSiteUser = LoggerMockDataCreator.createUser(experienceSiteUserProfileId);
            experienceSiteUser.ContactId = contact.Id;
            insert experienceSiteUser;
        }
        return [SELECT Id, AccountId, ContactId FROM User WHERE Id = :experienceSiteUser.Id];
    }
}
