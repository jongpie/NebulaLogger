//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Builds and sends email notifications when internal exceptions occur within the logging system
 */
@SuppressWarnings('PMD.PropertyNamingConventions')
public without sharing class LoggerEmailUtils {
    @TestVisible
    private static final List<String> CACHED_APEX_ERROR_RECIPIENTS {
        get {
            if (CACHED_APEX_ERROR_RECIPIENTS == null) {
                CACHED_APEX_ERROR_RECIPIENTS = queryApexErrrorRecipients();
            }
            return CACHED_APEX_ERROR_RECIPIENTS;
        }
        set;
    }

    private static Boolean IS_EMAIL_DELIVERABILITY_ENABLED {
        get {
            if (IS_EMAIL_DELIVERABILITY_ENABLED == null) {
                try {
                    Messaging.reserveSingleEmailCapacity(1);
                    Messaging.reserveMassEmailCapacity(1);
                    IS_EMAIL_DELIVERABILITY_ENABLED = true;
                    return IS_EMAIL_DELIVERABILITY_ENABLED;
                } catch (System.NoAccessException e) {
                    IS_EMAIL_DELIVERABILITY_ENABLED = false;
                    return IS_EMAIL_DELIVERABILITY_ENABLED;
                }
            }
            return IS_EMAIL_DELIVERABILITY_ENABLED;
        }
        set;
    }

    @TestVisible
    private static final List<Messaging.SingleEmailMessage> SENT_EMAILS {
        get {
            if (SENT_EMAILS == null) {
                SENT_EMAILS = new List<Messaging.SingleEmailMessage>();
            }
            return SENT_EMAILS;
        }
        set;
    }

    /**
     * @description Sends an error email notification to the org's list of Apex Exception Email recipients,
     *              configured under Setup --> Email --> Apex Exception Email
     * @param  sobjectType The SObjectType of records being saved.
     * @param  saveResults The list of Database.SaveResult instances to use in the email.
     *                     If no errors are found in the provided list, then no email will be sent.
     */
    public static void sendErrorEmail(Schema.SObjectType sobjectType, List<Database.SaveResult> saveResults) {
        if (LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS == false || saveResults == null || saveResults.isEmpty() == true) {
            return;
        }

        List<String> errorMessages = getErrorMessages(saveResults);
        sendErrorEmail(sobjectType, errorMessages);
    }

    /**
     * @description Sends an error email notification to the org's list of Apex Exception Email recipients,
     *              configured under Setup --> Email --> Apex Exception Email
     * @param  sobjectType The SObjectType of records being saved.
     * @param  upsertResults The list of Database.UpsertResult instances to use in the email.
     *                     If no errors are found in the provided list, then no email will be sent.
     */
    public static void sendErrorEmail(Schema.SObjectType sobjectType, List<Database.UpsertResult> upsertResults) {
        if (LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS == false || upsertResults == null || upsertResults.isEmpty() == true) {
            return;
        }

        List<String> errorMessages = getErrorMessages(upsertResults);
        sendErrorEmail(sobjectType, errorMessages);
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private static void sendErrorEmail(Schema.SObjectType sobjectType, List<String> errorMessages) {
        if (errorMessages.isEmpty() == true) {
            return;
        }

        if (CACHED_APEX_ERROR_RECIPIENTS.isEmpty() == true) {
            System.debug(LoggingLevel.INFO, 'Logger - no Apex email recipients configured, skipping sending email');
            return;
        }

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setToAddresses(CACHED_APEX_ERROR_RECIPIENTS);
        message.setSubject(buildSubject(errorMessages));
        message.setHtmlBody(buildHtmlBody(sobjectType, errorMessages));
        sendEmail(message);
    }

    private static List<String> getErrorMessages(List<Database.SaveResult> saveResults) {
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

    private static List<String> getErrorMessages(List<Database.UpsertResult> upsertResults) {
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
        if (IS_EMAIL_DELIVERABILITY_ENABLED == true) {
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>{ message };
            List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(messages);
            SENT_EMAILS.add(message);
            if (emailResults[0].success == true) {
                System.debug(LoggingLevel.INFO, 'Logger - The email was sent successfully');
            } else {
                System.debug(LoggingLevel.INFO, 'Logger - The email failed to send: ' + emailResults[0].errors[0].message);
            }
        }
    }

    private static String buildSubject(List<String> errorMessages) {
        String emailSubjectTemplate = 'Logger - Error Notification - {0} ({1})';
        List<Object> emailSubjectInputs = new List<Object>{ LogEntryEventBuilder.CACHED_ORGANIZATION.Name, LogEntryEventBuilder.CACHED_ORGANIZATION.Id };
        return String.format(emailSubjectTemplate, emailSubjectInputs);
    }

    private static String buildHtmlBody(Schema.SObjectType sobjectType, List<String> errorMessages) {
        final String emailBodyTemplate = 'Logger failed to save {0} {1} records for {2} (User ID: {3})<br /><br />Error Messages:<ul>{4}</ul>';
        final String formattedErrorMessages = '<li>' + String.join(errorMessages, '</li><li>') + '</li>';
        List<Object> emailBodyInputs = new List<Object>{
            errorMessages.size(),
            sobjectType,
            LogEntryEventBuilder.CACHED_USER.Username,
            LogEntryEventBuilder.CACHED_USER.Id,
            formattedErrorMessages
        };
        return String.format(emailBodyTemplate, emailBodyInputs);
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<String> queryApexErrrorRecipients() {
        List<String> apexErrrorRecipients = new List<String>();
        for (ApexEmailNotification notification : [SELECT Email, UserId FROM ApexEmailNotification WHERE Email != NULL OR User.IsActive = TRUE]) {
            if (notification.UserId != null) {
                apexErrrorRecipients.add(notification.UserId);
            } else {
                apexErrrorRecipients.addAll(notification.Email.split(';'));
            }
        }
        return apexErrrorRecipients;
    }
}
