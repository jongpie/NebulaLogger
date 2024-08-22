//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=false)
private class LogEntryEventBuilder_Tests_Network {
  private static final String EXPERIENCE_CLOUD_NETWORK_NAME = 'Logger Test LWR Site';
  private static final String EXPERIENCE_CLOUD_USER_PROFILE_NAME = 'Logger Test Site User Profile';

  @IsTest
  static void it_should_set_network_fields_for_experience_site_user() {
    // No need to fail the test if it's running in an org that does not have Experience Cloud enabled
    if (LoggerEngineDataSelector.IS_EXPERIENCE_CLOUD_ENABLED == false) {
      return;
    }

    System.Assert.isTrue(LoggerParameter.QUERY_NETWORK_DATA);
    SObject networkRecord = getExperienceCloudNetwork();
    System.Assert.isNotNull(networkRecord.Id);
    LogEntryEventBuilder.networkId = networkRecord.Id;
    Schema.User experienceSiteUser = setupExperienceSiteUser();

    LogEntryEvent__e logEntryEvent;
    System.runAs(experienceSiteUser) {
      logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true).getLogEntryEvent();
    }

    System.Assert.areEqual(networkRecord.get('Id'), logEntryEvent.NetworkId__c);
    System.Assert.areEqual((String) networkRecord.get('Name'), logEntryEvent.NetworkName__c);
    System.Assert.areEqual(System.Network.getLoginUrl(networkRecord.Id), logEntryEvent.NetworkLoginUrl__c);
    System.Assert.areEqual(System.Network.getLogoutUrl(networkRecord.Id), logEntryEvent.NetworkLogoutUrl__c);
    System.Assert.areEqual(System.Network.getSelfRegUrl(networkRecord.Id), logEntryEvent.NetworkSelfRegistrationUrl__c);
    System.Assert.areEqual((String) networkRecord.get('UrlPathPrefix'), logEntryEvent.NetworkUrlPathPrefix__c);
  }

  @IsTest
  static void it_should_not_set_network_fields_for_experience_site_user_when_disabled_via_logger_parameter() {
    // No need to fail the test if it's running in an org that does not have Experience Cloud enabled
    if (LoggerEngineDataSelector.IS_EXPERIENCE_CLOUD_ENABLED == false) {
      return;
    }

    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryNetworkData', Value__c = String.valueOf(false)));
    System.Assert.isFalse(LoggerParameter.QUERY_NETWORK_DATA);
    SObject networkRecord = getExperienceCloudNetwork();
    System.Assert.isNotNull(networkRecord.Id);
    LogEntryEventBuilder.networkId = networkRecord.Id;
    Schema.User experienceSiteUser = setupExperienceSiteUser();

    LogEntryEvent__e logEntryEvent;
    System.runAs(experienceSiteUser) {
      logEntryEvent = new LogEntryEventBuilder(getUserSettings(), System.LoggingLevel.INFO, true).getLogEntryEvent();
    }

    System.Assert.isNull(logEntryEvent.NetworkName__c);
    System.Assert.isNull(logEntryEvent.NetworkLoginUrl__c);
    System.Assert.isNull(logEntryEvent.NetworkLogoutUrl__c);
    System.Assert.isNull(logEntryEvent.NetworkSelfRegistrationUrl__c);
    System.Assert.isNull(logEntryEvent.NetworkUrlPathPrefix__c);
  }

  static SObject getExperienceCloudNetwork() {
    return System.Database.query('SELECT Id, Name, UrlPathPrefix FROM Network WHERE Name = :EXPERIENCE_CLOUD_NETWORK_NAME');
  }

  static LoggerSettings__c getUserSettings() {
    LoggerSettings__c userSettings = (LoggerSettings__c) Schema.LoggerSettings__c.SObjectType.newSObject(null, true);
    userSettings.SetupOwnerId = System.UserInfo.getUserId();
    return userSettings;
  }

  static Schema.User setupExperienceSiteUser() {
    Schema.UserRole userRole = new Schema.UserRole(DeveloperName = 'LoggerTestRole', Name = 'Logger Test Role');
    insert userRole;
    Schema.User currentUser = new Schema.User(Id = System.UserInfo.getUserId(), UserRoleId = userRole.Id);
    update currentUser;
    Schema.User experienceSiteUser;
    System.runAs(currentUser) {
      Schema.Account account = new Schema.Account(Name = 'Test Account', OwnerId = currentUser.Id);
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
