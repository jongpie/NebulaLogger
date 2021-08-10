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

---

### Inner Classes

#### FlowLogger.LogEntry class

---

##### Properties

###### `faultMessage` → `String`

###### `flowName` → `String`

###### `loggingLevelName` → `String`

###### `message` → `String`

###### `saveLog` → `Boolean`

###### `tagsString` → `String`

###### `timestamp` → `DateTime`

###### `topics` → `List<String>`

---

##### Methods

###### `addToLoggerBuffer()` → `LogEntryEventBuilder`

---
