---
layout: default
---

## LogEntryArchiveBuilder class

Builder class to create an instance of `LogEntryArchive__b`, used by the BigObject plugin

### Related

[LogEntryArchivePlugin](../Plugins/LogEntryArchivePlugin)

[LogEntryEventBuilder](LogEntryEventBuilder)

---

### Constructors

#### `LogEntryArchiveBuilder(LogEntryEvent__e logEntryEvent)`

Used by `LogEntryArchivePlugin` to instantiate a new instance of `LogEntryArchiveBuilder`

##### Parameters

| Param           | Description                                                                           |
| --------------- | ------------------------------------------------------------------------------------- |
| `logEntryEvent` | The `LogEntryEvent__e` record that will be converted to a `LogEntryArchive__b` record |

#### `LogEntryArchiveBuilder(LogEntry__c logEntry)`

Used by `LogEntryArchivePlugin` to instantiate a new instance of `LogEntryArchiveBuilder`

##### Parameters

| Param      | Description                                                                      |
| ---------- | -------------------------------------------------------------------------------- |
| `logEntry` | The `LogEntry__c` record that will be converted to a `LogEntryArchive__b` record |

---

### Methods

#### `getLogEntryArchive()` → `LogEntryArchive__b`

Returns the `LogEntryArchive__b` record for this instance of LogEntryEventBuilder

##### Return

**Type**

LogEntryArchive\_\_b

**Description**

The `LogEntryArchive__b` record

---
