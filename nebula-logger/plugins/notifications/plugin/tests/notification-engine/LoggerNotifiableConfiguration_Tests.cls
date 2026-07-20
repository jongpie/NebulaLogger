//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotifiableConfiguration_Tests {
  @IsTest
  static void it_should_return_empty_config_when_recipient_is_null() {
    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(null);

    System.Assert.isNotNull(config);
    System.Assert.isNull(config.getSourceFields(), 'A null recipient should yield null source fields (meaning: use the notifier default)');
  }

  @IsTest
  static void it_should_return_empty_config_when_json_is_blank() {
    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(new LoggerNotificationRecipient__c());

    System.Assert.isNull(config.getSourceFields());
  }

  @IsTest
  static void it_should_return_empty_config_when_json_is_malformed() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = 'not json');

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    System.Assert.isNull(config.getSourceFields(), 'Malformed JSON should be swallowed and treated as no config');
  }

  @IsTest
  static void it_should_return_empty_config_when_json_is_not_an_object() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '["just", "a", "list"]');

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    System.Assert.isNull(config.getSourceFields(), 'A JSON array (not an object) should be treated as no config');
  }

  @IsTest
  static void it_should_return_null_source_fields_when_key_is_absent() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"someOtherKey": true}');

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    System.Assert.isNull(config.getSourceFields(), 'A config without sourceFields should return null so notifiers know to use their default');
  }

  @IsTest
  static void it_should_return_the_configured_source_fields_in_order() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"sourceFields":["LoggingLevel__c","Message__c","StackTrace__c"]}'
    );

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    List<String> fields = config.getSourceFields();
    System.Assert.areEqual(3, fields.size());
    System.Assert.areEqual('LoggingLevel__c', fields.get(0));
    System.Assert.areEqual('Message__c', fields.get(1));
    System.Assert.areEqual('StackTrace__c', fields.get(2));
  }

  @IsTest
  static void it_should_return_empty_list_when_source_fields_key_is_present_but_empty() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"sourceFields":[]}');

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    List<String> fields = config.getSourceFields();
    System.Assert.isNotNull(fields, 'An explicit empty list is different from an absent key');
    System.Assert.areEqual(0, fields.size(), 'Admins can explicitly opt out of rendering any source fields');
  }

  @IsTest
  static void it_should_drop_blank_entries_from_the_source_fields_list() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"sourceFields":["LoggingLevel__c","","Message__c",null,"   "]}'
    );

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    List<String> fields = config.getSourceFields();
    System.Assert.areEqual(2, fields.size(), 'Blanks and nulls should be dropped: ' + fields);
    System.Assert.areEqual('LoggingLevel__c', fields.get(0));
    System.Assert.areEqual('Message__c', fields.get(1));
  }

  @IsTest
  static void it_should_return_null_when_source_fields_value_is_not_a_list() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"sourceFields":"LoggingLevel__c"}');

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    System.Assert.isNull(config.getSourceFields(), 'A non-array sourceFields value should be treated as no config');
  }

  @IsTest
  static void it_should_return_source_field_specs_for_bare_string_entries() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"sourceFields":["LoggingLevel__c","Message__c"]}');

    List<LoggerNotifiableConfiguration.SourceFieldSpec> specs = LoggerNotifiableConfiguration.fromRecipient(recipient).getSourceFieldSpecs();

    System.Assert.areEqual(2, specs.size());
    System.Assert.areEqual('LoggingLevel__c', specs.get(0).field);
    System.Assert.isNull(specs.get(0).displayField, 'Bare strings should have no display field override');
    System.Assert.isNull(specs.get(0).displayLabel, 'Bare strings should have no display label override');
    System.Assert.areEqual('Message__c', specs.get(1).field);
  }

  @IsTest
  static void it_should_return_source_field_specs_for_object_entries_with_overrides() {
    String json = '{"sourceFields":[{"field":"Log__r.LoggedBy__c","displayField":"Log__r.LoggedBy__r.Username","displayLabel":"Logged By"}]}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);

    List<LoggerNotifiableConfiguration.SourceFieldSpec> specs = LoggerNotifiableConfiguration.fromRecipient(recipient).getSourceFieldSpecs();

    System.Assert.areEqual(1, specs.size());
    System.Assert.areEqual('Log__r.LoggedBy__c', specs.get(0).field);
    System.Assert.areEqual('Log__r.LoggedBy__r.Username', specs.get(0).displayField);
    System.Assert.areEqual('Logged By', specs.get(0).displayLabel);
  }

  @IsTest
  static void it_should_allow_bare_strings_and_object_entries_in_the_same_list() {
    String json = '{"sourceFields":["LoggingLevel__c",{"field":"Message__c","displayLabel":"Body"}]}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);

    List<LoggerNotifiableConfiguration.SourceFieldSpec> specs = LoggerNotifiableConfiguration.fromRecipient(recipient).getSourceFieldSpecs();

    System.Assert.areEqual(2, specs.size());
    System.Assert.areEqual('LoggingLevel__c', specs.get(0).field);
    System.Assert.isNull(specs.get(0).displayLabel);
    System.Assert.areEqual('Message__c', specs.get(1).field);
    System.Assert.areEqual('Body', specs.get(1).displayLabel);
  }

  @IsTest
  static void it_should_drop_object_entries_missing_a_field_key() {
    String json = '{"sourceFields":[{"displayField":"Log__r.Name"},{"field":"LoggingLevel__c"}]}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);

    List<LoggerNotifiableConfiguration.SourceFieldSpec> specs = LoggerNotifiableConfiguration.fromRecipient(recipient).getSourceFieldSpecs();

    System.Assert.areEqual(1, specs.size(), 'Entries without a `field` key should be silently dropped');
    System.Assert.areEqual('LoggingLevel__c', specs.get(0).field);
  }

  @IsTest
  static void it_should_treat_blank_display_overrides_as_absent() {
    // Blank displayField / displayLabel strings should behave the same as an absent key - the notifier
    // falls back to the field's own value / describe label.
    String json = '{"sourceFields":[{"field":"LoggingLevel__c","displayField":"","displayLabel":"   "}]}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);

    List<LoggerNotifiableConfiguration.SourceFieldSpec> specs = LoggerNotifiableConfiguration.fromRecipient(recipient).getSourceFieldSpecs();

    System.Assert.areEqual(1, specs.size());
    System.Assert.isNull(specs.get(0).displayField, 'Blank displayField should be treated as absent');
    System.Assert.isNull(specs.get(0).displayLabel, 'Blank displayLabel should be treated as absent');
  }

  @IsTest
  static void it_should_return_null_from_get_string_when_key_is_absent() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"someOtherKey":"value"}');

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    System.Assert.isNull(config.getString('missingKey'));
  }

  @IsTest
  static void it_should_return_the_configured_string_value_from_get_string() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"notificationTypeDeveloperName":"LoggerCustomNotification"}'
    );

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    System.Assert.areEqual('LoggerCustomNotification', config.getString('notificationTypeDeveloperName'));
  }

  @IsTest
  static void it_should_return_null_from_get_string_when_value_is_blank_or_wrong_type() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"blank":"   ","number":42,"list":["value"]}');

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    System.Assert.isNull(config.getString('blank'), 'Blank strings should be treated as absent');
    System.Assert.isNull(config.getString('number'), 'Non-string values should be treated as absent');
    System.Assert.isNull(config.getString('list'), 'List values should be treated as absent');
  }

  @IsTest
  static void it_should_return_null_from_get_string_list_when_key_is_absent() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"someOtherKey":"value"}');

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    System.Assert.isNull(config.getStringList('missingKey'));
  }

  @IsTest
  static void it_should_return_null_from_get_string_list_when_value_is_not_a_list() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"scalar":"value"}');

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    System.Assert.isNull(config.getStringList('scalar'), 'A non-array value should be treated as absent');
  }

  @IsTest
  static void it_should_return_the_configured_string_list_and_drop_blanks() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"recipientUserIds":["005000000000000001","",null,"005000000000000002","   "]}'
    );

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    List<String> values = config.getStringList('recipientUserIds');
    System.Assert.areEqual(2, values.size(), 'Blanks and nulls should be dropped: ' + values);
    System.Assert.areEqual('005000000000000001', values.get(0));
    System.Assert.areEqual('005000000000000002', values.get(1));
  }

  @IsTest
  static void it_should_return_an_empty_list_when_get_string_list_key_is_explicitly_empty() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"recipientUserIds":[]}');

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    List<String> values = config.getStringList('recipientUserIds');
    System.Assert.isNotNull(values, 'An explicit empty list is different from an absent key');
    System.Assert.areEqual(0, values.size());
  }

  @IsTest
  static void it_should_return_the_default_value_from_get_boolean_when_key_is_absent() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"someOtherKey":"value"}');

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    System.Assert.isTrue(config.getBoolean('missingKey', true));
    System.Assert.isFalse(config.getBoolean('missingKey', false));
  }

  @IsTest
  static void it_should_return_the_configured_boolean_from_get_boolean_when_present() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"includeNullValues":true,"suppressAttachments":false}'
    );

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    System.Assert.isTrue(config.getBoolean('includeNullValues', false), 'Explicit true should override the default');
    System.Assert.isFalse(config.getBoolean('suppressAttachments', true), 'Explicit false should override the default');
  }

  @IsTest
  static void it_should_fall_back_to_default_from_get_boolean_when_value_is_not_a_boolean() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"includeNullValues":"yes"}');

    LoggerNotifiableConfiguration config = LoggerNotifiableConfiguration.fromRecipient(recipient);

    System.Assert.isFalse(config.getBoolean('includeNullValues', false), 'A non-Boolean value should be treated as absent');
    System.Assert.isTrue(config.getBoolean('includeNullValues', true), 'A non-Boolean value should be treated as absent');
  }

  @IsTest
  static void it_should_flatten_source_fields_for_the_backwards_compatible_string_accessor() {
    // getSourceFields() (the pre-existing plain-strings accessor) should still work for object entries
    // by returning just the underlying `field` value from each spec.
    String json = '{"sourceFields":["LoggingLevel__c",{"field":"Message__c","displayLabel":"Body"}]}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);

    List<String> flat = LoggerNotifiableConfiguration.fromRecipient(recipient).getSourceFields();

    System.Assert.areEqual(new List<String>{ 'LoggingLevel__c', 'Message__c' }, flat);
  }
}
