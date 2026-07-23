//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotifier_Tests {
  @IsTest
  static void it_should_return_one_spec_per_field_name_with_no_overrides() {
    // TODO eliminate this, the list of source fields will vary based on rule's SourceSObjectType__c,
    // so definining defaults needs to be sobject-specific.
    // The recipients should provide a list of source fields, so there shouldn't be a need for default fields.
    List<String> fieldNames = new List<String>{ 'LoggingLevel__c', 'Message__c', 'Origin__c' };

    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = LoggerNotifier.buildDefaultSourceFields(fieldNames);

    System.Assert.areEqual(3, sourceFields.size());
    for (Integer i = 0; i < fieldNames.size(); i++) {
      System.Assert.areEqual(fieldNames.get(i), sourceFields.get(i).sourceField, 'Order should match the input list');
      System.Assert.isNull(sourceFields.get(i).displayField, 'Default sourceFields should not override the display field');
      System.Assert.isNull(sourceFields.get(i).displayLabel, 'Default sourceFields should not override the display label');
    }
  }

  @IsTest
  static void it_should_return_an_empty_list_when_field_names_is_empty() {
    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = LoggerNotifier.buildDefaultSourceFields(new List<String>());

    System.Assert.areEqual(0, sourceFields.size(), 'An empty input list should yield an empty sourceField list');
  }

  @IsTest
  static void it_should_return_null_when_record_is_null() {
    System.Assert.isNull(LoggerNotifier.getValueByPath(null, 'LoggingLevel__c'));
  }

  @IsTest
  static void it_should_return_null_when_field_path_is_blank() {
    System.Assert.isNull(LoggerNotifier.getValueByPath(new LogEntry__c(), null));
    System.Assert.isNull(LoggerNotifier.getValueByPath(new LogEntry__c(), ''));
    System.Assert.isNull(LoggerNotifier.getValueByPath(new LogEntry__c(), '  '));
  }

  @IsTest
  static void it_should_return_the_direct_field_value() {
    LogEntry__c logEntry = new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name(), Message__c = 'boom');

    System.Assert.areEqual(System.LoggingLevel.ERROR.name(), LoggerNotifier.getValueByPath(logEntry, 'LoggingLevel__c'));
    System.Assert.areEqual('boom', LoggerNotifier.getValueByPath(logEntry, 'Message__c'));
  }

  @IsTest
  static void it_should_return_null_for_an_unknown_field_on_the_record() {
    LogEntry__c logEntry = new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name());

    System.Assert.isNull(LoggerNotifier.getValueByPath(logEntry, 'ThisFieldDoesNotExist__c'), 'Unknown fields should return null rather than throwing');
  }

  @IsTest
  static void it_should_walk_dotted_relationship_paths_using_json_hydration() {
    // In-memory parent-relationship hydration goes through JSON deserialization; the LogEntry__c has
    // a Log__r sub-record with its own Name populated.
    LogEntry__c logEntry = (LogEntry__c) System.JSON.deserialize(
      '{"attributes":{"type":"LogEntry__c"},"LoggingLevel__c":"ERROR","Log__r":{"attributes":{"type":"Log__c"},"Name":"Parent Log"}}',
      LogEntry__c.class
    );

    System.Assert.areEqual('Parent Log', LoggerNotifier.getValueByPath(logEntry, 'Log__r.Name'));
  }

  @IsTest
  static void it_should_return_null_when_a_parent_hop_is_not_populated() {
    LogEntry__c logEntry = new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name());

    System.Assert.isNull(
      LoggerNotifier.getValueByPath(logEntry, 'Log__r.Name'),
      'A parent hop with no in-memory sub-record should return null rather than throwing'
    );
  }

  @IsTest
  static void it_should_return_null_when_a_relationship_segment_is_unknown() {
    LogEntry__c logEntry = new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name());

    System.Assert.isNull(
      LoggerNotifier.getValueByPath(logEntry, 'NoSuchRelationship__r.Name'),
      'An unknown relationship segment should return null rather than throwing'
    );
  }

  @IsTest
  static void it_should_return_null_when_type_is_null() {
    System.Assert.isNull(LoggerNotifier.getDescribeByPath(null, 'LoggingLevel__c'));
  }

  @IsTest
  static void it_should_return_null_describe_when_field_path_is_blank() {
    System.Assert.isNull(LoggerNotifier.getDescribeByPath(Schema.LogEntry__c.SObjectType, null));
    System.Assert.isNull(LoggerNotifier.getDescribeByPath(Schema.LogEntry__c.SObjectType, ''));
  }

  @IsTest
  static void it_should_return_the_direct_field_describe() {
    Schema.DescribeFieldResult describe = LoggerNotifier.getDescribeByPath(Schema.LogEntry__c.SObjectType, 'LoggingLevel__c');

    System.Assert.isNotNull(describe);
    System.Assert.areEqual('LoggingLevel__c', describe.getName());
  }

  @IsTest
  static void it_should_return_null_when_the_terminal_field_does_not_exist() {
    System.Assert.isNull(
      LoggerNotifier.getDescribeByPath(Schema.LogEntry__c.SObjectType, 'ThisFieldDoesNotExist__c'),
      'An unknown terminal field should return null rather than throwing'
    );
  }

  @IsTest
  static void it_should_walk_dotted_relationship_paths_and_describe_the_terminal_field() {
    Schema.DescribeFieldResult describe = LoggerNotifier.getDescribeByPath(Schema.LogEntry__c.SObjectType, 'Log__r.Name');

    System.Assert.isNotNull(describe, 'Log__r.Name should resolve to the Name field on Log__c');
    System.Assert.areEqual('Name', describe.getName());
  }

  @IsTest
  static void it_should_return_null_describe_when_a_relationship_segment_is_unknown() {
    System.Assert.isNull(
      LoggerNotifier.getDescribeByPath(Schema.LogEntry__c.SObjectType, 'NoSuchRelationship__r.Name'),
      'An unknown relationship segment should return null rather than throwing'
    );
  }

  @IsTest
  static void it_should_return_records_untouched_when_no_dotted_paths_are_configured() {
    List<SObject> records = new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name()) };
    Set<String> flatPaths = new Set<String>{ 'LoggingLevel__c', 'Message__c' };

    List<SObject> requeriedRecords = LoggerNotifier.requeryRecordsWithFieldPaths(records, flatPaths);

    // Same reference means we skipped the SOQL round-trip entirely - the flat-path short-circuit fired.
    System.Assert.isTrue(requeriedRecords === records, 'Flat paths should short-circuit the re-query and return the input list untouched');
  }

  @IsTest
  static void it_should_return_records_untouched_when_records_are_null_or_empty() {
    System.Assert.isNull(LoggerNotifier.requeryRecordsWithFieldPaths(null, new Set<String>{ 'Log__r.Name' }));
    List<SObject> empty = new List<SObject>();
    System.Assert.isTrue(LoggerNotifier.requeryRecordsWithFieldPaths(empty, new Set<String>{ 'Log__r.Name' }) === empty);
  }

  @IsTest
  static void it_should_return_records_untouched_when_field_paths_are_null_or_empty() {
    List<SObject> records = new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name()) };

    System.Assert.isTrue(LoggerNotifier.requeryRecordsWithFieldPaths(records, null) === records);
    System.Assert.isTrue(LoggerNotifier.requeryRecordsWithFieldPaths(records, new Set<String>()) === records);
  }

  @IsTest
  static void it_should_leave_records_without_ids_untouched() {
    // Records without a persisted Id cannot be re-queried, so the helper falls through and returns them unchanged.
    List<SObject> records = new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name()) };

    List<SObject> requeriedRecords = LoggerNotifier.requeryRecordsWithFieldPaths(records, new Set<String>{ 'Log__r.Name' });

    System.Assert.areEqual(1, requeriedRecords.size());
    System.Assert.isTrue(requeriedRecords.get(0) === records.get(0), 'Records without Ids should fall through untouched');
  }

  @IsTest
  static void it_should_load_parent_lookups_when_dotted_paths_are_configured() {
    Log__c log = new Log__c(TransactionId__c = 'test-transaction');
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    // Log__c.Name is auto-numbered; Salesforce only populates it into the local record on re-query.
    String expectedParentName = [SELECT Name FROM Log__c WHERE Id = :log.Id].Name;
    // The trigger-supplied record only carries the FK; Log__r.Name is unpopulated in-memory.
    LogEntry__c triggerCopy = new LogEntry__c(Id = logEntry.Id, Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name());

    List<SObject> requeriedRecords = LoggerNotifier.requeryRecordsWithFieldPaths(new List<SObject>{ triggerCopy }, new Set<String>{ 'Log__r.Name' });

    System.Assert.areEqual(1, requeriedRecords.size());
    LogEntry__c requeriedEntry = (LogEntry__c) requeriedRecords.get(0);
    System.Assert.areEqual(log.Id, requeriedEntry.Log__c);
    System.Assert.isNotNull(requeriedEntry.Log__r, 'Log__r should have been loaded by the re-query');
    System.Assert.areEqual(expectedParentName, requeriedEntry.Log__r.Name, 'Log__r.Name should now be resolvable via getValueByPath');
  }

  @IsTest
  static void it_should_drop_unresolvable_paths_from_the_select() {
    // A single bogus configured path used to poison the whole SELECT, which fell back to the
    // trigger-supplied records and made every OTHER configured field render as its null placeholder.
    // Dropping unresolvable paths from the SELECT lets the good ones still resolve.
    Log__c log = new Log__c(TransactionId__c = 'drop-unresolvable');
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    String expectedParentName = [SELECT Name FROM Log__c WHERE Id = :log.Id].Name;
    LogEntry__c triggerCopy = new LogEntry__c(Id = logEntry.Id, Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name());

    List<SObject> requeriedRecords = LoggerNotifier.requeryRecordsWithFieldPaths(
      new List<SObject>{ triggerCopy },
      new Set<String>{ 'Log__r.Name', 'NoSuchPath__r.Name' }
    );

    System.Assert.areEqual(1, requeriedRecords.size());
    LogEntry__c requeriedEntry = (LogEntry__c) requeriedRecords.get(0);
    System.Assert.areEqual(expectedParentName, requeriedEntry.Log__r.Name, 'Good path should still resolve after the bad path was dropped');
  }

  @IsTest
  static void it_should_derive_parent_name_path_for_a_reference_field() {
    // LogEntry__c.Log__c is a REFERENCE to Log__c, and Log__c has a Name field.
    String parentNamePath = LoggerNotifier.deriveParentNamePath('Log__c', Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual('Log__r.Name', parentNamePath, 'A REFERENCE field with a Name-bearing parent should derive `<relationshipName>.Name`');
  }

  @IsTest
  static void it_should_derive_parent_name_path_when_field_path_is_dotted() {
    // Log__c.LoggedBy__c is a REFERENCE to User. Starting from LogEntry__c and going Log__r.LoggedBy__c
    // should yield Log__r.LoggedBy__r.Name.
    String parentNamePath = LoggerNotifier.deriveParentNamePath('Log__r.LoggedBy__c', Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual('Log__r.LoggedBy__r.Name', parentNamePath, 'A dotted REFERENCE path should replace only the terminal FK segment');
  }

  @IsTest
  static void it_should_return_null_parent_name_path_for_non_reference_fields() {
    System.Assert.isNull(
      LoggerNotifier.deriveParentNamePath('LoggingLevel__c', Schema.LogEntry__c.SObjectType),
      'A non-REFERENCE field has no parent to link to'
    );
  }

  @IsTest
  static void it_should_return_null_parent_name_path_for_unknown_fields() {
    System.Assert.isNull(
      LoggerNotifier.deriveParentNamePath('ThisFieldDoesNotExist__c', Schema.LogEntry__c.SObjectType),
      'An unknown field should return null rather than throwing'
    );
  }

  @IsTest
  static void it_should_return_null_parent_name_path_for_blank_or_null_inputs() {
    System.Assert.isNull(LoggerNotifier.deriveParentNamePath(null, Schema.LogEntry__c.SObjectType));
    System.Assert.isNull(LoggerNotifier.deriveParentNamePath('', Schema.LogEntry__c.SObjectType));
    System.Assert.isNull(LoggerNotifier.deriveParentNamePath('Log__c', null));
  }

  @IsTest
  static void it_should_return_an_empty_set_when_source_fields_are_null_or_empty() {
    System.Assert.areEqual(new Set<String>(), LoggerNotifier.collectFieldPathsToRequery(null, Schema.LogEntry__c.SObjectType));
    System.Assert.areEqual(
      new Set<String>(),
      LoggerNotifier.collectFieldPathsToRequery(new List<LoggerNotifierConfiguration.SourceFieldDefinition>(), Schema.LogEntry__c.SObjectType)
    );
  }

  @IsTest
  static void it_should_collect_the_bare_source_field_path_for_non_reference_definitions() {
    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = new List<LoggerNotifierConfiguration.SourceFieldDefinition>{
      new LoggerNotifierConfiguration.SourceFieldDefinition('LoggingLevel__c', null, null),
      new LoggerNotifierConfiguration.SourceFieldDefinition('Message__c', null, null)
    };

    Set<String> paths = LoggerNotifier.collectFieldPathsToRequery(sourceFields, Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual(new Set<String>{ 'LoggingLevel__c', 'Message__c' }, paths, 'Non-REFERENCE definitions should contribute only their source field');
  }

  @IsTest
  static void it_should_include_the_parent_name_path_for_reference_definitions_without_override() {
    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = new List<LoggerNotifierConfiguration.SourceFieldDefinition>{
      new LoggerNotifierConfiguration.SourceFieldDefinition('Log__c', null, null)
    };

    Set<String> paths = LoggerNotifier.collectFieldPathsToRequery(sourceFields, Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual(new Set<String>{ 'Log__c', 'Log__r.Name' }, paths, 'A REFERENCE field with no override should also request the parent Name');
  }

  @IsTest
  static void it_should_include_the_display_field_override_instead_of_the_parent_name_path() {
    List<LoggerNotifierConfiguration.SourceFieldDefinition> sourceFields = new List<LoggerNotifierConfiguration.SourceFieldDefinition>{
      new LoggerNotifierConfiguration.SourceFieldDefinition('Log__c', 'Log__r.TransactionId__c', null)
    };

    Set<String> paths = LoggerNotifier.collectFieldPathsToRequery(sourceFields, Schema.LogEntry__c.SObjectType);

    System.Assert.areEqual(
      new Set<String>{ 'Log__c', 'Log__r.TransactionId__c' },
      paths,
      'An explicit displayField should replace the auto-derived parent Name path'
    );
  }

  @IsTest
  static void it_should_resolve_the_link_target_id_for_a_reference_field() {
    // The trigger-supplied record carries the FK; the REFERENCE case reads it directly with no re-query.
    Id logId = (Id) LoggerMockDataCreator.createId(Schema.Log__c.SObjectType);
    LogEntry__c logEntry = new LogEntry__c(Log__c = logId);
    Schema.DescribeFieldResult logDescribe = LoggerNotifier.getDescribeByPath(Schema.LogEntry__c.SObjectType, 'Log__c');

    Id linkTarget = LoggerNotifier.resolveLinkTarget(logEntry, 'Log__c', logDescribe);

    System.Assert.areEqual(logId, linkTarget, 'A REFERENCE field should link to the referenced record');
  }

  @IsTest
  static void it_should_return_null_link_target_for_a_reference_field_with_a_null_value() {
    LogEntry__c logEntry = new LogEntry__c();
    Schema.DescribeFieldResult logDescribe = LoggerNotifier.getDescribeByPath(Schema.LogEntry__c.SObjectType, 'Log__c');

    System.Assert.isNull(LoggerNotifier.resolveLinkTarget(logEntry, 'Log__c', logDescribe), 'A REFERENCE field with a null value should not link');
  }

  @IsTest
  static void it_should_resolve_the_link_target_for_a_bare_name_path() {
    // A `Name` on the source record links to the source record itself.
    Id fakeId = (Id) LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType);
    LogEntry__c logEntry = (LogEntry__c) System.JSON.deserialize(
      '{"attributes":{"type":"LogEntry__c"},"Id":"' + fakeId + '","Name":"LE-0001"}',
      LogEntry__c.class
    );
    Schema.DescribeFieldResult nameDescribe = LoggerNotifier.getDescribeByPath(Schema.LogEntry__c.SObjectType, 'Name');

    Id linkTarget = LoggerNotifier.resolveLinkTarget(logEntry, 'Name', nameDescribe);

    System.Assert.areEqual(fakeId, linkTarget, 'A bare Name path should link to the source record');
  }

  @IsTest
  static void it_should_resolve_the_link_target_for_a_parent_dotted_name_path() {
    Id logId = (Id) LoggerMockDataCreator.createId(Schema.Log__c.SObjectType);
    // Trigger-supplied FK on the source record; the walker reads the FK column, not the __r sub-record.
    LogEntry__c logEntry = new LogEntry__c(Log__c = logId);
    Schema.DescribeFieldResult logNameDescribe = LoggerNotifier.getDescribeByPath(Schema.LogEntry__c.SObjectType, 'Log__r.Name');

    Id linkTarget = LoggerNotifier.resolveLinkTarget(logEntry, 'Log__r.Name', logNameDescribe);

    System.Assert.areEqual(logId, linkTarget, 'A parent-dotted Name path should link to the parent record');
  }

  @IsTest
  static void it_should_return_null_link_target_for_a_scalar_non_name_path() {
    LogEntry__c logEntry = new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name());
    Schema.DescribeFieldResult loggingLevelDescribe = LoggerNotifier.getDescribeByPath(Schema.LogEntry__c.SObjectType, 'LoggingLevel__c');

    System.Assert.isNull(
      LoggerNotifier.resolveLinkTarget(logEntry, 'LoggingLevel__c', loggingLevelDescribe),
      'A scalar non-Name field should not link to anything'
    );
  }

  @IsTest
  static void it_should_return_null_link_target_for_null_inputs() {
    Schema.DescribeFieldResult logDescribe = LoggerNotifier.getDescribeByPath(Schema.LogEntry__c.SObjectType, 'Log__c');

    System.Assert.isNull(LoggerNotifier.resolveLinkTarget(null, 'Log__c', logDescribe));
    System.Assert.isNull(LoggerNotifier.resolveLinkTarget(new LogEntry__c(), null, logDescribe));
    System.Assert.isNull(LoggerNotifier.resolveLinkTarget(new LogEntry__c(), '', logDescribe));
    System.Assert.isNull(LoggerNotifier.resolveLinkTarget(new LogEntry__c(), 'Log__c', null));
  }
}
