//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest
private class LogEntryHandler_Tests_Integration {
    @IsTest
    static void it_should_populate_related_record_name_field_on_log_entry_with_email_message_subject() {
        System.assertEquals(
            false,
            Schema.EmailMessage.Subject.getDescribe().isNameField(),
            'This test assumes that EmailMessage does not use Subject as the object\'s display-name field'
        );
        Case cas = (Case) LoggerTestMockCreator.createDataGenerator(Schema.Case.SObjectType).populateRequiredFields().getRecord();
        insert cas;
        EmailMessage emailMessage = (EmailMessage) LoggerTestMockCreator.createDataGenerator(Schema.EmailMessage.SObjectType)
            .populateRequiredFields()
            .getRecord();
        emailMessage.Subject = 'Some subject';
        emailMessage.ParentId = cas.Id;
        insert emailMessage;
        Log__c log = (Log__c) LoggerTestMockCreator.createDataGenerator(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert log;
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = emailMessage.Id);

        insert logEntry;

        logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
        System.assertEquals(emailMessage.Id, logEntry.RecordId__c);
        System.assertEquals(emailMessage.Subject, logEntry.RecordName__c);
    }
}
