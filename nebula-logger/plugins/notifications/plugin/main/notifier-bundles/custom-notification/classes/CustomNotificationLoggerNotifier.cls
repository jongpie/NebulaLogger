//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Delivers a `LoggerNotifierRequest` as a Salesforce Custom Notification - the bell
 *              icon in the header + the Salesforce mobile app push. Emits one notification per matching
 *              record; recipients who want fewer notifications configure `DeduplicationSourceField__c` on
 *              the rule so duplicates collapse before dispatch.
 *
 *              Recipient configuration (read from `LoggerNotifierRequest.configuration`, which parses the
 *              recipient's `ConfigurationJson__c`):
 *                - `User__c` on the recipient - single user (required if the config JSON doesn't specify recipients)
 *                - `notificationTypeDeveloperName` (string, required) - matches a `CustomNotificationType.DeveloperName`
 *                - `recipientUserIds` (string list, optional) - additional users
 *                - `recipientGroupIds` (string list, optional) - public / queue groups
 *                - `titleTemplate` (string, optional) - Custom Notification title. Merge tokens `{FieldName__c}`
 *                    resolve against the current matching record; `{RuleName}` resolves to the rule's Name.
 *                    Defaults to `Nebula Logger: {RuleName}`.
 *                - `bodyTemplate` (string, optional) - Custom Notification body. Same merge tokens as
 *                    `titleTemplate`. Defaults to the record's Name (or its Id when the SObject has no
 *                    Name field).
 *
 *              At least one recipient (either `User__c` or an entry in the config JSON) must resolve.
 */
public without sharing class CustomNotificationLoggerNotifier extends LoggerNotifier {
  private static final Integer MAX_TITLE_LENGTH = 80;
  private static final Integer MAX_BODY_LENGTH = 750;

  private static final String CONFIG_KEY_NOTIFICATION_TYPE = 'notificationTypeDeveloperName';
  private static final String CONFIG_KEY_RECIPIENT_USER_IDS = 'recipientUserIds';
  private static final String CONFIG_KEY_RECIPIENT_GROUP_IDS = 'recipientGroupIds';
  private static final String CONFIG_KEY_TITLE_TEMPLATE = 'titleTemplate';
  private static final String CONFIG_KEY_BODY_TEMPLATE = 'bodyTemplate';

  private static final String TOKEN_RULE_NAME = 'RuleName';

  private static final String DEFAULT_TITLE_TEMPLATE = 'Nebula Logger: {' + TOKEN_RULE_NAME + '}';

  private static final System.Pattern MERGE_TOKEN_PATTERN = System.Pattern.compile('\\{([A-Za-z0-9_.]+)\\}');

  /**
   * @description Called by `LoggerNotificationAsyncDispatcher` in an async context.
   * @param request The rule + recipient + service + matching records to deliver.
   */
  public override LoggerNotifierResult sendNotification(LoggerNotifierRequest request) {
    if (request == null || request.recipient == null || request.matchingRecords == null || request.matchingRecords.isEmpty()) {
      return null;
    }
    String notificationTypeDeveloperName = request.configuration.getString(CONFIG_KEY_NOTIFICATION_TYPE);
    if (String.isBlank(notificationTypeDeveloperName)) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('CustomNotificationLoggerNotifier - ConfigurationJson__c must set ' + CONFIG_KEY_NOTIFICATION_TYPE + '; skipping');
      }
      LoggerNotifierResult skipped = new LoggerNotifierResult();
      skipped.status = LoggerNotifierResult.STATUS_SKIPPED;
      skipped.errorMessage = CONFIG_KEY_NOTIFICATION_TYPE + ' missing from ConfigurationJson__c';
      // TODO revisit this part, it might be better to throw (or at least construct) a relevant Exception instance instead
      skipped.errorStackTrace = new LoggerStackTrace().ParsedStackTraceString;
      return skipped;
    }
    Set<String> recipientIds = this.resolveRecipientIds(request);
    if (recipientIds.isEmpty()) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('CustomNotificationLoggerNotifier - no recipient users or groups resolved; skipping');
      }
      LoggerNotifierResult skipped = new LoggerNotifierResult();
      skipped.status = LoggerNotifierResult.STATUS_SKIPPED;
      skipped.errorMessage = 'No recipient users or groups resolved';
      return skipped;
    }
    Id typeId = this.lookupNotificationTypeId(notificationTypeDeveloperName);
    if (typeId == null) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        Logger.warn('CustomNotificationLoggerNotifier - could not resolve CustomNotificationType DeveloperName ' + notificationTypeDeveloperName);
      }
      LoggerNotifierResult skipped = new LoggerNotifierResult();
      skipped.status = LoggerNotifierResult.STATUS_SKIPPED;
      skipped.errorMessage = 'CustomNotificationType__mdt DeveloperName ' + notificationTypeDeveloperName + ' not found';
      return skipped;
    }
    String titleTemplate = request.configuration.getString(CONFIG_KEY_TITLE_TEMPLATE);
    String bodyTemplate = request.configuration.getString(CONFIG_KEY_BODY_TEMPLATE);
    Integer failureCount = 0;
    String firstError;
    for (SObject record : request.matchingRecords) {
      Messaging.CustomNotification customNotification = this.buildNotification(request, record, typeId, titleTemplate, bodyTemplate);
      try {
        customNotification.send(recipientIds);
      } catch (System.Exception ex) {
        failureCount++;
        if (String.isBlank(firstError)) {
          firstError = ex.getMessage();
        }
        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
          Logger.error('CustomNotificationLoggerNotifier - send failed', ex);
        }
      }
    }
    // See Backlog.md: notifier-side Logger.saveLog() re-fires the notifications plugin trigger; commented out for now.
    // Logger.saveLog();
    LoggerNotifierResult outcome = new LoggerNotifierResult();
    if (failureCount == 0) {
      outcome.status = LoggerNotifierResult.STATUS_DELIVERED;
    } else {
      outcome.status = LoggerNotifierResult.STATUS_FAILED;
      outcome.errorMessage = failureCount + ' of ' + request.matchingRecords.size() + ' notifications failed; first error: ' + firstError;
    }
    return outcome;
  }

  @TestVisible
  private Messaging.CustomNotification buildNotification(
    LoggerNotifierRequest request,
    SObject record,
    Id typeId,
    String titleTemplate,
    String bodyTemplate
  ) {
    Messaging.CustomNotification customNotification = new Messaging.CustomNotification();
    customNotification.setNotificationTypeId(typeId);
    customNotification.setTitle(this.buildTitle(request, record, titleTemplate));
    customNotification.setBody(this.buildBody(request, record, bodyTemplate));
    customNotification.setTargetId((Id) record.get('Id'));
    return customNotification;
  }

  @TestVisible
  private String buildTitle(LoggerNotifierRequest request, SObject record, String template) {
    String effectiveTemplate = String.isBlank(template) ? DEFAULT_TITLE_TEMPLATE : template;
    String rendered = this.renderTemplate(effectiveTemplate, request, record);
    return this.truncate(rendered, MAX_TITLE_LENGTH);
  }

  @TestVisible
  private String buildBody(LoggerNotifierRequest request, SObject record, String template) {
    if (String.isNotBlank(template)) {
      return this.truncate(this.renderTemplate(template, request, record), MAX_BODY_LENGTH);
    }
    return this.truncate(this.defaultBody(record), MAX_BODY_LENGTH);
  }

  private String defaultBody(SObject record) {
    String name = this.tryGetString(record, 'Name');
    if (String.isNotBlank(name)) {
      return name;
    }
    Id recordId = (Id) record.get('Id');
    return recordId == null ? '' : String.valueOf(recordId);
  }

  @TestVisible
  private String renderTemplate(String template, LoggerNotifierRequest request, SObject record) {
    if (String.isBlank(template)) {
      return '';
    }
    System.Matcher matcher = MERGE_TOKEN_PATTERN.matcher(template);
    List<String> parts = new List<String>();
    Integer cursor = 0;
    while (matcher.find()) {
      parts.add(template.substring(cursor, matcher.start()));
      String token = matcher.group(1);
      String resolved = this.resolveToken(token, request, record);
      parts.add(resolved == null ? '' : resolved);
      cursor = matcher.end();
    }
    parts.add(template.substring(cursor));
    return String.join(parts, '');
  }

  private String resolveToken(String token, LoggerNotifierRequest request, SObject record) {
    if (TOKEN_RULE_NAME.equalsIgnoreCase(token)) {
      return request.notificationRule == null ? '' : String.valueOf(request.notificationRule.Name);
    }
    Object value = this.resolveFieldPath(record, token);
    return value == null ? '' : String.valueOf(value);
  }

  private Object resolveFieldPath(SObject record, String fieldPath) {
    if (record == null || String.isBlank(fieldPath)) {
      return null;
    }
    List<String> parts = fieldPath.split('\\.');
    SObject current = record;
    for (Integer i = 0; i < parts.size() - 1; i++) {
      try {
        current = current.getSObject(parts.get(i));
      } catch (System.SObjectException ex) {
        return null;
      }
      if (current == null) {
        return null;
      }
    }
    try {
      return current.get(parts.get(parts.size() - 1));
    } catch (System.SObjectException ex) {
      return null;
    }
  }

  @TestVisible
  private Set<String> resolveRecipientIds(LoggerNotifierRequest request) {
    Set<String> recipientIds = new Set<String>();
    if (request.recipient.User__c != null) {
      recipientIds.add(String.valueOf(request.recipient.User__c));
    }
    this.addIdsFromConfig(recipientIds, request.configuration, CONFIG_KEY_RECIPIENT_USER_IDS);
    this.addIdsFromConfig(recipientIds, request.configuration, CONFIG_KEY_RECIPIENT_GROUP_IDS);
    return recipientIds;
  }

  private void addIdsFromConfig(Set<String> target, LoggerNotifierConfiguration config, String key) {
    List<String> values = config.getStringList(key);
    if (values == null) {
      return;
    }
    target.addAll(values);
  }

  @TestVisible
  private Id lookupNotificationTypeId(String developerName) {
    List<CustomNotificationType> results = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = :developerName LIMIT 1];
    return results.isEmpty() ? null : results.get(0).Id;
  }

  private String tryGetString(SObject record, String fieldName) {
    Map<String, Schema.SObjectField> fields = record.getSObjectType().getDescribe().fields.getMap();
    if (fields.containsKey(fieldName.toLowerCase()) == false) {
      return null;
    }
    try {
      Object value = record.get(fieldName);
      return value == null ? null : String.valueOf(value);
    } catch (System.SObjectException ex) {
      return null;
    }
  }

  private String truncate(String value, Integer maxLength) {
    if (value == null || value.length() <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength - 3) + '...';
  }
}
