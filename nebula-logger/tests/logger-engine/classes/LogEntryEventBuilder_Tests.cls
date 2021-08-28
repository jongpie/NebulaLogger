//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@IsTest
private class LogEntryEventBuilder_Tests {
    static String getMessage() {
        return 'Hello, world';
    }

    static LogMessage getLogMessage() {
        return new LogMessage('The current date is {0}', System.today());
    }

    static LogEntryDataMaskRule__mdt getCreditCardNumberDataMaskRule() {
        return new LogEntryDataMaskRule__mdt(
            IsEnabled__c = true,
            ApplyToMessage__c = true,
            ApplyToRecordJson__c = true,
            SensitiveDataRegEx__c = '(\\d{3})[- ]*(\\d{2})[- ]*(\\d{4})',
            ReplacementRegEx__c = 'XXX-XX-$3'
        );
    }

    static LogEntryDataMaskRule__mdt getSocialSecurityNumberDataMaskRule() {
        return new LogEntryDataMaskRule__mdt(
            IsEnabled__c = true,
            ApplyToMessage__c = true,
            ApplyToRecordJson__c = true,
            SensitiveDataRegEx__c = '(4\\d{3})[- ]*(\\d{4})[- ]*(\\d{4})[- ]*(\\d{4})',
            ReplacementRegEx__c = '****-****-****-$4'
        );
    }

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
    static void it_should_apply_credit_card_number_data_mask_rule_when_enabled() {
        Logger.getUserSettings().ApplyDataMaskRules__c = true;
        LogEntryEventBuilder.addMockDataMaskRule(getCreditCardNumberDataMaskRule());

        String message = 'Something, something, something credit card 4000 1111 2222 3333 and something else';
        String expectedSanitizedMessage = 'Something, something, something credit card ****-****-****-3333 and something else';
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setMessage(message);

        System.assertEquals(true, builder.getLogEntryEvent().MessageMasked__c);
        System.assertNotEquals(message, builder.getLogEntryEvent().Message__c);
        System.assertEquals(expectedSanitizedMessage, builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_apply_social_security_number_data_mask_rule_when_enabled() {
        Logger.getUserSettings().ApplyDataMaskRules__c = true;
        LogEntryDataMaskRule__mdt rule = getSocialSecurityNumberDataMaskRule();
        System.assertEquals(true, rule.ApplyToMessage__c);
        System.assertEquals(true, rule.ApplyToRecordJson__c);
        LogEntryEventBuilder.addMockDataMaskRule(rule);

        String message = 'Something, something, something and in case you want to steal my identity, my social is 400 11 9999 and something else';
        String expectedSanitizedMessage = 'Something, something, something and in case you want to steal my identity, my social is XXX-XX-9999 and something else';
        Account account = new Account(Name = message);
        String accountJson = JSON.serializePretty(account);
        String expectedSanitizedAccountJson = JSON.serializePretty(new Account(Name = expectedSanitizedMessage));
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setMessage(message).setRecord(account);

        System.assertEquals(true, builder.getLogEntryEvent().MessageMasked__c);
        System.assertNotEquals(message, builder.getLogEntryEvent().Message__c);
        System.assertEquals(expectedSanitizedMessage, builder.getLogEntryEvent().Message__c);
        System.assertEquals(true, builder.getLogEntryEvent().RecordJsonMasked__c);
        System.assertNotEquals(accountJson, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(expectedSanitizedAccountJson, builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_not_apply_credit_card_number_data_mask_rule_when_disabled() {
        Logger.getUserSettings().ApplyDataMaskRules__c = false;
        LogEntryEventBuilder.addMockDataMaskRule(getCreditCardNumberDataMaskRule());

        String message = 'Something, something, something credit card 4000-1111-2222-3333 and something else';
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setMessage(message);

        System.assertEquals(message, builder.getLogEntryEvent().Message__c);
    }

    @IsTest
    static void it_should_not_apply_social_security_number_data_mask_rule_when_disabled() {
        Logger.getUserSettings().ApplyDataMaskRules__c = false;
        LogEntryEventBuilder.addMockDataMaskRule(getSocialSecurityNumberDataMaskRule());

        String message = 'Something, something, something and in case you want to steal my identity, my social is 400-11-9999 and something else';
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setMessage(message);

        System.assertEquals(message, builder.getLogEntryEvent().Message__c);
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
    static void it_should_set_database_result_fields_for_successful_deleteResult() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        Database.DeleteResult deleteResult = Database.delete(log, false);
        System.assertEquals(true, deleteResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(deleteResult);

        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(deleteResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_failed_deleteResult() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        // Delete the log twice to trigger a DeleteResult error
        delete log;
        Database.DeleteResult deleteResult = Database.delete(log, false);
        System.assertEquals(false, deleteResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(deleteResult);

        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(deleteResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    // TODO only some standard objects can be merged - need to find a way to either mock or trigger a merge result that works in all orgs
    // @IsTest
    // static void it_should_set_database_result_fields_for_failed_mergeResult() {
    //     Database.MergeResult mergeResult = Database.merge(new Account(Name='Expcted'), new Account(Name='Failure'), false);
    //     System.assertEquals(false, mergeResult.isSuccess());

    //     LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

    //     Test.startTest();
    //     builder.setDatabaseResult(mergeResult);
    //     Test.stopTest();

    //     LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

    //     System.assertEquals(JSON.serializePretty(mergeResult), logEntryEvent.DatabaseResultJson__c);
    //     System.assertEquals(Database.MergeResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    // }

    @IsTest
    static void it_should_set_database_result_fields_for_successful_saveResult() {
        Database.SaveResult saveResult = Database.insert(new Log__c(TransactionId__c = '1234'), false);
        System.assertEquals(true, saveResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(saveResult);

        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(saveResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_failed_saveResult() {
        Database.SaveResult saveResult = Database.insert(new Account(), false);
        System.assertEquals(false, saveResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(saveResult);

        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(saveResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_successful_undeleteResult() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        delete log;

        Database.UndeleteResult undeleteResult = Database.undelete(log.Id, false);
        System.assertEquals(true, undeleteResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(undeleteResult);

        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_failed_undeleteResult() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        delete log;
        // Hard delete to (later) cause an undelete error
        Database.emptyRecycleBin(log);

        Database.UndeleteResult undeleteResult = Database.undelete(log.Id, false);
        System.assertEquals(false, undeleteResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(undeleteResult);

        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(undeleteResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_successful_upsertResult_when_insert() {
        // UpsertResult for a new record insert
        Database.UpsertResult upsertResult = Database.upsert(new Log__c(TransactionId__c = '1234'), false);
        System.assertEquals(true, upsertResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(upsertResult);

        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_failed_upsertResult_when_insert() {
        // UpsertResult for a new record insert
        Database.UpsertResult upsertResult = Database.upsert(new Account(), false);
        System.assertEquals(false, upsertResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(upsertResult);

        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_successful_upsertResult_when_update() {
        // UpsertResult for an existing record update
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        log.TransactionId__c = '9876';

        Database.UpsertResult upsertResult = Database.upsert(log, false);
        System.assertEquals(true, upsertResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(upsertResult);

        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_failed_upsertResult_when_update() {
        // UpsertResult for an existing record update
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        // Use a log entry this time to handle the upsert scenario
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, Name = 'Test Log Entry');
        insert logEntry;

        // Set name field to a value too long for the field
        Integer maxFieldLength = Schema.LogEntry__c.Name.getDescribe().getLength();
        logEntry.Name = '0'.repeat(maxFieldLength + 10);

        Database.UpsertResult upsertResult = Database.upsert(logEntry, false);
        System.assertEquals(false, upsertResult.isSuccess());

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(upsertResult);

        System.assertEquals('Single', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResult), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_successful_deleteResult() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
            logs.add(log);
        }
        insert logs;

        List<Database.DeleteResult> deleteResults = Database.delete(logs, false);
        for (Database.DeleteResult deleteResult : deleteResults) {
            System.assertEquals(true, deleteResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(deleteResults);

        System.assertEquals('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(deleteResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_failed_deleteResult() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
            logs.add(log);
        }
        insert logs;

        // Delete the logs twice to trigger DeleteResult errors
        delete logs;

        List<Database.DeleteResult> deleteResults = Database.delete(logs, false);
        for (Database.DeleteResult deleteResult : deleteResults) {
            System.assertEquals(false, deleteResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(deleteResults);

        System.assertEquals('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(deleteResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.DeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    // TODO only some standard objects can be merged - need to find a way to either mock or trigger a merge result that works in all orgs
    // @IsTest
    // static void it_should_set_database_result_fields_for_list_of_failed_mergeResult() {
    //     Database.MergeResult mergeResult = Database.merge(new Account(Name='Expcted'), new Account(Name='Failure'), false);
    //     System.assertEquals(false, mergeResult.isSuccess());

    //     LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);

    //     Test.startTest();
    //     builder.setDatabaseResult(mergeResult);
    //     Test.stopTest();

    //     LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();

    //     System.assertEquals(JSON.serializePretty(mergeResult), logEntryEvent.DatabaseResultJson__c);
    //     System.assertEquals(Database.MergeResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    // }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_successful_saveResult() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
            logs.add(log);
        }
        List<Database.SaveResult> saveResults = Database.insert(logs, false);
        for (Database.SaveResult saveResult : saveResults) {
            System.assertEquals(true, saveResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(saveResults);

        System.assertEquals('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(saveResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_failed_saveResult() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            Account account = new Account();
            accounts.add(account);
        }
        List<Database.SaveResult> saveResults = Database.insert(accounts, false);
        for (Database.SaveResult saveResult : saveResults) {
            System.assertEquals(false, saveResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(saveResults);

        System.assertEquals('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(saveResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.SaveResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_successful_undeleteResult() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
            logs.add(log);
        }
        insert logs;
        delete logs;

        List<Database.UndeleteResult> undeleteResults = Database.undelete(logs, false);
        for (Database.UndeleteResult undeleteResult : undeleteResults) {
            System.assertEquals(true, undeleteResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(undeleteResults);

        System.assertEquals('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_failed_undeleteResult() {
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
            logs.add(log);
        }
        insert logs;
        delete logs;
        // Hard delete to (later) cause an undelete error
        Database.emptyRecycleBin(logs);

        List<Database.UndeleteResult> undeleteResults = Database.undelete(logs, false);
        for (Database.UndeleteResult undeleteResult : undeleteResults) {
            System.assertEquals(false, undeleteResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(undeleteResults);

        System.assertEquals('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(undeleteResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_successful_upsertResult_when_insert() {
        // UpsertResult for a new record insert
        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 5; i++) {
            Log__c log = new Log__c(TransactionId__c = '1234' + i);
            logs.add(log);
        }
        List<Database.UpsertResult> upsertResults = Database.upsert(logs, false);
        for (Database.UpsertResult upsertResult : upsertResults) {
            System.assertEquals(true, upsertResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(upsertResults);

        System.assertEquals('List', builder.getLogEntryEvent().DatabaseResultCollectionType__c);
        System.assertEquals(JSON.serializePretty(upsertResults), builder.getLogEntryEvent().DatabaseResultJson__c);
        System.assertEquals(Database.UpsertResult.class.getName(), builder.getLogEntryEvent().DatabaseResultType__c);
    }

    @IsTest
    static void it_should_set_database_result_fields_for_list_of_failed_upsertResult_when_insert() {
        // UpsertResult for a new record insert
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            Account account = new Account();
            accounts.add(account);
        }
        List<Database.UpsertResult> upsertResults = Database.upsert(accounts, false);
        for (Database.UpsertResult upsertResult : upsertResults) {
            System.assertEquals(false, upsertResult.isSuccess());
        }

        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        builder.setDatabaseResult(upsertResults);

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

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        builder.setRecordId(log.Id);

        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(log.Id, builder.getLogEntryEvent().RecordId__c);
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

        Test.startTest();

        LogStatus__mdt status = [SELECT Id, MasterLabel, DeveloperName FROM LogStatus__mdt LIMIT 1];
        builder.setRecordId(status.Id);

        Test.stopTest();

        System.assertEquals('Single', builder.getLogEntryEvent().RecordCollectionType__c);
        System.assertEquals(status.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Metadata Type Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(LogStatus__mdt.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_record_when_standard_object() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectType__c);
        System.assertEquals(null, builder.getLogEntryEvent().RecordSObjectTypeNamespace__c);

        Test.startTest();

        User currentUser = [SELECT Id, Name, ProfileId, Profile.Name, IsActive FROM User WHERE Id = :UserInfo.getUserId()];
        builder.setRecordId(currentUser);

        Test.stopTest();

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

        Test.startTest();

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        builder.setRecordId(log);

        Test.stopTest();

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

        Test.startTest();

        LogStatus__mdt status = [SELECT Id, MasterLabel, DeveloperName FROM LogStatus__mdt LIMIT 1];
        builder.setRecordId(status);

        Test.stopTest();

        System.assertEquals(status.Id, builder.getLogEntryEvent().RecordId__c);
        System.assertEquals(JSON.serializePretty(status), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals('Custom Metadata Type Object', builder.getLogEntryEvent().RecordSObjectClassification__c);
        System.assertEquals(LogStatus__mdt.SObjectType.getDescribe().getName(), builder.getLogEntryEvent().RecordSObjectType__c);
    }

    @IsTest
    static void it_should_strip_inaccessible_fields_for_record_when_enabled() {
        User standardUser = LoggerTestUtils.createStandardUser();
        AccountBrand mockAccountBrand = new AccountBrand(
            Id = LoggerTestUtils.createMockId(Schema.AccountBrand.SObjectType),
            CompanyName = 'Some Company, Inc.',
            Email = 'some.one@some.company.com',
            Name = 'Something',
            Phone = '510-555-1234'
        );
        // The 'standard user' profile doesn't have access to AccountBrand,
        // so stripAccessible will remove everything except the ID field
        AccountBrand strippedAccountBrand = new AccountBrand(Id = mockAccountBrand.Id);

        LogEntryEventBuilder builder;
        System.runAs(standardUser) {
            System.assertEquals(false, Schema.AccountBrand.SObjectType.getDescribe().isAccessible());
            System.assertEquals(false, Schema.AccountBrand.CompanyName.getDescribe().isAccessible());
            System.assertEquals(false, Schema.AccountBrand.Email.getDescribe().isAccessible());
            System.assertEquals(false, Schema.AccountBrand.Name.getDescribe().isAccessible());
            System.assertEquals(false, Schema.AccountBrand.Phone.getDescribe().isAccessible());

            Logger.getUserSettings().StripInaccessibleRecordFields__c = true;
            builder = new LogEntryEventBuilder(LoggingLevel.INFO, true).setRecord(mockAccountBrand);
        }

        System.assertNotEquals(JSON.serializePretty(mockAccountBrand), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(strippedAccountBrand), builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_strip_inaccessible_fields_for_records_when_enabled() {
        User standardUser = LoggerTestUtils.createStandardUser();
        List<AccountBrand> mockAccountBrands = new List<AccountBrand>();
        List<AccountBrand> strippedAccountBrands = new List<AccountBrand>();
        for (Integer i = 0; i < 5; i++) {
            AccountBrand mockAccountBrand = new AccountBrand(
                Id = LoggerTestUtils.createMockId(Schema.AccountBrand.SObjectType),
                CompanyName = 'Some Company, Inc.',
                Email = 'some.one.number_' + i + '@some.company.com',
                Name = 'Something',
                Phone = '510-555-1234'
            );
            mockAccountBrands.add(mockAccountBrand);

            // The 'standard user' profile doesn't have access to AccountBrand,
            // so stripAccessible will remove everything except the ID field
            AccountBrand strippedAccountBrand = new AccountBrand(Id = mockAccountBrand.Id);
            strippedAccountBrands.add(strippedAccountBrand);
        }

        LogEntryEventBuilder builder;
        System.runAs(standardUser) {
            System.assertEquals(false, Schema.AccountBrand.SObjectType.getDescribe().isAccessible());
            System.assertEquals(false, Schema.AccountBrand.CompanyName.getDescribe().isAccessible());
            System.assertEquals(false, Schema.AccountBrand.Email.getDescribe().isAccessible());
            System.assertEquals(false, Schema.AccountBrand.Name.getDescribe().isAccessible());
            System.assertEquals(false, Schema.AccountBrand.Phone.getDescribe().isAccessible());

            Logger.getUserSettings().StripInaccessibleRecordFields__c = true;
            builder = new LogEntryEventBuilder(LoggingLevel.INFO, true).setRecord(mockAccountBrands);
        }

        System.assertNotEquals(JSON.serializePretty(mockAccountBrands), builder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(JSON.serializePretty(strippedAccountBrands), builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_skip_stripping_inaccessible_fields_for_aggregate_result() {
        User standardUser = LoggerTestUtils.createStandardUser();
        AggregateResult mockAggregateResult = LoggerTestUtils.createMockAggregateResult();

        LogEntryEventBuilder builder;
        System.runAs(standardUser) {
            Logger.getUserSettings().StripInaccessibleRecordFields__c = true;
            builder = new LogEntryEventBuilder(LoggingLevel.INFO, true).setRecord(mockAggregateResult);
        }

        System.assertEquals(JSON.serializePretty(mockAggregateResult), builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_skip_stripping_inaccessible_fields_for_aggregate_results() {
        User standardUser = LoggerTestUtils.createStandardUser();
        List<AggregateResult> mockAggregateResults = new List<AggregateResult>{ LoggerTestUtils.createMockAggregateResult() };

        LogEntryEventBuilder builder;
        System.runAs(standardUser) {
            Logger.getUserSettings().StripInaccessibleRecordFields__c = true;
            builder = new LogEntryEventBuilder(LoggingLevel.INFO, true).setRecord(mockAggregateResults);
        }

        System.assertEquals(JSON.serializePretty(mockAggregateResults), builder.getLogEntryEvent().RecordJson__c);
    }

    @IsTest
    static void it_should_set_record_fields_for_list_of_records() {
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
    static void it_should_set_tags_string_for_list_of_tags() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Tags__c);

        List<String> tags = new List<String>{ 'some-tag', 'another One', 'here\'s one more!' };
        builder.addTags(tags);

        String expectedTagsString = String.escapeSingleQuotes(String.join(tags, '\n'));
        System.assertEquals(expectedTagsString, builder.getLogEntryEvent().Tags__c);
    }

    @IsTest
    static void it_should_deduplicate_tags() {
        LogEntryEventBuilder builder = new LogEntryEventBuilder(LoggingLevel.INFO, true);
        System.assertEquals(null, builder.getLogEntryEvent().Tags__c);

        List<String> tags = new List<String>{ 'duplicate-tag', 'duplicate-tag', 'another One' };
        builder.addTags(tags);

        String expectedTagsString = 'duplicate-tag\nanother One';
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
    static void it_should_set_detailed_fields() {
        // Get expected data
        Organization organization = LoggerTestUtils.getOrganization();
        String organizationEnvironmentType = LoggerTestUtils.getOrganizationEnvironmentType();
        SObject networkSite = LoggerTestUtils.getNetwork();
        User user = LoggerTestUtils.getUser();

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
}
