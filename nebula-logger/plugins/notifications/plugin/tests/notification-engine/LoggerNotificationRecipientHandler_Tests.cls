//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotificationRecipientHandler_Tests {
  static {
    LoggerConfigurationSelector.useMocks();
  }

  @IsTest
  static void it_should_return_the_loggerNotificationRecipient_sobjectType() {
    System.Assert.areEqual(Schema.LoggerNotificationRecipient__c.SObjectType, new LoggerNotificationRecipientHandler().getSObjectType());
  }

  @IsTest
  static void it_should_allow_a_null_configuration_json_on_insert() {
    LoggerNotificationRecipient__c recipient = buildValidRecipient();
    recipient.ConfigurationJson__c = null;

    LoggerDataStore.getDatabase().insertRecord(recipient);

    LoggerNotificationRecipient__c requeried = [SELECT Id, ConfigurationJson__c FROM LoggerNotificationRecipient__c WHERE Id = :recipient.Id];
    System.Assert.isNull(requeried.ConfigurationJson__c);
  }

  @IsTest
  static void it_should_allow_a_blank_configuration_json_on_insert() {
    LoggerNotificationRecipient__c recipient = buildValidRecipient();
    recipient.ConfigurationJson__c = '   ';

    LoggerDataStore.getDatabase().insertRecord(recipient);

    LoggerNotificationRecipient__c requeried = [SELECT Id FROM LoggerNotificationRecipient__c WHERE Id = :recipient.Id];
    System.Assert.isNotNull(requeried.Id, 'A whitespace-only config JSON should be treated as empty and pass validation');
  }

  @IsTest
  static void it_should_allow_a_valid_json_object_on_insert() {
    LoggerNotificationRecipient__c recipient = buildValidRecipient();
    recipient.ConfigurationJson__c = '{"foo":"bar","count":3,"nested":{"a":1}}';

    LoggerDataStore.getDatabase().insertRecord(recipient);

    LoggerNotificationRecipient__c requeried = [SELECT Id, ConfigurationJson__c FROM LoggerNotificationRecipient__c WHERE Id = :recipient.Id];
    System.Assert.areEqual('{"foo":"bar","count":3,"nested":{"a":1}}', requeried.ConfigurationJson__c);
  }

  @IsTest
  static void it_should_reject_malformed_json_on_insert() {
    LoggerNotificationRecipient__c recipient = buildValidRecipient();
    recipient.ConfigurationJson__c = '{"foo":';

    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().insertRecord(recipient);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'Malformed JSON should have blocked the insert');
    System.Assert.isTrue(
      thrown.getMessage().contains('Configuration JSON is not valid JSON'),
      'Error message should identify the parse failure: ' + thrown.getMessage()
    );
  }

  @IsTest
  static void it_should_reject_a_top_level_array_on_insert() {
    LoggerNotificationRecipient__c recipient = buildValidRecipient();
    recipient.ConfigurationJson__c = '["foo","bar"]';

    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().insertRecord(recipient);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A top-level JSON array should have blocked the insert');
    System.Assert.isTrue(
      thrown.getMessage().contains('must be a JSON object'),
      'Error message should identify the top-level-shape failure: ' + thrown.getMessage()
    );
  }

  @IsTest
  static void it_should_reject_a_top_level_scalar_on_insert() {
    LoggerNotificationRecipient__c recipient = buildValidRecipient();
    recipient.ConfigurationJson__c = '"just a string"';

    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().insertRecord(recipient);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A top-level JSON string should have blocked the insert');
    System.Assert.isTrue(
      thrown.getMessage().contains('must be a JSON object'),
      'Error message should identify the top-level-shape failure: ' + thrown.getMessage()
    );
  }

  @IsTest
  static void it_should_reject_a_top_level_number_on_insert() {
    LoggerNotificationRecipient__c recipient = buildValidRecipient();
    recipient.ConfigurationJson__c = '42';

    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().insertRecord(recipient);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'A top-level JSON number should have blocked the insert');
    System.Assert.isTrue(thrown.getMessage().contains('must be a JSON object'));
  }

  @IsTest
  static void it_should_allow_a_valid_config_change_on_update() {
    LoggerNotificationRecipient__c recipient = buildValidRecipient();
    recipient.ConfigurationJson__c = '{"foo":"bar"}';
    LoggerDataStore.getDatabase().insertRecord(recipient);

    recipient.ConfigurationJson__c = '{"baz":42,"qux":true}';
    LoggerDataStore.getDatabase().updateRecord(recipient);

    LoggerNotificationRecipient__c requeried = [SELECT Id, ConfigurationJson__c FROM LoggerNotificationRecipient__c WHERE Id = :recipient.Id];
    System.Assert.areEqual('{"baz":42,"qux":true}', requeried.ConfigurationJson__c);
  }

  @IsTest
  static void it_should_reject_an_invalid_config_change_on_update() {
    LoggerNotificationRecipient__c recipient = buildValidRecipient();
    recipient.ConfigurationJson__c = '{"foo":"bar"}';
    LoggerDataStore.getDatabase().insertRecord(recipient);

    recipient.ConfigurationJson__c = '["nope"]';

    System.DmlException thrown;
    try {
      LoggerDataStore.getDatabase().updateRecord(recipient);
    } catch (System.DmlException ex) {
      thrown = ex;
    }

    System.Assert.isNotNull(thrown, 'An update to a top-level array should have blocked the update');
    System.Assert.isTrue(thrown.getMessage().contains('must be a JSON object'));
  }

  @IsTest
  static void it_should_skip_validation_when_the_config_json_is_unchanged_on_update() {
    LoggerNotificationRecipient__c recipient = buildValidRecipient();
    recipient.ConfigurationJson__c = '{"foo":"bar"}';
    LoggerDataStore.getDatabase().insertRecord(recipient);

    // Update a different field. The config JSON is unchanged, so validation should not re-run and
    // should not throw. (This matters if the field somehow contained a stale-format value from a
    // previous release - existing records shouldn't fail on unrelated updates.)
    recipient.IsEnabled__c = !recipient.IsEnabled__c;
    LoggerDataStore.getDatabase().updateRecord(recipient);

    LoggerNotificationRecipient__c requeried = [SELECT Id, IsEnabled__c FROM LoggerNotificationRecipient__c WHERE Id = :recipient.Id];
    System.Assert.areEqual(recipient.IsEnabled__c, requeried.IsEnabled__c);
  }

  // Builds a minimally-valid recipient - inserts the rule + service first, then returns an
  // unsaved recipient with the required references stamped. Tests customize the config JSON before
  // calling `insert` themselves.
  private static LoggerNotificationRecipient__c buildValidRecipient() {
    LoggerNotificationRule__c rule = (LoggerNotificationRule__c) LoggerMockDataCreator.createDataBuilder(Schema.LoggerNotificationRule__c.SObjectType)
      .populateRequiredFields()
      .getRecord();
    // populateRequiredFields() inverts boolean defaults on purpose (to prove the field was
    // intentionally set), which produces IsMatchHistoryEnabled__c = false + IsMatchThresholdEnabled__c = true,
    // a combo the rule handler rejects ("threshold requires match history"). Reset the booleans to false to disable
    // all of the related features.
    rule.IsMatchHistoryEnabled__c = false;
    rule.IsMatchThresholdEnabled__c = false;
    rule.IsDeliveryHistoryEnabled__c = false;
    rule.SourceSObjectType__c = Schema.LogEntry__c.SObjectType.toString();
    rule.SourceSObjectFilter__c = 'HasException__c';
    LoggerDataStore.getDatabase().insertRecord(rule);

    LoggerNotificationService__c service = (LoggerNotificationService__c) LoggerMockDataCreator.createDataBuilder(
        Schema.LoggerNotificationService__c.SObjectType
      )
      .populateRequiredFields()
      .getRecord();
    service.NotifierApexClassName__c = 'EmailLoggerNotifier';
    service.IsEnabled__c = true;
    LoggerDataStore.getDatabase().insertRecord(service);

    LoggerNotificationRecipient__c recipient = (LoggerNotificationRecipient__c) LoggerMockDataCreator.createDataBuilder(
        Schema.LoggerNotificationRecipient__c.SObjectType
      )
      .populateRequiredFields()
      .getRecord();
    recipient.LoggerNotificationRule__c = rule.Id;
    recipient.LoggerNotificationService__c = service.Id;
    recipient.EmailAddress__c = 'test@example.com';
    recipient.IsEnabled__c = true;
    return recipient;
  }
}
