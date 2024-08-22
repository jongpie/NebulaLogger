//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions, PMD.PropertyNamingConventions')
@IsTest(IsParallel=true)
private class LogEntryArchiveController_Tests {
  @IsTest
  static void it_returns_subset_of_log_entry_archives_when_row_limit_met() {
    List<LogEntryArchive__b> expectedLogEntryArchives = createLogEntryArchive(5, System.LoggingLevel.DEBUG);
    LogEntryArchiveController.MOCK_RECORDS.addAll(expectedLogEntryArchives);
    Integer rowLimit = expectedLogEntryArchives.size() - 2;

    List<LogEntryArchive__b> returnedLogEntryArchives = LogEntryArchiveController.getLogEntryArchives(
      System.today().addDays(-1),
      System.today(),
      rowLimit,
      null,
      null
    );

    System.Assert.areNotEqual(0, returnedLogEntryArchives.size(), 'Records should have been returned');
    System.Assert.areEqual(rowLimit, returnedLogEntryArchives.size(), 'Returned records should match the specified row limit');
  }

  @IsTest
  static void it_returns_all_log_entry_archives_when_logging_level_and_message_search_term_are_null() {
    List<LogEntryArchive__b> expectedLogEntryArchives = createLogEntryArchive(5, System.LoggingLevel.DEBUG);
    LogEntryArchiveController.MOCK_RECORDS.addAll(expectedLogEntryArchives);

    List<LogEntryArchive__b> returnedLogEntryArchives = LogEntryArchiveController.getLogEntryArchives(
      System.today().addDays(-1),
      System.today(),
      100,
      null,
      null
    );

    System.Assert.areNotEqual(0, returnedLogEntryArchives.size(), 'Records should have been returned');
    System.Assert.areEqual(expectedLogEntryArchives.size(), returnedLogEntryArchives.size(), 'Returned records should match the expected records');
  }

  @IsTest
  static void it_returns_filtered_log_entry_archives_whenlogging_level_filter_is_specified() {
    List<LogEntryArchive__b> expectedLogEntryArchives = createLogEntryArchive(5, System.LoggingLevel.DEBUG);
    System.LoggingLevel minimumLoggingLevel = System.LoggingLevel.INFO;
    expectedLogEntryArchives.get(0).LoggingLevel__c = System.LoggingLevel.WARN.name();
    expectedLogEntryArchives.get(0).LoggingLevelOrdinal__c = System.LoggingLevel.WARN.ordinal();
    LogEntryArchiveController.MOCK_RECORDS.addAll(expectedLogEntryArchives);

    List<LogEntryArchive__b> returnedLogEntryArchives = LogEntryArchiveController.getLogEntryArchives(
      System.today().addDays(-1),
      System.today(),
      100,
      minimumLoggingLevel.ordinal(),
      null
    );

    System.Assert.areEqual(1, returnedLogEntryArchives.size(), 'Only one matching record should have been returned');
    System.Assert.isTrue(returnedLogEntryArchives.get(0).LoggingLevelOrdinal__c > minimumLoggingLevel.ordinal());
  }

  @IsTest
  static void it_returns_filtered_log_entry_archives_when_message_search_term_is_specified() {
    List<LogEntryArchive__b> expectedLogEntryArchives = createLogEntryArchive(5, System.LoggingLevel.DEBUG);
    String messageSearchTerm = 'some substring';
    expectedLogEntryArchives.get(0).Message__c = 'some extra text and ' + messageSearchTerm + ' and then also some more text, blah blah blah';
    LogEntryArchiveController.MOCK_RECORDS.addAll(expectedLogEntryArchives);

    List<LogEntryArchive__b> returnedLogEntryArchives = LogEntryArchiveController.getLogEntryArchives(
      System.today().addDays(-1),
      System.today(),
      100,
      null,
      messageSearchTerm
    );

    System.Assert.areEqual(1, returnedLogEntryArchives.size(), 'Only one matching record should have been returned');
    System.Assert.isTrue(returnedLogEntryArchives.get(0).Message__c.contains(messageSearchTerm));
  }

  private static List<LogEntryArchive__b> createLogEntryArchive(Integer numberOfRecordsToCreate, System.LoggingLevel logLevel) {
    List<LogEntryArchive__b> records = new List<LogEntryArchive__b>();
    for (Integer i = 0; i < numberOfRecordsToCreate; i++) {
      records.add(
        new LogEntryArchive__b(
          LoggingLevel__c = logLevel.name(),
          LoggingLevelOrdinal__c = logLevel.ordinal(),
          Timestamp__c = System.now().addMinutes(-i),
          TransactionId__c = null,
          TransactionEntryNumber__c = i + 1
        )
      );
    }
    return records;
  }
}
