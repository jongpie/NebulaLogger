//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for lwc `logBatchPurge`, used to provide metrics of `Log__c`, `LogEntry__c`,
 *              `LogEntryTag__c` records to purge and allow user to manually run `LogBatchPurger` from the UI.
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ExcessivePublicCount')
public with sharing class LogBatchPurgeController {
  @TestVisible
  private static final String CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION = 'CanExecuteLogBatchPurger';
  @TestVisible
  private static final String CUSTOM_LOG_PURGE_ACTION_PREFIX = 'CustomLogPurgeAction';
  @TestVisible
  private static final String DELETE_LOG_PURGE_ACTION = 'Delete';
  @TestVisible
  private static final String LOG_PURGE_ACTION_ALIAS = 'LogPurgeAction__c';
  @TestVisible
  private static final String RECORD_COUNT_ALIAS = 'recordCount';
  private static final Set<String> SUPPORTED_DATE_FILTER_OPTIONS = new Set<String>{ 'TODAY', 'THIS_WEEK', 'THIS_MONTH' };

  /**
   * @description Returns true if the current user has delete permission on the `Log__c` object,
   *              or if the user is assigned the `CanExecuteLogBatchPurger` custom permission.
   * @return true if the current user is permitted to run `LogBatchPurger`.
   */
  @AuraEnabled
  public static Boolean canUserRunLogBatchPurger() {
    return Schema.Log__c.SObjectType.getDescribe().isDeletable() || System.FeatureManagement.checkPermission(CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION);
  }

  /**
   * @description Returns counts of `Log__c`, `LogEntry__c`, and `LogEntryTag__c` records eligible for purge,
   *              grouped by `Log__c.LogPurgeAction__c`, for records whose `LogRetentionDate__c` falls within
   *              the given timeframe.
   * @param dateFilterOption A date literal used to filter on `LogRetentionDate__c`. Must be one of: `TODAY`, `THIS_WEEK`, `THIS_MONTH`.
   * @return A map keyed by object API name (`Log__c`, `LogEntry__c`, `LogEntryTag__c`), where each value is a
   *         `List<AggregateResult>` containing `LogPurgeAction__c` and `recordCount` per purge action.
   */
  @AuraEnabled
  public static Map<String, Object> getMetrics(String dateFilterOption) {
    String validatedDateFilterOption = validateDateFilterOption(dateFilterOption);
    return new Map<String, Object>{
      Schema.Log__c.SObjectType.getDescribe().getLocalName() => getLogObjectSummary(validatedDateFilterOption),
      Schema.LogEntry__c.SObjectType.getDescribe().getLocalName() => getLogEntryObjectSummary(validatedDateFilterOption),
      Schema.LogEntryTag__c.SObjectType.getDescribe().getLocalName() => getLogEntryTagObjectSummary(validatedDateFilterOption)
    };
  }

  /**
   * @description Returns the list of purge action picklist options shown in the UI: the built-in `Delete`
   *              action plus any custom actions defined via `LoggerParameter__mdt` records prefixed with
   *              `CustomLogPurgeAction`.
   * @return A sorted list of `PicklistOption` records.
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
   * @description Returns recent `Schema.AsyncApexJob` records for `LogBatchPurger`, used to display batch
   *              job history in the UI.
   * @return The 50 most recent `LogBatchPurger` async apex jobs.
   */
  @AuraEnabled
  public static List<Schema.AsyncApexJob> getBatchPurgeJobRecords() {
    String qualifiedClassName = LogBatchPurger.class.getName();
    String apexClassNamespacePrefix = qualifiedClassName.contains('.') ? qualifiedClassName.substringBefore('.') : null;
    String apexClassName = qualifiedClassName.contains('.') ? qualifiedClassName.substringAfter('.') : qualifiedClassName;
    // TODO move to a selector class
    return [
      SELECT Id, JobType, JobItemsProcessed, MethodName, NumberOfErrors, Status, CreatedDate, CreatedBy.Name
      FROM AsyncApexJob
      WHERE
        JobType IN ('ScheduledApex', 'BatchApex', 'BatchApexWorker')
        AND ApexClass.NamespacePrefix = :apexClassNamespacePrefix
        AND ApexClass.Name = :apexClassName
      ORDER BY CreatedDate DESC
      LIMIT 50
    ];
  }

  /**
   * @description Executes `LogBatchPurger` with the configured default batch size.
   * @return The ID of the queued `Schema.AsyncApexJob`.
   */
  @AuraEnabled
  public static String runBatchPurge() {
    return System.Database.executeBatch(new LogBatchPurger(), LogBatchPurger.getDefaultBatchSize());
  }

  @TestVisible
  private static List<AggregateResult> getLogObjectSummary(String dateFilterOption) {
    return System.Database.query(
      'SELECT LogPurgeAction__c LogPurgeAction__c, COUNT(Id) recordCount FROM Log__c WHERE LogRetentionDate__c = ' +
        validateDateFilterOption(dateFilterOption) +
        ' GROUP BY LogPurgeAction__c'
    );
  }

  @TestVisible
  private static List<AggregateResult> getLogEntryObjectSummary(String dateFilterOption) {
    return System.Database.query(
      'SELECT Log__r.LogPurgeAction__c LogPurgeAction__c, COUNT(Id) recordCount FROM LogEntry__c WHERE Log__r.LogRetentionDate__c = ' +
        validateDateFilterOption(dateFilterOption) +
        ' GROUP BY Log__r.LogPurgeAction__c'
    );
  }

  @TestVisible
  private static List<AggregateResult> getLogEntryTagObjectSummary(String dateFilterOption) {
    return System.Database.query(
      'SELECT LogEntry__r.Log__r.LogPurgeAction__c LogPurgeAction__c, COUNT(Id) recordCount FROM LogEntryTag__c WHERE LogEntry__r.Log__r.LogRetentionDate__c = ' +
        validateDateFilterOption(dateFilterOption) +
        ' GROUP BY LogEntry__r.Log__r.LogPurgeAction__c'
    );
  }

  // The dateFilterOption is concatenated directly into a SOQL date literal,
  // so it must be validated against an allowlist to prevent SOQL injection.
  private static String validateDateFilterOption(String dateFilterOption) {
    if (SUPPORTED_DATE_FILTER_OPTIONS.contains(dateFilterOption) == false) {
      throw new System.IllegalArgumentException('Unsupported dateFilterOption: ' + dateFilterOption);
    }
    return dateFilterOption;
  }

  /**
   * @description Inner class for returning all custom `List<PicklistOption>` in a single Apex method call
   */
  public class PicklistOption {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String value;
  }
}
