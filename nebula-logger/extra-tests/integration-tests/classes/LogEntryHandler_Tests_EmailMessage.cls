//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LogEntryHandler_Tests_EmailMessage {
  @IsTest
  static void it_should_populate_related_record_name_field_on_log_entry_with_email_message_subject() {
    System.Assert.areEqual(
      false,
      Schema.EmailMessage.Subject.getDescribe().isNameField(),
      'This test assumes that EmailMessage does not use Subject as the object\'s display-name field'
    );
    Case cas = (Case) LoggerMockDataCreator.createDataBuilder(Schema.Case.SObjectType).populateRequiredFields().getRecord();
    insert cas;
    EmailMessage emailMessage = (EmailMessage) LoggerMockDataCreator.createDataBuilder(new EmailMessage(Subject = 'Some subject', ParentId = cas.Id))
      .populateRequiredFields()
      .getRecord();
    insert emailMessage;
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    insert log;
    LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = emailMessage.Id);

    insert logEntry;

    logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
    System.Assert.areEqual(emailMessage.Id, logEntry.RecordId__c);
    System.Assert.areEqual(emailMessage.Subject, logEntry.RecordName__c);
  }
}
