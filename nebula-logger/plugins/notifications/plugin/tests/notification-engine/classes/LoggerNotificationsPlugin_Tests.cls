//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotificationsPlugin_Tests {
  private static final String MOCK_NOTIFIER_CLASS = MockNotifier.class.getName();
  private static final String LOG_ROLLUP_FILTER = 'TotalERRORLogEntries__c >= 1';

  private static Integer mockNotifierInvocationCount = 0;
  private static LoggerNotifierRequest mockNotifierLastRequest;

  static {
    LoggerConfigurationSelector.useMocks();
  }

  @IsTest
  static void it_should_short_circuit_when_input_is_null() {
    RecordingNotifier notifier = installRecordingNotifier();
    LoggerNotificationsPlugin plugin = new LoggerNotificationsPlugin();

    plugin.execute(new LoggerPlugin__mdt(), null);

    System.Assert.areEqual(0, notifier.invocationCount);
  }

  @IsTest
  static void it_should_short_circuit_when_triggerNew_is_null_or_empty() {
    RecordingNotifier notifier = installRecordingNotifier();
    LoggerNotificationsPlugin plugin = new LoggerNotificationsPlugin();

    plugin.execute(
      new LoggerPlugin__mdt(),
      new LoggerTriggerableContext(Schema.LogEntry__c.SObjectType, System.TriggerOperation.AFTER_INSERT, new List<SObject>())
    );

    System.Assert.areEqual(0, notifier.invocationCount);
  }

  @IsTest
  static void it_should_ignore_non_after_insert_operations() {
    RecordingNotifier notifier = installRecordingNotifier();
    LoggerNotificationsPlugin plugin = new LoggerNotificationsPlugin();
    List<SObject> records = new List<SObject>{ new LogEntry__c() };

    plugin.execute(new LoggerPlugin__mdt(), new LoggerTriggerableContext(Schema.LogEntry__c.SObjectType, System.TriggerOperation.BEFORE_INSERT, records));
    plugin.execute(new LoggerPlugin__mdt(), new LoggerTriggerableContext(Schema.LogEntry__c.SObjectType, System.TriggerOperation.BEFORE_UPDATE, records));

    System.Assert.areEqual(0, notifier.invocationCount);
  }

  @IsTest
  static void it_should_ignore_unrelated_sobject_types() {
    RecordingNotifier notifier = installRecordingNotifier();
    LoggerNotificationsPlugin plugin = new LoggerNotificationsPlugin();

    // Non-source types are never a source for this plugin - the supported set is only the
    // Nebula Logger objects (LogEntry, LogEntryTag, Log, LoggerScenario, LoggerTag).
    // LoggerNotificationRecipient__c is not a supported source SObject type - it lives inside this
    // plugin but is not one of the notification-eligible source types (rule/service/match are also excluded).
    List<LoggerNotificationRecipient__c> records = new List<LoggerNotificationRecipient__c>{ new LoggerNotificationRecipient__c() };
    plugin.execute(
      new LoggerPlugin__mdt(),
      new LoggerTriggerableContext(Schema.LoggerNotificationRecipient__c.SObjectType, System.TriggerOperation.AFTER_INSERT, records)
    );

    System.Assert.areEqual(0, notifier.invocationCount);
  }

  @IsTest
  static void it_should_delegate_logEntry_after_insert_to_the_notifier() {
    RecordingNotifier notifier = installRecordingNotifier();
    LoggerNotificationsPlugin plugin = new LoggerNotificationsPlugin();
    List<SObject> records = new List<SObject>{ new LogEntry__c(LoggingLevel__c = System.LoggingLevel.ERROR.name()) };

    plugin.execute(new LoggerPlugin__mdt(), new LoggerTriggerableContext(Schema.LogEntry__c.SObjectType, System.TriggerOperation.AFTER_INSERT, records));

    System.Assert.areEqual(1, notifier.invocationCount);
    System.Assert.areEqual(Schema.LogEntry__c.SObjectType, notifier.lastSObjectType);
    System.Assert.areEqual(records, notifier.lastRecords);
  }

  @IsTest
  static void it_should_ignore_logEntryEvent_after_insert() {
    // LogEntryEvent__e is not a supported source SObject type - platform events have no IDs, so we
    // cannot record LoggerNotificationMatch__c records against them. The plugin should silently skip.
    RecordingNotifier notifier = installRecordingNotifier();
    LoggerNotificationsPlugin plugin = new LoggerNotificationsPlugin();
    List<SObject> records = new List<SObject>{ new LogEntryEvent__e(LoggingLevel__c = System.LoggingLevel.ERROR.name()) };

    plugin.execute(new LoggerPlugin__mdt(), new LoggerTriggerableContext(Schema.LogEntryEvent__e.SObjectType, System.TriggerOperation.AFTER_INSERT, records));

    System.Assert.areEqual(0, notifier.invocationCount);
  }

  @IsTest
  static void it_should_delegate_logEntryTag_after_insert_to_the_notifier() {
    RecordingNotifier notifier = installRecordingNotifier();
    LoggerNotificationsPlugin plugin = new LoggerNotificationsPlugin();
    List<SObject> records = new List<SObject>{ new LogEntryTag__c() };

    plugin.execute(new LoggerPlugin__mdt(), new LoggerTriggerableContext(Schema.LogEntryTag__c.SObjectType, System.TriggerOperation.AFTER_INSERT, records));

    System.Assert.areEqual(1, notifier.invocationCount);
    System.Assert.areEqual(Schema.LogEntryTag__c.SObjectType, notifier.lastSObjectType);
    System.Assert.areEqual(records, notifier.lastRecords);
  }

  @IsTest
  static void it_should_delegate_log_after_insert_to_the_notifier() {
    RecordingNotifier notifier = installRecordingNotifier();
    LoggerNotificationsPlugin plugin = new LoggerNotificationsPlugin();
    List<SObject> records = new List<SObject>{ new Log__c() };

    plugin.execute(new LoggerPlugin__mdt(), new LoggerTriggerableContext(Schema.Log__c.SObjectType, System.TriggerOperation.AFTER_INSERT, records));

    System.Assert.areEqual(1, notifier.invocationCount);
    System.Assert.areEqual(Schema.Log__c.SObjectType, notifier.lastSObjectType);
    System.Assert.areEqual(records, notifier.lastRecords);
  }

  @IsTest
  static void it_should_delegate_loggerScenario_after_insert_to_the_notifier() {
    RecordingNotifier notifier = installRecordingNotifier();
    LoggerNotificationsPlugin plugin = new LoggerNotificationsPlugin();
    List<SObject> records = new List<SObject>{ new LoggerScenario__c() };

    plugin.execute(new LoggerPlugin__mdt(), new LoggerTriggerableContext(Schema.LoggerScenario__c.SObjectType, System.TriggerOperation.AFTER_INSERT, records));

    System.Assert.areEqual(1, notifier.invocationCount);
    System.Assert.areEqual(Schema.LoggerScenario__c.SObjectType, notifier.lastSObjectType);
    System.Assert.areEqual(records, notifier.lastRecords);
  }

  @IsTest
  static void it_should_delegate_loggerTag_after_insert_to_the_notifier() {
    RecordingNotifier notifier = installRecordingNotifier();
    LoggerNotificationsPlugin plugin = new LoggerNotificationsPlugin();
    List<SObject> records = new List<SObject>{ new LoggerTag__c() };

    plugin.execute(new LoggerPlugin__mdt(), new LoggerTriggerableContext(Schema.LoggerTag__c.SObjectType, System.TriggerOperation.AFTER_INSERT, records));

    System.Assert.areEqual(1, notifier.invocationCount);
    System.Assert.areEqual(Schema.LoggerTag__c.SObjectType, notifier.lastSObjectType);
    System.Assert.areEqual(records, notifier.lastRecords);
  }

  @IsTest
  static void it_should_return_purgeable_registrations_for_match_and_delivery_with_delivery_ahead_of_match() {
    // Delivery is a master-detail child of Match, so the plugin lists delivery first in its
    // returned list. The purger preserves iteration order, so this is how the plugin communicates
    // "delete delivery records before their parent match records". Each registration declares its
    // RetentionDate__c field for the cutoff comparison and clusters its records by master-detail
    // parent for ORDER BY so batches acquire one parent lock per cluster instead of interleaving
    // locks across many parents.
    List<LoggerPurgeRegistration> registrations = new LoggerNotificationsPlugin().getPurgeRegistrations();

    System.Assert.areEqual(2, registrations.size(), 'Plugin should declare exactly two purgeable SObjects: ' + registrations);

    LoggerPurgeRegistration deliveryRegistration = registrations.get(0);
    System.Assert.areEqual(
      Schema.LoggerNotificationDelivery__c.SObjectType,
      deliveryRegistration.sobjectType,
      'Delivery should appear ahead of Match so the child deliveries purge first'
    );
    System.Assert.areEqual(
      Schema.LoggerNotificationDelivery__c.RetentionDate__c,
      deliveryRegistration.retentionDateField,
      'Delivery registration should point at LoggerNotificationDelivery__c.RetentionDate__c'
    );
    System.Assert.areEqual(
      new List<Schema.SObjectField>{
        Schema.LoggerNotificationDelivery__c.LoggerNotificationMatch__c,
        Schema.LoggerNotificationDelivery__c.LoggerNotificationRecipient__c
      },
      deliveryRegistration.sortByFields,
      'Delivery ORDER BY should cluster deliveries by master-detail parent + recipient to reduce lock scope'
    );

    LoggerPurgeRegistration matchRegistration = registrations.get(1);
    System.Assert.areEqual(Schema.LoggerNotificationMatch__c.SObjectType, matchRegistration.sobjectType);
    System.Assert.areEqual(
      Schema.LoggerNotificationMatch__c.RetentionDate__c,
      matchRegistration.retentionDateField,
      'Match registration should point at LoggerNotificationMatch__c.RetentionDate__c'
    );
    System.Assert.areEqual(
      new List<Schema.SObjectField>{ Schema.LoggerNotificationMatch__c.LoggerNotificationRule__c },
      matchRegistration.sortByFields,
      'Match ORDER BY should cluster deliveries by master-detail parent (LoggerNotificationRule__c)'
    );
  }

  @IsTest
  static void it_should_not_match_a_log_source_rule_on_a_rollup_field_at_after_insert_because_the_in_memory_rollup_is_still_zero() {
    // When a Logger.saveLog transaction inserts a Log__c and then inserts child LogEntry__c records,
    // the parent's AFTER_INSERT trigger fires with TotalERRORLogEntries__c = 0 on the in-memory
    // Trigger.new record - the rollup has not been recalculated yet. The plugin evaluates against the
    // in-memory record (no re-query), so a filter of `TotalERRORLogEntries__c >= 1` correctly evaluates
    // FALSE at insert time. The AFTER_UPDATE pass that Salesforce fires once the rollup recalculates
    // is the one that carries the satisfying value.
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    Log__c freshLog = [SELECT Id, TotalERRORLogEntries__c FROM Log__c WHERE Id = :log.Id WITH SYSTEM_MODE];
    System.Assert.areEqual(
      0,
      freshLog.TotalERRORLogEntries__c,
      'Test precondition: a Log__c with no child LogEntry__c records has TotalERRORLogEntries__c = 0'
    );
    LoggerNotificationRule__c rule = buildRule(Schema.Log__c.SObjectType, LOG_ROLLUP_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    new LoggerNotificationsPlugin()
      .execute(
        new LoggerPlugin__mdt(),
        new LoggerTriggerableContext(Schema.Log__c.SObjectType, System.TriggerOperation.AFTER_INSERT, new List<SObject>{ log })
      );
    System.Test.stopTest();

    System.Assert.areEqual(0, mockNotifierInvocationCount, 'AFTER_INSERT with rollup still 0 should not match a rollup >= 1 filter');
    System.Assert.areEqual(0, [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id WITH SYSTEM_MODE]);
  }

  @IsTest
  static void it_should_match_a_log_source_rule_on_a_rollup_field_at_after_update_when_a_child_insert_bumped_the_rollup_into_range() {
    // Child LogEntry__c inserts force Salesforce to recalculate the parent Log__c rollup, which flows
    // through the Log__c AFTER_UPDATE trigger with the new rollup value visible directly on the
    // Trigger.new record - no re-query needed. The plugin should treat this update as an opportunity
    // to evaluate rules whose filters reference rollup fields.
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    LoggerDataStore.getDatabase().insertRecord(log);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), Timestamp__c = System.now());
    LoggerDataStore.getDatabase().insertRecord(logEntry);
    Log__c updatedLog = [SELECT Id, TotalERRORLogEntries__c FROM Log__c WHERE Id = :log.Id WITH SYSTEM_MODE];
    System.Assert.areEqual(
      1,
      updatedLog.TotalERRORLogEntries__c,
      'Test precondition: the child ERROR LogEntry__c should have rolled up into the parent Log__c'
    );
    LoggerNotificationRule__c rule = buildRule(Schema.Log__c.SObjectType, LOG_ROLLUP_FILTER);
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    // Mirror the natural transaction shape: AFTER_INSERT first with the freshly-inserted Log__c (rollup
    // still 0 in memory, filter does not match), then AFTER_UPDATE once Salesforce recalculates the
    // new rollup value.
    LoggerNotificationsPlugin plugin = new LoggerNotificationsPlugin();
    plugin.execute(
      new LoggerPlugin__mdt(),
      new LoggerTriggerableContext(Schema.Log__c.SObjectType, System.TriggerOperation.AFTER_INSERT, new List<SObject>{ log })
    );
    plugin.execute(
      new LoggerPlugin__mdt(),
      new LoggerTriggerableContext(Schema.Log__c.SObjectType, System.TriggerOperation.AFTER_UPDATE, new List<SObject>{ updatedLog })
    );
    System.Test.stopTest();

    System.Assert.areEqual(
      1,
      mockNotifierInvocationCount,
      'AFTER_UPDATE on Log__c should feed rule evaluation so the rollup-bumped-into-range case reaches the notifier'
    );
    System.Assert.areEqual(
      1,
      [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id WITH SYSTEM_MODE],
      'A LoggerNotificationMatch__c should be recorded once the rollup update flows through the plugin'
    );
  }

  @IsTest
  static void it_should_ignore_after_update_for_records_not_seen_at_after_insert_in_the_same_transaction() {
    // The plugin accepts AFTER_UPDATE only so that Salesforce's rollup recalculation on any rollup summary fields
    // (which fires an AFTER_UPDATE immediately after the AFTER_INSERT pass that spawned the rollup) can be
    // observed by rule filters. It should NOT process later admin edits to those same records - e.g.,
    // an admin updating Log__c.Status__c / Log__c.Comments__c in a subsequent transaction. Only records
    // whose ID appeared in an AFTER_INSERT context earlier - in the same transaction - should be evaluated
    // at AFTER_UPDATE. This test simulates the admin-edit case: a Log__c already exists in the database
    // (the plugin never saw its AFTER_INSERT because that was a prior transaction), and the plugin is
    // handed only its AFTER_UPDATE. Notifier must not fire.
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    log.TransactionId__c = 'admin-edited-log';
    LoggerDataStore.getDatabase().insertRecord(log);
    Log__c persistedLog = [SELECT Id, TransactionId__c FROM Log__c WHERE Id = :log.Id WITH SYSTEM_MODE];
    LoggerNotificationRule__c rule = buildRule(Schema.Log__c.SObjectType, 'TransactionId__c = \'admin-edited-log\'');
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    // Only AFTER_UPDATE fires - no preceding AFTER_INSERT for this record in this transaction. This
    // mirrors the shape of a later admin edit that flows through the Log__c trigger stack without any
    // preceding insert pass.
    new LoggerNotificationsPlugin()
      .execute(
        new LoggerPlugin__mdt(),
        new LoggerTriggerableContext(Schema.Log__c.SObjectType, System.TriggerOperation.AFTER_UPDATE, new List<SObject>{ persistedLog })
      );
    System.Test.stopTest();

    System.Assert.areEqual(
      0,
      mockNotifierInvocationCount,
      'AFTER_UPDATE for a record that was not inserted earlier in this transaction should be ignored (admin-edit case)'
    );
    System.Assert.areEqual(
      0,
      [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id WITH SYSTEM_MODE],
      'No LoggerNotificationMatch__c should be recorded when AFTER_UPDATE is ignored for a record that was not inserted this transaction'
    );
  }

  @IsTest
  static void it_should_fire_the_notifier_only_once_when_a_record_matches_the_same_rule_at_after_insert_and_after_update() {
    // Records that match on both AFTER_INSERT and AFTER_UPDATE (typical of a filter that references
    // fields updated by same-transaction downstream DML) should notify exactly once per (rule, record)
    // per transaction. The processor tracks dispatched (rule, record) pairs and skips duplicates.
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    log.TransactionId__c = 'log-fires-once';
    LoggerDataStore.getDatabase().insertRecord(log);
    // Rule filter is satisfied on both passes below - the in-memory record carries a matching value at
    // AFTER_INSERT, and the same record with the same value is re-presented at AFTER_UPDATE. Without
    // the (rule, record) dedup, the notifier would fire twice.
    LoggerNotificationRule__c rule = buildRule(Schema.Log__c.SObjectType, 'TransactionId__c = \'log-fires-once\'');
    LoggerDataStore.getDatabase().insertRecord(rule);
    LoggerNotificationService__c service = buildService(MOCK_NOTIFIER_CLASS);
    LoggerDataStore.getDatabase().insertRecord(service);
    LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
      LoggerNotificationRule__c = rule.Id,
      LoggerNotificationService__c = service.Id
    );
    LoggerDataStore.getDatabase().insertRecord(recipient);

    System.Test.startTest();
    LoggerNotificationsPlugin plugin = new LoggerNotificationsPlugin();
    plugin.execute(
      new LoggerPlugin__mdt(),
      new LoggerTriggerableContext(Schema.Log__c.SObjectType, System.TriggerOperation.AFTER_INSERT, new List<SObject>{ log })
    );
    plugin.execute(
      new LoggerPlugin__mdt(),
      new LoggerTriggerableContext(Schema.Log__c.SObjectType, System.TriggerOperation.AFTER_UPDATE, new List<SObject>{ log })
    );
    System.Test.stopTest();

    System.Assert.areEqual(
      1,
      mockNotifierInvocationCount,
      'Same-transaction AFTER_INSERT + AFTER_UPDATE for the same (rule, record) should fire the notifier exactly once'
    );
    System.Assert.areEqual(
      1,
      [SELECT COUNT() FROM LoggerNotificationMatch__c WHERE LoggerNotificationRule__c = :rule.Id WITH SYSTEM_MODE],
      'Only one LoggerNotificationMatch__c should be recorded for the deduped (rule, record) pair'
    );
  }

  private static RecordingNotifier installRecordingNotifier() {
    RecordingNotifier recorder = new RecordingNotifier();
    LoggerNotificationsPlugin.notifierOverride = recorder;
    return recorder;
  }

  private static LoggerNotificationRule__c buildRule(Schema.SObjectType sobjectType, String filter) {
    return new LoggerNotificationRule__c(
      IsEnabled__c = true,
      IsMatchHistoryEnabled__c = true,
      IsDeliveryHistoryEnabled__c = true,
      IsMatchThresholdEnabled__c = false,
      Name = 'Test rule',
      SourceSObjectFilter__c = filter,
      SourceSObjectType__c = sobjectType.toString()
    );
  }

  private static LoggerNotificationService__c buildService(String notifierApexClassName) {
    return new LoggerNotificationService__c(IsEnabled__c = true, Name = 'Mock service', NotifierApexClassName__c = notifierApexClassName);
  }

  public class MockNotifier extends LoggerNotifier {
    public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
      mockNotifierInvocationCount++;
      mockNotifierLastRequest = request;
      return null;
    }
  }

  private class RecordingNotifier extends LoggerNotificationProcessor {
    public Integer invocationCount = 0;
    public Schema.SObjectType lastSObjectType;
    public List<SObject> lastRecords;

    public override void sendNotifications(Schema.SObjectType sobjectType, List<SObject> records) {
      this.invocationCount++;
      this.lastSObjectType = sobjectType;
      this.lastRecords = records;
    }
  }
}
