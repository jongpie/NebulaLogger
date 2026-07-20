//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerNotificationsPlugin_Tests {
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
    List<SObject> records = new List<SObject>{ new LogEntry__c(LoggingLevel__c = 'ERROR') };

    plugin.execute(new LoggerPlugin__mdt(), new LoggerTriggerableContext(Schema.LogEntry__c.SObjectType, System.TriggerOperation.AFTER_INSERT, records));

    System.Assert.areEqual(1, notifier.invocationCount);
    System.Assert.areEqual(Schema.LogEntry__c.SObjectType, notifier.lastSObjectType);
    System.Assert.areEqual(records, notifier.lastRecords);
  }

  @IsTest
  static void it_should_ignore_logEntryEvent_after_insert() {
    // LogEntryEvent__e is not a supported source SObject type - platform events have no IDs, so we
    // cannot record LoggerNotificationMatch__c rows against them. The plugin should silently skip.
    RecordingNotifier notifier = installRecordingNotifier();
    LoggerNotificationsPlugin plugin = new LoggerNotificationsPlugin();
    List<SObject> records = new List<SObject>{ new LogEntryEvent__e(LoggingLevel__c = 'ERROR') };

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
    // "delete delivery rows before their parent match rows". Each registration declares its
    // RetentionDate__c field for the cutoff comparison and clusters its rows by master-detail
    // parent for ORDER BY so batches acquire one parent lock per cluster instead of interleaving
    // locks across many parents.
    List<LoggerPurgeRegistration> registrations = new LoggerNotificationsPlugin().getPurgeRegistrations();

    System.Assert.areEqual(2, registrations.size(), 'Plugin should declare exactly two purgeable SObjects: ' + registrations);

    LoggerPurgeRegistration deliveryRegistration = registrations.get(0);
    System.Assert.areEqual(
      Schema.LoggerNotificationDelivery__c.SObjectType,
      deliveryRegistration.sobjectType,
      'Delivery should appear ahead of Match so the child rows purge first'
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
      'Delivery ORDER BY should cluster rows by master-detail parent + recipient to reduce lock scope'
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
      'Match ORDER BY should cluster rows by master-detail parent (LoggerNotificationRule__c)'
    );
  }

  private static RecordingNotifier installRecordingNotifier() {
    RecordingNotifier recorder = new RecordingNotifier();
    LoggerNotificationsPlugin.notifierOverride = recorder;
    return recorder;
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
