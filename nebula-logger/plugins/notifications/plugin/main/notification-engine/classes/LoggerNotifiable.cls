//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Interface implemented by Apex classes that deliver notifications for the Nebula Logger notifications
 *              plugin. Each `LoggerNotificationService__c` record names an Apex class implementing this interface via
 *              its `NotifierApexClassName__c` field. The runtime instantiates the class dynamically for each recipient
 *              and hands it the matching records plus the recipient's connection configuration.
 */
public interface LoggerNotifiable {
  /**
   * @description Called by `LoggerNotifier` when one or more records match a rule that references this service.
   *              Implementations are responsible for delivering the notification (callout, email, etc.) and
   *              returning a `LoggerNotifiableResult` describing what happened. Returning `null` is treated
   *              the same as a bare success by the runtime.
   * @param context The details of the matched rule, recipient, and records.
   * @return A `LoggerNotifiableResult` describing the delivery outcome (status, external reference, HTTP details, etc.),
   *         or `null` to accept the runtime's default of "delivered with no additional detail".
   */
  LoggerNotifiableResult sendNotification(LoggerNotifiableContext context);
}
