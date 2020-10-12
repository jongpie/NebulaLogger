/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
@isTest
private class Logger_Tests {

    private class Logger_TestsException extends Exception {}

    static User getCurrentUser() {
        return new User(
            Id = UserInfo.getUserId()
        );
    }

    static void setUserLoggingLevel(LoggingLevel loggingLevel) {
        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.LoggingLevel__c = loggingLevel.name();
        update settings;
    }

    static String getOriginLocation() {
        String originLocation;
        for(String currentStackTraceLine : new DmlException().getStackTraceString().split('\n')) {
            if(currentStackTraceLine.contains('Logger_Tests.getOriginLocation')) continue;
            if(currentStackTraceLine.contains('.LogEntryBuilder.')) continue;
            if(currentStackTraceLine.contains('.Logger.')) continue;

            originLocation = currentStackTraceLine.substringBefore(':');
            if(originLocation.startsWith('Class.')) {
                originLocation = originLocation.substringAfter('Class.');
            }
            break;
        }

        return originLocation;
    }

    @testSetup
    static void setup() {
        LoggerSettings__c settings       = LoggerSettings__c.getInstance();
        settings.IsEnabled__c            = true;
        settings.EnableSystemMessages__c = false;
        settings.LoggingLevel__c         = LoggingLevel.DEBUG.name();
        upsert settings;
    }

    @isTest
    static void it_should_return_transaction_id() {
        String transactionId = Logger.getTransactionId();
        System.assert(!String.isBlank(transactionId));
        System.assert(Uuid.isValid(transactionId));
    }

    @isTest
    static void it_should_return_user_logging_level() {
        LoggingLevel expectedValue = LoggingLevel.FINE;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.LoggingLevel__c   = expectedValue.name();
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
        settings.IsEnabled__c      = expectedValue;
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_provided_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Boolean expectedValue     = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c      = expectedValue;
        settings.LoggingLevel__c   = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isEnabled(loggingLevel);
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_error_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.ERROR;
        Boolean expectedValue     = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c      = expectedValue;
        settings.LoggingLevel__c   = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isErrorEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_warn_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.WARN;
        Boolean expectedValue     = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c      = expectedValue;
        settings.LoggingLevel__c   = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isWarnEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_info_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.INFO;
        Boolean expectedValue     = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c      = expectedValue;
        settings.LoggingLevel__c   = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isInfoEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_debug_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.DEBUG;
        Boolean expectedValue     = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c      = expectedValue;
        settings.LoggingLevel__c   = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isDebugEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_fine_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.FINE;
        Boolean expectedValue     = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c      = expectedValue;
        settings.LoggingLevel__c   = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isFineEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_finer_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.FINER;
        Boolean expectedValue     = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c      = expectedValue;
        settings.LoggingLevel__c   = loggingLevel.name();
        update settings;

        Test.startTest();
        Boolean returnedValue = Logger.isFinerEnabled();
        Test.stopTest();

        System.assertEquals(expectedValue, returnedValue);
    }

