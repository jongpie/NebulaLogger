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
 *              evaluation and dispatch work to `LoggerNotificationProcessor`.
 *
 *              Also implements `LoggerPlugin.Purgeable` so `LogBatchPurger` picks up
 *              `LoggerNotificationMatch__c` and `LoggerNotificationDelivery__c` and cleans up records
 *              older than their `RetentionDate__c`. Registration is wired via
 *              `LoggerPlugin__mdt.BatchPurgeRegistrarApexClass__c` on the plugin's CMDT
 *              record; the purger's constructor instantiates this class and calls
 *              `getPurgeRegistrations()` at batch start.
 */
public without sharing class LoggerNotificationsPlugin implements LoggerPlugin.Triggerable, LoggerPlugin.Purgeable {
  // IDs of records seen at AFTER_INSERT earlier in this transaction. AFTER_UPDATE only re-evaluates
  // records in this set so that admin edits (Log__c.Status__c, Log__c.Comments__c, etc.) in a later
  // transaction don't refire notifications for records that already matched at insert time. Salesforce
  // IDs are globally unique, so a single flat Set<Id> is sufficient (no per-SObjectType bucketing
  // needed). The set is cleared automatically when the transaction ends.
  private static final Set<Id> INSERTED_RECORD_IDS = new Set<Id>();
  private static final Set<Schema.SObjectType> SUPPORTED_SOURCE_TYPES = new Set<Schema.SObjectType>{
    Schema.LogEntry__c.SObjectType,
    Schema.LogEntryTag__c.SObjectType,
    Schema.Log__c.SObjectType,
    Schema.LoggerScenario__c.SObjectType,
    Schema.LoggerTag__c.SObjectType
  };
  private static final Set<System.TriggerOperation> SUPPORTED_TRIGGER_OPERATIONS = new Set<System.TriggerOperation>{
    System.TriggerOperation.AFTER_INSERT,
    System.TriggerOperation.AFTER_UPDATE
  };

  @TestVisible
  private static LoggerNotificationProcessor notifierOverride;

  /**
   * @description Handles the plugin trigger callback from `LoggerSObjectHandler`.
   * @param configuration The `LoggerPlugin__mdt` record that registered this plugin. Unused today but required by the interface.
   * @param input The trigger request provided by the core framework.
   */
  public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input) {
    if (input == null || input.triggerNew == null || input.triggerNew.isEmpty() || SUPPORTED_SOURCE_TYPES.contains(input.sobjectType) == false) {
      return;
    }

    // AFTER_UPDATE is accepted so that rollup fields (like Log__c.TotalERRORLogEntries__c, Log__c.TotalLogEntries__c,
    // etc.) - which Salesforce recalculates when child LogEntry__c records insert - can drive rule
    // matching. The rollup value on Trigger.new for AFTER_UPDATE reflects the post-recalculation value,
    // so no re-query is needed. Per-(rule, record) deduplication in `LoggerNotificationProcessor` keeps
    // the AFTER_INSERT + AFTER_UPDATE pair from producing duplicate notifications for the same record.
    if (SUPPORTED_TRIGGER_OPERATIONS.contains(input.triggerOperationType) == false) {
      return;
    }

    List<SObject> recordsToProcess = input.triggerNew;
    if (input.triggerOperationType == System.TriggerOperation.AFTER_INSERT) {
      // Track every incoming Id so a same-transaction AFTER_UPDATE for these records (e.g. Salesforce's
      // rollup-recalculation update on Log__c after child LogEntry__c inserts) is allowed through.
      for (SObject record : input.triggerNew) {
        INSERTED_RECORD_IDS.add(record.Id);
      }
    } else {
      // AFTER_UPDATE: only re-evaluate records that were inserted earlier in this transaction. This
      // scopes the AFTER_UPDATE handling to Salesforce's automatic rollup-recalc pass and deliberately
      // ignores admin edits (Status__c, Comments__c, etc.) that arrive in a separate transaction with
      // an empty `INSERTED_RECORD_IDS` set.
      //
      // TODO: this approach misses one scenario - it's possible that LogEntry__c records for the same
      // Log__c _could_ be inserted in separate transactions - Log__c and LogEntry__c are normalized
      // data from LogEntryEvent__e, and the platform itself (the event bus) manages chunking & processing
      // platform event records. So LogEntryEvent__e records from 1 transaction could get processed by the
      // event bus in multiple separate async transactions.
      //
      // And if the Log__c ON_INSERT doesn't match the rule's filter, but later it _does_ matches the rule's filter
      // in the subsequent transactions (after LogEntry__c records inserted async --> rollup fields in rules update
      // to match filter), then this approach would _not_ send out a notification.
      //

      // One option to possibly close that gap would be to ALSO track child-record Ids inserted this transaction
      // (e.g. LogEntry__c inserts) and, at AFTER_UPDATE time on a parent SObject, cross-reference each parent ID
      // against the child records' parent-lookup values (LogEntry__c.Log__c) to detect "this update was driven by a
      // same-transaction child insert." I'm not going to worry about it for now until we see a real report of this issue.
      recordsToProcess = new List<SObject>();
      for (SObject record : input.triggerNew) {
        if (INSERTED_RECORD_IDS.contains(record.Id)) {
          recordsToProcess.add(record);
        }
      }
      if (recordsToProcess.isEmpty()) {
        return;
      }
    }

    LoggerNotificationProcessor notifier = notifierOverride ?? new LoggerNotificationProcessor();
    notifier.sendNotifications(input.sobjectType, recordsToProcess);
  }

  /**
   * @description Called by `LogBatchPurger` at batch start when `LoggerPlugin.LoggerNotifications`
   *              CMDT record has `BatchPurgeRegistrarApexClass__c` = `LoggerNotificationsPlugin`.
   *              Delivery is a master-detail child of Match, so delivery is placed first in the
   *              returned list - the purger preserves list order so child records are deleted before
   *              the purger tries to delete their parent match records.
   */
  public List<LoggerPurgeRegistration> getPurgeRegistrations() {
    LoggerPurgeRegistration deliveryPurgeRegistration = new LoggerPurgeRegistration(
      Schema.LoggerNotificationDelivery__c.SObjectType,
      Schema.LoggerNotificationDelivery__c.RetentionDate__c,
      // Order by 2 lookups - match & recipient - to try to minimize row-level locks
      new List<Schema.SObjectField>{
        Schema.LoggerNotificationDelivery__c.LoggerNotificationMatch__c,
        Schema.LoggerNotificationDelivery__c.LoggerNotificationRecipient__c
      }
    );
    LoggerPurgeRegistration matchPurgeRegistration = new LoggerPurgeRegistration(
      Schema.LoggerNotificationMatch__c.SObjectType,
      Schema.LoggerNotificationMatch__c.RetentionDate__c,
      Schema.LoggerNotificationMatch__c.LoggerNotificationRule__c
    );
    return new List<LoggerPurgeRegistration>{ deliveryPurgeRegistration, matchPurgeRegistration };
  }
}
