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
    private static final List<ApexEmailNotification> CACHED_APEX_ERROR_RECIPIENTS {
        get {
            if (CACHED_APEX_ERROR_RECIPIENTS == null) {
                CACHED_APEX_ERROR_RECIPIENTS = queryApexErrrorRecipients();
            }
            return CACHED_APEX_ERROR_RECIPIENTS;
        }
        set;
    }

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

    /**
     * @description Sends an error email notification to the org's list of Apex Exception Email recipients,
     *              configured under Setup --> Email --> Apex Exception Email
     * @param  sobjectType The SObjectType of records being saved.
     * @param  saveResults The list of Database.SaveResult instances to use in the email.
     *                     If no errors are found in the provided list, then no email will be sent.
     */
    public static void sendErrorEmail(Schema.SObjectType sobjectType, List<Database.SaveResult> saveResults) {
        if (LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS == false || saveResults == null || saveResults.isEmpty()) {
            return;
        }

        List<String> errorMessages = getErrorMessages(saveResults);
        sendErrorEmail(sobjectType, errorMessages);
    }

    /**
     * @description Sends an error email notification to the org's list of Apex System.Exception Email recipients,
     *              configured under Setup --> Email --> Apex System.Exception Email
     * @param  sobjectType The SObjectType of records being saved.
     * @param  upsertResults The list of Database.UpsertResult instances to use in the email.
     *                     If no errors are found in the provided list, then no email will be sent.
     */
    public static void sendErrorEmail(Schema.SObjectType sobjectType, List<Database.UpsertResult> upsertResults) {
        if (LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS == false || upsertResults == null || upsertResults.isEmpty()) {
            return;
        }

        List<String> errorMessages = getErrorMessages(upsertResults);
        sendErrorEmail(sobjectType, errorMessages);
    }

    private static void sendErrorEmail(Schema.SObjectType sobjectType, List<String> errorMessages) {
        if (errorMessages.isEmpty()) {
            return;
        }

        if (CACHED_APEX_ERROR_RECIPIENTS.isEmpty() == true) {
            if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == true) {
                // One of a few limited places in the codebase (except tests) that should use System.debug()
                // The rest of the codebase should use a method in Logger.cls
                System.debug(System.LoggingLevel.WARN, 'Nebula Logger - no Apex email recipients configured, skipping sending email'); // NOPMD
            }
            return;
        }

        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        for (Schema.ApexEmailNotification notification : CACHED_APEX_ERROR_RECIPIENTS) {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setSubject(buildSubject(errorMessages));
            message.setHtmlBody(buildHtmlBody(sobjectType, errorMessages));

            if (notification.UserId != null) {
                message.setTargetObjectId(notification.UserId);
                message.setSaveAsActivity(false);
            } else if (String.isNotBlank(notification.Email) == true) {
                message.setToAddresses(new List<String>{ notification.Email });
            }
            messages.add(message);
        }
        sendEmail(messages);
    }

    private static String getErrorMessageFromDatabaseError(Database.Error error) {
        List<String> messageParts = new List<String>();

        // Add the status code
        messageParts.add('StatusCode: ' + error.getStatusCode());
        // Add the message
        messageParts.add('Message: ' + error.getMessage());
        // Add the fields if available
        List<String> fields = error.getFields();
        if (fields?.isEmpty() == false) {
            messageParts.add('Field(s): [' + String.join(fields, ', ') + ']');
        }

        return String.join(messageParts, ', ');
    }

    private static List<String> getErrorMessages(List<Database.SaveResult> saveResults) {
        List<String> errorMessages = new List<String>();
        for (Database.SaveResult result : saveResults) {
            if (result.isSuccess() == false) {
                for (Database.Error error : result.getErrors()) {
                    errorMessages.add(getErrorMessageFromDatabaseError(error));
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
                    errorMessages.add(getErrorMessageFromDatabaseError(error));
                }
            }
        }
        return errorMessages;
    }

    private static void sendEmail(List<Messaging.SingleEmailMessage> messages) {
        SENT_EMAILS.addAll(messages);
        if (IS_EMAIL_DELIVERABILITY_AVAILABLE) {
            List<Messaging.SendEmailResult> emailResults = System.Messaging.sendEmail(messages);

            if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == false) {
                return;
            } else if (emailResults.get(0).success == true) {
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

    private static String buildSubject(List<String> errorMessages) {
        String emailSubjectTemplate = 'Nebula Logger - Error Notification - {0} ({1})';
        List<Object> emailSubjectInputs = new List<Object>{
            LoggerEngineDataSelector.getInstance().getCachedOrganization().Name,
            LoggerEngineDataSelector.getInstance().getCachedOrganization().Id
        };
        return String.format(emailSubjectTemplate, emailSubjectInputs);
    }

    private static String buildHtmlBody(Schema.SObjectType sobjectType, List<String> errorMessages) {
        final String emailBodyTemplate = 'Logger failed to save {0} {1} records for {2} (User ID: {3})<br /><br />Errors:<ul>{4}</ul>';
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

    private static List<ApexEmailNotification> queryApexErrrorRecipients() {
        List<ApexEmailNotification> notifications = LogManagementDataSelector.getInstance().getCachedApexEmailNotifications();
        if (System.Test.isRunningTest()) {
            notifications.clear();
            notifications.addAll(MOCK_NOTIFICATIONS);
        }

        return notifications;
    }
}
