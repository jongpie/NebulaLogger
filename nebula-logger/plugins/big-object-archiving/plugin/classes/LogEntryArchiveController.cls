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
    @SuppressWarnings('PMD.ExcessiveParameterList')
    @AuraEnabled
    public static List<LogEntryArchive__b> getLogEntryArchives(
        Date startDate,
        Date endDate,
        Integer rowLimit,
        Integer minimumLoggingLevelOrdinal,
        String messageSearchTerm
    ) {
        // TODO Features that'd be great to able to support:
        //      1. Specify LIMIT in query via method parameter (passed from LWC via some input element). Any additional filtering (#2 below) would then be handled post-querying due to limitations with SOQL + big objects
        //      2. Support additional filtering of queried records on these fields (with a scaleable design to support easily adding/removing filters in future releases - mini QueryPredicate concept?)
        //          - logged by/username
        //          - logging level name (label)/ordinal(value)
        //          - origin type/location, message
        //          - record ID/name/type
        //          - scenario
        //          - tags
        //      3. Return additional fields in query that can be displayed in a record view form inside the LWC (via the table row action 'View')
        //      4. Figure out a way to handle `OFFSET` in or after SOQL query - goal would be to eventually add the ability to paginate or infinite scroll more records in LWC `logEntryArchives`
        //      5. Either integrate big object data with existing LWC `relatedLogEntries` LWC (new plugin type?), or make the `logEntryArchives` LWC embeddable/filterable on record pages
        //          and have the LWC filter to only show archive records with the matching recordId value in `LogEntryArchive__b.RecordId__c`
        //      6. Long-term, an option in the LWC `logEntryArchives` datatable to "restore" a set of `LogEntryArchive__b` records into `Log__c`, `LogEntry__c` and `LogEntryTag__c`
        //      7. See if there's any reasonable way to group related `LogEntryArchive__b` records in LWC `logEntryArchives`, based on `LogEntryArchive__b.TransactionId__c`

        List<LogEntryArchive__b> logEntryArchives = [
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
            WITH SECURITY_ENFORCED
            ORDER BY Timestamp__c DESC, TransactionId__c ASC, TransactionEntryNumber__c ASC
            // Since additional filtering is applied below (outside of the query), so query as many rows
            // as possible to maximize the possible matches from post-query filtering
            LIMIT :Limits.getLimitQueryRows()
        ];

        // In a test context, creating Big Object data will actually, truly create the data - it's not isolated
        // when running in a test context. That makes testing trickier, so mock records are injected here.
        if (System.Test.isRunningTest() == true) {
            logEntryArchives.clear();
            logEntryArchives.addAll(MOCK_RECORDS);
        }

        // Big Objects have very, very limited support for SOQL filtering, so additional filtering is applied after querying
        List<LogEntryArchive__b> matchingLogEntryArchives = new List<LogEntryArchive__b>();
        for (LogEntryArchive__b logEntryArchive : logEntryArchives) {
            if (matchesFilterCriteria(logEntryArchive, minimumLoggingLevelOrdinal, messageSearchTerm)) {
                matchingLogEntryArchives.add(logEntryArchive);
            }

            if (matchingLogEntryArchives.size() == rowLimit) {
                break;
            }
        }

        return matchingLogEntryArchives;
    }

    private static Boolean matchesFilterCriteria(LogEntryArchive__b logEntryArchive, Integer minimumLoggingLevelOrdinal, String messageSearchTerm) {
        Boolean matchesLoggingLevelOrdinal = minimumLoggingLevelOrdinal == null || logEntryArchive.LoggingLevelOrdinal__c >= minimumLoggingLevelOrdinal;
        Boolean matchesSearchTerm = String.isBlank(messageSearchTerm) == true || logEntryArchive.Message__c?.containsIgnoreCase(messageSearchTerm) == true;
        if (matchesLoggingLevelOrdinal == true && matchesSearchTerm == true) {
            return true;
        }
        return false;
    }
}
