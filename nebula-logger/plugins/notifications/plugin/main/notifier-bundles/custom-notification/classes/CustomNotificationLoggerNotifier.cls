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
 *                - `User__c` on the recipient - the single target user (required)
 *                - `notificationTypeDeveloperName` (string, required) - matches a `CustomNotificationType.DeveloperName`
 *                - `titleTemplate` (string, optional) - Custom Notification title. Merge tokens `{FieldName__c}`
 *                    resolve against the current matching record; `{RuleName}` resolves to the rule's Name.
 *                    Defaults to `Nebula Logger: {RuleName}`.
 *                - `bodyTemplate` (string, optional) - Custom Notification body. Same merge tokens as
 *                    `titleTemplate`. Defaults to the record's Name (or its Id when the SObject has no
 *                    Name field).
 */
public without sharing class CustomNotificationLoggerNotifier extends LoggerNotifier {
  private static final Integer MAX_TITLE_LENGTH = 80;
  private static final Integer MAX_BODY_LENGTH = 750;

  private static final String CONFIG_KEY_NOTIFICATION_TYPE = 'notificationTypeDeveloperName';
  private static final String CONFIG_KEY_TITLE_TEMPLATE = 'titleTemplate';
  private static final String CONFIG_KEY_BODY_TEMPLATE = 'bodyTemplate';

  private static final String MERGE_KEY_RULE_NAME = 'RuleName';

  private static final String DEFAULT_TITLE_TEMPLATE = 'Nebula Logger: {' + MERGE_KEY_RULE_NAME + '}';

  private static final System.Pattern MERGE_TOKEN_PATTERN = System.Pattern.compile('\\{([A-Za-z0-9_.]+)\\}');

  @TestVisible
  private static Sender sender = new RealSender();

  /**
   * @description Called by `LoggerNotificationAsyncDispatcher` in an async context.
   * @param notifierRequest The rule + recipient + service + matching records to deliver.
   */
  public override LoggerNotifierResult sendNotification(LoggerNotifierRequest notifierRequest) {
    if (notifierRequest == null || notifierRequest.recipient == null || notifierRequest.matchingRecords == null || notifierRequest.matchingRecords.isEmpty()) {
      return null;
    }
    String notificationTypeDeveloperName = notifierRequest.configuration.getString(CONFIG_KEY_NOTIFICATION_TYPE);
    if (String.isBlank(notificationTypeDeveloperName)) {
      return buildSkipped(
        'CustomNotificationLoggerNotifier - ConfigurationJson__c must set ' + CONFIG_KEY_NOTIFICATION_TYPE + '; skipping',
        CONFIG_KEY_NOTIFICATION_TYPE + ' missing from ConfigurationJson__c'
      );
    }
    if (notifierRequest.recipient.User__c == null) {
      return buildSkipped('CustomNotificationLoggerNotifier - recipient has no User__c set; skipping', 'Recipient User__c is required');
    }
    Id customNotificationTypeId = this.lookupNotificationTypeId(notificationTypeDeveloperName);
    if (customNotificationTypeId == null) {
      return buildSkipped(
        'CustomNotificationLoggerNotifier - could not resolve CustomNotificationType DeveloperName ' + notificationTypeDeveloperName,
        'CustomNotificationType__mdt DeveloperName ' + notificationTypeDeveloperName + ' not found'
      );
    }
    Integer failureCount = 0;
    String firstError;
    for (SObject matchingRecord : notifierRequest.matchingRecords) {
      Payload payload = this.buildPayload(notifierRequest, matchingRecord, customNotificationTypeId);
      try {
        sender.send(payload);
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
    LoggerNotifierResult outcome = new LoggerNotifierResult();
    if (failureCount == 0) {
      outcome.status = LoggerNotifierResult.STATUS_DELIVERED;
    } else {
      outcome.status = LoggerNotifierResult.STATUS_FAILED;
      outcome.errorMessage = failureCount + ' of ' + notifierRequest.matchingRecords.size() + ' notifications failed; first error: ' + firstError;
    }
    return outcome;
  }

  /**
   * @description Builds a `STATUS_SKIPPED` result with a system-messages warning and an admin-facing
   *              error message. Kept as a helper so `sendNotification`'s three guard clauses stay
   *              structurally identical instead of drifting.
   */
  private static LoggerNotifierResult buildSkipped(String warnMessage, String errorMessage) {
    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      Logger.warn(warnMessage);
    }
    LoggerNotifierResult skipped = new LoggerNotifierResult();
    skipped.status = LoggerNotifierResult.STATUS_SKIPPED;
    skipped.errorMessage = errorMessage;
    return skipped;
  }

  private Payload buildPayload(LoggerNotifierRequest notifierRequest, SObject matchingRecord, Id customNotificationTypeId) {
    String titleTemplate = notifierRequest.configuration.getString(CONFIG_KEY_TITLE_TEMPLATE);
    String bodyTemplate = notifierRequest.configuration.getString(CONFIG_KEY_BODY_TEMPLATE);
    Payload payload = new Payload();
    payload.notificationTypeId = customNotificationTypeId;
    payload.title = this.buildTitle(notifierRequest, matchingRecord, titleTemplate);
    payload.body = this.buildBody(notifierRequest, matchingRecord, bodyTemplate);
    payload.targetId = (Id) matchingRecord.get('Id');
    payload.recipientUserId = notifierRequest.recipient.User__c;
    return payload;
  }

  private String buildTitle(LoggerNotifierRequest notifierRequest, SObject record, String template) {
    String effectiveTemplate = String.isBlank(template) ? DEFAULT_TITLE_TEMPLATE : template;
    String rendered = this.renderTemplate(effectiveTemplate, notifierRequest, record);
    return rendered?.abbreviate(MAX_TITLE_LENGTH);
  }

  private String buildBody(LoggerNotifierRequest notifierRequest, SObject record, String template) {
    if (String.isNotBlank(template)) {
      return this.renderTemplate(template, notifierRequest, record)?.abbreviate(MAX_BODY_LENGTH);
    }
    return this.defaultBody(record)?.abbreviate(MAX_BODY_LENGTH);
  }

  private String defaultBody(SObject record) {
    String name = this.tryGetString(record, 'Name');
    if (String.isNotBlank(name)) {
      return name;
    }
    Id recordId = (Id) record.get('Id');
    return recordId == null ? '' : String.valueOf(recordId);
  }

  private String renderTemplate(String template, LoggerNotifierRequest notifierRequest, SObject record) {
    if (String.isBlank(template)) {
      return '';
    }
    System.Matcher matcher = MERGE_TOKEN_PATTERN.matcher(template);
    List<String> parts = new List<String>();
    Integer cursor = 0;
    while (matcher.find()) {
      parts.add(template.substring(cursor, matcher.start()));
      String token = matcher.group(1);
      String resolved = this.resolveToken(token, notifierRequest, record);
      parts.add(resolved == null ? '' : resolved);
      cursor = matcher.end();
    }
    parts.add(template.substring(cursor));
    return String.join(parts, '');
  }

  private String resolveToken(String token, LoggerNotifierRequest notifierRequest, SObject record) {
    if (MERGE_KEY_RULE_NAME.equalsIgnoreCase(token)) {
      return notifierRequest.recipient.LoggerNotificationRule__r == null ? '' : String.valueOf(notifierRequest.recipient.LoggerNotificationRule__r.Name);
    }
    Object value = LoggerNotifier.getValueByPath(record, token);
    return value == null ? '' : String.valueOf(value);
  }

  private Id lookupNotificationTypeId(String developerName) {
    // CustomNotificationType is an admin-managed metadata table; SYSTEM_MODE keeps the lookup working
    // regardless of the async-executing user's object-level permissions on it.
    List<CustomNotificationType> results = [
      SELECT Id
      FROM CustomNotificationType
      WHERE DeveloperName = :developerName
      WITH SYSTEM_MODE
    ];
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

  /**
   * @description DTO capturing every value the notifier will set on a `Messaging.CustomNotification`
   *              plus the target user. `RealSender` translates this to a live Custom Notification and
   *              dispatches it; tests inject a capturing `Sender` implementation and assert on the DTO.
   */
  public class Payload {
    public String title;
    public String body;
    public Id notificationTypeId;
    public Id recipientUserId;
    public Id targetId;
  }

  /**
   * @description Seam over `Messaging.CustomNotification.send(...)`. `RealSender` is the production
   *              implementation; tests replace `CustomNotificationLoggerNotifier.sender` with a
   *              capturing implementation so they can assert on the `Payload` values.
   */
  public interface Sender {
    void send(Payload payload);
  }

  private class RealSender implements Sender {
    public void send(Payload payload) {
      Messaging.CustomNotification notification = new Messaging.CustomNotification();
      notification.setNotificationTypeId(payload.notificationTypeId);
      notification.setTitle(payload.title);
      notification.setBody(payload.body);
      notification.setTargetId(payload.targetId);
      notification.send(new Set<String>{ payload.recipientUserId });
    }
  }
}
