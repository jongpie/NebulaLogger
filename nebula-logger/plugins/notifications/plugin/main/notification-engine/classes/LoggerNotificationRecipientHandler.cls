//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Handles trigger events for the `LoggerNotificationRecipient__c` object. Validates each
 *              recipient's `ConfigurationJson__c` by delegating to the notifier's
 *              `LoggerNotifier.validateConfiguration(...)` method, which by default runs the framework
 *              checks in `LoggerNotifierConfiguration.validate(...)` (malformed JSON, wrong top-level
 *              shape, `sourceFields` entries missing / with stale field paths). Notifier subclasses can
 *              override that method to add their own domain-specific checks. Any errors are surfaced as
 *              record-level `addError` calls so admins cannot persist a config the runtime would refuse
 *              to consume.
 */
public without sharing class LoggerNotificationRecipientHandler extends LoggerSObjectHandler {
  /**
   * @description Returns the SObject Type that the handler is responsible for processing
   * @return      The instance of `SObjectType`
   */
  public override Schema.SObjectType getSObjectType() {
    return Schema.LoggerNotificationRecipient__c.SObjectType;
  }

  protected override void executeBeforeInsert(List<SObject> triggerNew) {
    this.validateConfigurationJson(triggerNew, null);
  }

  protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
    this.validateConfigurationJson(triggerNewMap.values(), triggerOldMap);
  }

  private void validateConfigurationJson(List<LoggerNotificationRecipient__c> recipients, Map<Id, LoggerNotificationRecipient__c> triggerOldMap) {
    List<LoggerNotificationRecipient__c> recipientsToValidate = new List<LoggerNotificationRecipient__c>();
    Set<Id> ruleIds = new Set<Id>();
    Set<Id> serviceIds = new Set<Id>();
    for (LoggerNotificationRecipient__c recipient : recipients) {
      if (String.isBlank(recipient.ConfigurationJson__c)) {
        continue;
      }

      if (triggerOldMap?.get(recipient.Id)?.ConfigurationJson__c == recipient.ConfigurationJson__c) {
        continue;
      }

      recipientsToValidate.add(recipient);
      ruleIds.add(recipient.LoggerNotificationRule__c);
      serviceIds.add(recipient.LoggerNotificationService__c);
    }

    if (recipientsToValidate.isEmpty()) {
      return;
    }

    Map<Id, LoggerNotificationRule__c> rulesById = new Map<Id, LoggerNotificationRule__c>(
      [SELECT Id, SourceSObjectType__c FROM LoggerNotificationRule__c WHERE Id IN :ruleIds WITH SYSTEM_MODE]
    );
    Map<Id, LoggerNotificationService__c> servicesById = new Map<Id, LoggerNotificationService__c>(
      [SELECT Id, NotifierApexClassName__c FROM LoggerNotificationService__c WHERE Id IN :serviceIds WITH SYSTEM_MODE]
    );
    for (LoggerNotificationRecipient__c recipient : recipientsToValidate) {
      LoggerNotificationRule__c rule = rulesById.get(recipient.LoggerNotificationRule__c);
      LoggerNotificationService__c service = servicesById.get(recipient.LoggerNotificationService__c);

      Schema.SObjectType sourceSObjectType = rule == null ? null : LoggerNotificationRuleHandler.resolveSObjectType(rule.SourceSObjectType__c);
      LoggerNotifier notifier = instantiateNotifier(service?.NotifierApexClassName__c);
      List<String> errors = notifier == null
        ? LoggerNotifierConfiguration.validate(recipient.ConfigurationJson__c, sourceSObjectType)
        : notifier.validateConfiguration(recipient, sourceSObjectType);

      if (errors != null && errors.isEmpty() == false) {
        recipient.addError(String.join(errors, '\n'));
      }
    }
  }

  /**
   * @description Resolves the recipient's notifier class name to a `LoggerNotifier` instance so
   *              subclass-specific overrides of `validateConfiguration` get a chance to run. Falls back to
   *              null when the class name is missing / unresolvable / does not extend `LoggerNotifier` -
   *              callers then use the framework-level validator directly, matching the notifier runtime's
   *              own fail-open behavior on the same conditions.
   */
  private static LoggerNotifier instantiateNotifier(String notifierApexClassName) {
    if (String.isBlank(notifierApexClassName)) {
      return null;
    }
    System.Type notifierType = System.Type.forName(notifierApexClassName);
    if (notifierType == null) {
      return null;
    }
    Object instance;
    try {
      instance = notifierType.newInstance();
    } catch (Exception ex) {
      return null;
    }
    return instance instanceof LoggerNotifier ? (LoggerNotifier) instance : null;
  }
}
