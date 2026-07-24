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
  static void it_should_parse_the_configured_max_length_from_an_object_entry() {
    String json = '{"sourceFields":[{"sourceField":"Message__c","maxLength":500}]}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);

    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = new LoggerNotifierConfiguration(recipient).getSourceFields();

    System.Assert.areEqual(1, sourceFields.size());
    System.Assert.areEqual(500, sourceFields.get(0).maxLength);
  }

  @IsTest
  static void it_should_default_max_length_to_null_when_absent_or_not_a_positive_integer() {
    // Absent, wrong type (string), zero, and negative all resolve to null so notifiers know "no admin cap".
    String json =
      '{"sourceFields":[' +
      '{"sourceField":"A__c"},' +
      '{"sourceField":"B__c","maxLength":"nope"},' +
      '{"sourceField":"C__c","maxLength":0},' +
      '{"sourceField":"D__c","maxLength":-5}' +
      ']}';
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = json);

    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = new LoggerNotifierConfiguration(recipient).getSourceFields();

    System.Assert.areEqual(4, sourceFields.size());
    for (LoggerNotifierConfiguration.SourceFieldDefinition definition : sourceFields) {
      System.Assert.isNull(definition.maxLength, 'Non-positive-integer maxLength values should parse as null: ' + definition.sourceField);
    }
  }

  @IsTest
  static void it_should_default_max_length_to_null_for_bare_string_entries() {
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(ConfigurationJson__c = '{"sourceFields":["Message__c"]}');

    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = new LoggerNotifierConfiguration(recipient).getSourceFields();

    System.Assert.areEqual(1, sourceFields.size());
    System.Assert.isNull(sourceFields.get(0).maxLength);
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

  @IsTest
  static void it_should_return_no_validation_errors_when_json_is_blank() {
    System.Assert.areEqual(
      0,
      LoggerNotifierConfiguration.validate(null, Schema.LogEntry__c.SObjectType).size(),
      'A null JSON should be treated as absent, not invalid'
    );
    System.Assert.areEqual(
      0,
      LoggerNotifierConfiguration.validate('', Schema.LogEntry__c.SObjectType).size(),
      'A blank JSON should be treated as absent, not invalid'
    );
    System.Assert.areEqual(
      0,
      LoggerNotifierConfiguration.validate('   ', Schema.LogEntry__c.SObjectType).size(),
      'Whitespace-only JSON should be treated as absent, not invalid'
    );
  }

  @IsTest
  static void it_should_return_a_validation_error_for_malformed_json() {
    List<String> errors = LoggerNotifierConfiguration.validate('{"foo":', Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual(1, errors.size(), 'Malformed JSON should produce a single error: ' + errors);
    System.Assert.isTrue(
      errors.get(0).startsWith(LoggerNotifierConfiguration.INVALID_JSON_ERROR_PREFIX),
      'Malformed JSON error should carry the invalid-JSON prefix: ' + errors.get(0)
    );
  }

  @IsTest
  static void it_should_return_a_validation_error_when_top_level_is_not_a_map() {
    System.Assert.areEqual(
      new List<String>{ LoggerNotifierConfiguration.TOP_LEVEL_SHAPE_ERROR_MESSAGE },
      LoggerNotifierConfiguration.validate('["foo","bar"]', Schema.LogEntry__c.SObjectType)
    );
    System.Assert.areEqual(
      new List<String>{ LoggerNotifierConfiguration.TOP_LEVEL_SHAPE_ERROR_MESSAGE },
      LoggerNotifierConfiguration.validate('42', Schema.LogEntry__c.SObjectType)
    );
    System.Assert.areEqual(
      new List<String>{ LoggerNotifierConfiguration.TOP_LEVEL_SHAPE_ERROR_MESSAGE },
      LoggerNotifierConfiguration.validate('"just a string"', Schema.LogEntry__c.SObjectType)
    );
  }

  @IsTest
  static void it_should_return_no_validation_errors_when_source_fields_is_absent() {
    System.Assert.areEqual(
      0,
      LoggerNotifierConfiguration.validate('{"someOtherKey":"value"}', Schema.LogEntry__c.SObjectType).size(),
      'Configs without a sourceFields key are valid'
    );
  }

  @IsTest
  static void it_should_return_a_validation_error_when_source_fields_is_not_a_list() {
    List<String> errors = LoggerNotifierConfiguration.validate('{"sourceFields":"LoggingLevel__c"}', Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual(new List<String>{ LoggerNotifierConfiguration.SOURCE_FIELDS_NOT_A_LIST_ERROR_MESSAGE }, errors);
  }

  @IsTest
  static void it_should_return_a_validation_error_when_object_entry_uses_the_wrong_primary_key() {
    // This is the exact regression case from the CMDT `field` -> `sourceField` rename - the pre-fix parser
    // silently dropped these entries at runtime. The validator flags them at save time so admins never
    // persist a config the notifier will silently ignore.
    List<String> errors = LoggerNotifierConfiguration.validate('{"sourceFields":[{"field":"LoggingLevel__c"}]}', Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual(new List<String>{ LoggerNotifierConfiguration.OBJECT_ENTRY_MISSING_SOURCE_FIELD_ERROR_MESSAGE }, errors);
  }

  @IsTest
  static void it_should_return_a_validation_error_when_object_entry_source_field_is_blank() {
    List<String> errors = LoggerNotifierConfiguration.validate('{"sourceFields":[{"sourceField":"","displayLabel":"X"}]}', Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual(new List<String>{ LoggerNotifierConfiguration.OBJECT_ENTRY_MISSING_SOURCE_FIELD_ERROR_MESSAGE }, errors);
  }

  @IsTest
  static void it_should_return_a_validation_error_for_a_bare_string_path_that_does_not_resolve() {
    List<String> errors = LoggerNotifierConfiguration.validate('{"sourceFields":["ThisFieldDoesNotExist__c"]}', Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual(1, errors.size(), 'One unresolvable bare-string entry should produce one error: ' + errors);
    System.Assert.areEqual(LoggerNotifierConfiguration.UNRESOLVABLE_SOURCE_FIELD_ERROR_PREFIX + 'ThisFieldDoesNotExist__c', errors.get(0));
  }

  @IsTest
  static void it_should_return_a_validation_error_for_an_object_source_field_that_does_not_resolve() {
    List<String> errors = LoggerNotifierConfiguration.validate('{"sourceFields":[{"sourceField":"ThisFieldDoesNotExist__c"}]}', Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual(new List<String>{ LoggerNotifierConfiguration.UNRESOLVABLE_SOURCE_FIELD_ERROR_PREFIX + 'ThisFieldDoesNotExist__c' }, errors);
  }

  @IsTest
  static void it_should_return_a_validation_error_for_a_display_field_that_does_not_resolve() {
    List<String> errors = LoggerNotifierConfiguration.validate(
      '{"sourceFields":[{"sourceField":"LoggingLevel__c","displayField":"NotARealDisplayField__c"}]}',
      Schema.LogEntry__c.SObjectType
    );

    System.Assert.areEqual(new List<String>{ LoggerNotifierConfiguration.UNRESOLVABLE_DISPLAY_FIELD_ERROR_PREFIX + 'NotARealDisplayField__c' }, errors);
  }

  @IsTest
  static void it_should_skip_field_path_checks_when_source_type_is_null() {
    // The rule handler blocks a save with an unresolvable SourceSObjectType__c separately - the recipient
    // handler shouldn't double-report the same problem.
    List<String> errors = LoggerNotifierConfiguration.validate('{"sourceFields":["AnythingGoesHere__c"]}', null);

    System.Assert.areEqual(0, errors.size(), 'A null source type should skip field-path validation: ' + errors);
  }

  @IsTest
  static void it_should_pass_validation_for_a_realistic_slack_style_config() {
    String json =
      '{"sourceFields":["LoggingLevel__c","Message__c",' +
      '{"sourceField":"Log__r.LoggedBy__c","displayField":"Log__r.LoggedBy__r.Username"},' +
      '{"sourceField":"Log__r.OrganizationId__c"}],"includeNullValues":false}';
    List<String> errors = LoggerNotifierConfiguration.validate(json, Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual(0, errors.size(), 'A realistic Slack-style config should validate cleanly: ' + errors);
  }

  @IsTest
  static void it_should_accumulate_multiple_errors_across_entries() {
    String json = '{"sourceFields":["BadFieldA__c",{"sourceField":"BadFieldB__c"},{"field":"BadFieldC__c"}]}';
    List<String> errors = LoggerNotifierConfiguration.validate(json, Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual(3, errors.size(), 'Every offending entry should get its own error: ' + errors);
  }

  @IsTest
  static void it_should_validate_a_positive_integer_max_length_cleanly() {
    String json = '{"sourceFields":[{"sourceField":"Message__c","maxLength":500}]}';

    List<String> errors = LoggerNotifierConfiguration.validate(json, Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual(0, errors.size(), 'A positive integer maxLength should validate cleanly: ' + errors);
  }

  @IsTest
  static void it_should_reject_a_max_length_that_is_not_a_positive_integer() {
    String json =
      '{"sourceFields":[' +
      '{"sourceField":"Message__c","maxLength":"nope"},' +
      '{"sourceField":"LoggingLevel__c","maxLength":0},' +
      '{"sourceField":"Origin__c","maxLength":-10},' +
      '{"sourceField":"StackTrace__c","maxLength":null}' +
      ']}';

    List<String> errors = LoggerNotifierConfiguration.validate(json, Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual(4, errors.size(), 'Every non-positive-integer maxLength should surface its own error: ' + errors);
    for (String error : errors) {
      System.Assert.areEqual(LoggerNotifierConfiguration.MAX_LENGTH_MUST_BE_POSITIVE_INTEGER_ERROR_MESSAGE, error);
    }
  }
}
