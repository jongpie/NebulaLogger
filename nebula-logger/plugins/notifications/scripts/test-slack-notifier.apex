// Directly invokes SlackLoggerNotifier.sendNotification with a hand-built
// LoggerNotifiableContext. Use this to verify Slack delivery end-to-end without
// waiting for a LogEntryEvent__e trigger to fire the full notifications
// pipeline. Slack accepts HTTP callouts synchronously, so the message posts as
// soon as the script finishes.
//
// Usage:
//   sf apex run --file nebula-logger/plugins/notifications/scripts/test-slack-notifier.apex
//
// Prerequisites:
//   1. Deploy the notifications plugin.
//   2. Choose Web-API mode (Named Credential) or Webhook mode - edit the CONFIG
//      block below. In Web-API mode, the Named Credential must exist in the org
//      and its principal must be granted callout access to the running user (or
//      via the LoggerNotificationsPluginAdmin permission set). In Webhook mode,
//      paste a working incoming-webhook URL.

// ---- CONFIG ------------------------------------------------------------------
// Set exactly ONE of the two. Leave the other blank.
//
// Named Credential DeveloperName - used for Web API mode via
//   callout:<name>/chat.postMessage. Point at a Slack app installed in your
//   workspace with the chat:write scope.
String namedCredentialDeveloperName = '';
//
// Incoming webhook URL. Only valid for the specific channel the webhook was
// created against.
String webhookUrl = 'https://hooks.slack.com/services/REPLACE/WITH/YOUR_WEBHOOK';

// Channel identifier - required for Web API mode (e.g. `#alerts` or a channel
// Id like `C01234567`), ignored for webhook mode.
String channelIdentifier = '#alerts';

// Per-recipient sourceFields config. Set to null to fall back to the notifier's
// built-in default set (LoggingLevel__c, Origin__c, Message__c, StackTrace__c,
// ExceptionType__c). Bare strings or {field, displayField, displayLabel} object
// entries both work.
List<Object> sourceFieldsConfig = null;

// Rule name shown in the top-level `text` line of the Slack payload.
String ruleName = 'Manual test rule';

// The matching record the notifier renders against. Uses the most recent real
// LogEntry__c out of the org so hydration + linkification work against real
// data. Run a Logger recipe first if the org has no log entries.
List<LogEntry__c> recentEntries = [SELECT Id, Name, LoggingLevel__c, Message__c FROM LogEntry__c ORDER BY CreatedDate DESC LIMIT 1];
if (recentEntries.isEmpty()) {
  throw new System.IllegalArgumentException(
    'No LogEntry__c rows exist in the org - run a Logger recipe or an anonymous Apex block that logs something before invoking this script'
  );
}
SObject matchingRecord = recentEntries.get(0);
System.debug('Testing against LogEntry__c ' + matchingRecord.Id + ' - ' + recentEntries.get(0).Message__c);

// ---- Validate CONFIG ---------------------------------------------------------
if (String.isBlank(namedCredentialDeveloperName) && String.isBlank(webhookUrl)) {
  throw new System.IllegalArgumentException('Set either namedCredentialDeveloperName or webhookUrl in the CONFIG block');
}
if (String.isNotBlank(namedCredentialDeveloperName) && String.isNotBlank(webhookUrl)) {
  throw new System.IllegalArgumentException('Set exactly ONE of namedCredentialDeveloperName or webhookUrl, not both');
}

// ---- Build the context -------------------------------------------------------
Map<String, Object> configPayload = new Map<String, Object>();
if (sourceFieldsConfig != null) {
  configPayload.put('sourceFields', sourceFieldsConfig);
}

LoggerNotificationRule__c rule = new LoggerNotificationRule__c(Name = ruleName, SourceSObjectType__c = String.valueOf(matchingRecord.getSObjectType()));
LoggerNotificationService__c service = new LoggerNotificationService__c(
  Name = 'Manual test Slack service',
  NotifierApexClassName__c = 'SlackLoggerNotifier',
  IsEnabled__c = true,
  NamedCredentialDeveloperName__c = String.isBlank(namedCredentialDeveloperName) ? null : namedCredentialDeveloperName,
  WebhookUrl__c = String.isBlank(webhookUrl) ? null : webhookUrl
);
LoggerNotificationRecipient__c recipient = new LoggerNotificationRecipient__c(
  ChannelIdentifier__c = channelIdentifier,
  ConfigurationJson__c = configPayload.isEmpty() ? null : System.JSON.serialize(configPayload)
);
LoggerNotifiableContext context = new LoggerNotifiableContext(rule, recipient, service, new List<SObject>{ matchingRecord });

System.debug('Slack mode: ' + (String.isNotBlank(namedCredentialDeveloperName) ? 'Named Credential ' + namedCredentialDeveloperName : 'Webhook'));
System.debug('Channel: ' + channelIdentifier);
if (configPayload.isEmpty() == false) {
  System.debug('Config payload: ' + System.JSON.serialize(configPayload));
}

// ---- Invoke ------------------------------------------------------------------
SlackLoggerNotifier notifier = new SlackLoggerNotifier();
LoggerNotifiableResult result = notifier.sendNotification(context);

// ---- Report ------------------------------------------------------------------
System.debug('----- SlackLoggerNotifier result -----');
if (result == null) {
  System.debug('Notifier returned null (short-circuited before delivery)');
} else {
  System.debug('Status: ' + result.status);
  System.debug('HTTP status: ' + result.httpStatusCode + ' ' + result.httpStatusReason);
  if (String.isNotBlank(result.requestUrl)) {
    System.debug('Request URL: ' + result.requestUrl);
  }
  if (String.isNotBlank(result.requestBody)) {
    System.debug('Request body: ' + result.requestBody);
  }
  if (String.isNotBlank(result.responseBody)) {
    System.debug('Response body: ' + result.responseBody);
  }
  if (String.isNotBlank(result.externalReferenceId)) {
    System.debug('External reference id (message ts): ' + result.externalReferenceId);
  }
  if (String.isNotBlank(result.externalReferenceUrl)) {
    System.debug('External reference url: ' + result.externalReferenceUrl);
  }
  if (String.isNotBlank(result.errorMessage)) {
    System.debug('Error message: ' + result.errorMessage);
  }
  if (String.isNotBlank(result.errorStackTrace)) {
    System.debug('Stack trace: ' + result.errorStackTrace);
  }
}
