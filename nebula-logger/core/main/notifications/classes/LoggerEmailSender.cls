//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Builds and sends email notifications when internal exceptions occur within the logging system
 */
@SuppressWarnings('PMD.PropertyNamingConventions')
public without sharing virtual class LoggerEmailSender {
    @TestVisible
    private static final List<Messaging.SingleEmailMessage> SENT_EMAILS = new List<Messaging.SingleEmailMessage>();

    @TestVisible
    private static Boolean IS_EMAIL_DELIVERABILITY_AVAILABLE {
        get {
            if (IS_EMAIL_DELIVERABILITY_AVAILABLE == null) {
                try {
                    System.Messaging.reserveSingleEmailCapacity(1);
                    IS_EMAIL_DELIVERABILITY_AVAILABLE = true;
                } catch (System.NoAccessException e) {
                    // Exception thrown when email deliverability is disabled
                    IS_EMAIL_DELIVERABILITY_AVAILABLE = false;
                } catch (System.HandledException handledException) {
                    // Exception thrown when org limits are reached
                    IS_EMAIL_DELIVERABILITY_AVAILABLE = false;
                }
            }
            return IS_EMAIL_DELIVERABILITY_AVAILABLE;
        }
        set;
    }

    public void sendEmail(List<Messaging.SingleEmailMessage> messages) {
        SENT_EMAILS.addAll(messages);
        if (IS_EMAIL_DELIVERABILITY_AVAILABLE) {
            List<Messaging.SendEmailResult> emailResults = System.Messaging.sendEmail(messages);

            if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == false) {
                return;
            } else if (emailResults.get(0).success) {
                // One of a few limited places in the codebase (except tests) that should use System.debug()
                // The rest of the codebase should use a method in Logger.cls
                System.debug(System.LoggingLevel.INFO, 'Nebula Logger - The email was sent successfully'); // NOPMD
            } else {
                // One of a few limited places in the codebase (except tests) that should use System.debug()
                // The rest of the codebase should use a method in Logger.cls
                System.debug(System.LoggingLevel.WARN, 'Nebula Logger - The email failed to send: ' + emailResults.get(0).errors.get(0).message); // NOPMD
            }
        }
    }
}
