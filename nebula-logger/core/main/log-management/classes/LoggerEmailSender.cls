//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Builds and sends email notifications when internal exceptions occur within the logging system
 */
@SuppressWarnings('PMD.PropertyNamingConventions')
public without sharing class LoggerEmailSender {
    @TestVisible
    private static final List<ApexEmailNotification> MOCK_NOTIFICATIONS = new List<ApexEmailNotification>();
    @TestVisible
    private static final List<Messaging.SingleEmailMessage> SENT_EMAILS = new List<Messaging.SingleEmailMessage>();

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

    @TestVisible
    private static Boolean IS_EMAIL_DELIVERABILITY_ENABLED {
        get {
            if (IS_EMAIL_DELIVERABILITY_ENABLED == null) {
                try {
                    System.Messaging.reserveSingleEmailCapacity(1);
                    System.Messaging.reserveMassEmailCapacity(1);
                    IS_EMAIL_DELIVERABILITY_ENABLED = true;
                } catch (System.NoAccessException e) {
                    IS_EMAIL_DELIVERABILITY_ENABLED = false;
                }
            }
            return IS_EMAIL_DELIVERABILITY_ENABLED;
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

    private static void sendErrorEmail(Schema.SObjectType sobjectType, List<String> errorMessages) {
        if (errorMessages.isEmpty() == true) {
            return;
        }

        if (CACHED_APEX_ERROR_RECIPIENTS.isEmpty() == true) {
            if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == true) {
                Logger.info('Logger - no Apex email recipients configured, skipping sending email');
            }
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

    private static void sendEmail(Messaging.SingleEmailMessage message) {
        SENT_EMAILS.add(message);
        if (IS_EMAIL_DELIVERABILITY_ENABLED == true) {
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>{ message };
            List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(messages);

            if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == false) {
                return;
            } else if (emailResults.get(0).success == true) {
                Logger.info('Logger - The email was sent successfully');
            } else {
                Logger.warn('Logger - The email failed to send: ' + emailResults.get(0).errors.get(0).message);
            }
        }
    }

    private static String buildSubject(List<String> errorMessages) {
        String emailSubjectTemplate = 'Logger - Error Notification - {0} ({1})';
        List<Object> emailSubjectInputs = new List<Object>{
            LoggerEngineDataSelector.getInstance().getCachedOrganization().Name,
            LoggerEngineDataSelector.getInstance().getCachedOrganization().Id
        };
        return String.format(emailSubjectTemplate, emailSubjectInputs);
    }

    private static String buildHtmlBody(Schema.SObjectType sobjectType, List<String> errorMessages) {
        final String emailBodyTemplate = 'Logger failed to save {0} {1} records for {2} (User ID: {3})<br /><br />Error Messages:<ul>{4}</ul>';
        final String formattedErrorMessages = '<li>' + String.join(errorMessages, '</li><li>') + '</li>';
        List<Object> emailBodyInputs = new List<Object>{
            errorMessages.size(),
            sobjectType,
            LoggerEngineDataSelector.getInstance().getCachedUser().Username,
            LoggerEngineDataSelector.getInstance().getCachedUser().Id,
            formattedErrorMessages
        };
        return String.format(emailBodyTemplate, emailBodyInputs);
    }

    private static List<String> queryApexErrrorRecipients() {
        List<String> apexErrrorRecipients = new List<String>();
        List<ApexEmailNotification> notifications = LogManagementDataSelector.getInstance().getCachedApexEmailNotifications();
        if (System.Test.isRunningTest() == true) {
            notifications.clear();
            notifications.addAll(MOCK_NOTIFICATIONS);
        }

        for (ApexEmailNotification notification : notifications) {
            if (notification.UserId != null) {
                apexErrrorRecipients.add(notification.UserId);
            } else if (String.isNotBlank(notification.Email) == true) {
                apexErrrorRecipients.addAll(notification.Email.split(';'));
            }
        }
        return apexErrrorRecipients;
    }
}
