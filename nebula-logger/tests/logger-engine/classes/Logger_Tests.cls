//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//
@isTest
private class Logger_Tests {
    // Helper classes
    private class Logger_TestsException extends Exception {
    }

    private class SuccessCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setBody(request.getBody());
            response.setStatusCode(200);
            return response;
        }
    }

    private class FailureCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setBody(request.getBody());
            response.setStatusCode(400);
            return response;
        }
    }

    // Helper methods
    static User getCurrentUser() {
        return new User(Id = UserInfo.getUserId());
    }

    static void setUserLoggingLevel(LoggingLevel loggingLevel) {
        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.LoggingLevel__c = loggingLevel.name();
        update settings;
    }

    static String getMessage() {
        return 'Hello, world';
    }

    static LogMessage getLogMessage() {
        return new LogMessage('The current user is {0}', getRecord());
    }

    static SObject getRecord() {
        return new User(
            Id = UserInfo.getUserId(),
            ProfileId = UserInfo.getProfileId(),
            Username = UserInfo.getUserName(),
            UserRoleId = UserInfo.getUserRoleId()
        );
    }

    static Exception getException() {
        return new DmlException('Example DML Exception');
    }

    static Database.DeleteResult getDeleteResult(Boolean isSuccess) {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        if (isSuccess == false) {
            // Delete the log twice to trigger a DeleteResult error
            delete log;
        }

        Database.DeleteResult deleteResult = Database.delete(log, false);
        System.assertEquals(isSuccess, deleteResult.isSuccess());

        return deleteResult;
    }

    // TODO only some standard objects can be merged - need to find a way to either mock or trigger a merge result that works in all orgs
    // static Database.MergeResult getMergeResult(Boolean isSuccess) { }

    static Database.SaveResult getSaveResult(Boolean isSuccess) {
        Database.SaveResult saveResult;

        if (isSuccess == false) {
            saveResult = Database.insert(new Account(), false);
        } else {
            saveResult = Database.insert(new Log__c(TransactionId__c = '1234'), false);
        }
        System.assertEquals(isSuccess, saveResult.isSuccess());
        return saveResult;
    }

    static Database.UpsertResult getUpsertResult(Boolean isSuccess, Boolean isInsert) {
        Database.UpsertResult upsertResult;

        if (isSuccess == false && isInsert == true) {
            upsertResult = Database.upsert(new Account(), false);
        } else if (isSuccess == true && isInsert == true) {
            upsertResult = Database.upsert(new Log__c(TransactionId__c = '1234'), false);
        } else if (isSuccess == true && isInsert == false) {
            Log__c log = new Log__c(TransactionId__c = '1234');
            insert log;
            log.TransactionId__c = '9876';

            upsertResult = Database.upsert(log, false);
        } else if (isSuccess == false && isInsert == false) {
            Log__c log = new Log__c(TransactionId__c = '1234');
            insert log;

            // Use a log entry this time to handle the upsert scenario
            LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, Name = 'Test Log Entry');
            insert logEntry;

            // Set name field to a value too long for the field
            Integer maxFieldLength = Schema.LogEntry__c.Name.getDescribe().getLength();
            logEntry.Name = '0'.repeat(maxFieldLength + 10);

            upsertResult = Database.upsert(logEntry, false);
        }
        System.assertEquals(isSuccess, upsertResult.isSuccess());
        System.assertEquals(isInsert, upsertResult.isCreated());
        return upsertResult;
    }

    static Database.UndeleteResult getUndeleteResult(Boolean isSuccess) {
        Database.UndeleteResult undeleteResult;

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        delete log;

        if (isSuccess == false) {
            // Hard delete to cause an undelete error
            Database.emptyRecycleBin(log);

            undeleteResult = Database.undelete(log.Id, false);
        } else {
            undeleteResult = Database.undelete(log.Id, false);
        }
        System.assertEquals(isSuccess, undeleteResult.isSuccess());
        return undeleteResult;
    }

    static List<String> getTopics() {
        return new List<String>{ 'some topic', 'another topic', 'yet another one' };
    }

    static String getOriginLocation() {
        String originLocation;
        for (String currentStackTraceLine : new DmlException().getStackTraceString().split('\n')) {
            if (currentStackTraceLine.contains('Logger_Tests.getOriginLocation'))
                continue;
            if (currentStackTraceLine.contains('.LogEntryEventBuilder.'))
                continue;
            if (currentStackTraceLine.contains('.Logger.'))
                continue;

            originLocation = currentStackTraceLine.substringBefore(':');
            if (originLocation.startsWith('Class.')) {
                originLocation = originLocation.substringAfter('Class.');
            }
            break;
        }

        return originLocation;
    }

    @testSetup
    static void setup() {
        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c = true;
        settings.EnableSystemMessages__c = false;
        settings.LoggingLevel__c = LoggingLevel.DEBUG.name();
        upsert settings;
    }

    @isTest
    static void it_should_auto_create_org_default_settings_when_not_configured() {
        delete [SELECT Id FROM LoggerSettings__c];
        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.assertEquals(0, existingSettings.size());

        Test.startTest();
        Logger.isEnabled();
        Test.stopTest();

        existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.assertEquals(1, existingSettings.size());

        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        System.assertEquals(orgDefaults.Id, existingSettings.get(0).Id);
    }

    @isTest
    static void it_should_return_transaction_id() {
        String transactionId = Logger.getTransactionId();
        System.assert(!String.isBlank(transactionId));
    }

    @isTest
    static void it_should_return_set_parent_transaction_id() {
        String expectedParentTransactionId = 'imagineThisWereAGuid';
        Logger.setParentLogTransactionId(expectedParentTransactionId);
        System.assertEquals(expectedParentTransactionId, Logger.getParentLogTransactionId());
    }

    @isTest
    static void it_should_return_quiddity_level() {
        List<Quiddity> acceptableDefaultQuidditiesForTests = new List<Quiddity>{ Quiddity.RUNTEST_ASYNC, Quiddity.RUNTEST_DEPLOY, Quiddity.RUNTEST_SYNC };
        System.assertEquals(true, acceptableDefaultQuidditiesForTests.contains(Logger.getCurrentQuiddity()));

        System.assertEquals(System.Request.getCurrent().getQuiddity(), Logger.getCurrentQuiddity());
    }

    @isTest
    static void it_should_return_user_logging_level() {
        LoggingLevel expectedValue = LoggingLevel.FINE;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.LoggingLevel__c = expectedValue.name();
        update settings;

        Test.startTest();
        LoggingLevel returnedValue = Logger.getUserLoggingLevel();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_enabled() {
        Boolean expectedValue = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c = expectedValue;
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_provided_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Boolean expectedValue = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c = expectedValue;
        settings.LoggingLevel__c = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isEnabled(loggingLevel);
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_error_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        Boolean expectedValue = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c = expectedValue;
        settings.LoggingLevel__c = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isErrorEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_warn_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        Boolean expectedValue = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c = expectedValue;
        settings.LoggingLevel__c = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isWarnEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_info_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        Boolean expectedValue = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c = expectedValue;
        settings.LoggingLevel__c = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isInfoEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_debug_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        Boolean expectedValue = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c = expectedValue;
        settings.LoggingLevel__c = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isDebugEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_fine_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Boolean expectedValue = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c = expectedValue;
        settings.LoggingLevel__c = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isFineEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_finer_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        Boolean expectedValue = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c = expectedValue;
        settings.LoggingLevel__c = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isFinerEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_finest_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        Boolean expectedValue = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c = expectedValue;
        settings.LoggingLevel__c = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isFinestEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_saving_is_suspended() {
        System.assertEquals(false, Logger.isSavingSuspended());

        Test.startTest();
        Logger.suspendSaving();
        Test.stopTest();

        System.assertEquals(true, Logger.isSavingSuspended());
    }

    @isTest
    static void it_should_suspend_saving() {
        setUserLoggingLevel(LoggingLevel.DEBUG);

        Integer countOfExistingLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfExistingLogEntries);

        Test.startTest();

        Logger.suspendSaving();

        Logger.debug('test log entry');
        Logger.saveLog();

        Test.stopTest();

        countOfExistingLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfExistingLogEntries);
    }

    @isTest
    static void it_should_resume_saving() {
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        Test.startTest();

        Integer logEntriesToCreate = 4;

        Logger.suspendSaving();

        for (Integer i = 0; i < logEntriesToCreate; i++) {
            Logger.debug('test log entry #' + i);
        }
        Logger.saveLog();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        Logger.resumeSaving();
        Logger.saveLog();

        Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(logEntriesToCreate, countOfLogEntries);
        System.assertEquals(1, Limits.getDmlStatements());
    }

    @isTest
    static void it_should_return_the_buffer_size() {
        System.assertEquals(0, Logger.getBufferSize());

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Test.startTest();

        Logger.debug('test log entry');
        Logger.warn('another test log entry');

        Test.stopTest();

        System.assertEquals(2, Logger.getBufferSize());
    }

    @isTest
    static void it_should_save_via_event_bus() {
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getPublishImmediateDml());

        Test.startTest();

        Logger.saveLog(Logger.SaveMethod.EVENT_BUS);
        System.assertEquals(1, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());

        Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(2, countOfLogEntries);
    }

    @isTest
    static void it_should_save_via_queueable() {
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getQueueableJobs());

        Test.startTest();

        Logger.saveLog(Logger.SaveMethod.QUEUEABLE);
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(1, Limits.getQueueableJobs());
        System.assertEquals(0, Limits.getCallouts());

        Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(2, countOfLogEntries);
    }

    @isTest
    static void it_should_save_via_rest_api() {
        Test.setMock(HttpCalloutMock.class, new SuccessCalloutMock());

        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getCallouts());

        Test.startTest();

        Logger.saveLog(Logger.SaveMethod.REST);
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(1, Limits.getCallouts());

        Test.stopTest();
    }

    @isTest
    static void it_should_throw_exception_when_save_via_rest_api_fails() {
        Test.setMock(HttpCalloutMock.class, new FailureCalloutMock());

        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        System.assertEquals(0, Limits.getCallouts());

        Test.startTest();

        try {
            Logger.saveLog(Logger.SaveMethod.REST);
        } catch (Exception ex) {
            System.assertEquals(ex.getTypeName(), Logger.RestResponseException.class.getName());
        }
        System.assertEquals(0, Limits.getPublishImmediateDml());
        System.assertEquals(0, Limits.getQueueableJobs());
        System.assertEquals(1, Limits.getCallouts());

        Test.stopTest();
    }

    @isTest
    static void it_should_flush_buffer() {
        Integer countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(0, countOfLogEntries);

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Test.startTest();

        Logger.debug('test log entry');
        Logger.debug('another test log entry');

        Logger.flushBuffer();

        Logger.debug('the only log entry to save');
        Logger.saveLog();

        Test.stopTest();

        countOfLogEntries = [SELECT COUNT() FROM LogEntry__c];
        System.assertEquals(1, countOfLogEntries);
    }

    // Start ERROR methods for LogMessage
    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_deleteResult_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), deleteResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_deleteResult_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), deleteResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(deleteResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(deleteResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_saveResult_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), saveResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_saveResult_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), saveResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(saveResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(saveResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_undeleteResult_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), undeleteResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_undeleteResult_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), undeleteResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(undeleteResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(undeleteResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_upsertResult_and_topics_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_upsertResult_and_topics_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(upsertResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_upsertResult_and_topics_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_upsertResult_and_topics_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(upsertResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(upsertResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_successful_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_failed_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(upsertResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_exception_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getException(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordId_and_exception_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord().Id, getException(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordId_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord().Id, getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_record_and_exception_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord(), getException(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_record_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End ERROR methods for LogMessage

    // Start ERROR methods for String
    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_deleteResult_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), deleteResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_deleteResult_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), deleteResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(deleteResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_deleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.DeleteResult deleteResult = getDeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), deleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(deleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(deleteResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.DeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_saveResult_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), saveResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_saveResult_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), saveResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(saveResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_saveResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.SaveResult saveResult = getSaveResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), saveResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(saveResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(saveResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.SaveResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_undeleteResult_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), undeleteResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_undeleteResult_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), undeleteResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(undeleteResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_undeleteResult() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UndeleteResult undeleteResult = getUndeleteResult(false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), undeleteResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(undeleteResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(undeleteResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UndeleteResult.class.getName(), entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_upsertResult_and_topics_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_upsertResult_and_topics_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(upsertResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_upsertResult_and_topics_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_upsertResult_and_topics_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(upsertResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_upsertResult_when_insert() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, true);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(upsertResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Insert', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_successful_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(true, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_failed_upsertResult_when_update() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Database.UpsertResult upsertResult = getUpsertResult(false, false);

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), upsertResult);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(upsertResult.getId(), entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(Json.serializePretty(upsertResult.getErrors()), entryBuilder.getLogEntryEvent().DmlResultErrors__c);
        System.assertEquals(Database.UpsertResult.class.getName() + '.Update', entryBuilder.getLogEntryEvent().DmlResultType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_exception_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getException(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_recordId_and_exception_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord().Id, getException(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_recordId_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord().Id, getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_record_and_exception_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord(), getException(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_record_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_error_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.error(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    // Start WARN methods for LogMessage
    @isTest
    static void it_should_add_an_warn_entry_for_logMessage_with_exception_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getException(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_logMessage_with_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_logMessage_with_recordId_and_exception_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord().Id, getException(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_logMessage_with_recordId_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord().Id, getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_logMessage_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_logMessage_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_logMessage_with_record_and_exception_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord(), getException(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_logMessage_with_record_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_logMessage_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End WARN methods for LogMessage

    // Start WARN methods for String
    @isTest
    static void it_should_add_an_warn_entry_for_string_message_with_exception_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getException(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_string_message_with_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_string_message_with_recordId_and_exception_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord().Id, getException(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_string_message_with_recordId_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord().Id, getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_string_message_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_string_message_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_string_message_with_record_and_exception_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord(), getException(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_string_message_with_record_and_exception() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord(), getException());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(getException().getMessage(), entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(getException().getTypeName(), entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_string_message_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_warn_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.warn(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End WARN methods for String

    // Start INFO methods for LogMessage
    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End INFO methods for LogMessage

    // Start INFO methods for String
    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_info_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.info(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End INFO methods for String

    // Start DEBUG methods for LogMessage
    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End DEBUG methods for LogMessage

    // Start DEBUG methods for String
    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_debug_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.debug(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End DEBUG methods for String

    // Start FINE methods for LogMessage
    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End FINE methods for LogMessage

    // Start FINE methods for String
    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_fine_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.fine(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End FINE methods for String

    // Start FINER methods for LogMessage
    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End FINER methods for LogMessage

    // Start FINER methods for String
    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finer_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finer(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End FINER methods for String

    // Start FINEST methods for LogMessage
    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End FINEST methods for LogMessage

    // Start FINEST methods for String
    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_recordId_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), getRecord().Id, getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_recordId() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), getRecord().Id);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_record_and_topics() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), getRecord(), getTopics());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(String.join(getTopics(), ','), entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message_with_record() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage(), getRecord());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(getRecord().Id, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(Json.serializePretty(getRecord()), entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_add_an_finest_entry_for_string_message() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.finest(getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End FINEST methods for String

    // Start newEntry for LogMessage test methods
    @isTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_logMessage_and_shouldSave_override() {
        LoggingLevel userLoggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        LoggingLevel logEntryLoggingLevel = LoggingLevel.FINEST;
        System.assertEquals(false, Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        Boolean shouldSave = true;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getLogMessage(), shouldSave);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(shouldSave, entryBuilder.shouldSave());
        System.assertEquals(logEntryLoggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_not_add_a_new_entry_for_loggingLevel_with_logMessage_and_shouldNotSave_override() {
        LoggingLevel userLoggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        LoggingLevel logEntryLoggingLevel = LoggingLevel.FINEST;
        System.assertEquals(false, Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        Boolean shouldSave = false;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getLogMessage(), shouldSave);

        Test.stopTest();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(shouldSave, entryBuilder.shouldSave());
        System.assertEquals(null, entryBuilder.getLogEntryEvent());
    }

    @isTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_logMessage() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.newEntry(loggingLevel, getLogMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(true, entryBuilder.shouldSave());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getLogMessage().getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End newEntry for LogMessage test methods

    // Start newEntry for String test methods
    @isTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_string_and_shouldSave_override() {
        LoggingLevel userLoggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        LoggingLevel logEntryLoggingLevel = LoggingLevel.FINEST;
        System.assertEquals(false, Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        Boolean shouldSave = true;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getMessage(), shouldSave);

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(shouldSave, entryBuilder.shouldSave());
        System.assertEquals(logEntryLoggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }

    @isTest
    static void it_should_not_add_a_new_entry_for_loggingLevel_with_string_and_shouldNotSave_override() {
        LoggingLevel userLoggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(userLoggingLevel);
        LoggingLevel logEntryLoggingLevel = LoggingLevel.FINEST;
        System.assertEquals(false, Logger.meetsUserLoggingLevel(logEntryLoggingLevel));
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        Boolean shouldSave = false;
        LogEntryEventBuilder entryBuilder = Logger.newEntry(logEntryLoggingLevel, getMessage(), shouldSave);

        Test.stopTest();

        System.assertEquals(0, Logger.getBufferSize());
        System.assertEquals(shouldSave, entryBuilder.shouldSave());
        System.assertEquals(null, entryBuilder.getLogEntryEvent());
    }

    @isTest
    static void it_should_add_a_new_entry_for_loggingLevel_with_string() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        setUserLoggingLevel(loggingLevel);
        System.assertEquals(0, Logger.getBufferSize());

        Test.startTest();

        LogEntryEventBuilder entryBuilder = Logger.newEntry(loggingLevel, getMessage());

        Test.stopTest();

        System.assertEquals(1, Logger.getBufferSize());
        System.assertEquals(true, entryBuilder.shouldSave());
        System.assertEquals(loggingLevel.name(), entryBuilder.getLogEntryEvent().LoggingLevel__c);
        System.assertEquals(getMessage(), entryBuilder.getLogEntryEvent().Message__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordId__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().RecordJson__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionMessage__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().ExceptionType__c);
        System.assertEquals(null, entryBuilder.getLogEntryEvent().Topics__c);
    }
    // End newEntry for String test methods

    // Start tests for utility methods
    @isTest
    static void it_should_return_logging_levels_for_string_names() {
        System.assertEquals(LoggingLevel.DEBUG, Logger.getLoggingLevel('fake'));
        System.assertEquals(LoggingLevel.NONE, Logger.getLoggingLevel('none'));
        System.assertEquals(LoggingLevel.ERROR, Logger.getLoggingLevel('error'));
        System.assertEquals(LoggingLevel.WARN, Logger.getLoggingLevel('warn'));
        System.assertEquals(LoggingLevel.INFO, Logger.getLoggingLevel('info'));
        System.assertEquals(LoggingLevel.DEBUG, Logger.getLoggingLevel('debug'));
        System.assertEquals(LoggingLevel.FINE, Logger.getLoggingLevel('fine'));
        System.assertEquals(LoggingLevel.FINER, Logger.getLoggingLevel('finer'));
        System.assertEquals(LoggingLevel.FINEST, Logger.getLoggingLevel('finest'));
    }

    @isTest
    static void it_should_return_log_when_id_provided() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        Test.startTest();
        Log__c returnedLog = Logger.getLog(log.Id);
        Test.stopTest();

        System.assertEquals(log.Id, returnedLog.Id);
    }

    @isTest
    static void it_should_return_log_when_transaction_id_provided() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;

        Test.startTest();
        Log__c returnedLog = Logger.getLog(log.TransactionId__c);
        Test.stopTest();

        System.assertEquals(log.Id, returnedLog.Id);
    }
    // End tests for utility methods
}
