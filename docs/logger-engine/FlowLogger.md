---
layout: default
---

## FlowLogger class

Handles some common logic used by `FlowLogEntry`, `FlowRecordLogEntry` and `FlowCollectionLogEntry`

### Related

[FlowLogEntry](FlowLogEntry)

[FlowRecordLogEntry](FlowRecordLogEntry)

[FlowCollectionLogEntry](FlowCollectionLogEntry)

[Logger](Logger)

[LogEntryEventBuilder](LogEntryEventBuilder)

---

### Methods

#### `addEntries(List<LogEntry> flowEntries)` → `List<String>`

Adds logging entries

##### Parameters

| Param         | Description                     |
| ------------- | ------------------------------- |
| `flowEntries` | The log entry instances to add. |

##### Return

**Type**

List&lt;String&gt;

**Description**

A list of transaction ids.

---

### Inner Classes

#### FlowLogger.LogEntry class

Inner, wrapper class containing Log Entry information.

---

##### Properties

###### `faultMessage` → `String`

String containing fault message, if applicable

###### `flowName` → `String`

API name of the flow

###### `loggingLevelName` → `String`

String name of the entry&apos;s logging level

###### `message` → `String`

General message to log

###### `saveLog` → `Boolean`

Boolean used to determine if logs are saved to Salesforce

###### `saveMethodName` → `String`

String name of the instance of Logger.SaveMethod to use when &apos;Save Log&apos; == true

###### `scenario` → `String`

Optionally specify the scenario to use for the current transaction

###### `tagsString` → `String`

Comma-separated string of tags

###### `timestamp` → `DateTime`

timestamp of the log

###### `topics` → `List<String>`

List of tags / topics

---

##### Methods

###### `addToLoggerBuffer()` → `LogEntryEventBuilder`

Adds the logger to the buffer

####### Return

**Type**

LogEntryEventBuilder

**Description**

An instance of LogEntryEventBuilder

---
