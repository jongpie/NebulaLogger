//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description DTO passed to `LoggerNotifier` implementations at delivery time. Carries the recipient
 *              (which itself carries its parent rule + service via `LoggerNotificationRule__r` and
 *              `LoggerNotificationService__r`) and the logging records that satisfied the rule's
 *              `SourceSObjectFilter__c` expression.
 */
public class LoggerNotifierRequest {
  /**
   * @description The specific `LoggerNotificationRecipient__c` this delivery is targeting. Its parent
   *              lookups (`LoggerNotificationRule__r` and `LoggerNotificationService__r`) carry the
   *              rule that matched and the service that owns this recipient.
   */
  public final LoggerNotificationRecipient__c recipient;

  /**
   * @description The logging records (`Log__c`, `LogEntry__c`, etc.) that matched the rule filter.
   */
  public final List<SObject> matchingRecords;

  /**
   * @description Typed accessor over the recipient's `ConfigurationJson__c` payload. Notifiers
   *              read per-recipient overrides (which source fields to render, etc.) from here instead of
   *              parsing raw JSON. Never null; a recipient with no configuration yields an empty config
   *              whose getters return null / empty defaults.
   */
  public final LoggerNotifierConfiguration configuration;

  public LoggerNotifierRequest(LoggerNotificationRecipient__c recipient, List<SObject> matchingRecords) {
    this.recipient = recipient;
    this.matchingRecords = matchingRecords;
    this.configuration = new LoggerNotifierConfiguration(recipient);
  }
}
