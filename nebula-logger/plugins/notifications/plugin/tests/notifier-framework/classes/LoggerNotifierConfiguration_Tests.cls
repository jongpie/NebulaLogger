//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotifierConfiguration_Tests {
  @IsTest
  static void it_should_return_empty_config_when_recipient_is_null() {
    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(null);

    System.Assert.isNotNull(configuration);
    System.Assert.isNull(configuration.getSourceFieldPaths(), 'A null recipient should yield null source fields (meaning: use the notifier default)');
  }

  @IsTest
  static void it_should_return_empty_config_when_json_is_blank() {
    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(new LoggerNotificationRecipient__c());

    System.Assert.isNull(configuration.getSourceFieldPaths());
  }

  @IsTest
  static void it_should_return_empty_config_when_json_is_malformed() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = 'not json');

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    System.Assert.isNull(configuration.getSourceFieldPaths(), 'Malformed JSON should be swallowed and treated as no configuration');
  }

  @IsTest
  static void it_should_return_empty_config_when_json_is_not_an_object() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '["just", "a", "list"]');

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    System.Assert.isNull(configuration.getSourceFieldPaths(), 'A JSON array (not an object) should be treated as no configuration');
  }

  @IsTest
  static void it_should_return_null_source_fields_when_key_is_absent() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"someOtherKey": true}');

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    System.Assert.isNull(configuration.getSourceFieldPaths(), 'A configuration without sourceFields should return null so notifiers know to use their default');
  }

  @IsTest
  static void it_should_return_the_configured_source_fields_in_order() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"sourceFields":["LoggingLevel__c","Message__c","StackTrace__c"]}'
    );

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    List<String> fields = configuration.getSourceFieldPaths();
    System.Assert.areEqual(3, fields.size());
    System.Assert.areEqual('LoggingLevel__c', fields.get(0));
    System.Assert.areEqual('Message__c', fields.get(1));
    System.Assert.areEqual('StackTrace__c', fields.get(2));
  }

  @IsTest
  static void it_should_return_empty_list_when_source_fields_key_is_present_but_empty() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"sourceFields":[]}');

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    List<String> fields = configuration.getSourceFieldPaths();
    System.Assert.isNotNull(fields, 'An explicit empty list is different from an absent key');
    System.Assert.areEqual(0, fields.size(), 'Admins can explicitly opt out of rendering any source fields');
  }

  @IsTest
  static void it_should_drop_blank_entries_from_the_source_fields_list() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"sourceFields":["LoggingLevel__c","","Message__c",null,"   "]}'
    );

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    List<String> fields = configuration.getSourceFieldPaths();
    System.Assert.areEqual(2, fields.size(), 'Blanks and nulls should be dropped: ' + fields);
    System.Assert.areEqual('LoggingLevel__c', fields.get(0));
    System.Assert.areEqual('Message__c', fields.get(1));
  }

  @IsTest
  static void it_should_return_null_when_source_fields_value_is_not_a_list() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"sourceFields":"LoggingLevel__c"}');

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    System.Assert.isNull(configuration.getSourceFieldPaths(), 'A non-array sourceFields value should be treated as no configuration');
  }

  @IsTest
  static void it_should_return_source_fields_for_bare_string_entries() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"sourceFields":["LoggingLevel__c","Message__c"]}');

    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = new LoggerNotifierConfiguration(recipient).getSourceFields();

    System.Assert.areEqual(2, sourceFields.size());
    System.Assert.areEqual('LoggingLevel__c', sourceFields.get(0).sourceField);
    System.Assert.isNull(sourceFields.get(0).displayField, 'Bare strings should have no display field override');
    System.Assert.isNull(sourceFields.get(0).displayLabel, 'Bare strings should have no display label override');
    System.Assert.areEqual('Message__c', sourceFields.get(1).sourceField);
  }

  @IsTest
  static void it_should_return_source_fields_for_object_entries_with_overrides() {
    String json = '{"sourceFields":[{"sourceField":"Log__r.LoggedBy__c","displayField":"Log__r.LoggedBy__r.Username","displayLabel":"Logged By"}]}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);

    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = new LoggerNotifierConfiguration(recipient).getSourceFields();

    System.Assert.areEqual(1, sourceFields.size());
    System.Assert.areEqual('Log__r.LoggedBy__c', sourceFields.get(0).sourceField);
    System.Assert.areEqual('Log__r.LoggedBy__r.Username', sourceFields.get(0).displayField);
    System.Assert.areEqual('Logged By', sourceFields.get(0).displayLabel);
  }

  @IsTest
  static void it_should_allow_bare_strings_and_object_entries_in_the_same_list() {
    String json = '{"sourceFields":["LoggingLevel__c",{"sourceField":"Message__c","displayLabel":"Body"}]}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);

    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = new LoggerNotifierConfiguration(recipient).getSourceFields();

    System.Assert.areEqual(2, sourceFields.size());
    System.Assert.areEqual('LoggingLevel__c', sourceFields.get(0).sourceField);
    System.Assert.isNull(sourceFields.get(0).displayLabel);
    System.Assert.areEqual('Message__c', sourceFields.get(1).sourceField);
    System.Assert.areEqual('Body', sourceFields.get(1).displayLabel);
  }

  @IsTest
  static void it_should_drop_object_entries_missing_a_source_field_key() {
    String json = '{"sourceFields":[{"displayField":"Log__r.Name"},{"sourceField":"LoggingLevel__c"}]}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);

    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = new LoggerNotifierConfiguration(recipient).getSourceFields();

    System.Assert.areEqual(1, sourceFields.size(), 'Entries without a `sourceField` key should be silently dropped');
    System.Assert.areEqual('LoggingLevel__c', sourceFields.get(0).sourceField);
  }

  @IsTest
  static void it_should_treat_blank_display_overrides_as_absent() {
    // Blank displayField / displayLabel strings should behave the same as an absent key - the notifier
    // falls back to the field's own value / describe label.
    String json = '{"sourceFields":[{"sourceField":"LoggingLevel__c","displayField":"","displayLabel":"   "}]}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);

    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = new LoggerNotifierConfiguration(recipient).getSourceFields();

    System.Assert.areEqual(1, sourceFields.size());
    System.Assert.isNull(sourceFields.get(0).displayField, 'Blank displayField should be treated as absent');
    System.Assert.isNull(sourceFields.get(0).displayLabel, 'Blank displayLabel should be treated as absent');
  }

  @IsTest
  static void it_should_return_null_from_get_string_when_key_is_absent() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"someOtherKey":"value"}');

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    System.Assert.isNull(configuration.getString('missingKey'));
  }

  @IsTest
  static void it_should_return_the_configured_string_value_from_get_string() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"notificationTypeDeveloperName":"LoggerCustomNotification"}'
    );

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    System.Assert.areEqual('LoggerCustomNotification', configuration.getString('notificationTypeDeveloperName'));
  }

  @IsTest
  static void it_should_return_null_from_get_string_when_value_is_blank_or_wrong_type() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"blank":"   ","number":42,"list":["value"]}');

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    System.Assert.isNull(configuration.getString('blank'), 'Blank strings should be treated as absent');
    System.Assert.isNull(configuration.getString('number'), 'Non-string values should be treated as absent');
    System.Assert.isNull(configuration.getString('list'), 'List values should be treated as absent');
  }

  @IsTest
  static void it_should_return_null_from_get_string_list_when_key_is_absent() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"someOtherKey":"value"}');

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    System.Assert.isNull(configuration.getStringList('missingKey'));
  }

  @IsTest
  static void it_should_return_null_from_get_string_list_when_value_is_not_a_list() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"scalar":"value"}');

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    System.Assert.isNull(configuration.getStringList('scalar'), 'A non-array value should be treated as absent');
  }

  @IsTest
  static void it_should_return_the_configured_string_list_and_drop_blanks() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"recipientUserIds":["005000000000000001","",null,"005000000000000002","   "]}'
    );

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    List<String> values = configuration.getStringList('recipientUserIds');
    System.Assert.areEqual(2, values.size(), 'Blanks and nulls should be dropped: ' + values);
    System.Assert.areEqual('005000000000000001', values.get(0));
    System.Assert.areEqual('005000000000000002', values.get(1));
  }

  @IsTest
  static void it_should_return_an_empty_list_when_get_string_list_key_is_explicitly_empty() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"recipientUserIds":[]}');

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    List<String> values = configuration.getStringList('recipientUserIds');
    System.Assert.isNotNull(values, 'An explicit empty list is different from an absent key');
    System.Assert.areEqual(0, values.size());
  }

  @IsTest
  static void it_should_return_the_default_value_from_get_boolean_when_key_is_absent() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"someOtherKey":"value"}');

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    System.Assert.isTrue(configuration.getBoolean('missingKey', true));
    System.Assert.isFalse(configuration.getBoolean('missingKey', false));
  }

  @IsTest
  static void it_should_return_the_configured_boolean_from_get_boolean_when_present() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      ConfigurationJson__c = '{"includeNullValues":true,"suppressAttachments":false}'
    );

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    System.Assert.isTrue(configuration.getBoolean('includeNullValues', false), 'Explicit true should override the default');
    System.Assert.isFalse(configuration.getBoolean('suppressAttachments', true), 'Explicit false should override the default');
  }

  @IsTest
  static void it_should_fall_back_to_default_from_get_boolean_when_value_is_not_a_boolean() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"includeNullValues":"yes"}');

    LoggerNotifierConfiguration configuration = new LoggerNotifierConfiguration(recipient);

    System.Assert.isFalse(configuration.getBoolean('includeNullValues', false), 'A non-Boolean value should be treated as absent');
    System.Assert.isTrue(configuration.getBoolean('includeNullValues', true), 'A non-Boolean value should be treated as absent');
  }

  @IsTest
  static void it_should_flatten_source_fields_for_the_backwards_compatible_string_accessor() {
    // getSourceFieldPaths() (the pre-existing plain-strings accessor) should still work for object entries
    // by returning just the underlying `sourceField` value from each entry.
    String json = '{"sourceFields":["LoggingLevel__c",{"sourceField":"Message__c","displayLabel":"Body"}]}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);

    List<String> flat = new LoggerNotifierConfiguration(recipient).getSourceFieldPaths();

    System.Assert.areEqual(new List<String>{ 'LoggingLevel__c', 'Message__c' }, flat);
  }
}
