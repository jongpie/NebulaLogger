---
layout: default
---

## FlowCollectionLogEntry class

Handles adding new log entries in Flow for a particular `SObject` record collection

### Related

[FlowLogEntry](FlowLogEntry)

[FlowRecordLogEntry](FlowRecordLogEntry)

[FlowLogger](FlowLogger)

[Logger](Logger)

[LogEntryEventBuilder](LogEntryEventBuilder)

---

### Properties

#### `faultMessage` → `String`

Optionally log a Flow fault error message

#### `flowName` → `String`

The API name of the Flow creating the log entry. Due to Salesforce limitations, this cannot be automatically determined

#### `loggingLevelName` → `String`

Optionally specify a logging level - the default is &apos;DEBUG&apos;

#### `message` → `String`

The message to log

#### `records` → `List<SObject>`

The records to relate to this log entry - the records&apos; JSON is automatically added to the log entry

#### `saveLog` → `Boolean`

Optionally choose to save any pending log entries

#### `saveMethodName` → `String`

Optionally choose the save method to use when &apos;Save Log&apos; is true

#### `scenario` → `String`

Optionally specify the name to use for the current transaction&apos;s scenario

#### `tagsString` → `String`

Optionally provide a comma-separated String of tags to dynamically assign to the log entry

#### `timestamp` → `DateTime`

Represents the current system time

#### `topics` → `List<String>`

Optionally provide a comma-separated String of tags to dynamically assign to the log entry

---

### Methods

#### `addFlowCollectionEntries(List<FlowCollectionLogEntry> flowCollectionLogEntries)` → `List<String>`

Invocable method for adding LogEntry records via flow or process builder

##### Parameters

| Param                      | Description                                      |
| -------------------------- | ------------------------------------------------ |
| `flowCollectionLogEntries` | The list of FlowRecordLogEntry instances to save |

##### Return

**Type**

List&lt;String&gt;

**Description**

The current transaction&apos;s ID (based on `Logger.getTransactionId()`)

---
