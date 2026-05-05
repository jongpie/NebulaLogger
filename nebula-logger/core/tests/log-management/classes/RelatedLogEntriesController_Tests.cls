//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class RelatedLogEntriesController_Tests {
  private static final Id TARGET_RECORD_ID = System.UserInfo.getUserId();
  private static final Integer TOTAL_LOG_ENTRIES = 10;
  private static final Integer TOTAL_RELATED_LOG_ENTRIES = 7;

  static {
    // Don't use the org's actual custom metadata records when running tests
    LoggerConfigurationSelector.useMocks();
  }

  @TestSetup
  static void setupData() {
    LoggerSObjectHandler.shouldExecute(false);

    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    insert log;

    List<LogEntry__c> logEntries = new List<LogEntry__c>();
    for (Integer i = 0; i < TOTAL_LOG_ENTRIES; i++) {
      LogEntry__c logEntry = new LogEntry__c(
        Log__c = log.Id,
        Message__c = 'test ' + i,
        LoggingLevel__c = i < 5 ? 'ERROR' : 'INFO',
        OriginSourceMetadataType__c = i < 3 ? 'ApexClass' : 'ApexTrigger'
      );
      if (i <= TOTAL_RELATED_LOG_ENTRIES) {
        logEntry.RecordId__c = TARGET_RECORD_ID;
      }
      LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

      logEntries.add(logEntry);
    }
    insert logEntries;

    // Create some tags
    List<LoggerTag__c> tags = new List<LoggerTag__c>{
      new LoggerTag__c(UniqueId__c = 'TestTag1'),
      new LoggerTag__c(UniqueId__c = 'TestTag2')
    };
    insert tags;

    // Create junction records for the first 3 log entries
    List<LogEntryTag__c> logEntryTags = new List<LogEntryTag__c>();
    for (Integer i = 0; i < 3; i++) {
      logEntryTags.add(new LogEntryTag__c(LogEntry__c = logEntries[i].Id, Tag__c = tags[0].Id));
    }
    insert logEntryTags;
  }

  @IsTest
  static void it_should_return_matching_logEntryQueryResult_when_no_search_term_provided() {
    String fieldSetName = getFieldSetName();
    Integer rowLimit = 10;
    String sortByFieldName = 'Name';
    String sortDirection = 'ASC';
    String searchTerm = null;
    List<LogEntry__c> matchingLogEntries = [SELECT Id FROM LogEntry__c WHERE RecordId__c = :TARGET_RECORD_ID];

    // TODO revisit how SOSL is tested - having to use setFixedSearchResults() means we're not really truly testing
    // that the SOSL search query is working (other than confirming that the query string can be executed successfully),
    // the test will just return the records specified
    System.Test.setFixedSearchResults(new List<Id>(new Map<Id, SObject>(matchingLogEntries).keySet()));
    RelatedLogEntriesController.LogEntryQueryResult result = RelatedLogEntriesController.getQueryResult(
      TARGET_RECORD_ID,
      fieldSetName,
      rowLimit,
      sortByFieldName,
      sortDirection,
      searchTerm,
      null
    );

    System.Assert.areEqual(fieldSetName, result.fieldSet.name);
    System.Assert.areEqual(matchingLogEntries.size(), result.records.size());
    System.Assert.areEqual(new Map<Id, SObject>(matchingLogEntries).keySet(), new Map<Id, SObject>(result.records).keySet());
  }

  @IsTest
  static void it_should_return_matching_logEntryQueryResult_when_search_term_provided() {
    String fieldSetName = getFieldSetName();
    Integer rowLimit = 10;
    String sortByFieldName = 'Name';
    String sortDirection = 'ASC';
    String searchTerm = 'my searchTerm term';
    Log__c log = [SELECT Id FROM Log__c];
    LogEntry__c logEntryWithSearchTerm = new LogEntry__c(Log__c = log.Id, Message__c = searchTerm, RecordId__c = TARGET_RECORD_ID);
    insert logEntryWithSearchTerm;

    // TODO revisit how SOSL is tested - having to use setFixedSearchResults() means we're not really truly testing
    // that the SOSL search query is working (other than confirming that the query string can be executed successfully),
    // the test will just return the records specified
    System.Test.setFixedSearchResults(new List<Id>{ logEntryWithSearchTerm.Id });
    RelatedLogEntriesController.LogEntryQueryResult result = RelatedLogEntriesController.getQueryResult(
      TARGET_RECORD_ID,
      fieldSetName,
      rowLimit,
      sortByFieldName,
      sortDirection,
      searchTerm,
      null
    );

    System.Assert.areEqual(fieldSetName, result.fieldSet.name);
    System.Assert.areEqual(1, result.records.size());
    System.Assert.areEqual(logEntryWithSearchTerm.Id, result.records[0].Id);
  }

  @IsTest
  static void it_should_return_filtered_logEntryQueryResult_when_logging_level_filter_provided() {
    String fieldSetName = getFieldSetName();
    Integer rowLimit = 10;
    String sortByFieldName = 'Name';
    String sortDirection = 'ASC';
    String searchTerm = null;
    Map<String, Object> filters = new Map<String, Object>{ 'loggingLevels' => new List<String>{ 'ERROR' } };
    String filtersJson = JSON.serialize(filters);

    List<LogEntry__c> matchingLogEntries = [SELECT Id FROM LogEntry__c WHERE RecordId__c = :TARGET_RECORD_ID AND LoggingLevel__c = 'ERROR'];

    System.Test.setFixedSearchResults(new List<Id>(new Map<Id, SObject>(matchingLogEntries).keySet()));
    RelatedLogEntriesController.LogEntryQueryResult result = RelatedLogEntriesController.getQueryResult(
      TARGET_RECORD_ID,
      fieldSetName,
      rowLimit,
      sortByFieldName,
      sortDirection,
      searchTerm,
      filtersJson
    );

    System.Assert.areEqual(fieldSetName, result.fieldSet.name);
    System.Assert.areEqual(matchingLogEntries.size(), result.records.size());
  }

  @IsTest
  static void it_should_return_filtered_logEntryQueryResult_when_origin_source_metadata_type_filter_provided() {
    String fieldSetName = getFieldSetName();
    Integer rowLimit = 10;
    String sortByFieldName = 'Name';
    String sortDirection = 'ASC';
    String searchTerm = null;
    Map<String, Object> filters = new Map<String, Object>{ 'originSourceMetadataTypes' => new List<String>{ 'ApexClass' } };
    String filtersJson = JSON.serialize(filters);

    List<LogEntry__c> matchingLogEntries = [
      SELECT Id
      FROM LogEntry__c
      WHERE RecordId__c = :TARGET_RECORD_ID AND OriginSourceMetadataType__c = 'ApexClass'
    ];

    System.Test.setFixedSearchResults(new List<Id>(new Map<Id, SObject>(matchingLogEntries).keySet()));
    RelatedLogEntriesController.LogEntryQueryResult result = RelatedLogEntriesController.getQueryResult(
      TARGET_RECORD_ID,
      fieldSetName,
      rowLimit,
      sortByFieldName,
      sortDirection,
      searchTerm,
      filtersJson
    );

    System.Assert.areEqual(fieldSetName, result.fieldSet.name);
    System.Assert.areEqual(matchingLogEntries.size(), result.records.size());
  }

  @IsTest
  static void it_should_return_filtered_logEntryQueryResult_when_timestamp_filter_provided() {
    String fieldSetName = getFieldSetName();
    Integer rowLimit = 10;
    String sortByFieldName = 'Name';
    String sortDirection = 'ASC';
    String searchTerm = null;
    Datetime yesterday = System.now().addDays(-1);
    Datetime tomorrow = System.now().addDays(1);
    Map<String, Object> filters = new Map<String, Object>{
      'timestampStart' => yesterday.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),
      'timestampEnd' => tomorrow.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
    };
    String filtersJson = JSON.serialize(filters);

    List<LogEntry__c> matchingLogEntries = [
      SELECT Id
      FROM LogEntry__c
      WHERE RecordId__c = :TARGET_RECORD_ID AND Timestamp__c >= :yesterday AND Timestamp__c <= :tomorrow
    ];

    System.Test.setFixedSearchResults(new List<Id>(new Map<Id, SObject>(matchingLogEntries).keySet()));
    RelatedLogEntriesController.LogEntryQueryResult result = RelatedLogEntriesController.getQueryResult(
      TARGET_RECORD_ID,
      fieldSetName,
      rowLimit,
      sortByFieldName,
      sortDirection,
      searchTerm,
      filtersJson
    );

    System.Assert.areEqual(fieldSetName, result.fieldSet.name);
    System.Assert.isTrue(result.records.size() > 0);
  }

  @IsTest
  static void it_should_return_available_tags() {
    List<String> availableTags = RelatedLogEntriesController.getAvailableTags(TARGET_RECORD_ID);

    System.Assert.isTrue(availableTags.size() > 0, 'Expected at least one tag');
    System.Assert.areEqual('TestTag1', availableTags[0]);
  }

  @IsTest
  static void it_should_return_empty_list_when_no_tags_exist() {
    Id nonRelatedRecordId = System.UserInfo.getOrganizationId();
    List<String> availableTags = RelatedLogEntriesController.getAvailableTags(nonRelatedRecordId);

    System.Assert.areEqual(0, availableTags.size(), 'Expected no tags for unrelated record');
  }

  @IsTest
  static void it_should_return_current_username() {
    String currentUsername = RelatedLogEntriesController.getCurrentUsername();

    System.Assert.isNotNull(currentUsername, 'Expected current username to not be null');
    System.Assert.areEqual(System.UserInfo.getUserName(), currentUsername);
  }

  static String getFieldSetName() {
    Schema.FieldSet fieldSet = Schema.SObjectType.LogEntry__c.fieldSets.getMap().values().get(0);
    String fieldSetNamespacePrefix = String.isBlank(fieldSet.getNamespace()) ? '' : fieldSet.getNamespace() + '__';
    String fieldSetName = fieldSetNamespacePrefix + fieldSet.getName();

    return fieldSetName;
  }
}
