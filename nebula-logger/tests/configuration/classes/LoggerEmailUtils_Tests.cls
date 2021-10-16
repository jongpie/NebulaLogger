//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest
private class LoggerEmailUtils_Tests {
    @IsTest
    static void it_should_send_email_notification_for_saveResult_errors() {
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (interntionally) fail
        List<Database.SaveResult> saveResultsWithErrors = Database.insert(new List<LogEntry__c>{ new LogEntry__c() }, false);
        LoggerEmailUtils.CACHED_APEX_ERROR_RECIPIENTS.add(UserInfo.getUserId());
        LoggerEmailUtils.sendErrorEmail(saveResultsWithErrors);

        System.assertEquals(1, Limits.getEmailInvocations(), 'Emails should be sent');
    }

    @IsTest
    static void it_should_send_email_notification_for_upsertResult_errors() {
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');

        // LogEntry__c requires a Log__c parent record, so inserting a LogEntry__c with no fields set will (interntionally) fail
        List<Database.UpsertResult> upsertResultsWithErrors = Database.upsert(new List<LogEntry__c>{ new LogEntry__c() }, false);
        LoggerEmailUtils.CACHED_APEX_ERROR_RECIPIENTS.add(UserInfo.getUserId());
        LoggerEmailUtils.sendErrorEmail(upsertResultsWithErrors);

        System.assertEquals(1, Limits.getEmailInvocations(), 'Emails should be sent');
    }
}
