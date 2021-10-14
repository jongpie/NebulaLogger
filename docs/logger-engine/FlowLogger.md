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

name of the flow.

###### `loggingLevelName` → `String`

String containing the logging level.

###### `message` → `String`

General message to log.

###### `saveLog` → `Boolean`

boolean used to determine if logs are saved to Salesforce.

###### `scenario` → `String`

Optionally specify the name to use for the current transaction&apos;s scenario

###### `tagsString` → `String`

String of tags / topics.

###### `timestamp` → `DateTime`

timestamp of the log

###### `topics` → `List<String>`

List of tags / topics.

---

##### Methods

###### `addToLoggerBuffer()` → `LogEntryEventBuilder`

Adds the logger to the buffer.

####### Return

**Type**

LogEntryEventBuilder

**Description**

An instance of LogEntryEventBuilder.

---
