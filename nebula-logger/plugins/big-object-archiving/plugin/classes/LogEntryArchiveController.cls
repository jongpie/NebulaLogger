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

    @AuraEnabled
    /**
     * @description Returns a list of `LogEntryArchive__b` records, based on the current user's record access
     * @return   The list of `LogEntryArchive__b` records
     */
    public static List<LogEntryArchive__b> getLogEntryArchives() {
        // TODO add more fields, add support for filters (based on index),
        // add 'order by' or custom sorting (index limits which fields can be used in sort within SOQL)

        // Timestamp__c DESC, LoggingLevelOrdinal__c DESC, TransactionId__c ASC, TransactionEntryNumber__c ASC
        List<LogEntryArchive__b> logEntryArchives = [
            SELECT LoggedByUsername__c, LoggingLevel__c, Message__c
            FROM LogEntryArchive__b
            WITH SECURITY_ENFORCED
            ORDER BY Timestamp__c DESC, LoggingLevelOrdinal__c DESC, TransactionId__c ASC, TransactionEntryNumber__c ASC
            LIMIT 200
        ];

        if (System.Test.isRunningTest() == true) {
            logEntryArchives.clear();
            logEntryArchives.addAll(MOCK_RECORDS);
        }

        return logEntryArchives;
    }
}
