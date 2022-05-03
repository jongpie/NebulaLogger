//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings(
    'PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount'
)
@IsTest(IsParallel=false)
private class LogEntryEventBuilder_Tests {
    @IsTest
    static void it_should_short_circuit_when_disabled() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.DEBUG, false);

        // Run all public and global methods to make sure no errors occur when not enabled (it's happened before)
        System.assertEquals(null, builder.setMessage(getLogMessage()).getLogEntryEvent());
        System.assertEquals(null, builder.setMessage(getMessage()).getLogEntryEvent());
        System.assertEquals(null, builder.setExceptionDetails(new DmlException()).getLogEntryEvent());
        System.assertEquals(null, builder.setDatabaseResult((Database.DeleteResult) null).getLogEntryEvent());
        System.assertEquals(null, builder.setDatabaseResult((Database.MergeResult) null).getLogEntryEvent());
        System.assertEquals(null, builder.setDatabaseResult((Database.SaveResult) null).getLogEntryEvent());
        System.assertEquals(null, builder.setDatabaseResult((Database.UpsertResult) null).getLogEntryEvent());
        System.assertEquals(null, builder.setDatabaseResult((Database.UndeleteResult) null).getLogEntryEvent());
        System.assertEquals(null, builder.setDatabaseResult(new List<Database.DeleteResult>()).getLogEntryEvent());
        System.assertEquals(null, builder.setDatabaseResult(new List<Database.MergeResult>()).getLogEntryEvent());
        System.assertEquals(null, builder.setDatabaseResult(new List<Database.SaveResult>()).getLogEntryEvent());
        System.assertEquals(null, builder.setDatabaseResult(new List<Database.UpsertResult>()).getLogEntryEvent());
        System.assertEquals(null, builder.setDatabaseResult(new List<Database.UndeleteResult>()).getLogEntryEvent());
        System.assertEquals(null, builder.setRecordId(UserInfo.getUserId()).getLogEntryEvent());
        System.assertEquals(null, builder.setRecordId(new User(Id = UserInfo.getUserId())).getLogEntryEvent());
        System.assertEquals(null, builder.setRecord(UserInfo.getUserId()).getLogEntryEvent());
        System.assertEquals(null, builder.setRecord(new User(Id = UserInfo.getUserId())).getLogEntryEvent());
        System.assertEquals(null, builder.setRecord(new List<User>{ new User(Id = UserInfo.getUserId()) }).getLogEntryEvent());
        System.assertEquals(null, builder.addTags(new List<String>{ 'tag-1', 'tag-2' }).getLogEntryEvent());
        System.assertEquals(null, builder.parseStackTrace(new DmlException().getStackTraceString()).getLogEntryEvent());
    }

    @IsTest
    static void it_should_not_run_queries_when_logging_disabled() {
        Logger.getUserSettings().IsEnabled__c = false;
        System.assertEquals(false, Logger.isEnabled());
        System.assertEquals(0, Limits.getQueries());

        new LogEntryEventBuilder(LoggingLevel.FINE, false).setMessage('some message').getLogEntryEvent();
        System.assertEquals(0, Limits.getQueries());
    }

    @IsTest
    static void it_should_short_circuit_when_enabled_logging_level_above_called_level() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, false);
        System.assertEquals(null, builder.getLogEntryEvent());
    }

    @IsTest
    static void it_should_not_short_circuit_when_enabledl() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, true);
        System.assertNotEquals(null, builder.getLogEntryEvent());
    }

    @IsTest
    static void it_should_set_message_fields_for_logMessage() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageMasked__c);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);

        LogMessage logMessage = new LogMessage('The time is {0}', System.now());
        builder.setMessage(logMessage);

        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageMasked__c);
        System.assertEquals(logMessage.getMessage(), builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_set_message_fields_for_null_logMessage() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageMasked__c);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);

        LogMessage logMessage = null;
        builder.setMessage(logMessage);

        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageMasked__c);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_set_message_fields_for_string() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageMasked__c);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);

        String message = 'The time is ' + String.valueOf(System.now());
        builder.setMessage(message);

        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageMasked__c);
        System.assertEquals(message, builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_set_message_fields_for_null_string() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageMasked__c);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);

        String message = null;
        builder.setMessage(message);

        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageMasked__c);
        System.assertEquals(message, builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_not_apply_data_mask_rule_when_rule_disabled() {
        Logger.getUserSettings().IsDataMaskingEnabled__c = true;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = false;
        LogEntryEventBuilder.setMockDataMaskRule(rule);
        String message = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        Account account = new Account(Name = message);
        String accountJson = JSON.serializePretty(account);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setMessage(message).setRecord(account);

        System.assertEquals(false, builder.getLogEntryEvent().MessageMasked__c, builder.getLogEntryEvent().Message__c);
        System.assertEquals(message, builder.getLogEntryEvent().Message__c);
        System.assertEquals(false, builder.getLogEntryEvent().RecordJsonMasked__c);
        System.assertEquals(accountJson, builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_not_apply_data_mask_rule_when_disabled_for_user() {
        Logger.getUserSettings().IsDataMaskingEnabled__c = false;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = true;
        LogEntryEventBuilder.setMockDataMaskRule(rule);
        String message = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        Account account = new Account(Name = message);
        String accountJson = JSON.serializePretty(account);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setMessage(message).setRecord(account);

        System.assertEquals(false, builder.getLogEntryEvent().MessageMasked__c);
        System.assertEquals(message, builder.getLogEntryEvent().Message__c);
        System.assertEquals(false, builder.getLogEntryEvent().RecordJsonMasked__c);
        System.assertEquals(accountJson, builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_apply_data_mask_rule_to_message_when_enabled() {
        Logger.getUserSettings().IsDataMaskingEnabled__c = true;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = true;
        LogEntryEventBuilder.setMockDataMaskRule(rule);
        String sensitiveString = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        String expectedSanitizedString = 'Something, something, and my social is XXX-XX-9999 in case you want to steal my identity';

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setMessage(sensitiveString);

        System.assertEquals(true, builder.getLogEntryEvent().MessageMasked__c);
        System.assertNotEquals(sensitiveString, builder.getLogEntryEvent().Message__c);
        System.assertEquals(expectedSanitizedString, builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_apply_data_mask_rule_to_record_json_when_enabled() {
        Logger.getUserSettings().IsDataMaskingEnabled__c = true;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = true;
        LogEntryEventBuilder.setMockDataMaskRule(rule);
        String sensitiveString = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        String expectedSanitizedString = 'Something, something, and my social is XXX-XX-9999 in case you want to steal my identity';
        Account account = new Account(Name = sensitiveString);
        String accountJson = JSON.serializePretty(account);
        String expectedSanitizedAccountJson = JSON.serializePretty(new Account(Name = expectedSanitizedString));

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setRecord(account);

        System.assertEquals(true, builder.getLogEntryEvent().RecordJsonMasked__c);
        System.assertNotEquals(accountJson, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(expectedSanitizedAccountJson, builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_apply_data_mask_rule_to_record_list_json_when_enabled() {
        Logger.getUserSettings().IsDataMaskingEnabled__c = true;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = true;
        LogEntryEventBuilder.setMockDataMaskRule(rule);

        String sensitiveString = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        String expectedSanitizedString = 'Something, something, and my social is XXX-XX-9999 in case you want to steal my identity';
        List<Account> accounts = new List<Account>{ new Account(Name = sensitiveString) };
        String accountListJson = JSON.serializePretty(accounts);
        String expectedSanitizedAccountListJson = JSON.serializePretty(new List<Account>{ new Account(Name = expectedSanitizedString) });
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setRecord(accounts);

        System.assertEquals(true, builder.getLogEntryEvent().RecordJsonMasked__c);
        System.assertNotEquals(accountListJson, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(expectedSanitizedAccountListJson, builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_apply_data_mask_rule_to_http_request_body_when_enabled() {
        Logger.getUserSettings().IsDataMaskingEnabled__c = true;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = true;
        LogEntryEventBuilder.setMockDataMaskRule(rule);
        String sensitiveString = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        String expectedSanitizedString = 'Something, something, and my social is XXX-XX-9999 in case you want to steal my identity';
        HttpRequest httpRequest = LoggerMockDataCreator.createHttpRequest();
        httpRequest.setBody(sensitiveString);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setHttpRequestDetails(httpRequest);

        System.assertEquals(true, builder.getLogEntryEvent().HttpRequestBodyMasked__c);
        System.assertNotEquals(sensitiveString, builder.getLogEntryEvent().HttpRequestBody__c);
        System.assertEquals(expectedSanitizedString, builder.getLogEntryEvent().HttpRequestBody__c);
    }

    @IsTest
    static void it_should_apply_data_mask_rule_to_http_response_body_when_enabled() {
        Logger.getUserSettings().IsDataMaskingEnabled__c = true;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        rule.IsEnabled__c = true;
        LogEntryEventBuilder.setMockDataMaskRule(rule);
        String sensitiveString = 'Something, something, and my social is 400 11 9999 in case you want to steal my identity';
        String expectedSanitizedString = 'Something, something, and my social is XXX-XX-9999 in case you want to steal my identity';
        HttpResponse httpResponse = LoggerMockDataCreator.createHttpResponse();
        httpResponse.setBody(sensitiveString);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setHttpResponseDetails(httpResponse);

        System.assertEquals(true, builder.getLogEntryEvent().HttpResponseBodyMasked__c);
        System.assertNotEquals(sensitiveString, builder.getLogEntryEvent().HttpResponseBody__c);
        System.assertEquals(expectedSanitizedString, builder.getLogEntryEvent().HttpResponseBody__c);
    }

    @IsTest
    static void it_should_truncate_message_for_long_logMessage() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageMasked__c);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);

        Integer maxMessageLength = Schema.LogEntry__c.Message__c.getDescribe().getLength();
        String baseMessage = 'z'.repeat(LogEntryEvent__e.Message__c.getDescribe().getLength() + 1);
        LogMessage logMessage = new LogMessage(baseMessage, 'something else');
        builder.setMessage(logMessage);
        System.assert(logMessage.getMessage().length() > maxMessageLength, 'Test message length should exceed the field length');
        builder.setMessage(logMessage);

        System.assertEquals(true, builder.getLogEntryEvent().MessageTruncated__c, 'Message should have been truncated');
        System.assertEquals(logMessage.getMessage().left(maxMessageLength), builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_truncate_message_for_long_string() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(false, builder.getLogEntryEvent().MessageTruncated__c);
        System.assertEquals(false, builder.getLogEntryEvent().MessageMasked__c);
        System.assertEquals(null, builder.getLogEntryEvent().Message__c);

        Integer maxMessageLength = Schema.LogEntry__c.Message__c.getDescribe().getLength();
        String message = 'z'.repeat(LogEntryEvent__e.Message__c.getDescribe().getLength() + 1);
        System.assert(message.length() > maxMessageLength, 'Test message length should exceed the field length');
        builder.setMessage(message);

        System.assertEquals(true, builder.getLogEntryEvent().MessageTruncated__c, 'Message should have been truncated');
        System.assertEquals(message.left(maxMessageLength), builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_set_exception_fields_for_dmlException() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, builder.getLogEntryEvent().ExceptionType__c);

        DmlException dmlException = new DmlException('Test DML exception');
        builder.setExceptionDetails(dmlException);

        System.assertEquals(dmlException.getMessage(), builder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(dmlException.getTypeName(), builder.getLogEntryEvent().ExceptionType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_deleteResult() {
        Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);
        System.assertNotEquals(null, deleteResult);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(deleteResult);

        System.assertEquals(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(deleteResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_mergeResult() {
        Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);
        System.assertNotEquals(null, mergeResult);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(mergeResult);

        System.assertEquals(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_saveResult() {
        Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);
        System.assertNotEquals(null, saveResult);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(saveResult);

        System.assertEquals(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(saveResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_undeleteResult() {
        Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);
        System.assertNotEquals(null, undeleteResult);

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(undeleteResult);

        System.assertEquals(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_upsertResult_when_insert() {
        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);
        System.assertNotEquals(null, upsertResult);
        System.assertEquals(true, upsertResult.isCreated());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(upsertResult);

        System.assertEquals(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_upsertResult_when_update() {
        Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, false);
        System.assertNotEquals(null, upsertResult);
        System.assertEquals(false, upsertResult.isCreated());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(upsertResult);

        System.assertEquals(1, builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_deleteResult() {
        List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>();
        for (Integer i = 0; i < 5; i++) {
            deleteResults.add(LoggerMockDataCreator.createDatabaseDeleteResult(false));
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(deleteResults);

        System.assertEquals(deleteResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.assertEquals('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(deleteResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_mergeResult() {
        List<Database.MergeResult> mergeResults = new List<Database.MergeResult>();
        for (Integer i = 0; i < 5; i++) {
            mergeResults.add(LoggerMockDataCreator.createDatabaseMergeResult(false));
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(mergeResults);

        System.assertEquals(mergeResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.assertEquals('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(mergeResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.MergeResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_saveResult() {
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>();
        for (Integer i = 0; i < 5; i++) {
            saveResults.add(LoggerMockDataCreator.createDatabaseSaveResult(false));
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(saveResults);

        System.assertEquals(saveResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.assertEquals('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(saveResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_undeleteResult() {
        List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>();
        for (Integer i = 0; i < 5; i++) {
            undeleteResults.add(LoggerMockDataCreator.createDatabaseUndeleteResult(false));
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(undeleteResults);

        System.assertEquals(undeleteResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.assertEquals('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_upsertResult() {
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>();
        for (Integer i = 0; i < 5; i++) {
            upsertResults.add(LoggerMockDataCreator.createDatabaseUpsertResult(false, false));
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(upsertResults);

        System.assertEquals(upsertResults.size(), builder.getLogEntryEvent().DatabaseResultCollectionSize__c);
        System.assertEquals('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_recordId_when_standard_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Id currentUserId = UserInfo.getUserId();
        builder.setRecordId(currentUserId);

        System.assertEquals(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(currentUserId, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals('User', builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_recordId_when_custom_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Id mockLogId = LoggerMockDataCreator.createId(Schema.Log__c.SObjectType);
        builder.setRecordId(mockLogId);

        System.assertEquals(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(mockLogId, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(Log__c.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_recordId_when_custom_metadata_type() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        LogStatus__mdt status = [SELECT Id, MasterLabel, DeveloperName FROM LogStatus__mdt LIMIT 1];
        builder.setRecordId(status.Id);

        System.assertEquals(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(status.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Metadata Type Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(LogStatus__mdt.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_record_when_null() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        User nullUser;
        System.assertEquals(null, nullUser);
        builder.setRecordId(nullUser);

        System.assertEquals(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals('null', builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_record_when_standard_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        User currentUser = [SELECT Id, Name, ProfileId, Profile.Name, IsActive FROM User WHERE Id = :UserInfo.getUserId()];
        builder.setRecordId(currentUser);

        System.assertEquals(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(currentUser.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(currentUser), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals('User', builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_record_when_custom_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Log__c log = (Log__c) LoggerMockDataCreator.createDataBuilder(Schema.Log__c.SObjectType).populateRequiredFields().getRecord();
        builder.setRecordId(log);

        System.assertEquals(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(log.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(log), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(Log__c.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_record_when_custom_metadata_type() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        LogStatus__mdt status = [SELECT Id, MasterLabel, DeveloperName FROM LogStatus__mdt LIMIT 1];
        builder.setRecordId(status);

        System.assertEquals(1, builder.getLogEntryEvent().RecordCollectionSize__c);
        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(status.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(status), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Metadata Type Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(LogStatus__mdt.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_skip_stripping_inaccessible_fields_for_aggregate_result() {
        User standardUser = LoggerMockDataCreator.createUser();
        AggregateResult mockAggregateResult = LoggerMockDataCreator.createAggregateResult();

        LogEntryEventBuilder builder;
        System.runAs(standardUser) {
            Logger.getUserSettings().IsRecordFieldStrippingEnabled__c = true;
            builder = new LogEntryEventBuilder(LoggingLevel.INFO, true).setRecord(mockAggregateResult);
        }

        System.assertEquals(JSON.serializePretty(mockAggregateResult), builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_skip_stripping_inaccessible_fields_for_aggregate_results() {
        User standardUser = LoggerMockDataCreator.createUser();
        List<AggregateResult> mockAggregateResults = new List<AggregateResult>{ LoggerMockDataCreator.createAggregateResult() };

        LogEntryEventBuilder builder;
        System.runAs(standardUser) {
            Logger.getUserSettings().IsRecordFieldStrippingEnabled__c = true;
            builder = new LogEntryEventBuilder(LoggingLevel.INFO, true).setRecord(mockAggregateResults);
        }

        System.assertEquals(JSON.serializePretty(mockAggregateResults), builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_list_of_records_when_list_is_null() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        List<SObject> users;
        System.assertEquals(null, users);
        builder.setRecord(users);

        System.assertEquals('List', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals('null', builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_list_of_records_when_list_is_empty() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        List<SObject> users = new List<SObject>();
        System.assertEquals(true, users.isEmpty());
        builder.setRecord(users);

        System.assertEquals('List', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_list_of_records_when_first_record_is_null() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        List<SObject> users = new List<SObject>();
        User nullUser;
        users.add(nullUser);
        users.add(new User(Id = UserInfo.getUserId()));
        builder.setRecord(users);

        System.assertEquals('List', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Unknown', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals('Unknown', builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_list_of_records_when_populated() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        List<User> users = [SELECT Id, Name, Username, IsActive FROM User LIMIT 5];
        builder.setRecord(users);

        System.assertEquals('List', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(users), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Standard Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(User.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_skip_setting_http_request_fields_when_request_is_null() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestBody__c);
        System.assertEquals(false, builder.getLogEntryEvent().HttpRequestCompressed__c);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestEndpoint__c);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestMethod__c);
        HttpRequest request = null;

        builder.setHttpRequestDetails(request);

        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestBody__c);
        System.assertEquals(false, builder.getLogEntryEvent().HttpRequestCompressed__c);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestEndpoint__c);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestMethod__c);
    }

    @IsTest
    static void it_should_set_http_request_fields_when_request_is_populated() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestBody__c);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestEndpoint__c);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestMethod__c);
        HttpRequest request = new HttpRequest();
        request.setBody('Hello, world!');
        request.setCompressed(true);
        request.setEndpoint('https://fake.salesforce.com');
        request.setMethod('GET');

        builder.setHttpRequestDetails(request);

        System.assertEquals(request.getBody(), builder.getLogEntryEvent().HttpRequestBody__c);
        System.assertEquals(request.getCompressed(), builder.getLogEntryEvent().HttpRequestCompressed__c);
        System.assertEquals(request.getEndpoint(), builder.getLogEntryEvent().HttpRequestEndpoint__c);
        System.assertEquals(request.getMethod(), builder.getLogEntryEvent().HttpRequestMethod__c);
    }

    @IsTest
    static void it_should_skip_setting_http_response_fields_when_response_is_null() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestBody__c);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestEndpoint__c);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestMethod__c);
        HttpResponse response = null;

        builder.setHttpResponseDetails(response);

        System.assertEquals(null, builder.getLogEntryEvent().HttpResponseBody__c);
        System.assertEquals(null, builder.getLogEntryEvent().HttpResponseHeaderKeys__c);
        System.assertEquals(null, builder.getLogEntryEvent().HttpResponseStatus__c);
        System.assertEquals(null, builder.getLogEntryEvent().HttpResponseStatusCode__c);
    }

    @IsTest
    static void it_should_set_http_response_fields_when_populated() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestBody__c);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestEndpoint__c);
        System.assertEquals(null, builder.getLogEntryEvent().HttpRequestMethod__c);
        HttpResponse response = new HttpResponse();
        response.setBody('Hello, world!');
        response.setHeader('someKey', 'some string value');
        response.setHeader('anotherKey', 'an amazing example value, wow');
        response.setStatus('STATUS_GOOD_JOB_YOU_DID_IT');
        response.setStatusCode(201);

        builder.setHttpResponseDetails(response);

        System.assertEquals(response.getBody(), builder.getLogEntryEvent().HttpResponseBody__c);
        System.assertEquals(String.join(response.getHeaderKeys(), '\n'), builder.getLogEntryEvent().HttpResponseHeaderKeys__c);
        System.assertEquals(response.getStatus(), builder.getLogEntryEvent().HttpResponseStatus__c);
        System.assertEquals(response.getStatusCode(), builder.getLogEntryEvent().HttpResponseStatusCode__c);
    }

    @IsTest
    static void it_should_set_tags_string_for_list_of_tags() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Tags__c);

        List<String> tags = new List<String>{ 'some-tag', 'another One', 'here\'s one more!' };
        builder.addTags(tags);

        tags.sort();
        String expectedTagsString = String.escapeSingleQuotes(String.join(tags, '\n'));
        System.assertEquals(expectedTagsString, builder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_deduplicate_and_sort_tags() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Tags__c);

        List<String> tags = new List<String>{ 'duplicate-tag', 'duplicate-tag', 'another One' };
        builder.addTags(tags);

        String expectedTagsString = 'another One\nduplicate-tag';
        System.assertEquals(expectedTagsString, builder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_set_stack_trace_and_origin_location_for_stack_trace_string() {
        DmlException stackTraceHandler = new DmlException();

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, true);
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;
        builder.parseStackTrace(stackTraceHandler.getStackTraceString());

        String expectedOriginLocation = stackTraceHandler.getStackTraceString().split('\n').get(0).substringBefore(':').substringAfter('Class.');
        String expectedStackTrace = stackTraceHandler.getStackTraceString();

        System.assertNotEquals(null, builder.getLogEntryEvent().OriginLocation__c);
        System.assertEquals(expectedOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
        System.assertNotEquals(null, builder.getLogEntryEvent().StackTrace__c);
        System.assertEquals(expectedStackTrace, builder.getLogEntryEvent().StackTrace__c);
    }

    @IsTest
    static void it_should_set_stack_trace_and_origin_location_for_anonymous_apex_stack_trace_string() {
        String anonymousApexOriginLocation = 'AnonymousBlock';
        String anonymousApexStackTraceString = 'AnonymousBlock: line 9, column 1';

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, true);
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;
        builder.parseStackTrace(anonymousApexStackTraceString);

        System.assertNotEquals(null, builder.getLogEntryEvent().OriginLocation__c);
        System.assertEquals(anonymousApexOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
        System.assertNotEquals(null, builder.getLogEntryEvent().StackTrace__c);
        System.assertEquals(anonymousApexStackTraceString, builder.getLogEntryEvent().StackTrace__c);
    }

    @IsTest
    static void it_should_deduplicate_sequential_lines_when_setting_stack_trace() {
        String anonymousApexOriginLocation = 'AnonymousBlock';
        String deduplicatedStackTraceString = 'AnonymousBlock: line 9, column 1';
        String duplicatedStackTraceString = deduplicatedStackTraceString + '\n' + deduplicatedStackTraceString + '\n' + deduplicatedStackTraceString;

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.FINE, true);
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;
        builder.parseStackTrace(duplicatedStackTraceString);

        System.assertNotEquals(null, builder.getLogEntryEvent().OriginLocation__c);
        System.assertEquals(anonymousApexOriginLocation, builder.getLogEntryEvent().OriginLocation__c);
        System.assertNotEquals(null, builder.getLogEntryEvent().StackTrace__c);
        System.assertEquals(deduplicatedStackTraceString, builder.getLogEntryEvent().StackTrace__c);
    }

    @IsTest
    static void it_should_not_set_stack_trace_and_origin_location_for_invalid_stack_trace_string() {
        final String invalidStackTrace = '()';

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        // Clear out any auto-set values
        builder.getLogEntryEvent().OriginLocation__c = null;
        builder.getLogEntryEvent().StackTrace__c = null;
        builder.parseStackTrace(invalidStackTrace);

        System.assertEquals(null, builder.getLogEntryEvent().OriginLocation__c);
        System.assertEquals(null, builder.getLogEntryEvent().StackTrace__c);
    }

    @IsTest
    static void it_should_return_value_of_shouldSave_when_true() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(true, builder.shouldSave());
    }

    @IsTest
    static void it_should_return_value_of_shouldSave_when_false() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, false);
        System.assertEquals(false, builder.shouldSave());
    }

    @IsTest
    static void it_should_not_set_user_fields_when_anonymous_mode_disabled() {
        // Get expected data
        Organization organization = LoggerMockDataCreator.getOrganization();
        String organizationEnvironmentType = LoggerMockDataCreator.getOrganizationEnvironmentType();
        User user = LoggerMockDataCreator.getUser();

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

        // Verify organization fields
        System.assertEquals(Url.getOrgDomainUrl().toExternalForm(), builder.getLogEntryEvent().OrganizationDomainUrl__c);
        System.assertEquals(organizationEnvironmentType, builder.getLogEntryEvent().OrganizationEnvironmentType__c);
        System.assertEquals(organization.Id, builder.getLogEntryEvent().OrganizationId__c);
        System.assertEquals(organization.InstanceName, builder.getLogEntryEvent().OrganizationInstanceName__c);
        System.assertEquals(organization.Name, builder.getLogEntryEvent().OrganizationName__c);
        System.assertEquals(organization.NamespacePrefix, builder.getLogEntryEvent().OrganizationNamespacePrefix__c);
        System.assertEquals(organization.OrganizationType, builder.getLogEntryEvent().OrganizationType__c);

        // Verify user fields
        System.assertEquals(USER.Id, builder.getLogEntryEvent().LoggedById__c);
        System.assertEquals(USER.Username, builder.getLogEntryEvent().LoggedByUsername__c);
        System.assertEquals(USER.Profile.Name, builder.getLogEntryEvent().ProfileName__c);
        System.assertEquals(USER.Profile.UserLicense.LicenseDefinitionKey, builder.getLogEntryEvent().UserLicenseDefinitionKey__c);
        System.assertEquals(USER.Profile.UserLicenseId, builder.getLogEntryEvent().UserLicenseId__c);
        System.assertEquals(USER.Profile.UserLicense.Name, builder.getLogEntryEvent().UserLicenseName__c);
        System.assertEquals(USER.UserRole?.Name, builder.getLogEntryEvent().UserRoleName__c);
    }

    @IsTest
    static void it_should_not_set_user_fields_when_anonymous_mode_enabled() {
        Logger.getUserSettings().IsAnonymousModeEnabled__c = true;

        LogEntryEventBuilder builder = Logger.debug('test log entry');

        System.assertEquals(null, builder.getLogEntryEvent().Locale__c);
        System.assertEquals(null, builder.getLogEntryEvent().LoggedById__c);
        System.assertEquals(null, builder.getLogEntryEvent().LoggedByUsername__c);
        System.assertEquals(null, builder.getLogEntryEvent().LoginApplication__c);
        System.assertEquals(null, builder.getLogEntryEvent().LoginBrowser__c);
        System.assertEquals(null, builder.getLogEntryEvent().LoginHistoryId__c);
        System.assertEquals(null, builder.getLogEntryEvent().LoginPlatform__c);
        System.assertEquals(null, builder.getLogEntryEvent().LoginType__c);
        System.assertEquals(null, builder.getLogEntryEvent().LogoutUrl__c);
        System.assertEquals(null, builder.getLogEntryEvent().ProfileId__c);
        System.assertEquals(null, builder.getLogEntryEvent().ProfileName__c);
        System.assertEquals(null, builder.getLogEntryEvent().SessionId__c);
        System.assertEquals(null, builder.getLogEntryEvent().SessionSecurityLevel__c);
        System.assertEquals(null, builder.getLogEntryEvent().SessionType__c);
        System.assertEquals(null, builder.getLogEntryEvent().SourceIp__c);
        System.assertEquals(null, builder.getLogEntryEvent().ThemeDisplayed__c);
        System.assertEquals(null, builder.getLogEntryEvent().TimeZoneId__c);
        System.assertEquals(null, builder.getLogEntryEvent().TimeZoneName__c);
        System.assertEquals(null, builder.getLogEntryEvent().UserLicenseDefinitionKey__c);
        System.assertEquals(null, builder.getLogEntryEvent().UserLicenseId__c);
        System.assertEquals(null, builder.getLogEntryEvent().UserLicenseName__c);
        System.assertEquals(null, builder.getLogEntryEvent().UserLoggingLevel__c);
        System.assertEquals(null, builder.getLogEntryEvent().UserLoggingLevelOrdinal__c);
        System.assertEquals(null, builder.getLogEntryEvent().UserRoleId__c);
        System.assertEquals(null, builder.getLogEntryEvent().UserRoleName__c);
        System.assertEquals(null, builder.getLogEntryEvent().UserType__c);
    }

    @IsTest
    static void it_should_use_configured_log_entry_event_fields_for_debug_string() {
        LoggerParameter.setMock(
            new LoggerParameter__mdt(DeveloperName = 'SystemDebugMessageFormat', Value__c = '{OriginLocation__c}\n{Message__c}: {LoggingLevel__c}')
        );

        DebugStringExample example = new DebugStringExample();
        LogEntryEventBuilder builder = example.myMethod();

        System.assertEquals(
            DebugStringExample.class.getName() +
            '.myMethod' +
            '\n' +
            example.loggingString +
            ': ' +
            LoggingLevel.DEBUG.name(),
            builder.debugMessage
        );
    }

    static String getMessage() {
        return 'Hello, world';
    }

    static LogMessage getLogMessage() {
        return new LogMessage('The current date is {0}', System.today());
    }

    static LogEntryDataMaskRule__mdt getSocialSecurityNumberDataMaskRule() {
        return new LogEntryDataMaskRule__mdt(
            DeveloperName = 'SocialSecurityNumber',
            IsEnabled__c = true,
            SensitiveDataRegEx__c = '(\\d{3})[- ]*(\\d{2})[- ]*(\\d{4})',
            ReplacementRegEx__c = 'XXX-XX-$3'
        );
    }

    private class DebugStringExample {
        public final String loggingString = 'Inside DebugStringExample.myMethod !';
        public LogEntryEventBuilder myMethod() {
            return Logger.debug(loggingString);
        }
    }
}