    @isTest
    static void it_should_return_true_when_finest_logging_level_is_enabled() {
        LoggingLevel loggingLevel = LoggingLevel.FINEST;
        Boolean expectedValue     = true;

        LoggerSettings__c settings = LoggerSettings__c.getInstance();
        settings.IsEnabled__c      = expectedValue;
        settings.LoggingLevel__c   = loggingLevel.name();
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

        for(Integer i = 0; i < logEntriesToCreate; i++) {
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

    @isTest
    static void it_should_return_logging_level() {
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
    static void it_should_log_a_error_entry_string() {
        String message = 'test message';

        setUserLoggingLevel(LoggingLevel.ERROR);

        Test.startTest();

        Logger.error(message);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.ERROR.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_log_a_error_entry_log_message() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());

        setUserLoggingLevel(LoggingLevel.ERROR);

        Test.startTest();

        Logger.error(logMessage);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.ERROR.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }
// public static void error(String message, List<String> topics) {
//     error().setMessage(message).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_error_entry_string_for_record() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.ERROR);

        Test.startTest();

        Logger.error(message, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.ERROR.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_error_entry_logMessage_for_record() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.ERROR);

        Test.startTest();

        Logger.error(logMessage, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.ERROR.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void error(String message, SObject record, List<String> topics) {
//     error().setMessage(message).setRecordId(record).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_error_entry_string_for_record_id() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.ERROR);

        Test.startTest();

        Logger.error(message, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.ERROR.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_error_entry_logMessage_for_record_id() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.ERROR);

        Test.startTest();

        Logger.error(logMessage, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.ERROR.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void error(String message, Id recordId, List<String> topics) {
//     error().setMessage(message).setRecordId(recordId).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_warn_entry_string() {
        String message = 'test message';

        setUserLoggingLevel(LoggingLevel.WARN);

        Test.startTest();

        Logger.warn(message);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.WARN.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_log_a_warn_entry_log_message() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());

        setUserLoggingLevel(LoggingLevel.WARN);

        Test.startTest();

        Logger.warn(logMessage);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.WARN.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }
// public static void warn(String message, List<String> topics) {
//     warn().setMessage(message).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_warn_entry_string_for_record() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.WARN);

        Test.startTest();

        Logger.warn(message, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.WARN.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_warn_entry_logMessage_for_record() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.WARN);

        Test.startTest();

        Logger.warn(logMessage, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.WARN.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void warn(String message, SObject record, List<String> topics) {
//     warn().setMessage(message).setRecordId(record).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_warn_entry_string_for_record_id() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.WARN);

        Test.startTest();

        Logger.warn(message, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.WARN.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_warn_entry_logMessage_for_record_id() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.WARN);

        Test.startTest();

        Logger.warn(logMessage, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.WARN.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void warn(String message, Id recordId, List<String> topics) {
//     warn().setMessage(message).setRecordId(recordId).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_info_entry_string() {
        String message = 'test message';

        setUserLoggingLevel(LoggingLevel.INFO);

        Test.startTest();

        Logger.info(message);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.INFO.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_log_a_info_entry_logMessage() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());

        setUserLoggingLevel(LoggingLevel.INFO);

        Test.startTest();

        Logger.info(logMessage);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.INFO.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }
// public static void info(String message, List<String> topics) {
//     info().setMessage(message).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_info_entry_string_for_record() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.INFO);

        Test.startTest();

        Logger.info(message, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.INFO.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_info_entry_logMessage_for_record() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.INFO);

        Test.startTest();

        Logger.info(logMessage, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.INFO.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void info(String message, SObject record, List<String> topics) {
//     info().setMessage(message).setRecordId(record).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_info_entry_string_for_record_id() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.INFO);

        Test.startTest();

        Logger.info(message, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.INFO.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_info_entry_logMessage_for_record_id() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.INFO);

        Test.startTest();

        Logger.info(logMessage, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.INFO.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void info(String message, Id recordId, List<String> topics) {
//     info().setMessage(message).setRecordId(recordId).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_debug_entry_string() {
        String message = 'test message';

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Test.startTest();

        Logger.debug(message);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.DEBUG.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_log_a_debug_entry_logMessage() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Test.startTest();

        Logger.debug(logMessage);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.DEBUG.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }
// public static void debug(String message, List<String> topics) {
//     debug().setMessage(message).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_debug_entry_string_for_record() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Test.startTest();

        Logger.debug(message, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.DEBUG.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_debug_entry_logMessage_for_record() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Test.startTest();

        Logger.debug(logMessage, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.DEBUG.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void debug(String message, SObject record, List<String> topics) {
//     debug().setMessage(message).setRecordId(record).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_debug_entry_string_for_record_id() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Test.startTest();

        Logger.debug(message, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.DEBUG.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_debug_entry_logMessage_for_record_id() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.DEBUG);

        Test.startTest();

        Logger.debug(logMessage, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.DEBUG.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void debug(String message, Id recordId, List<String> topics) {
//     debug().setMessage(message).setRecordId(recordId).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_fine_entry_string() {
        String message = 'test message';

        setUserLoggingLevel(LoggingLevel.FINE);

        Test.startTest();

        Logger.fine(message);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINE.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_log_a_fine_entry_logMessage() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());

        setUserLoggingLevel(LoggingLevel.FINE);

        Test.startTest();

        Logger.fine(logMessage);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINE.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }
// public static void fine(String message, List<String> topics) {
//     fine().setMessage(message).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_fine_entry_string_for_record() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.FINE);

        Test.startTest();

        Logger.fine(message, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINE.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_fine_entry_logMessage_for_record() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.FINE);

        Test.startTest();

        Logger.fine(logMessage, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINE.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void fine(String message, SObject record, List<String> topics) {
//     fine().setMessage(message).setRecordId(record).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_fine_entry_string_for_record_id() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.FINE);

        Test.startTest();

        Logger.fine(message, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINE.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_fine_entry_logMessage_for_record_id() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.FINE);

        Test.startTest();

        Logger.fine(logMessage, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINE.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void fine(String message, Id recordId, List<String> topics) {
//     fine().setMessage(message).setRecordId(recordId).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_finer_entry_string() {
        String message = 'test message';

        setUserLoggingLevel(LoggingLevel.FINER);

        Test.startTest();

        Logger.finer(message);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINER.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_log_a_finer_entry_logMessage() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());

        setUserLoggingLevel(LoggingLevel.FINER);

        Test.startTest();

        Logger.finer(logMessage);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINER.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }
// public static void finer(String message, List<String> topics) {
//     finer().setMessage(message).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_finer_entry_string_for_record() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.FINER);

        Test.startTest();

        Logger.finer(message, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINER.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_finer_entry_logMessage_for_record() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.FINER);

        Test.startTest();

        Logger.finer(logMessage, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINER.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void finer(String message, SObject record, List<String> topics) {
//     finer().setMessage(message).setRecordId(record).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_finer_entry_string_for_record_id() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.FINER);

        Test.startTest();

        Logger.finer(message, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINER.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_finer_entry_logMessage_for_record_id() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.FINER);

        Test.startTest();

        Logger.finer(logMessage, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINER.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void finer(String message, Id recordId, List<String> topics) {
//     finer().setMessage(message).setRecordId(recordId).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_finest_entry_string() {
        String message = 'test message';

        setUserLoggingLevel(LoggingLevel.FINEST);

        Test.startTest();

        Logger.finest(message);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINEST.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }

    @isTest
    static void it_should_log_a_finest_entry_logMessage() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());

        setUserLoggingLevel(LoggingLevel.FINEST);

        Test.startTest();

        Logger.finest(logMessage);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINEST.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
    }
// public static void finest(String message, List<String> topics) {
//     finest().setMessage(message).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_finest_entry_string_for_record() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.FINEST);

        Test.startTest();

        Logger.finest(message, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINEST.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_finest_entry_logMessage_for_record() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.FINEST);

        Test.startTest();

        Logger.finest(logMessage, currentUser);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINEST.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void finest(String message, SObject record, List<String> topics) {
//     finest().setMessage(message).setRecordId(record).setTopics(topics);
// }

    @isTest
    static void it_should_log_a_finest_entry_string_for_record_id() {
        String message   = 'test message';
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.FINEST);

        Test.startTest();

        Logger.finest(message, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINEST.name(), logEntry.LoggingLevel__c);
        System.assertEquals(message, logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }

    @isTest
    static void it_should_log_a_finest_entry_logMessage_for_record_id() {
        LogMessage logMessage = new LogMessage('test message, {0} is the input', System.now());
        User currentUser = getCurrentUser();

        setUserLoggingLevel(LoggingLevel.FINEST);

        Test.startTest();

        Logger.finest(logMessage, currentUser.Id);
        Logger.saveLog();

        Test.stopTest();

        LogEntry__c logEntry = [SELECT Id, LoggingLevel__c, Message__c, OriginLocation__c, RelatedRecordId__c FROM LogEntry__c];
        System.assertEquals(LoggingLevel.FINEST.name(), logEntry.LoggingLevel__c);
        System.assertEquals(logMessage.getMessage(), logEntry.Message__c);
        System.assertEquals(getOriginLocation(), logEntry.OriginLocation__c);
        System.assertEquals(currentUser.Id, logEntry.RelatedRecordId__c);
    }
// public static void finest(String message, Id recordId, List<String> topics) {
//     finest().setMessage(message).setRecordId(recordId).setTopics(topics);
// }
}