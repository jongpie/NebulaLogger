//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LogEntryHandler_Tests {
    @TestSetup
    static void setupData() {
        LoggerSObjectHandler.shouldExecute(false);
        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        insert log;
        System.Test.setCreatedDate(log.Id, System.now().addDays(-8));
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

        System.Assert.areEqual(
            0,
            LoggerSObjectHandler.getExecutedHandlers().get(Schema.LogEntry__c.SObjectType).size(),
            'Handler class should not have executed'
        );
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
        User currentUser = [SELECT Id, Username FROM User WHERE Id = :System.UserInfo.getUserId()];
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
        Profile currentProfile = [SELECT Id, Name FROM Profile WHERE Id = :System.UserInfo.getProfileId()];
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
        User currentUser = [SELECT Id, Username FROM User WHERE Id = :System.UserInfo.getUserId()];
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
            TriggerOperation.BEFORE_INSERT,
            new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
        );
        new LogEntryHandler().overrideTriggerableContext(context).execute();

        System.Assert.isTrue(matchingLogEntry.HasDatabaseResultJson__c);
        System.Assert.isFalse(nonMatchingLogEntry.HasDatabaseResultJson__c);
    }

    @IsTest
    static void it_should_set_hasDatabaseResultJson_on_before_update() {
        LogEntry__c matchingLogEntry = new LogEntry__c(
            DatabaseResultJson__c = 'some value',
            Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType)
        );
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(DatabaseResultJson__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
        List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
        System.Assert.isNotNull(matchingLogEntry.DatabaseResultJson__c);
        System.Assert.isNull(nonMatchingLogEntry.DatabaseResultJson__c);

        LoggerTriggerableContext context = new LoggerTriggerableContext(
            Schema.LogEntry__c.SObjectType,
            TriggerOperation.BEFORE_UPDATE,
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
            TriggerOperation.BEFORE_INSERT,
            new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
        );
        new LogEntryHandler().overrideTriggerableContext(context).execute();

        System.Assert.isTrue(matchingLogEntry.HasExceptionStackTrace__c);
        System.Assert.isFalse(nonMatchingLogEntry.HasExceptionStackTrace__c);
    }

    @IsTest
    static void it_should_set_hasExceptionStackTrace_on_before_update() {
        LogEntry__c matchingLogEntry = new LogEntry__c(
            ExceptionStackTrace__c = 'some value',
            Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType)
        );
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(ExceptionStackTrace__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
        List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
        System.Assert.isNotNull(matchingLogEntry.ExceptionStackTrace__c);
        System.Assert.isNull(nonMatchingLogEntry.ExceptionStackTrace__c);

        LoggerTriggerableContext context = new LoggerTriggerableContext(
            Schema.LogEntry__c.SObjectType,
            TriggerOperation.BEFORE_UPDATE,
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
            TriggerOperation.BEFORE_INSERT,
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
            TriggerOperation.BEFORE_UPDATE,
            updatedRecords,
            new Map<Id, SObject>(updatedRecords),
            null
        );
        new LogEntryHandler().overrideTriggerableContext(context).execute();

        System.Assert.isTrue(matchingLogEntry.HasHttpRequestBody__c);
        System.Assert.isFalse(nonMatchingLogEntry.HasHttpRequestBody__c);
    }

    @IsTest
    static void it_should_set_hasHttpResponseBody_on_before_insert() {
        LogEntry__c matchingLogEntry = new LogEntry__c(HttpResponseBody__c = 'some value');
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpResponseBody__c = null);
        System.Assert.isNotNull(matchingLogEntry.HttpResponseBody__c);
        System.Assert.isNull(nonMatchingLogEntry.HttpResponseBody__c);

        LoggerTriggerableContext context = new LoggerTriggerableContext(
            Schema.LogEntry__c.SObjectType,
            TriggerOperation.BEFORE_INSERT,
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
            TriggerOperation.BEFORE_UPDATE,
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
            TriggerOperation.BEFORE_INSERT,
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
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(
            HttpResponseHeaderKeys__c = null,
            Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType)
        );
        List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
        System.Assert.isNotNull(matchingLogEntry.HttpResponseHeaderKeys__c);
        System.Assert.isNull(nonMatchingLogEntry.HttpResponseHeaderKeys__c);

        LoggerTriggerableContext context = new LoggerTriggerableContext(
            Schema.LogEntry__c.SObjectType,
            TriggerOperation.BEFORE_UPDATE,
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
            TriggerOperation.BEFORE_INSERT,
            new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry }
        );
        new LogEntryHandler().overrideTriggerableContext(context).execute();

        System.Assert.isTrue(matchingLogEntry.HasHttpResponseHeaders__c);
        System.Assert.isFalse(nonMatchingLogEntry.HasHttpResponseHeaders__c);
    }

    @IsTest
    static void it_should_set_hasHttpResponseHeaders_on_before_update() {
        LogEntry__c matchingLogEntry = new LogEntry__c(
            HttpResponseHeaders__c = 'some value',
            Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType)
        );
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(HttpResponseHeaders__c = null, Id = LoggerMockDataCreator.createId(Schema.LogEntry__c.SObjectType));
        List<LogEntry__c> updatedRecords = new List<LogEntry__c>{ matchingLogEntry, nonMatchingLogEntry };
        System.Assert.isNotNull(matchingLogEntry.HttpResponseHeaders__c);
        System.Assert.isNull(nonMatchingLogEntry.HttpResponseHeaders__c);

        LoggerTriggerableContext context = new LoggerTriggerableContext(
            Schema.LogEntry__c.SObjectType,
            TriggerOperation.BEFORE_UPDATE,
            updatedRecords,
            new Map<Id, SObject>(updatedRecords),
            null
        );
        new LogEntryHandler().overrideTriggerableContext(context).execute();

        System.Assert.isTrue(matchingLogEntry.HasHttpResponseHeaders__c);
        System.Assert.isFalse(nonMatchingLogEntry.HasHttpResponseHeaders__c);
    }
    @IsTest
    static void it_should_set_hasInlineTags_on_before_insert() {
        LogEntry__c matchingLogEntry = new LogEntry__c(Tags__c = 'some value');
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(Tags__c = null);
        System.Assert.isNotNull(matchingLogEntry.Tags__c);
        System.Assert.isNull(nonMatchingLogEntry.Tags__c);

        LoggerTriggerableContext context = new LoggerTriggerableContext(
            Schema.LogEntry__c.SObjectType,
            TriggerOperation.BEFORE_INSERT,
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
            TriggerOperation.BEFORE_UPDATE,
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
            TriggerOperation.BEFORE_INSERT,
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
            TriggerOperation.BEFORE_UPDATE,
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
            TriggerOperation.BEFORE_INSERT,
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
            TriggerOperation.BEFORE_UPDATE,
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
    static void it_should_set_apex_class_details_for_top_level_class() {
        // FIXME the implementation does not seem to properly handle classes with a namespace prefix
        // (including when both the managed & unlocked packages are installed in an org), so skip the tests for now,
        // but revisit this test + implementation
        if (String.isNotBlank(Logger.getNamespacePrefix())) {
            return;
        }

        String exampleTopLevelClassName = 'Logger';
        String methodName = 'saveLog';
        String exampleTopLevelClassMethodName = exampleTopLevelClassName + '. ' + methodName;
        ApexClass apexClass = [
            SELECT Id, ApiVersion, CreatedDate, LastModifiedDate
            FROM ApexClass
            WHERE NamespacePrefix = :getNamespacePrefix() AND Name = :exampleTopLevelClassName
        ];
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginLocation__c = exampleTopLevelClassMethodName, OriginType__c = 'Apex');
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
                OriginLocation__c
            FROM LogEntry__c
            WHERE Id = :logEntry.Id
        ];
        System.Assert.areEqual(exampleTopLevelClassMethodName, logEntry.OriginLocation__c);
        System.Assert.areEqual('v' + apexClass.ApiVersion, logEntry.ApexClassApiVersion__c);
        System.Assert.areEqual(apexClass.CreatedDate, logEntry.ApexClassCreatedDate__c);
        System.Assert.areEqual(apexClass.Id, logEntry.ApexClassId__c);
        System.Assert.areEqual(apexClass.LastModifiedDate, logEntry.ApexClassLastModifiedDate__c);
        System.Assert.areEqual(exampleTopLevelClassName, logEntry.ApexClassName__c);
        System.Assert.isNull(logEntry.ApexInnerClassName__c);
        System.Assert.areEqual(methodName, logEntry.ApexMethodName__c);
    }

    @IsTest
    static void it_should_set_apex_class_details_for_inner_class() {
        // FIXME the implementation does not seem to properly handle classes with a namespace prefix
        // (including when both the managed & unlocked packages are installed in an org), so skip the tests for now,
        // but revisit this test + implementation
        if (String.isNotBlank(Logger.getNamespacePrefix())) {
            return;
        }

        String exampleTopLevelClassName = 'Logger';
        String exampleInnerClassName = 'QueueableSaver';
        String methodName = 'execute';
        String exampleInnerClassMethodName = exampleTopLevelClassName + '.' + exampleInnerClassName + '.' + methodName;
        ApexClass apexClass = [
            SELECT Id, ApiVersion, CreatedDate, LastModifiedDate
            FROM ApexClass
            WHERE NamespacePrefix = :getNamespacePrefix() AND Name = :exampleTopLevelClassName
        ];
        Log__c log = [SELECT Id FROM Log__c LIMIT 1];
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginLocation__c = exampleInnerClassMethodName, OriginType__c = 'Apex');
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
                OriginLocation__c
            FROM LogEntry__c
            WHERE Id = :logEntry.Id
        ];
        System.Assert.areEqual(exampleInnerClassMethodName, logEntry.OriginLocation__c);
        System.Assert.areEqual('v' + apexClass.ApiVersion, logEntry.ApexClassApiVersion__c);
        System.Assert.areEqual(apexClass.CreatedDate, logEntry.ApexClassCreatedDate__c);
        System.Assert.areEqual(apexClass.Id, logEntry.ApexClassId__c);
        System.Assert.areEqual(apexClass.LastModifiedDate, logEntry.ApexClassLastModifiedDate__c);
        System.Assert.areEqual(exampleTopLevelClassName, logEntry.ApexClassName__c);
        System.Assert.areEqual(exampleInnerClassName, logEntry.ApexInnerClassName__c);
        System.Assert.areEqual(methodName, logEntry.ApexMethodName__c);
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
                OriginType__c
            FROM LogEntry__c
            WHERE Id = :logEntry.Id
        ];
        System.Assert.areEqual(invalidOriginLocation, logEntry.OriginLocation__c);
        System.Assert.areEqual('Flow', logEntry.OriginType__c);
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
    }

    private static String getNamespacePrefix() {
        String className = LogEntryHandler_Tests.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

        return namespacePrefix;
    }

    private class MockLogManagementDataSelector extends LogManagementDataSelector {
        private Integer apexClassesQueryCount = 0;

        public override List<ApexClass> getApexClasses(List<String> apexClassNames) {
            this.apexClassesQueryCount++;
            return super.getApexClasses(apexClassNames);
        }

        public Integer getApexClassesQueryCount() {
            return apexClassesQueryCount;
        }
    }
}
