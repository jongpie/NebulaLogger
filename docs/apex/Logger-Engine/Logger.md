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

Enum used to control how LogEntryEvent\_\_e records are inserted

---

### Properties

#### `Products` → `List<StatusApiResponseProduct>`

#### `allOrNone` → `Boolean`

Boolean used when saving records. If true, all records must save correctly or an exception is thrown. If false, partial processing is enabled, and if an indidividual record fails, successful records are still saved without exception.

#### `childJobId` → `String`

#### `finalizerException` → `Exception`

#### `finalizerResult` → `String`

#### `finalizerUnhandledException` → `Map<String, Object>`

#### `location` → `String`

#### `maintenanceWindow` → `String`

#### `parentJobId` → `String`

#### `records` → `List<SObject>`

List of records to save.

#### `releaseNumber` → `String`

#### `releaseVersion` → `String`

#### `triggerId` → `String`

#### `type` → `String`

---

### Methods

#### `AsyncContext(Database.BatchableContext batchableContext)` → `public`

#### `AsyncContext(System.FinalizerContext finalizerContext)` → `public`

#### `AsyncContext(System.QueueableContext queueableContext)` → `public`

#### `AsyncContext(System.SchedulableContext schedulableContext)` → `public`

#### `callStatusApi()` → `StatusApiResponse`

**This is only intended to be used internally by Nebula Logger, and is subject to change.** Calls Salesforce&apos;s API endpoint https://api.status.salesforce.com/v1/instances/ to get more details about the current org, including the org&apos;s release number and release version. Trust API docs available at https://api.status.salesforce.com/v1/docs/

##### Return

**Type**

StatusApiResponse

**Description**

An instance of `Logger.StatusApiResponse` (a DTO that maps to the JSON returned by the status API endpoint),

#### `createSettings()` → `LoggerSettings__c`

**This is only intended to be used internally by Nebula Logger, and is subject to change.** Creates a new, unsaved `LoggerSettings__c` record

##### Return

**Type**

LoggerSettings\_\_c

**Description**

A new `LoggerSettings__c` record, with all fields populated with default field values

