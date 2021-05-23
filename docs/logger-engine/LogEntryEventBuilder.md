---
layout: default
---
## LogEntryEventBuilder class

Builder class that generates each LogEntryEvent__c record

### Related

[Logger](Logger)

---
### Constructors
#### `LogEntryEventBuilder(LoggingLevel loggingLevel, Boolean shouldSave)`
---
### Methods
#### `getLogEntryEvent()` → `LogEntryEvent__e`

 Returns the LogEntryEvent__e record for this instance of LogEntryEventBuilder

##### Return

**Type**

LogEntryEvent__e

**Description**

The LogEntryEvent__e record

#### `parseStackTrace(String stackTraceString)` → `LogEntryEventBuilder`

 Parses the provided stack trace and sets the log entry's origin & stack trace fields

##### Parameters

|Param|Description|
|-----|-----------|
|`stackTraceString` |  The Apex stack trace string to parse |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of LogEntryEventBuilder, useful for chaining methods

#### `setExceptionDetails(Exception apexException)` → `LogEntryEventBuilder`

 Sets the log entry event's exception fields

##### Parameters

|Param|Description|
|-----|-----------|
|`apexException` |  The instance of an Exception to use. |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of LogEntryEventBuilder, useful for chaining methods

#### `setMessage(LogMessage logMessage)` → `LogEntryEventBuilder`

 Sets the log entry event's message field

##### Parameters

|Param|Description|
|-----|-----------|
|`logMessage` |  The instance of LogMessage to use - LogMessage.getMessage() will be used |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of LogEntryEventBuilder, useful for chaining methods

#### `setMessage(String message)` → `LogEntryEventBuilder`

 Sets the log entry event's message field

##### Parameters

|Param|Description|
|-----|-----------|
|`message` |  The instance of LogMessage to use - LogMessage.getMessage() will be used |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of LogEntryEventBuilder, useful for chaining methods

#### `setRecordId(SObject record)` → `LogEntryEventBuilder`

 Sets the log entry event's record fields

##### Parameters

|Param|Description|
|-----|-----------|
|`record` |  The SObject record related to the entry. The JSON of the record is automatically added to the entry |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of LogEntryEventBuilder, useful for chaining methods

#### `setRecordId(Id recordId)` → `LogEntryEventBuilder`

 Sets the log entry event's record fields

##### Parameters

|Param|Description|
|-----|-----------|
|`recordId` |  The ID of the SObject record related to the entry |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of LogEntryEventBuilder, useful for chaining methods

#### `setTopics(List<String> topics)` → `LogEntryEventBuilder`

 Sets a comma-separate list of strings on the LogEntryEvent__e, which ultimately becomes Topic & TopicAssignment records on Log__c and LogEntry__c

##### Parameters

|Param|Description|
|-----|-----------|
|`topics` |  The list of strings to use as topics for the current entry |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of LogEntryEventBuilder, useful for chaining methods

#### `shouldSave()` → `Boolean`

 Determines if this instance of LogEntryEventBuilder should be saved the next time that Logger.saveLog() is called

##### Return

**Type**

Boolean

**Description**

Boolean

---
