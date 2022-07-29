---
layout: default
---

## LogEntryEventBuilder class

Builder class that generates each `LogEntryEvent__e` record

### Related

[Logger](Logger)

---

### Constructors

#### `LogEntryEventBuilder(LoggerSettings__c userSettings, LoggingLevel entryLoggingLevel, Boolean shouldSave, Set<String> ignoredOrigins)`

Used by `Logger` to instantiate a new instance of `LogEntryEventBuilder`

##### Parameters

| Param               | Description                                                                                                        |
| ------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `userSettings`      | The instance of `LoggerSettings__c` for the current to use to control any feature flags                            |
| `entryLoggingLevel` | The `LoggingLevel` value to use for the log entry                                                                  |
| `shouldSave`        | Indicates if the builder&apos;s instance of `LogEntryEvent__e` should be saved                                     |
| `ignoredOrigins`    | A `Set&lt;String&gt;` of the names of any Apex classes that should be ignored when parsing the entry&apos;s origin |

---

### Methods

#### `addTag(String tag)` → `LogEntryEventBuilder`

Appends the tag to the existing list of tags

##### Parameters

| Param | Description                                      |
| ----- | ------------------------------------------------ |
| `tag` | The string to use as a tag for the current entry |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `addTags(List<String> tags)` → `LogEntryEventBuilder`

Appends the tag to the existing list of tags

##### Parameters

| Param  | Description                                              |
| ------ | -------------------------------------------------------- |
| `tags` | The list of strings to use as tags for the current entry |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `getLogEntryEvent()` → `LogEntryEvent__e`

Returns the `LogEntryEvent__e` record for this instance of LogEntryEventBuilder

##### Return

**Type**

LogEntryEvent\_\_e

**Description**

The `LogEntryEvent__e` record

#### `parseStackTrace(String stackTraceString)` → `LogEntryEventBuilder`

Parses the provided stack trace and sets the log entry&apos;s origin &amp; stack trace fields

##### Parameters

| Param              | Description                          |
| ------------------ | ------------------------------------ |
| `stackTraceString` | The Apex stack trace string to parse |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param          | Description                                    |
| -------------- | ---------------------------------------------- |
| `deleteResult` | The instance of `Database.DeleteResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param         | Description                                   |
| ------------- | --------------------------------------------- |
| `mergeResult` | The instance of `Database.MergeResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param        | Description                                  |
| ------------ | -------------------------------------------- |
| `saveResult` | The instance of `Database.SaveResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param          | Description                                    |
| -------------- | ---------------------------------------------- |
| `upsertResult` | The instance of `Database.UpsertResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param            | Description                                      |
| ---------------- | ------------------------------------------------ |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `deleteResults` | The list of `Database.DeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param          | Description                                         |
| -------------- | --------------------------------------------------- |
| `mergeResults` | The list of `Database.MergeResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param         | Description                                        |
| ------------- | -------------------------------------------------- |
| `saveResults` | The list of `Database.SaveResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `upsertResults` | The list of `Database.UpsertResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param             | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setExceptionDetails(Exception apexException)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s exception fields

##### Parameters

| Param           | Description                            |
| --------------- | -------------------------------------- |
| `apexException` | The instance of an `Exception` to use. |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setHttpRequestDetails(HttpRequest request)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s HTTP Request fields

##### Parameters

| Param     | Description                          |
| --------- | ------------------------------------ |
| `request` | The instance of `HttpRequest` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setHttpResponseDetails(HttpResponse response)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s HTTP Response fields

##### Parameters

| Param      | Description                           |
| ---------- | ------------------------------------- |
| `response` | The instance of `HttpResponse` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setMessage(LogMessage logMessage)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s message field

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setMessage(String message)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s message field

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setRecord(Id recordId)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s record fields

##### Parameters

| Param      | Description                                       |
| ---------- | ------------------------------------------------- |
| `recordId` | The ID of the SObject record related to the entry |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setRecord(SObject record)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s record fields

##### Parameters

| Param    | Description                                                                                           |
| -------- | ----------------------------------------------------------------------------------------------------- |
| `record` | The `SObject` record related to the entry. The JSON of the record is automatically added to the entry |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setRecord(List<SObject> records)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s record fields

##### Parameters

| Param     | Description                                                                                                  |
| --------- | ------------------------------------------------------------------------------------------------------------ |
| `records` | The list of `SObject` records related to the entry. The JSON of the list is automatically added to the entry |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setRecordId(Id recordId)` → `LogEntryEventBuilder`

Deprecated - use `setRecord(Id recordId)` instead

##### Parameters

| Param      | Description                  |
| ---------- | ---------------------------- |
| `recordId` | The id of the record to set. |

##### Return

**Type**

LogEntryEventBuilder

**Description**

An instance of LogEntryEventBuilder with a record associated wit recordId.

#### `setRecordId(SObject record)` → `LogEntryEventBuilder`

Deprecated - use `setRecord(SObject record)` instead

##### Parameters

| Param    | Description        |
| -------- | ------------------ |
| `record` | the record to set. |

##### Return

**Type**

LogEntryEventBuilder

**Description**

An instance of LogEntryEventBuilder with the given record.

#### `setTopics(List<String> tags)` → `LogEntryEventBuilder`

Deprecated - use `addTags(List&lt;String&gt; tags)` instead. This method will be removed in a future release

##### Parameters

| Param  | Description    |
| ------ | -------------- |
| `tags` | A list of tags |

##### Return

**Type**

LogEntryEventBuilder

**Description**

An instance of LogEntryEventBuilder with the given topics / tags.

#### `shouldSave()` → `Boolean`

Determines if this instance of `LogEntryEventBuilder` should be saved the next time that `Logger.saveLog()` is called

##### Return

**Type**

Boolean

**Description**

A boolean set to true if the log entries should be saved.

---
