---
layout: default
---

## LogEntryEventBuilder class

Builder class that generates each `LogEntryEvent__e` record

### Related

[Logger](Logger)

---

### Constructors

#### `LogEntryEventBuilder(LoggerSettings__c userSettings, System.LoggingLevel entryLoggingLevel, Boolean shouldSave)`

Used by `Logger` to instantiate a new instance of `LogEntryEventBuilder`

##### Parameters

| Param               | Description                                                                             |
| ------------------- | --------------------------------------------------------------------------------------- |
| `userSettings`      | The instance of `LoggerSettings__c` for the current to use to control any feature flags |
| `entryLoggingLevel` | The `LoggingLevel` value to use for the log entry                                       |
| `shouldSave`        | Indicates if the builder&apos;s instance of `LogEntryEvent__e` should be saved          |

---

### Properties

#### `aggregateQueriesMax` → `Integer`

#### `asyncCallsMax` → `Integer`

#### `calloutsMax` → `Integer`

#### `cpuTimeMax` → `Integer`

#### `dmlRowsMax` → `Integer`

#### `dmlStatementsMax` → `Integer`

#### `emailInvocationsMax` → `Integer`

#### `futureCallsMax` → `Integer`

#### `heapSizeMax` → `Integer`

#### `mobilePushApexCallsMax` → `Integer`

#### `publishImmediateDmlStatementsMax` → `Integer`

#### `queueableJobsMax` → `Integer`

#### `soqlQueriesMax` → `Integer`

#### `soqlQueryLocatorRowsMax` → `Integer`

#### `soqlQueryRowsMax` → `Integer`

#### `soslSearchesMax` → `Integer`

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

#### `setDatabaseResult(Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param                   | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param               | Description                                         |
| ------------------- | --------------------------------------------------- |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log |

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

#### `setDatabaseResult(List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param                    | Description                                          |
| ------------------------ | ---------------------------------------------------- |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult`s to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setDatabaseResult(List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s database operation result fields

##### Parameters

| Param                | Description                                      |
| -------------------- | ------------------------------------------------ |
| `leadConvertResults` | The list of `Database.LeadConvertResult`s to log |

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

#### `setExceptionDetails(System.Exception apexException)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s exception fields

##### Parameters

| Param           | Description                                   |
| --------------- | --------------------------------------------- |
| `apexException` | The instance of an `System.Exception` to use. |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setField(Schema.SObjectField field, Object fieldValue)` → `LogEntryEventBuilder`

Sets a field value on the builder&apos;s `LogEntryEvent__e` record

##### Parameters

| Param        | Description                                              |
| ------------ | -------------------------------------------------------- |
| `field`      | The `Schema.SObjectField` token of the field to populate |
| `fieldValue` | The `Object` value to populate in the provided field     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setField(Map<Schema.SObjectField, Object> fieldToValue)` → `LogEntryEventBuilder`

Sets multiple field values on the builder&apos;s `LogEntryEvent__e` record

##### Parameters

| Param          | Description                                                            |
| -------------- | ---------------------------------------------------------------------- |
| `fieldToValue` | An instance of `Map&lt;Schema.SObjectField, Object&gt;` containing the |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setHttpRequestDetails(System.HttpRequest request)` → `LogEntryEventBuilder`

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

#### `setHttpRequestDetails(System.HttpRequest request, List<String> headersToLog)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s HTTP Request fields

##### Parameters

| Param          | Description                                                           |
| -------------- | --------------------------------------------------------------------- |
| `request`      | The instance of `HttpRequest` to log                                  |
| `headersToLog` | An instance of `List&lt;String&gt;` containing the header keys to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setHttpResponseDetails(System.HttpResponse response)` → `LogEntryEventBuilder`

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

#### `setLoggingContext(LoggingContext loggingContext)` → `void`

**This is only intended to be used internally by Nebula Logger, and is subject to change.**

##### Parameters

| Param            | Description                                    |
| ---------------- | ---------------------------------------------- |
| `loggingContext` | Variables specific to the current Logger state |

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

#### `setRecord(Map<Id, SObject> recordIdToRecord)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s record fields

##### Parameters

| Param              | Description                                                                                                |
| ------------------ | ---------------------------------------------------------------------------------------------------------- |
| `recordIdToRecord` | The map of `SObject` records related to the entry. The JSON of the map is automatically added to the entry |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setRecord(System.Iterable<Id> recordsIds)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s record fields

##### Parameters

| Param        | Description                                                                                                                                   |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `recordsIds` | The Set of `SObject` records ids related to the entry. Will be converted to list and the JSON of the list is automatically added to the entry |

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

#### `setRestRequestDetails(System.RestRequest request)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s REST Request fields

##### Parameters

| Param     | Description                                 |
| --------- | ------------------------------------------- |
| `request` | The instance of `System.RestRequest` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setRestResponseDetails(System.RestResponse response)` → `LogEntryEventBuilder`

Sets the log entry event&apos;s REST Response fields

##### Parameters

| Param      | Description                                  |
| ---------- | -------------------------------------------- |
| `response` | The instance of `System.RestResponse` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

#### `setTimestamp(Datetime timestamp)` → `LogEntryEventBuilder`

**This is only intended to be used internally by Nebula Logger, and is subject to change.**

##### Parameters

| Param       | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `timestamp` | Datetime instance to set timestamp fields on this.logEntryEvent |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The same instance of `LogEntryEventBuilder`, useful for chaining methods

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

### Inner Classes

#### LogEntryEventBuilder.LoggingContext class

---

##### Constructors

###### `LoggingContext(String loggerVersionNumber,String organizationApiVersion,String organizationDomainUrl,String requestId,System.Quiddity systemMode,String transactionId)`

---

##### Properties

###### `currentEntryScenario` → `String`

###### `entryNumber` → `Integer`

###### `loggerVersionNumber` → `String`

###### `organizationApiVersion` → `String`

###### `organizationDomainUrl` → `String`

###### `requestId` → `String`

###### `systemMode` → `System.Quiddity`

###### `transactionId` → `String`

###### `userLoggingLevel` → `System.LoggingLevel`

---
