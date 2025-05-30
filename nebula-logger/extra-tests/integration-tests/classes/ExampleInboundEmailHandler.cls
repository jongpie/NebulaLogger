//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @description Example inbound email handler class
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class ExampleInboundEmailHandler implements Messaging.InboundEmailHandler {
  @TestVisible
  private static String logEntryMessage = 'Testing logging from InboundEmailHandler';

  /**
   * @description Required by the InboundEmailHandler interface, this method contains the
   * logic executed when an email comes in.
   * @param email - The email to act upon
   * @param env The envelope of the incoming email
   * @return The result of the inbound email and email handling.
   */
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env) {
    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
    try {
      String nullString = null;
      nullString.length();
    } catch (System.Exception apexException) {
      Logger.error(logEntryMessage, apexException);
    } finally {
      result.success = true;
      Logger.info('Logger buffer size before save: ' + Logger.getBufferSize());
      Logger.saveLog();
      Logger.info('Logger buffer size after save: ' + Logger.getBufferSize());
    }

    return result;
  }
}
