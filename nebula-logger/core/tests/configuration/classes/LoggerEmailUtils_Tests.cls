//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest
private class LoggerEmailUtils_Tests {
    @IsTest
    static void it_should_send_email_notification_for_saveResult_errors_when_enabled() {
        LoggerEmailUtils.CACHED_APEX_ERROR_RECIPIENTS.add(UserInfo.getUserId());
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent yet');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (interntionally) fail
        List<Database.SaveResult> saveResultsWithErrors = Database.insert(new List<LogEntry__c>{ new LogEntry__c() }, false);
        LoggerEmailUtils.sendErrorEmail(Schema.LogEntry__c.SObjectType, saveResultsWithErrors);

        System.assertEquals(1, Limits.getEmailInvocations(), 'Email should have been sent');
        System.assertEquals(
            true,
            LoggerEmailUtils.SENT_EMAILS.get(0).getHtmlBody().contains(saveResultsWithErrors.get(0).errors.get(0).getMessage()),
            'Email message should contain SaveResult error message'
        );
    }

    @IsTest
    static void it_should_not_send_email_notification_for_saveResult_errors_when_no_recipients_configured() {
        LoggerParameter.setMockParameter(new LoggerParameter__mdt(DeveloperName = 'SendErrorEmailNotifications', Value__c = 'true'));
        System.assertEquals(true, LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS);
        LoggerEmailUtils.CACHED_APEX_ERROR_RECIPIENTS.clear();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent yet');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (interntionally) fail
        List<Database.SaveResult> saveResultsWithErrors = Database.insert(new List<LogEntry__c>{ new LogEntry__c() }, false);
        LoggerEmailUtils.sendErrorEmail(Schema.LogEntry__c.SObjectType, saveResultsWithErrors);

        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent');
        System.assertEquals(true, LoggerEmailUtils.SENT_EMAILS.isEmpty(), 'No email messages should have been generated');
    }

    @IsTest
    static void it_should_not_send_email_notification_for_saveResult_errors_when_disabled() {
        LoggerParameter.setMockParameter(new LoggerParameter__mdt(DeveloperName = 'SendErrorEmailNotifications', Value__c = 'false'));
        System.assertEquals(false, LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS);
        LoggerEmailUtils.CACHED_APEX_ERROR_RECIPIENTS.add(UserInfo.getUserId());
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent yet');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (interntionally) fail
        List<Database.SaveResult> saveResultsWithErrors = Database.insert(new List<LogEntry__c>{ new LogEntry__c() }, false);
        LoggerEmailUtils.sendErrorEmail(Schema.LogEntry__c.SObjectType, saveResultsWithErrors);

        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent');
        System.assertEquals(true, LoggerEmailUtils.SENT_EMAILS.isEmpty(), 'No email messages should have been generated');
    }

    @IsTest
    static void it_should_send_email_notification_for_upsertResult_errors_when_enabled() {
        LoggerEmailUtils.CACHED_APEX_ERROR_RECIPIENTS.add(UserInfo.getUserId());
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent yet');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (interntionally) fail
        List<Database.UpsertResult> upsertResultsWithErrors = Database.upsert(new List<LogEntry__c>{ new LogEntry__c() }, false);
        LoggerEmailUtils.sendErrorEmail(Schema.LogEntry__c.SObjectType, upsertResultsWithErrors);

        System.assertEquals(1, Limits.getEmailInvocations(), 'Email should have been sent');
        System.assertEquals(
            true,
            LoggerEmailUtils.SENT_EMAILS.get(0).getHtmlBody().contains(upsertResultsWithErrors.get(0).errors.get(0).getMessage()),
            'Email message should contain UpsertResult error message'
        );
    }

    @IsTest
    static void it_should_not_send_email_notification_for_upsertResult_errors_when_no_recipients_configured() {
        LoggerParameter.setMockParameter(new LoggerParameter__mdt(DeveloperName = 'SendErrorEmailNotifications', Value__c = 'true'));
        System.assertEquals(true, LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS);
        LoggerEmailUtils.CACHED_APEX_ERROR_RECIPIENTS.clear();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent yet');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (interntionally) fail
        List<Database.UpsertResult> upsertResultsWithErrors = Database.upsert(new List<LogEntry__c>{ new LogEntry__c() }, false);
        LoggerEmailUtils.sendErrorEmail(Schema.LogEntry__c.SObjectType, upsertResultsWithErrors);

        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent');
        System.assertEquals(true, LoggerEmailUtils.SENT_EMAILS.isEmpty(), 'No email messages should have been generated');
    }

    @IsTest
    static void it_should_not_send_email_notification_for_upsertResult_errors_when_disabled() {
        LoggerParameter.setMockParameter(new LoggerParameter__mdt(DeveloperName = 'SendErrorEmailNotifications', Value__c = 'false'));
        System.assertEquals(false, LoggerParameter.SEND_ERROR_EMAIL_NOTIFICATIONS);
        LoggerEmailUtils.CACHED_APEX_ERROR_RECIPIENTS.add(UserInfo.getUserId());
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent yet');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (interntionally) fail
        List<Database.UpsertResult> upsertResultsWithErrors = Database.upsert(new List<LogEntry__c>{ new LogEntry__c() }, false);
        LoggerEmailUtils.sendErrorEmail(Schema.LogEntry__c.SObjectType, upsertResultsWithErrors);

        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should have been sent');
        System.assertEquals(true, LoggerEmailUtils.SENT_EMAILS.isEmpty(), 'No email messages should have been generated');
    }
}
