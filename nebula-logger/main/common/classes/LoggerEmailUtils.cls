//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Common
 * @description Builds and sends email notifications when internal exceptions occur within the logging system
 */
@SuppressWarnings('PMD.PropertyNamingConventions')
public without sharing class LoggerEmailUtils {
    private static final List<String> CACHED_APEX_ERROR_RECIPIENTS {
        get {
            if (CACHED_APEX_ERROR_RECIPIENTS == null) {
                CACHED_APEX_ERROR_RECIPIENTS = loadApexErrrorRecipients();
            }
            return CACHED_APEX_ERROR_RECIPIENTS;
        }
        set;
    }

    /**
     * @description Sends an error email notification to the org's list of Apex Exception Email recipients,
     *              configured under Setup --> Email --> Apex Exception Email
     * @param  saveResults The list of Database.SaveResult instances to use in the email.
     *                     If no errors are found in the provided list, then no email will be sent.
     */
    public static void sendErrorEmail(List<Database.SaveResult> saveResults) {
        if (LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS == false || saveResults == null || saveResults.isEmpty() == true) {
            return;
        }

        List<String> errorMessages = getErrorMessages(saveResults);
        sendErrorEmail(errorMessages);
    }

    /**
     * @description Sends an error email notification to the org's list of Apex Exception Email recipients,
     *              configured under Setup --> Email --> Apex Exception Email
     * @param  upsertResults The list of Database.UpsertResult instances to use in the email.
     *                     If no errors are found in the provided list, then no email will be sent.
     */
    public static void sendErrorEmail(List<Database.UpsertResult> upsertResults) {
        if (LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS == false || upsertResults == null || upsertResults.isEmpty() == true) {
            return;
        }

        List<String> errorMessages = getErrorMessages(upsertResults);
        sendErrorEmail(errorMessages);
    }

    private static void sendErrorEmail(List<String> errorMessages) {
        if (errorMessages.isEmpty() == true) {
            return;
        }
        System.debug(LoggingLevel.INFO, 'Logger - errorMessages: ' + errorMessages);
        if (CACHED_APEX_ERROR_RECIPIENTS.isEmpty() == true) {
            return;
        }
        final String formattedErrorMessages = String.join(errorMessages, '\n\t');
        System.debug(LoggingLevel.INFO, 'Logger - formattedErrorMessages: ' + formattedErrorMessages);

        final String emailBody = 'Logger failed to save 1 or more log entries for {0} (User ID: {1})\nError Messages:\n\t{2}';
        List<String> emailBodyInputs = new List<String>{ UserInfo.getUserName(), UserInfo.getUserId(), formattedErrorMessages };
        String formattedEmailBody = String.format(emailBody, emailBodyInputs);
        System.debug(LoggingLevel.INFO, 'Logger - formattedEmailBody: ' + formattedEmailBody);
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.ToAddresses = CACHED_APEX_ERROR_RECIPIENTS;
        message.Subject = 'Logger Error';
        message.PlainTextBody = formattedEmailBody;
        sendEmail(message);
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private static List<String> getErrorMessages(List<Database.SaveResult> saveResults) {
        System.debug(LoggingLevel.INFO, 'Logger - LogEntryEvent__e save results: ' + saveResults);
        List<String> errorMessages = new List<String>();
        for (Database.SaveResult result : saveResults) {
            if (result.isSuccess() == false) {
                for (Database.Error error : result.getErrors()) {
                    errorMessages.add(error.getMessage());
                }
            }
        }
        return errorMessages;
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private static List<String> getErrorMessages(List<Database.UpsertResult> upsertResults) {
        System.debug(LoggingLevel.INFO, 'Logger - LogEntryEvent__e upsert results: ' + upsertResults);
        List<String> errorMessages = new List<String>();
        for (Database.UpsertResult result : upsertResults) {
            if (result.isSuccess() == false) {
                for (Database.Error error : result.getErrors()) {
                    errorMessages.add(error.getMessage());
                }
            }
        }
        return errorMessages;
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private static void sendEmail(Messaging.SingleEmailMessage message) {
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>{ message };
        List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(messages);
        if (emailResults[0].success == true) {
            System.debug(LoggingLevel.INFO, 'Logger - The email was sent successfully');
        } else {
            System.debug(LoggingLevel.INFO, 'Logger - The email failed to send: ' + emailResults[0].errors[0].message);
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<String> loadApexErrrorRecipients() {
        List<String> apexErrrorRecipients = new List<String>();
        for (ApexEmailNotification notification : [SELECT Email, UserId FROM ApexEmailNotification WHERE Email != NULL OR User.IsActive = TRUE]) {
            if (notification.UserId != null) {
                apexErrrorRecipients.add(notification.UserId);
            } else {
                apexErrrorRecipients.addAll(notification.Email.split(';'));
            }
        }
        apexErrrorRecipients.add(UserInfo.getUserId());
        return apexErrrorRecipients;
    }
}