#### `debug(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param                   | Description                                                               |
| ----------------------- | ------------------------------------------------------------------------- |
| `logMessage`            | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param               | Description                                                               |
| ------------------- | ------------------------------------------------------------------------- |
| `logMessage`        | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log                              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param            | Description                                                               |
| ---------------- | ------------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResults` | The instance of `List&lt;Database.DeleteResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param                    | Description                                                               |
| ------------------------ | ------------------------------------------------------------------------- |
| `logMessage`             | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param                | Description                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| `logMessage`         | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResults` | The instance of `List&lt;Database.MergeResult&gt;` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResults` | The instance of `List&lt;Database.SaveResult&gt;` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param             | Description                                                               |
| ----------------- | ------------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResults` | The instance of `List&lt;Database.UndeleteResult&gt;` to log              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResults` | The instance of `List&lt;Database.UpsertResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `recordId`   | The record ID of an `SObject` to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `record`     | The `SObject` record to log                                               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `records`    | The list of `SObject` records to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param                   | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `message`               | The string to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param               | Description                                             |
| ------------------- | ------------------------------------------------------- |
| `message`           | The string to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log           |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param        | Description                                             |
| ------------ | ------------------------------------------------------- |
| `message`    | The string to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param            | Description                                             |
| ---------------- | ------------------------------------------------------- |
| `message`        | The string to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `deleteResults` | The list of `Database.DeleteResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param                    | Description                                                   |
| ------------------------ | ------------------------------------------------------------- |
| `message`                | The string to use to set the entry&apos;s message field       |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param                | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `message`            | The string to use to set the entry&apos;s message field    |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `mergeResults` | The list of `Database.MergeResult` instances to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `saveResults` | The list of `Database.SaveResult` instances to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param             | Description                                             |
| ----------------- | ------------------------------------------------------- |
| `message`         | The string to use to set the entry&apos;s message field |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `upsertResults` | The list of `Database.UpsertResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param      | Description                                             |
| ---------- | ------------------------------------------------------- |
| `message`  | The string to use to set the entry&apos;s message field |
| `recordId` | The record ID of an `SObject` to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `record`  | The `SObject` record to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `records` | The list of `SObject` records to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `debug(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.DEBUG`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `endScenario(String scenario)` → `void`

End the specified scenario, if it&apos;s the currently active scenario, and rolls back to the previous scenario (if a previous scenario was specified in the current transaction)

##### Parameters

| Param      | Description                     |
| ---------- | ------------------------------- |
| `scenario` | The name of the scenario to end |

#### `error(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param                   | Description                                                               |
| ----------------------- | ------------------------------------------------------------------------- |
| `logMessage`            | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param               | Description                                                               |
| ------------------- | ------------------------------------------------------------------------- |
| `logMessage`        | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log                              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param            | Description                                                               |
| ---------------- | ------------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResults` | The instance of `List&lt;Database.DeleteResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param                    | Description                                                               |
| ------------------------ | ------------------------------------------------------------------------- |
| `logMessage`             | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param                | Description                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| `logMessage`         | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResults` | The instance of `List&lt;Database.MergeResult&gt;` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResults` | The instance of `List&lt;Database.SaveResult&gt;` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param             | Description                                                               |
| ----------------- | ------------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResults` | The instance of `List&lt;Database.UndeleteResult&gt;` to log              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResults` | The instance of `List&lt;Database.UpsertResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `apexException` | The instance of `System.Exception` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Id recordId, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `recordId`      | The record ID of an `SObject` to log                                      |
| `apexException` | The instance of `System.Exception` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `recordId`   | The record ID of an `SObject` to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, SObject record, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `record`        | The `SObject` record to log                                               |
| `apexException` | The instance of `System.Exception` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `record`     | The `SObject` record to log                                               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<SObject> records, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `records`       | The list of `SObject` records to log                                      |
| `apexException` | The instance of `System.Exception` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `records`    | The list of `SObject` records to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param                   | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `message`               | The string to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param               | Description                                             |
| ------------------- | ------------------------------------------------------- |
| `message`           | The string to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log           |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param        | Description                                             |
| ------------ | ------------------------------------------------------- |
| `message`    | The string to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param            | Description                                             |
| ---------------- | ------------------------------------------------------- |
| `message`        | The string to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `deleteResults` | The list of `Database.DeleteResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param                    | Description                                                   |
| ------------------------ | ------------------------------------------------------------- |
| `message`                | The string to use to set the entry&apos;s message field       |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param                | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `message`            | The string to use to set the entry&apos;s message field    |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `mergeResults` | The list of `Database.MergeResult` instances to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `saveResults` | The list of `Database.SaveResult` instances to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param             | Description                                             |
| ----------------- | ------------------------------------------------------- |
| `message`         | The string to use to set the entry&apos;s message field |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `upsertResults` | The list of `Database.UpsertResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `apexException` | The instance of `System.Exception` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Id recordId, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `recordId`      | The record ID of an `SObject` to log                    |
| `apexException` | The instance of `System.Exception` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param      | Description                                             |
| ---------- | ------------------------------------------------------- |
| `message`  | The string to use to set the entry&apos;s message field |
| `recordId` | The record ID of an `SObject` to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, SObject record, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `record`        | The `SObject` record to log                             |
| `apexException` | The instance of `System.Exception` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `record`  | The `SObject` record to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<SObject> records, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `message`       | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `records`       | The list of `SObject` records to log                                      |
| `apexException` | The instance of `System.Exception` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `records` | The list of `SObject` records to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `error(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `exception(LogMessage logMessage, System.Exception apexException)` → `void`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`, automatically saves the log, and then throws the provided exception

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `apexException` | The instance of `System.Exception` to log and throw                       |

#### `exception(LogMessage logMessage, Id recordId, System.Exception apexException)` → `void`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`, automatically saves the log, and then throws the provided exception

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `recordId`      | The record ID of an `SObject` to log                                      |
| `apexException` | The instance of `System.Exception` to log and throw                       |

#### `exception(LogMessage logMessage, SObject record, System.Exception apexException)` → `void`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`, automatically saves the log, and then throws the provided exception

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `record`        | The `SObject` record to log                                               |
| `apexException` | The instance of `System.Exception` to log and throw                       |

#### `exception(LogMessage logMessage, List<SObject> records, System.Exception apexException)` → `void`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`, automatically saves the log, and then throws the provided exception

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `records`       | The list of `SObject` records to log                                      |
| `apexException` | The instance of `System.Exception` to log and throw                       |

#### `exception(String message, System.Exception apexException)` → `void`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`, automatically saves the log, and then throws the provided exception

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `apexException` | The instance of `System.Exception` to log and throw     |

#### `exception(String message, Id recordId, System.Exception apexException)` → `void`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`, automatically saves the log, and then throws the provided exception

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `recordId`      | The record ID of an `SObject` to log                    |
| `apexException` | The instance of `System.Exception` to log and throw     |

#### `exception(String message, SObject record, System.Exception apexException)` → `void`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`, automatically saves the log, and then throws the provided exception

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `record`        | The `SObject` record to log                             |
| `apexException` | The instance of `System.Exception` to log and throw     |

#### `exception(String message, List<SObject> records, System.Exception apexException)` → `void`

Creates a new log entry with logging level == `System.LoggingLevel.ERROR`, automatically saves the log, and then throws the provided exception

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `message`       | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `records`       | The list of `SObject` records to log                                      |
| `apexException` | The instance of `System.Exception` to log and throw                       |

#### `execute(System.QueueableContext queueableContext)` → `void`

Asynchronoulsy publishes the list of `LogEntryEvent__e` records

##### Parameters

| Param              | Description                                                |
| ------------------ | ---------------------------------------------------------- |
| `queueableContext` | The context of the current queue, provided by the platform |

#### `fine(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param                   | Description                                                               |
| ----------------------- | ------------------------------------------------------------------------- |
| `logMessage`            | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param               | Description                                                               |
| ------------------- | ------------------------------------------------------------------------- |
| `logMessage`        | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log                              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param            | Description                                                               |
| ---------------- | ------------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResults` | The instance of `List&lt;Database.DeleteResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param                    | Description                                                               |
| ------------------------ | ------------------------------------------------------------------------- |
| `logMessage`             | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param                | Description                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| `logMessage`         | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResults` | The instance of `List&lt;Database.MergeResult&gt;` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResults` | The instance of `List&lt;Database.SaveResult&gt;` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param             | Description                                                               |
| ----------------- | ------------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResults` | The instance of `List&lt;Database.UndeleteResult&gt;` to log              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResults` | The instance of `List&lt;Database.UpsertResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `recordId`   | The record ID of an `SObject` to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `record`     | The `SObject` record to log                                               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `records`    | The list of `SObject` records to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param                   | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `message`               | The string to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param               | Description                                             |
| ------------------- | ------------------------------------------------------- |
| `message`           | The string to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log           |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param        | Description                                             |
| ------------ | ------------------------------------------------------- |
| `message`    | The string to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param            | Description                                             |
| ---------------- | ------------------------------------------------------- |
| `message`        | The string to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `deleteResults` | The list of `Database.DeleteResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param                    | Description                                                   |
| ------------------------ | ------------------------------------------------------------- |
| `message`                | The string to use to set the entry&apos;s message field       |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param                | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `message`            | The string to use to set the entry&apos;s message field    |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `mergeResults` | The list of `Database.MergeResult` instances to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `saveResults` | The list of `Database.SaveResult` instances to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param             | Description                                             |
| ----------------- | ------------------------------------------------------- |
| `message`         | The string to use to set the entry&apos;s message field |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `upsertResults` | The list of `Database.UpsertResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param      | Description                                             |
| ---------- | ------------------------------------------------------- |
| `message`  | The string to use to set the entry&apos;s message field |
| `recordId` | The record ID of an `SObject` to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `record`  | The `SObject` record to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `records` | The list of `SObject` records to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `fine(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINE`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param                   | Description                                                               |
| ----------------------- | ------------------------------------------------------------------------- |
| `logMessage`            | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param               | Description                                                               |
| ------------------- | ------------------------------------------------------------------------- |
| `logMessage`        | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log                              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param            | Description                                                               |
| ---------------- | ------------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResults` | The instance of `List&lt;Database.DeleteResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param                    | Description                                                               |
| ------------------------ | ------------------------------------------------------------------------- |
| `logMessage`             | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param                | Description                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| `logMessage`         | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResults` | The instance of `List&lt;Database.MergeResult&gt;` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResults` | The instance of `List&lt;Database.SaveResult&gt;` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param             | Description                                                               |
| ----------------- | ------------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResults` | The instance of `List&lt;Database.UndeleteResult&gt;` to log              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResults` | The instance of `List&lt;Database.UpsertResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `recordId`   | The record ID of an `SObject` to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `record`     | The `SObject` record to log                                               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `records`    | The list of `SObject` records to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param                   | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `message`               | The string to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param               | Description                                             |
| ------------------- | ------------------------------------------------------- |
| `message`           | The string to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log           |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param        | Description                                             |
| ------------ | ------------------------------------------------------- |
| `message`    | The string to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param            | Description                                             |
| ---------------- | ------------------------------------------------------- |
| `message`        | The string to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `deleteResults` | The list of `Database.DeleteResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param                    | Description                                                   |
| ------------------------ | ------------------------------------------------------------- |
| `message`                | The string to use to set the entry&apos;s message field       |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param                | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `message`            | The string to use to set the entry&apos;s message field    |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `mergeResults` | The list of `Database.MergeResult` instances to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `saveResults` | The list of `Database.SaveResult` instances to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param             | Description                                             |
| ----------------- | ------------------------------------------------------- |
| `message`         | The string to use to set the entry&apos;s message field |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `upsertResults` | The list of `Database.UpsertResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param      | Description                                             |
| ---------- | ------------------------------------------------------- |
| `message`  | The string to use to set the entry&apos;s message field |
| `recordId` | The record ID of an `SObject` to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `record`  | The `SObject` record to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `records` | The list of `SObject` records to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finer(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINER`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param                   | Description                                                               |
| ----------------------- | ------------------------------------------------------------------------- |
| `logMessage`            | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param               | Description                                                               |
| ------------------- | ------------------------------------------------------------------------- |
| `logMessage`        | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log                              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param            | Description                                                               |
| ---------------- | ------------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResults` | The instance of `List&lt;Database.DeleteResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param                    | Description                                                               |
| ------------------------ | ------------------------------------------------------------------------- |
| `logMessage`             | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param                | Description                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| `logMessage`         | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResults` | The instance of `List&lt;Database.MergeResult&gt;` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResults` | The instance of `List&lt;Database.SaveResult&gt;` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param             | Description                                                               |
| ----------------- | ------------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResults` | The instance of `List&lt;Database.UndeleteResult&gt;` to log              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResults` | The instance of `List&lt;Database.UpsertResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `recordId`   | The record ID of an `SObject` to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `record`     | The `SObject` record to log                                               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `records`    | The list of `SObject` records to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param                   | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `message`               | The string to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param               | Description                                             |
| ------------------- | ------------------------------------------------------- |
| `message`           | The string to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log           |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param        | Description                                             |
| ------------ | ------------------------------------------------------- |
| `message`    | The string to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param            | Description                                             |
| ---------------- | ------------------------------------------------------- |
| `message`        | The string to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `deleteResults` | The list of `Database.DeleteResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param                    | Description                                                   |
| ------------------------ | ------------------------------------------------------------- |
| `message`                | The string to use to set the entry&apos;s message field       |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param                | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `message`            | The string to use to set the entry&apos;s message field    |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `mergeResults` | The list of `Database.MergeResult` instances to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `saveResults` | The list of `Database.SaveResult` instances to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param             | Description                                             |
| ----------------- | ------------------------------------------------------- |
| `message`         | The string to use to set the entry&apos;s message field |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `upsertResults` | The list of `Database.UpsertResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param      | Description                                             |
| ---------- | ------------------------------------------------------- |
| `message`  | The string to use to set the entry&apos;s message field |
| `recordId` | The record ID of an `SObject` to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `record`  | The `SObject` record to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `records` | The list of `SObject` records to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `finest(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.FINEST`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `flushBuffer()` → `void`

Discards any entries that have been generated but not yet saved

#### `getBufferSize()` → `Integer`

Returns the number of entries that have been generated but not yet saved

##### Return

**Type**

Integer

**Description**

Integer

#### `getCurrentQuiddity()` → `System.Quiddity`

Returns the System.Quiddity context of the current transaction.

##### Return

**Type**

System.Quiddity

**Description**

System.Quiddity - The value of System.Request.getCurrent().getQuiddity()

#### `getLoggingLevel(String loggingLevelName)` → `System.LoggingLevel`

Converts a String to an instance of LoggingLevel

##### Parameters

| Param              | Description                              |
| ------------------ | ---------------------------------------- |
| `loggingLevelName` | The string name of an Apex logging level |

##### Return

**Type**

System.LoggingLevel

**Description**

The matching instance of System.LoggingLevel (or a default value if a match is not found)

#### `getNamespacePrefix()` → `String`

**This is only intended to be used internally by Nebula Logger, and is subject to change.** Returns the current namespace of Nebula Logger

##### Return

**Type**

String

**Description**

The current namespace prefix, or an empty string when no namespace is being used

#### `getOrganizationApiVersion()` → `String`

**This is only intended to be used internally by Nebula Logger, and is subject to change.** Returns the current Salesforce API version number of the org

##### Return

**Type**

String

**Description**

The current API version, in the format `v00.0`

#### `getParentLogTransactionId()` → `String`

Returns the transaction ID value that will be used to relate the current transaction&apos;s log to a parent log

##### Return

**Type**

String

**Description**

String - The parent log&apos;s transaction ID. This must be explicitly set by calling setParentLogTransactionId(String)

#### `getRequestId()` → `String`

Returns the request ID generated by Salesforce for a particular transaction. This value is stored in `LogEntryEvent__e.RequestId__c` and `Log__c.RequestId__c`.

##### Return

**Type**

String

**Description**

String - The value returned by `System.Request.getCurrent().getRequestId()`

#### `getSaveMethod()` → `SaveMethod`

Returns the default save method used when calling saveLog() - set via LoggerSettings\_\_c or by calling setSaveMethod(SaveMethod saveMethod)

##### Return

**Type**

SaveMethod

**Description**

The enum value of Logger.SaveMethod to use for any calls to saveLog() in the current transaction

#### `getScenario()` → `String`

Returns the scenario name for the current transaction - this is stored in `LogEntryEvent__e.Scenario__c` and `Log__c.Scenario__c`, and can be used to filter &amp; group logs

##### Return

**Type**

String

**Description**

The value currently set as the current transaction&apos;s scenario

#### `getTransactionId()` → `String`

Returns the unique ID generated by Nebula Logger for a particular transaction. This value is stored in `LogEntryEvent__e.TransactionId__c` and `Log__c.TransactionId__c`.

##### Return

**Type**

String

**Description**

String - A `UUID` value generated by Nebula Logger, using `System.UUID.randomUUID().toString()`

#### `getUserLoggingLevel()` → `System.LoggingLevel`

Returns the logging level for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

System.LoggingLevel

**Description**

System.LoggingLevel - The matching instance of LoggingLevel

#### `getUserSettings()` → `LoggerSettings__c`

**This is only intended to be used internally by Nebula Logger, and is subject to change.** Returns the current user&apos;s instance of `LoggerSettings__c`

##### Return

**Type**

LoggerSettings\_\_c

**Description**

LoggerSettings\_\_c - The current user&apos;s instance of the custom settings

#### `getUserSettings(Schema.User loggingUser)` → `LoggerSettings__c`

**This is only intended to be used internally by Nebula Logger, and is subject to change.** Returns the specified user&apos;s instance of `LoggerSettings__c`

##### Parameters

| Param         | Description                                                                                      |
| ------------- | ------------------------------------------------------------------------------------------------ |
| `loggingUser` | The user record - at a minimum, this record should have the user Id and Profile fields populated |

##### Return

**Type**

LoggerSettings\_\_c

**Description**

LoggerSettings\_\_c - The specified user&apos;s instance of the custom settings

#### `getVersionNumber()` → `String`

Returns the current version number of Nebula Logger

##### Return

**Type**

String

**Description**

The current version number, in the format `v0.0.0`

#### `ignoreOrigin(System.Type apexType)` → `void`

Adds the specified Apex type to the list of ignored origin locations for the current transaction. Any ignored types will be removed from the StackTrace\_\_c field, and will be skipped when determining the log entry&apos;s origin location

##### Parameters

| Param      | Description                          |
| ---------- | ------------------------------------ |
| `apexType` | The Apex type of the class to ignore |

#### `info(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param                   | Description                                                               |
| ----------------------- | ------------------------------------------------------------------------- |
| `logMessage`            | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param               | Description                                                               |
| ------------------- | ------------------------------------------------------------------------- |
| `logMessage`        | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log                              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param            | Description                                                               |
| ---------------- | ------------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResults` | The instance of `List&lt;Database.DeleteResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param                    | Description                                                               |
| ------------------------ | ------------------------------------------------------------------------- |
| `logMessage`             | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param                | Description                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| `logMessage`         | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResults` | The instance of `List&lt;Database.MergeResult&gt;` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResults` | The instance of `List&lt;Database.SaveResult&gt;` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param             | Description                                                               |
| ----------------- | ------------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResults` | The instance of `List&lt;Database.UndeleteResult&gt;` to log              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResults` | The instance of `List&lt;Database.UpsertResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `recordId`   | The record ID of an `SObject` to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `record`     | The `SObject` record to log                                               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `records`    | The list of `SObject` records to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param                   | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `message`               | The string to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param               | Description                                             |
| ------------------- | ------------------------------------------------------- |
| `message`           | The string to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log           |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param        | Description                                             |
| ------------ | ------------------------------------------------------- |
| `message`    | The string to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param            | Description                                             |
| ---------------- | ------------------------------------------------------- |
| `message`        | The string to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `deleteResults` | The list of `Database.DeleteResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param                    | Description                                                   |
| ------------------------ | ------------------------------------------------------------- |
| `message`                | The string to use to set the entry&apos;s message field       |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param                | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `message`            | The string to use to set the entry&apos;s message field    |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `mergeResults` | The list of `Database.MergeResult` instances to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `saveResults` | The list of `Database.SaveResult` instances to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param             | Description                                             |
| ----------------- | ------------------------------------------------------- |
| `message`         | The string to use to set the entry&apos;s message field |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `upsertResults` | The list of `Database.UpsertResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param      | Description                                             |
| ---------- | ------------------------------------------------------- |
| `message`  | The string to use to set the entry&apos;s message field |
| `recordId` | The record ID of an `SObject` to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `record`  | The `SObject` record to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `records` | The list of `SObject` records to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `info(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.INFO`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `insertRecords(List<SObject> records)` → `void`

Inserts records via the REST api.

##### Parameters

| Param     | Description          |
| --------- | -------------------- |
| `records` | The records to save. |

#### `isDebugEnabled()` → `Boolean`

Indicates if logging level &apos;DEBUG&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isEnabled()` → `Boolean`

Indicates if logging has been enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isEnabled(System.LoggingLevel loggingLevel)` → `Boolean`

Indicates if logging for the specified logging level is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Parameters

| Param          | Description                  |
| -------------- | ---------------------------- |
| `loggingLevel` | - The logging level to check |

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isErrorEnabled()` → `Boolean`

Indicates if logging level &apos;ERROR&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isFineEnabled()` → `Boolean`

Indicates if logging level &apos;FINE&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isFinerEnabled()` → `Boolean`

Indicates if logging level &apos;FINER&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isFinestEnabled()` → `Boolean`

Indicates if logging level &apos;FINEST&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `isInfoEnabled()` → `Boolean`

Indicates if logging level &apos;INFO&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

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

Indicates if logging level &apos;WARN&apos; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Return

**Type**

Boolean

**Description**

Boolean

#### `logDatabaseErrors(System.LoggingLevel loggingLevel,LogMessage logMessage,List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a log entry for any results within the provided `List&lt;LeadConvertResult&gt;` where `isSuccess() != true`

##### Parameters

| Param                | Description                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| `loggingLevel`       | The logging level to use for the log entry                                |
| `logMessage`         | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResults` | The instance of `List&lt;Database.LeadConvertResult&gt;` to log           |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

#### `logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a log entry for any results within the provided `List&lt;LeadConvertResult&gt;` where `isSuccess() != true`

##### Parameters

| Param                | Description                                                     |
| -------------------- | --------------------------------------------------------------- |
| `loggingLevel`       | The logging level to use for the log entry                      |
| `message`            | The string to use to set the entry&apos;s message field         |
| `leadConvertResults` | The instance of `List&lt;Database.LeadConvertResult&gt;` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

#### `logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a log entry for any results within the provided `List&lt;DeleteResult&gt;` where `isSuccess() != true`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `loggingLevel`  | The logging level to use for the log entry                                |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResults` | The instance of `List&lt;Database.DeleteResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

#### `logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a log entry for any results within the provided `List&lt;DeleteResult&gt;` where `isSuccess() != true`

##### Parameters

| Param           | Description                                                |
| --------------- | ---------------------------------------------------------- |
| `loggingLevel`  | The logging level to use for the log entry                 |
| `message`       | The string to use to set the entry&apos;s message field    |
| `deleteResults` | The instance of `List&lt;Database.DeleteResult&gt;` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

#### `logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a log entry for any results within the provided `List&lt;MergeResult&gt;` where `isSuccess() != true`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `loggingLevel` | The logging level to use for the log entry                                |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResults` | The instance of `List&lt;Database.MergeResult&gt;` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

#### `logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a log entry for any results within the provided `List&lt;MergeResult&gt;` where `isSuccess() != true`

##### Parameters

| Param          | Description                                               |
| -------------- | --------------------------------------------------------- |
| `loggingLevel` | The logging level to use for the log entry                |
| `message`      | The string to use to set the entry&apos;s message field   |
| `mergeResults` | The instance of `List&lt;Database.MergeResult&gt;` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

#### `logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a log entry for any results within the provided `List&lt;SaveResult&gt;` where `isSuccess() != true`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `loggingLevel` | The logging level to use for the log entry                                |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResults`  | The instance of `List&lt;Database.SaveResult&gt;` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

#### `logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a log entry for any results within the provided `List&lt;SaveResult&gt;` where `isSuccess() != true`

##### Parameters

| Param          | Description                                              |
| -------------- | -------------------------------------------------------- |
| `loggingLevel` | The logging level to use for the log entry               |
| `message`      | The string to use to set the entry&apos;s message field  |
| `saveResults`  | The instance of `List&lt;Database.SaveResult&gt;` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

#### `logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a log entry for any results within the provided `List&lt;UpsertResult&gt;` where `isSuccess() != true`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `loggingLevel`  | The logging level to use for the log entry                                |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResults` | The instance of `List&lt;Database.UpsertResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

#### `logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a log entry for any results within the provided `List&lt;UpsertResult&gt;` where `isSuccess() != true`

##### Parameters

| Param           | Description                                                |
| --------------- | ---------------------------------------------------------- |
| `loggingLevel`  | The logging level to use for the log entry                 |
| `message`       | The string to use to set the entry&apos;s message field    |
| `upsertResults` | The instance of `List&lt;Database.UpsertResult&gt;` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

#### `logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a log entry for any results within the provided `List&lt;UndeleteResult&gt;` where `isSuccess() != true`

##### Parameters

| Param             | Description                                                               |
| ----------------- | ------------------------------------------------------------------------- |
| `loggingLevel`    | The logging level to use for the log entry                                |
| `logMessage`      | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResults` | The instance of `List&lt;Database.UndeleteResult&gt;` to log              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

#### `logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a log entry for any results within the provided `List&lt;UndeleteResult&gt;` where `isSuccess() != true`

##### Parameters

| Param             | Description                                                  |
| ----------------- | ------------------------------------------------------------ |
| `loggingLevel`    | The logging level to use for the log entry                   |
| `message`         | The string to use to set the entry&apos;s message field      |
| `undeleteResults` | The instance of `List&lt;Database.UndeleteResult&gt;` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

#### `meetsUserLoggingLevel(System.LoggingLevel logEntryLoggingLevel)` → `Boolean`

Indicates if the specified logging level is enabled for the current user, based on the custom setting LoggerSettings\_\_c

##### Parameters

| Param                  | Description                 |
| ---------------------- | --------------------------- |
| `logEntryLoggingLevel` | the logging level to check. |

##### Return

**Type**

Boolean

**Description**

Boolean

#### `newEntry(System.LoggingLevel loggingLevel, LogMessage logMessage, Boolean shouldSave)` → `LogEntryEventBuilder`

Adds a new instance of LogEntryEventBuilder to Logger&apos;s buffer, when `shouldSave` is `true`

##### Parameters

| Param          | Description                                                                                                                                                   |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `loggingLevel` | The logging level enum value for the new entry                                                                                                                |
| `logMessage`   | The instance of LogMessage to use as the entry&apos;s message                                                                                                 |
| `shouldSave`   | Controls if the new entry will be saved. This can be used to save entries, even if the entry&apos;s logging level does not meet the user&apos;s logging level |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of LogEntryEventBuilder

#### `newEntry(System.LoggingLevel loggingLevel, LogMessage logMessage)` → `LogEntryEventBuilder`

Adds a new instance of LogEntryEventBuilder to Logger&apos;s buffer, if it meets the user&apos;s logging level

##### Parameters

| Param          | Description                                                   |
| -------------- | ------------------------------------------------------------- |
| `loggingLevel` | The logging level enum value for the new entry                |
| `logMessage`   | The instance of LogMessage to use as the entry&apos;s message |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of LogEntryEventBuilder

#### `newEntry(System.LoggingLevel loggingLevel, String message, Boolean shouldSave)` → `LogEntryEventBuilder`

Adds a new instance of LogEntryEventBuilder to Logger&apos;s buffer, if it meets the user&apos;s logging level

##### Parameters

| Param          | Description                                                                                                                                                   |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `loggingLevel` | The logging level enum value for the new entry                                                                                                                |
| `message`      | The string to use as the entry&apos;s message                                                                                                                 |
| `shouldSave`   | Controls if the new entry will be saved. This can be used to save entries, even if the entry&apos;s logging level does not meet the user&apos;s logging level |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of LogEntryEventBuilder

#### `newEntry(System.LoggingLevel loggingLevel, String message)` → `LogEntryEventBuilder`

Adds a new instance of LogEntryEventBuilder to Logger&apos;s buffer, if it meets the user&apos;s logging level

##### Parameters

| Param          | Description                                    |
| -------------- | ---------------------------------------------- |
| `loggingLevel` | The logging level enum value for the new entry |
| `message`      | The string to use as the entry&apos;s message  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of LogEntryEventBuilder

#### `resumeSaving()` → `void`

Resumes saving for the current transaction, used to reverse suspendSaving(). Any calls to saveLog() are ignored until saving is resumed.

#### `saveLog()` → `void`

Saves any entries in Logger&apos;s buffer. By default, entries are saved via Apex&apos;s EventBus and can be overridden with setSaveMethod(SaveMethod saveMethod)

#### `saveLog(SaveMethod saveMethod)` → `void`

Saves any entries in Logger&apos;s buffer, using the specified save method for only this call. All subsequent calls to saveLog() will use the transaction save method.

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `saveMethod` | The enum value of Logger.SaveMethod to use for this specific save action. |

#### `saveLog(String saveMethodName)` → `void`

**This is only intended to be used internally by Nebula Logger, and is subject to change.** Saves any entries in Logger&apos;s buffer, using the specified save method for only this call. All subsequent calls to saveLog() will use the transaction save method.

##### Parameters

| Param            | Description                                                               |
| ---------------- | ------------------------------------------------------------------------- |
| `saveMethodName` | The String value of the save method to use for this specific save action. |

#### `setAsyncContext(Database.BatchableContext batchableContext)` → `void`

Stores additional details about the current transacation&apos;s async context

##### Parameters

| Param              | Description                                            |
| ------------------ | ------------------------------------------------------ |
| `batchableContext` | - The instance of `Database.BatchableContext` to track |

#### `setAsyncContext(System.FinalizerContext finalizerContext)` → `void`

Stores additional details about the current transacation&apos;s async context

##### Parameters

| Param              | Description                                          |
| ------------------ | ---------------------------------------------------- |
| `finalizerContext` | - The instance of `System.FinalizerContext` to track |

#### `setAsyncContext(System.QueueableContext queueableContext)` → `void`

Stores additional details about the current transacation&apos;s async context

##### Parameters

| Param              | Description                                          |
| ------------------ | ---------------------------------------------------- |
| `queueableContext` | - The instance of `System.QueueableContext` to track |

#### `setAsyncContext(System.SchedulableContext schedulableContext)` → `void`

Stores additional details about the current transacation&apos;s async context

##### Parameters

| Param                | Description                                            |
| -------------------- | ------------------------------------------------------ |
| `schedulableContext` | - The instance of `System.SchedulableContext` to track |

#### `setField(Schema.SObjectField field, Object fieldValue)` → `void`

Sets a field value on every generated `LogEntryEvent__e` record

##### Parameters

| Param        | Description                                              |
| ------------ | -------------------------------------------------------- |
| `field`      | The `Schema.SObjectField` token of the field to populate |
| `fieldValue` | The `Object` value to populate in the provided field     |

#### `setField(Map<Schema.SObjectField, Object> fieldToValue)` → `void`

Sets multiple field values oon every generated `LogEntryEvent__e` record

##### Parameters

| Param          | Description                                                            |
| -------------- | ---------------------------------------------------------------------- |
| `fieldToValue` | An instance of `Map&lt;Schema.SObjectField, Object&gt;` containing the |

#### `setParentLogTransactionId(String parentTransactionId)` → `void`

Relates the current transaction&apos;s log to a parent log via the field Log**c.ParentLog**c This is useful for relating multiple asynchronous operations together, such as batch &amp; queueable jobs.

##### Parameters

| Param                 | Description                                             |
| --------------------- | ------------------------------------------------------- |
| `parentTransactionId` | - The transaction ID of the original parent transaction |

#### `setSaveMethod(SaveMethod saveMethod)` → `void`

Sets the default save method used when calling saveLog() - any subsequent calls to saveLog() will use the specified save method

##### Parameters

| Param        | Description                                                                                            |
| ------------ | ------------------------------------------------------------------------------------------------------ |
| `saveMethod` | The enum value of Logger.SaveMethod to use for any other calls to saveLog() in the current transaction |

#### `setScenario(String scenario)` → `void`

Sets the current scenario, which can be used to identify modules or groupings of for the current transaction

##### Parameters

| Param      | Description                                                 |
| ---------- | ----------------------------------------------------------- |
| `scenario` | The name to use for the current transaction&apos;s scenario |

#### `suspendSaving()` → `void`

Pauses saving for the current transaction. Any calls to saveLog() are ignored until saving is resumed.

#### `warn(LogMessage logMessage, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param                   | Description                                                               |
| ----------------------- | ------------------------------------------------------------------------- |
| `logMessage`            | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log                   |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param               | Description                                                               |
| ------------------- | ------------------------------------------------------------------------- |
| `logMessage`        | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log                       |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log                              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param            | Description                                                               |
| ---------------- | ------------------------------------------------------------------------- |
| `logMessage`     | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log                          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log                            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `deleteResults` | The instance of `List&lt;Database.DeleteResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param                    | Description                                                               |
| ------------------------ | ------------------------------------------------------------------------- |
| `logMessage`             | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param                | Description                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| `logMessage`         | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param          | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| `logMessage`   | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `mergeResults` | The instance of `List&lt;Database.MergeResult&gt;` to log                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param         | Description                                                               |
| ------------- | ------------------------------------------------------------------------- |
| `logMessage`  | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `saveResults` | The instance of `List&lt;Database.SaveResult&gt;` to log                  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param             | Description                                                               |
| ----------------- | ------------------------------------------------------------------------- |
| `logMessage`      | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `undeleteResults` | The instance of `List&lt;Database.UndeleteResult&gt;` to log              |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `upsertResults` | The instance of `List&lt;Database.UpsertResult&gt;` to log                |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `apexException` | The instance of `System.Exception` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Id recordId, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `recordId`      | The record ID of an `SObject` to log                                      |
| `apexException` | The instance of `System.Exception` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `recordId`   | The record ID of an `SObject` to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, SObject record, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `record`        | The `SObject` record to log                                               |
| `apexException` | The instance of `System.Exception` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `record`     | The `SObject` record to log                                               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<SObject> records, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `logMessage`    | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `records`       | The list of `SObject` records to log                                      |
| `apexException` | The instance of `System.Exception` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `records`    | The list of `SObject` records to log                                      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(LogMessage logMessage)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param        | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| `logMessage` | The instance of `LogMessage` to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Database.DeleteResult deleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `deleteResult` | The instance of `Database.DeleteResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param                   | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `message`               | The string to use to set the entry&apos;s message field |
| `emptyRecycleBinResult` | The instance of `Database.EmptyRecycleBinResult` to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Database.LeadConvertResult leadConvertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param               | Description                                             |
| ------------------- | ------------------------------------------------------- |
| `message`           | The string to use to set the entry&apos;s message field |
| `leadConvertResult` | The instance of `Database.LeadConvertResult` to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Database.MergeResult mergeResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `mergeResult` | The instance of `Database.MergeResult` to log           |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Database.SaveResult saveResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param        | Description                                             |
| ------------ | ------------------------------------------------------- |
| `message`    | The string to use to set the entry&apos;s message field |
| `saveResult` | The instance of `Database.SaveResult` to log            |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Database.UndeleteResult undeleteResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param            | Description                                             |
| ---------------- | ------------------------------------------------------- |
| `message`        | The string to use to set the entry&apos;s message field |
| `undeleteResult` | The instance of `Database.UndeleteResult` to log        |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Database.UpsertResult upsertResult)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `upsertResult` | The instance of `Database.UpsertResult` to log          |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<Database.DeleteResult> deleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `deleteResults` | The list of `Database.DeleteResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param                    | Description                                                   |
| ------------------------ | ------------------------------------------------------------- |
| `message`                | The string to use to set the entry&apos;s message field       |
| `emptyRecycleBinResults` | The list of `Database.EmptyRecycleBinResult` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<Database.LeadConvertResult> leadConvertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param                | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `message`            | The string to use to set the entry&apos;s message field    |
| `leadConvertResults` | The list of `Database.LeadConvertResults` instances to log |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<Database.MergeResult> mergeResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param          | Description                                             |
| -------------- | ------------------------------------------------------- |
| `message`      | The string to use to set the entry&apos;s message field |
| `mergeResults` | The list of `Database.MergeResult` instances to log     |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<Database.SaveResult> saveResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param         | Description                                             |
| ------------- | ------------------------------------------------------- |
| `message`     | The string to use to set the entry&apos;s message field |
| `saveResults` | The list of `Database.SaveResult` instances to log      |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<Database.UndeleteResult> undeleteResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param             | Description                                             |
| ----------------- | ------------------------------------------------------- |
| `message`         | The string to use to set the entry&apos;s message field |
| `undeleteResults` | The list of `Database.UndeleteResult` instances to log  |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<Database.UpsertResult> upsertResults)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `upsertResults` | The list of `Database.UpsertResult` instances to log    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `apexException` | The instance of `System.Exception` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Id recordId, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `recordId`      | The record ID of an `SObject` to log                    |
| `apexException` | The instance of `System.Exception` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, Id recordId)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param      | Description                                             |
| ---------- | ------------------------------------------------------- |
| `message`  | The string to use to set the entry&apos;s message field |
| `recordId` | The record ID of an `SObject` to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, SObject record, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param           | Description                                             |
| --------------- | ------------------------------------------------------- |
| `message`       | The string to use to set the entry&apos;s message field |
| `record`        | The `SObject` record to log                             |
| `apexException` | The instance of `System.Exception` to log               |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, SObject record)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `record`  | The `SObject` record to log                             |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<SObject> records, System.Exception apexException)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param           | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| `message`       | The instance of `LogMessage` to use to set the entry&apos;s message field |
| `records`       | The list of `SObject` records to log                                      |
| `apexException` | The instance of `System.Exception` to log                                 |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message, List<SObject> records)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |
| `records` | The list of `SObject` records to log                    |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

#### `warn(String message)` → `LogEntryEventBuilder`

Creates a new log entry with logging level == `System.LoggingLevel.WARN`

##### Parameters

| Param     | Description                                             |
| --------- | ------------------------------------------------------- |
| `message` | The string to use to set the entry&apos;s message field |

##### Return

**Type**

LogEntryEventBuilder

**Description**

The new entry&apos;s instance of `LogEntryEventBuilder`, useful for chaining methods

---

### Inner Classes

#### Logger.LoggerException class

---

#### Logger.QueueableSaver class

Inner class for publishing log entries via the System.Queueable interface.

---

#### Logger.StatusApiResponseProduct class

---

##### Properties

###### `key` → `String`

###### `name` → `String`

---
