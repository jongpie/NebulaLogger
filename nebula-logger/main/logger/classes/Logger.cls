/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class Logger {

    public enum SaveMethod { DML, REST_API, QUEUEABLE_JOB }

    private static final List<LogEntryBuilder> LOG_ENTRIES = new List<LogEntryBuilder>();
    private static final String TRANSACTION_ID             = new Uuid().getValue();

    private static final LoggingLevel USER_LOGGING_LEVEL = getLoggingLevel(LoggerSettings__c.getInstance().LoggingLevel__c);

    private static final QueueableSaver ASYNC_SAVER_INSTANCE = new QueueableSaver();

    private static String parentLogTransactionId;
    private static Boolean suspendSaving            = false;
    private static SaveMethod transactionSaveMethod = SaveMethod.DML;

    // Settings management methods
    public static String getTransactionId() {
        return TRANSACTION_ID;
    }

    public static void setParentLogTransactionId(String transactionId) {
        parentLogTransactionId = transactionId;
    }

    public static String getParentLogTransactionId() {
        return parentLogTransactionId;
    }

    public static LoggingLevel getUserLoggingLevel() {
        return USER_LOGGING_LEVEL;
    }

    public static Id getQueueableSaveJobId() {
        return ASYNC_SAVER_INSTANCE.jobId;
    }

    public static Boolean isEnabled() {
        return LoggerSettings__c.getInstance().IsEnabled__c;
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

    public static Boolean meetsUserLoggingLevel(LoggingLevel logEntryLoggingLevel) {
        return USER_LOGGING_LEVEL.ordinal() <= logEntryLoggingLevel.ordinal();
    }

    // Transaction control methods
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

    public static LogEntryBuilder error(String message) {
        return error().setMessage(message);
    }

    public static LogEntryBuilder error(LogMessage logMessage) {
        return error().setMessage(logMessage);
    }

    public static LogEntryBuilder error(String message, List<String> topics) {
        return error().setMessage(message).setTopics(topics);
    }

    public static LogEntryBuilder error(LogMessage logMessage, List<String> topics) {
        return error().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryBuilder error(String message, SObject record) {
        return error().setMessage(message).setRecordId(record);
    }

    public static LogEntryBuilder error(LogMessage logMessage, SObject record) {
        return error().setMessage(logMessage).setRecordId(record);
    }

    public static LogEntryBuilder error(String message, SObject record, List<String> topics) {
        return error().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder error(LogMessage logMessage, SObject record, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder error(String message, Id recordId) {
        return error().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryBuilder error(LogMessage logMessage, Id recordId) {
        return error().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryBuilder error(String message, Id recordId, List<String> topics) {
        return error().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    public static LogEntryBuilder error(LogMessage logMessage, Id recordId, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    public static LogEntryBuilder error(String message, Exception apexException) {
        return error().setMessage(message).setExceptionDetails(apexException);
    }

    public static LogEntryBuilder error(LogMessage logMessage, Exception apexException) {
        return error().setMessage(logMessage).setExceptionDetails(apexException);
    }

    public static LogEntryBuilder error(String message, Exception apexException, List<String> topics) {
        return error().setMessage(message).setTopics(topics).setExceptionDetails(apexException);
    }

    public static LogEntryBuilder error(LogMessage logMessage, Exception apexException, List<String> topics) {
        return error().setMessage(logMessage).setTopics(topics).setExceptionDetails(apexException);
    }

    public static LogEntryBuilder error(String message, SObject record, Exception apexException) {
        return error().setMessage(message).setRecordId(record).setExceptionDetails(apexException);
    }

    public static LogEntryBuilder error(LogMessage logMessage, SObject record, Exception apexException) {
        return error().setMessage(logMessage).setRecordId(record).setExceptionDetails(apexException);
    }

    public static LogEntryBuilder error(String message, SObject record, Exception apexException, List<String> topics) {
        return error().setMessage(message).setRecordId(record).setTopics(topics).setExceptionDetails(apexException);
    }

    public static LogEntryBuilder error(LogMessage logMessage, SObject record, Exception apexException, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(record).setTopics(topics).setExceptionDetails(apexException);
    }

    public static LogEntryBuilder error(String message, Id recordId, Exception apexException) {
        return error().setMessage(message).setRecordId(recordId).setExceptionDetails(apexException);
    }

    public static LogEntryBuilder error(LogMessage logMessage, Id recordId, Exception apexException) {
        return error().setMessage(logMessage).setRecordId(recordId).setExceptionDetails(apexException);
    }

    public static LogEntryBuilder error(String message, Id recordId, Exception apexException, List<String> topics) {
        return error().setMessage(message).setRecordId(recordId).setTopics(topics).setExceptionDetails(apexException);
    }

    public static LogEntryBuilder error(LogMessage logMessage, Id recordId, Exception apexException, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(recordId).setTopics(topics).setExceptionDetails(apexException);
    }

    // WARN logging level methods
    public static LogEntryBuilder warn() {
        return createLogEntryBuilder(LoggingLevel.WARN);
    }

    public static LogEntryBuilder warn(String message) {
        return warn().setMessage(message);
    }

    public static LogEntryBuilder warn(LogMessage logMessage) {
        return warn().setMessage(logMessage);
    }

    public static LogEntryBuilder warn(String message, List<String> topics) {
        return warn().setMessage(message).setTopics(topics);
    }

    public static LogEntryBuilder warn(LogMessage logMessage, List<String> topics) {
        return warn().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryBuilder warn(String message, SObject record) {
        return warn().setMessage(message).setRecordId(record);
    }

    public static LogEntryBuilder warn(LogMessage logMessage, SObject record) {
        return warn().setMessage(logMessage).setRecordId(record);
    }

    public static LogEntryBuilder warn(String message, SObject record, List<String> topics) {
        return warn().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder warn(LogMessage logMessage, SObject record, List<String> topics) {
        return warn().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder warn(String message, Id recordId) {
        return warn().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryBuilder warn(LogMessage logMessage, Id recordId) {
        return warn().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryBuilder warn(String message, Id recordId, List<String> topics) {
        return warn().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    public static LogEntryBuilder warn(LogMessage logMessage, Id recordId, List<String> topics) {
        return warn().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    // INFO logging level methods
    public static LogEntryBuilder info() {
        return createLogEntryBuilder(LoggingLevel.INFO);
    }

    public static LogEntryBuilder info(String message) {
        return info().setMessage(message);
    }

    public static LogEntryBuilder info(LogMessage logMessage) {
        return info().setMessage(logMessage);
    }

    public static LogEntryBuilder info(String message, List<String> topics) {
        return info().setMessage(message).setTopics(topics);
    }

    public static LogEntryBuilder info(LogMessage logMessage, List<String> topics) {
        return info().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryBuilder info(String message, SObject record) {
        return info().setMessage(message).setRecordId(record);
    }

    public static LogEntryBuilder info(LogMessage logMessage, SObject record) {
        return info().setMessage(logMessage).setRecordId(record);
    }

    public static LogEntryBuilder info(String message, SObject record, List<String> topics) {
        return info().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder info(LogMessage logMessage, SObject record, List<String> topics) {
        return info().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder info(String message, Id recordId) {
        return info().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryBuilder info(LogMessage logMessage, Id recordId) {
        return info().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryBuilder info(String message, Id recordId, List<String> topics) {
        return info().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    public static LogEntryBuilder info(LogMessage logMessage, Id recordId, List<String> topics) {
        return info().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }


    // DEBUG log level methods
    public static LogEntryBuilder debug() {
        return createLogEntryBuilder(LoggingLevel.DEBUG);
    }

    public static LogEntryBuilder debug(String message) {
        return debug().setMessage(message);
    }

    public static LogEntryBuilder debug(LogMessage logMessage) {
        return debug().setMessage(logMessage);
    }


    public static LogEntryBuilder debug(String message, List<String> topics) {
        return debug().setMessage(message).setTopics(topics);
    }

    public static LogEntryBuilder debug(LogMessage logMessage, List<String> topics) {
        return debug().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryBuilder debug(String message, SObject record) {
        return debug().setMessage(message).setRecordId(record);
    }

    public static LogEntryBuilder debug(LogMessage logMessage, SObject record) {
        return debug().setMessage(logMessage).setRecordId(record);
    }

    public static LogEntryBuilder debug(String message, SObject record, List<String> topics) {
        return debug().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder debug(LogMessage logMessage, SObject record, List<String> topics) {
        return debug().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder debug(String message, Id recordId) {
        return debug().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryBuilder debug(LogMessage logMessage, Id recordId) {
        return debug().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryBuilder debug(String message, Id recordId, List<String> topics) {
        return debug().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    public static LogEntryBuilder debug(LogMessage logMessage, Id recordId, List<String> topics) {
        return debug().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    // FINE log level methods
    public static LogEntryBuilder fine() {
        return createLogEntryBuilder(LoggingLevel.FINE);
    }

    public static LogEntryBuilder fine(String message) {
        return fine().setMessage(message);
    }

    public static LogEntryBuilder fine(LogMessage logMessage) {
        return fine().setMessage(logMessage);
    }

    public static LogEntryBuilder fine(String message, List<String> topics) {
        return fine().setMessage(message).setTopics(topics);
    }

    public static LogEntryBuilder fine(LogMessage logMessage, List<String> topics) {
        return fine().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryBuilder fine(String message, SObject record) {
        return fine().setMessage(message).setRecordId(record);
    }

    public static LogEntryBuilder fine(LogMessage logMessage, SObject record) {
        return fine().setMessage(logMessage).setRecordId(record);
    }

    public static LogEntryBuilder fine(String message, SObject record, List<String> topics) {
        return fine().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder fine(LogMessage logMessage, SObject record, List<String> topics) {
        return fine().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder fine(String message, Id recordId) {
        return fine().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryBuilder fine(LogMessage logMessage, Id recordId) {
        return fine().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryBuilder fine(String message, Id recordId, List<String> topics) {
        return fine().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    public static LogEntryBuilder fine(LogMessage logMessage, Id recordId, List<String> topics) {
        return fine().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    // FINER log level methods
    public static LogEntryBuilder finer() {
        return createLogEntryBuilder(LoggingLevel.FINER);
    }

    public static LogEntryBuilder finer(String message) {
        return finer().setMessage(message);
    }

    public static LogEntryBuilder finer(LogMessage logMessage) {
        return finer().setMessage(logMessage);
    }

    public static LogEntryBuilder finer(String message, List<String> topics) {
        return finer().setMessage(message).setTopics(topics);
    }

    public static LogEntryBuilder finer(LogMessage logMessage, List<String> topics) {
        return finer().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryBuilder finer(String message, SObject record) {
        return finer().setMessage(message).setRecordId(record);
    }

    public static LogEntryBuilder finer(LogMessage logMessage, SObject record) {
        return finer().setMessage(logMessage).setRecordId(record);
    }

    public static LogEntryBuilder finer(String message, SObject record, List<String> topics) {
        return finer().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder finer(LogMessage logMessage, SObject record, List<String> topics) {
        return finer().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder finer(String message, Id recordId) {
        return finer().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryBuilder finer(LogMessage logMessage, Id recordId) {
        return finer().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryBuilder finer(String message, Id recordId, List<String> topics) {
        return finer().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    public static LogEntryBuilder finer(LogMessage logMessage, Id recordId, List<String> topics) {
        return finer().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    // FINEST log level methods
    public static LogEntryBuilder finest() {
        return createLogEntryBuilder(LoggingLevel.FINEST);
    }

    public static LogEntryBuilder finest(String message) {
        return finest().setMessage(message);
    }

    public static LogEntryBuilder finest(LogMessage logMessage) {
        return finest().setMessage(logMessage);
    }

    public static LogEntryBuilder finest(String message, List<String> topics) {
        return finest().setMessage(message).setTopics(topics);
    }

    public static LogEntryBuilder finest(LogMessage logMessage, List<String> topics) {
        return finest().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryBuilder finest(String message, SObject record) {
        return finest().setMessage(message).setRecordId(record);
    }

    public static LogEntryBuilder finest(LogMessage logMessage, SObject record) {
        return finest().setMessage(logMessage).setRecordId(record);
    }

    public static LogEntryBuilder finest(String message, SObject record, List<String> topics) {
        return finest().setMessage(message).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder finest(LogMessage logMessage, SObject record, List<String> topics) {
        return finest().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    public static LogEntryBuilder finest(String message, Id recordId) {
        return finest().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryBuilder finest(LogMessage logMessage, Id recordId) {
        return finest().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryBuilder finest(String message, Id recordId, List<String> topics) {
        return finest().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    public static LogEntryBuilder finest(LogMessage logMessage, Id recordId, List<String> topics) {
        return finest().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    public static void setSaveMethod(SaveMethod saveMethod) {
        transactionSaveMethod = saveMethod;
    }

    @InvocableMethod(label='Save Log' description='Saves any log entries that have been generated')
    public static void saveLog() {
        saveLog(transactionSaveMethod);
    }

    public static void saveLog(SaveMethod transactionSaveMethod) {
        if(LOG_ENTRIES.isEmpty()) return;

        Boolean systemMessagesEnabled = LoggerSettings__c.getInstance().EnableSystemMessages__c;

        if(suspendSaving) {
            if(systemMessagesEnabled) {
                String suspendSavingLogMessage = 'Logging suspended, ignoring call to saveLog()';
                finest(suspendSavingLogMessage);
            }

            return;
        }

        if(systemMessagesEnabled) {
            String savingLogMessage = 'Saving ' + LOG_ENTRIES.size() + ' log entries via ';
            switch on transactionSaveMethod {
                when DML           { savingLogMessage += 'Apex DML'; }
                when QUEUEABLE_JOB { savingLogMessage += 'Apex queueable job'; }
                when REST_API      { savingLogMessage += 'Apex REST callout'; }
            }
            finest(savingLogMessage);
        }

        // TODO cleanup
        List<LogEntryBuilder> logEntriesToSave = new List<LogEntryBuilder>();
        for(LogEntryBuilder logEntryBuilder : LOG_ENTRIES) {
            if(!logEntryBuilder.shouldSave()) continue;

            logEntriesToSave.add(logEntryBuilder);
        }
        flushBuffer();
        LOG_ENTRIES.addAll(logEntriesToSave);

        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        Integer indexOfLastRecord = LOG_ENTRIES.size() - 1;
        for(Integer i = 0; i < LOG_ENTRIES.size(); i++) {
            LogEntryBuilder logEntryBuilder = LOG_ENTRIES.get(i);

            if(i == indexOfLastRecord) logEntryBuilder.setUserSessionDetails();

            LogEntryEvent__e logEntryEvent = logEntryBuilder.getLogEntryEvent();
            logEntryEvents.add(logEntryEvent);
        }

        switch on transactionSaveMethod {
            when DML           {
                List<Database.SaveResult> results = EventBus.publish(logEntryEvents);
                System.debug('saveResults =' + results);
            }
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
                finest(message);
                return LoggingLevel.DEBUG;
            }
        }
    }

    public static LogEntryBuilder createLogEntryBuilder(LoggingLevel loggingLevel) {
        LogEntryBuilder logEntryBuilder = new LogEntryBuilder(LoggingLevel);
        // if(isEnabled(loggingLevel)) {
            LOG_ENTRIES.add(logEntryBuilder);
        // }

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