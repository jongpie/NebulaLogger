---
layout: default
---
## Logger class

The core class for logging

### Related

[LogEntryEventBuilder](LogEntryEventBuilder)


[LogMessage](LogMessage)

---
### Enums
#### SaveMethod


 Enum used to control how LogEntryEvent__e records are inserted

---
### Properties

#### `allOrNone` → `Boolean`

#### `records` → `List<SObject>`

---
### Methods
#### `debug(LogMessage logMessage, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `debug(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`
#### `debug(LogMessage logMessage, List<String> topics)` → `LogEntryEventBuilder`
#### `debug(LogMessage logMessage, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `debug(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`
#### `debug(LogMessage logMessage)` → `LogEntryEventBuilder`
#### `debug(String message, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `debug(String message, Id recordId)` → `LogEntryEventBuilder`
#### `debug(String message, List<String> topics)` → `LogEntryEventBuilder`
#### `debug(String message, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `debug(String message, SObject record)` → `LogEntryEventBuilder`
#### `debug(String message)` → `LogEntryEventBuilder`
#### `error(LogMessage logMessage, Exception apexException, List<String> topics)` → `LogEntryEventBuilder`
#### `error(LogMessage logMessage, Exception apexException)` → `LogEntryEventBuilder`
#### `error(LogMessage logMessage, Id recordId, Exception apexException, List<String> topics)` → `LogEntryEventBuilder`
#### `error(LogMessage logMessage, Id recordId, Exception apexException)` → `LogEntryEventBuilder`
#### `error(LogMessage logMessage, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `error(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`
#### `error(LogMessage logMessage, List<String> topics)` → `LogEntryEventBuilder`
#### `error(LogMessage logMessage, SObject record, Exception apexException, List<String> topics)` → `LogEntryEventBuilder`
#### `error(LogMessage logMessage, SObject record, Exception apexException)` → `LogEntryEventBuilder`
#### `error(LogMessage logMessage, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `error(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`
#### `error(LogMessage logMessage)` → `LogEntryEventBuilder`
#### `error(String message, Exception apexException, List<String> topics)` → `LogEntryEventBuilder`
#### `error(String message, Exception apexException)` → `LogEntryEventBuilder`
#### `error(String message, Id recordId, Exception apexException, List<String> topics)` → `LogEntryEventBuilder`
#### `error(String message, Id recordId, Exception apexException)` → `LogEntryEventBuilder`
#### `error(String message, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `error(String message, Id recordId)` → `LogEntryEventBuilder`
#### `error(String message, List<String> topics)` → `LogEntryEventBuilder`
#### `error(String message, SObject record, Exception apexException, List<String> topics)` → `LogEntryEventBuilder`
#### `error(String message, SObject record, Exception apexException)` → `LogEntryEventBuilder`
#### `error(String message, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `error(String message, SObject record)` → `LogEntryEventBuilder`
#### `error(String message)` → `LogEntryEventBuilder`
#### `fine(LogMessage logMessage, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `fine(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`
#### `fine(LogMessage logMessage, List<String> topics)` → `LogEntryEventBuilder`
#### `fine(LogMessage logMessage, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `fine(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`
#### `fine(LogMessage logMessage)` → `LogEntryEventBuilder`
#### `fine(String message, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `fine(String message, Id recordId)` → `LogEntryEventBuilder`
#### `fine(String message, List<String> topics)` → `LogEntryEventBuilder`
#### `fine(String message, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `fine(String message, SObject record)` → `LogEntryEventBuilder`
#### `fine(String message)` → `LogEntryEventBuilder`
#### `finer(LogMessage logMessage, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `finer(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`
#### `finer(LogMessage logMessage, List<String> topics)` → `LogEntryEventBuilder`
#### `finer(LogMessage logMessage, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `finer(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`
#### `finer(LogMessage logMessage)` → `LogEntryEventBuilder`
#### `finer(String message, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `finer(String message, Id recordId)` → `LogEntryEventBuilder`
#### `finer(String message, List<String> topics)` → `LogEntryEventBuilder`
#### `finer(String message, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `finer(String message, SObject record)` → `LogEntryEventBuilder`
#### `finer(String message)` → `LogEntryEventBuilder`
#### `finest(LogMessage logMessage, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `finest(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`
#### `finest(LogMessage logMessage, List<String> topics)` → `LogEntryEventBuilder`
#### `finest(LogMessage logMessage, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `finest(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`
#### `finest(LogMessage logMessage)` → `LogEntryEventBuilder`
#### `finest(String message, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `finest(String message, Id recordId)` → `LogEntryEventBuilder`
#### `finest(String message, List<String> topics)` → `LogEntryEventBuilder`
#### `finest(String message, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `finest(String message, SObject record)` → `LogEntryEventBuilder`
#### `finest(String message)` → `LogEntryEventBuilder`
#### `flushBuffer()` → `void`

 Discards any entries that have been generated but not yet saved

