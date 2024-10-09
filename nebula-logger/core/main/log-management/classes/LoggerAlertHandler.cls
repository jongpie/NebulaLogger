//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Handles trigger events for the `LoggerAlert__c` object
 */
public without sharing class LoggerAlertHandler extends LoggerSObjectHandler {
  /**
   * @description Returns SObject Type that the handler is responsible for processing
   * @return      The instance of `SObjectType`
   */
  public override Schema.SObjectType getSObjectType() {
    return Schema.LoggerAlert__c.SObjectType;
  }

  protected override void executeBeforeInsert(List<SObject> triggerNew) {
    List<LoggerAlert__c> loggerAlerts = (List<LoggerAlert__c>) triggerNew;

    LoggerAlertHandler.setOrganizationId(loggerAlerts);
    LoggerAlertHandler.validateFilters(loggerAlerts);
  }

  protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
    List<LoggerAlert__c> loggerAlerts = (List<LoggerAlert__c>) triggerNewMap.values();
    Map<Id, LoggerAlert__c> idToOldLoggerAlert = (Map<Id, LoggerAlert__c>) triggerOldMap;

    LoggerAlertHandler.setOrganizationId(loggerAlerts);
    LoggerAlertHandler.validateFilters(loggerAlerts, idToOldLoggerAlert);
  }

  private static Schema.SObjectType getSObjectType(String sobjectApiName) {
    switch on sobjectApiName {
      when 'LogEntryEvent__e' {
        return LogEntryEvent__e.SObjectType;
      }
      when 'LogEntry__c' {
        return LogEntry__c.SObjectType;
      }
      when 'LogEntryTag__c' {
        return LogEntryTag__c.SObjectType;
      }
      when else {
        throw new System.IllegalArgumentException('Unsupported SObject Type ' + sobjectApiName);
      }
    }
  }

  private static void setOrganizationId(List<LoggerAlert__c> loggerAlerts) {
    for (LoggerAlert__c loggerAlert : loggerAlerts) {
      loggerAlert.OriginOrganizationId__c = System.UserInfo.getOrganizationId();
    }
  }

  private static void validateFilters(List<LoggerAlert__c> loggerAlerts, Map<Id, LoggerAlert__c> loggerAlertIdToOldLoggerAlert) {
    List<LoggerAlert__c> changedLoggerAlerts = new List<LoggerAlert__c>();
    for (LoggerAlert__c loggerAlert : loggerAlerts) {
      LoggerAlert__c oldLoggerAlert = loggerAlertIdToOldLoggerAlert.get(loggerAlert.Id);
      if (
        loggerAlert.SourceSObjectType__c != oldLoggerAlert.SourceSObjectType__c ||
        loggerAlert.SourceSObjectFilter__c != oldLoggerAlert.SourceSObjectFilter__c
      ) {
        changedLoggerAlerts.add(loggerAlert);
      }
    }

    LoggerAlertHandler.validateFilters(changedLoggerAlerts);
  }

  private static void validateFilters(List<LoggerAlert__c> loggerAlerts) {
    for (LoggerAlert__c loggerAlert : loggerAlerts) {
      if (String.isBlank(loggerAlert.SourceSObjectFilter__c)) {
        return;
      }

      Schema.SObjectType sourceSObjectType = getSObjectType(loggerAlert.SourceSObjectType__c);
      System.Formula.builder()
        .withFormula(loggerAlert.SourceSObjectFilter__c)
        .withReturnType(FormulaEval.FormulaReturnType.Boolean)
        .withType(sourceSObjectType)
        .build();
    }
  }
}
