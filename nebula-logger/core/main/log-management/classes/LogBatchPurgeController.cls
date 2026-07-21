//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for lwc `logBatchPurge`, used to provide metrics of `Log__c`, `LogEntry__c`,
 *              `LogEntryTag__c`, and any plugin-registered SObject types to purge, and to let a user manually
 *              run `LogBatchPurger` from the UI.
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount')
public with sharing class LogBatchPurgeController {
  private static final String CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION = 'CanExecuteLogBatchPurger';
  private static final String CUSTOM_LOG_PURGE_ACTION_PREFIX = 'CustomLogPurgeAction';
  private static final String DELETE_LOG_PURGE_ACTION = 'Delete';
  private static final Set<String> SUPPORTED_DATE_FILTER_OPTIONS = new Set<String>{ 'TODAY', 'THIS_WEEK', 'THIS_MONTH', 'ALL_TIME' };

  /**
   * @description Returns true if the current user has delete permission on the `Log__c` object or the
   *              `CanExecuteLogBatchPurger` custom permission is assigned.
   * @return `true` when the user can run the purge batch job from the UI.
   */
  @AuraEnabled
  public static Boolean canUserRunLogBatchPurger() {
    return Schema.Log__c.SObjectType.getDescribe().isDeletable() || System.FeatureManagement.checkPermission(CAN_EXECUTE_LOG_BATCH_PURGER_PERMISSION);
  }

  /**
   * @description Returns purge metrics for the core log objects (`Log__c`, `LogEntry__c`, `LogEntryTag__c`)
   *              and every plugin-registered SObject type. Counts are grouped by `Log__c.LogPurgeAction__c`
   *              for the core objects (traversing parent relationships for `LogEntry__c` / `LogEntryTag__c`).
   *              Plugin-registered types don't have a `LogPurgeAction__c` field, so their entries come back
   *              as a single-element list with `LogPurgeAction__c` set to `Delete` (since the batch always
   *              deletes registered rows).
   * @param dateFilterOption One of `TODAY`, `THIS_WEEK`, `THIS_MONTH`, `ALL_TIME`. Filters on
   *                         `Log__c.LogRetentionDate__c` (or the plugin-declared retention date field for
   *                         registered types) so admins see what's actually scheduled for purge, not what
   *                         happened to be created recently.
   * @return Map keyed by SObject API name. Values are `List<Map<String, Object>>` shaped like an
   *         `AggregateResult` (`{ LogPurgeAction__c, expr0 }`).
   */
  @AuraEnabled
  public static Map<String, Object> getMetrics(String dateFilterOption) {
    if (SUPPORTED_DATE_FILTER_OPTIONS.contains(dateFilterOption) == false) {
      throw new System.IllegalArgumentException('Unsupported dateFilterOption: ' + dateFilterOption);
    }
    Map<String, Object> result = new Map<String, Object>();
    result.put(Schema.Log__c.SObjectType.getDescribe().getLocalName(), getLogObjectSummary(dateFilterOption));
    result.put(Schema.LogEntry__c.SObjectType.getDescribe().getLocalName(), getLogEntryObjectSummary(dateFilterOption));
    result.put(Schema.LogEntryTag__c.SObjectType.getDescribe().getLocalName(), getLogEntryTagObjectSummary(dateFilterOption));
    for (RegisteredPurgeableSObjectType registered : getRegisteredPurgeableSObjectTypes()) {
      result.put(registered.apiName, getRegisteredSObjectSummary(registered, dateFilterOption));
    }
    return result;
  }

  /**
   * @description Returns all of the `LogPurgeAction__c` picklist options used to display the metrics table.
   * @return List of picklist options; `Delete` is always present, plus any `CustomLogPurgeAction*`
   *         `LoggerParameter__mdt` values.
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
   * @description Returns the SObject types that plugins have registered with `LogBatchPurger` via
   *              `LoggerPlugin.Purgeable` / `LoggerPlugin__mdt.BatchPurgeRegistrarApexClass__c`. The LWC uses
   *              this to render additional rows in the metrics table (one per plugin-registered SObject) and
   *              to fetch counts through `getMetrics`.
   * @return Ordered list matching the purger's own registration order (child SObjects before parent, so
   *         plugin rows in the UI match the order they'll be purged).
   */
  @AuraEnabled(cacheable=true)
  public static List<RegisteredPurgeableSObjectType> getRegisteredPurgeableSObjectTypes() {
    List<RegisteredPurgeableSObjectType> registeredTypes = new List<RegisteredPurgeableSObjectType>();
    LogBatchPurger purger = new LogBatchPurger();
    for (Schema.SObjectType sobjectType : purger.getRegisteredSObjectTypes()) {
      RegisteredPurgeableSObjectType entry = new RegisteredPurgeableSObjectType();
      Schema.DescribeSObjectResult describe = sobjectType.getDescribe();
      entry.apiName = describe.getName();
      entry.localApiName = describe.getLocalName();
      entry.label = describe.getLabel();
      entry.labelPlural = describe.getLabelPlural();
      entry.registeredQuery = purger.getRegisteredQuery(sobjectType);
      entry.registeringPluginDeveloperName = purger.getRegisteringPluginDeveloperName(sobjectType);
      registeredTypes.add(entry);
    }
    return registeredTypes;
  }

  /**
   * @description Returns the most recent `LogBatchPurger` `AsyncApexJob` records for the datatable.
   * @return Up to 50 recent jobs, newest first.
   */
  @AuraEnabled
  public static List<Schema.AsyncApexJob> getBatchPurgeJobRecords() {
    List<String> qualifiedClassNamePieces = LogBatchPurger.class.getName().split('\\.');
    String apexClassNamespacePrefix = qualifiedClassNamePieces.size() == 2 ? qualifiedClassNamePieces.get(0) : null;
    String apexClassName = qualifiedClassNamePieces.size() == 2 ? qualifiedClassNamePieces.get(1) : qualifiedClassNamePieces.get(0);
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
   * @description Executes the `LogBatchPurger` batch job with the default batch size.
   * @return `Id` of the enqueued `AsyncApexJob`, as a `String`.
   */
  @AuraEnabled
  public static String runBatchPurge() {
    return System.Database.executeBatch(new LogBatchPurger(), LogBatchPurger.getDefaultBatchSize());
  }

  private static List<AggregateResult> getLogObjectSummary(String dateFilterOption) {
    String whereClause = buildRetentionDateWhereClause('LogRetentionDate__c', dateFilterOption);
    String query = 'SELECT LogPurgeAction__c LogPurgeAction__c, COUNT(Id) FROM Log__c WHERE ' + whereClause + ' GROUP BY LogPurgeAction__c';
    return System.Database.query(query);
  }

  private static List<AggregateResult> getLogEntryObjectSummary(String dateFilterOption) {
    String whereClause = buildRetentionDateWhereClause('Log__r.LogRetentionDate__c', dateFilterOption);
    String query = 'SELECT Log__r.LogPurgeAction__c LogPurgeAction__c, COUNT(Id) FROM LogEntry__c WHERE ' + whereClause + ' GROUP BY Log__r.LogPurgeAction__c';
    return System.Database.query(query);
  }

  private static List<AggregateResult> getLogEntryTagObjectSummary(String dateFilterOption) {
    String whereClause = buildRetentionDateWhereClause('LogEntry__r.Log__r.LogRetentionDate__c', dateFilterOption);
    String query =
      'SELECT LogEntry__r.Log__r.LogPurgeAction__c LogPurgeAction__c, COUNT(Id) FROM LogEntryTag__c WHERE ' +
      whereClause +
      ' GROUP BY LogEntry__r.Log__r.LogPurgeAction__c';
    return System.Database.query(query);
  }

  private static List<Map<String, Object>> getRegisteredSObjectSummary(RegisteredPurgeableSObjectType registered, String dateFilterOption) {
    // Plugin-registered SObjects don't have a LogPurgeAction__c field, so we synthesize a single-row
    // AggregateResult-shaped payload so the LWC's rendering code stays uniform with the core rows.
    // Extract the SObject + retention field from the built query so we don't reach back into the purger
    // for it - LoggerPurgeRegistration.buildQuery() already wrote them in a known format.
    List<Map<String, Object>> summary = new List<Map<String, Object>>();
    Integer count = getRegisteredSObjectCount(registered, dateFilterOption);
    summary.add(new Map<String, Object>{ 'LogPurgeAction__c' => DELETE_LOG_PURGE_ACTION, 'expr0' => count });
    return summary;
  }

  private static Integer getRegisteredSObjectCount(RegisteredPurgeableSObjectType registered, String dateFilterOption) {
    // registeredQuery shape from LoggerPurgeRegistration.buildQuery():
    // "SELECT Id FROM <SObject> WHERE <field> <= :RETENTION_END_DATE AND <field> != NULL ORDER BY ..."
    // Parse out the SObject name and the retention field so we can build a COUNT() query with the
    // caller's date filter substituted in.
    if (String.isBlank(registered.registeredQuery)) {
      return 0;
    }
    System.Pattern queryPattern = System.Pattern.compile('(?i)FROM\\s+(\\S+)\\s+WHERE\\s+(\\S+)\\s+<=');
    System.Matcher matcher = queryPattern.matcher(registered.registeredQuery);
    if (matcher.find() == false) {
      return 0;
    }
    String sobjectName = matcher.group(1);
    String retentionField = matcher.group(2);
    String whereClause = buildRetentionDateWhereClause(retentionField, dateFilterOption);
    String countQuery = 'SELECT COUNT() FROM ' + sobjectName + ' WHERE ' + whereClause;
    try {
      return System.Database.countQuery(countQuery);
    } catch (System.QueryException ex) {
      // A plugin that registered a valid retention query but the SObject / field no longer exists at
      // count time shouldn't crash the whole metrics panel. Zero is the safe fallback; the plugin's
      // rows will just show zero in the UI.
      return 0;
    }
  }

  private static String buildRetentionDateWhereClause(String retentionFieldPath, String dateFilterOption) {
    // Retention semantics: a null retention date is the admin's way of saying "keep this row forever",
    // so it's always excluded. The date-range clause is applied against the retention date field, NOT
    // against CreatedDate (an earlier version filtered on CreatedDate, which is meaningless for a
    // "what's about to be purged" view). Date literals TODAY / THIS_WEEK / THIS_MONTH are valid on
    // Date-typed fields.
    //
    // ALL_TIME is intentionally NOT capped at `<= TODAY`. A log created today with a 30-day retention
    // date sits in the future - it would match THIS_MONTH (any day this month) but a `<= TODAY` clause
    // on ALL_TIME would exclude it, making ALL_TIME return fewer rows than THIS_MONTH, which is
    // nonsensical to admins. ALL_TIME is "every row scheduled for purge, regardless of when the
    // purge is scheduled" - only the null-retention "keep forever" opt-out is honored.
    if (dateFilterOption == 'ALL_TIME') {
      return retentionFieldPath + ' != NULL';
    }
    return retentionFieldPath + ' = ' + dateFilterOption + ' AND ' + retentionFieldPath + ' != NULL';
  }

  /**
   * @description Inner class returned by `getPurgeActionOptions`.
   */
  public class PicklistOption {
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String value;
  }

  /**
   * @description DTO returned by `getRegisteredPurgeableSObjectTypes` describing one plugin-registered
   *              SObject type included in the purge chain.
   */
  public class RegisteredPurgeableSObjectType {
    @AuraEnabled
    public String apiName;
    @AuraEnabled
    public String localApiName;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String labelPlural;
    @AuraEnabled
    public String registeredQuery;
    @AuraEnabled
    public String registeringPluginDeveloperName;
  }
}