#### `getBufferSize()` → `Integer`

 Returns the number of entries that have been generated but not yet saved

##### Return

**Type**

Integer

**Description**

Integer

#### `getCurrentQuiddity()` → `Quiddity`

 Returns the Quiddity context of the current transaction.

##### Return

**Type**

Quiddity

**Description**

Quiddity - The value of System.Request.getCurrent().getQuiddity()

#### `getLog(String logId)` → `Log__c`

 Returns a Log__c record from the database

##### Parameters

|Param|Description|
|-----|-----------|
|`logId` |  - The Salesforce ID or TransactionId__c of the Log__c |

##### Return

**Type**

Log__c

**Description**

Log__c - The matching record, with all fields that the current user can access

#### `getLoggingLevel(String loggingLevelName)` → `LoggingLevel`

 Converts a String to an instance of LoggingLevel

##### Parameters

|Param|Description|
|-----|-----------|
|`String` |  loggingLevelName - The string name of an Apex logging level |

##### Return

**Type**

LoggingLevel

**Description**

LoggingLevel - The matching instance of LoggingLevel (or a default value if a match is not found)

#### `getParentLogTransactionId()` → `String`

 Returns the transaction ID value that will be used to relate the current transaction's log to a parent log

##### Return

**Type**

String

**Description**

String - The parent log's transaction ID. This must be explicitly set by calling setParentLogTransactionId(String)

#### `getTransactionId()` → `String`

 Returns the unique ID for a particular transaction, stored in Log__c.TransactionId__c

##### Return

**Type**

String

**Description**

String - The value of System.Request.getCurrent().getRequestId()

#### `getUserLoggingLevel()` → `LoggingLevel`

 Returns the logging level for the current user, based on the custom setting LoggerSettings__c

##### Return

**Type**

LoggingLevel

**Description**

LoggingLevel - The matching instance of LoggingLevel

#### `info(LogMessage logMessage, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `info(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`
#### `info(LogMessage logMessage, List<String> topics)` → `LogEntryEventBuilder`
#### `info(LogMessage logMessage, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `info(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`
#### `info(LogMessage logMessage)` → `LogEntryEventBuilder`
#### `info(String message, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `info(String message, Id recordId)` → `LogEntryEventBuilder`
#### `info(String message, List<String> topics)` → `LogEntryEventBuilder`
#### `info(String message, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `info(String message, SObject record)` → `LogEntryEventBuilder`
#### `info(String message)` → `LogEntryEventBuilder`
#### `insertRecords(List<SObject> records)` → `void`
#### `isDebugEnabled()` → `Boolean`

 Indicates if logging level 'DEBUG' is enabled for the current user, based on the custom setting LoggerSettings__c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isEnabled()` → `Boolean`

 Indicates if logging has been enabled for the current user, based on the custom setting LoggerSettings__c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isEnabled(LoggingLevel loggingLevel)` → `Boolean`

 Indicates if logging for the specified logging level is enabled for the current user, based on the custom setting LoggerSettings__c

##### Parameters

