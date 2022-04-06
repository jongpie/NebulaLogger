//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Controller class used by the LWC `logEntryArchives` to display `LogEntryArchive__b` data
 * @see LogEntryArchivePlugin
 * @see LogEntryEventBuilder
 */
public with sharing class LogEntryArchiveController {
    @TestVisible
    private static final List<LogEntryArchive__b> MOCK_RECORDS = new List<LogEntryArchive__b>();

    /**
     * @description Returns a list of `LogEntryArchive__b` records, based on the current user's record access + an optional search term for `Message__c`
     * @return   The list of matching `LogEntryArchive__b` records
     */
    @AuraEnabled
    public static List<LogEntryArchive__b> getLogEntryArchives(Integer minimumLoggingLevelOrdinal, String messageSearchTerm) {
        System.debug('minimumLoggingLevelOrdinal==' + minimumLoggingLevelOrdinal);
        System.debug('messageSearchTerm==' + messageSearchTerm);
        List<LogEntryArchive__b> logEntryArchives = [
            SELECT
                LoggedByUsername__c,
                LoggingLevel__c,
                LoggingLevelOrdinal__c,
                Message__c,
                OriginLocation__c,
                OriginType__c,
                Timestamp__c,
                TransactionEntryNumber__c,
                TransactionId__c
            FROM LogEntryArchive__b
            WITH SECURITY_ENFORCED
            ORDER BY Timestamp__c DESC, LoggingLevelOrdinal__c DESC, TransactionId__c ASC, TransactionEntryNumber__c ASC
            LIMIT 200
        ];

        if (System.Test.isRunningTest() == true) {
            logEntryArchives.clear();
            logEntryArchives.addAll(MOCK_RECORDS);
        }

        // Big Objects have very, very limited support for SOQL filtering, so filtering is applied after querying
        List<LogEntryArchive__b> matchingLogEntryArchives = new List<LogEntryArchive__b>();
        for (LogEntryArchive__b logEntryArchive : logEntryArchives) {
            Boolean matchesLoggingLevelOrdinal = minimumLoggingLevelOrdinal == null || logEntryArchive.LoggingLevelOrdinal__c >= minimumLoggingLevelOrdinal;
            Boolean matchesSearchTerm = String.isBlank(messageSearchTerm) == true || logEntryArchive.Message__c?.contains(messageSearchTerm) == true;
            if (matchesLoggingLevelOrdinal == true && matchesSearchTerm == true) {
                matchingLogEntryArchives.add(logEntryArchive);
            }
        }
        return matchingLogEntryArchives;
    }
}
