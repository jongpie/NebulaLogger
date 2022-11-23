//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for lwc `logBatchPurge`, used to provide metrics of `Log__c`, `LogEntry__c`,
 *              `LogEntryTag__c` records to purge and allow user to manually run `LogBatchPurger` from the UI.
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount')
public with sharing class LogBatchPurgeController {
    @TestVisible
    private static final String CUSTOM_LOG_PURGE_ACTION_PREFIX = 'CustomLogPurgeAction';
    @TestVisible
    private static final String DELETE_LOG_PURGE_ACTION = 'Delete';

    private static final Integer PURGE_BATCH_SIZE = 2000;

    @TestVisible
    static final String CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION = 'CanExecuteLogBatchPurger';

    /**
     * @description Inner class for returning all custom `List<PicklistOption>` in a single Apex method call
     */
    public class PicklistOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
    }

    @TestVisible
    private static List<AggregateResult> getLogObjectSummary(String dateFilterOption) {
        String query =
            'select LogPurgeAction__c LogPurgeAction__c, count(id) from Log__c where CreatedDate=' +
            dateFilterOption +
            ' group by LogPurgeAction__c';
        return Database.query(String.escapeSingleQuotes(query));
    }

    @TestVisible
    private static List<AggregateResult> getLogEntryObjectSummary(String dateFilterOption) {
        String query =
            'select Log__r.LogPurgeAction__c LogPurgeAction__c, count(id) from LogEntry__c where CreatedDate=' +
            dateFilterOption +
            ' group by Log__r.LogPurgeAction__c';
        return Database.query(String.escapeSingleQuotes(query));
    }

    @TestVisible
    private static List<AggregateResult> getLogEntryTagObjectSummary(String dateFilterOption) {
        String query =
            'select LogEntry__r.Log__r.LogPurgeAction__c LogPurgeAction__c, count(id) from LogEntryTag__c where CreatedDate=' +
            dateFilterOption +
            ' group by LogEntry__r.Log__r.LogPurgeAction__c';
        return Database.query(String.escapeSingleQuotes(query));
    }

    /**
     * @description return a `Map<String,Object>` contains metrics for number of `Log__c`, `LogEntry__c`, `LogEntryTag__c` records to purge,
     *              for the given timeframe TODAY/ THIS_WEEK/ THIS_MONTH. The metrics is grouped by `Log__c.LogPurgeAction__c`.
     * @param dateFilterOption a Date Literal used to filter log records. Possible values are TODAY, THIS_WEEK, THIS_MONTH
     * @return The instance of `Map<String,Object>`,contains keys as `Log__c`, `LogEntry__c`, `LogEntryTag__c` and value as metrics for the corresponding object records to purge
     *         for the given timeframe TODAY/ THIS_WEEK/ THIS_MONTH. The metrics is grouped by `Log__c.LogPurgeAction__c`.
     */
    @AuraEnabled
    public static Map<String, Object> getMetrics(String dateFilterOption) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            result.put('Log__c', getLogObjectSummary(dateFilterOption));
            result.put('LogEntry__c', getLogEntryObjectSummary(dateFilterOption));
            result.put('LogEntryTag__c', getLogEntryTagObjectSummary(dateFilterOption));
            return result;
        } catch (System.Exception ex) {
            throw createAuraHandledException(ex);
        }
    }
    /**
     * @description Returns all of the PurgeAction options to display the log metrics in UI
     * @return   The instance of `List<PicklistOption>`, containing all picklist options for purge Action.
     */
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getPurgeActionOptions() {
        List<String> logPurgeActionNames = new List<String>{ DELETE_LOG_PURGE_ACTION };
        for (LoggerParameter__mdt matchingAdditionalParameter : LoggerParameter.matchOnPrefix(CUSTOM_LOG_PURGE_ACTION_PREFIX)) {
            logPurgeActionNames.add(matchingAdditionalParameter.Value__c);
        }
        logPurgeActionNames.sort();

        List<PicklistOption> picklistOptions = new List<PicklistOption>();
        for (String logPurgeActionName : logPurgeActionNames) {
            PicklistOption picklistOption = new PicklistOption();
            picklistOption.label = logPurgeActionName;
            picklistOption.value = logPurgeActionName;
            picklistOptions.add(picklistOption);
        }
        return picklistOptions;
    }

    /**
     * @description Returns `List<AsyncApexJob>` to display logBatchPurger jobs details in a Datatable.
     * @return   The instance of `List<AsyncApexJob>`, containing list of logBatchPurge jobs.
     */
    @AuraEnabled
    public static List<AsyncApexJob> getPurgeBatchJobRecords() {
        try {
            String apexClassNamespacePrefix = LogBatchPurger.class.getName().contains('.') ? LogBatchPurger.class.getName().substringBefore('.') : null;
            String apexClassName = LogBatchPurger.class.getName().contains('.')
                ? LogBatchPurger.class.getName().substringAfter('.')
                : LogBatchPurger.class.getName();
            List<AsyncApexJob> purgeBatchJobs = [
                SELECT Id, JobType, JobItemsProcessed, MethodName, NumberOfErrors, Status, CreatedDate, CreatedBy.Name
                FROM AsyncApexJob
                WHERE
                    JobType IN ('ScheduledApex', 'BatchApex', 'BatchApexWorker')
                    AND ApexClass.NamespacePrefix = :apexClassNamespacePrefix
                    AND ApexClass.Name = :apexClassName
                ORDER BY CreatedDate DESC
                LIMIT 50
            ];
            return purgeBatchJobs;
        } catch (System.Exception ex) {
            throw createAuraHandledException(ex);
        }
    }

    /**
     * @description Returns true if the current user has delete permission on the Log__c object or
     * @return true if the current user has delete permission on the Log__c object.
     */
    @AuraEnabled
    public static boolean canUserRunLogBatchPurger() {
        return Schema.Log__c.SObjectType.getDescribe().isDeletable() == true ||
            FeatureManagement.checkPermission(CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION) == true;
    }

    /**
     * @description execute the logBatchPurger batch with batch size 2000
     * @return Returns the ID of the AsyncApexJob object associated with the LogBatchPurger job as a string
     */
    @AuraEnabled
    public static String runPurgeBatch() {
        try {
            String jobId = Database.executeBatch(new LogBatchPurger(), PURGE_BATCH_SIZE);
            return jobId;
        } catch (System.Exception ex) {
            throw createAuraHandledException(ex);
        }
    }

    private static System.AuraHandledException createAuraHandledException(System.Exception ex) {
        System.AuraHandledException auraHandledException = new System.AuraHandledException(ex.getMessage());
        auraHandledException.setMessage(ex.getMessage());
        return auraHandledException;
    }
}
