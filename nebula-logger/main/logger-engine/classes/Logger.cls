//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group logger-engine
 * @description The core class for logging
 * @see LogEntryEventBuilder
 * @see LogMessage
 */
global with sharing class Logger {
    private static final LoggingLevel DEFAULT_LOGGING_LEVEL = LoggingLevel.DEBUG;
    private static final List<LogEntryEventBuilder> LOG_ENTRIES_BUFFER = new List<LogEntryEventBuilder>();
    private static final Boolean SYSTEM_MESSAGES_ENABLED = LoggerSettings__c.getInstance().EnableSystemMessages__c;
    private static final String TRANSACTION_ID = System.Request.getCurrent().getRequestId();
    private static final Quiddity TRANSACTION_QUIDDITY = System.Request.getCurrent().getQuiddity();
    private static final Boolean USER_CAN_CREATE_LOG_ENTRY_EVENTS = SObjectType.LogEntryEvent__e.isCreateable();
    private static final Boolean USER_HAS_LOGGING_ENABLED = LoggerSettings__c.getInstance().IsEnabled__c;
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

    /**
     * Enum used to control how LogEntryEvent__e records are inserted
     */
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
     * @param  parentTransactionId - The transaction ID of the original parent transaction
     */
    global static void setParentLogTransactionId(String parentTransactionId) {
        parentLogTransactionId = parentTransactionId;
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
        return USER_HAS_LOGGING_ENABLED;
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
     * Indicates if the specified logging level is enabled for the current user, based on the custom setting LoggerSettings__c
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
        return LOG_ENTRIES_BUFFER.size();
    }

    /**
     * Discards any entries that have been generated but not yet saved
     */
    global static void flushBuffer() {
        LOG_ENTRIES_BUFFER.clear();
    }

    // ERROR logging level methods
    public static LogEntryEventBuilder error(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return error().setMessage(logMessage).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return error().setMessage(logMessage).setDmlResult(deleteResult);
    }

    public static LogEntryEventBuilder error(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return error().setMessage(logMessage).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Database.MergeResult mergeResult) {
        return error().setMessage(logMessage).setDmlResult(mergeResult);
    }

    public static LogEntryEventBuilder error(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return error().setMessage(logMessage).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Database.SaveResult saveResult) {
        return error().setMessage(logMessage).setDmlResult(saveResult);
    }

    public static LogEntryEventBuilder error(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return error().setMessage(logMessage).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return error().setMessage(logMessage).setDmlResult(undeleteResult);
    }

    public static LogEntryEventBuilder error(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return error().setMessage(logMessage).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return error().setMessage(logMessage).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder error(LogMessage logMessage, Exception apexException, List<String> topics) {
        return error().setMessage(logMessage).setExceptionDetails(apexException).setTopics(topics);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Exception apexException) {
        return error().setMessage(logMessage).setExceptionDetails(apexException);
    }

    public static LogEntryEventBuilder error(LogMessage logMessage, Id recordId, Exception apexException, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(recordId).setExceptionDetails(apexException).setTopics(topics);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId, Exception apexException) {
        return error().setMessage(logMessage).setRecordId(recordId).setExceptionDetails(apexException);
    }

    public static LogEntryEventBuilder error(LogMessage logMessage, Id recordId, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId) {
        return error().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryEventBuilder error(LogMessage logMessage, List<String> topics) {
        return error().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryEventBuilder error(LogMessage logMessage, SObject record, Exception apexException, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(record).setExceptionDetails(apexException).setTopics(topics);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, SObject record, Exception apexException) {
        return error().setMessage(logMessage).setRecordId(record).setExceptionDetails(apexException);
    }

    public static LogEntryEventBuilder error(LogMessage logMessage, SObject record, List<String> topics) {
        return error().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage, SObject record) {
        return error().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder error(LogMessage logMessage) {
        return error().setMessage(logMessage);
    }

    public static LogEntryEventBuilder error(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return error().setMessage(message).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder error(String message, Database.DeleteResult deleteResult) {
        return error().setMessage(message).setDmlResult(deleteResult);
    }

    public static LogEntryEventBuilder error(String message, Database.MergeResult mergeResult, List<String> topics) {
        return error().setMessage(message).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder error(String message, Database.MergeResult mergeResult) {
        return error().setMessage(message).setDmlResult(mergeResult);
    }

    public static LogEntryEventBuilder error(String message, Database.SaveResult saveResult, List<String> topics) {
        return error().setMessage(message).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder error(String message, Database.SaveResult saveResult) {
        return error().setMessage(message).setDmlResult(saveResult);
    }

    public static LogEntryEventBuilder error(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return error().setMessage(message).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder error(String message, Database.UndeleteResult undeleteResult) {
        return error().setMessage(message).setDmlResult(undeleteResult);
    }

    public static LogEntryEventBuilder error(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return error().setMessage(message).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder error(String message, Database.UpsertResult upsertResult) {
        return error().setMessage(message).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder error(String message, Exception apexException, List<String> topics) {
        return error().setMessage(message).setExceptionDetails(apexException).setTopics(topics);
    }

    global static LogEntryEventBuilder error(String message, Exception apexException) {
        return error().setMessage(message).setExceptionDetails(apexException);
    }

    public static LogEntryEventBuilder error(String message, Id recordId, Exception apexException, List<String> topics) {
        return error().setMessage(message).setRecordId(recordId).setExceptionDetails(apexException).setTopics(topics);
    }

    global static LogEntryEventBuilder error(String message, Id recordId, Exception apexException) {
        return error().setMessage(message).setRecordId(recordId).setExceptionDetails(apexException);
    }

    public static LogEntryEventBuilder error(String message, Id recordId, List<String> topics) {
        return error().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder error(String message, Id recordId) {
        return error().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryEventBuilder error(String message, List<String> topics) {
        return error().setMessage(message).setTopics(topics);
    }

    public static LogEntryEventBuilder error(String message, SObject record, Exception apexException, List<String> topics) {
        return error().setMessage(message).setRecordId(record).setExceptionDetails(apexException).setTopics(topics);
    }

    global static LogEntryEventBuilder error(String message, SObject record, Exception apexException) {
        return error().setMessage(message).setRecordId(record).setExceptionDetails(apexException);
    }

    public static LogEntryEventBuilder error(String message, SObject record, List<String> topics) {
        return error().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder error(String message, SObject record) {
        return error().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder error(String message) {
        return error().setMessage(message);
    }

    // WARN logging level methods
    public static LogEntryEventBuilder warn(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return warn().setMessage(logMessage).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return warn().setMessage(logMessage).setDmlResult(deleteResult);
    }

    public static LogEntryEventBuilder warn(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return warn().setMessage(logMessage).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.MergeResult mergeResult) {
        return warn().setMessage(logMessage).setDmlResult(mergeResult);
    }

    public static LogEntryEventBuilder warn(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return warn().setMessage(logMessage).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.SaveResult saveResult) {
        return warn().setMessage(logMessage).setDmlResult(saveResult);
    }

    public static LogEntryEventBuilder warn(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return warn().setMessage(logMessage).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return warn().setMessage(logMessage).setDmlResult(undeleteResult);
    }

    public static LogEntryEventBuilder warn(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return warn().setMessage(logMessage).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return warn().setMessage(logMessage).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder warn(LogMessage logMessage, Exception apexException, List<String> topics) {
        return warn().setMessage(logMessage).setExceptionDetails(apexException).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, Exception apexException) {
        return warn().setMessage(logMessage).setExceptionDetails(apexException);
    }

    public static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId, Exception apexException, List<String> topics) {
        return warn().setMessage(logMessage).setRecordId(recordId).setExceptionDetails(apexException).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId, Exception apexException) {
        return warn().setMessage(logMessage).setRecordId(recordId).setExceptionDetails(apexException);
    }

    public static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId, List<String> topics) {
        return warn().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId) {
        return warn().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryEventBuilder warn(LogMessage logMessage, List<String> topics) {
        return warn().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryEventBuilder warn(LogMessage logMessage, SObject record, Exception apexException, List<String> topics) {
        return warn().setMessage(logMessage).setRecordId(record).setExceptionDetails(apexException).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, SObject record, Exception apexException) {
        return warn().setMessage(logMessage).setRecordId(record).setExceptionDetails(apexException);
    }

    public static LogEntryEventBuilder warn(LogMessage logMessage, SObject record, List<String> topics) {
        return warn().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage, SObject record) {
        return warn().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder warn(LogMessage logMessage) {
        return warn().setMessage(logMessage);
    }

    public static LogEntryEventBuilder warn(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return warn().setMessage(message).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(String message, Database.DeleteResult deleteResult) {
        return warn().setMessage(message).setDmlResult(deleteResult);
    }

    public static LogEntryEventBuilder warn(String message, Database.MergeResult mergeResult, List<String> topics) {
        return warn().setMessage(message).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(String message, Database.MergeResult mergeResult) {
        return warn().setMessage(message).setDmlResult(mergeResult);
    }

    public static LogEntryEventBuilder warn(String message, Database.SaveResult saveResult, List<String> topics) {
        return warn().setMessage(message).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(String message, Database.SaveResult saveResult) {
        return warn().setMessage(message).setDmlResult(saveResult);
    }

    public static LogEntryEventBuilder warn(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return warn().setMessage(message).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(String message, Database.UndeleteResult undeleteResult) {
        return warn().setMessage(message).setDmlResult(undeleteResult);
    }

    public static LogEntryEventBuilder warn(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return warn().setMessage(message).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(String message, Database.UpsertResult upsertResult) {
        return warn().setMessage(message).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder warn(String message, Exception apexException, List<String> topics) {
        return warn().setMessage(message).setExceptionDetails(apexException).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(String message, Exception apexException) {
        return warn().setMessage(message).setExceptionDetails(apexException);
    }

    public static LogEntryEventBuilder warn(String message, Id recordId, Exception apexException, List<String> topics) {
        return warn().setMessage(message).setRecordId(recordId).setExceptionDetails(apexException).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(String message, Id recordId, Exception apexException) {
        return warn().setMessage(message).setRecordId(recordId).setExceptionDetails(apexException);
    }

    public static LogEntryEventBuilder warn(String message, Id recordId, List<String> topics) {
        return warn().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(String message, Id recordId) {
        return warn().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryEventBuilder warn(String message, List<String> topics) {
        return warn().setMessage(message).setTopics(topics);
    }

    public static LogEntryEventBuilder warn(String message, SObject record, Exception apexException, List<String> topics) {
        return warn().setMessage(message).setRecordId(record).setExceptionDetails(apexException).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(String message, SObject record, Exception apexException) {
        return warn().setMessage(message).setRecordId(record).setExceptionDetails(apexException);
    }

    public static LogEntryEventBuilder warn(String message, SObject record, List<String> topics) {
        return warn().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder warn(String message, SObject record) {
        return warn().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder warn(String message) {
        return warn().setMessage(message);
    }

    // INFO logging level methods
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return info().setMessage(logMessage).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return info().setMessage(logMessage).setDmlResult(deleteResult);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return info().setMessage(logMessage).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, Database.MergeResult mergeResult) {
        return info().setMessage(logMessage).setDmlResult(mergeResult);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return info().setMessage(logMessage).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, Database.SaveResult saveResult) {
        return info().setMessage(logMessage).setDmlResult(saveResult);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return info().setMessage(logMessage).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return info().setMessage(logMessage).setDmlResult(undeleteResult);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return info().setMessage(logMessage).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return info().setMessage(logMessage).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder info(LogMessage logMessage, Id recordId, List<String> topics) {
        return info().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, Id recordId) {
        return info().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryEventBuilder info(LogMessage logMessage, List<String> topics) {
        return info().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryEventBuilder info(LogMessage logMessage, SObject record, List<String> topics) {
        return info().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage, SObject record) {
        return info().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder info(LogMessage logMessage) {
        return info().setMessage(logMessage);
    }

    public static LogEntryEventBuilder info(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return info().setMessage(message).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder info(String message, Database.DeleteResult deleteResult) {
        return info().setMessage(message).setDmlResult(deleteResult);
    }

    public static LogEntryEventBuilder info(String message, Database.MergeResult mergeResult, List<String> topics) {
        return info().setMessage(message).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder info(String message, Database.MergeResult mergeResult) {
        return info().setMessage(message).setDmlResult(mergeResult);
    }

    public static LogEntryEventBuilder info(String message, Database.SaveResult saveResult, List<String> topics) {
        return info().setMessage(message).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder info(String message, Database.SaveResult saveResult) {
        return info().setMessage(message).setDmlResult(saveResult);
    }

    public static LogEntryEventBuilder info(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return info().setMessage(message).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder info(String message, Database.UndeleteResult undeleteResult) {
        return info().setMessage(message).setDmlResult(undeleteResult);
    }

    public static LogEntryEventBuilder info(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return info().setMessage(message).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder info(String message, Database.UpsertResult upsertResult) {
        return info().setMessage(message).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder info(String message, Id recordId, List<String> topics) {
        return info().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder info(String message, Id recordId) {
        return info().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryEventBuilder info(String message, List<String> topics) {
        return info().setMessage(message).setTopics(topics);
    }

    public static LogEntryEventBuilder info(String message, SObject record, List<String> topics) {
        return info().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder info(String message, SObject record) {
        return info().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder info(String message) {
        return info().setMessage(message);
    }

    // DEBUG log level methods
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return debug().setMessage(logMessage).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return debug().setMessage(logMessage).setDmlResult(deleteResult);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return debug().setMessage(logMessage).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.MergeResult mergeResult) {
        return debug().setMessage(logMessage).setDmlResult(mergeResult);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return debug().setMessage(logMessage).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.SaveResult saveResult) {
        return debug().setMessage(logMessage).setDmlResult(saveResult);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return debug().setMessage(logMessage).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return debug().setMessage(logMessage).setDmlResult(undeleteResult);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return debug().setMessage(logMessage).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return debug().setMessage(logMessage).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder debug(LogMessage logMessage, Id recordId, List<String> topics) {
        return debug().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, Id recordId) {
        return debug().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryEventBuilder debug(LogMessage logMessage, List<String> topics) {
        return debug().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryEventBuilder debug(LogMessage logMessage, SObject record, List<String> topics) {
        return debug().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage, SObject record) {
        return debug().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder debug(LogMessage logMessage) {
        return debug().setMessage(logMessage);
    }

    public static LogEntryEventBuilder debug(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return debug().setMessage(message).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(String message, Database.DeleteResult deleteResult) {
        return debug().setMessage(message).setDmlResult(deleteResult);
    }

    public static LogEntryEventBuilder debug(String message, Database.MergeResult mergeResult, List<String> topics) {
        return debug().setMessage(message).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(String message, Database.MergeResult mergeResult) {
        return debug().setMessage(message).setDmlResult(mergeResult);
    }

    public static LogEntryEventBuilder debug(String message, Database.SaveResult saveResult, List<String> topics) {
        return debug().setMessage(message).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(String message, Database.SaveResult saveResult) {
        return debug().setMessage(message).setDmlResult(saveResult);
    }

    public static LogEntryEventBuilder debug(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return debug().setMessage(message).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(String message, Database.UndeleteResult undeleteResult) {
        return debug().setMessage(message).setDmlResult(undeleteResult);
    }

    public static LogEntryEventBuilder debug(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return debug().setMessage(message).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(String message, Database.UpsertResult upsertResult) {
        return debug().setMessage(message).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder debug(String message, Id recordId, List<String> topics) {
        return debug().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(String message, Id recordId) {
        return debug().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryEventBuilder debug(String message, List<String> topics) {
        return debug().setMessage(message).setTopics(topics);
    }

    public static LogEntryEventBuilder debug(String message, SObject record, List<String> topics) {
        return debug().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder debug(String message, SObject record) {
        return debug().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder debug(String message) {
        return debug().setMessage(message);
    }

    // FINE log level methods
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return fine().setMessage(logMessage).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return fine().setMessage(logMessage).setDmlResult(deleteResult);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return fine().setMessage(logMessage).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.MergeResult mergeResult) {
        return fine().setMessage(logMessage).setDmlResult(mergeResult);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return fine().setMessage(logMessage).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.SaveResult saveResult) {
        return fine().setMessage(logMessage).setDmlResult(saveResult);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return fine().setMessage(logMessage).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return fine().setMessage(logMessage).setDmlResult(undeleteResult);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return fine().setMessage(logMessage).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return fine().setMessage(logMessage).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder fine(LogMessage logMessage, Id recordId, List<String> topics) {
        return fine().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, Id recordId) {
        return fine().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryEventBuilder fine(LogMessage logMessage, List<String> topics) {
        return fine().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryEventBuilder fine(LogMessage logMessage, SObject record, List<String> topics) {
        return fine().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage, SObject record) {
        return fine().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder fine(LogMessage logMessage) {
        return fine().setMessage(logMessage);
    }

    public static LogEntryEventBuilder fine(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return fine().setMessage(message).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(String message, Database.DeleteResult deleteResult) {
        return fine().setMessage(message).setDmlResult(deleteResult);
    }

    public static LogEntryEventBuilder fine(String message, Database.MergeResult mergeResult, List<String> topics) {
        return fine().setMessage(message).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(String message, Database.MergeResult mergeResult) {
        return fine().setMessage(message).setDmlResult(mergeResult);
    }

    public static LogEntryEventBuilder fine(String message, Database.SaveResult saveResult, List<String> topics) {
        return fine().setMessage(message).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(String message, Database.SaveResult saveResult) {
        return fine().setMessage(message).setDmlResult(saveResult);
    }

    public static LogEntryEventBuilder fine(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return fine().setMessage(message).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(String message, Database.UndeleteResult undeleteResult) {
        return fine().setMessage(message).setDmlResult(undeleteResult);
    }

    public static LogEntryEventBuilder fine(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return fine().setMessage(message).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(String message, Database.UpsertResult upsertResult) {
        return fine().setMessage(message).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder fine(String message, Id recordId, List<String> topics) {
        return fine().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(String message, Id recordId) {
        return fine().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryEventBuilder fine(String message, List<String> topics) {
        return fine().setMessage(message).setTopics(topics);
    }

    public static LogEntryEventBuilder fine(String message, SObject record, List<String> topics) {
        return fine().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder fine(String message, SObject record) {
        return fine().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder fine(String message) {
        return fine().setMessage(message);
    }

    // FINER log level methods
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return finer().setMessage(logMessage).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return finer().setMessage(logMessage).setDmlResult(deleteResult);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return finer().setMessage(logMessage).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.MergeResult mergeResult) {
        return finer().setMessage(logMessage).setDmlResult(mergeResult);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return finer().setMessage(logMessage).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.SaveResult saveResult) {
        return finer().setMessage(logMessage).setDmlResult(saveResult);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return finer().setMessage(logMessage).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return finer().setMessage(logMessage).setDmlResult(undeleteResult);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return finer().setMessage(logMessage).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return finer().setMessage(logMessage).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder finer(LogMessage logMessage, Id recordId, List<String> topics) {
        return finer().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, Id recordId) {
        return finer().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryEventBuilder finer(LogMessage logMessage, List<String> topics) {
        return finer().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryEventBuilder finer(LogMessage logMessage, SObject record, List<String> topics) {
        return finer().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage, SObject record) {
        return finer().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder finer(LogMessage logMessage) {
        return finer().setMessage(logMessage);
    }

    public static LogEntryEventBuilder finer(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return finer().setMessage(message).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(String message, Database.DeleteResult deleteResult) {
        return finer().setMessage(message).setDmlResult(deleteResult);
    }

    public static LogEntryEventBuilder finer(String message, Database.MergeResult mergeResult, List<String> topics) {
        return finer().setMessage(message).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(String message, Database.MergeResult mergeResult) {
        return finer().setMessage(message).setDmlResult(mergeResult);
    }

    public static LogEntryEventBuilder finer(String message, Database.SaveResult saveResult, List<String> topics) {
        return finer().setMessage(message).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(String message, Database.SaveResult saveResult) {
        return finer().setMessage(message).setDmlResult(saveResult);
    }

    public static LogEntryEventBuilder finer(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return finer().setMessage(message).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(String message, Database.UndeleteResult undeleteResult) {
        return finer().setMessage(message).setDmlResult(undeleteResult);
    }

    public static LogEntryEventBuilder finer(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return finer().setMessage(message).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(String message, Database.UpsertResult upsertResult) {
        return finer().setMessage(message).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder finer(String message, Id recordId, List<String> topics) {
        return finer().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(String message, Id recordId) {
        return finer().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryEventBuilder finer(String message, List<String> topics) {
        return finer().setMessage(message).setTopics(topics);
    }

    public static LogEntryEventBuilder finer(String message, SObject record, List<String> topics) {
        return finer().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder finer(String message, SObject record) {
        return finer().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder finer(String message) {
        return finer().setMessage(message);
    }

    // FINEST log level methods
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.DeleteResult deleteResult, List<String> topics) {
        return finest().setMessage(logMessage).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return finest().setMessage(logMessage).setDmlResult(deleteResult);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.MergeResult mergeResult, List<String> topics) {
        return finest().setMessage(logMessage).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.MergeResult mergeResult) {
        return finest().setMessage(logMessage).setDmlResult(mergeResult);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.SaveResult saveResult, List<String> topics) {
        return finest().setMessage(logMessage).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.SaveResult saveResult) {
        return finest().setMessage(logMessage).setDmlResult(saveResult);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.UndeleteResult undeleteResult, List<String> topics) {
        return finest().setMessage(logMessage).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return finest().setMessage(logMessage).setDmlResult(undeleteResult);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.UpsertResult upsertResult, List<String> topics) {
        return finest().setMessage(logMessage).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return finest().setMessage(logMessage).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder finest(LogMessage logMessage, Id recordId, List<String> topics) {
        return finest().setMessage(logMessage).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, Id recordId) {
        return finest().setMessage(logMessage).setRecordId(recordId);
    }

    public static LogEntryEventBuilder finest(LogMessage logMessage, List<String> topics) {
        return finest().setMessage(logMessage).setTopics(topics);
    }

    public static LogEntryEventBuilder finest(LogMessage logMessage, SObject record, List<String> topics) {
        return finest().setMessage(logMessage).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage, SObject record) {
        return finest().setMessage(logMessage).setRecordId(record);
    }

    global static LogEntryEventBuilder finest(LogMessage logMessage) {
        return finest().setMessage(logMessage);
    }

    public static LogEntryEventBuilder finest(String message, Database.DeleteResult deleteResult, List<String> topics) {
        return finest().setMessage(message).setDmlResult(deleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(String message, Database.DeleteResult deleteResult) {
        return finest().setMessage(message).setDmlResult(deleteResult);
    }

    public static LogEntryEventBuilder finest(String message, Database.MergeResult mergeResult, List<String> topics) {
        return finest().setMessage(message).setDmlResult(mergeResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(String message, Database.MergeResult mergeResult) {
        return finest().setMessage(message).setDmlResult(mergeResult);
    }

    public static LogEntryEventBuilder finest(String message, Database.SaveResult saveResult, List<String> topics) {
        return finest().setMessage(message).setDmlResult(saveResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(String message, Database.SaveResult saveResult) {
        return finest().setMessage(message).setDmlResult(saveResult);
    }

    public static LogEntryEventBuilder finest(String message, Database.UndeleteResult undeleteResult, List<String> topics) {
        return finest().setMessage(message).setDmlResult(undeleteResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(String message, Database.UndeleteResult undeleteResult) {
        return finest().setMessage(message).setDmlResult(undeleteResult);
    }

    public static LogEntryEventBuilder finest(String message, Database.UpsertResult upsertResult, List<String> topics) {
        return finest().setMessage(message).setDmlResult(upsertResult).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(String message, Database.UpsertResult upsertResult) {
        return finest().setMessage(message).setDmlResult(upsertResult);
    }

    public static LogEntryEventBuilder finest(String message, Id recordId, List<String> topics) {
        return finest().setMessage(message).setRecordId(recordId).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(String message, Id recordId) {
        return finest().setMessage(message).setRecordId(recordId);
    }

    public static LogEntryEventBuilder finest(String message, List<String> topics) {
        return finest().setMessage(message).setTopics(topics);
    }

    public static LogEntryEventBuilder finest(String message, SObject record, List<String> topics) {
        return finest().setMessage(message).setRecordId(record).setTopics(topics);
    }

    global static LogEntryEventBuilder finest(String message, SObject record) {
        return finest().setMessage(message).setRecordId(record);
    }

    global static LogEntryEventBuilder finest(String message) {
        return finest().setMessage(message);
    }

    /**
     * Adds a new instance of LogEntryEventBuilder to Logger's buffer, if shouldSave == true
     * @param  loggingLevel The logging level enum for the new entry
     * @param  logMessage   The instance of LogMessage to use as the entry's message
     * @param  shouldSave   Controls if the new entry will be saved. This can be used to save entries, even if the entry's logging level does not meet the user's logging level
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, LogMessage logMessage, Boolean shouldSave) {
        return newEntry(loggingLevel, shouldSave).setMessage(logMessage);
    }

    /**
     * Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
     * @param  loggingLevel The logging level enum for the new entry
     * @param  logMessage   The instance of LogMessage to use as the entry's message
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, LogMessage logMessage) {
        return newEntry(loggingLevel).setMessage(logMessage);
    }

    /**
     * Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
     * @param  loggingLevel The logging level enum for the new entry
     * @param  message      The string to use as the entry's message
     * @param  shouldSave   Controls if the new entry will be saved. This can be used to save entries, even if the entry's logging level does not meet the user's logging level
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, String message, Boolean shouldSave) {
        return newEntry(loggingLevel, shouldSave).setMessage(message);
    }

    /**
     * Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
     * @param  loggingLevel The logging level enum for the new entry
     * @param  message      The string to use as the entry's message
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, String message) {
        return newEntry(loggingLevel).setMessage(message);
    }

    // Save control methods

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
        if (USER_CAN_CREATE_LOG_ENTRY_EVENTS == false) {
            return;
        }

        if (LOG_ENTRIES_BUFFER.isEmpty()) {
            return;
        }

        if (suspendSaving) {
            if (SYSTEM_MESSAGES_ENABLED) {
                finest(getSuspendSavingLogSystemMessage());
            }

            return;
        }

        if (SYSTEM_MESSAGES_ENABLED) {
            finest(getSavingLogSystemMessage(saveMethod));
        }

        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        for (LogEntryEventBuilder logEntryEventBuilder : LOG_ENTRIES_BUFFER) {
            if (logEntryEventBuilder.shouldSave()) {
                LogEntryEvent__e logEntryEvent = logEntryEventBuilder.getLogEntryEvent();
                logEntryEvent.ParentLogTransactionId__c = getParentLogTransactionId();
                logEntryEvent.SystemMode__c = getCurrentQuiddity().name();
                logEntryEvent.TransactionId__c = getTransactionId();

                logEntryEvents.add(logEntryEvent);
            }
        }

        switch on saveMethod {
            when EVENT_BUS {
                // TODO add error handling for when event bus fails to publish
                List<Database.SaveResult> results = EventBus.publish(logEntryEvents);
                System.debug('saveResults =' + results);
            }
            when QUEUEABLE {
                System.enqueueJob(new QueueableSaver(logEntryEvents));
            }
            when REST {
                // If the user doesn't have a session ID (e.g., site guest user), the REST API call will fail
                // To avoid that, use the EventBus instead (even though REST was specified)
                if (String.isBlank(UserInfo.getUserId())) {
                    saveLog(Logger.SaveMethod.EVENT_BUS);
                } else {
                    new RestApiSaver().insertRecords(logEntryEvents);
                }
            }
        }

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
                if (SYSTEM_MESSAGES_ENABLED) {
                    String message = 'Unknown logging level ' + loggingLevelName + 'specified, using ' + DEFAULT_LOGGING_LEVEL.name();
                    finest(message);
                }
                return DEFAULT_LOGGING_LEVEL;
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

    // Private logging level methods to keep global methods simpler/cleaner
    private static LogEntryEventBuilder error() {
        return newEntry(LoggingLevel.ERROR);
    }

    private static LogEntryEventBuilder warn() {
        return newEntry(LoggingLevel.WARN);
    }

    private static LogEntryEventBuilder info() {
        return newEntry(LoggingLevel.INFO);
    }

    private static LogEntryEventBuilder debug() {
        return newEntry(LoggingLevel.DEBUG);
    }

    private static LogEntryEventBuilder fine() {
        return newEntry(LoggingLevel.FINE);
    }

    private static LogEntryEventBuilder finer() {
        return newEntry(LoggingLevel.FINER);
    }

    private static LogEntryEventBuilder finest() {
        return newEntry(LoggingLevel.FINEST);
    }

    private static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel) {
        return newEntry(loggingLevel, isEnabled(loggingLevel));
    }

    private static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, Boolean shouldSave) {
        LogEntryEventBuilder logEntryEventBuilder = new LogEntryEventBuilder(LoggingLevel, shouldSave);
        if (logEntryEventBuilder.shouldSave()) {
            LOG_ENTRIES_BUFFER.add(logEntryEventBuilder);
        }

        return logEntryEventBuilder;
    }

    private static String getSuspendSavingLogSystemMessage() {
        return 'Logging suspended, ignoring call to saveLog()';
    }

    private static String getSavingLogSystemMessage(SaveMethod saveMethod) {
        String savingLogMessage = 'Saving ' + LOG_ENTRIES_BUFFER.size() + ' log entries via ';
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

        return savingLogMessage;
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
        private final String BASE_URL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/data/v51.0';
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
