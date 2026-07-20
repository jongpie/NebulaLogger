// Directly invokes EmailLoggerNotifier.sendNotification with a hand-built
// LoggerNotifiableContext. Use this to verify email delivery end-to-end without
// waiting for a LogEntryEvent__e trigger to fire the full notifications
// pipeline.
//
// Usage:
//   sf apex run --file nebula-logger/plugins/notifications/scripts/test-email-notifier.apex
//
// Prerequisites:
//   1. Deploy the notifications plugin.
//   2. The running user's org must have "Access Deliverability" set to "All
//      email" (Setup -> Email -> Deliverability). Otherwise Salesforce silently
//      drops the outbound message.
//   3. If using recipientUserId, the target User needs a valid email address.
//      If using recipientEmailAddress, that address counts against the daily
//      external-email limit (5000/day).

// ---- CONFIG ------------------------------------------------------------------
// Set exactly ONE of the two. Leave the other blank.
//
// Target user - the email is sent as a "template email to user" so it does NOT
// count against the external-email daily limit. Defaults to the running user.
Id recipientUserId = System.UserInfo.getUserId();
//
// Or a raw email address - the email is sent as an external message and counts
// against the daily limit. Leave blank to use recipientUserId instead.
String recipientEmailAddress = '';

// Rule name that shows up in the subject line and body.
String ruleName = 'Manual test rule';

// Optional formula-source-object-filter text shown in the body. Blank omits it.
String sourceSObjectFilter = '';

// The matching record the notifier renders against. Uses the most recent real
// LogEntry__c out of the org so the "Record link" in the email body points at
// a real page. Run a Logger recipe first if the org has no log entries.
List<LogEntry__c> recentEntries = [SELECT Id, Name, LoggingLevel__c, Message__c, Origin__c, StackTrace__c FROM LogEntry__c ORDER BY CreatedDate DESC LIMIT 1];
if (recentEntries.isEmpty()) {
  throw new System.IllegalArgumentException(
    'No LogEntry__c rows exist in the org - run a Logger recipe or an anonymous Apex block that logs something before invoking this script'
  );
}
SObject matchingRecord = recentEntries.get(0);
System.debug('Testing against LogEntry__c ' + matchingRecord.Id + ' - ' + recentEntries.get(0).Message__c);

// ---- Validate CONFIG ---------------------------------------------------------
if (recipientUserId == null && String.isBlank(recipientEmailAddress)) {
  throw new System.IllegalArgumentException('Set either recipientUserId or recipientEmailAddress in the CONFIG block');
}

// ---- Build the context -------------------------------------------------------
LoggerNotificationRule__c rule = new LoggerNotificationRule__c(
  Name = ruleName,
  SourceSObjectType__c = String.valueOf(matchingRecord.getSObjectType()),
  SourceSObjectFilter__c = String.isBlank(sourceSObjectFilter) ? null : sourceSObjectFilter
);
LoggerNotificationService__c service = new LoggerNotificationService__c(
  Name = 'Manual test email service',
  NotifierApexClassName__c = 'EmailLoggerNotifier',
  IsEnabled__c = true
);
LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
  // User__c takes precedence over EmailAddress__c in the notifier; leaving both
  // set here is a config bug that this script's validation above already caught.
  User__c = String.isBlank(recipientEmailAddress) ? recipientUserId : null,
  EmailAddress__c = String.isBlank(recipientEmailAddress) ? null : recipientEmailAddress
);
LoggerNotifiableContext context = new LoggerNotifiableContext(rule, recipient, service, new List<SObject>{ matchingRecord });

System.debug('Email target: ' + (String.isNotBlank(recipientEmailAddress) ? 'external address ' + recipientEmailAddress : 'user ' + recipientUserId));

// ---- Invoke ------------------------------------------------------------------
EmailLoggerNotifier notifier = new EmailLoggerNotifier();
LoggerNotifiableResult result = notifier.sendNotification(context);

// ---- Report ------------------------------------------------------------------
System.debug('----- EmailLoggerNotifier result -----');
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
