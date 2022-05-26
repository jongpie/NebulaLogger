//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexCRUDViolation, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount')
public with sharing class BatchPurgeController {

    @TestVisible
    private static final String CUSTOM_LOG_PURGE_ACTION_PREFIX = 'CustomLogPurgeAction';
    @TestVisible
    private static final String DELETE_LOG_PURGE_ACTION = 'Delete';

    private static final Integer PURGE_BATCH_SIZE=2000;
    
    @TestVisible
    static final String  CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION='CanExecuteLogBatchPurger';

    public class PicklistOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
    }

    @TestVisible
    private static List<AggregateResult>  getLogObjectSummary(String dateFilterOption){
        
        String query='select LogPurgeAction__c,count(id) from Log__c where CreatedDate='+dateFilterOption+
                        ' group by LogPurgeAction__c';
        return Database.query(String.escapeSingleQuotes(query));
    }

    @TestVisible
    private static List<AggregateResult>  getLogEntryObjectSummary(String dateFilterOption){
        
        String query='select Log__r.LogPurgeAction__c,count(id) from LogEntry__c where CreatedDate='+dateFilterOption+
                        ' group by Log__r.LogPurgeAction__c';
        return Database.query(String.escapeSingleQuotes(query));
    }

    @TestVisible
    private static List<AggregateResult>  getLogEntryTagObjectSummary(String dateFilterOption){
        
        String query='select LogEntry__r.Log__r.LogPurgeAction__c,count(id) from LogEntryTag__c where CreatedDate='+dateFilterOption+
                        ' group by LogEntry__r.Log__r.LogPurgeAction__c';
        return Database.query(String.escapeSingleQuotes(query));
    }

    @AuraEnabled
    public static Map<String,Object> getMetrics(String dateFilterOption){
        try {
            Map<String,Object> result=new Map<String,Object>();
            result.put('Log__c',getLogObjectSummary(dateFilterOption));
            result.put('LogEntry__c',getLogEntryObjectSummary(dateFilterOption));
            result.put('LogEntryTag__c',getLogEntryTagObjectSummary(dateFilterOption));
            return result;
        } catch (Exception ex) {
            throw createAuraHandledException(ex);
        }
    }
    
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

    @AuraEnabled
    public static List<AsyncApexJob> getPurgeBatchJobRecords(){
        try {
            List<AsyncApexJob> scheduledJobs = [
            SELECT Id,JobType,JobItemsProcessed,MethodName,NumberOfErrors,Status,
            createdDate,createdBy.name
            FROM AsyncApexJob  
            WHERE jobType in ('ScheduledApex','BatchApex','BatchApexWorker')
            AND ApexClass.Name = :LogBatchPurger.class.getName()
            ORDER BY  createdDate DESC ];
            return scheduledJobs;

        } catch (Exception ex) {
            throw createAuraHandledException(ex);
        }
    }

    @AuraEnabled
    public static boolean canUserRunLogBatchPurger(){
        return FeatureManagement.checkPermission(CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION)==true;
    }

    @AuraEnabled
    public static String runPurgeBatch(){
        try {
        String jobId=Database.executeBatch(new LogBatchPurger(), PURGE_BATCH_SIZE);
        return jobId;    
        } catch (Exception ex) {
            throw createAuraHandledException(ex);
        }
    }

     private static AuraHandledException createAuraHandledException(Exception ex) {
        AuraHandledException auraHandledException = new AuraHandledException(ex.getMessage());
        auraHandledException.setMessage(ex.getMessage());
        return auraHandledException;
    }

}