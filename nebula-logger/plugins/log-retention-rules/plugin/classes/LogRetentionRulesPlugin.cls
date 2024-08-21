//-----------------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                           //
// The core functionality of this plugin's code originated in https://github.com/jongpie/ApexValidationRules //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.               //
//-----------------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Optional plugin that adds the ability to create & deploy advanced, configurable rules
 *              for setting the retention date of `Log__c` records, using custom metadata types
 *              `LogRetentionRule__mdt` and `LogRetentionRuleCondition__mdt`.
 * @see LogRetentionFilter
 */
public without sharing class LogRetentionRulesPlugin implements LoggerPlugin.Triggerable {
  private static final Map<String, LogRetentionRule__mdt> RULE_NAME_TO_RULE = new Map<String, LogRetentionRule__mdt>();
  private static final Map<String, List<LogRetentionRuleCondition__mdt>> RULE_NAME_TO_CONDITIONS = new Map<String, List<LogRetentionRuleCondition__mdt>>();

  /**
   * @description Handles converting Logger's buffer of `LogEntryEvent__e` records into `LogEntryArchive__b` records
   *              for any user with the included custom save method 'BIG_OBJECT'
   * @param  configuration The instance of `LoggerPlugin__mdt` configured for this specific plugin
   * @param  input The instance of `LoggerTriggerableContext`, provided by the logging system
   */
  public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input) {
    if (input.sobjectType != Schema.LogEntry__c.SObjectType) {
      return;
    }

    this.loadConfiguredFilters();

    switch on input.triggerOperationType {
      when AFTER_INSERT {
        List<LogEntry__c> logEntries = requeryLogEntries((List<LogEntry__c>) input.triggerNew);
        this.setLogRetentionDate(logEntries);
      }
    }
  }

  private List<LogEntry__c> requeryLogEntries(List<LogEntry__c> logEntries) {
    // Requery the LogEntry__c records so the parent Log__c fields can be included/used in rules
    List<String> logEntryFieldNames = new List<String>(Schema.LogEntry__c.SObjectType.getDescribe().fields.getMap().keySet());

    List<String> logFieldNames = new List<String>(Schema.Log__c.SObjectType.getDescribe().fields.getMap().keySet());
    logFieldNames.addAll(new List<String>{ 'Owner.Name', 'Owner.Type' });
    for (String logFieldName : logFieldNames) {
      String logRelationshipPrefix = Schema.LogEntry__c.Log__c.getDescribe().getName().substringBeforeLast('__c') + '__r';
      logEntryFieldNames.add(logRelationshipPrefix + '.' + logFieldName);
    }

    String queryTemplate = 'SELECT {0} FROM {1} WHERE {2} IN :logEntries';
    List<String> queryInputs = new List<String>{
      String.join(logEntryFieldNames, ','),
      Schema.LogEntry__c.SObjectType.getDescribe().getName(),
      Schema.LogEntry__c.Id.getDescribe().getName()
    };
    String logEntryQuery = String.escapeSingleQuotes(String.format(queryTemplate, queryInputs));
    return (List<LogEntry__c>) System.Database.query(logEntryQuery);
  }

  private void setLogRetentionDate(List<LogEntry__c> logEntries) {
    Map<Id, Log__c> logIdToLog = new Map<Id, Log__c>();
    List<LogRetentionFilter.FilterResult> filterResults = this.runFilters(logEntries);
    for (LogRetentionFilter.FilterResult filterResult : filterResults) {
      if (filterResult.matchesFilter()) {
        Id logId = (Id) filterResult.getRecord().get(Schema.LogEntry__c.Log__c);
        Log__c log = logIdToLog.get(logId);
        if (log == null) {
          log = new Log__c(Id = logId);
        }

        Integer numberOfDaysToRetainLogs = Integer.valueOf(filterResult.getRule().NumberOfDaysToRetainLogs__c);
        log.LogRetentionDate__c = numberOfDaysToRetainLogs == null ? null : System.today().addDays(numberOfDaysToRetainLogs);

        logIdToLog.put(log.Id, log);
      }
    }
    update logIdToLog.values();
  }

  @SuppressWarnings('PMD.ApexCRUDViolation')
  private void loadConfiguredFilters() {
    Map<String, LogRetentionRule__mdt> queriedRulesByDeveloperName = new Map<String, LogRetentionRule__mdt>();
    Map<String, List<LogRetentionRuleCondition__mdt>> queriedConditionsByRuleDeveloperName = new Map<String, List<LogRetentionRuleCondition__mdt>>();
    for (LogRetentionRule__mdt rule : [
      SELECT
        DeveloperName,
        ConditionLogicType__c,
        CustomConditionLogic__c,
        NumberOfDaysToRetainLogs__c,
        (SELECT FieldPath__c, Operator__c, ValueType__c, Value__c FROM LogRetentionRuleConditions__r ORDER BY SortOrder__c NULLS LAST, DeveloperName)
      FROM LogRetentionRule__mdt
      WHERE IsEnabled__c = TRUE
      ORDER BY ExecutionOrder__c NULLS LAST, DeveloperName
    ]) {
      queriedRulesByDeveloperName.put(rule.DeveloperName, rule);
      queriedConditionsByRuleDeveloperName.put(rule.DeveloperName, rule.LogRetentionRuleConditions__r);

      if (System.Test.isRunningTest()) {
        queriedRulesByDeveloperName.clear();
        queriedConditionsByRuleDeveloperName.clear();
      }
      RULE_NAME_TO_RULE.putAll(queriedRulesByDeveloperName);
      RULE_NAME_TO_CONDITIONS.putAll(queriedConditionsByRuleDeveloperName);
    }
  }

  private List<LogRetentionFilter.FilterResult> runFilters(List<SObject> records) {
    List<LogRetentionFilter.FilterResult> results = new List<LogRetentionFilter.FilterResult>();
    for (SObject record : records) {
      for (String filterDeveloperName : RULE_NAME_TO_RULE.keySet()) {
        LogRetentionRule__mdt filter = RULE_NAME_TO_RULE.get(filterDeveloperName);
        List<LogRetentionRuleCondition__mdt> filterConditions = RULE_NAME_TO_CONDITIONS.get(filter.DeveloperName);
        LogRetentionFilter.FilterResult filterResult = new LogRetentionFilter(record, filter, filterConditions).getFilterResult();

        results.add(filterResult);
      }
    }
    return results;
  }

  @TestVisible
  private static void setMockRetentionRule(LogRetentionRule__mdt rule) {
    RULE_NAME_TO_RULE.put(rule.DeveloperName, rule);
  }

  @TestVisible
  private static void setMockRetentionRuleConditions(LogRetentionRule__mdt rule, List<LogRetentionRuleCondition__mdt> conditions) {
    RULE_NAME_TO_CONDITIONS.put(rule.DeveloperName, conditions);
  }
}
