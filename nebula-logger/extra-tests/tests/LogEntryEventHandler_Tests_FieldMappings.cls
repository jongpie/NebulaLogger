//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LogEntryEventHandler_Tests_FieldMappings {
  @IsTest
  static void it_should_use_field_mappings_on_logger_scenario_and_log_and_log_entry_when_mappings_have_been_configured() {
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
    LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.Log__c.SObjectType).IsEnabled__c = false;
    LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
    LoggerFieldMapper.setMock(
      new LoggerFieldMapping__mdt(
        DeveloperName = 'LoggerScenarioFieldMapping',
        IsEnabled__c = true,
        SourceSObjectType__c = Schema.LogEntryEvent__e.SObjectType.toString(),
        SourceField__c = Schema.LogEntryEvent__e.SomeLoggerScenarioField__c.toString(),
        TargetSObjectType__c = Schema.LoggerScenario__c.SObjectType.toString(),
        TargetField__c = Schema.LoggerScenario__c.SomeLoggerScenarioField__c.toString()
      )
    );
    LoggerFieldMapper.setMock(
      new LoggerFieldMapping__mdt(
        DeveloperName = 'LogFieldMapping',
        IsEnabled__c = true,
        SourceSObjectType__c = Schema.LogEntryEvent__e.SObjectType.toString(),
        SourceField__c = Schema.LogEntryEvent__e.SomeLogField__c.toString(),
        TargetSObjectType__c = Schema.Log__c.SObjectType.toString(),
        TargetField__c = Schema.Log__c.SomeLogField__c.toString()
      )
    );
    LoggerFieldMapper.setMock(
      new LoggerFieldMapping__mdt(
        DeveloperName = 'LogEntryFieldMapping',
        IsEnabled__c = true,
        SourceSObjectType__c = Schema.LogEntryEvent__e.SObjectType.toString(),
        SourceField__c = Schema.LogEntryEvent__e.SomeLogEntryField__c.toString(),
        TargetSObjectType__c = Schema.LogEntry__c.SObjectType.toString(),
        TargetField__c = Schema.LogEntry__c.SomeLogEntryField__c.toString()
      )
    );
    LogEntryEvent__e logEntryEvent = createLogEntryEvent();
    logEntryEvent.SomeLoggerScenarioField__c = 'Some value to map to LoggerScenario__c.SomeLoggerScenarioField__c';
    logEntryEvent.SomeLogField__c = 'Some value to map to Log__c.SomeLogField__c';
    logEntryEvent.SomeLogEntryField__c = 'Some value to map to LogEntry__c.SomeLogEntryField__c';

    Database.SaveResult saveResult = LoggerMockDataStore.getEventBus().publishRecord(logEntryEvent);
    LoggerMockDataStore.getEventBus().deliver(new LogEntryEventHandler());

    System.Assert.isTrue(saveResult.isSuccess(), saveResult.getErrors().toString());
    System.Assert.areEqual(
      1,
      LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntryEvent__e.SObjectType).size(),
      'Handler class should have executed one time for AFTER_INSERT'
    );
    // 2 scenarios should be created: 1 for TransactionScenario__c, and 1 for EntryScenario__c
    List<LoggerScenario__c> loggerScenarios = [SELECT Id, SomeLoggerScenarioField__c FROM LoggerScenario__c];
    System.Assert.areEqual(2, loggerScenarios.size());
    for (LoggerScenario__c loggerScenario : loggerScenarios) {
      System.Assert.areEqual(logEntryEvent.SomeLoggerScenarioField__c, loggerScenario.SomeLoggerScenarioField__c);
    }
    Log__c log = [SELECT Id, SomeLogField__c, (SELECT SomeLogEntryField__c FROM LogEntries__r) FROM Log__c];
    LogEntry__c logEntry = log.LogEntries__r.get(0);
    System.Assert.areEqual(logEntryEvent.SomeLogField__c, log.SomeLogField__c);
    System.Assert.areEqual(logEntryEvent.SomeLogEntryField__c, logEntry.SomeLogEntryField__c);
  }

  private static LogEntryEvent__e createLogEntryEvent() {
    // The data builder class handles populating field values, but for some fields,
    // certain values are expected (e.g., LoggedById__c should have a valid user ID),
    // so this method handles any additional manipulation to the field values
    LogEntryEvent__e logEntryEvent = (LogEntryEvent__e) LoggerMockDataCreator.createDataBuilder(Schema.LogEntryEvent__e.SObjectType)
      .populateAllFields()
      .getRecord();
    logEntryEvent.ImpersonatedById__c = null;
    logEntryEvent.LoggedById__c = System.UserInfo.getUserId();
    logEntryEvent.LoggingLevel__c = System.LoggingLevel.INFO.name();
    logEntryEvent.LoggingLevelOrdinal__c = System.LoggingLevel.INFO.ordinal();
    logEntryEvent.ProfileId__c = System.UserInfo.getProfileId();
    logEntryEvent.RecordCollectionSize__c = 1;
    logEntryEvent.RecordCollectionType__c = 'Single';
    logEntryEvent.RecordId__c = System.UserInfo.getUserId();
    logEntryEvent.TimestampString__c = String.valueOf(logEntryEvent.Timestamp__c.getTime());
    logEntryEvent.TransactionId__c = System.UUID.randomUUID().toString();
    logEntryEvent.UserLoggingLevel__c = System.LoggingLevel.INFO.name();
    logEntryEvent.UserLoggingLevelOrdinal__c = System.LoggingLevel.INFO.ordinal();
    logEntryEvent = (LogEntryEvent__e) LoggerMockDataCreator.setReadOnlyField(logEntryEvent, Schema.LogEntryEvent__e.EventUuid, System.UUID.randomUUID());

    return logEntryEvent;
  }
}
