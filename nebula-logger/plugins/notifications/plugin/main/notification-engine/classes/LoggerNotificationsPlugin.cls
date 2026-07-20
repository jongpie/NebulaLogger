//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Nebula Logger plugin entry point for the notifications system. Registered via
 *              `LoggerPlugin.LoggerNotifications` CMDT. Fires on AFTER_INSERT for LogEntry__c,
 *              Log__c, LoggerScenario__c, LogEntryTag__c, and LoggerTag__c; each rule opts into
 *              one source SObject type via its SourceSObjectType__c value. Delegates the actual
 *              evaluation and dispatch work to `LoggerNotifier`.
 *
 *              Also implements `LoggerPlugin.Purgeable` so `LogBatchPurger` picks up
 *              `LoggerNotificationMatch__c` and `LoggerNotificationDelivery__c` and cleans up rows
 *              older than their `RetentionDate__c`. Registration is wired via
 *              `LoggerPlugin__mdt.BatchPurgeRegistrarApexClass__c` on the plugin's CMDT
 *              record; the purger's constructor instantiates this class and calls
 *              `getPurgeRegistrations()` at batch start.
 */
public without sharing class LoggerNotificationsPlugin implements LoggerPlugin.Triggerable, LoggerPlugin.Purgeable {
  private static final Set<Schema.SObjectType> SUPPORTED_SOURCE_TYPES = new Set<Schema.SObjectType>{
    Schema.LogEntry__c.SObjectType,
    Schema.LogEntryTag__c.SObjectType,
    Schema.Log__c.SObjectType,
    Schema.LoggerScenario__c.SObjectType,
    Schema.LoggerTag__c.SObjectType
  };

  @TestVisible
  private static LoggerNotifier notifierOverride;

  /**
   * @description Handles the plugin trigger callback from `LoggerSObjectHandler`.
   * @param configuration The `LoggerPlugin__mdt` record that registered this plugin. Unused today but required by the interface.
   * @param input The trigger context provided by the core framework.
   */
  public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input) {
    if (input == null || input.triggerNew == null || input.triggerNew.isEmpty()) {
      return;
    }
    // TODO revisit this, we need to support after update too for rollup fields to be recalculated
    // (without sending duplicate notifications in the same transaction for the same source record)
    if (input.triggerOperationType != System.TriggerOperation.AFTER_INSERT) {
      return;
    }
    if (SUPPORTED_SOURCE_TYPES.contains(input.sobjectType) == false) {
      return;
    }
    LoggerNotifier notifier = notifierOverride != null ? notifierOverride : new LoggerNotifier();
    notifier.sendNotifications(input.sobjectType, input.triggerNew);
  }

  /**
   * @description Called by `LogBatchPurger` at batch start when `LoggerPlugin.LoggerNotifications`
   *              CMDT record has `BatchPurgeRegistrarApexClass__c` = `LoggerNotificationsPlugin`.
   *              Delivery is a master-detail child of Match, so delivery is placed first in the
   *              returned list - the purger preserves list order so child rows are deleted before
   *              the purger tries to delete their parent match rows.
   */
  public List<LoggerPurgeRegistration> getPurgeRegistrations() {
    // Sort by the master-detail parent (and, for deliveries, by the intermediate parent chain) so
    // each batch clusters child rows under their parent. Deleting a batch's worth of rows in
    // parent-clustered order takes one row-level lock per parent instead of interleaving locks
    // across many parents, which cuts parallel-batch lock contention on high-volume rules.
    // Sorting by RetentionDate__c would only affect which rows die first within a run - it does
    // nothing to reduce lock scope, so it's not the right choice here.
    return new List<LoggerPurgeRegistration>{
      new LoggerPurgeRegistration(
        Schema.LoggerNotificationDelivery__c.SObjectType,
        Schema.LoggerNotificationDelivery__c.RetentionDate__c,
        new List<Schema.SObjectField>{
          Schema.LoggerNotificationDelivery__c.LoggerNotificationMatch__c,
          Schema.LoggerNotificationDelivery__c.LoggerNotificationRecipient__c
        }
      ),
      new LoggerPurgeRegistration(
        Schema.LoggerNotificationMatch__c.SObjectType,
        Schema.LoggerNotificationMatch__c.RetentionDate__c,
        Schema.LoggerNotificationMatch__c.LoggerNotificationRule__c
      )
    };
  }
}
