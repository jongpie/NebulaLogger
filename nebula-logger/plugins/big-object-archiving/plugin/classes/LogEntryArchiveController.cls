//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Controller class used by the LWC `logEntryArchives` to display `LogEntryArchive__b` data
 * @see LogEntryArchivePlugin
 * @see LogEntryArchiveBuilder
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class LogEntryArchiveController {
    @TestVisible
    private static final List<LogEntryArchive__b> MOCK_RECORDS = new List<LogEntryArchive__b>();

    /**
     * @description Returns a list of `LogEntryArchive__b` records, based on the current user's record access + an optional search term for `Message__c`
     * @param  startDate                  The initial date to check for matching `LogEntryArchive__b` records, used to filter on `LogEntryArchive__b.Timestamp__c`
     * @param  endDate                    The last date to check for matching `LogEntryArchive__b` records, used to filter on `LogEntryArchive__b.Timestamp__c`
     * @param  rowLimit                   The max number of rows to return
     * @param  minimumLoggingLevelOrdinal Optional filter for a minimal logging level ordinal, applied to the field `LoggingLevelOrdinal__c`
     * @param  messageSearchTerm          Optional filter for text contained within the field `Message__c`
     * @return                            The list of matching `LogEntryArchive__b` records
     */
    @SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList')
    @AuraEnabled
    public static List<LogEntryArchive__b> getLogEntryArchives(
        Date startDate,
        Date endDate,
        Integer rowLimit,
        Integer minimumLoggingLevelOrdinal,
        String messageSearchTerm
    ) {
        List<LogEntryArchive__b> matchingLogEntryArchives = new List<LogEntryArchive__b>();

        // Big Objects have very, very limited support for SOQL filtering, so additional filtering is applied after querying
        // Since additional filtering is applied below (outside of the query), so this query gets as many rows
        // as possible to maximize the possible matches from post-query filtering
        Integer queryLimit = System.Test.isRunningTest() ? 1 : System.Limits.getLimitQueryRows();
        for (LogEntryArchive__b logEntryArchive : [
            SELECT
                LoggedByUsername__c,
                LoggingLevel__c,
                LoggingLevelOrdinal__c,
                Message__c,
                OriginLocation__c,
                OriginType__c,
                Tags__c,
                Timestamp__c,
                TransactionEntryNumber__c,
                TransactionId__c
            FROM LogEntryArchive__b
            WHERE Timestamp__c >= :startDate AND Timestamp__c <= :endDate.addDays(1)
            ORDER BY Timestamp__c DESC, TransactionId__c ASC, TransactionEntryNumber__c DESC
            LIMIT :queryLimit
        ]) {
            addMatches(matchingLogEntryArchives, logEntryArchive, minimumLoggingLevelOrdinal, messageSearchTerm, rowLimit);
        }

        // In a test context, creating Big Object data will actually, truly create the data - it's not isolated
        // from the org's data. That makes testing trickier, so mock records are injected here.
        if (System.Test.isRunningTest()) {
            matchingLogEntryArchives.clear();
            for (LogEntryArchive__b mockLogEntryArchive : MOCK_RECORDS) {
                addMatches(matchingLogEntryArchives, mockLogEntryArchive, minimumLoggingLevelOrdinal, messageSearchTerm, rowLimit);
            }
        }

        return matchingLogEntryArchives;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void addMatches(
        List<LogEntryArchive__b> matchingLogEntryArchives,
        LogEntryArchive__b potentialMatchingArchive,
        Integer minimumLoggingLevelOrdinal,
        String messageSearchTerm,
        Integer rowLimit
    ) {
        if (matchingLogEntryArchives.size() == rowLimit) {
            return;
        }

        if (matchesFilterCriteria(potentialMatchingArchive, minimumLoggingLevelOrdinal, messageSearchTerm)) {
            matchingLogEntryArchives.add(potentialMatchingArchive);
        }
    }

    private static Boolean matchesFilterCriteria(LogEntryArchive__b logEntryArchive, Integer minimumLoggingLevelOrdinal, String messageSearchTerm) {
        Boolean matchesLoggingLevelOrdinal = minimumLoggingLevelOrdinal == null || logEntryArchive.LoggingLevelOrdinal__c >= minimumLoggingLevelOrdinal;

        messageSearchTerm = messageSearchTerm == null ? '' : messageSearchTerm;
        String messageValue = logEntryArchive.Message__c == null ? '' : logEntryArchive.Message__c;
        Boolean matchesSearchTerm =
            String.isBlank(messageSearchTerm) ||
            messageValue.containsIgnoreCase(messageSearchTerm) ||
            System.Pattern.matches(messageSearchTerm, messageValue);

        return matchesLoggingLevelOrdinal && matchesSearchTerm;
    }
}
