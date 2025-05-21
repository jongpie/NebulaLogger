//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=false)
private class LogEntryEventBuilder_Tests_Security {
  private static final Schema.Profile STANDARD_USER_PROFILE = [SELECT Id FROM Profile WHERE Name IN ('Standard User', 'Usuario estándar', '標準ユーザー')];

  @IsTest
  static void it_should_strip_inaccessible_fields_for_single_record_when_enabled() {
    Schema.User standardUser = LoggerMockDataCreator.createUser(STANDARD_USER_PROFILE.Id);
    AccountBrand mockAccountBrand = (AccountBrand) LoggerMockDataCreator.createDataBuilder(Schema.AccountBrand.SObjectType)
      .populateMockId()
      .populateRequiredFields()
      .getRecord();
    // The 'standard user' profile doesn't have access to AccountBrand,
    // so stripAccessible will remove everything except the ID field
    AccountBrand strippedAccountBrand = new AccountBrand(Id = mockAccountBrand.Id);

    LogEntryEventBuilder builder;
    System.runAs(standardUser) {
      System.Assert.isFalse(Schema.AccountBrand.SObjectType.getDescribe().isAccessible(), 'AccountBrand was accessible, and should not have been.');
      System.Assert.areEqual(
        false,
        Schema.AccountBrand.CompanyName.getDescribe().isAccessible(),
        'AccountBrand Company Name was accessible, and should not have been.'
      );
      System.Assert.isFalse(Schema.AccountBrand.Email.getDescribe().isAccessible(), 'AccountBrand Email was accessible, and should not have been.');
      System.Assert.isFalse(Schema.AccountBrand.Name.getDescribe().isAccessible(), 'AccountBrand Name was accessible, and should not have been.');
      System.Assert.isFalse(Schema.AccountBrand.Phone.getDescribe().isAccessible(), 'AccountBrand Phone was accessible, and should not have been.');

      LoggerSettings__c userSettings = getUserSettings();
      userSettings.IsRecordFieldStrippingEnabled__c = true;
      builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true).setRecord(mockAccountBrand);
    }

