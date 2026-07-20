//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description DTO passed to `LoggerNotifier` implementations at delivery time. Carries the rule that
 *              matched, the recipient configuration, the service configuration, and the log records
 *              that satisfied the rule's `SourceSObjectFilter__c` expression.
 */
public class LoggerNotifierRequest {
  /**
   * @description The `LoggerNotificationRule__c` rule that matched the records.
   */
  public LoggerNotificationRule__c notificationRule { get; private set; }

  /**
   * @description The specific `LoggerNotificationRecipient__c` this delivery is targeting.
   */
  public LoggerNotificationRecipient__c recipient { get; private set; }

  /**
   * @description The `LoggerNotificationService__c` referenced by the recipient.
   */
  public LoggerNotificationService__c service { get; private set; }

  /**
   * @description The log records (`LogEntry__c` or `LogEntryEvent__e`) that matched the rule.
   */
  public List<SObject> matchingRecords { get; private set; }

  /**
   * @description Typed accessor over the recipient's `ConfigurationJson__c` payload. Notifiers
   *              read per-recipient overrides (which source fields to render, etc.) from here instead of
   *              parsing raw JSON. Never null; a recipient with no configuration yields an empty config
   *              whose getters return null / empty defaults.
   */
  public LoggerNotifierConfiguration configuration { get; private set; }

  public LoggerNotifierRequest(
    LoggerNotificationRule__c notificationRule,
    LoggerNotificationRecipient__c recipient,
    LoggerNotificationService__c service,
    List<SObject> matchingRecords
  ) {
    this.notificationRule = notificationRule;
    this.recipient = recipient;
    this.service = service;
    this.matchingRecords = matchingRecords;
    this.configuration = new LoggerNotifierConfiguration(recipient);
  }
}
