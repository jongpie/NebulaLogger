//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions, PMD.PropertyNamingConventions')
@IsTest
private class LogEntryArchiveController_Tests {
    private static final String FAKE_TRANSACTION_ID = '1234';

    @IsTest
    static void it_returns_a_list_of_log_entry_archives() {
        List<LogEntryArchive__b> expectedLogEntryArchives = createLogEntryArchive(5);
        LogEntryArchiveController.MOCK_RECORDS.addAll(expectedLogEntryArchives);

        List<LogEntryArchive__b> returnedLogEntryArchives = LogEntryArchiveController.getLogEntryArchives();

        System.assertNotEquals(0, returnedLogEntryArchives.size(), 'Records should have been returned');
        System.assertEquals(
            JSON.serialize(expectedLogEntryArchives),
            JSON.serialize(returnedLogEntryArchives),
            'Returned records should match the expected records'
        );
    }

    private static List<LogEntryArchive__b> createLogEntryArchive(Integer numberOfRecordsToCreate) {
        List<LogEntryArchive__b> records = new List<LogEntryArchive__b>();
        for (Integer i = 0; i < numberOfRecordsToCreate; i++) {
            records.add(
                new LogEntryArchive__b(
                    Timestamp__c = System.now().addMinutes(-i),
                    LoggingLevelOrdinal__c = null,
                    TransactionId__c = null,
                    TransactionEntryNumber__c = i + 1
                )
            );
        }
        return records;
    }
}