|Param|Description|
|-----|-----------|
|`loggingLevel` |  - The logging level to check |

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isErrorEnabled()` → `Boolean`

 Indicates if logging level 'ERROR' is enabled for the current user, based on the custom setting LoggerSettings__c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isFineEnabled()` → `Boolean`

 Indicates if logging level 'FINE' is enabled for the current user, based on the custom setting LoggerSettings__c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isFinerEnabled()` → `Boolean`

 Indicates if logging level 'FINER' is enabled for the current user, based on the custom setting LoggerSettings__c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isFinestEnabled()` → `Boolean`

 Indicates if logging level 'FINEST' is enabled for the current user, based on the custom setting LoggerSettings__c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isInfoEnabled()` → `Boolean`

 Indicates if logging level 'INFO' is enabled for the current user, based on the custom setting LoggerSettings__c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isSavingSuspended()` → `Boolean`

 Indicates if saving has been temporarily suspended for the current transaction

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isWarnEnabled()` → `Boolean`

 Indicates if logging level 'WARN' is enabled for the current user, based on the custom setting LoggerSettings__c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `meetsUserLoggingLevel(LoggingLevel logEntryLoggingLevel)` → `Boolean`

 Indicates if the specified logging level is enabled for the current user, based on the custom setting LoggerSettings__c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `newEntry(LoggingLevel loggingLevel, LogMessage logMessage, Boolean shouldSave)` → `LogEntryEventBuilder`

 Adds a new instance of LogEntryEventBuilder to Logger's buffer, if shouldSave == true

##### Parameters

|Param|Description|
|-----|-----------|
|`loggingLevel` |  The logging level enum for the new entry |
|`logMessage` |    The instance of LogMessage to use as the entry's message |
|`shouldSave` |    Controls if the new entry will be saved. This can be used to save entries, even if the entry's logging level does not meet the user's logging level |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of LogEntryEventBuilder

#### `newEntry(LoggingLevel loggingLevel, LogMessage logMessage)` → `LogEntryEventBuilder`

 Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level

##### Parameters

|Param|Description|
|-----|-----------|
|`loggingLevel` |  The logging level enum for the new entry |
|`logMessage` |    The instance of LogMessage to use as the entry's message |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of LogEntryEventBuilder

#### `newEntry(LoggingLevel loggingLevel, String message, Boolean shouldSave)` → `LogEntryEventBuilder`

 Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level

##### Parameters

|Param|Description|
|-----|-----------|
|`loggingLevel` |  The logging level enum for the new entry |
|`message` |       The string to use as the entry's message |
|`shouldSave` |    Controls if the new entry will be saved. This can be used to save entries, even if the entry's logging level does not meet the user's logging level |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of LogEntryEventBuilder

#### `newEntry(LoggingLevel loggingLevel, String message)` → `LogEntryEventBuilder`

 Adds a new instance of LogEntryEventBuilder to Logger's buffer, if it meets the user's logging level

##### Parameters

|Param|Description|
|-----|-----------|
|`loggingLevel` |  The logging level enum for the new entry |
|`message` |       The string to use as the entry's message |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry's instance of LogEntryEventBuilder

#### `resumeSaving()` → `void`

 Resumes saving for the current transaction, used to reverse suspendSaving(). Any calls to saveLog() are ignored until saving is resumed.

#### `saveLog()` → `void`

 Saves any entries in Logger's buffer. By default, entries are saved via Apex's EventBus and can be overridden with setSaveMethod(SaveMethod saveMethod)

#### `saveLog(SaveMethod saveMethod)` → `void`

 Saves any entries in Logger's buffer, using the specified save method for only this call. All subsequent calls to saveLog() will use the transaction save method.

##### Parameters

|Param|Description|
|-----|-----------|
|`saveMethod` |  The enum value of Logger.SaveMethod to use for this specific save action. |

#### `setParentLogTransactionId(String parentTransactionId)` → `void`

 Relates the current transaction's log to a parent log via the field Log__c.ParentLog__c This is useful for relating multiple asynchronous operations together, such as batch & queueable jobs.

##### Parameters

|Param|Description|
|-----|-----------|
|`parentTransactionId` |  - The transaction ID of the original parent transaction |

#### `setSaveMethod(SaveMethod saveMethod)` → `void`

 Sets the default save method used when calling saveLog() - any subsequent calls to saveLog() will use the specified save method

##### Parameters

|Param|Description|
|-----|-----------|
|`saveMethod` |  - The enum value of Logger.SaveMethod to use for any other calls to saveLog() in the current transaction |

#### `suspendSaving()` → `void`

 Pauses saving for the current transaction. Any calls to saveLog() are ignored until saving is resumed.

#### `warn(LogMessage logMessage, Exception apexException, List<String> topics)` → `LogEntryEventBuilder`
#### `warn(LogMessage logMessage, Exception apexException)` → `LogEntryEventBuilder`
#### `warn(LogMessage logMessage, Id recordId, Exception apexException, List<String> topics)` → `LogEntryEventBuilder`
#### `warn(LogMessage logMessage, Id recordId, Exception apexException)` → `LogEntryEventBuilder`
#### `warn(LogMessage logMessage, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `warn(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`
#### `warn(LogMessage logMessage, List<String> topics)` → `LogEntryEventBuilder`
#### `warn(LogMessage logMessage, SObject record, Exception apexException, List<String> topics)` → `LogEntryEventBuilder`
#### `warn(LogMessage logMessage, SObject record, Exception apexException)` → `LogEntryEventBuilder`
#### `warn(LogMessage logMessage, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `warn(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`
#### `warn(LogMessage logMessage)` → `LogEntryEventBuilder`
#### `warn(String message, Exception apexException, List<String> topics)` → `LogEntryEventBuilder`
#### `warn(String message, Exception apexException)` → `LogEntryEventBuilder`
#### `warn(String message, Id recordId, Exception apexException, List<String> topics)` → `LogEntryEventBuilder`
#### `warn(String message, Id recordId, Exception apexException)` → `LogEntryEventBuilder`
#### `warn(String message, Id recordId, List<String> topics)` → `LogEntryEventBuilder`
#### `warn(String message, Id recordId)` → `LogEntryEventBuilder`
#### `warn(String message, List<String> topics)` → `LogEntryEventBuilder`
#### `warn(String message, SObject record, Exception apexException, List<String> topics)` → `LogEntryEventBuilder`
#### `warn(String message, SObject record, Exception apexException)` → `LogEntryEventBuilder`
#### `warn(String message, SObject record, List<String> topics)` → `LogEntryEventBuilder`
#### `warn(String message, SObject record)` → `LogEntryEventBuilder`
#### `warn(String message)` → `LogEntryEventBuilder`
---
### Inner Classes

#### Logger.QueueableSaver class
---
##### Methods
###### `execute(System.QueueableContext queueableContext)` → `void`
---
