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
@SuppressWarnings('PMD.AvoidDebugStatements, PMD.AvoidGlobalModifier, PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.ExcessiveClassLength')
global with sharing class Logger {
    // There's no reliable way to get the version number dynamically in Apex
    @TestVisible
    private static final String CURRENT_VERSION_NUMBER = 'v4.7.6';
    private static final LoggingLevel DEFAULT_LOGGING_LEVEL = LoggingLevel.DEBUG;
    private static final List<LogEntryEventBuilder> LOG_ENTRIES_BUFFER = new List<LogEntryEventBuilder>();
    private static final Map<String, LogScenarioRule__mdt> MOCK_SCENARIO_TO_SCENARIO_RULE = new Map<String, LogScenarioRule__mdt>();
    private static final String TRANSACTION_ID = new Uuid().getValue();
    private static final Quiddity TRANSACTION_QUIDDITY = setTransactionQuiddity();
    private static final Boolean USE_FIRST_SPECIFIED_SCENARIO = LoggerParameter.getBoolean('UseFirstSpecifiedScenario', true);

    private static Integer currentTransactionEntryNumber = 1;
    @TestVisible
    private static String lastSaveMethodNameUsed;
    private static String parentLogTransactionId;
    @TestVisible
    private static Integer saveLogCallCount = 0;
    private static Boolean suspendSaving = false;
    private static String transactionScenario = getUserSettings().DefaultLogScenario__c;
    private static LoggerSettings__c userSettings;

    private static String transactionSaveMethodName {
        get {
            if (transactionSaveMethodName == null) {
                transactionSaveMethodName = getUserSettings().DefaultSaveMethod__c;
            }
            return transactionSaveMethodName;
        }
        set;
    }

    private static LoggingLevel userLoggingLevel {
        get {
            if (userLoggingLevel == null || userLoggingLevel.name() != getUserSettings().LoggingLevel__c) {
                userLoggingLevel = getLoggingLevel(getUserSettings().LoggingLevel__c);
            }
            return userLoggingLevel;
        }
        set;
    }

    static {
        // 1 of 2 places in the codebase (except tests) that should use System.debug()
        // The rest of the codebase should use a method in Logger.cls
        System.debug(LoggingLevel.INFO, 'Logger - Version Number: ' + getVersionNumber());
        System.debug(LoggingLevel.INFO, 'Logger - Transaction ID: ' + getTransactionId());
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
    public static String getVersionNumber() {
        return CURRENT_VERSION_NUMBER;
    }

    /**
     * @description Returns the current namespace of Nebula Logger
     * @return   The current namespace prefix, or an empty string when no namespace is being used
     */
    public static String getNamespacePrefix() {
        String className = Logger.class.getName();
        return className.contains('.') ? className.substringBefore('.') : '';
    }

    // Settings management methods

    /**
     * @description Returns the unique ID for a particular transaction, stored in Log__c.TransactionId__c
     * @return String - The value of System.Request.getCurrent().getRequestId()
     */
    global static String getTransactionId() {
        return TRANSACTION_ID;
    }

    /**
     * @description Returns the Quiddity context of the current transaction.
     * @return Quiddity - The value of System.Request.getCurrent().getQuiddity()
     */
    global static Quiddity getCurrentQuiddity() {
        return TRANSACTION_QUIDDITY;
    }

    /**
     * @description Relates the current transaction's log to a parent log via the field Log__c.ParentLog__c
     *   This is useful for relating multiple asynchronous operations together, such as batch & queueable jobs.
     * @param  parentTransactionId - The transaction ID of the original parent transaction
     */
    global static void setParentLogTransactionId(String parentTransactionId) {
        if (parentTransactionId != getTransactionId()) {
            parentLogTransactionId = parentTransactionId;
        }
    }

    /**
     * @description Returns the transaction ID value that will be used to relate the current transaction's log to a parent log
     * @return String - The parent log's transaction ID. This must be explicitly set by calling setParentLogTransactionId(String)
     */
    global static String getParentLogTransactionId() {
        return parentLogTransactionId;
    }

    /**
     * @description Indicates if logging has been enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isEnabled() {
        return getUserSettings().IsEnabled__c;
    }

    /**
     * @description Indicates if logging for the specified logging level is enabled for the current user, based on the custom setting LoggerSettings__c
     * @param  loggingLevel - The logging level to check
     * @return Boolean
     */
    global static Boolean isEnabled(LoggingLevel loggingLevel) {
        return isEnabled() && meetsUserLoggingLevel(loggingLevel);
    }

    /**
     * @description Indicates if logging level 'ERROR' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isErrorEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.ERROR);
    }

    /**
     * @description Indicates if logging level 'WARN' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isWarnEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.WARN);
    }

    /**
     * @description Indicates if logging level 'INFO' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isInfoEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.INFO);
    }

    /**
     * @description Indicates if logging level 'DEBUG' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isDebugEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.DEBUG);
    }

    /**
     * @description Indicates if logging level 'FINE' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isFineEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINE);
    }

    /**
     * @description Indicates if logging level 'FINER' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isFinerEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINER);
    }

    /**
     * @description Indicates if logging level 'FINEST' is enabled for the current user, based on the custom setting LoggerSettings__c
     * @return Boolean
     */
    global static Boolean isFinestEnabled() {
        return isEnabled() && meetsUserLoggingLevel(LoggingLevel.FINEST);
    }

    /**
     * @description Indicates if the specified logging level is enabled for the current user, based on the custom setting LoggerSettings__c
     * @param logEntryLoggingLevel the logging level to check.
     * @return Boolean
     */
    global static Boolean meetsUserLoggingLevel(LoggingLevel logEntryLoggingLevel) {
        return userLoggingLevel.ordinal() <= logEntryLoggingLevel.ordinal();
    }

    /**
     * @description Returns the logging level for the current user, based on the custom setting LoggerSettings__c
     * @return LoggingLevel - The matching instance of LoggingLevel
     */
    global static LoggingLevel getUserLoggingLevel() {
        return userLoggingLevel;
    }

    /**
     * @description Returns the current user's instance of `LoggerSettings__c`
     * @return LoggerSettings__c - The current user's instance of the custom settings
     */
    // TODO make this method `global` in a future release
    public static LoggerSettings__c getUserSettings() {
        // Only load the current user's settings once - this allows the instance to be modified in memory (as well as upserted if any changes should be persisted)
        if (userSettings == null) {
            User currentUser = new User(Id = UserInfo.getUserId(), ProfileId = UserInfo.getProfileId());
            userSettings = getUserSettings(currentUser);
        }
        return userSettings;
    }

    /**
     * @description Returns the specified user's instance of `LoggerSettings__c`
     * @param loggingUser The user record - at a minimum, this record should have the user Id and Profile fields populated
     * @return LoggerSettings__c - The specified user's instance of the custom settings
     */
    // TODO make this method `global` in a future release
    public static LoggerSettings__c getUserSettings(User loggingUser) {
        // Typically, using LoggerSettings__c.getInstance() would be easier
        // However, some settings fields are expected to have null values, which conflicts with how `getInstance()` behaves
        // So, instead use LoggerSettings__c.getValues(Id userOrProfileId) to load exactly what's been configured (including nulls)

        LoggerSettings__c loggingUserSettings;
        if (loggingUser.Id != null && LoggerSettings__c.getValues(loggingUser.Id) != null) {
            // Check for User-level settings
            loggingUserSettings = LoggerSettings__c.getValues(loggingUser.Id);
        } else if (loggingUserSettings == null && loggingUser.ProfileId != null && LoggerSettings__c.getValues(loggingUser.ProfileId) != null) {
            // Next, check for Profile-level settings
            loggingUserSettings = LoggerSettings__c.getValues(loggingUser.ProfileId);
        } else if (LoggerSettings__c.getOrgDefaults().Id != null) {
            // Next, use the org defaults (if configured)
            loggingUserSettings = LoggerSettings__c.getOrgDefaults();
        } else {
            loggingUserSettings = (LoggerSettings__c) LoggerSettings__c.SObjectType.newSObject(null, true);
        }

        // If the settings were loaded from the org or profile level, clear the ID and make the user the SetupOwnerId (since the method is getUserSettings)
        // This allows the ability to then upsert the instance of LoggerSettings__c and it will always be specific to that user...
        // which avoids accidentally changing something at the org or profile levels
        if (loggingUser.Id != null && loggingUserSettings.SetupOwnerId != loggingUser.Id) {
            loggingUserSettings.Id = null;
            loggingUserSettings.SetupOwnerId = loggingUser.Id;
        }

        return loggingUserSettings;
    }

    // Transaction control methods

    /**
     * @description Indicates if saving has been temporarily suspended for the current transaction
     * @return Boolean
     */
    global static Boolean isSavingSuspended() {
        return suspendSaving;
    }

    /**
     * @description Pauses saving for the current transaction.
     *   Any calls to saveLog() are ignored until saving is resumed.
     */
    global static void suspendSaving() {
        suspendSaving = true;
    }

    /**
     * @description Resumes saving for the current transaction, used to reverse suspendSaving().
     *   Any calls to saveLog() are ignored until saving is resumed.
     */
    global static void resumeSaving() {
        suspendSaving = false;
    }

    /**
     * @description Returns the number of entries that have been generated but not yet saved
     * @return Integer
     */
    global static Integer getBufferSize() {
        return LOG_ENTRIES_BUFFER.size();
    }

    /**
     * @description Discards any entries that have been generated but not yet saved
     */
    global static void flushBuffer() {
        LOG_ENTRIES_BUFFER.clear();
    }

    // ERROR logging level methods
    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return error().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.MergeResult mergeResult) {
        return error().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.SaveResult saveResult) {
        return error().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return error().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return error().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return error().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return error().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return error().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return error().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return error().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Exception apexException) {
        return error().setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId, Exception apexException) {
        return error().setRecordId(recordId).setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId) {
        return error().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, SObject record, Exception apexException) {
        return error().setRecordId(record).setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, SObject record) {
        return error().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<SObject> records, Exception apexException) {
        return error().setRecord(records).setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage, List<SObject> records) {
        return error().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(LogMessage logMessage) {
        return error().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.DeleteResult deleteResult) {
        return error().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.MergeResult mergeResult) {
        return error().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.SaveResult saveResult) {
        return error().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.UndeleteResult undeleteResult) {
        return error().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Database.UpsertResult upsertResult) {
        return error().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.DeleteResult> deleteResults) {
        return error().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.MergeResult> mergeResults) {
        return error().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.SaveResult> saveResults) {
        return error().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.UndeleteResult> undeleteResults) {
        return error().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<Database.UpsertResult> upsertResults) {
        return error().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Exception apexException) {
        return error().setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Id recordId, Exception apexException) {
        return error().setRecordId(recordId).setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, Id recordId) {
        return error().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message       The string to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, SObject record, Exception apexException) {
        return error().setRecordId(record).setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, SObject record) {
        return error().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<SObject> records, Exception apexException) {
        return error().setRecord(records).setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message, List<SObject> records) {
        return error().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.ERROR`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder error(String message) {
        return error().setMessage(message);
    }

    // WARN logging level methods
    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return warn().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.MergeResult mergeResult) {
        return warn().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.SaveResult saveResult) {
        return warn().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return warn().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return warn().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return warn().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return warn().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return warn().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return warn().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return warn().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Exception apexException) {
        return warn().setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId, Exception apexException) {
        return warn().setRecordId(recordId).setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId) {
        return warn().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, SObject record, Exception apexException) {
        return warn().setRecordId(record).setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, SObject record) {
        return warn().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<SObject> records, Exception apexException) {
        return warn().setRecord(records).setExceptionDetails(apexException).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage, List<SObject> records) {
        return warn().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(LogMessage logMessage) {
        return warn().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.DeleteResult deleteResult) {
        return warn().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.MergeResult mergeResult) {
        return warn().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.SaveResult saveResult) {
        return warn().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.UndeleteResult undeleteResult) {
        return warn().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Database.UpsertResult upsertResult) {
        return warn().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.DeleteResult> deleteResults) {
        return warn().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.MergeResult> mergeResults) {
        return warn().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.SaveResult> saveResults) {
        return warn().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.UndeleteResult> undeleteResults) {
        return warn().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<Database.UpsertResult> upsertResults) {
        return warn().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Exception apexException) {
        return warn().setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  recordId      The record ID of an `SObject` to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Id recordId, Exception apexException) {
        return warn().setRecordId(recordId).setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, Id recordId) {
        return warn().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message       The string to use to set the entry's message field
     * @param  record        The `SObject` record to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, SObject record, Exception apexException) {
        return warn().setRecordId(record).setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, SObject record) {
        return warn().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message    The instance of `LogMessage` to use to set the entry's message field
     * @param  records       The list of `SObject` records to log
     * @param  apexException The instance of `Exception` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<SObject> records, Exception apexException) {
        return warn().setRecord(records).setExceptionDetails(apexException).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message, List<SObject> records) {
        return warn().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.WARN`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder warn(String message) {
        return warn().setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return info().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.MergeResult mergeResult) {
        return info().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.SaveResult saveResult) {
        return info().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return info().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return info().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return info().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return info().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return info().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return info().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return info().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, Id recordId) {
        return info().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, SObject record) {
        return info().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage, List<SObject> records) {
        return info().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(LogMessage logMessage) {
        return info().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.DeleteResult deleteResult) {
        return info().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.MergeResult mergeResult) {
        return info().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.SaveResult saveResult) {
        return info().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.UndeleteResult undeleteResult) {
        return info().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Database.UpsertResult upsertResult) {
        return info().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.DeleteResult> deleteResults) {
        return info().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.MergeResult> mergeResults) {
        return info().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.SaveResult> saveResults) {
        return info().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.UndeleteResult> undeleteResults) {
        return info().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<Database.UpsertResult> upsertResults) {
        return info().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, Id recordId) {
        return info().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, SObject record) {
        return info().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message, List<SObject> records) {
        return info().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.INFO`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder info(String message) {
        return info().setMessage(message);
    }

    // DEBUG log level methods
    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return debug().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.MergeResult mergeResult) {
        return debug().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.SaveResult saveResult) {
        return debug().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return debug().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return debug().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return debug().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return debug().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return debug().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return debug().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return debug().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, Id recordId) {
        return debug().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, SObject record) {
        return debug().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage, List<SObject> records) {
        return debug().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(LogMessage logMessage) {
        return debug().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.DeleteResult deleteResult) {
        return debug().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.MergeResult mergeResult) {
        return debug().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.SaveResult saveResult) {
        return debug().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.UndeleteResult undeleteResult) {
        return debug().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Database.UpsertResult upsertResult) {
        return debug().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.DeleteResult> deleteResults) {
        return debug().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.MergeResult> mergeResults) {
        return debug().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.SaveResult> saveResults) {
        return debug().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.UndeleteResult> undeleteResults) {
        return debug().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<Database.UpsertResult> upsertResults) {
        return debug().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, Id recordId) {
        return debug().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, SObject record) {
        return debug().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message, List<SObject> records) {
        return debug().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.DEBUG`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder debug(String message) {
        return debug().setMessage(message);
    }

    // FINE log level methods
    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return fine().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.MergeResult mergeResult) {
        return fine().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.SaveResult saveResult) {
        return fine().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return fine().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return fine().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return fine().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return fine().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return fine().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return fine().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return fine().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, Id recordId) {
        return fine().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, SObject record) {
        return fine().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage, List<SObject> records) {
        return fine().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(LogMessage logMessage) {
        return fine().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.DeleteResult deleteResult) {
        return fine().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.MergeResult mergeResult) {
        return fine().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.SaveResult saveResult) {
        return fine().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.UndeleteResult undeleteResult) {
        return fine().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Database.UpsertResult upsertResult) {
        return fine().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.DeleteResult> deleteResults) {
        return fine().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.MergeResult> mergeResults) {
        return fine().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.SaveResult> saveResults) {
        return fine().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.UndeleteResult> undeleteResults) {
        return fine().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<Database.UpsertResult> upsertResults) {
        return fine().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, Id recordId) {
        return fine().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, SObject record) {
        return fine().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message, List<SObject> records) {
        return fine().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINE`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder fine(String message) {
        return fine().setMessage(message);
    }

    // FINER log level methods
    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return finer().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.MergeResult mergeResult) {
        return finer().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.SaveResult saveResult) {
        return finer().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return finer().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return finer().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return finer().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return finer().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return finer().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return finer().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return finer().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, Id recordId) {
        return finer().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, SObject record) {
        return finer().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage, List<SObject> records) {
        return finer().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(LogMessage logMessage) {
        return finer().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.DeleteResult deleteResult) {
        return finer().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.MergeResult mergeResult) {
        return finer().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.SaveResult saveResult) {
        return finer().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.UndeleteResult undeleteResult) {
        return finer().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Database.UpsertResult upsertResult) {
        return finer().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.DeleteResult> deleteResults) {
        return finer().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.MergeResult> mergeResults) {
        return finer().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.SaveResult> saveResults) {
        return finer().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.UndeleteResult> undeleteResults) {
        return finer().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<Database.UpsertResult> upsertResults) {
        return finer().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, Id recordId) {
        return finer().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, SObject record) {
        return finer().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message, List<SObject> records) {
        return finer().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINER`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finer(String message) {
        return finer().setMessage(message);
    }

    // FINEST log level methods
    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.DeleteResult deleteResult) {
        return finest().setDatabaseResult(deleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.MergeResult mergeResult) {
        return finest().setDatabaseResult(mergeResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.SaveResult saveResult) {
        return finest().setDatabaseResult(saveResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage     The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.UndeleteResult undeleteResult) {
        return finest().setDatabaseResult(undeleteResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Database.UpsertResult upsertResult) {
        return finest().setDatabaseResult(upsertResult).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        return finest().setDatabaseResult(deleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        return finest().setDatabaseResult(mergeResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage  The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults The instance of `List<Database.SaveResult>` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.SaveResult> saveResults) {
        return finest().setDatabaseResult(saveResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        return finest().setDatabaseResult(undeleteResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        return finest().setDatabaseResult(upsertResults).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  recordId   The record ID of an `SObject` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, Id recordId) {
        return finest().setRecordId(recordId).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  record     The `SObject` record to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, SObject record) {
        return finest().setRecordId(record).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @param  records    The list of `SObject` records to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage, List<SObject> records) {
        return finest().setRecord(records).setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(LogMessage logMessage) {
        return finest().setMessage(logMessage);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message   The string to use to set the entry's message field
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.DeleteResult deleteResult) {
        return finest().setDatabaseResult(deleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message     The string to use to set the entry's message field
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.MergeResult mergeResult) {
        return finest().setDatabaseResult(mergeResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message    The string to use to set the entry's message field
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.SaveResult saveResult) {
        return finest().setDatabaseResult(saveResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message        The string to use to set the entry's message field
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.UndeleteResult undeleteResult) {
        return finest().setDatabaseResult(undeleteResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message      The string to use to set the entry's message field
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Database.UpsertResult upsertResult) {
        return finest().setDatabaseResult(upsertResult).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.DeleteResult> deleteResults) {
        return finest().setDatabaseResult(deleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.MergeResult> mergeResults) {
        return finest().setDatabaseResult(mergeResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message     The string to use to set the entry's message field
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.SaveResult> saveResults) {
        return finest().setDatabaseResult(saveResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.UndeleteResult> undeleteResults) {
        return finest().setDatabaseResult(undeleteResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<Database.UpsertResult> upsertResults) {
        return finest().setDatabaseResult(upsertResults).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message  The string to use to set the entry's message field
     * @param  recordId The record ID of an `SObject` to log
     * @return          The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, Id recordId) {
        return finest().setRecordId(recordId).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message The string to use to set the entry's message field
     * @param  record  The `SObject` record to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, SObject record) {
        return finest().setRecordId(record).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message The string to use to set the entry's message field
     * @param  records The list of `SObject` records to log
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message, List<SObject> records) {
        return finest().setRecord(records).setMessage(message);
    }

    /**
     * @description Creates a new log entry with logging level == `LoggingLevel.FINEST`
     * @param  message The string to use to set the entry's message field
     * @return         The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global static LogEntryEventBuilder finest(String message) {
        return finest().setMessage(message);
    }

    /**
     * @description Creates a log entry for any results within the provided `List<DeleteResult>` where `isSuccess() != true`
     * @param  loggingLevel  The logging level to use for the log entry
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(LoggingLevel loggingLevel, LogMessage logMessage, List<Database.DeleteResult> deleteResults) {
        if (isEnabled(loggingLevel) == false) {
            return null;
        } else {
            return logDatabaseErrors(loggingLevel, logMessage.getMessage(), deleteResults);
        }
    }

    /**
     * @description Creates a log entry for any results within the provided `List<DeleteResult>` where `isSuccess() != true`
     * @param  loggingLevel  The logging level to use for the log entry
     * @param  message       The string to use to set the entry's message field
     * @param  deleteResults The instance of `List<Database.DeleteResult>` to log
     * @return               The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(LoggingLevel loggingLevel, String message, List<Database.DeleteResult> deleteResults) {
        if (isEnabled(loggingLevel) == false) {
            return null;
        }

        List<Database.DeleteResult> resultsToLog = new List<Database.DeleteResult>();
        for (Database.DeleteResult deleteResult : deleteResults) {
            if (deleteResult.isSuccess() == false) {
                resultsToLog.add(deleteResult);
            }
        }

        LogEntryEventBuilder logEntryEventBuilder;
        if (resultsToLog.isEmpty() == false) {
            logEntryEventBuilder = newEntry(loggingLevel, message).setDatabaseResult(resultsToLog);
        }
        return logEntryEventBuilder;
    }

    /**
     * @description Creates a log entry for any results within the provided `List<MergeResult>` where `isSuccess() != true`
     * @param  loggingLevel The logging level to use for the log entry
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(LoggingLevel loggingLevel, LogMessage logMessage, List<Database.MergeResult> mergeResults) {
        if (isEnabled(loggingLevel) == false) {
            return null;
        } else {
            return logDatabaseErrors(loggingLevel, logMessage.getMessage(), mergeResults);
        }
    }

    /**
     * @description Creates a log entry for any results within the provided `List<MergeResult>` where `isSuccess() != true`
     * @param  loggingLevel The logging level to use for the log entry
     * @param  message      The string to use to set the entry's message field
     * @param  mergeResults The instance of `List<Database.MergeResult>` to log
     * @return              The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(LoggingLevel loggingLevel, String message, List<Database.MergeResult> mergeResults) {
        if (isEnabled(loggingLevel) == false) {
            return null;
        }

        List<Database.MergeResult> resultsToLog = new List<Database.MergeResult>();
        for (Database.MergeResult mergeResult : mergeResults) {
            if (mergeResult.isSuccess() == false) {
                resultsToLog.add(mergeResult);
            }
        }

        LogEntryEventBuilder logEntryEventBuilder;
        if (resultsToLog.isEmpty() == false) {
            logEntryEventBuilder = newEntry(loggingLevel, message).setDatabaseResult(resultsToLog);
        }
        return logEntryEventBuilder;
    }

    /**
     * @description Creates a log entry for any results within the provided `List<SaveResult>` where `isSuccess() != true`
     * @param  loggingLevel The logging level to use for the log entry
     * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
     * @param  saveResults  The instance of `List<Database.SaveResult>` to log
     * @return              The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(LoggingLevel loggingLevel, LogMessage logMessage, List<Database.SaveResult> saveResults) {
        if (isEnabled(loggingLevel) == false) {
            return null;
        } else {
            return logDatabaseErrors(loggingLevel, logMessage.getMessage(), saveResults);
        }
    }

    /**
     * @description Creates a log entry for any results within the provided `List<SaveResult>` where `isSuccess() != true`
     * @param  loggingLevel The logging level to use for the log entry
     * @param  message      The string to use to set the entry's message field
     * @param  saveResults  The instance of `List<Database.SaveResult>` to log
     * @return              The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(LoggingLevel loggingLevel, String message, List<Database.SaveResult> saveResults) {
        if (isEnabled(loggingLevel) == false) {
            return null;
        }

        List<Database.SaveResult> resultsToLog = new List<Database.SaveResult>();
        for (Database.SaveResult saveResult : saveResults) {
            if (saveResult.isSuccess() == false) {
                resultsToLog.add(saveResult);
            }
        }

        LogEntryEventBuilder logEntryEventBuilder;
        if (resultsToLog.isEmpty() == false) {
            logEntryEventBuilder = newEntry(loggingLevel, message).setDatabaseResult(resultsToLog);
        }
        return logEntryEventBuilder;
    }

    /**
     * @description Creates a log entry for any results within the provided `List<UpsertResult>` where `isSuccess() != true`
     * @param  loggingLevel  The logging level to use for the log entry
     * @param  logMessage    The instance of `LogMessage` to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(LoggingLevel loggingLevel, LogMessage logMessage, List<Database.UpsertResult> upsertResults) {
        if (isEnabled(loggingLevel) == false) {
            return null;
        } else {
            return logDatabaseErrors(loggingLevel, logMessage.getMessage(), upsertResults);
        }
    }

    /**
     * @description Creates a log entry for any results within the provided `List<UpsertResult>` where `isSuccess() != true`
     * @param  loggingLevel  The logging level to use for the log entry
     * @param  message       The string to use to set the entry's message field
     * @param  upsertResults The instance of `List<Database.UpsertResult>` to log
     * @return               The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(LoggingLevel loggingLevel, String message, List<Database.UpsertResult> upsertResults) {
        if (isEnabled(loggingLevel) == false) {
            return null;
        }

        List<Database.UpsertResult> resultsToLog = new List<Database.UpsertResult>();
        for (Database.UpsertResult upsertResult : upsertResults) {
            if (upsertResult.isSuccess() == false) {
                resultsToLog.add(upsertResult);
            }
        }

        LogEntryEventBuilder logEntryEventBuilder;
        if (resultsToLog.isEmpty() == false) {
            logEntryEventBuilder = newEntry(loggingLevel, message).setDatabaseResult(resultsToLog);
        }
        return logEntryEventBuilder;
    }

    /**
     * @description Creates a log entry for any results within the provided `List<UndeleteResult>` where `isSuccess() != true`
     * @param  loggingLevel    The logging level to use for the log entry
     * @param  logMessage      The instance of `LogMessage` to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(LoggingLevel loggingLevel, LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
        if (isEnabled(loggingLevel) == false) {
            return null;
        } else {
            return logDatabaseErrors(loggingLevel, logMessage.getMessage(), undeleteResults);
        }
    }

    /**
     * @description Creates a log entry for any results within the provided `List<UndeleteResult>` where `isSuccess() != true`
     * @param  loggingLevel    The logging level to use for the log entry
     * @param  message         The string to use to set the entry's message field
     * @param  undeleteResults The instance of `List<Database.UndeleteResult>` to log
     * @return                 The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
     */
    global static LogEntryEventBuilder logDatabaseErrors(LoggingLevel loggingLevel, String message, List<Database.UndeleteResult> undeleteResults) {
        if (isEnabled(loggingLevel) == false) {
            return null;
        }

        List<Database.UndeleteResult> resultsToLog = new List<Database.UndeleteResult>();
        for (Database.UndeleteResult undeleteResult : undeleteResults) {
            if (undeleteResult.isSuccess() == false) {
                resultsToLog.add(undeleteResult);
            }
        }

        LogEntryEventBuilder logEntryEventBuilder;
        if (resultsToLog.isEmpty() == false) {
            logEntryEventBuilder = newEntry(loggingLevel, message).setDatabaseResult(resultsToLog);
        }
        return logEntryEventBuilder;
    }

    /**
     * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if shouldSave == true
     * @param  loggingLevel The logging level enum value for the new entry
     * @param  logMessage   The instance of LogMessage to use as the entry's message
     * @param  shouldSave   Controls if the new entry will be saved. This can be used to save entries, even if the entry's logging level does not meet the user's logging level
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, LogMessage logMessage, Boolean shouldSave) {
        return newEntry(loggingLevel, shouldSave).setMessage(logMessage);
    }

    /**
     * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
     * @param  loggingLevel The logging level enum value for the new entry
     * @param  logMessage   The instance of LogMessage to use as the entry's message
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, LogMessage logMessage) {
        return newEntry(loggingLevel).setMessage(logMessage);
    }

    /**
     * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
     * @param  loggingLevel The logging level enum value for the new entry
     * @param  message      The string to use as the entry's message
     * @param  shouldSave   Controls if the new entry will be saved. This can be used to save entries, even if the entry's logging level does not meet the user's logging level
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, String message, Boolean shouldSave) {
        return newEntry(loggingLevel, shouldSave).setMessage(message);
    }

    /**
     * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
     * @param  loggingLevel The logging level enum value for the new entry
     * @param  message      The string to use as the entry's message
     * @return              The new entry's instance of LogEntryEventBuilder
     */
    global static LogEntryEventBuilder newEntry(LoggingLevel loggingLevel, String message) {
        return newEntry(loggingLevel).setMessage(message);
    }

    // Save control methods
    /**
     * @description Returns the scenario name for the current transaction - this is stored in `LogEntryEvent__e.Scenario__c`
     *              and `Log__c.Scenario__c`, and can be used to filter & group logs
     * @return   The value currently set as the current transaction's scenario
     */
    global static String getScenario() {
        return transactionScenario;
    }

    /**
     * @description Sets the scenario name for the current transaction - this is stored in `LogEntryEvent__e.Scenario__c`
     *              and `Log__c.Scenario__c`, and can be used to filter & group logs
     * @param  scenario The name to use for the current transaction's scenario
     */
    global static void setScenario(String scenario) {
        if (USE_FIRST_SPECIFIED_SCENARIO == true && String.isNotBlank(transactionScenario) == true) {
            return;
        }

        transactionScenario = scenario;

        LogScenarioRule__mdt matchingScenarioRule;
        for (LogScenarioRule__mdt scenarioRule : LogScenarioRule__mdt.getAll().values()) {
            if (scenarioRule.IsEnabled__c = true && scenarioRule.Scenario__c == scenario) {
                matchingScenarioRule = scenarioRule;
                break;
            }
        }

        if (System.Test.isRunningTest() == true) {
            matchingScenarioRule = MOCK_SCENARIO_TO_SCENARIO_RULE.get(scenario);
        }

        if (matchingScenarioRule != null) {
            getUserSettings().LoggingLevel__c = matchingScenarioRule.UserLoggingLevel__c;
        }
    }

    @TestVisible
    private static void setMockScenarioRule(LogScenarioRule__mdt scenarioRule) {
        MOCK_SCENARIO_TO_SCENARIO_RULE.put(scenarioRule.Scenario__c, scenarioRule);
    }

    /**
     * @description Returns the default save method used when calling saveLog() - set via LoggerSettings__c or by calling setSaveMethod(SaveMethod saveMethod)
     * @return   The enum value of Logger.SaveMethod to use for any calls to saveLog() in the current transaction
     */
    global static SaveMethod getSaveMethod() {
        return getSaveMethod(transactionSaveMethodName);
    }

    /**
     * @description Sets the default save method used when calling saveLog() - any subsequent calls to saveLog() will use the specified save method
     * @param  saveMethod The enum value of Logger.SaveMethod to use for any other calls to saveLog() in the current transaction
     */
    global static void setSaveMethod(SaveMethod saveMethod) {
        transactionSaveMethodName = saveMethod.name();
    }

    /**
     * @description Saves any entries in Logger's buffer. By default, entries are saved via Apex's EventBus and can be overridden with setSaveMethod(SaveMethod saveMethod)
     */
    @InvocableMethod(category='Logging' label='Save Log' description='Saves any log entries that have been generated')
    global static void saveLog() {
        saveLog(transactionSaveMethodName);
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
     * @description Saves any entries in Logger's buffer, using the specified save method for only this call.
     *   All subsequent calls to saveLog() will use the transaction save method.
     * @param  saveMethodName The String value of the save method to use for this specific save action.
     */
    @SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount')
    public static void saveLog(String saveMethodName) {
        saveLogCallCount++;
        lastSaveMethodNameUsed = saveMethodName;
        if (LOG_ENTRIES_BUFFER.isEmpty() || getUserSettings().IsSavingEnabled__c == false) {
            return;
        }

        if (suspendSaving == true) {
            if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == true) {
                finest(getSuspendSavingLogSystemMessage());
            }

            return;
        }

        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == true) {
            finest(getSavingLogSystemMessage(saveMethodName));
        }

        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
        for (LogEntryEventBuilder logEntryEventBuilder : LOG_ENTRIES_BUFFER) {
            if (logEntryEventBuilder.shouldSave()) {
                LogEntryEvent__e logEntryEvent = logEntryEventBuilder.getLogEntryEvent();
                logEntryEvent.ParentLogTransactionId__c = getParentLogTransactionId();
                logEntryEvent.Scenario__c = transactionScenario;
                logEntryEvent.SystemMode__c = getCurrentQuiddity()?.name();
                logEntryEvent.TransactionId__c = getTransactionId();

                logEntryEvents.add(logEntryEvent);
            }
        }

        // Platform events don't support BEFORE_INSERT operations (only AFTER_INSERT is supported),
        // but here we are, getting ready to insert the records, but we haven't.... yet
        // It's... it's... almost like... this part of the code IS a BEFORE_INSERT context. Huzzah!
        // This gives us a chance to run the handler class & handler plugins before insert,
        // allowing the plugins to make further changes to the `LogEntryEvent__e` records
        // So, execute the handler, which internally then executes any plugins
        LoggerTriggerableContext logEntryEventsBeforeContext = new LoggerTriggerableContext(
            Schema.LogEntryEvent__e.SObjectType,
            TriggerOperation.BEFORE_INSERT,
            logEntryEvents
        );
        LoggerSObjectHandler.getHandler(Schema.LogEntryEvent__e.SObjectType)?.overrideTriggerableContext(logEntryEventsBeforeContext).execute();

        // Now that the plugins have run, double check to make sure that saving should still happen
        if (getBufferSize() == 0) {
            return;
        }

        switch on getSaveMethod(saveMethodName) {
            when EVENT_BUS {
                List<Database.SaveResult> saveResults = LoggerDataStore.getEventBus().publishRecords(logEntryEvents);
                LoggerEmailSender.sendErrorEmail(Schema.LogEntryEvent__e.SObjectType, saveResults);
            }
            when QUEUEABLE {
                LoggerDataStore.getJobQueue().enqueueJob(new QueueableSaver(logEntryEvents));
            }
            when REST {
                // If the user doesn't have a session ID (e.g., site guest user), the REST API call will fail
                // To avoid that, use the EventBus instead (even though REST was specified)
                if (String.isBlank(UserInfo.getSessionId())) {
                    saveLog(Logger.SaveMethod.EVENT_BUS);
                } else {
                    new RestApiSaver().insertRecords(logEntryEvents);
                }
            }
            when SYNCHRONOUS_DML {
                LoggerTriggerableContext logEntryEventsAfterContext = new LoggerTriggerableContext(
                    Schema.LogEntryEvent__e.SObjectType,
                    TriggerOperation.AFTER_INSERT,
                    logEntryEvents
                );
                LoggerSObjectHandler.getHandler(Schema.LogEntryEvent__e.SObjectType)?.overrideTriggerableContext(logEntryEventsAfterContext).execute();
            }
        }

        flushBuffer();
    }

    // Utility methods

    /**
     * @description Converts a String to an instance of LoggingLevel
     * @param  loggingLevelName The string name of an Apex logging level
     * @return                  The matching instance of LoggingLevel (or a default value if a match is not found)
     */
    global static LoggingLevel getLoggingLevel(String loggingLevelName) {
        try {
            return System.LoggingLevel.valueOf(loggingLevelName?.trim().toUpperCase());
        } catch (NoSuchElementException ex) {
            if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == true) {
                LogMessage logMessage = new LogMessage(
                    'Logger - Unknown logging level {0} specified, using {1}',
                    loggingLevelName,
                    DEFAULT_LOGGING_LEVEL.name()
                );
                finest(logMessage);
            }
            return DEFAULT_LOGGING_LEVEL;
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
        if (logEntryEventBuilder.shouldSave() == true) {
            logEntryEventBuilder.getLogEntryEvent().LoggerVersionNumber__c = CURRENT_VERSION_NUMBER;
            logEntryEventBuilder.getLogEntryEvent().TransactionEntryNumber__c = currentTransactionEntryNumber++;
            LOG_ENTRIES_BUFFER.add(logEntryEventBuilder);
        }

        return logEntryEventBuilder;
    }

    private static Quiddity setTransactionQuiddity() {
        // An error can sometimes occur when calling System.Request.getCurrent(), such as when logging
        // from an Auth Provider class (that implements Auth.RegistrationHandler). As a workaround,
        // skip calling System.Request.getCurrent() if there is no user session.
        // TODO: see if there is a better approach for this long term (or hopefully Salesforce fixes the gack error)
        if (String.isNotBlank(UserInfo.getSessionId())) {
            return System.Request.getCurrent().getQuiddity();
        } else {
            return null;
        }
    }

    private static SaveMethod getSaveMethod(String saveMethodName) {
        try {
            return SaveMethod.valueOf(saveMethodName);
        } catch (NoSuchElementException ex) {
            return null;
        }
    }

    private static String getSuspendSavingLogSystemMessage() {
        return 'Logger - Logging suspended, ignoring call to saveLog()';
    }

    private static String getSavingLogSystemMessage(String saveMethodName) {
        String savingLogMessage = 'Logger - Saving ' + LOG_ENTRIES_BUFFER.size() + ' log entries via ';
        switch on getCurrentQuiddity() {
            when ANONYMOUS {
                savingLogMessage += 'Anonymous Apex';
            }
            when AURA, VF {
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
            when null {
                savingLogMessage += 'unknown context';
            }
            when else {
                savingLogMessage += getCurrentQuiddity()?.name();
            }
        }
        savingLogMessage += ', save method is ' + saveMethodName;
        savingLogMessage +=
            '. Logger.saveLog() has been called ' +
            saveLogCallCount +
            (saveLogCallCount == 1 ? ' time' : ' times') +
            ' in the current transaction.';

        return savingLogMessage;
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
            LoggerDataStore.getEventBus().publishRecords(this.logEntryEvents);
        }
    }

    // Inner class for saving log entries via the REST API (using the current user's session ID)
    private class RestApiSaver {
        private final String baseURL = System.Url.getSalesforceBaseUrl().toExternalForm() + '/services/data/v53.0';
        private final String compositeEndpoint = '/composite/sobjects';

        @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
        /**
         * @description Inserts records via the REST api.
         * @param records The records to save.
         */
        public void insertRecords(List<SObject> records) {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(baseURL + compositeEndpoint);
            request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            request.setHeader('Content-Type', 'application/json; charset=utf-8');
            request.setMethod('POST');

            Boolean allOrNone = true;
            RestSaveRequest saveRequest = new RestSaveRequest(records, allOrNone);
            request.setBody(JSON.serialize(saveRequest));

            HttpResponse response = new Http().send(request);
            this.validateResponse(response);
        }

        private void validateResponse(Httpresponse response) {
            Integer statusCode = response.getStatusCode();
            if (statusCode >= 400) {
                String errorMessage = 'Saving via REST API failed. Received request status code ' + statusCode + ', status message: ' + response.getStatus();
                throw new CalloutException(errorMessage);
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

    /******************************************************************************************
     * This code is based on the Apex UUID project, released under the MIT License.            *
     * See LICENSE file or go to https://github.com/jongpie/ApexUuid for full license details. *
     * @description private, inner class for UUID. See comment for more information.           *
     ******************************************************************************************/
    @TestVisible
    private without sharing class Uuid {
        private final String hexCharacters = '0123456789abcdef';
        private final String hexPrefix = '0x';
        private final List<String> hexCharacterList = hexCharacters.split('');
        private final Integer uuidV4Length = 36;
        private final String uuidV4Regex = '[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}';

        private final String value;

        /**
         * @description Default constructor
         */
        public Uuid() {
            this.value = this.generateValue();
        }

        /**
         * @description Getter returning the uuid value
         * @return A string containing the UUID value.
         */
        public String getValue() {
            return this.value;
        }

        private String generateValue() {
            String hexValue = EncodingUtil.convertToHex(Crypto.generateAesKey(128));

            // Version Calculation: (i & 0x0f) | 0x40
            // Version Format: Always begins with 4
            String versionShiftedHexBits = this.getShiftedHexBits(
                hexValue.substring(14, 16),
                this.convertHexToInteger('0x0f'),
                this.convertHexToInteger('0x40')
            );

            // Variant Calculation: (i & 0x3f) | 0x80
            // Variant Format: Always begins with 8, 9, A or B
            String variantShiftedHexBits = this.getShiftedHexBits(
                hexValue.substring(18, 20),
                this.convertHexToInteger('0x3f'),
                this.convertHexToInteger('0x80')
            );

            String uuidValue =
                hexValue.substring(0, 8) + // time-low
                hexValue.substring(8, 12) + // time-mid
                versionShiftedHexBits +
                hexValue.substring(14, 16) + // time-high-and-version
                variantShiftedHexBits +
                hexValue.substring(18, 20) + // clock-seq-and-reserved + clock-seq-low
                hexValue.substring(20); // node

            return formatValue(uuidValue);
        }

        private String formatValue(String unformattedValue) {
            // Remove any non-alphanumeric characters
            unformattedValue = unformattedValue.replaceAll('[^a-zA-Z0-9]', '');

            // UUID Pattern: 8-4-4-4-12
            String formattedValue =
                unformattedValue.substring(0, 8) +
                '-' +
                unformattedValue.substring(8, 12) +
                '-' +
                unformattedValue.substring(12, 16) +
                '-' +
                unformattedValue.substring(16, 20) +
                '-' +
                unformattedValue.substring(20);

            return formattedValue.toLowerCase();
        }

        private String getShiftedHexBits(String hexSubstring, Integer lowerThreshold, Integer upperThreshold) {
            Integer shiftedIntegerBits = (this.convertHexToInteger(hexSubstring) & lowerThreshold) | upperThreshold;
            return this.convertIntegerToHex(shiftedIntegerBits);
        }

        private Integer convertHexToInteger(String hexValue) {
            hexValue = hexValue.toLowerCase();

            if (hexValue.startsWith(hexPrefix)) {
                hexValue = hexValue.substringAfter(hexPrefix);
            }

            Integer integerValue = 0;
            for (String hexCharacter : hexValue.split('')) {
                Integer hexCharacterIndex = hexCharacters.indexOf(hexCharacter);

                integerValue = hexCharacters.length() * integerValue + hexCharacterIndex;
            }
            return integerValue;
        }

        private String convertIntegerToHex(Integer integerValue) {
            String hexValue = '';
            while (integerValue > 0) {
                Integer hexCharacterIndex = Math.mod(integerValue, hexCharacters.length());

                hexValue = hexCharacterList[hexCharacterIndex] + hexValue;
                integerValue = integerValue / hexCharacters.length();
            }
            return hexValue;
        }
    }
}
