//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description The core class for logging
 * @see LogEntryEventBuilder
 * @see LogMessage
 */
@SuppressWarnings(
    'PMD.AvoidDebugStatements, PMD.AvoidGlobalModifier, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveClassLength, PMD.ExcessivePublicCount, PMD.PropertyNamingConventions, PMD.StdCyclomaticComplexity'
)
global with sharing class Logger_v2 {
    // There's no reliable way to get the version number dynamically in Apex
    @TestVisible
    private static final String CURRENT_VERSION_NUMBER = 'v4.12.6';
    private static final Map<String, SaveMethod> SAVE_METHOD_NAME_TO_SAVE_METHOD = new Map<String, SaveMethod>();

    private static final Database.DmlOptions PLATFORM_EVENT_DML_OPTIONS {
        get {
            if (PLATFORM_EVENT_DML_OPTIONS == null) {
                PLATFORM_EVENT_DML_OPTIONS = new Database.DmlOptions();
                PLATFORM_EVENT_DML_OPTIONS.AllowFieldTruncation = true;
            }
            return PLATFORM_EVENT_DML_OPTIONS;
        }
        set;
    }

    static {
        LoggerService.getInstance().entryBuilderManager.ignoreOrigin(Logger.class);
        LoggerService.getInstance().entryBuilderManager.ignoreOrigin(LoggerService.class);
        LoggerService.getInstance().entryBuilderManager.ignoreOrigin(LogEntryEventBuilder.class);
        LoggerService.getInstance().entryBuilderManager.ignoreOrigin(LogMessage.class);
        // One of a few limited places in the codebase (except tests) that should use System.debug()
        // The rest of the codebase should use a method in Logger.cls
        System.debug(System.LoggingLevel.INFO, 'Nebula Logger - Version Number: ' + getVersionNumber());
        System.debug(System.LoggingLevel.INFO, 'Nebula Logger - Transaction ID: ' + getTransactionId());
        System.debug(System.LoggingLevel.INFO, 'Nebula Logger - Organization API Version: ' + getOrganizationApiVersion());
    }

    /**
     * @description Enum used to control how LogEntryEvent__e records are inserted
     */
    global enum SaveMethod {
        EVENT_BUS,
        QUEUEABLE,
        REST,
        SYNCHRONOUS_DML
    }

    // System info methods

    /**
     * @description Returns the current version number of Nebula Logger
     * @return The current version number, in the format `v0.0.0`
     */
    global static String getVersionNumber() {
        return LoggerService.getInstance().environmentManager.serviceVersionNumber;
    }

    // TODO delete
    /**
     * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
     *              Returns the current namespace of Nebula Logger
     * @return      The current namespace prefix, or an empty string when no namespace is being used
     */
    public static String getNamespacePrefix() {
        return LoggerService.getInstance().environmentManager.serviceNamespace;
    }

    /**
     * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
     *              Returns the current Salesforce API version number of the org
     * @return      The current API version, in the format `v00.0`
     */
    public static String getOrganizationApiVersion() {
        return LoggerService.getInstance().environmentManager.organizationApiVersion;
    }

    // Settings management methods

    /**
     * @description Returns the unique ID for a particular transaction, stored in Log__c.TransactionId__c
     * @return String - The value of System.Request.getCurrent().getRequestId()
     */
    global static String getTransactionId() {
        return LoggerService.getInstance().transactionContextManager.transactionId;
    }

    /**
     * @description Returns the Quiddity context of the current transaction.
     * @return Quiddity - The value of System.Request.getCurrent().getQuiddity()
     */
    global static Quiddity getCurrentQuiddity() {
        return LoggerService.getInstance().transactionContextManager.quiddity;
    }

    /**
     * @description Stores additional details about the current transacation's async context
     * @param  batchableContext - The instance of `Database.BatchableContext` to track
     */
    global static void setAsyncContext(Database.BatchableContext batchableContext) {
        LoggerService.getInstance().asyncContextManager.setCurrentAsyncContext(batchableContext);
    }

    /**
     * @description Stores additional details about the current transacation's async context
     * @param  finalizerContext - The instance of `System.FinalizerContext` to track
     */
    global static void setAsyncContext(System.FinalizerContext finalizerContext) {
        LoggerService.getInstance().asyncContextManager.setCurrentAsyncContext(finalizerContext);
    }

    /**
     * @description Stores additional details about the current transacation's async context
     * @param  queueableContext - The instance of `System.QueueableContext` to track
     */
    global static void setAsyncContext(System.QueueableContext queueableContext) {
        LoggerService.getInstance().asyncContextManager.setCurrentAsyncContext(queueableContext);
    }

    /**
     * @description Stores additional details about the current transacation's async context
     * @param  schedulableContext - The instance of `System.SchedulableContext` to track
     */
    global static void setAsyncContext(System.SchedulableContext schedulableContext) {
        LoggerService.getInstance().asyncContextManager.setCurrentAsyncContext(schedulableContext);
    }

    /**
     * @description Relates the current transaction's log to a parent log via the field Log__c.ParentLog__c
     *   This is useful for relating multiple asynchronous operations together, such as batch & queueable jobs.
     * @param  parentTransactionId - The transaction ID of the original parent transaction
     */
    global static void setParentLogTransactionId(String parentTransactionId) {
        LoggerService.getInstance().transactionContextManager.setParentLogTransactionId(parentTransactionId);
    }

    /**
     * @description Returns the transaction ID value that will be used to relate the current transaction's log to a parent log
     * @return String - The parent log's transaction ID. This must be explicitly set by calling setParentLogTransactionId(String)
     */
    global static String getParentLogTransactionId() {
        return LoggerService.getInstance().transactionContextManager.getParentLogTransactionId();
    }

    /**
     * @description Indicates if logging has been enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isEnabled() {
        return LoggerService.getInstance().settingsManager.getUserSettings().IsEnabled__c;
    }

    /**
     * @description Indicates if logging for the specified logging level is enabled for the current user, based on the custom setting LoggerSettings__c
     * @param  loggingLevel - The logging level to check
     * @return Boolean
     */
    global static Boolean isEnabled(System.LoggingLevel loggingLevel) {
        return LoggerService.getInstance().settingsManager.meetsUserLoggingLevel(loggingLevel);
    }

    /**
     * @description Indicates if logging level 'ERROR' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isErrorEnabled() {
        return LoggerService.getInstance().settingsManager.meetsUserLoggingLevel(System.LoggingLevel.ERROR);
    }

    /**
     * @description Indicates if logging level 'WARN' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isWarnEnabled() {
        return LoggerService.getInstance().settingsManager.meetsUserLoggingLevel(System.LoggingLevel.WARN);
    }

    /**
     * @description Indicates if logging level 'INFO' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isInfoEnabled() {
        return LoggerService.getInstance().settingsManager.meetsUserLoggingLevel(System.LoggingLevel.INFO);
    }

    /**
     * @description Indicates if logging level 'DEBUG' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isDebugEnabled() {
        return LoggerService.getInstance().settingsManager.meetsUserLoggingLevel(System.LoggingLevel.DEBUG);
    }

    /**
     * @description Indicates if logging level 'FINE' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isFineEnabled() {
        return LoggerService.getInstance().settingsManager.meetsUserLoggingLevel(System.LoggingLevel.FINE);
    }

    /**
     * @description Indicates if logging level 'FINER' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isFinerEnabled() {
        return LoggerService.getInstance().settingsManager.meetsUserLoggingLevel(System.LoggingLevel.FINER);
    }

    /**
     * @description Indicates if logging level 'FINEST' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isFinestEnabled() {
        return LoggerService.getInstance().settingsManager.meetsUserLoggingLevel(System.LoggingLevel.FINEST);
    }

    /**
     * @description Indicates if the specified logging level is enabled for the current user, based on the custom setting LoggerSettings__c
     * @param loggingLevel the logging level to check.
     * @return Boolean
     */
    global static Boolean meetsUserLoggingLevel(System.LoggingLevel loggingLevel) {
        return LoggerService.getInstance().settingsManager.meetsUserLoggingLevel(loggingLevel);
    }

    /**
     * @description Returns the logging level for the current user, based on the custom setting LoggerSettings__c
     * @return System.LoggingLevel - The matching instance of LoggingLevel
     */
    global static System.LoggingLevel getUserLoggingLevel() {
        return LoggerService.getInstance().settingsManager.getUserLoggingLevel();
    }

    /**
     * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
     *              Creates a new, unsaved `LoggerSettings__c` record
     * @return      A new `LoggerSettings__c` record, with all fields populated with default field values
     */
    public static LoggerSettings__c createSettings() {
        return (LoggerSettings__c) Schema.LoggerSettings__c.SObjectType.newSObject(null, true);
    }

    /**
     * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
     *              Returns the current user's instance of `LoggerSettings__c`
     * @return      LoggerSettings__c - The current user's instance of the custom settings
     */
    public static LoggerSettings__c getUserSettings() {
        return LoggerService.getInstance().settingsManager.getUserSettings();
    }

    /**
     * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
     *              Returns the specified user's instance of `LoggerSettings__c`
     * @param       loggingUser The user record - at a minimum, this record should have the user Id and Profile fields populated
     * @return      LoggerSettings__c - The specified user's instance of the custom settings
     */
    public static LoggerSettings__c getUserSettings(Schema.User loggingUser) {
        return LoggerService.getInstance().settingsManager.getUserSettings(loggingUser);
    }

    // Transaction control methods

    /**
     * @description Indicates if saving has been temporarily suspended for the current transaction
     * @return Boolean
     */
    global static Boolean isSavingSuspended() {
        return LoggerService.getInstance().saveManager.isSavingSuspended();
    }

    /**
     * @description Pauses saving for the current transaction.
     *   Any calls to saveLog() are ignored until saving is resumed.
     */
    global static void suspendSaving() {
        LoggerService.getInstance().saveManager.suspendSaving();
    }

    /**
     * @description Resumes saving for the current transaction, used to reverse suspendSaving().
     *   Any calls to saveLog() are ignored until saving is resumed.
     */
    global static void resumeSaving() {
        LoggerService.getInstance().saveManager.resumeSaving();
    }

    /**
     * @description Returns the number of entries that have been generated but not yet saved
     * @return Integer
     */
    global static Integer getBufferSize() {
        return LoggerService.getInstance().entryBuilderManager.getBuffer().size();
    }

    /**
     * @description Discards any entries that have been generated but not yet saved
     */
    global static void flushBuffer() {
        LoggerService.getInstance().entryBuilderManager.flushBuffer();
    }

    // Exception methods - these all use ERROR logging level & automatically save & throw the provided exception
    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`,
     *              automatically saves the log, and then throws the provided exception
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  apexException The instance of `System.Exception` to log and throw
     */
    global static void exception(LogMessage logMessage, System.Exception apexException) {
        error().setExceptionDetails(apexException).setMessage(logMessage);
        saveLog(SaveMethod.EVENT_BUS);
        throw apexException;
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`,
     *              automatically saves the log, and then throws the provided exception
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `System.Exception` to log and throw
     */
    global static void exception(LogMessage logMessage, Id recordId, System.Exception apexException) {
        error().setRecordId(recordId).setExceptionDetails(apexException).setMessage(logMessage);
        saveLog(SaveMethod.EVENT_BUS);
        throw apexException;
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`,
     *              automatically saves the log, and then throws the provided exception
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `System.Exception` to log and throw
     */
    global static void exception(LogMessage logMessage, SObject record, System.Exception apexException) {
        error().setRecordId(record).setExceptionDetails(apexException).setMessage(logMessage);
        saveLog(SaveMethod.EVENT_BUS);
        throw apexException;
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`,
     *              automatically saves the log, and then throws the provided exception
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `System.Exception` to log and throw
     */
    global static void exception(LogMessage logMessage, List<SObject> records, System.Exception apexException) {
        error().setRecord(records).setExceptionDetails(apexException).setMessage(logMessage);
        saveLog(SaveMethod.EVENT_BUS);
        throw apexException;
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`,
     *              automatically saves the log, and then throws the provided exception
     * @param  message       The string to use to set the entry's message field
     * @param  apexException The instance of `System.Exception` to log and throw
     */
    global static void exception(String message, System.Exception apexException) {
        error().setExceptionDetails(apexException).setMessage(message);
        saveLog(SaveMethod.EVENT_BUS);
        throw apexException;
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`,
     *              automatically saves the log, and then throws the provided exception
     * @param  message       The string to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `System.Exception` to log and throw
     */
    global static void exception(String message, Id recordId, System.Exception apexException) {
        error().setRecordId(recordId).setExceptionDetails(apexException).setMessage(message);
        saveLog(SaveMethod.EVENT_BUS);
        throw apexException;
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`,
     *              automatically saves the log, and then throws the provided exception
     * @param  message       The string to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `System.Exception` to log and throw
     */
    global static void exception(String message, SObject record, System.Exception apexException) {
        error().setRecordId(record).setExceptionDetails(apexException).setMessage(message);
        saveLog(SaveMethod.EVENT_BUS);
        throw apexException;
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`,
     *              automatically saves the log, and then throws the provided exception
     * @param  message       The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `System.Exception` to log and throw
     */
    global static void exception(String message, List<SObject> records, System.Exception apexException) {
        error().setRecord(records).setExceptionDetails(apexException).setMessage(message);
        saveLog(SaveMethod.EVENT_BUS);
        throw apexException;
    }

    // ERROR logging level methods
    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage        The instance of `LogMessage` to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.LeadConvertResult leadConvertResult) {
        return error().setDatabaseResult(leadConvertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return error().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.MergeResult mergeResult) {
        return error().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.SaveResult saveResult) {
        return error().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return error().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return error().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return error().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return error().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return error().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return error().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return error().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, System.Exception apexException) {
        return error().setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId, System.Exception apexException) {
        return error().setRecordId(recordId).setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId) {
        return error().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, SObject record, System.Exception apexException) {
        return error().setRecordId(record).setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, SObject record) {
        return error().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<SObject> records, System.Exception apexException) {
        return error().setRecord(records).setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<SObject> records) {
        return error().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage) {
        return error().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message           The string to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.LeadConvertResult leadConvertResult) {
        return error().setDatabaseResult(leadConvertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.DeleteResult deleteResult) {
        return error().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.MergeResult mergeResult) {
        return error().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.SaveResult saveResult) {
        return error().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.UndeleteResult undeleteResult) {
        return error().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.UpsertResult upsertResult) {
        return error().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.DeleteResult> deleteResults) {
        return error().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.MergeResult> mergeResults) {
        return error().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.SaveResult> saveResults) {
        return error().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.UndeleteResult> undeleteResults) {
        return error().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.UpsertResult> upsertResults) {
        return error().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, System.Exception apexException) {
        return error().setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Id recordId, System.Exception apexException) {
        return error().setRecordId(recordId).setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Id recordId) {
        return error().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, SObject record, System.Exception apexException) {
        return error().setRecordId(record).setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, SObject record) {
        return error().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<SObject> records, System.Exception apexException) {
        return error().setRecord(records).setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<SObject> records) {
        return error().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message) {
        return error().setMessage(message);
    }

    // WARN logging level methods
    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage        The instance of `LogMessage` to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.LeadConvertResult leadConvertResult) {
        return warn().setDatabaseResult(leadConvertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return warn().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.MergeResult mergeResult) {
        return warn().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.SaveResult saveResult) {
        return warn().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return warn().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return warn().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return warn().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return warn().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return warn().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return warn().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return warn().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, System.Exception apexException) {
        return warn().setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId, System.Exception apexException) {
        return warn().setRecordId(recordId).setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId) {
        return warn().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, SObject record, System.Exception apexException) {
        return warn().setRecordId(record).setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, SObject record) {
        return warn().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<SObject> records, System.Exception apexException) {
        return warn().setRecord(records).setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<SObject> records) {
        return warn().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage) {
        return warn().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message           The string to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.LeadConvertResult leadConvertResult) {
        return warn().setDatabaseResult(leadConvertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.DeleteResult deleteResult) {
        return warn().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.MergeResult mergeResult) {
        return warn().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.SaveResult saveResult) {
        return warn().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.UndeleteResult undeleteResult) {
        return warn().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.UpsertResult upsertResult) {
        return warn().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.DeleteResult> deleteResults) {
        return warn().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.MergeResult> mergeResults) {
        return warn().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.SaveResult> saveResults) {
        return warn().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.UndeleteResult> undeleteResults) {
        return warn().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.UpsertResult> upsertResults) {
        return warn().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, System.Exception apexException) {
        return warn().setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Id recordId, System.Exception apexException) {
        return warn().setRecordId(recordId).setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Id recordId) {
        return warn().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, SObject record, System.Exception apexException) {
        return warn().setRecordId(record).setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, SObject record) {
        return warn().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `System.Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<SObject> records, System.Exception apexException) {
        return warn().setRecord(records).setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<SObject> records) {
        return warn().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message) {
        return warn().setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage        The instance of `LogMessage` to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.LeadConvertResult leadConvertResult) {
        return info().setDatabaseResult(leadConvertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return info().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.MergeResult mergeResult) {
        return info().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.SaveResult saveResult) {
        return info().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return info().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return info().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return info().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return info().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return info().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return info().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return info().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Id recordId) {
        return info().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, SObject record) {
        return info().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<SObject> records) {
        return info().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage) {
        return info().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message           The string to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.LeadConvertResult leadConvertResult) {
        return info().setDatabaseResult(leadConvertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.DeleteResult deleteResult) {
        return info().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.MergeResult mergeResult) {
        return info().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.SaveResult saveResult) {
        return info().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.UndeleteResult undeleteResult) {
        return info().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.UpsertResult upsertResult) {
        return info().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.DeleteResult> deleteResults) {
        return info().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.MergeResult> mergeResults) {
        return info().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.SaveResult> saveResults) {
        return info().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.UndeleteResult> undeleteResults) {
        return info().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.UpsertResult> upsertResults) {
        return info().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Id recordId) {
        return info().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, SObject record) {
        return info().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<SObject> records) {
        return info().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message) {
        return info().setMessage(message);
    }

    // DEBUG log level methods
    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.LeadConvertResult leadConvertResult) {
        return debug().setDatabaseResult(leadConvertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return debug().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.MergeResult mergeResult) {
        return debug().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.SaveResult saveResult) {
        return debug().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return debug().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return debug().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return debug().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return debug().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return debug().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return debug().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return debug().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Id recordId) {
        return debug().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, SObject record) {
        return debug().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<SObject> records) {
        return debug().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage) {
        return debug().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message           The string to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.LeadConvertResult leadConvertResult) {
        return debug().setDatabaseResult(leadConvertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.DeleteResult deleteResult) {
        return debug().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.MergeResult mergeResult) {
        return debug().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.SaveResult saveResult) {
        return debug().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.UndeleteResult undeleteResult) {
        return debug().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.UpsertResult upsertResult) {
        return debug().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.DeleteResult> deleteResults) {
        return debug().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.MergeResult> mergeResults) {
        return debug().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.SaveResult> saveResults) {
        return debug().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.UndeleteResult> undeleteResults) {
        return debug().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.UpsertResult> upsertResults) {
        return debug().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Id recordId) {
        return debug().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, SObject record) {
        return debug().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<SObject> records) {
        return debug().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message) {
        return debug().setMessage(message);
    }

    // FINE log level methods
    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.LeadConvertResult leadConvertResult) {
        return fine().setDatabaseResult(leadConvertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return fine().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.MergeResult mergeResult) {
        return fine().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.SaveResult saveResult) {
        return fine().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return fine().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return fine().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return fine().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return fine().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return fine().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return fine().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return fine().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Id recordId) {
        return fine().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, SObject record) {
        return fine().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<SObject> records) {
        return fine().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage) {
        return fine().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message           The string to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.LeadConvertResult leadConvertResult) {
        return fine().setDatabaseResult(leadConvertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.DeleteResult deleteResult) {
        return fine().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.MergeResult mergeResult) {
        return fine().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.SaveResult saveResult) {
        return fine().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.UndeleteResult undeleteResult) {
        return fine().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.UpsertResult upsertResult) {
        return fine().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.DeleteResult> deleteResults) {
        return fine().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.MergeResult> mergeResults) {
        return fine().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.SaveResult> saveResults) {
        return fine().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.UndeleteResult> undeleteResults) {
        return fine().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.UpsertResult> upsertResults) {
        return fine().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Id recordId) {
        return fine().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, SObject record) {
        return fine().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<SObject> records) {
        return fine().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message) {
        return fine().setMessage(message);
    }

    // FINER log level methods
    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.LeadConvertResult leadConvertResult) {
        return finer().setDatabaseResult(leadConvertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return finer().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.MergeResult mergeResult) {
        return finer().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.SaveResult saveResult) {
        return finer().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return finer().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return finer().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return finer().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return finer().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return finer().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return finer().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return finer().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Id recordId) {
        return finer().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, SObject record) {
        return finer().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<SObject> records) {
        return finer().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage) {
        return finer().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message           The string to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.LeadConvertResult leadConvertResult) {
        return finer().setDatabaseResult(leadConvertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.DeleteResult deleteResult) {
        return finer().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.MergeResult mergeResult) {
        return finer().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.SaveResult saveResult) {
        return finer().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.UndeleteResult undeleteResult) {
        return finer().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.UpsertResult upsertResult) {
        return finer().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.DeleteResult> deleteResults) {
        return finer().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.MergeResult> mergeResults) {
        return finer().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.SaveResult> saveResults) {
        return finer().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.UndeleteResult> undeleteResults) {
        return finer().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.UpsertResult> upsertResults) {
        return finer().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Id recordId) {
        return finer().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, SObject record) {
        return finer().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<SObject> records) {
        return finer().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message) {
        return finer().setMessage(message);
    }

    // FINEST log level methods
    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.LeadConvertResult leadConvertResult) {
        return finest().setDatabaseResult(leadConvertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return finest().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.MergeResult mergeResult) {
        return finest().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.SaveResult saveResult) {
        return finest().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return finest().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return finest().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return finest().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return finest().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return finest().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return finest().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return finest().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Id recordId) {
        return finest().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, SObject record) {
        return finest().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<SObject> records) {
        return finest().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage) {
        return finest().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message           The string to use to set the entry's message field
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.LeadConvertResult leadConvertResult) {
        return finest().setDatabaseResult(leadConvertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.DeleteResult deleteResult) {
        return finest().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.MergeResult mergeResult) {
        return finest().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.SaveResult saveResult) {
        return finest().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.UndeleteResult undeleteResult) {
        return finest().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.UpsertResult upsertResult) {
        return finest().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.DeleteResult> deleteResults) {
        return finest().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.MergeResult> mergeResults) {
        return finest().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.SaveResult> saveResults) {
        return finest().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.UndeleteResult> undeleteResults) {
        return finest().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.UpsertResult> upsertResults) {
        return finest().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Id recordId) {
        return finest().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, SObject record) {
        return finest().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<SObject> records) {
        return finest().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message) {
        return finest().setMessage(message);
    }

    /**
     * @description Creates a log entry for any results within the provided `List<LeadConvertResult>` where `isSuccess() != true`
     * @param  loggingLevel       The logging level to use for the log entry
     * @param  logMessage         The instance of `LogMessage` to use to set the entry's message field
     * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
     * @return                    The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(
        System.LoggingLevel loggingLevel,
        LogMessage logMessage,
        List<Database.LeadConvertResult> leadConvertResults
    ) {
        return logDatabaseErrors(loggingLevel, logMessage.getMessage(), leadConvertResults);
    }

    /**
     * @description Creates a log entry for any results within the provided `List<LeadConvertResult>` where `isSuccess() != true`
     * @param  loggingLevel  The logging level to use for the log entry
     * @param  message       The string to use to set the entry's message field
     * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
     * @return               The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(
        System.LoggingLevel loggingLevel,
        String message,
        List<Database.LeadConvertResult> leadConvertResults
    ) {
        List<Database.LeadConvertResult> resultsToLog = new List<Database.LeadConvertResult>();
        for (Database.LeadConvertResult leadConvertResult : leadConvertResults) {
            if (leadConvertResult.isSuccess() == false) {
                resultsToLog.add(leadConvertResult);
            }
        }

        Boolean shouldSave = resultsToLog.isEmpty() == false && isEnabled(loggingLevel);
        return newEntry(loggingLevel, message, shouldSave).setDatabaseResult(resultsToLog);
    }

    /**
     * @description Creates a log entry for any results within the provided `List<DeleteResult>` where `isSuccess() != true`
     * @param  loggingLevel  The logging level to use for the log entry
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return logDatabaseErrors(loggingLevel, logMessage.getMessage(), deleteResults);
    }

    /**
     * @description Creates a log entry for any results within the provided `List<DeleteResult>` where `isSuccess() != true`
     * @param  loggingLevel  The logging level to use for the log entry
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.DeleteResult> deleteResults) {
        List<Database.DeleteResult> resultsToLog = new List<Database.DeleteResult>();
        for (Database.DeleteResult deleteResult : deleteResults) {
            if (deleteResult.isSuccess() == false) {
                resultsToLog.add(deleteResult);
            }
        }

        Boolean shouldSave = resultsToLog.isEmpty() == false && isEnabled(loggingLevel);
        return newEntry(loggingLevel, message, shouldSave).setDatabaseResult(resultsToLog);
    }

    /**
     * @description Creates a log entry for any results within the provided `List<MergeResult>` where `isSuccess() != true`
     * @param  loggingLevel The logging level to use for the log entry
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return logDatabaseErrors(loggingLevel, logMessage.getMessage(), mergeResults);
    }

    /**
     * @description Creates a log entry for any results within the provided `List<MergeResult>` where `isSuccess() != true`
     * @param  loggingLevel The logging level to use for the log entry
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.MergeResult> mergeResults) {
        List<Database.MergeResult> resultsToLog = new List<Database.MergeResult>();
        for (Database.MergeResult mergeResult : mergeResults) {
            if (mergeResult.isSuccess() == false) {
                resultsToLog.add(mergeResult);
            }
        }

        Boolean shouldSave = resultsToLog.isEmpty() == false && isEnabled(loggingLevel);
        return newEntry(loggingLevel, message, shouldSave).setDatabaseResult(resultsToLog);
    }

    /**
     * @description Creates a log entry for any results within the provided `List<SaveResult>` where `isSuccess() != true`
     * @param  loggingLevel The logging level to use for the log entry
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults  The instance of `List<Database.SaveResult>` to log
     * @return              The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return logDatabaseErrors(loggingLevel, logMessage.getMessage(), saveResults);
    }

    /**
     * @description Creates a log entry for any results within the provided `List<SaveResult>` where `isSuccess() != true`
     * @param  loggingLevel The logging level to use for the log entry
     * @param  message      The string to use to set the entry's message field
     * @param  saveResults  The instance of `List<Database.SaveResult>` to log
     * @return              The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.SaveResult> saveResults) {
        List<Database.SaveResult> resultsToLog = new List<Database.SaveResult>();
        for (Database.SaveResult saveResult : saveResults) {
            if (saveResult.isSuccess() == false) {
                resultsToLog.add(saveResult);
            }
        }

        Boolean shouldSave = resultsToLog.isEmpty() == false && isEnabled(loggingLevel);
        return newEntry(loggingLevel, message, shouldSave).setDatabaseResult(resultsToLog);
    }

    /**
     * @description Creates a log entry for any results within the provided `List<UpsertResult>` where `isSuccess() != true`
     * @param  loggingLevel  The logging level to use for the log entry
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return logDatabaseErrors(loggingLevel, logMessage.getMessage(), upsertResults);
    }

    /**
     * @description Creates a log entry for any results within the provided `List<UpsertResult>` where `isSuccess() != true`
     * @param  loggingLevel  The logging level to use for the log entry
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.UpsertResult> upsertResults) {
        List<Database.UpsertResult> resultsToLog = new List<Database.UpsertResult>();
        for (Database.UpsertResult upsertResult : upsertResults) {
            if (upsertResult.isSuccess() == false) {
                resultsToLog.add(upsertResult);
            }
        }

        Boolean shouldSave = resultsToLog.isEmpty() == false && isEnabled(loggingLevel);
        return newEntry(loggingLevel, message, shouldSave).setDatabaseResult(resultsToLog);
    }

    /**
     * @description Creates a log entry for any results within the provided `List<UndeleteResult>` where `isSuccess() != true`
     * @param  loggingLevel    The logging level to use for the log entry
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(
        System.LoggingLevel loggingLevel,
        LogMessage logMessage,
        List<Database.UndeleteResult> undeleteResults
    ) {
        return logDatabaseErrors(loggingLevel, logMessage.getMessage(), undeleteResults);
    }

    /**
     * @description Creates a log entry for any results within the provided `List<UndeleteResult>` where `isSuccess() != true`
     * @param  loggingLevel    The logging level to use for the log entry
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.UndeleteResult> undeleteResults) {
        List<Database.UndeleteResult> resultsToLog = new List<Database.UndeleteResult>();
        for (Database.UndeleteResult undeleteResult : undeleteResults) {
            if (undeleteResult.isSuccess() == false) {
                resultsToLog.add(undeleteResult);
            }
        }

        Boolean shouldSave = resultsToLog.isEmpty() == false && isEnabled(loggingLevel);
        return newEntry(loggingLevel, message, shouldSave).setDatabaseResult(resultsToLog);
    }

    /**
     * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, when `shouldSave` is `true`
     * @param  loggingLevel The logging level enum value for the new entry
     * @param  logMessage   The instance of LogMessage to use as the entry's message
     * @param  shouldSave   Controls if the new entry will be saved. This can be used to save entries, even if the entry's logging level does not meet the user's logging level
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel, LogMessage logMessage, Boolean shouldSave) {
        return LoggerService.getInstance().entryBuilderManager.newEntry(loggingLevel, shouldSave).setMessage(logMessage);
    }

    /**
     * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
     * @param  loggingLevel The logging level enum value for the new entry
     * @param  logMessage   The instance of LogMessage to use as the entry's message
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel, LogMessage logMessage) {
        return LoggerService.getInstance().entryBuilderManager.newEntry(loggingLevel).setMessage(logMessage);
    }

    /**
     * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
     * @param  loggingLevel The logging level enum value for the new entry
     * @param  message      The string to use as the entry's message
     * @param  shouldSave   Controls if the new entry will be saved. This can be used to save entries, even if the entry's logging level does not meet the user's logging level
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel, String message, Boolean shouldSave) {
        return LoggerService.getInstance().entryBuilderManager.newEntry(loggingLevel, shouldSave).setMessage(message);
    }

    /**
     * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
     * @param  loggingLevel The logging level enum value for the new entry
     * @param  message      The string to use as the entry's message
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel, String message) {
        return LoggerService.getInstance().entryBuilderManager.newEntry(loggingLevel).setMessage(message);
    }

    // Save control methods
    /**
     * @description Returns the scenario name for the current transaction - this is stored in `LogEntryEvent__e.Scenario__c`
     *              and `Log__c.Scenario__c`, and can be used to filter & group logs
     * @return   The value currently set as the current transaction's scenario
     */
    global static String getScenario() {
        return LoggerService.getInstance().scenarioManager.getCurrentEntryScenario();
    }

    /**
     * @description Sets the current scenario, which can be used to identify modules or groupings of  for the current transaction
     * @param  scenario The name to use for the current transaction's scenario
     */
    @SuppressWarnings('PMD.NcssMethodCount')
    global static void setScenario(String scenario) {
        LoggerService.getInstance().scenarioManager.setScenario(scenario);
    }

    /**
     * @description End the specified scenario, if it's the currently active scenario,
     *              and rolls back to the previous scenario (if a previous scenario was specified in the current transaction)
     * @param  scenario The name of the scenario to end
     */
    global static void endScenario(String scenario) {
        LoggerService.getInstance().scenarioManager.endScenario(scenario);
    }

    /**
     * @description Adds the specified Apex type to the list of ignored origin locations for the current transaction.
     *              Any ignored types will be removed from the StackTrace__c field, and will be skipped when determining
     *              the log entry's origin location
     * @param  apexType The Apex type of the class to ignore
     */
    global static void ignoreOrigin(System.Type apexType) {
        LoggerService.getInstance().entryBuilderManager.ignoreOrigin(apexType);
    }

    /**
     * @description Returns the default save method used when calling saveLog() - set via LoggerSettings__c or by calling setSaveMethod(SaveMethod saveMethod)
     * @return   The enum value of Logger.SaveMethod to use for any calls to saveLog() in the current transaction
     */
    global static SaveMethod getSaveMethod() {
        if (SAVE_METHOD_NAME_TO_SAVE_METHOD.isEmpty()) {
            for (SaveMethod method : SaveMethod.values()) {
                SAVE_METHOD_NAME_TO_SAVE_METHOD.put(method.name(), method);
            }
        }

        return SAVE_METHOD_NAME_TO_SAVE_METHOD.get(LoggerService.getInstance().saveManager.getSaveMethodName());
    }

    /**
     * @description Sets the default save method used when calling saveLog() - any subsequent calls to saveLog() will use the specified save method
     * @param  saveMethod The enum value of Logger.SaveMethod to use for any other calls to saveLog() in the current transaction
     */
    global static void setSaveMethod(SaveMethod saveMethod) {
        LoggerService.getInstance().saveManager.setSaveMethod(saveMethod.name());
    }

    /**
     * @description Saves any entries in Logger's buffer. By default, entries are saved via Apex's EventBus and can be overridden with setSaveMethod(SaveMethod saveMethod)
     */
    @InvocableMethod(category='Logging' label='Save Log' description='Saves any log entries that have been generated')
    global static void saveLog() {
        LoggerService.getInstance().saveManager.saveLog();
    }

    /**
     * @description Saves any entries in Logger's buffer, using the specified save method for only this call.
     *   All subsequent calls to saveLog() will use the transaction save method.
     * @param  saveMethod The enum value of Logger.SaveMethod to use for this specific save action.
     */
    global static void saveLog(SaveMethod saveMethod) {
        saveLog(saveMethod.name());
    }

    /**
     * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
     *              Saves any entries in Logger's buffer, using the specified save method for only this call.
     *              All subsequent calls to saveLog() will use the transaction save method.
     * @param  saveMethodName The String value of the save method to use for this specific save action.
     */
    @SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount')
    public static void saveLog(String saveMethodName) {
        LoggerService.getInstance().saveManager.saveLog(saveMethodName);
    }

    // Utility methods

    /**
     * @description Converts a String to an instance of LoggingLevel
     * @param  loggingLevelName The string name of an Apex logging level
     * @return                  The matching instance of System.LoggingLevel (or a default value if a match is not found)
     */
    global static System.LoggingLevel getLoggingLevel(String loggingLevelName) {
        return LoggerService.getInstance().settingsManager.getLoggingLevel(loggingLevelName);
    }

    /**
     * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
     *              Calls Salesforce's API endpoint https://api.status.salesforce.com/v1/instances/
     *              to get more details about the current org, including the org's release number and release version.
     *              Trust API docs available at https://api.status.salesforce.com/v1/docs/
     * @return      An instance of `Logger.StatusApiResponse` (a DTO that maps to the JSON returned by the status API endpoint),
     *              or `null` when the callout fails (due to the remote site setting being disabled, the endpoint being unable, etc.).
     */
    public static LoggerService.StatusApiResponse callStatusApi() {
        return LoggerService.getInstance().statusApiClient.callStatusApi();
    }

    // Private logging level methods to keep global methods simpler/cleaner
    private static LogEntryEventBuilder error() {
        return LoggerService.getInstance().entryBuilderManager.newEntry(System.LoggingLevel.ERROR);
    }

    private static LogEntryEventBuilder warn() {
        return LoggerService.getInstance().entryBuilderManager.newEntry(System.LoggingLevel.WARN);
    }

    private static LogEntryEventBuilder info() {
        return LoggerService.getInstance().entryBuilderManager.newEntry(System.LoggingLevel.INFO);
    }

    private static LogEntryEventBuilder debug() {
        return LoggerService.getInstance().entryBuilderManager.newEntry(System.LoggingLevel.DEBUG);
    }

    private static LogEntryEventBuilder fine() {
        return LoggerService.getInstance().entryBuilderManager.newEntry(System.LoggingLevel.FINE);
    }

    private static LogEntryEventBuilder finer() {
        return LoggerService.getInstance().entryBuilderManager.newEntry(System.LoggingLevel.FINER);
    }

    private static LogEntryEventBuilder finest() {
        return LoggerService.getInstance().entryBuilderManager.newEntry(System.LoggingLevel.FINEST);
    }

    // Inner class for saving log entries via a queuable job
    /**
     * @description Inner class for publishing log entries via the Queueable interface.
     */
    global class QueueableSaver implements Queueable {
        private List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();

        private QueueableSaver(List<LogEntryEvent__e> logEntryEvents) {
            this.logEntryEvents = logEntryEvents;
        }

        /**
         * @description Asynchronoulsy publishes the list of `LogEntryEvent__e` records
         * @param queueableContext The context of the current queue, provided by the platform
         */
        global void execute(System.QueueableContext queueableContext) {
            Logger.setAsyncContext(queueableContext);
            LoggerDataStore.getEventBus().publishRecords(this.logEntryEvents, PLATFORM_EVENT_DML_OPTIONS);
        }
    }


    // Inner class for saving log entries via the REST API (using the current user's session ID)
    private class RestApiSaver {
        private final String baseURL = LoggerService.getInstance().environmentManager.organizationDomainUrl + '/services/data/' + getOrganizationApiVersion();
        private final String compositeEndpoint = '/composite/sobjects';

        @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
        /**
         * @description Inserts records via the REST api.
         * @param records The records to save.
         */
        public void insertRecords(List<SObject> records) {
            System.HttpRequest request = new System.HttpRequest();
            request.setEndpoint(baseURL + compositeEndpoint);
            request.setHeader('Authorization', 'Bearer ' + LoggerService.getInstance().transactionContextManager.userSessionId);
            request.setHeader('Content-Type', 'application/json; charset=utf-8');
            request.setMethod('POST');

            Boolean allOrNone = true;
            RestSaveRequest saveRequest = new RestSaveRequest(records, allOrNone);
            request.setBody(JSON.serialize(saveRequest));

            System.HttpResponse response = new System.Http().send(request);
            this.validateResponse(response);
        }

        private void validateResponse(System.HttpResponse response) {
            Integer statusCode = response.getStatusCode();
            if (statusCode >= 400) {
                String errorMessage = 'Saving via REST API failed. Received request status code ' + statusCode + ', status message: ' + response.getStatus();
                throw new System.CalloutException(errorMessage);
            }
        }
    }

    // Inner class that matches the format expected by the REST API for saving SObjects
    private class RestSaveRequest {
        /**
         * @description Boolean used when saving records.  If true, all records must save correctly or an exception
         * is thrown.  If false, partial processing is enabled, and if an indidividual record fails, successful records are still saved without exception.
         */
        public Boolean allOrNone { get; set; }

        /**
         * @description List of records to save.
         */
        public List<SObject> records { get; set; }

        private RestSaveRequest(List<SObject> records, Boolean allOrNone) {
            this.allOrNone = allOrNone;
            this.records = records;
        }
    }
}
