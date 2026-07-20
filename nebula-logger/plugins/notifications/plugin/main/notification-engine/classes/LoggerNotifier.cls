//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Abstract base class extended by Apex classes that deliver notifications for the Nebula Logger notifications
 *              plugin. Each `LoggerNotificationService__c` record names a concrete subclass via its
 *              `NotifierApexClassName__c` field. The runtime instantiates the subclass dynamically for each recipient
 *              and hands it the matching records plus the recipient's connection configuration.
 */
public abstract class LoggerNotifier {
  /**
   * @description Called by `LoggerNotificationProcessor` when one or more records match a rule that references this service.
   *              Subclasses are responsible for delivering the notification (callout, email, etc.) and
   *              returning a `LoggerNotifierResult` describing what happened. Returning `null` is treated
   *              the same as a bare success by the runtime.
   * @param request The details of the matched rule, recipient, and records.
   * @return A `LoggerNotifierResult` describing the delivery outcome (status, external reference, HTTP details, etc.),
   *         or `null` to accept the runtime's default of "delivered with no additional detail".
   */
  public abstract LoggerNotifierResult sendNotification(LoggerNotifierRequest request);
}
