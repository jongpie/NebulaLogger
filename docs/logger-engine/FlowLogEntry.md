---
layout: default
---

## FlowLogEntry class

Handles adding new log entries in Flow

### Related

[FlowRecordLogEntry](FlowRecordLogEntry)

[FlowCollectionLogEntry](FlowCollectionLogEntry)

[FlowLogger](FlowLogger)

[Logger](Logger)

[LogEntryEventBuilder](LogEntryEventBuilder)

---

### Properties

#### `faultMessage` → `String`

Optionally log a Flow fault error message

#### `flowName` → `String`

The API name of the Flow creating the log entry. Due to Salesforce limitations, this cannot be automatically determined.

#### `loggingLevelName` → `String`

Optionally specify a logging level - the default is &apos;DEBUG&apos;

#### `message` → `String`

The message to log

#### `recordId` → `Id`

Optionally relate the log entry to a particular record ID

#### `saveLog` → `Boolean`

Optionally choose to save any pending log entries

#### `saveMethodName` → `String`

Optionally choose the save method to use when &apos;Save Log&apos; is true

#### `scenario` → `String`

Optionally specify the name to use for the current transaction&apos;s scenario

#### `tagsString` → `String`

Optionally provide a comma-separated String of tags to dynamically assign to the log entry

#### `timestamp` → `DateTime`

Current system timestamp.

#### `topics` → `List<String>`

Optionally provide a comma-separated String of tags to dynamically assign to the log entry

---

### Methods

#### `addFlowEntries(List<FlowLogEntry> flowLogEntries)` → `List<String>`

Invocable method, that can be called via flow.

##### Parameters

| Param            | Description                                |
| ---------------- | ------------------------------------------ |
| `flowLogEntries` | The list of FlowLogEntry instances to save |

##### Return

**Type**

List&lt;String&gt;

**Description**

The current transaction&apos;s ID (based on `Logger.getTransactionId()`)

---
