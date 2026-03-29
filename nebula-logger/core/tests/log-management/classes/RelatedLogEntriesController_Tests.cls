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
      LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, Message__c = 'test ' + i);
      if (i <= TOTAL_RELATED_LOG_ENTRIES) {
        logEntry.RecordId__c = TARGET_RECORD_ID;
      }
      LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

      logEntries.add(logEntry);
    }
    insert logEntries;
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
      searchTerm
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
      searchTerm
    );

    System.Assert.areEqual(fieldSetName, result.fieldSet.name);
    System.Assert.areEqual(1, result.records.size());
    System.Assert.areEqual(logEntryWithSearchTerm.Id, result.records[0].Id);
  }

  static String getFieldSetName() {
    Schema.FieldSet fieldSet = Schema.SObjectType.LogEntry__c.fieldSets.getMap().values().get(0);
    String fieldSetNamespacePrefix = String.isBlank(fieldSet.getNamespace()) ? '' : fieldSet.getNamespace() + '__';
    String fieldSetName = fieldSetNamespacePrefix + fieldSet.getName();

    return fieldSetName;
  }
}
