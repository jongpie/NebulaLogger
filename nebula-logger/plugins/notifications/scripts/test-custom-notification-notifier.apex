// Directly invokes CustomNotificationLoggerNotifier.sendNotification with a
// hand-built LoggerNotifiableContext. Use this to verify custom-notification
// delivery end-to-end without waiting for a LogEntryEvent__e trigger to fire the
// full notifications pipeline. The Custom Notification is sent synchronously
// from anonymous Apex - the bell should light up for the target user as soon as
// the script finishes.
//
// Usage:
//   sf apex run --file nebula-logger/plugins/notifications/scripts/test-custom-notification-notifier.apex
//
// Prerequisites:
//   1. Deploy the notifications plugin (including the LoggerCustomNotification
//      CustomNotificationType record).
//   2. Assign the LoggerNotificationsPluginAdmin permission set (or ensure the
//      running user has Read on LogEntry__c and can send Custom Notifications).
//   3. Edit the CONFIG block below - at minimum, drop a real recipient user Id
//      into `recipientUserId`.

// ---- CONFIG ------------------------------------------------------------------
// Recipient user - the bell icon fires for this user. Defaults to the running user.
Id recipientUserId = System.UserInfo.getUserId();

// CustomNotificationType DeveloperName. LoggerCustomNotification ships with the plugin.
String notificationTypeDeveloperName = 'LoggerCustomNotification';

// Title / body templates. Set to null to fall back to the notifier's defaults.
String titleTemplate = '[Test] {RuleName}';
String bodyTemplate = '[{LoggingLevel__c}] {Message__c}';

// Rule name that {RuleName} resolves to.
String ruleName = 'Manual test rule';

// The matching record the notifier renders against. Uses the most recent real
// LogEntry__c out of the org, so setTargetId points at a page that actually
// exists and the click-through works. Run some Logger recipes first if the org
// is empty.
List<LogEntry__c> recentEntries = [SELECT Id, Name, LoggingLevel__c, Message__c FROM LogEntry__c ORDER BY CreatedDate DESC LIMIT 1];
if (recentEntries.isEmpty()) {
  throw new System.IllegalArgumentException(
    'No LogEntry__c rows exist in the org - run a Logger recipe or an anonymous Apex block that logs something before invoking this script'
  );
}
SObject matchingRecord = recentEntries.get(0);
System.debug('Testing against LogEntry__c ' + matchingRecord.Id + ' - ' + recentEntries.get(0).Message__c);

// ---- Build the context -------------------------------------------------------
Map<String, Object> configPayload = new Map<String, Object>{ 'notificationTypeDeveloperName' => notificationTypeDeveloperName };
if (String.isNotBlank(titleTemplate)) {
  configPayload.put('titleTemplate', titleTemplate);
}
if (String.isNotBlank(bodyTemplate)) {
  configPayload.put('bodyTemplate', bodyTemplate);
}

LoggerNotificationRule__c rule = new LoggerNotificationRule__c(Name = ruleName, SourceSObjectType__c = String.valueOf(matchingRecord.getSObjectType()));
LoggerNotificationService__c service = new LoggerNotificationService__c(
  Name = 'Manual test service',
  NotifierApexClassName__c = 'CustomNotificationLoggerNotifier',
  IsEnabled__c = true
);
LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
  User__c = recipientUserId,
  ConfigurationJson__c = System.JSON.serialize(configPayload)
);
LoggerNotifiableContext context = new LoggerNotifiableContext(rule, recipient, service, new List<SObject>{ matchingRecord });

System.debug('Recipient user: ' + recipientUserId);
System.debug('Config payload: ' + System.JSON.serialize(configPayload));

// ---- Invoke ------------------------------------------------------------------
CustomNotificationLoggerNotifier notifier = new CustomNotificationLoggerNotifier();
LoggerNotifiableResult result = notifier.sendNotification(context);

// ---- Report ------------------------------------------------------------------
System.debug('----- CustomNotificationLoggerNotifier result -----');
if (result == null) {
  System.debug('Notifier returned null (short-circuited before delivery)');
} else {
  System.debug('Status: ' + result.status);
  if (String.isNotBlank(result.errorMessage)) {
    System.debug('Error message: ' + result.errorMessage);
  }
  if (String.isNotBlank(result.errorStackTrace)) {
    System.debug('Stack trace: ' + result.errorStackTrace);
  }
}
