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

The name of the Flow creating the log entry. Due to Salesforce limitations, this cannot be automatically determined

#### `loggingLevelName` → `String`

Optionally specify a logging level - the default is &apos;DEBUG&apos;

#### `message` → `String`

The message to log

#### `records` → `List<SObject>`

The records to relate to this log entry - the records&apos; JSON is automatically added to the log entry

#### `saveLog` → `Boolean`

Optionally choose to save any pending log entries

#### `tagsString` → `String`

Optionally provide a comma-separated String of tags to dynamically assign to the log entry

#### `timestamp` → `DateTime`

#### `topics` → `List<String>`

Optionally provide a comma-separated String of tags to dynamically assign to the log entry

---

### Methods

#### `addFlowCollectionEntries(List<FlowCollectionLogEntry> flowCollectionLogEntries)` → `List<String>`

addFlowRecordEntries description

##### Parameters

| Param                  | Description                                      |
| ---------------------- | ------------------------------------------------ |
| `flowRecordLogEntries` | The list of FlowRecordLogEntry instances to save |

##### Return

**Type**

List&lt;String&gt;

**Description**

The current transaction&apos;s ID (based on `Logger.getTransactionId()`)

---
