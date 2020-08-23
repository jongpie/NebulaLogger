/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class Logger {

    public enum SaveMethod { DML, REST_API, QUEUEABLE_JOB }

    private static final List<LogEntryBuilder> LOG_ENTRIES = new List<LogEntryBuilder>();
    private static final String TRANSACTION_ID             = new Uuid().getValue();

    private static final LoggerSettings__c SETTINGS      = LoggerSettings__c.getInstance();
    private static final LoggingLevel USER_LOGGING_LEVEL = getLoggingLevel(SETTINGS.LoggingLevel__c);

    private static final QueueableSaver ASYNC_SAVER_INSTANCE {
        get {
            if(ASYNC_SAVER_INSTANCE == null) { ASYNC_SAVER_INSTANCE = new QueueableSaver(); }
            return ASYNC_SAVER_INSTANCE;
        }
        private set;
    }

    private static Boolean suspendSaving            = false;
    private static SaveMethod transactionSaveMethod = SaveMethod.DML;

    // Settings management methods
    public static String getTransactionId() {
        return TRANSACTION_ID;
    }

    public static LoggingLevel getUserLoggingLevel() {
        return getLoggingLevel(getSettings().LoggingLevel__c);
    }

    public static Id getQueueableSaveJobId() {
        return ASYNC_SAVER_INSTANCE.jobId;
    }

    public static Boolean isEnabled() {
        return SETTINGS.IsEnabled__c;
    }

    public static Boolean isEnabled(LoggingLevel loggingLevel) {
        return isEnabled() && meetsUserLoggingLevel(loggingLevel);
    }

    public static Boolean isErrorEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.ERROR);
    }

    public static Boolean isWarnEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.WARN);
    }

    public static Boolean isInfoEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.INFO);
    }

    public static Boolean isDebugEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.DEBUG);
    }

    public static Boolean isFineEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINE);
    }

    public static Boolean isFinerEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINER);
    }

    public static Boolean isFinestEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINEST);
    }

    // Transaction control methods
    public static void setSaveMethod(SaveMethod saveMethod) {
        transactionSaveMethod = saveMethod;
    }

    public static Boolean isSavingSuspended() {
        return suspendSaving;
    }

    public static void suspendSaving() {
        suspendSaving = true;
    }

    public static void resumeSaving() {
        suspendSaving = false;
    }

    public static Integer getBufferSize() {
        return LOG_ENTRIES.size();
    }

    public static void flushBuffer() {
        LOG_ENTRIES.clear();
    }

    // ERROR logging level methods
    public static LogEntryBuilder error() {
        return createLogEntryBuilder(LoggingLevel.ERROR);
    }

    public static void error(String message) {
        error().setMessage(message);
    }

    public static void error(String message, List<String> topics) {
        error().setMessage(message).setTopics(topics);
    }

    public static void error(String message, SObject record) {
        error().setMessage(message).setRecordId(record);
    }

    public static void error(String message, SObject record, List<String> topics) {
        error().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static void error(String message, Id recordId) {
        error().setMessage(message).setRecordId(recordId);
    }

    public static void error(String message, Id recordId, List<String> topics) {
        error().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    public static void error(String message, Exception apexException) {
        error().setMessage(message).setExceptionDetails(apexException);
        if(getSettings().AutoSaveExceptionEntries__c) saveLog();
    }

    public static void error(String message, Exception apexException, List<String> topics) {
        error().setMessage(message).setExceptionDetails(apexException).setTopics(topics);
        if(getSettings().AutoSaveExceptionEntries__c) saveLog();
    }

     public static void error(String message, Exception apexException, Id recordId) {
        error().setMessage(message).setExceptionDetails(apexException).setRecordId(recordId);
        if(getSettings().AutoSaveExceptionEntries__c) saveLog();
    }

    public static void error(String message, Exception apexException, Id recordId, List<String> topics) {
        error().setMessage(message).setExceptionDetails(apexException).setRecordId(recordId).setTopics(topics);
        if(getSettings().AutoSaveExceptionEntries__c) saveLog();
    }

    // WARN logging level methods
    public static LogEntryBuilder warn() {
        return createLogEntryBuilder(LoggingLevel.WARN);
    }

    public static void warn(String message) {
        warn().setMessage(message);
    }

    public static void warn(String message, List<String> topics) {
        warn().setMessage(message).setTopics(topics);
    }

    public static void warn(String message, SObject record) {
        warn().setMessage(message).setRecordId(record);
    }

    public static void warn(String message, SObject record, List<String> topics) {
        warn().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static void warn(String message, Id recordId) {
        warn().setMessage(message).setRecordId(recordId);
    }

    public static void warn(String message, Id recordId, List<String> topics) {
        warn().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    // INFO logging level methods
    public static LogEntryBuilder info() {
        return createLogEntryBuilder(LoggingLevel.INFO);
    }

    public static void info(String message) {
        info().setMessage(message);
    }

    public static void info(String message, List<String> topics) {
        info().setMessage(message).setTopics(topics);
    }

    public static void info(String message, SObject record) {
        info().setMessage(message).setRecordId(record);
    }

    public static void info(String message, SObject record, List<String> topics) {
        info().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static void info(String message, Id recordId) {
        info().setMessage(message).setRecordId(recordId);
    }

    public static void info(String message, Id recordId, List<String> topics) {
        info().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    // DEBUG log level methods
    public static LogEntryBuilder debug() {
        return createLogEntryBuilder(LoggingLevel.DEBUG);
    }

    public static void debug(String message) {
        debug().setMessage(message);
    }

    public static void debug(String message, List<String> topics) {
        debug().setMessage(message).setTopics(topics);
    }

    public static void debug(String message, SObject record) {
        debug().setMessage(message).setRecordId(record);
    }

    public static void debug(String message, SObject record, List<String> topics) {
        debug().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static void debug(String message, Id recordId) {
        debug().setMessage(message).setRecordId(recordId);
    }

    public static void debug(String message, Id recordId, List<String> topics) {
        debug().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    // FINE log level methods
    public static LogEntryBuilder fine() {
        return createLogEntryBuilder(LoggingLevel.FINE);
    }

    public static void fine(String message) {
        fine().setMessage(message);
    }

    public static void fine(String message, List<String> topics) {
        fine().setMessage(message).setTopics(topics);
    }

    public static void fine(String message, SObject record) {
        fine().setMessage(message).setRecordId(record);
    }

    public static void fine(String message, SObject record, List<String> topics) {
        fine().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static void fine(String message, Id recordId) {
        fine().setMessage(message).setRecordId(recordId);
    }

    public static void fine(String message, Id recordId, List<String> topics) {
        fine().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    // FINER log level methods
    public static LogEntryBuilder finer() {
        return createLogEntryBuilder(LoggingLevel.FINER);
    }

    public static void finer(String message) {
        finer().setMessage(message);
    }

    public static void finer(String message, List<String> topics) {
        finer().setMessage(message).setTopics(topics);
    }

    public static void finer(String message, SObject record) {
        finer().setMessage(message).setRecordId(record);
    }

    public static void finer(String message, SObject record, List<String> topics) {
        finer().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static void finer(String message, Id recordId) {
        finer().setMessage(message).setRecordId(recordId);
    }

    public static void finer(String message, Id recordId, List<String> topics) {
        finer().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    // FINEST log level methods
    public static LogEntryBuilder finest() {
        return createLogEntryBuilder(LoggingLevel.FINEST);
    }

    public static void finest(String message) {
        finest().setMessage(message);
    }

    public static void finest(String message, List<String> topics) {
        finest().setMessage(message).setTopics(topics);
    }

    public static void finest(String message, SObject record) {
        finest().setMessage(message).setRecordId(record);
    }

    public static void finest(String message, SObject record, List<String> topics) {
        finest().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static void finest(String message, Id recordId) {
        finest().setMessage(message).setRecordId(recordId);
    }

    public static void finest(String message, Id recordId, List<String> topics) {
        finest().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    @InvocableMethod(label='Save Log' description='Saves any log entries that have been generated')
    public static void saveLog() {
        saveLog(transactionSaveMethod);
    }

    public static void saveLog(SaveMethod transactionSaveMethod) {
        if(LOG_ENTRIES.isEmpty()) return;

        if(suspendSaving) {
            String suspendSavingLogMessage = 'Logging suspended, ignoring call to saveLog()';
            //finest(suspendSavingLogMessage);

            return;
        }

        String savingLogMessage = 'Saving ' + LOG_ENTRIES.size() + ' log entries via ';
        switch on transactionSaveMethod {
            when DML           { savingLogMessage += 'Apex DML'; }
            when QUEUEABLE_JOB { savingLogMessage += 'Apex queueable job'; }
            when REST_API      { savingLogMessage += 'Apex REST callout'; }
        }
        //finest(savingLogMessage);

        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        for(LogEntryBuilder logEntryGenerator : LOG_ENTRIES) {
            LogEntryEvent__e logEntryEvent = logEntryGenerator.getLogEntryEvent();
            System.debug('logEntryEvent=' + logEntryEvent);
            logEntryEvents.add(logEntryEvent);
        }

        switch on transactionSaveMethod {
            when DML           { EventBus.publish(logEntryEvents); }
            when QUEUEABLE_JOB { ASYNC_SAVER_INSTANCE.enqueueLogEntries(logEntryEvents); }
            when REST_API      { RestApi.insertRecords(logEntryEvents); }
        }

        // TODO add error handling for when event bus fails to publish

        flushBuffer();
    }

    // Utility methods
    public static LoggingLevel getLoggingLevel(String loggingLevelName) {
        if(loggingLevelName != null) loggingLevelName = loggingLevelName.toUpperCase();

        switch on loggingLevelName {
            when 'NONE'   { return LoggingLevel.NONE;   }
            when 'ERROR'  { return LoggingLevel.ERROR;  }
            when 'WARN'   { return LoggingLevel.WARN;   }
            when 'INFO'   { return LoggingLevel.INFO;   }
            when 'DEBUG'  { return LoggingLevel.DEBUG;  }
            when 'FINE'   { return LoggingLevel.FINE;   }
            when 'FINER'  { return LoggingLevel.FINER;  }
            when 'FINEST' { return LoggingLevel.FINEST; }
            when else     {
                LoggingLevel fallbackLevel = LoggingLevel.DEBUG;
                String message = 'Unknown logging level ' + loggingLevelName + 'specified, using ' + fallbackLevel.Name();
                //finest(message);
                return LoggingLevel.DEBUG;
            }
        }
    }

    public static LogEntryBuilder createLogEntryBuilder(LoggingLevel loggingLevel) {
        LogEntryBuilder logEntryBuilder = new LogEntryBuilder(LoggingLevel);
        if(LoggerSettings.isEnabled(loggingLevel)) {
            LOG_ENTRIES.add(logEntryBuilder);
        }

        return logEntryBuilder;
    }

    @AuraEnabled
    public static Log__c getLog(Id logId) {
        List<String> logFieldNames      = new List<String>(Schema.Log__c.SObjectType.getDescribe().fields.getMap().keySet());
        List<String> logEntryFieldNames = new List<String>(Schema.LogEntry__c.SObjectType.getDescribe().fields.getMap().keySet());

        List<String> textReplacements = new List<String>{String.join(logFieldNames, ','), String.join(logEntryFieldNames, ',')};
        String query = String.format('SELECT {0}, (SELECT {1} FROM LogEntries__r) FROM Log__c WHERE Id = :logId', textReplacements);

        return (Log__c)Database.query(query);
    }

    // Private methods
    private static LoggerSettings__c getSettings() {
        return LoggerSettings__c.getInstance();
    }

    private static Boolean meetsUserLoggingLevel(LoggingLevel logEntryLoggingLevel) {
        return USER_LOGGING_LEVEL.ORDINAL() <= logEntryLoggingLevel.ORDINAL();
    }

    // Private inner class for saving log entries via a queuable job (using a singleton pattern)
    private class QueueableSaver implements Queueable {
        public Id jobId;

        private List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();

        public void enqueueLogEntries(List<LogEntryEvent__e> logEntryEvents) {
            this.logEntryEvents.addAll(logEntryEvents);

            if(jobId == null) jobId = System.enqueueJob(this);
        }

        public void execute(System.QueueableContext queueableContext) {
            EventBus.publish(this.logEntryEvents);
        }
    }

}