    System.Assert.areNotEqual(
      System.JSON.serializePretty(mockAccountBrand),
      builder.getLogEntryEvent().RecordJson__c,
      'Log entry event record JSON was incorrect.'
    );
    System.Assert.areEqual(
      System.JSON.serializePretty(strippedAccountBrand),
      builder.getLogEntryEvent().RecordJson__c,
      'Log entry event record JSON was incorrect.'
    );
  }

  @IsTest
  static void it_should_strip_inaccessible_fields_for_record_list_when_enabled() {
    Schema.User standardUser = LoggerMockDataCreator.createUser(STANDARD_USER_PROFILE.Id);
    List<AccountBrand> mockAccountBrands = new List<AccountBrand>();
    List<AccountBrand> strippedAccountBrands = new List<AccountBrand>();
    for (Integer i = 0; i < 5; i++) {
      AccountBrand mockAccountBrand = (AccountBrand) LoggerMockDataCreator.createDataBuilder(Schema.AccountBrand.SObjectType)
        .populateMockId()
        .populateRequiredFields()
        .getRecord();
      mockAccountBrands.add(mockAccountBrand);

      // The 'standard user' profile doesn't have access to AccountBrand,
      // so stripAccessible will remove everything except the ID field
      AccountBrand strippedAccountBrand = new AccountBrand(Id = mockAccountBrand.Id);
      strippedAccountBrands.add(strippedAccountBrand);
    }

    LogEntryEventBuilder builder;
    System.runAs(standardUser) {
      System.Assert.isFalse(Schema.AccountBrand.SObjectType.getDescribe().isAccessible(), 'AccountBrand was accessible, and should not have been.');
      System.Assert.areEqual(
        false,
        Schema.AccountBrand.CompanyName.getDescribe().isAccessible(),
        'AccountBrand Company Name was accessible and should not have been.'
      );
      System.Assert.isFalse(Schema.AccountBrand.Email.getDescribe().isAccessible(), 'AccountBrand Email was accessible, and should not have been,');
      System.Assert.isFalse(Schema.AccountBrand.Name.getDescribe().isAccessible(), 'AccountBrand Name was accessible, and should not have been.');
      System.Assert.isFalse(Schema.AccountBrand.Phone.getDescribe().isAccessible(), 'AccountBrand Phone was accessible, and should not have been.');

      LoggerSettings__c userSettings = getUserSettings();
      userSettings.IsRecordFieldStrippingEnabled__c = true;
      builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true).setRecord(mockAccountBrands);
    }

    System.Assert.areNotEqual(System.JSON.serializePretty(mockAccountBrands), builder.getLogEntryEvent().RecordJson__c, 'Record JSON is incorrect.');
    System.Assert.areEqual(System.JSON.serializePretty(strippedAccountBrands), builder.getLogEntryEvent().RecordJson__c, 'Record JSON is incorrect.');
  }

  @IsTest
  static void it_should_strip_inaccessible_fields_for_record_map_when_enabled() {
    Schema.User standardUser = LoggerMockDataCreator.createUser(STANDARD_USER_PROFILE.Id);
    Map<Id, AccountBrand> mockIdToAccountBrand = new Map<Id, AccountBrand>();
    Map<String, AccountBrand> mockIdStringToStrippedAccountBrand = new Map<String, AccountBrand>();
    for (Integer i = 0; i < 5; i++) {
      AccountBrand mockAccountBrand = (AccountBrand) LoggerMockDataCreator.createDataBuilder(Schema.AccountBrand.SObjectType)
        .populateMockId()
        .populateRequiredFields()
        .getRecord();
      mockIdToAccountBrand.put(mockAccountBrand.Id, mockAccountBrand);

      // The 'standard user' profile doesn't have access to AccountBrand,
      // so stripAccessible will remove everything except the ID field
      AccountBrand strippedAccountBrand = new AccountBrand(Id = mockAccountBrand.Id);
      mockIdStringToStrippedAccountBrand.put(strippedAccountBrand.Id, strippedAccountBrand);
    }
    // Previous versions of Nebula Logger would throw a runtime exception if the Map contained a null key,
    // so add one to ensure it works as expected
    AccountBrand anotherMockAccountBrand = (AccountBrand) LoggerMockDataCreator.createDataBuilder(Schema.AccountBrand.SObjectType)
      .populateRequiredFields()
      .getRecord();
    mockIdToAccountBrand.put(null, anotherMockAccountBrand);
    mockIdStringToStrippedAccountBrand.put('', new AccountBrand());

    LogEntryEventBuilder builder;
    System.runAs(standardUser) {
      System.Assert.isFalse(Schema.AccountBrand.SObjectType.getDescribe().isAccessible(), 'AccountBrand was accessible, and should not have been.');
      System.Assert.areEqual(
        false,
        Schema.AccountBrand.CompanyName.getDescribe().isAccessible(),
        'AccountBrand Company Name was accessible and should not have been.'
      );
      System.Assert.isFalse(Schema.AccountBrand.Email.getDescribe().isAccessible(), 'AccountBrand Email was accessible, and should not have been,');
      System.Assert.isFalse(Schema.AccountBrand.Name.getDescribe().isAccessible(), 'AccountBrand Name was accessible, and should not have been.');
      System.Assert.isFalse(Schema.AccountBrand.Phone.getDescribe().isAccessible(), 'AccountBrand Phone was accessible, and should not have been.');

      LoggerSettings__c userSettings = getUserSettings();
      userSettings.IsRecordFieldStrippingEnabled__c = true;
      builder = new LogEntryEventBuilder(userSettings, System.LoggingLevel.INFO, true).setRecord(mockIdToAccountBrand);
    }

    System.Assert.areEqual(
      System.JSON.serializePretty(mockIdStringToStrippedAccountBrand),
      builder.getLogEntryEvent().RecordJson__c,
      'Record JSON is incorrect.'
    );
  }

  static LoggerSettings__c getUserSettings() {
    LoggerSettings__c userSettings = (LoggerSettings__c) Schema.LoggerSettings__c.SObjectType.newSObject(null, true);
    userSettings.SetupOwnerId = System.UserInfo.getUserId();
    return userSettings;
  }
}
