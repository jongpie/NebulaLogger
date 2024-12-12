//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LogEntryHandler_Tests {
  private static final Boolean IS_OMNISTUDIO_ENABLED = System.Type.forName('Schema.OmniProcess') != null;

  @TestSetup
  static void setupData() {
    LoggerSObjectHandler.shouldExecute(false);
    Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
    insert log;
    System.Test.setCreatedDate(log.Id, System.Datetime.now().addDays(-8));
  }

  @IsTest
  static void it_should_return_the_logEntry_sobjectType() {
    System.Assert.areEqual(Schema.LogEntry__c.SObjectType, new LogEntryHandler().getSObjectType());
  }

  @IsTest
  static void it_should_not_run_when_disabled_via_configuration() {
    LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
    LoggerTestConfigurator.getSObjectHandlerConfiguration(Schema.LogEntry__c.SObjectType).IsEnabled__c = false;
    Log__c log = [SELECT Id FROM Log__c LIMIT 1];
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id);
    LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

    LoggerDataStore.getDatabase().insertRecord(logEntry);

    System.Assert.areEqual(0, LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(), 'Handler class should not have executed');
  }

  @IsTest
  static void it_should_save_log_entry_without_related_record_id() {
    Log__c log = [SELECT Id FROM Log__c LIMIT 1];
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = null);

    LoggerDataStore.getDatabase().insertRecord(logEntry);

    System.Assert.areEqual(
      2,
      LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
      'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
    );
    logEntry = [SELECT Id, RecordId__c FROM LogEntry__c WHERE Id = :logEntry.Id];
    System.Assert.isNull(logEntry.RecordId__c);
  }

  @IsTest
  static void it_should_populate_related_record_fields_on_log_entry_with_related_user_record_id() {
    Log__c log = [SELECT Id FROM Log__c LIMIT 1];
    Schema.User currentUser = [SELECT Id, Username FROM User WHERE Id = :System.UserInfo.getUserId()];
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = currentUser.Id);

    LoggerDataStore.getDatabase().insertRecord(logEntry);

    System.Assert.areEqual(
      2,
      LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
      'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
    );
    logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
    System.Assert.areEqual(currentUser.Id, logEntry.RecordId__c);
    System.Assert.areEqual(currentUser.Username, logEntry.RecordName__c);
  }

  @IsTest
  static void it_should_populate_related_record_fields_on_log_entry_with_related_profile_record_id() {
    Log__c log = [SELECT Id FROM Log__c LIMIT 1];
    Schema.Profile currentProfile = [SELECT Id, Name FROM Profile WHERE Id = :System.UserInfo.getProfileId()];
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = currentProfile.Id);

    LoggerDataStore.getDatabase().insertRecord(logEntry);

    System.Assert.areEqual(
      2,
      LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
      'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
    );
    logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
    System.Assert.areEqual(currentProfile.Id, logEntry.RecordId__c);
    System.Assert.areEqual(currentProfile.Name, logEntry.RecordName__c);
  }

  @IsTest
  static void it_should_not_populate_related_record_fields_on_log_entry_with_related_template_standard_object_record_id() {
    Log__c log = [SELECT Id FROM Log__c LIMIT 1];
    Id templateSObjectRecordId = LoggerMockDataCreator.createId(Schema.CaseComment.SObjectType);
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = templateSObjectRecordId);

    LoggerDataStore.getDatabase().insertRecord(logEntry);

    System.Assert.areEqual(
      2,
      LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
      'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
    );
    logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
    System.Assert.areEqual(templateSObjectRecordId, logEntry.RecordId__c);
    System.Assert.isNull(logEntry.RecordName__c);
  }

  @IsTest
  static void it_should_not_populate_related_record_fields_on_log_entry_when_disabled_via_logger_parameter() {
    Log__c log = [SELECT Id FROM Log__c LIMIT 1];
    Schema.User currentUser = [SELECT Id, Username FROM User WHERE Id = :System.UserInfo.getUserId()];
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, RecordId__c = currentUser.Id);
    LoggerParameter.setMock(new LoggerParameter__mdt(DeveloperName = 'QueryRelatedRecordData', Value__c = String.valueOf(false)));

    LoggerDataStore.getDatabase().insertRecord(logEntry);

    System.Assert.areEqual(
      2,
      LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
      'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
    );
    logEntry = [SELECT Id, RecordId__c, RecordName__c FROM LogEntry__c WHERE Id = :logEntry.Id];
    System.Assert.areEqual(currentUser.Id, logEntry.RecordId__c);
    System.Assert.isNull(logEntry.RecordName__c);
  }

  @IsTest
  static void it_should_set_hasDatabaseResultJson_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(DatabaseResultJson__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(DatabaseResultJson__c = null);
    System.Assert.isNotNull(matchingLogEntry.DatabaseResultJson__c);
    System.Assert.isNull(nonMatchingLogEntry.DatabaseResultJson__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasDatabaseResultJson__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasDatabaseResultJson__c);
  }

  @IsTest
  static void it_should_set_hasDatabaseResultJson_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(DatabaseResultJson__c = 'some value', Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(DatabaseResultJson__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.DatabaseResultJson__c);
    System.Assert.isNull(nonMatchingLogEntry.DatabaseResultJson__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasDatabaseResultJson__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasDatabaseResultJson__c);
  }

  @IsTest
  static void it_should_set_hasExceptionStackTrace_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(ExceptionStackTrace__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(ExceptionStackTrace__c = null);
    System.Assert.isNotNull(matchingLogEntry.ExceptionStackTrace__c);
    System.Assert.isNull(nonMatchingLogEntry.ExceptionStackTrace__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasExceptionStackTrace__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasExceptionStackTrace__c);
  }

  @IsTest
  static void it_should_set_hasExceptionStackTrace_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(ExceptionStackTrace__c = 'some value', Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(ExceptionStackTrace__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.ExceptionStackTrace__c);
    System.Assert.isNull(nonMatchingLogEntry.ExceptionStackTrace__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasExceptionStackTrace__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasExceptionStackTrace__c);
  }

  @IsTest
  static void it_should_set_hasHttpRequestBody_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(HttpRequestBody__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpRequestBody__c = null);
    System.Assert.isNotNull(matchingLogEntry.HttpRequestBody__c);
    System.Assert.isNull(nonMatchingLogEntry.HttpRequestBody__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasHttpRequestBody__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasHttpRequestBody__c);
  }

  @IsTest
  static void it_should_set_hasHttpRequestBody_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(HttpRequestBody__c = 'some value', Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpRequestBody__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.HttpRequestBody__c);
    System.Assert.isNull(nonMatchingLogEntry.HttpRequestBody__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasHttpRequestBody__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasHttpRequestBody__c);
  }

  @IsTest
  static void it_should_set_hasHttpRequestHeaderKeys_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(HttpRequestHeaderKeys__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpRequestHeaderKeys__c = null);
    System.Assert.isNotNull(matchingLogEntry.HttpRequestHeaderKeys__c);
    System.Assert.isNull(nonMatchingLogEntry.HttpRequestHeaderKeys__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasHttpRequestHeaderKeys__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasHttpRequestHeaderKeys__c);
  }

  @IsTest
  static void it_should_set_hasHttpRequestHeaderKeys_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(
      HttpRequestHeaderKeys__c = 'some value',
      Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType)
    );
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpRequestHeaderKeys__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.HttpRequestHeaderKeys__c);
    System.Assert.isNull(nonMatchingLogEntry.HttpRequestHeaderKeys__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasHttpRequestHeaderKeys__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasHttpRequestHeaderKeys__c);
  }

  @IsTest
  static void it_should_set_hasHttpRequestHeaders_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(HttpRequestHeaders__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpRequestHeaders__c = null);
    System.Assert.isNotNull(matchingLogEntry.HttpRequestHeaders__c);
    System.Assert.isNull(nonMatchingLogEntry.HttpRequestHeaders__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasHttpRequestHeaders__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasHttpRequestHeaders__c);
  }

  @IsTest
  static void it_should_set_hasHttpRequestHeaders_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(HttpRequestHeaders__c = 'some value', Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpRequestHeaders__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.HttpRequestHeaders__c);
    System.Assert.isNull(nonMatchingLogEntry.HttpRequestHeaders__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasHttpRequestHeaders__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasHttpRequestHeaders__c);
  }

  @IsTest
  static void it_should_set_hasHttpResponseBody_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(HttpResponseBody__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpResponseBody__c = null);
    System.Assert.isNotNull(matchingLogEntry.HttpResponseBody__c);
    System.Assert.isNull(nonMatchingLogEntry.HttpResponseBody__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasHttpResponseBody__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasHttpResponseBody__c);
  }

  @IsTest
  static void it_should_set_hasHttpResponseBody_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(HttpResponseBody__c = 'some value', Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpResponseBody__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.HttpResponseBody__c);
    System.Assert.isNull(nonMatchingLogEntry.HttpResponseBody__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasHttpResponseBody__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasHttpResponseBody__c);
  }

  @IsTest
  static void it_should_set_hasHttpResponseHeaderKeys_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(HttpResponseHeaderKeys__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpResponseHeaderKeys__c = null);
    System.Assert.isNotNull(matchingLogEntry.HttpResponseHeaderKeys__c);
    System.Assert.isNull(nonMatchingLogEntry.HttpResponseHeaderKeys__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasHttpResponseHeaderKeys__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasHttpResponseHeaderKeys__c);
  }

  @IsTest
  static void it_should_set_hasHttpResponseHeaderKeys_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(
      HttpResponseHeaderKeys__c = 'some value',
      Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType)
    );
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpResponseHeaderKeys__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.HttpResponseHeaderKeys__c);
    System.Assert.isNull(nonMatchingLogEntry.HttpResponseHeaderKeys__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasHttpResponseHeaderKeys__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasHttpResponseHeaderKeys__c);
  }

  @IsTest
  static void it_should_set_hasHttpResponseHeaders_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(HttpResponseHeaders__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpResponseHeaders__c = null);
    System.Assert.isNotNull(matchingLogEntry.HttpResponseHeaders__c);
    System.Assert.isNull(nonMatchingLogEntry.HttpResponseHeaders__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasHttpResponseHeaders__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasHttpResponseHeaders__c);
  }

  @IsTest
  static void it_should_set_hasHttpResponseHeaders_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(HttpResponseHeaders__c = 'some value', Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpResponseHeaders__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.HttpResponseHeaders__c);
    System.Assert.isNull(nonMatchingLogEntry.HttpResponseHeaders__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasHttpResponseHeaders__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasHttpResponseHeaders__c);
  }

  @IsTest
  static void it_should_set_hasRestRequestBody_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(RestRequestBody__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RestRequestBody__c = null);
    System.Assert.isNotNull(matchingLogEntry.RestRequestBody__c);
    System.Assert.isNull(nonMatchingLogEntry.RestRequestBody__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRestRequestBody__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRestRequestBody__c);
  }

  @IsTest
  static void it_should_set_hasRestRequestBody_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(RestRequestBody__c = 'some value', Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RestRequestBody__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.RestRequestBody__c);
    System.Assert.isNull(nonMatchingLogEntry.RestRequestBody__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRestRequestBody__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRestRequestBody__c);
  }

  @IsTest
  static void it_should_set_hasRestRequestHeaderKeys_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(RestRequestHeaderKeys__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RestRequestHeaderKeys__c = null);
    System.Assert.isNotNull(matchingLogEntry.RestRequestHeaderKeys__c);
    System.Assert.isNull(nonMatchingLogEntry.RestRequestHeaderKeys__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRestRequestHeaderKeys__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRestRequestHeaderKeys__c);
  }

  @IsTest
  static void it_should_set_hasRestRequestHeaderKeys_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(
      RestRequestHeaderKeys__c = 'some value',
      Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType)
    );
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RestRequestHeaderKeys__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.RestRequestHeaderKeys__c);
    System.Assert.isNull(nonMatchingLogEntry.RestRequestHeaderKeys__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRestRequestHeaderKeys__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRestRequestHeaderKeys__c);
  }

  @IsTest
  static void it_should_set_hasRestRequestHeaders_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(RestRequestHeaders__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RestRequestHeaders__c = null);
    System.Assert.isNotNull(matchingLogEntry.RestRequestHeaders__c);
    System.Assert.isNull(nonMatchingLogEntry.RestRequestHeaders__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRestRequestHeaders__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRestRequestHeaders__c);
  }

  @IsTest
  static void it_should_set_hasRestRequestHeaders_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(RestRequestHeaders__c = 'some value', Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RestRequestHeaders__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.RestRequestHeaders__c);
    System.Assert.isNull(nonMatchingLogEntry.RestRequestHeaders__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRestRequestHeaders__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRestRequestHeaders__c);
  }

  @IsTest
  static void it_should_set_hasRestResponseBody_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(RestResponseBody__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RestResponseBody__c = null);
    System.Assert.isNotNull(matchingLogEntry.RestResponseBody__c);
    System.Assert.isNull(nonMatchingLogEntry.RestResponseBody__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRestResponseBody__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRestResponseBody__c);
  }

  @IsTest
  static void it_should_set_hasRestResponseBody_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(RestResponseBody__c = 'some value', Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RestResponseBody__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.RestResponseBody__c);
    System.Assert.isNull(nonMatchingLogEntry.RestResponseBody__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRestResponseBody__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRestResponseBody__c);
  }

  @IsTest
  static void it_should_set_hasRestResponseHeaderKeys_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(RestResponseHeaderKeys__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RestResponseHeaderKeys__c = null);
    System.Assert.isNotNull(matchingLogEntry.RestResponseHeaderKeys__c);
    System.Assert.isNull(nonMatchingLogEntry.RestResponseHeaderKeys__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRestResponseHeaderKeys__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRestResponseHeaderKeys__c);
  }

  @IsTest
  static void it_should_set_hasRestResponseHeaderKeys_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(
      RestResponseHeaderKeys__c = 'some value',
      Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType)
    );
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RestResponseHeaderKeys__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.RestResponseHeaderKeys__c);
    System.Assert.isNull(nonMatchingLogEntry.RestResponseHeaderKeys__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRestResponseHeaderKeys__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRestResponseHeaderKeys__c);
  }

  @IsTest
  static void it_should_set_hasRestResponseHeaders_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(RestResponseHeaders__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RestResponseHeaders__c = null);
    System.Assert.isNotNull(matchingLogEntry.RestResponseHeaders__c);
    System.Assert.isNull(nonMatchingLogEntry.RestResponseHeaders__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRestResponseHeaders__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRestResponseHeaders__c);
  }

  @IsTest
  static void it_should_set_hasRestResponseHeaders_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(RestResponseHeaders__c = 'some value', Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RestResponseHeaders__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.RestResponseHeaders__c);
    System.Assert.isNull(nonMatchingLogEntry.RestResponseHeaders__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRestResponseHeaders__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRestResponseHeaders__c);
  }

  @IsTest
  static void it_should_set_hasInlineTags_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(Tags__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(Tags__c = null);
    System.Assert.isNotNull(matchingLogEntry.Tags__c);
    System.Assert.isNull(nonMatchingLogEntry.Tags__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasInlineTags__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasInlineTags__c);
  }

  @IsTest
  static void it_should_set_hasInlineTags_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(Tags__c = 'some value', Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(Tags__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.Tags__c);
    System.Assert.isNull(nonMatchingLogEntry.Tags__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasInlineTags__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasInlineTags__c);
  }

  @IsTest
  static void it_should_set_hasRecordJson_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(RecordJson__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RecordJson__c = null);
    System.Assert.isNotNull(matchingLogEntry.RecordJson__c);
    System.Assert.isNull(nonMatchingLogEntry.RecordJson__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRecordJson__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRecordJson__c);
  }

  @IsTest
  static void it_should_set_hasRecordJson_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(RecordJson__c = 'some value', Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(RecordJson__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.RecordJson__c);
    System.Assert.isNull(nonMatchingLogEntry.RecordJson__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasRecordJson__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasRecordJson__c);
  }

  @IsTest
  static void it_should_set_hasStackTrace_on_before_insert() {
    LogEntry__c matchingLogEntry = new LogEntry__c(StackTrace__c = 'some value');
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(StackTrace__c = null);
    System.Assert.isNotNull(matchingLogEntry.StackTrace__c);
    System.Assert.isNull(nonMatchingLogEntry.StackTrace__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_INSERT,
      new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasStackTrace__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasStackTrace__c);
  }

  @IsTest
  static void it_should_set_hasStackTrace_on_before_update() {
    LogEntry__c matchingLogEntry = new LogEntry__c(StackTrace__c = 'some value', Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    LogEntry__c nonMatchingLogEntry = new LogEntry__c(StackTrace__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
    List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
    System.Assert.isNotNull(matchingLogEntry.StackTrace__c);
    System.Assert.isNull(nonMatchingLogEntry.StackTrace__c);

    LoggerTriggerableContext context = new LoggerTriggerableContext(
      Schema.LogEntry__c.SObjectType,
      System.TriggerOperation.BEFORE_UPDATE,
      updatedRecords,
      new Map<Id, SObject>(updatedRecords),
      null
    );
    new LogEntryHandler().overrideTriggerableContext(context).execute();

    System.Assert.isTrue(matchingLogEntry.HasStackTrace__c);
    System.Assert.isFalse(nonMatchingLogEntry.HasStackTrace__c);
  }

  @IsTest
  static void it_should_set_skip_setting_apex_class_details_when_origin_location_is_null() {
    Log__c log = [SELECT Id FROM Log__c LIMIT 1];
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginLocation__c = null, OriginType__c = 'Apex');
    LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

    LoggerDataStore.getDatabase().insertRecord(logEntry);

    System.Assert.areEqual(
      2,
      LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
      'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
    );
    logEntry = [
      SELECT
        Id,
        ApexClassApiVersion__c,
        ApexClassCreatedDate__c,
        ApexClassId__c,
        ApexClassLastModifiedDate__c,
        ApexClassName__c,
        ApexInnerClassName__c,
        ApexMethodName__c,
        OriginLocation__c,
        OriginType__c
      FROM LogEntry__c
      WHERE Id = :logEntry.Id
    ];
    System.Assert.areEqual('Apex', logEntry.OriginType__c);
    System.Assert.isNull(logEntry.OriginLocation__c);
    System.Assert.isNull(logEntry.ApexClassApiVersion__c);
    System.Assert.isNull(logEntry.ApexClassCreatedDate__c);
    System.Assert.isNull(logEntry.ApexClassId__c);
    System.Assert.isNull(logEntry.ApexClassLastModifiedDate__c);
    System.Assert.isNull(logEntry.ApexClassName__c);
    System.Assert.isNull(logEntry.ApexInnerClassName__c);
    System.Assert.isNull(logEntry.ApexMethodName__c);
  }

  @IsTest
  static void it_should_set_exception_apex_class_details_for_top_level_class() {
    // FIXME the implementation does not seem to properly handle classes with a namespace prefix
    // (including when both the managed & unlocked packages are installed in an org), so skip the tests for now,
    // but revisit this test + implementation
    if (String.isNotBlank(Logger.getNamespacePrefix())) {
      return;
    }

    LoggerStackTrace stackTrace = new LoggerStackTrace();
    Schema.ApexClass apexClass = [
      SELECT Id, ApiVersion, Body, CreatedBy.Username, CreatedDate, LastModifiedBy.Username, LastModifiedDate
      FROM ApexClass
      WHERE NamespacePrefix = :getNamespacePrefix() AND Name = :stackTrace.Source.ApiName
    ];
    Log__c log = [SELECT Id FROM Log__c LIMIT 1];
    LogEntry__c logEntry = new LogEntry__c(
      ExceptionSourceApiName__c = stackTrace.Source.ApiName,
      ExceptionSourceMetadataType__c = 'ApexClass',
      ExceptionStackTrace__c = String.join(
        new List<String>{ 'Class.' + stackTrace.Location + ': line ' + stackTrace.Source.LineNumber + ', column 1', 'AnonymousBlock: line 1, column 1' },
        '\n'
      ),
      Log__c = log.Id
    );
    LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

    LoggerDataStore.getDatabase().insertRecord(logEntry);

    System.Assert.areEqual(
      2,
      LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
      'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
    );
    logEntry = [
      SELECT
        Id,
        HasExceptionSourceSnippet__c,
        ExceptionSourceApiVersion__c,
        ExceptionSourceCreatedById__c,
        ExceptionSourceCreatedByUsername__c,
        ExceptionSourceCreatedDate__c,
        ExceptionSourceId__c,
        ExceptionSourceLastModifiedById__c,
        ExceptionSourceLastModifiedByUsername__c,
        ExceptionSourceLastModifiedDate__c,
        ExceptionSourceSnippet__c
      FROM LogEntry__c
      WHERE Id = :logEntry.Id
    ];
    System.Assert.areEqual('v' + apexClass.ApiVersion, logEntry.ExceptionSourceApiVersion__c);
    System.Assert.areEqual(apexClass.CreatedById, logEntry.ExceptionSourceCreatedById__c);
    System.Assert.areEqual(apexClass.CreatedBy.Username, logEntry.ExceptionSourceCreatedByUsername__c);
    System.Assert.areEqual(apexClass.CreatedDate, logEntry.ExceptionSourceCreatedDate__c);
    System.Assert.areEqual(apexClass.Id, logEntry.ExceptionSourceId__c);
    System.Assert.areEqual(apexClass.LastModifiedById, logEntry.ExceptionSourceLastModifiedById__c);
    System.Assert.areEqual(apexClass.LastModifiedBy.Username, logEntry.ExceptionSourceLastModifiedByUsername__c);
    System.Assert.areEqual(apexClass.LastModifiedDate, logEntry.ExceptionSourceLastModifiedDate__c);
    System.Assert.isTrue(logEntry.HasExceptionSourceSnippet__c);
    LogEntryHandler.SourceMetadataSnippet expectedSnippet = new LogEntryHandler.SourceMetadataSnippet(stackTrace, apexClass);
    System.Assert.areEqual(stackTrace, expectedSnippet.StackTrace);
    System.Assert.areEqual(stackTrace.Source.LineNumber, expectedSnippet.TargetLineNumber);
    /*
            TODO determine best way(s) to test remaining code snippet properties:
                [x] public String sourceApiName
                [x] public String sourceType
                [ ] public String code
                [ ] public Integer startingLineNumber
                [ ] public Integer endingLineNumber
                [x] public Integer targetLineNumber
                [ ] public Integer totalLinesOfCode
        */
    System.Assert.areEqual(System.JSON.serializePretty(expectedSnippet), logEntry.ExceptionSourceSnippet__c);
  }

  @IsTest
  static void it_should_set_origin_apex_class_details_for_top_level_class() {
    // FIXME the implementation does not seem to properly handle classes with a namespace prefix
    // (including when both the managed & unlocked packages are installed in an org), so skip the tests for now,
    // but revisit this test + implementation
    if (String.isNotBlank(Logger.getNamespacePrefix())) {
      return;
    }

    LoggerStackTrace stackTrace = new LoggerStackTrace();
    Schema.ApexClass apexClass = [
      SELECT Id, ApiVersion, Body, CreatedBy.Username, CreatedDate, LastModifiedBy.Username, LastModifiedDate
      FROM ApexClass
      WHERE NamespacePrefix = :getNamespacePrefix() AND Name = :stackTrace.Source.ApiName
    ];
    Log__c log = [SELECT Id FROM Log__c LIMIT 1];
    LogEntry__c logEntry = new LogEntry__c(
      Log__c = log.Id,
      OriginSourceApiName__c = stackTrace.Source.ApiName,
      OriginSourceMetadataType__c = 'ApexClass',
      StackTrace__c = String.join(
        new List<String>{ 'Class.' + stackTrace.Location + ': line ' + stackTrace.Source.LineNumber + ', column 1', 'AnonymousBlock: line 1, column 1' },
        '\n'
      )
    );
    LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

    LoggerDataStore.getDatabase().insertRecord(logEntry);

    System.Assert.areEqual(
      2,
      LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
      'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
    );
    logEntry = [
      SELECT
        Id,
        ApexClassApiVersion__c,
        ApexClassCreatedDate__c,
        ApexClassId__c,
        ApexClassLastModifiedDate__c,
        ApexClassName__c,
        ApexInnerClassName__c,
        ApexMethodName__c,
        HasStackTrace__c,
        HasOriginSourceSnippet__c,
        OriginSourceApiVersion__c,
        OriginSourceCreatedById__c,
        OriginSourceCreatedByUsername__c,
        OriginSourceCreatedDate__c,
        OriginSourceId__c,
        OriginSourceLastModifiedById__c,
        OriginSourceLastModifiedByUsername__c,
        OriginSourceLastModifiedDate__c,
        OriginSourceSnippet__c,
        StackTrace__c
      FROM LogEntry__c
      WHERE Id = :logEntry.Id
    ];
    // Schema.ApexClass fields
    System.Assert.areEqual('v' + apexClass.ApiVersion, logEntry.ApexClassApiVersion__c);
    System.Assert.areEqual(apexClass.CreatedDate, logEntry.ApexClassCreatedDate__c);
    System.Assert.areEqual(apexClass.Id, logEntry.ApexClassId__c);
    System.Assert.areEqual(apexClass.LastModifiedDate, logEntry.ApexClassLastModifiedDate__c);
    System.Assert.areEqual(stackTrace.Source.ApiName, logEntry.ApexClassName__c);
    System.Assert.isNull(logEntry.ApexInnerClassName__c);
    System.Assert.areEqual(stackTrace.Source.ActionName, logEntry.ApexMethodName__c);
    // Origin source fields
    System.Assert.areEqual('v' + apexClass.ApiVersion, logEntry.OriginSourceApiVersion__c);
    System.Assert.areEqual(apexClass.CreatedById, logEntry.OriginSourceCreatedById__c);
    System.Assert.areEqual(apexClass.CreatedBy.Username, logEntry.OriginSourceCreatedByUsername__c);
    System.Assert.areEqual(apexClass.CreatedDate, logEntry.OriginSourceCreatedDate__c);
    System.Assert.areEqual(apexClass.Id, logEntry.OriginSourceId__c);
    System.Assert.areEqual(apexClass.LastModifiedById, logEntry.OriginSourceLastModifiedById__c);
    System.Assert.areEqual(apexClass.LastModifiedBy.Username, logEntry.OriginSourceLastModifiedByUsername__c);
    System.Assert.areEqual(apexClass.LastModifiedDate, logEntry.OriginSourceLastModifiedDate__c);
    System.Assert.isTrue(logEntry.HasOriginSourceSnippet__c);
    LogEntryHandler.SourceMetadataSnippet expectedSnippet = new LogEntryHandler.SourceMetadataSnippet(stackTrace, apexClass);
    System.Assert.areEqual(stackTrace, expectedSnippet.StackTrace);
    System.Assert.areEqual(stackTrace.Source.LineNumber, expectedSnippet.TargetLineNumber);
    /*
            TODO determine best way(s) to test remaining code snippet properties:
                [x] public String sourceApiName
                [x] public String sourceType
                [ ] public String code
                [ ] public Integer startingLineNumber
                [ ] public Integer endingLineNumber
                [x] public Integer targetLineNumber
                [ ] public Integer totalLinesOfCode
        */
    System.Assert.areEqual(System.JSON.serializePretty(expectedSnippet), logEntry.OriginSourceSnippet__c);
    System.Assert.isTrue(logEntry.HasStackTrace__c);
    // FIXME
    // System.Assert.areEqual(stackTrace.parsedStackTraceString, logEntry.StackTrace__c);
  }

  @IsTest
  static void it_should_set_origin_apex_class_details_for_inner_class() {
    // FIXME the implementation does not seem to properly handle classes with a namespace prefix
    // (including when both the managed & unlocked packages are installed in an org), so skip the tests for now,
    // but revisit this test + implementation
    if (String.isNotBlank(Logger.getNamespacePrefix())) {
      return;
    }

    LoggerStackTrace stackTrace = new SomeInnerClass().getLoggerStackTrace();
    Schema.ApexClass apexClass = [
      SELECT Id, ApiVersion, Body, CreatedBy.Username, CreatedDate, LastModifiedBy.Username, LastModifiedDate
      FROM ApexClass
      WHERE NamespacePrefix = :getNamespacePrefix() AND Name = :stackTrace.Source.ApiName
    ];
    Log__c log = [SELECT Id FROM Log__c LIMIT 1];
    LogEntry__c logEntry = new LogEntry__c(
      Log__c = log.Id,
      OriginSourceApiName__c = stackTrace.Source.ApiName,
      OriginSourceMetadataType__c = 'ApexClass',
      StackTrace__c = String.join(
        new List<String>{ 'Class.' + stackTrace.Location + ': line ' + stackTrace.Source.LineNumber + ', column 1', 'AnonymousBlock: line 1, column 1' },
        '\n'
      )
    );
    LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

    LoggerDataStore.getDatabase().insertRecord(logEntry);

    System.Assert.areEqual(
      2,
      LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
      'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
    );
    logEntry = [
      SELECT
        Id,
        ApexClassApiVersion__c,
        ApexClassCreatedDate__c,
        ApexClassId__c,
        ApexClassLastModifiedDate__c,
        ApexClassName__c,
        ApexInnerClassName__c,
        ApexMethodName__c,
        HasStackTrace__c,
        HasOriginSourceSnippet__c,
        OriginSourceApiVersion__c,
        OriginSourceCreatedById__c,
        OriginSourceCreatedByUsername__c,
        OriginSourceCreatedDate__c,
        OriginSourceId__c,
        OriginSourceLastModifiedById__c,
        OriginSourceLastModifiedByUsername__c,
        OriginSourceLastModifiedDate__c,
        OriginSourceSnippet__c,
        StackTrace__c
      FROM LogEntry__c
      WHERE Id = :logEntry.Id
    ];
    // Schema.ApexClass fields
    System.Assert.areEqual('v' + apexClass.ApiVersion, logEntry.ApexClassApiVersion__c);
    System.Assert.areEqual(apexClass.CreatedDate, logEntry.ApexClassCreatedDate__c);
    System.Assert.areEqual(apexClass.Id, logEntry.ApexClassId__c);
    System.Assert.areEqual(apexClass.LastModifiedDate, logEntry.ApexClassLastModifiedDate__c);
    System.Assert.areEqual(stackTrace.Source.ApiName, logEntry.ApexClassName__c);
    // TODO determine best way to test inner-class stuff
    // System.Assert.isNotNull(logEntry.ApexInnerClassName__c);
    // System.Assert.areEqual(stackTrace.apexInnerClassName, logEntry.ApexInnerClassName__c);
    System.Assert.areEqual(stackTrace.Source.ActionName, logEntry.ApexMethodName__c);
    // Origin source fields
    System.Assert.areEqual('v' + apexClass.ApiVersion, logEntry.OriginSourceApiVersion__c);
    System.Assert.areEqual(apexClass.CreatedById, logEntry.OriginSourceCreatedById__c);
    System.Assert.areEqual(apexClass.CreatedBy.Username, logEntry.OriginSourceCreatedByUsername__c);
    System.Assert.areEqual(apexClass.CreatedDate, logEntry.OriginSourceCreatedDate__c);
    System.Assert.areEqual(apexClass.Id, logEntry.OriginSourceId__c);
    System.Assert.areEqual(apexClass.LastModifiedById, logEntry.OriginSourceLastModifiedById__c);
    System.Assert.areEqual(apexClass.LastModifiedBy.Username, logEntry.OriginSourceLastModifiedByUsername__c);
    System.Assert.areEqual(apexClass.LastModifiedDate, logEntry.OriginSourceLastModifiedDate__c);
    System.Assert.isTrue(logEntry.HasOriginSourceSnippet__c);
    LogEntryHandler.SourceMetadataSnippet expectedSnippet = new LogEntryHandler.SourceMetadataSnippet(stackTrace, apexClass);
    System.Assert.areEqual(stackTrace, expectedSnippet.StackTrace);
    System.Assert.areEqual(stackTrace.Source.LineNumber, expectedSnippet.TargetLineNumber);
    /*
            TODO determine best way(s) to test remaining code snippet properties:
                [x] public String sourceApiName
                [x] public String sourceType
                [ ] public String code
                [ ] public Integer startingLineNumber
                [ ] public Integer endingLineNumber
                [x] public Integer targetLineNumber
                [ ] public Integer totalLinesOfCode
        */
    System.Assert.areEqual(System.JSON.serializePretty(expectedSnippet), logEntry.OriginSourceSnippet__c);
    System.Assert.isTrue(logEntry.HasStackTrace__c);
    // FIXME
    // System.Assert.areEqual(stackTrace.parsedStackTraceString, logEntry.StackTrace__c);
  }

  @IsTest
  static void it_should_set_origin_apex_trigger_details() {
    // FIXME the implementation does not seem to properly handle triggers with a namespace prefix
    // (including when both the managed & unlocked packages are installed in an org), so skip the tests for now,
    // but revisit this test + implementation
    if (String.isNotBlank(Logger.getNamespacePrefix())) {
      return;
    }

    // None of Nebula Logger's triggers include any logging (or logic), so use a mock
    // stack trace string so the code has an actual trigger to query
    String mockTriggerStackTraceString = String.join(new List<String>{ 'Trigger.LogEntry: line 2, column 1', 'AnonymousBlock: line 1, column 1' }, '\n');
    LoggerStackTrace stackTrace = new LoggerStackTrace(mockTriggerStackTraceString);
    Schema.ApexTrigger apexTrigger = [
      SELECT Id, ApiVersion, Body, CreatedBy.Username, CreatedDate, LastModifiedBy.Username, LastModifiedDate
      FROM ApexTrigger
      WHERE NamespacePrefix = :getNamespacePrefix() AND Name = :stackTrace.Source.ApiName
    ];
    Log__c log = [SELECT Id FROM Log__c LIMIT 1];
    LogEntry__c logEntry = new LogEntry__c(
      Log__c = log.Id,
      OriginSourceApiName__c = stackTrace.Source.ApiName,
      OriginSourceMetadataType__c = 'ApexTrigger',
      StackTrace__c = mockTriggerStackTraceString
    );
    LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

    LoggerDataStore.getDatabase().insertRecord(logEntry);

    System.Assert.areEqual(
      2,
      LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
      'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
    );
    logEntry = [
      SELECT
        Id,
        HasStackTrace__c,
        HasOriginSourceSnippet__c,
        OriginSourceApiVersion__c,
        OriginSourceCreatedById__c,
        OriginSourceCreatedByUsername__c,
        OriginSourceCreatedDate__c,
        OriginSourceId__c,
        OriginSourceLastModifiedById__c,
        OriginSourceLastModifiedByUsername__c,
        OriginSourceLastModifiedDate__c,
        OriginSourceSnippet__c,
        StackTrace__c
      FROM LogEntry__c
      WHERE Id = :logEntry.Id
    ];
    System.Assert.areEqual('v' + apexTrigger.ApiVersion, logEntry.OriginSourceApiVersion__c);
    System.Assert.areEqual(apexTrigger.CreatedById, logEntry.OriginSourceCreatedById__c);
    System.Assert.areEqual(apexTrigger.CreatedBy.Username, logEntry.OriginSourceCreatedByUsername__c);
    System.Assert.areEqual(apexTrigger.CreatedDate, logEntry.OriginSourceCreatedDate__c);
    System.Assert.areEqual(apexTrigger.Id, logEntry.OriginSourceId__c);
    System.Assert.areEqual(apexTrigger.LastModifiedById, logEntry.OriginSourceLastModifiedById__c);
    System.Assert.areEqual(apexTrigger.LastModifiedBy.Username, logEntry.OriginSourceLastModifiedByUsername__c);
    System.Assert.areEqual(apexTrigger.LastModifiedDate, logEntry.OriginSourceLastModifiedDate__c);
    System.Assert.isTrue(logEntry.HasOriginSourceSnippet__c);
    LogEntryHandler.SourceMetadataSnippet expectedSnippet = new LogEntryHandler.SourceMetadataSnippet(stackTrace, apexTrigger);
    System.Assert.areEqual(stackTrace, expectedSnippet.StackTrace);
    System.Assert.areEqual(stackTrace.Source.LineNumber, expectedSnippet.TargetLineNumber);
    /*
            TODO determine best way(s) to test remaining code snippet properties:
                [x] public String sourceApiName
                [x] public String sourceType
                [ ] public String code
                [ ] public Integer startingLineNumber
                [ ] public Integer endingLineNumber
                [x] public Integer targetLineNumber
                [ ] public Integer totalLinesOfCode
        */
    System.Assert.areEqual(System.JSON.serializePretty(expectedSnippet), logEntry.OriginSourceSnippet__c);
    System.Assert.isTrue(logEntry.HasStackTrace__c);
    // FIXME
    // System.Assert.areEqual(stackTrace.parsedStackTraceString, logEntry.StackTrace__c);
  }

  @IsTest
  static void it_should_set_gracefully_skip_setting_flow_details_when_origin_location_is_not_valid_flow_api_name() {
    Log__c log = new Log__c(TransactionId__c = '1234');
    insert log;
    LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
    String invalidOriginLocation = 'A_Very_Fake_Flow_API_Name';
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginLocation__c = invalidOriginLocation, OriginType__c = 'Flow');

    insert logEntry;

    logEntry = [
      SELECT
        FlowActiveVersionId__c,
        FlowDescription__c,
        FlowDurableId__c,
        FlowLabel__c,
        FlowLastModifiedByName__c,
        FlowLastModifiedDate__c,
        FlowProcessType__c,
        FlowRecordTriggerType__c,
        FlowTriggerSObjectType__c,
        FlowTriggerOrder__c,
        FlowTriggerType__c,
        FlowVersionApiVersionRuntime__c,
        FlowVersionNumber__c,
        FlowVersionRunInMode__c,
        Id,
        OriginLocation__c,
        OriginType__c,
        HasStackTrace__c,
        HasOriginSourceSnippet__c,
        OriginSourceApiVersion__c,
        OriginSourceCreatedById__c,
        OriginSourceCreatedByUsername__c,
        OriginSourceCreatedDate__c,
        OriginSourceId__c,
        OriginSourceLastModifiedById__c,
        OriginSourceLastModifiedByUsername__c,
        OriginSourceLastModifiedDate__c,
        OriginSourceSnippet__c,
        StackTrace__c
      FROM LogEntry__c
      WHERE Id = :logEntry.Id
    ];
    System.Assert.areEqual(invalidOriginLocation, logEntry.OriginLocation__c);
    System.Assert.areEqual('Flow', logEntry.OriginType__c);
    System.Assert.isNull(logEntry.StackTrace__c, 'Currently, there\'s no way to get a stack trace in Flow, so always expect null 😥');
    System.Assert.isNull(logEntry.FlowActiveVersionId__c);
    System.Assert.isNull(logEntry.FlowDescription__c);
    System.Assert.isNull(logEntry.FlowDurableId__c);
    System.Assert.isNull(logEntry.FlowLabel__c);
    System.Assert.isNull(logEntry.FlowLastModifiedByName__c);
    System.Assert.isNull(logEntry.FlowLastModifiedDate__c);
    System.Assert.isNull(logEntry.FlowProcessType__c);
    System.Assert.isNull(logEntry.FlowRecordTriggerType__c);
    System.Assert.isNull(logEntry.FlowTriggerSObjectType__c);
    System.Assert.isNull(logEntry.FlowTriggerOrder__c);
    System.Assert.isNull(logEntry.FlowTriggerType__c);
    System.Assert.isNull(logEntry.FlowVersionApiVersionRuntime__c);
    System.Assert.isNull(logEntry.FlowVersionNumber__c);
    System.Assert.isNull(logEntry.FlowVersionRunInMode__c);
    System.Assert.isFalse(logEntry.HasStackTrace__c);
    System.Assert.isFalse(logEntry.HasOriginSourceSnippet__c);
    System.Assert.isNull(logEntry.OriginSourceApiVersion__c);
    System.Assert.isNull(logEntry.OriginSourceCreatedById__c);
    System.Assert.isNull(logEntry.OriginSourceCreatedByUsername__c);
    System.Assert.isNull(logEntry.OriginSourceCreatedDate__c);
    System.Assert.isNull(logEntry.OriginSourceId__c);
    System.Assert.isNull(logEntry.OriginSourceLastModifiedById__c);
    System.Assert.isNull(logEntry.OriginSourceLastModifiedByUsername__c);
    System.Assert.isNull(logEntry.OriginSourceLastModifiedDate__c);
    System.Assert.isNull(logEntry.OriginSourceSnippet__c);
  }

  @IsTest
  static void it_should_set_origin_omni_process_details() {
    // No need to fail the test if it's running in an org that does not have OmniStudio enabled
    if (IS_OMNISTUDIO_ENABLED == false) {
      return;
    }
    Schema.User currentUser = new Schema.User(Id = System.UserInfo.getUserId(), Username = System.UserInfo.getUserName());
    SObject mockOmniProcessRecord = (SObject) (System.Type.forName('Schema.OmniProcess').newInstance());
    LoggerSObjectProxy.OmniProcess mockOmniProcessProxy = new LoggerSObjectProxy.OmniProcess(mockOmniProcessRecord);
    mockOmniProcessProxy.CreatedById = System.UserInfo.getUserId();
    mockOmniProcessProxy.CreatedBy = currentUser;
    mockOmniProcessProxy.CreatedDate = System.Datetime.now().addDays(-7);
    mockOmniProcessProxy.Id = LoggerMockDataCreator.createId(mockOmniProcessRecord.getSObjectType());
    mockOmniProcessProxy.LastModifiedById = currentUser.Id;
    mockOmniProcessProxy.LastModifiedBy = currentUser;
    mockOmniProcessProxy.LastModifiedDate = System.Datetime.now().addDays(-1);
    mockOmniProcessProxy.OmniProcessType = 'Integration Procedure';
    mockOmniProcessProxy.UniqueName = 'Mock_OmniScript_English_1';
    MockLogManagementDataSelector mockSelector = new MockLogManagementDataSelector();
    mockSelector.setMockOmniProcess(mockOmniProcessProxy);
    LogManagementDataSelector.setMock(mockSelector);
    Log__c log = [SELECT Id FROM Log__c LIMIT 1];
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginSourceId__c = mockOmniProcessProxy.Id, OriginType__c = 'OmniStudio');
    LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

    LoggerDataStore.getDatabase().insertRecord(logEntry);

    System.Assert.areEqual(
      2,
      LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
      'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
    );
    logEntry = [
      SELECT
        Id,
        OriginLocation__c,
        OriginSourceActionName__c,
        OriginSourceApiName__c,
        OriginSourceApiVersion__c,
        OriginSourceCreatedById__c,
        OriginSourceCreatedByUsername__c,
        OriginSourceCreatedDate__c,
        OriginSourceId__c,
        OriginSourceLastModifiedById__c,
        OriginSourceLastModifiedByUsername__c,
        OriginSourceLastModifiedDate__c,
        OriginSourceMetadataType__c,
        OriginType__c
      FROM LogEntry__c
      WHERE Id = :logEntry.Id
    ];
    System.Assert.areEqual('OmniStudio', logEntry.OriginType__c);
    System.Assert.isNull(logEntry.OriginLocation__c);
    System.Assert.isNull(logEntry.OriginSourceActionName__c);
    System.Assert.areEqual(mockOmniProcessProxy.UniqueName, logEntry.OriginSourceApiName__c);
    System.Assert.isNull(logEntry.OriginSourceApiVersion__c);
    System.Assert.areEqual(mockOmniProcessProxy.CreatedById, logEntry.OriginSourceCreatedById__c);
    System.Assert.areEqual(mockOmniProcessProxy.CreatedBy.Username, logEntry.OriginSourceCreatedByUsername__c);
    System.Assert.areEqual(mockOmniProcessProxy.CreatedDate, logEntry.OriginSourceCreatedDate__c);
    System.Assert.areEqual(mockOmniProcessProxy.Id, logEntry.OriginSourceId__c);
    System.Assert.areEqual(mockOmniProcessProxy.LastModifiedById, logEntry.OriginSourceLastModifiedById__c);
    System.Assert.areEqual(mockOmniProcessProxy.LastModifiedBy.Username, logEntry.OriginSourceLastModifiedByUsername__c);
    System.Assert.areEqual(mockOmniProcessProxy.LastModifiedDate, logEntry.OriginSourceLastModifiedDate__c);
    System.Assert.areEqual('OmniIntegrationProcedure', logEntry.OriginSourceMetadataType__c);
  }

  @IsTest
  static void it_should_set_skip_setting_origin_omni_process_details_when_origin_source_id_is_null() {
    Log__c log = [SELECT Id FROM Log__c LIMIT 1];
    LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginSourceId__c = null, OriginType__c = 'OmniStudio');
    LoggerMockDataCreator.createDataBuilder(logEntry).populateRequiredFields().getRecord();

    LoggerDataStore.getDatabase().insertRecord(logEntry);

    System.Assert.areEqual(
      2,
      LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
      'Handler class should have executed two times - once for BEFORE_INSERT and once for AFTER_INSERT'
    );
    logEntry = [
      SELECT
        Id,
        OriginLocation__c,
        OriginSourceActionName__c,
        OriginSourceApiName__c,
        OriginSourceApiVersion__c,
        OriginSourceCreatedById__c,
        OriginSourceCreatedByUsername__c,
        OriginSourceCreatedDate__c,
        OriginSourceId__c,
        OriginSourceLastModifiedById__c,
        OriginSourceLastModifiedByUsername__c,
        OriginSourceLastModifiedDate__c,
        OriginSourceMetadataType__c,
        OriginType__c
      FROM LogEntry__c
      WHERE Id = :logEntry.Id
    ];
    System.Assert.areEqual('OmniStudio', logEntry.OriginType__c);
    System.Assert.isNull(logEntry.OriginLocation__c);
    System.Assert.isNull(logEntry.OriginSourceActionName__c);
    System.Assert.isNull(logEntry.OriginSourceApiName__c);
    System.Assert.isNull(logEntry.OriginSourceApiVersion__c);
    System.Assert.isNull(logEntry.OriginSourceCreatedById__c);
    System.Assert.isNull(logEntry.OriginSourceCreatedByUsername__c);
    System.Assert.isNull(logEntry.OriginSourceCreatedDate__c);
    System.Assert.isNull(logEntry.OriginSourceId__c);
    System.Assert.isNull(logEntry.OriginSourceLastModifiedById__c);
    System.Assert.isNull(logEntry.OriginSourceLastModifiedByUsername__c);
    System.Assert.isNull(logEntry.OriginSourceLastModifiedDate__c);
    System.Assert.isNull(logEntry.OriginSourceMetadataType__c);
  }

  private static String getNamespacePrefix() {
    String className = LogEntryHandler_Tests.class.getName();
    String namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

    return namespacePrefix;
  }

  private class MockLogManagementDataSelector extends LogManagementDataSelector {
    private LoggerSObjectProxy.OmniProcess mockOmniProcessProxy;

    public override Map<Id, LoggerSObjectProxy.OmniProcess> getOmniProcessProxies(List<Id> omniProcessIds) {
      return new Map<Id, LoggerSObjectProxy.OmniProcess>{ mockOmniProcessProxy.Id => mockOmniProcessProxy };
    }

    public void setMockOmniProcess(LoggerSObjectProxy.OmniProcess omniProcessProxy) {
      this.mockOmniProcessProxy = omniProcessProxy;
    }
  }

  // Helper class for testing stack trace parsing & Schema.ApexClass querying for an inner class
  private class SomeInnerClass {
    public LoggerStackTrace getLoggerStackTrace() {
      return new LoggerStackTrace();
    }
  }
}
