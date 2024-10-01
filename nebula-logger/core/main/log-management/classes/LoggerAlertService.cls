//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Service class used for orchestrating & sending notifications for logging data,
 *              based on org-specific rules configured in `LoggerAlert__c`
 */
public without sharing class LoggerAlertService {
  private static final LoggerAlertService INSTANCE = new LoggerAlertService();

  //   private static final Map<Schema.SObjectType, List<LoggerAlert__c>> SOBJECT_TYPE_TO_ALERT_RULES {
  //     get {
  //       if (SOBJECT_TYPE_TO_ALERT_RULES == null) {
  //         // TODO use a new method in LogManagementDataSelector to query & cache LoggerAlert__c records
  //         SOBJECT_TYPE_TO_ALERT_RULES = new Map<Schema.SObjectType, List<LoggerAlert__c>>();
  //       }
  //       return SOBJECT_TYPE_TO_ALERT_RULES;
  //     }
  //     set;
  //   }
  private static final Map<String, List<LoggerAlert__c>> SOBJECT_API_NAME_TO_ALERT_RULES {
    get {
      if (SOBJECT_API_NAME_TO_ALERT_RULES == null) {
        // TODO use a new method in LogManagementDataSelector to query & cache LoggerAlert__c records
        SOBJECT_API_NAME_TO_ALERT_RULES = new Map<String, List<LoggerAlert__c>>();
        for (LoggerAlert__c alert : [
          SELECT Id, SourceSObjectType__c, SourceSObjectFilter__c, (SELECT Id, Type__c FROM LoggerAlertActions__r)
          FROM LoggerAlert__c
          WHERE IsEnabled__c = TRUE
        ]) {
          if (SOBJECT_API_NAME_TO_ALERT_RULES.containsKey(alert.SourceSObjectType__c) == false) {
            SOBJECT_API_NAME_TO_ALERT_RULES.put(alert.SourceSObjectType__c, new List<LoggerAlert__c>());
          }

          SOBJECT_API_NAME_TO_ALERT_RULES.get(alert.SourceSObjectType__c).add(alert);
        }
      }
      return SOBJECT_API_NAME_TO_ALERT_RULES;
    }
    set;
  }

  //   private final List<LoggerAlert__c> alertRules;

  public static LoggerAlertService getInstance() {
    return INSTANCE;
  }

  public void process(List<SObject> inputRecords) {
    // System.Assert.fail(inputRecords.getSObjectType().toString());
    if (SOBJECT_API_NAME_TO_ALERT_RULES.containsKey(inputRecords.getSObjectType().toString()) == false) {
      return;
    }

    List<AlertAction> actionsToExecute = new List<AlertAction>();
    for (LoggerAlert__c loggerAlert : SOBJECT_API_NAME_TO_ALERT_RULES.get(inputRecords.getSObjectType().toString())) {
      FormulaEval.FormulaInstance formulaEvaluator = System.Formula.builder()
        .withReturnType(FormulaEval.FormulaReturnType.Boolean)
        .withType(inputRecords.getSObjectType())
        .withFormula(loggerAlert.SourceSObjectFilter__c)
        .build();

      List<SObject> matchingRecords = new List<SObject>();
      for (SObject inputRecord : inputRecords) {
        Boolean matchesFilter = (Boolean) formulaEvaluator.evaluate(inputRecord);
        if (matchesFilter) {
          matchingRecords.add(inputRecord);
        }
      }

      System.debug('>>> matchingRecords found: ' + matchingRecords.size());
      for (LoggerAlertAction__c loggerAlertAction : loggerAlert.LoggerAlertActions__r) {
        AlertAction action;
        switch on loggerAlertAction.Type__c {
          when 'Email' {
            action = new EmailAlertAction();
          }
          when 'Slack' {
          }
          when 'Webhook' {
          }
        }

        System.debug('>>> action found: ' + action);
        if (action != null) {
          action.setAlert(loggerAlert);
          action.setScope(matchingRecords);
          actionsToExecute.add(action);
        }
      }
    }

    this.executeActions(actionsToExecute);
  }

  private void executeActions(List<AlertAction> actionsToExecute) {
    System.debug('>>> actions to execute: ' + actionsToExecute.size());
    for (AlertAction action : actionsToExecute) {
      action.execute();
    }
  }

  private abstract class AlertAction {
    protected LoggerAlert__c alert;
    protected List<SObject> scopeRecords;

    public void setAlert(LoggerAlert__c alert) {
      this.alert = alert;
    }

    public void setScope(List<SObject> scopeRecords) {
      this.scopeRecords = scopeRecords;
    }

    public abstract void execute();
  }

  private class EmailAlertAction extends AlertAction {
    public override void execute() {
      System.Assert.fail('TODO');
    }
  }

  private class SlackAlertAction extends AlertAction {
    public override void execute() {
      System.Assert.fail('TODO');
    }
  }

  private class WebhookAlertAction extends AlertAction {
    public override void execute() {
      System.Assert.fail('TODO');
    }
  }
}
