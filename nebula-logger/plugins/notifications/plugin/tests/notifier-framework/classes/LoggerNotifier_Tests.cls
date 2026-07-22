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
    List<String> flatPaths = new List<String>{ 'LoggingLevel__c', 'Message__c' };

    List<SObject> hydrated = LoggerNotifier.hydrateRecordsWithFieldPaths(records, flatPaths);

    // Same reference means we skipped the SOQL round-trip entirely - the flat-path short-circuit fired.
    System.Assert.isTrue(hydrated === records, 'Flat paths should short-circuit hydration and return the input list untouched');
  }

  @IsTest
  static void it_should_return_records_untouched_when_records_are_null_or_empty() {
    System.Assert.isNull(LoggerNotifier.hydrateRecordsWithFieldPaths(null, new List<String>{ 'Log__r.Name' }));
    List<SObject> empty = new List<SObject>();
    System.Assert.isTrue(LoggerNotifier.hydrateRecordsWithFieldPaths(empty, new List<String>{ 'Log__r.Name' }) === empty);
  }

  @IsTest
  static void it_should_return_records_untouched_when_field_paths_are_null_or_empty() {
    List<SObject> records = new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name()) };

    System.Assert.isTrue(LoggerNotifier.hydrateRecordsWithFieldPaths(records, null) === records);
    System.Assert.isTrue(LoggerNotifier.hydrateRecordsWithFieldPaths(records, new List<String>()) === records);
  }

  @IsTest
  static void it_should_leave_records_without_ids_untouched() {
    // Records without a persisted Id cannot be re-queried, so the hydration falls through and returns them unchanged.
    List<SObject> records = new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name()) };

    List<SObject> hydrated = LoggerNotifier.hydrateRecordsWithFieldPaths(records, new List<String>{ 'Log__r.Name' });

    System.Assert.areEqual(1, hydrated.size());
    System.Assert.isTrue(hydrated.get(0) === records.get(0), 'Records without Ids should fall through untouched');
  }

  @IsTest
  static void it_should_hydrate_parent_lookups_when_dotted_paths_are_configured() {
    Log__c log = new Log__c(TransactionId__c = 'test-transaction');
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    // Log__c.Name is auto-numbered; Salesforce only populates it into the local record on requery.
    String expectedParentName = [SELECT Name FROM Log__c WHERE Id = :log.Id].Name;
    // The trigger-supplied record only carries the FK; Log__r.Name is unpopulated in-memory.
    LogEntry__c triggerCopy = new LogEntry__c(Id = logEntry.Id, Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name());

    List<SObject> hydrated = LoggerNotifier.hydrateRecordsWithFieldPaths(new List<SObject>{ triggerCopy }, new List<String>{ 'Log__r.Name' });

    System.Assert.areEqual(1, hydrated.size());
    LogEntry__c hydratedEntry = (LogEntry__c) hydrated.get(0);
    System.Assert.areEqual(log.Id, hydratedEntry.Log__c);
    System.Assert.isNotNull(hydratedEntry.Log__r, 'Log__r should have been hydrated by the re-query');
    System.Assert.areEqual(expectedParentName, hydratedEntry.Log__r.Name, 'Log__r.Name should now be resolvable via getValueByPath');
  }

  @IsTest
  static void it_should_drop_unresolvable_paths_from_the_select() {
    // A single bogus configured path used to poison the whole SELECT, which fell back to un-hydrated
    // records and made every OTHER configured field render as its null placeholder. Dropping unresolvable
    // paths from the SELECT lets the good ones still hydrate.
    Log__c log = new Log__c(TransactionId__c = 'drop-unresolvable');
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    String expectedParentName = [SELECT Name FROM Log__c WHERE Id = :log.Id].Name;
    LogEntry__c triggerCopy = new LogEntry__c(Id = logEntry.Id, Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name());

    List<SObject> hydrated = LoggerNotifier.hydrateRecordsWithFieldPaths(
      new List<SObject>{ triggerCopy },
      new List<String>{ 'Log__r.Name', 'NoSuchPath__r.Name' }
    );

    System.Assert.areEqual(1, hydrated.size());
    LogEntry__c hydratedEntry = (LogEntry__c) hydrated.get(0);
    System.Assert.areEqual(expectedParentName, hydratedEntry.Log__r.Name, 'Good path should still hydrate after the bad path was dropped');
  }
}
