/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
global with sharing class Logger {
    private static final List<LogEntryEventBuilder> LOG_ENTRIES = new List<LogEntryEventBuilder>();
    private static final String TRANSACTION_ID = System.Request.getCurrent().getRequestId();
    private static final Quiddity TRANSACTION_QUIDDITY = System.Request.getCurrent().getQuiddity();
    private static final LoggingLevel USER_LOGGING_LEVEL = getLoggingLevel(LoggerSettings__c.getInstance().LoggingLevel__c);

    private static String parentLogTransactionId;
    private static Boolean suspendSaving = false;
    private static SaveMethod transactionSaveMethod = SaveMethod.EVENT_BUS;

    static {
        // If settings have not been configured, then insert the org defaults
        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        if (orgDefaults.Id == null) {
            insert orgDefaults;
        }
    }

    global enum SaveMethod {
        EVENT_BUS,
        QUEUEABLE,
        REST
    }

    // Settings management methods

    /**
     * Returns the unique ID for a particular transaction, stored in Log__c.TransactionId__c
     * @return String - The value of System.Request.getCurrent().getRequestId()
     */
    global static String getTransactionId() {
        return TRANSACTION_ID;
    }

    /**
     * Returns the Quiddity context of the current transaction.
     * @return Quiddity - The value of System.Request.getCurrent().getQuiddity()
     */
    global static Quiddity getCurrentQuiddity() {
        return TRANSACTION_QUIDDITY;
    }

    /**
     * Relates the current transaction's log to a parent log via the field Log__c.ParentLog__c
     * This is useful for relating multiple asynchronous operations together, such as batch & queueable jobs.
     * @param  parentLogTransactionId - The transaction ID of the original parent transaction
     */
    global static void setParentLogTransactionId(String parentLogTransactionId) {
        parentLogTransactionId = parentLogTransactionId;
    }

    /**
     * Returns the transaction ID value that will be used to relate the current transaction's log to a parent log
     * @return String - The parent log's transaction ID. This must be explicitly set by calling setParentLogTransactionId(String)
     */
    global static String getParentLogTransactionId() {
        return parentLogTransactionId;
    }

    /**
     * Indicates if logging has been enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isEnabled() {
        return LoggerSettings__c.getInstance().IsEnabled__c;
    }

    /**
     * Indicates if logging for the specified logging level is enabled for the current user, based on the custom setting LoggerSettings__c
     * @param  loggingLevel - The logging level to check
     * @return Boolean
     */
    global static Boolean isEnabled(LoggingLevel loggingLevel) {
        return isEnabled() && meetsUserLoggingLevel(loggingLevel);
    }

    /**
     * Indicates if logging level 'ERROR' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isErrorEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.ERROR);
    }

    /**
     * Indicates if logging level 'WARN' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isWarnEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.WARN);
    }

    /**
     * Indicates if logging level 'INFO' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isInfoEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.INFO);
    }

    /**
     * Indicates if logging level 'DEBUG' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isDebugEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.DEBUG);
    }

    /**
     * Indicates if logging level 'FINE' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isFineEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINE);
    }

    /**
     * Indicates if logging level 'FINER' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isFinerEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINER);
    }

    /**
     * Indicates if logging level 'FINEST' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isFinestEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINEST);
    }

    /**
     * Indicates if logging level '(' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean meetsUserLoggingLevel(LoggingLevel logEntryLoggingLevel) {
        return USER_LOGGING_LEVEL.ordinal() <= logEntryLoggingLevel.ordinal();
    }

    /**
     * Returns the logging level for the current user, based on the custom setting LoggerSettings__c
     * @return LoggingLevel - The matching instance of LoggingLevel
     */
    global static LoggingLevel getUserLoggingLevel() {
        return USER_LOGGING_LEVEL;
    }

    // Transaction control methods

    /**
     * Indicates if saving has been temporarily suspended for the current transaction
     * @return Boolean
     */
    global static Boolean isSavingSuspended() {
        return suspendSaving;
    }

    /**
     * Pauses saving for the current transaction.
     * Any calls to saveLog() are ignored until saving is resumed.
     */
    global static void suspendSaving() {
        suspendSaving = true;
    }

    /**
     * Resumes saving for the current transaction, used to reverse suspendSaving().
     * Any calls to saveLog() are ignored until saving is resumed.
     */
    global static void resumeSaving() {
        suspendSaving = false;
    }

    /**
     * Returns the number of entries that have been generated but not yet saved
     * @return Integer
     */
    global static Integer getBufferSize() {
        return LOG_ENTRIES.size();
    }

    /**
     * Discards any entries that have been generated but not yet saved
     */
    global static void flushBuffer() {
        LOG_ENTRIES.clear();
    }

    // ERROR logging level methods
    global static LogEntryEventBuilder error() {
        return newEntry(LoggingLevel.ERROR);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Exception apexException, List<String> topics) {
        return error().setMessage(logMessage).setTopics(topics).setExceptionDetails(apexException);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Exception apexException) {
        return error().setMessage(logMessage).setExceptionDetails(apexException);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId, Exception apexException, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(recordId).setTopics(topics).setExceptionDetails(apexException);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId, Exception apexException) {
        return error().setMessage(logMessage).setRecordId(recordId).setExceptionDetails(apexException);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId) {
        return error().setMessage(logMessage).setRecordId(recordId);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, List<String> topics) {
        return error().setMessage(logMessage).setTopics(topics);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, SObject record, Exception apexException, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(record).setTopics(topics).setExceptionDetails(apexException);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, SObject record, Exception apexException) {
        return error().setMessage(logMessage).setRecordId(record).setExceptionDetails(apexException);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, SObject record, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, SObject record) {
        return error().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage) {
        return error().setMessage(logMessage);
    }

    global static LogEntryEventBuilder error(String message, Exception apexException, List<String> topics) {
        return error().setMessage(message).setTopics(topics).setExceptionDetails(apexException);
    }

    global static LogEntryEventBuilder error(String message, Exception apexException) {
        return error().setMessage(message).setExceptionDetails(apexException);
    }

    global static LogEntryEventBuilder error(String message, Id recordId, Exception apexException, List<String> topics) {
        return error().setMessage(message).setRecordId(recordId).setTopics(topics).setExceptionDetails(apexException);
    }

    global static LogEntryEventBuilder error(String message, Id recordId, Exception apexException) {
        return error().setMessage(message).setRecordId(recordId).setExceptionDetails(apexException);
    }

    global static LogEntryEventBuilder error(String message, Id recordId, List<String> topics) {
        return error().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder error(String message, Id recordId) {
        return error().setMessage(message).setRecordId(recordId);
    }

    global static LogEntryEventBuilder error(String message, List<String> topics) {
        return error().setMessage(message).setTopics(topics);
    }

    global static LogEntryEventBuilder error(String message, SObject record, Exception apexException, List<String> topics) {
        return error().setMessage(message).setRecordId(record).setTopics(topics).setExceptionDetails(apexException);
    }

    global static LogEntryEventBuilder error(String message, SObject record, Exception apexException) {
        return error().setMessage(message).setRecordId(record).setExceptionDetails(apexException);
    }

    global static LogEntryEventBuilder error(String message, SObject record, List<String> topics) {
        return error().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder error(String message, SObject record) {
        return error().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder error(String message) {
        return error().setMessage(message);
    }

    // WARN logging level methods
    global static LogEntryEventBuilder warn() {
        return newEntry(LoggingLevel.WARN);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId, List<String> topics) {
        return warn().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId) {
        return warn().setMessage(logMessage).setRecordId(recordId);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, List<String> topics) {
        return warn().setMessage(logMessage).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, SObject record, List<String> topics) {
        return warn().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, SObject record) {
        return warn().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage) {
        return warn().setMessage(logMessage);
    }

    global static LogEntryEventBuilder warn(String message, Id recordId, List<String> topics) {
        return warn().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(String message, Id recordId) {
        return warn().setMessage(message).setRecordId(recordId);
    }

    global static LogEntryEventBuilder warn(String message, List<String> topics) {
        return warn().setMessage(message).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(String message, SObject record, List<String> topics) {
        return warn().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(String message, SObject record) {
        return warn().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder warn(String message) {
        return warn().setMessage(message);
    }

    // INFO logging level methods
    global static LogEntryEventBuilder info() {
        return newEntry(LoggingLevel.INFO);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, Id recordId, List<String> topics) {
        return info().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, Id recordId) {
        return info().setMessage(logMessage).setRecordId(recordId);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, List<String> topics) {
        return info().setMessage(logMessage).setTopics(topics);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, SObject record, List<String> topics) {
        return info().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, SObject record) {
        return info().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage) {
        return info().setMessage(logMessage);
    }

    global static LogEntryEventBuilder info(String message, Id recordId, List<String> topics) {
        return info().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder info(String message, Id recordId) {
        return info().setMessage(message).setRecordId(recordId);
    }

    global static LogEntryEventBuilder info(String message, List<String> topics) {
        return info().setMessage(message).setTopics(topics);
    }

    global static LogEntryEventBuilder info(String message, SObject record, List<String> topics) {
        return info().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder info(String message, SObject record) {
        return info().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder info(String message) {
        return info().setMessage(message);
    }

    // DEBUG log level methods
    global static LogEntryEventBuilder debug() {
        return newEntry(LoggingLevel.DEBUG);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, Id recordId, List<String> topics) {
        return debug().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, Id recordId) {
        return debug().setMessage(logMessage).setRecordId(recordId);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, List<String> topics) {
        return debug().setMessage(logMessage).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, SObject record, List<String> topics) {
        return debug().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, SObject record) {
        return debug().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage) {
        return debug().setMessage(logMessage);
    }

    global static LogEntryEventBuilder debug(String message, Id recordId, List<String> topics) {
        return debug().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(String message, Id recordId) {
        return debug().setMessage(message).setRecordId(recordId);
    }

    global static LogEntryEventBuilder debug(String message, List<String> topics) {
        return debug().setMessage(message).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(String message, SObject record, List<String> topics) {
        return debug().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(String message, SObject record) {
        return debug().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder debug(String message) {
        return debug().setMessage(message);
    }

    // FINE log level methods
    global static LogEntryEventBuilder fine() {
        return newEntry(LoggingLevel.FINE);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, Id recordId, List<String> topics) {
        return fine().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, Id recordId) {
        return fine().setMessage(logMessage).setRecordId(recordId);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, List<String> topics) {
        return fine().setMessage(logMessage).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, SObject record, List<String> topics) {
        return fine().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, SObject record) {
        return fine().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage) {
        return fine().setMessage(logMessage);
    }

    global static LogEntryEventBuilder fine(String message, Id recordId, List<String> topics) {
        return fine().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(String message, Id recordId) {
        return fine().setMessage(message).setRecordId(recordId);
    }

    global static LogEntryEventBuilder fine(String message, List<String> topics) {
        return fine().setMessage(message).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(String message, SObject record, List<String> topics) {
        return fine().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(String message, SObject record) {
        return fine().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder fine(String message) {
        return fine().setMessage(message);
    }

    // FINER log level methods
    global static LogEntryEventBuilder finer() {
        return newEntry(LoggingLevel.FINER);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, Id recordId, List<String> topics) {
        return finer().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, Id recordId) {
        return finer().setMessage(logMessage).setRecordId(recordId);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, List<String> topics) {
        return finer().setMessage(logMessage).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, SObject record, List<String> topics) {
        return finer().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, SObject record) {
        return finer().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage) {
        return finer().setMessage(logMessage);
    }

    global static LogEntryEventBuilder finer(String message, Id recordId, List<String> topics) {
        return finer().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(String message, Id recordId) {
        return finer().setMessage(message).setRecordId(recordId);
    }

    global static LogEntryEventBuilder finer(String message, List<String> topics) {
        return finer().setMessage(message).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(String message, SObject record, List<String> topics) {
        return finer().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(String message, SObject record) {
        return finer().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder finer(String message) {
        return finer().setMessage(message);
    }

    // FINEST log level methods
    global static LogEntryEventBuilder finest() {
        return newEntry(LoggingLevel.FINEST);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, Id recordId, List<String> topics) {
        return finest().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, Id recordId) {
        return finest().setMessage(logMessage).setRecordId(recordId);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, List<String> topics) {
        return finest().setMessage(logMessage).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, SObject record, List<String> topics) {
        return finest().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, SObject record) {
        return finest().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage) {
        return finest().setMessage(logMessage);
    }

    global static LogEntryEventBuilder finest(String message, Id recordId, List<String> topics) {
        return finest().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(String message, Id recordId) {
        return finest().setMessage(message).setRecordId(recordId);
    }

    global static LogEntryEventBuilder finest(String message, List<String> topics) {
        return finest().setMessage(message).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(String message, SObject record, List<String> topics) {
        return finest().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(String message, SObject record) {
        return finest().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder finest(String message) {
        return finest().setMessage(message);
    }

    /**
     * Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
     *
     * @param  LoggingLevel loggingLevel - the logging level of the new entry
     * @return LogEntryEventBuilder - returns the instance of LogEntryEventBuilder for the new entry
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel) {
        return newEntry(loggingLevel, isEnabled(loggingLevel));
    }

    /**
     * Adds a new instance of LogEntryEventBuilder to Logger's buffer
     *
     * @param  LoggingLevel loggingLevel - the logging level of the new entry
     * @param  Boolean alwaysSave - controls if the entry should be saved, even if it does not meet the user's logging level
     * @return LogEntryEventBuilder - returns the instance of LogEntryEventBuilder for the new entry
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, Boolean alwaysSave) {
        LogEntryEventBuilder logEntryBuilder = new LogEntryEventBuilder(LoggingLevel, alwaysSave);
        LOG_ENTRIES.add(logEntryBuilder);

        return logEntryBuilder;
    }

    /**
     * Sets the default save method used when calling saveLog() - any subsequent calls to saveLog() will use the specified save method
     * @param  saveMethod - The enum value of Logger.SaveMethod to use for any other calls to saveLog() in the current transaction
     */
    global static void setSaveMethod(SaveMethod saveMethod) {
        transactionSaveMethod = saveMethod;
    }

    /**
     * Saves any entries in Logger's buffer. By default, entries are saved via Apex's EventBus and can be overridden with setSaveMethod(SaveMethod saveMethod)
     */
    @InvocableMethod(category='Logging' label='Save Log' description='Saves any log entries that have been generated')
    global static void saveLog() {
        saveLog(transactionSaveMethod);
    }

    /**
     * Saves any entries in Logger's buffer, using the specified save method for only this call.
     * All subsequent calls to saveLog() will use the transaction save method.
     * @param  saveMethod The enum value of Logger.SaveMethod to use for this specific save action.
     */
    global static void saveLog(SaveMethod saveMethod) {
        // Verify that the user has create access
        if (!Schema.LogEntryEvent__e.SObjectType.getDescribe().isCreateable()) {
            return;
        }

        if (LOG_ENTRIES.isEmpty()) {
            return;
        }

        Boolean systemMessagesEnabled = LoggerSettings__c.getInstance().EnableSystemMessages__c;

        if (suspendSaving) {
            if (systemMessagesEnabled) {
                String suspendSavingLogMessage = 'Logging suspended, ignoring call to saveLog()';
                finest(suspendSavingLogMessage);
            }

            return;
        }

        if (systemMessagesEnabled) {
            String savingLogMessage = 'Saving ' + LOG_ENTRIES.size() + ' log entries via ';
            switch on getCurrentQuiddity() {
                when ANONYMOUS {
                    savingLogMessage += 'Anonymous Apex';
                }
                when Aura, VF {
                    savingLogMessage += 'Aura/Lightning/VF component';
                }
                when BATCH_ACS, BATCH_APEX, BATCH_CHUNK_PARALLEL, BATCH_CHUNK_SERIAL {
                    savingLogMessage += 'Apex batch job';
                }
                when INVOCABLE_ACTION {
                    savingLogMessage += 'Flow invocation';
                }
                when QUEUEABLE {
                    savingLogMessage += 'Apex queueable job';
                }
                when REST {
                    savingLogMessage += 'Apex REST callout';
                }
                when SCHEDULED {
                    savingLogMessage += 'Scheduled job';
                }
                when SYNCHRONOUS {
                    savingLogMessage += 'Apex synchronous DML';
                }
                when else {
                    savingLogMessage += getCurrentQuiddity().name();
                }
            }
            savingLogMessage += ', save method is ' + saveMethod.name();
            finest(savingLogMessage);
        }

        // TODO cleanup
        List<LogEntryEventBuilder> logEntriesToSave = new List<LogEntryEventBuilder>();
        for (LogEntryEventBuilder logEntryBuilder : LOG_ENTRIES) {
            if (!logEntryBuilder.shouldSave()) {
                continue;
            }

            logEntriesToSave.add(logEntryBuilder);
        }
        flushBuffer();
        LOG_ENTRIES.addAll(logEntriesToSave);

        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        for (Integer i = 0; i < LOG_ENTRIES.size(); i++) {
            LogEntryEventBuilder logEntryBuilder = LOG_ENTRIES.get(i);

            LogEntryEvent__e logEntryEvent = logEntryBuilder.getLogEntryEvent();
            logEntryEvent.ParentLogTransactionId__c = getParentLogTransactionId();
            logEntryEvent.SystemMode__c = getCurrentQuiddity().name();
            logEntryEvent.TransactionId__c = getTransactionId();
            logEntryEvents.add(logEntryEvent);
        }

        switch on saveMethod {
            when EVENT_BUS {
                List<Database.SaveResult> results = EventBus.publish(logEntryEvents);
                System.debug('saveResults =' + results);
            }
            when QUEUEABLE {
                System.enqueueJob(new QueueableSaver(logEntryEvents));
            }
            when REST {
                new RestApiSaver().insertRecords(logEntryEvents);
            }
        }

        // TODO add error handling for when event bus fails to publish
        flushBuffer();
    }

    // Utility methods

    /**
     * Converts a String to an instance of LoggingLevel
     * @param  String loggingLevelName - The string name of an Apex logging level
     * @return LoggingLevel - The matching instance of LoggingLevel (or a default value if a match is not found)
     */
    global static LoggingLevel getLoggingLevel(String loggingLevelName) {
        if (loggingLevelName != null) {
            loggingLevelName = loggingLevelName.toUpperCase();
        }

        switch on loggingLevelName {
            when 'NONE' {
                return LoggingLevel.NONE;
            }
            when 'ERROR' {
                return LoggingLevel.ERROR;
            }
            when 'WARN' {
                return LoggingLevel.WARN;
            }
            when 'INFO' {
                return LoggingLevel.INFO;
            }
            when 'DEBUG' {
                return LoggingLevel.DEBUG;
            }
            when 'FINE' {
                return LoggingLevel.FINE;
            }
            when 'FINER' {
                return LoggingLevel.FINER;
            }
            when 'FINEST' {
                return LoggingLevel.FINEST;
            }
            when else {
                LoggingLevel fallbackLevel = LoggingLevel.DEBUG;
                String message = 'Unknown logging level ' + loggingLevelName + 'specified, using ' + fallbackLevel.Name();
                finest(message);
                return LoggingLevel.DEBUG;
            }
        }
    }

    // For orgs that already have the aura cmp + quickAction deployed, this method is still needed (otherwise, deployment errors will occur)
    // TODO consider removing this method after converting aura cmp to lwc (and presumably create a dedicated Apex ctrl w/ this method)
    // But the safe choice is to just keep it now/forever
    /**
     * Returns a Log__c record from the database
     * @param  logId - The Salesforce ID or TransactionId__c of the Log__c
     * @return Log__c - The matching record, with all fields that the current user can access
     */
    @AuraEnabled(cacheable=true)
    public static Log__c getLog(String logId) {
        List<String> logFieldNames = new List<String>(Schema.Log__c.SObjectType.getDescribe().fields.getMap().keySet());
        List<String> logEntryFieldNames = new List<String>(Schema.LogEntry__c.SObjectType.getDescribe().fields.getMap().keySet());

        List<String> textReplacements = new List<String>{ String.join(logFieldNames, ','), String.join(logEntryFieldNames, ',') };
        String query = String.format(
            'SELECT {0}, (SELECT {1} FROM LogEntries__r) FROM Log__c WHERE Id = :logId OR TransactionId__c = :logId',
            textReplacements
        );

        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, Database.query(query));

        if (securityDecision.getRecords().isEmpty()) {
            return null;
        } else {
            return (Log__c) securityDecision.getRecords().get(0);
        }
    }

    // Inner class for saving log entries via a queuable job
    global class QueueableSaver implements Queueable {
        private Id jobId;

        private List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();

        private QueueableSaver(List<LogEntryEvent__e> logEntryEvents) {
            this.logEntryEvents = logEntryEvents;
        }

        global void execute(System.QueueableContext queueableContext) {
            EventBus.publish(this.logEntryEvents);
        }
    }

    // Inner class for saving log entries via the REST API (using the current user's session ID)
    private class RestApiSaver {
        private final String BASE_URL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/data/v50.0';
        private final String COMPOSITE_ENDPOINT = '/composite/sobjects';

        public void insertRecords(List<SObject> records) {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(BASE_URL + COMPOSITE_ENDPOINT);
            request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            request.setHeader('Content-Type', 'application/json; charset=utf-8');
            request.setMethod('POST');

            Boolean allOrNone = true;
            RestSaveRequest saveRequest = new RestSaveRequest(records, allOrNone);
            request.setBody(Json.serialize(saveRequest));

            HttpResponse response = new Http().send(request);
            this.validateResponse(response);
        }

        private void validateResponse(Httpresponse response) {
            Integer statusCode = response.getStatusCode();
            if (statusCode >= 400) {
                String errorMessage = 'Saving via REST API failed. Received request status code ' + statusCode + ', status message: ' + response.getStatus();
                throw new RestResponseException(errorMessage);
            }
        }
    }

    @testVisible
    private class RestResponseException extends Exception {
    }

    // Inner class that matches the format expected by the REST API for saving SObjects
    private class RestSaveRequest {
        public Boolean allOrNone { get; set; }
        public List<SObject> records { get; set; }

        private RestSaveRequest(List<SObject> records, Boolean allOrNone) {
            this.allOrNone = allOrNone;
            this.records = records;
        }
    }
}
