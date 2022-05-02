//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerEmailSender_Tests {
    @IsTest
    static void it_should_filter_apex_error_recipients() {
        ApexEmailNotification emailListNotification = new ApexEmailNotification(Email = 'hello@test.com;fake.person@not.real.com.biz', UserId = null);
        ApexEmailNotification userNotification = new ApexEmailNotification(Email = null, UserId = UserInfo.getUserId());
        ApexEmailNotification invalidNotification = new ApexEmailNotification(Email = null, UserId = null);
        LoggerEmailSender.MOCK_NOTIFICATIONS.addAll(new List<ApexEmailNotification>{ emailListNotification, userNotification, invalidNotification });

        List<String> returnedRecipients = LoggerEmailSender.CACHED_APEX_ERROR_RECIPIENTS;

        System.assertEquals(3, returnedRecipients.size(), 'Should have returned 3 recipients: 1 for the user ID, and 2 for the email addresses');
        for (String recipient : returnedRecipients) {
            Boolean matchesUserNotification = String.valueOf(userNotification.UserId) == recipient;
            Boolean matchesEmailListNotification = new Set<String>(emailListNotification.Email.split(';')).contains(recipient.trim());
            System.assertEquals(
                true,
                matchesUserNotification || matchesEmailListNotification,
                'Returned recipient ' +
                recipient +
                ' should match either the user notification or the email list notification\n' +
                JSON.serializePretty(LoggerEmailSender.MOCK_NOTIFICATIONS)
            );
        }
    }

    @IsTest
    static void it_should_send_email_notification_for_saveResult_errors_when_enabled() {
        LoggerEmailSender.CACHED_APEX_ERROR_RECIPIENTS.add(UserInfo.getUserId());
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent yet');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (intentionally) fail
        List<Database.SaveResult> saveResultsWithErrors = new List<Database.SaveResult>{ LoggerMockDataCreator.createDatabaseSaveResult(false) };
        LoggerEmailSender.sendErrorEmail(Schema.LogEntry__c.SObjectType, saveResultsWithErrors);

        System.assertEquals(
            true,
            LoggerEmailSender.SENT_EMAILS.get(0).getHtmlBody().contains(saveResultsWithErrors.get(0).errors.get(0).getMessage()),
            'Email message should contain SaveResult error message'
        );
        if (LoggerEmailSender.IS_EMAIL_DELIVERABILITY_ENABLED == true) {
            System.assertEquals(1, Limits.getEmailInvocations(), 'Email should have been sent');
        } else {
            System.assertEquals(0, Limits.getEmailInvocations(), 'Deliverability is not currently enabled');
        }
    }

    @IsTest
    static void it_should_not_send_email_notification_for_saveResult_errors_when_no_recipients_configured() {
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'SendErrorEmailNotifications', Value__c = 'true'));
        System.assertEquals(true, LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS);
        LoggerEmailSender.CACHED_APEX_ERROR_RECIPIENTS.clear();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent yet');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (intentionally) fail
        List<Database.SaveResult> saveResultsWithErrors = new List<Database.SaveResult>{ LoggerMockDataCreator.createDatabaseSaveResult(false) };
        LoggerEmailSender.sendErrorEmail(Schema.LogEntry__c.SObjectType, saveResultsWithErrors);

        System.assertEquals(true, LoggerEmailSender.SENT_EMAILS.isEmpty(), 'No email messages should have been generated');
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent');
    }

    @IsTest
    static void it_should_not_send_email_notification_for_saveResult_errors_when_disabled() {
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'SendErrorEmailNotifications', Value__c = 'false'));
        System.assertEquals(false, LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS);
        LoggerEmailSender.CACHED_APEX_ERROR_RECIPIENTS.add(UserInfo.getUserId());
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent yet');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (intentionally) fail
        List<Database.SaveResult> saveResultsWithErrors = new List<Database.SaveResult>{ LoggerMockDataCreator.createDatabaseSaveResult(false) };
        LoggerEmailSender.sendErrorEmail(Schema.LogEntry__c.SObjectType, saveResultsWithErrors);

        System.assertEquals(true, LoggerEmailSender.SENT_EMAILS.isEmpty(), 'No email messages should have been generated');
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent');
    }

    @IsTest
    static void it_should_send_email_notification_for_upsertResult_errors_when_enabled() {
        LoggerEmailSender.CACHED_APEX_ERROR_RECIPIENTS.add(UserInfo.getUserId());
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent yet');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (intentionally) fail
        List<Database.UpsertResult> upsertResultsWithErrors = Database.upsert(new List<LogEntry__c>{ new LogEntry__c() }, false);
        LoggerEmailSender.sendErrorEmail(Schema.LogEntry__c.SObjectType, upsertResultsWithErrors);

        System.assertEquals(
            true,
            LoggerEmailSender.SENT_EMAILS.get(0).getHtmlBody().contains(upsertResultsWithErrors.get(0).errors.get(0).getMessage()),
            'Email message should contain UpsertResult error message'
        );
        if (LoggerEmailSender.IS_EMAIL_DELIVERABILITY_ENABLED == true) {
            System.assertEquals(1, Limits.getEmailInvocations(), 'Email should have been sent');
        } else {
            System.assertEquals(0, Limits.getEmailInvocations(), 'Deliverability is not currently enabled');
        }
    }

    @IsTest
    static void it_should_not_send_email_notification_for_upsertResult_errors_when_no_recipients_configured() {
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'SendErrorEmailNotifications', Value__c = 'true'));
        System.assertEquals(true, LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS);
        LoggerEmailSender.CACHED_APEX_ERROR_RECIPIENTS.clear();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent yet');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (intentionally) fail
        List<Database.UpsertResult> upsertResultsWithErrors = Database.upsert(new List<LogEntry__c>{ new LogEntry__c() }, false);
        LoggerEmailSender.sendErrorEmail(Schema.LogEntry__c.SObjectType, upsertResultsWithErrors);

        System.assertEquals(true, LoggerEmailSender.SENT_EMAILS.isEmpty(), 'No email messages should have been generated');
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent');
    }

    @IsTest
    static void it_should_not_send_email_notification_for_upsertResult_errors_when_disabled() {
        LoggerTestConfigurator.setMock(new LoggerParameter__mdt(DeveloperName = 'SendErrorEmailNotifications', Value__c = 'false'));
        System.assertEquals(false, LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS);
        LoggerEmailSender.CACHED_APEX_ERROR_RECIPIENTS.add(UserInfo.getUserId());
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent yet');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (intentionally) fail
        List<Database.UpsertResult> upsertResultsWithErrors = Database.upsert(new List<LogEntry__c>{ new LogEntry__c() }, false);
        LoggerEmailSender.sendErrorEmail(Schema.LogEntry__c.SObjectType, upsertResultsWithErrors);

        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent');
        System.assertEquals(true, LoggerEmailSender.SENT_EMAILS.isEmpty(), 'No email messages should have been generated');
    }
}
