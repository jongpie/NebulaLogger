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
  'PMD.AvoidDebugStatements, PMD.AvoidGlobalModifier, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveClassLength, PMD.ExcessivePublicCount, PMD.NcssTypeCount, PMD.PropertyNamingConventions, PMD.StdCyclomaticComplexity'
)
global with sharing class Logger {
  // There's no reliable way to get the version number dynamically in Apex
  @TestVisible
  private static final String CURRENT_VERSION_NUMBER = 'v4.16.5';
  private static final System.LoggingLevel FALLBACK_LOGGING_LEVEL = System.LoggingLevel.DEBUG;
  private static final List<LogEntryEventBuilder> LOG_ENTRIES_BUFFER = new List<LogEntryEventBuilder>();
  private static final String MISSING_SCENARIO_ERROR_MESSAGE = 'No logger scenario specified. A scenario is required for logging in this org.';
  private static final String ORGANIZATION_DOMAIN_URL = System.URL.getOrgDomainUrl()?.toExternalForm();
  private static final String REQUEST_ID = System.Request.getCurrent().getRequestId();
  private static final Map<String, SaveMethod> SAVE_METHOD_NAME_TO_SAVE_METHOD = new Map<String, SaveMethod>();
  private static final Map<Schema.SObjectField, Object> TRANSACTION_FIELD_TO_VALUE = new Map<Schema.SObjectField, Object>();
  private static final String TRANSACTION_ID = System.UUID.randomUUID().toString();

  private static AsyncContext currentAsyncContext;
  private static String currentEntryScenario;
  private static LoggerSettings__c currentUserSettings;
  @TestVisible
  private static String lastSaveMethodNameUsed;
  private static List<String> orderedScenarios = new List<String>();
  private static String parentLogTransactionId;
  @TestVisible
  private static Integer saveLogCallCount = 0;
  private static Boolean suspendSaving = false;
  @TestVisible
  private static System.Quiddity transactionQuiddity = loadTransactionQuiddity();
  private static String transactionScenario;

  private static final List<String> CLASSES_TO_IGNORE {
    get {
      if (CLASSES_TO_IGNORE == null) {
        CLASSES_TO_IGNORE = new List<String>{
          'Class.' + Logger.class.getName(),
          'Class.' + LogEntryEventBuilder.class.getName(),
          'Class.' + LogMessage.class.getName()
        };
      }
      return CLASSES_TO_IGNORE;
    }
    set;
  }

  private static final LogEntryEventBuilder.LoggingContext LOGGING_CONTEXT {
    get {
      if (LOGGING_CONTEXT == null) {
        LOGGING_CONTEXT = new LogEntryEventBuilder.LoggingContext(
          getVersionNumber(),
          getOrganizationApiVersion(),
          ORGANIZATION_DOMAIN_URL,
          REQUEST_ID,
          getCurrentQuiddity(),
          getTransactionId()
        );
      }
      return LOGGING_CONTEXT;
    }
    set;
  }

  private static final String ORGANIZATION_API_VERSION {
    get {
      if (ORGANIZATION_API_VERSION == null) {
        // Small hack to determine the org's current API version (since Apex doesn't natively provide it)
        // Serializing any SObject w/ an ID will include the API version
        // So, use System.UserInfo.getUserId() to create the current user's record without querying
        // Then parse the JSON to get the API version
        // Expected JSON: {"attributes":{"type":"Schema.User","url":"/services/data/v53.0/sobjects/Schema.User/005J000000AugnYIAR"}
        String userJson = System.JSON.serialize(new Schema.User(Id = System.UserInfo.getUserId()));
        ORGANIZATION_API_VERSION = userJson.substringAfter('/data/').substringBefore('/sobjects/User');
      }
      return ORGANIZATION_API_VERSION;
    }
    set;
  }

  private static final String USER_SESSION_ID {
    get {
      if (USER_SESSION_ID == null) {
        // TODO Spring '24 release - simplify this (and other lazy-loaded values)
        // by switching to the fancy, new ?? null coalescing operator
        try {
          USER_SESSION_ID = System.UserInfo.getSessionId();
        } catch (Exception ex) {
          USER_SESSION_ID = '';
        }
        // If System.UserInfo.getSessionId() returns null, set to an empty string to
        // avoid calling System.UserInfo.getSessionId() again
        USER_SESSION_ID = USER_SESSION_ID ?? '';
      }
      return USER_SESSION_ID;
    }
    set;
  }

  private static String transactionSaveMethodName {
    get {
      if (transactionSaveMethodName == null) {
        transactionSaveMethodName = getUserSettings().DefaultSaveMethod__c;
      }
      return transactionSaveMethodName;
    }
    set;
  }

  private static System.LoggingLevel userLoggingLevel {
    get {
      if (userLoggingLevel == null || userLoggingLevel.name() != getUserSettings().LoggingLevel__c) {
        userLoggingLevel = getLoggingLevel(getUserSettings().LoggingLevel__c);
      }
      return userLoggingLevel;
    }
    set;
  }

  static {
    // One of a few limited places in the codebase (except tests) that should use System.debug()
    // The rest of the codebase should use a method in Logger.cls
    System.debug(System.LoggingLevel.INFO, 'Nebula Logger - Version Number: ' + getVersionNumber());
    System.debug(System.LoggingLevel.INFO, 'Nebula Logger - Transaction ID: ' + getTransactionId());
    System.debug(System.LoggingLevel.INFO, 'Nebula Logger - Request ID: ' + REQUEST_ID);
    System.debug(System.LoggingLevel.INFO, 'Nebula Logger - Organization API Version: ' + getOrganizationApiVersion());
    setScenario(getUserSettings().DefaultScenario__c);
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
    return CURRENT_VERSION_NUMBER;
  }

  // TODO delete
  /**
   * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
   *              Returns the current namespace of Nebula Logger
   * @return      The current namespace prefix, or an empty string when no namespace is being used
   */
  public static String getNamespacePrefix() {
    String className = Logger.class.getName();
    return className.contains('.') ? className.substringBefore('.') : '';
  }

  /**
   * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
   *              Returns the current Salesforce API version number of the org
   * @return      The current API version, in the format `v00.0`
   */
  public static String getOrganizationApiVersion() {
    return ORGANIZATION_API_VERSION;
  }

  // Settings management methods

  /**
   * @description Returns the request ID generated by Salesforce for a particular transaction.
   *      This value is stored in `LogEntryEvent__e.RequestId__c` and `Log__c.RequestId__c`.
   * @return String - The value returned by `System.Request.getCurrent().getRequestId()`
   */
  // TODO decide if this should be made `global` in a future release
  public static String getRequestId() {
    return REQUEST_ID;
  }

  /**
   * @description Returns the unique ID generated by Nebula Logger for a particular transaction.
   *              This value is stored in `LogEntryEvent__e.TransactionId__c` and `Log__c.TransactionId__c`.
   * @return String - A `UUID` value generated by Nebula Logger, using `System.UUID.randomUUID().toString()`
   */
  global static String getTransactionId() {
    return TRANSACTION_ID;
  }

  /**
   * @description Returns the System.Quiddity context of the current transaction.
   * @return System.Quiddity - The value of System.Request.getCurrent().getQuiddity()
   */
  global static System.Quiddity getCurrentQuiddity() {
    return transactionQuiddity;
  }

  /**
   * @description Stores additional details about the current transacation's async context
   * @param  batchableContext - The instance of `Database.BatchableContext` to track
   */
  global static void setAsyncContext(Database.BatchableContext batchableContext) {
    if (batchableContext != null) {
      setAsyncContext(new AsyncContext(batchableContext));
    }
  }

  /**
   * @description Stores additional details about the current transacation's async context
   * @param  finalizerContext - The instance of `System.FinalizerContext` to track
   */
  global static void setAsyncContext(System.FinalizerContext finalizerContext) {
    if (finalizerContext != null) {
      setAsyncContext(new AsyncContext(finalizerContext));
    }
  }

  /**
   * @description Stores additional details about the current transacation's async context
   * @param  queueableContext - The instance of `System.QueueableContext` to track
   */
  global static void setAsyncContext(System.QueueableContext queueableContext) {
    if (queueableContext != null) {
      setAsyncContext(new AsyncContext(queueableContext));
    }
  }

  /**
   * @description Stores additional details about the current transacation's async context
   * @param  schedulableContext - The instance of `System.SchedulableContext` to track
   */
  global static void setAsyncContext(System.SchedulableContext schedulableContext) {
    if (schedulableContext != null) {
      setAsyncContext(new AsyncContext(schedulableContext));
    }
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
   * @description Sets a field value on every generated `LogEntryEvent__e` record
   * @param  field      The `Schema.SObjectField` token of the field to populate
   *                    on each `LogEntryEvent__e` record in the current transaction
   * @param  fieldValue The `Object` value to populate in the provided field
   */
  global static void setField(Schema.SObjectField field, Object fieldValue) {
    setField(new Map<Schema.SObjectField, Object>{ field => fieldValue });
  }

  /**
   * @description Sets multiple field values oon every generated `LogEntryEvent__e` record
   * @param  fieldToValue An instance of `Map<Schema.SObjectField, Object>` containing the
   *                      the fields & values to populate on each `LogEntryEvent__e` record in the current transaction
   */
  global static void setField(Map<Schema.SObjectField, Object> fieldToValue) {
    if (getUserSettings().IsEnabled__c == false) {
      return;
    }

    TRANSACTION_FIELD_TO_VALUE.putAll(fieldToValue);
    TRANSACTION_FIELD_TO_VALUE.remove(null);
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
  global static Boolean isEnabled(System.LoggingLevel loggingLevel) {
    return isEnabled() && meetsUserLoggingLevel(loggingLevel);
  }

  /**
   * @description Indicates if logging level 'ERROR' is enabled for the current user, based on the custom setting LoggerSettings__c
   * @return Boolean
   */
  global static Boolean isErrorEnabled() {
    return isEnabled(System.LoggingLevel.ERROR);
  }

  /**
   * @description Indicates if logging level 'WARN' is enabled for the current user, based on the custom setting LoggerSettings__c
   * @return Boolean
   */
  global static Boolean isWarnEnabled() {
    return isEnabled(System.LoggingLevel.WARN);
  }

  /**
   * @description Indicates if logging level 'INFO' is enabled for the current user, based on the custom setting LoggerSettings__c
   * @return Boolean
   */
  global static Boolean isInfoEnabled() {
    return isEnabled(System.LoggingLevel.INFO);
  }

  /**
   * @description Indicates if logging level 'DEBUG' is enabled for the current user, based on the custom setting LoggerSettings__c
   * @return Boolean
   */
  global static Boolean isDebugEnabled() {
    return isEnabled(System.LoggingLevel.DEBUG);
  }

  /**
   * @description Indicates if logging level 'FINE' is enabled for the current user, based on the custom setting LoggerSettings__c
   * @return Boolean
   */
  global static Boolean isFineEnabled() {
    return isEnabled(System.LoggingLevel.FINE);
  }

  /**
   * @description Indicates if logging level 'FINER' is enabled for the current user, based on the custom setting LoggerSettings__c
   * @return Boolean
   */
  global static Boolean isFinerEnabled() {
    return isEnabled(System.LoggingLevel.FINER);
  }

  /**
   * @description Indicates if logging level 'FINEST' is enabled for the current user, based on the custom setting LoggerSettings__c
   * @return Boolean
   */
  global static Boolean isFinestEnabled() {
    return isEnabled(System.LoggingLevel.FINEST);
  }

  /**
   * @description Indicates if the specified logging level is enabled for the current user, based on the custom setting LoggerSettings__c
   * @param logEntryLoggingLevel the logging level to check.
   * @return Boolean
   */
  global static Boolean meetsUserLoggingLevel(System.LoggingLevel logEntryLoggingLevel) {
    return logEntryLoggingLevel.ordinal() >= userLoggingLevel.ordinal();
  }

  /**
   * @description Returns the logging level for the current user, based on the custom setting LoggerSettings__c
   * @return System.LoggingLevel - The matching instance of LoggingLevel
   */
  global static System.LoggingLevel getUserLoggingLevel() {
    return userLoggingLevel;
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
    // Only load the current user's settings once - this allows the instance to be modified in memory (as well as upserted if any changes should be persisted)
    if (currentUserSettings == null) {
      Schema.User currentUser = new Schema.User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
      currentUserSettings = getUserSettings(currentUser);
    }
    return currentUserSettings;
  }

  /**
   * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
   *              Returns the specified user's instance of `LoggerSettings__c`
   * @param       loggingUser The user record - at a minimum, this record should have the user Id and Profile fields populated
   * @return      LoggerSettings__c - The specified user's instance of the custom settings
   */
  public static LoggerSettings__c getUserSettings(Schema.User loggingUser) {
    // Typically, using LoggerSettings__c.getInstance() would be easier
    // However, some settings fields are expected to have null values, which conflicts with how `getInstance()` behaves
    // So, instead use LoggerSettings__c.getValues(Id userOrProfileId) to load exactly what's been configured (including nulls)

    // TODO cache the generated instances of LoggerSettings__c in LoggerCache.getTransactionCache().put()
    // (key would be 'Settings' + user ID)
    LoggerSettings__c loggingUserSettings;
    // First, check for Schema.User-level settings
    if (loggingUser.Id != null && LoggerSettings__c.getValues(loggingUser.Id) != null) {
      LoggerSettings__c userSettings = LoggerSettings__c.getValues(loggingUser.Id);
      if (hasValidStartAndEndTimes(userSettings)) {
        loggingUserSettings = userSettings;
      }
    }

    // Next, check for Profile-level settings
    if (loggingUserSettings == null && loggingUser.ProfileId != null && LoggerSettings__c.getValues(loggingUser.ProfileId) != null) {
      LoggerSettings__c profileSettings = LoggerSettings__c.getValues(loggingUser.ProfileId);
      if (hasValidStartAndEndTimes(profileSettings)) {
        loggingUserSettings = profileSettings;
      }
    }

    // Next, use the org defaults (if configured)
    if (loggingUserSettings == null && loggingUser.Id != null && LoggerSettings__c.getOrgDefaults().Id != null) {
      LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
      if (hasValidStartAndEndTimes(orgDefaults)) {
        loggingUserSettings = orgDefaults;
      }
    }

    // Finally, as a last resort, create an instance using default field values
    if (loggingUserSettings == null) {
      loggingUserSettings = createSettings();
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
   * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder error(LogMessage logMessage, Database.DeleteResult deleteResult) {
    return error().setDatabaseResult(deleteResult).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
   * @param  logMessage            The instance of `LogMessage` to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder error(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return error().setDatabaseResult(emptyRecycleBinResult).setMessage(logMessage);
  }

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
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return error().setDatabaseResult(emptyRecycleBinResults).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
   * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults) {
    return error().setDatabaseResult(leadConvertResults).setMessage(logMessage);
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
   * @param  message      The string to use to set the entry's message field
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder error(String message, Database.DeleteResult deleteResult) {
    return error().setDatabaseResult(deleteResult).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
   * @param  message               The string to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder error(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return error().setDatabaseResult(emptyRecycleBinResult).setMessage(message);
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
   * @param  message                The string to use to set the entry's message field
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder error(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return error().setDatabaseResult(emptyRecycleBinResults).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.ERROR`
   * @param  message      The string to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder error(String message, List<Database.LeadConvertResult> leadConvertResults) {
    return error().setDatabaseResult(leadConvertResults).setMessage(message);
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
   * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder warn(LogMessage logMessage, Database.DeleteResult deleteResult) {
    return warn().setDatabaseResult(deleteResult).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
   * @param  logMessage            The instance of `LogMessage` to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder warn(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return warn().setDatabaseResult(emptyRecycleBinResult).setMessage(logMessage);
  }

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
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return warn().setDatabaseResult(emptyRecycleBinResults).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
   * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults) {
    return warn().setDatabaseResult(leadConvertResults).setMessage(logMessage);
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
   * @param  message      The string to use to set the entry's message field
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder warn(String message, Database.DeleteResult deleteResult) {
    return warn().setDatabaseResult(deleteResult).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
   * @param  message               The string to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder warn(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return warn().setDatabaseResult(emptyRecycleBinResult).setMessage(message);
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
   * @param  message                The string to use to set the entry's message field
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder warn(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return warn().setDatabaseResult(emptyRecycleBinResults).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.WARN`
   * @param  message      The string to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder warn(String message, List<Database.LeadConvertResult> leadConvertResults) {
    return warn().setDatabaseResult(leadConvertResults).setMessage(message);
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
   * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder info(LogMessage logMessage, Database.DeleteResult deleteResult) {
    return info().setDatabaseResult(deleteResult).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
   * @param  logMessage            The instance of `LogMessage` to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder info(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return info().setDatabaseResult(emptyRecycleBinResult).setMessage(logMessage);
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
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return info().setDatabaseResult(emptyRecycleBinResults).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
   * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults) {
    return info().setDatabaseResult(leadConvertResults).setMessage(logMessage);
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
   * @param  message      The string to use to set the entry's message field
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder info(String message, Database.DeleteResult deleteResult) {
    return info().setDatabaseResult(deleteResult).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
   * @param  message               The string to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder info(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return info().setDatabaseResult(emptyRecycleBinResult).setMessage(message);
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
   * @param  message                The string to use to set the entry's message field
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder info(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return info().setDatabaseResult(emptyRecycleBinResults).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.INFO`
   * @param  message      The string to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder info(String message, List<Database.LeadConvertResult> leadConvertResults) {
    return info().setDatabaseResult(leadConvertResults).setMessage(message);
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
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder debug(LogMessage logMessage, Database.DeleteResult deleteResult) {
    return debug().setDatabaseResult(deleteResult).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
   * @param  logMessage            The instance of `LogMessage` to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder debug(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return debug().setDatabaseResult(emptyRecycleBinResult).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
   * @param  logMessage        The instance of `LogMessage` to use to set the entry's message field
   * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
   * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder debug(LogMessage logMessage, Database.LeadConvertResult leadConvertResult) {
    return debug().setDatabaseResult(leadConvertResult).setMessage(logMessage);
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
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return debug().setDatabaseResult(emptyRecycleBinResults).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
   * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults) {
    return debug().setDatabaseResult(leadConvertResults).setMessage(logMessage);
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
   * @param  message      The string to use to set the entry's message field
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder debug(String message, Database.DeleteResult deleteResult) {
    return debug().setDatabaseResult(deleteResult).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
   * @param  message               The string to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder debug(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return debug().setDatabaseResult(emptyRecycleBinResult).setMessage(message);
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
   * @param  message                The string to use to set the entry's message field
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder debug(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return debug().setDatabaseResult(emptyRecycleBinResults).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`
   * @param  message      The string to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder debug(String message, List<Database.LeadConvertResult> leadConvertResults) {
    return debug().setDatabaseResult(leadConvertResults).setMessage(message);
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
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder fine(LogMessage logMessage, Database.DeleteResult deleteResult) {
    return fine().setDatabaseResult(deleteResult).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
   * @param  logMessage            The instance of `LogMessage` to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder fine(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return fine().setDatabaseResult(emptyRecycleBinResult).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
   * @param  logMessage        The instance of `LogMessage` to use to set the entry's message field
   * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
   * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder fine(LogMessage logMessage, Database.LeadConvertResult leadConvertResult) {
    return fine().setDatabaseResult(leadConvertResult).setMessage(logMessage);
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
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return fine().setDatabaseResult(emptyRecycleBinResults).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
   * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults) {
    return fine().setDatabaseResult(leadConvertResults).setMessage(logMessage);
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
   * @param  message      The string to use to set the entry's message field
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder fine(String message, Database.DeleteResult deleteResult) {
    return fine().setDatabaseResult(deleteResult).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
   * @param  message               The string to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder fine(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return fine().setDatabaseResult(emptyRecycleBinResult).setMessage(message);
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
   * @param  message                The string to use to set the entry's message field
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder fine(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return fine().setDatabaseResult(emptyRecycleBinResults).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINE`
   * @param  message            The string to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder fine(String message, List<Database.LeadConvertResult> leadConvertResults) {
    return fine().setDatabaseResult(leadConvertResults).setMessage(message);
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
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finer(LogMessage logMessage, Database.DeleteResult deleteResult) {
    return finer().setDatabaseResult(deleteResult).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
   * @param  logMessage            The instance of `LogMessage` to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finer(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return finer().setDatabaseResult(emptyRecycleBinResult).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
   * @param  logMessage        The instance of `LogMessage` to use to set the entry's message field
   * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
   * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finer(LogMessage logMessage, Database.LeadConvertResult leadConvertResult) {
    return finer().setDatabaseResult(leadConvertResult).setMessage(logMessage);
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
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return finer().setDatabaseResult(emptyRecycleBinResults).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
   * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults) {
    return finer().setDatabaseResult(leadConvertResults).setMessage(logMessage);
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
   * @param  message      The string to use to set the entry's message field
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finer(String message, Database.DeleteResult deleteResult) {
    return finer().setDatabaseResult(deleteResult).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
   * @param  message               The string to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finer(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return finer().setDatabaseResult(emptyRecycleBinResult).setMessage(message);
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
   * @param  message                The string to use to set the entry's message field
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finer(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return finer().setDatabaseResult(emptyRecycleBinResults).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINER`
   * @param  message      The string to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finer(String message, List<Database.LeadConvertResult> leadConvertResults) {
    return finer().setDatabaseResult(leadConvertResults).setMessage(message);
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
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finest(LogMessage logMessage, Database.DeleteResult deleteResult) {
    return finest().setDatabaseResult(deleteResult).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
   * @param  logMessage            The instance of `LogMessage` to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finest(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return finest().setDatabaseResult(emptyRecycleBinResult).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
   * @param  logMessage        The instance of `LogMessage` to use to set the entry's message field
   * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
   * @return                   The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finest(LogMessage logMessage, Database.LeadConvertResult leadConvertResult) {
    return finest().setDatabaseResult(leadConvertResult).setMessage(logMessage);
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
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return finest().setDatabaseResult(emptyRecycleBinResults).setMessage(logMessage);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
   * @param  logMessage   The instance of `LogMessage` to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults) {
    return finest().setDatabaseResult(leadConvertResults).setMessage(logMessage);
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
   * @param  message      The string to use to set the entry's message field
   * @param  deleteResult The instance of `Database.DeleteResult` to log
   * @return              The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finest(String message, Database.DeleteResult deleteResult) {
    return finest().setDatabaseResult(deleteResult).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
   * @param  message               The string to use to set the entry's message field
   * @param  emptyRecycleBinResult The instance of `Database.LeadConvertResult` to log
   * @return                       The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finest(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult) {
    return finest().setDatabaseResult(emptyRecycleBinResult).setMessage(message);
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
   * @param  message                The string to use to set the entry's message field
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finest(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults) {
    return finest().setDatabaseResult(emptyRecycleBinResults).setMessage(message);
  }

  /**
   * @description Creates a new log entry with logging level == `System.LoggingLevel.FINEST`
   * @param  message      The string to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods
   */
  global static LogEntryEventBuilder finest(String message, List<Database.LeadConvertResult> leadConvertResults) {
    return finest().setDatabaseResult(leadConvertResults).setMessage(message);
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
   * @description Creates a log entry for any results within the provided `List<EmptyRecycleBinResult>` where `isSuccess() != true`
   * @param  loggingLevel           The logging level to use for the log entry
   * @param  logMessage             The instance of `LogMessage` to use to set the entry's message field
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
   */
  global static LogEntryEventBuilder logDatabaseErrors(
    System.LoggingLevel loggingLevel,
    LogMessage logMessage,
    List<Database.EmptyRecycleBinResult> emptyRecycleBinResults
  ) {
    return logDatabaseErrors(loggingLevel, logMessage.getMessage(), emptyRecycleBinResults);
  }

  /**
   * @description Creates a log entry for any results within the provided `List<EmptyRecycleBinResult>` where `isSuccess() != true`
   * @param  loggingLevel           The logging level to use for the log entry
   * @param  message                The string to use to set the entry's message field
   * @param  emptyRecycleBinResults The instance of `List<Database.EmptyRecycleBinResult>` to log
   * @return                        The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
   */
  global static LogEntryEventBuilder logDatabaseErrors(
    System.LoggingLevel loggingLevel,
    String message,
    List<Database.EmptyRecycleBinResult> emptyRecycleBinResults
  ) {
    List<Database.EmptyRecycleBinResult> resultsToLog = new List<Database.EmptyRecycleBinResult>();
    for (Database.EmptyRecycleBinResult emptyRecycleBinResult : emptyRecycleBinResults) {
      if (emptyRecycleBinResult.isSuccess() == false) {
        resultsToLog.add(emptyRecycleBinResult);
      }
    }

    Boolean shouldSave = resultsToLog.isEmpty() == false && isEnabled(loggingLevel);
    return newEntry(loggingLevel, message, shouldSave).setDatabaseResult(resultsToLog);
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
   * @param  loggingLevel       The logging level to use for the log entry
   * @param  message            The string to use to set the entry's message field
   * @param  leadConvertResults The instance of `List<Database.LeadConvertResult>` to log
   * @return                    The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors
   */
  global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.LeadConvertResult> leadConvertResults) {
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
  global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.UndeleteResult> undeleteResults) {
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
    return newEntry(loggingLevel, shouldSave).setMessage(logMessage);
  }

  /**
   * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
   * @param  loggingLevel The logging level enum value for the new entry
   * @param  logMessage   The instance of LogMessage to use as the entry's message
   * @return              The new entry's instance of LogEntryEventBuilder
   */
  global static LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel, LogMessage logMessage) {
    return newEntry(loggingLevel).setMessage(logMessage);
  }

  /**
   * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
   * @param  loggingLevel The logging level enum value for the new entry
   * @param  message      The string to use as the entry's message
   * @param  shouldSave   Controls if the new entry will be saved. This can be used to save entries, even if the entry's logging level does not meet the user's logging level
   * @return              The new entry's instance of LogEntryEventBuilder
   */
  global static LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel, String message, Boolean shouldSave) {
    return newEntry(loggingLevel, shouldSave).setMessage(message);
  }

  /**
   * @description Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level
   * @param  loggingLevel The logging level enum value for the new entry
   * @param  message      The string to use as the entry's message
   * @return              The new entry's instance of LogEntryEventBuilder
   */
  global static LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel, String message) {
    return newEntry(loggingLevel).setMessage(message);
  }

  // Save control methods
  /**
   * @description Returns the scenario name for the current transaction - this is stored in `LogEntryEvent__e.Scenario__c`
   *              and `Log__c.Scenario__c`, and can be used to filter & group logs
   * @return   The value currently set as the current transaction's scenario
   */
  global static String getScenario() {
    return currentEntryScenario;
  }

  /**
   * @description Sets the current scenario, which can be used to identify modules or groupings of  for the current transaction
   * @param  scenario The name to use for the current transaction's scenario
   */
  @SuppressWarnings('PMD.NcssMethodCount')
  global static void setScenario(String scenario) {
    if (LoggerParameter.USE_FIRST_SCENARIO_FOR_TRANSACTION == false || String.isBlank(transactionScenario)) {
      transactionScenario = scenario;
      // One of a few limited places in the codebase (except tests) that should use System.debug()
      // The rest of the codebase should use a method in Logger.cls
      if (String.isNotBlank(transactionScenario)) {
        System.debug(System.LoggingLevel.INFO, 'Nebula Logger - Transaction Scenario: ' + transactionScenario);
      }
    }

    if (String.isNotBlank(scenario) && scenario == currentEntryScenario) {
      return;
    }

    currentEntryScenario = scenario;
    orderedScenarios.add(scenario);
    // One of a few limited places in the codebase (except tests) that should use System.debug()
    // The rest of the codebase should use a method in Logger.cls
    if (String.isNotBlank(currentEntryScenario)) {
      System.debug(System.LoggingLevel.INFO, 'Nebula Logger - Entry Scenario: ' + currentEntryScenario);
    }
    LoggerScenarioRule__mdt matchingScenarioRule = LoggerScenarioRule.getInstance(scenario);
    if (matchingScenarioRule != null) {
      // Clear & reload the user's settings so that there aren't any lingering changes made by previous scenario rules
      currentUserSettings = null;
      LoggerSettings__c userSettings = getUserSettings();
      if (String.isNotBlank(matchingScenarioRule.IsLoggerEnabled__c)) {
        userSettings.IsEnabled__c = Boolean.valueOf(matchingScenarioRule.IsLoggerEnabled__c);
      }
      if (String.isNotBlank(matchingScenarioRule.IsAnonymousModeEnabled__c)) {
        userSettings.IsAnonymousModeEnabled__c = Boolean.valueOf(matchingScenarioRule.IsAnonymousModeEnabled__c);
      }
      if (String.isNotBlank(matchingScenarioRule.IsApexSystemDebugLoggingEnabled__c)) {
        userSettings.IsApexSystemDebugLoggingEnabled__c = Boolean.valueOf(matchingScenarioRule.IsApexSystemDebugLoggingEnabled__c);
      }
      if (String.isNotBlank(matchingScenarioRule.IsDataMaskingEnabled__c)) {
        userSettings.IsDataMaskingEnabled__c = Boolean.valueOf(matchingScenarioRule.IsDataMaskingEnabled__c);
      }
      if (String.isNotBlank(matchingScenarioRule.IsJavaScriptConsoleLoggingEnabled__c)) {
        userSettings.IsJavaScriptConsoleLoggingEnabled__c = Boolean.valueOf(matchingScenarioRule.IsJavaScriptConsoleLoggingEnabled__c);
      }
      if (String.isNotBlank(matchingScenarioRule.IsJavaScriptLightningLoggerEnabled__c)) {
        userSettings.IsJavaScriptLightningLoggerEnabled__c = Boolean.valueOf(matchingScenarioRule.IsJavaScriptLightningLoggerEnabled__c);
      }
      if (String.isNotBlank(matchingScenarioRule.IsRecordFieldStrippingEnabled__c)) {
        userSettings.IsRecordFieldStrippingEnabled__c = Boolean.valueOf(matchingScenarioRule.IsRecordFieldStrippingEnabled__c);
      }
      if (String.isNotBlank(matchingScenarioRule.IsSavingEnabled__c)) {
        userSettings.IsSavingEnabled__c = Boolean.valueOf(matchingScenarioRule.IsSavingEnabled__c);
      }
      if (String.isNotBlank(matchingScenarioRule.SaveMethod__c)) {
        setSaveMethod(matchingScenarioRule.SaveMethod__c);
      }
      if (String.isNotBlank(matchingScenarioRule.UserLoggingLevel__c)) {
        userSettings.LoggingLevel__c = matchingScenarioRule.UserLoggingLevel__c;
      }
    }
  }

  /**
   * @description End the specified scenario, if it's the currently active scenario,
   *              and rolls back to the previous scenario (if a previous scenario was specified in the current transaction)
   * @param  scenario The name of the scenario to end
   */
  global static void endScenario(String scenario) {
    if (String.isBlank(scenario) || scenario != currentEntryScenario || orderedScenarios.isEmpty()) {
      return;
    }

    Integer lastScenarioIndex = orderedScenarios.size() - 1;
    orderedScenarios.remove(lastScenarioIndex);
    String previousScenario;
    if (orderedScenarios.isEmpty() == false) {
      Integer previousScenarioIndex = orderedScenarios.size() - 1;
      previousScenario = orderedScenarios.remove(previousScenarioIndex);
    }
    if (String.isBlank(previousScenario)) {
      currentEntryScenario = null;
      // Clear & reload the user's settings so that there aren't any lingering changes made by previous scenario rules
      // The settings will then be auto-reloaded when setScenario(previousScenario) is called below
      currentUserSettings = null;
    }

    setScenario(previousScenario);
  }

  /**
   * @description Adds the specified Apex type to the list of ignored origin locations for the current transaction.
   *              Any ignored types will be removed from the StackTrace__c field, and will be skipped when determining
   *              the log entry's origin location
   * @param  apexType The Apex type of the class to ignore
   */
  global static void ignoreOrigin(System.Type apexType) {
    LoggerStackTrace.ignoreOrigin(apexType);
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
    setSaveMethod(saveMethod.name());
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
   * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
   *              Saves any entries in Logger's buffer, using the specified save method for only this call.
   *              All subsequent calls to saveLog() will use the transaction save method.
   * @param  saveMethodName The String value of the save method to use for this specific save action.
   */
  @SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount')
  public static void saveLog(String saveMethodName) {
    saveLogCallCount++;
    lastSaveMethodNameUsed = saveMethodName;
    if (LOG_ENTRIES_BUFFER.isEmpty() || getUserSettings().IsSavingEnabled__c == false) {
      return;
    }

    if (suspendSaving) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        finest(getSuspendSavingLogSystemMessage());
      }

      return;
    }

    if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
      finest(getSavingLogSystemMessage(saveMethodName));
    }

    List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();
    for (LogEntryEventBuilder logEntryEventBuilder : LOG_ENTRIES_BUFFER) {
      if (logEntryEventBuilder.shouldSave()) {
        LogEntryEvent__e logEntryEvent = logEntryEventBuilder.getLogEntryEvent();
        finalizeEntry(logEntryEvent);
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
      System.TriggerOperation.BEFORE_INSERT,
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
        if (String.isBlank(USER_SESSION_ID)) {
          saveLog(Logger.SaveMethod.EVENT_BUS);
        } else {
          new RestApiSaver().insertRecords(logEntryEvents);
        }
      }
      when SYNCHRONOUS_DML {
        LoggerTriggerableContext logEntryEventsAfterContext = new LoggerTriggerableContext(
          Schema.LogEntryEvent__e.SObjectType,
          System.TriggerOperation.AFTER_INSERT,
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
   * @return                  The matching instance of System.LoggingLevel (or a default value if a match is not found)
   */
  global static System.LoggingLevel getLoggingLevel(String loggingLevelName) {
    try {
      return System.LoggingLevel.valueOf(loggingLevelName?.trim().toUpperCase());
    } catch (NoSuchElementException ex) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        LogMessage logMessage = new LogMessage('Logger - Unknown logging level {0} specified, using {1}', loggingLevelName, FALLBACK_LOGGING_LEVEL.name());
        finest(logMessage);
      }
      return FALLBACK_LOGGING_LEVEL;
    }
  }

  /**
   * @description **This is only intended to be used internally by Nebula Logger, and is subject to change.**
   *              Calls Salesforce's API endpoint https://api.status.salesforce.com/v1/instances/
   *              to get more details about the current org, including the org's release number and release version.
   *              Trust API docs available at https://api.status.salesforce.com/v1/docs/
   * @return      An instance of `Logger.StatusApiResponse` (a DTO that maps to the JSON returned by the status API endpoint),
   *              or `null` when the callout fails (due to the remote site setting being disabled, the endpoint being unable, etc.).
   */
  public static StatusApiResponse callStatusApi() {
    if (LoggerParameter.CALL_STATUS_API == false) {
      return null;
    }

    Schema.Organization organization = LoggerEngineDataSelector.getInstance().getCachedOrganization();
    String statusApiEndpoint = 'https://api.status.salesforce.com/v1/instances/' + organization.InstanceName + '/status';

    System.HttpRequest request = new System.HttpRequest();
    request.setEndpoint(statusApiEndpoint);
    request.setMethod('GET');

    try {
      System.HttpResponse response = new System.Http().send(request);
      if (response.getStatusCode() >= 400) {
        String errorMessage =
          'Callout failed for ' +
          statusApiEndpoint +
          '\nReceived request status code ' +
          response.getStatusCode() +
          ', status message: ' +
          response.getStatus();
        throw new System.CalloutException(errorMessage);
      }

      StatusApiResponse statusApiResponse = (StatusApiResponse) System.JSON.deserialize(response.getBody(), StatusApiResponse.class);
      return statusApiResponse;
    } catch (Exception ex) {
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        finest('Callout to api.status.salesforce.com failed').setExceptionDetails(ex);
      }
      return null;
    }
  }

  // Private logging level methods to keep global methods simpler/cleaner
  private static LogEntryEventBuilder error() {
    return newEntry(System.LoggingLevel.ERROR);
  }

  private static LogEntryEventBuilder warn() {
    return newEntry(System.LoggingLevel.WARN);
  }

  private static LogEntryEventBuilder info() {
    return newEntry(System.LoggingLevel.INFO);
  }

  private static LogEntryEventBuilder debug() {
    return newEntry(System.LoggingLevel.DEBUG);
  }

  private static LogEntryEventBuilder fine() {
    return newEntry(System.LoggingLevel.FINE);
  }

  private static LogEntryEventBuilder finer() {
    return newEntry(System.LoggingLevel.FINER);
  }

  private static LogEntryEventBuilder finest() {
    return newEntry(System.LoggingLevel.FINEST);
  }

  private static LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel) {
    return newEntry(loggingLevel, isEnabled(loggingLevel));
  }

  private static LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel, Boolean shouldSave) {
    LogEntryEventBuilder logEntryEventBuilder = new LogEntryEventBuilder(getUserSettings(), loggingLevel, shouldSave)
      // Don't include the logging system's classes in the stack trace
      .parseStackTrace(new System.DmlException().getStackTraceString().replaceAll('(' + String.join(CLASSES_TO_IGNORE, '|') + ')\\..+?column 1', '').trim());
    if (logEntryEventBuilder.shouldSave()) {
      if (LoggerParameter.REQUIRE_SCENARIO_USAGE && String.isBlank(currentEntryScenario)) {
        throw new LoggerException(MISSING_SCENARIO_ERROR_MESSAGE);
      }
      LOGGING_CONTEXT.currentEntryScenario = currentEntryScenario;
      LOGGING_CONTEXT.entryNumber++;
      LOGGING_CONTEXT.userLoggingLevel = userLoggingLevel;
      logEntryEventBuilder.setLoggingContext(LOGGING_CONTEXT);
      LOG_ENTRIES_BUFFER.add(logEntryEventBuilder);
    }

    return logEntryEventBuilder;
  }
  private static void finalizeEntry(LogEntryEvent__e logEntryEvent) {
    setTransactionFields(logEntryEvent);

    logEntryEvent.ParentLogTransactionId__c = getParentLogTransactionId();
    logEntryEvent.TransactionScenario__c = transactionScenario;

    if (currentAsyncContext != null) {
      logEntryEvent.AsyncContextChildJobId__c = currentAsyncContext.childJobId;
      logEntryEvent.AsyncContextParentJobId__c = currentAsyncContext.parentJobId;
      logEntryEvent.AsyncContextTriggerId__c = currentAsyncContext.triggerId;
      logEntryEvent.AsyncContextType__c = currentAsyncContext.type;
    }
  }

  @SuppressWarnings('PMD.AvoidDebugStatements')
  private static void setTransactionFields(LogEntryEvent__e logEntryEvent) {
    for (Schema.SObjectField field : TRANSACTION_FIELD_TO_VALUE.keySet()) {
      Object value = TRANSACTION_FIELD_TO_VALUE.get(field);

      try {
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
        if (fieldDescribe.getSoapType() == Schema.SoapType.STRING) {
          value = LoggerDataStore.truncateFieldValue(field, (String) value);
        }

        logEntryEvent.put(field, value);
      } catch (System.Exception ex) {
        LogMessage logMessage = new LogMessage('Could not set field {0} with value {1}', field, value);
        System.debug(System.LoggingLevel.WARN, logMessage.getMessage());
      }
    }
  }

  private static Boolean hasValidStartAndEndTimes(LoggerSettings__c settings) {
    Datetime nowish = System.now();
    Boolean isStartTimeValid = settings.StartTime__c == null || settings.StartTime__c <= nowish;
    Boolean isEndTimeValid = settings.EndTime__c == null || settings.EndTime__c >= nowish;
    return isStartTimeValid && isEndTimeValid;
  }

  private static System.Quiddity loadTransactionQuiddity() {
    // An error can sometimes occur when calling System.Request.getCurrent(), such as when logging
    // from an Auth Provider class (that implements Auth.RegistrationHandler). As a workaround,
    // skip calling System.Request.getCurrent() if there is no user session.
    // TODO: see if there is a better approach for this long term (or hopefully Salesforce fixes the gack error)
    if (String.isNotBlank(USER_SESSION_ID)) {
      return System.Request.getCurrent().getQuiddity();
    } else {
      return null;
    }
  }

  private static void setAsyncContext(AsyncContext asyncContext) {
    // Only set the async context the first time that a non-null value is provided
    // Previous versions of Nebula Logger would always set it, but that wasn't the
    // intended behavior
    if (currentAsyncContext == null) {
      currentAsyncContext = asyncContext;
      if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
        info('Nebula Logger - Async Context: ' + System.JSON.serializePretty(asyncContext, true)).setExceptionDetails(asyncContext.finalizerException);
      }
    }
  }

  private static SaveMethod getSaveMethod(String saveMethodName) {
    if (SAVE_METHOD_NAME_TO_SAVE_METHOD.isEmpty()) {
      for (SaveMethod method : SaveMethod.values()) {
        SAVE_METHOD_NAME_TO_SAVE_METHOD.put(method.name(), method);
      }
    }

    return SAVE_METHOD_NAME_TO_SAVE_METHOD.get(saveMethodName);
  }

  private static void setSaveMethod(String saveMethodName) {
    transactionSaveMethodName = saveMethodName;
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
   * @description Inner class for publishing log entries via the System.Queueable interface.
   */
  global class QueueableSaver implements System.Queueable {
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
      LoggerDataStore.getEventBus().publishRecords(this.logEntryEvents);
    }
  }

  // Inner class used for any exceptions specific to Nebula Logger functionality
  @SuppressWarnings('PMD.ApexDoc')
  public class LoggerException extends Exception {
  }

  // Inner class used for deserializing data from the status API
  @SuppressWarnings('PMD.ApexDoc, PMD.VariableNamingConventions')
  public class StatusApiResponse {
    public String location { get; set; }
    public String maintenanceWindow { get; set; }
    public String releaseNumber { get; set; }
    public String releaseVersion { get; set; }
    public List<StatusApiResponseProduct> Products { get; set; }
  }

  // Inner class used for deserializing data from the status API
  @SuppressWarnings('PMD.ApexDoc')
  public class StatusApiResponseProduct {
    public String key { get; set; }
    public String name { get; set; }
  }

  // Inner class for tracking details about the current transaction's async context
  @SuppressWarnings('PMD.ApexDoc')
  @TestVisible
  private class AsyncContext {
    public final String type;
    public final String parentJobId;
    public final String childJobId;
    public final String triggerId;
    public final String finalizerResult;
    // Instances of Exception can't be serialized, but instances of AsyncContext
    // are sometimes serialized - so, the AsyncContext's Exception is transient,
    // and an extra getter for Map<String, Object>, containing the exception's data,
    // is used to provide a quick & easy serializable version
    public transient final Exception finalizerException;
    public Map<String, Object> finalizerUnhandledException {
      get {
        return finalizerException == null
          ? null
          : new Map<String, Object>{
              'cause' => this.finalizerException.getCause(),
              'lineNumber' => this.finalizerException.getLineNumber(),
              'message' => this.finalizerException.getMessage(),
              'stackTraceString' => this.finalizerException.getStackTraceString(),
              'typeName' => this.finalizerException.getTypeName()
            };
      }
    }

    public AsyncContext(Database.BatchableContext batchableContext) {
      this.childJobId = batchableContext?.getChildJobId();
      this.parentJobId = batchableContext?.getJobId();
      this.type = Database.BatchableContext.class.getName();
    }

    public AsyncContext(System.FinalizerContext finalizerContext) {
      if (finalizerContext != null) {
        this.finalizerException = finalizerContext.getException();
        this.finalizerResult = finalizerContext.getResult()?.name();
        this.parentJobId = finalizerContext.getAsyncApexJobId();
      }
      this.type = System.FinalizerContext.class.getName();
    }

    public AsyncContext(System.QueueableContext queueableContext) {
      this.parentJobId = queueableContext?.getJobId();
      this.type = System.QueueableContext.class.getName();
    }

    public AsyncContext(System.SchedulableContext schedulableContext) {
      this.triggerId = schedulableContext?.getTriggerId();
      this.type = System.SchedulableContext.class.getName();
    }
  }

  // Inner class for saving log entries via the REST API (using the current user's session ID)
  private class RestApiSaver {
    private final String baseURL = ORGANIZATION_DOMAIN_URL + '/services/data/' + getOrganizationApiVersion();
    private final String compositeEndpoint = '/composite/sobjects';

    @SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
    /**
     * @description Inserts records via the REST api.
     * @param records The records to save.
     */
    public void insertRecords(List<SObject> records) {
      System.HttpRequest request = new System.HttpRequest();
      request.setEndpoint(baseURL + compositeEndpoint);
      request.setHeader('Authorization', 'Bearer ' + USER_SESSION_ID);
      request.setHeader('Content-Type', 'application/json; charset=utf-8');
      request.setMethod('POST');

      Boolean allOrNone = true;
      RestSaveRequest saveRequest = new RestSaveRequest(records, allOrNone);
      request.setBody(System.JSON.serialize(saveRequest));

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
