---
title: FlowRecordLogEntry
description: 'Nebula Logger class reference: FlowRecordLogEntry.'
---

# FlowRecordLogEntry Class

`SUPPRESSWARNINGS`

Handles adding new log entries in Flow for a particular `SObject` record

**Group** Logger Engine

**See** [FlowLogEntry](FlowLogEntry.md)

**See** [FlowCollectionLogEntry](FlowCollectionLogEntry.md)

**See** FlowLogger

**See** [Logger](Logger.md)

**See** [LogEntryEventBuilder](LogEntryEventBuilder.md)

## Fields

### `faultMessage`

`INVOCABLEVARIABLE`

Optionally log a Flow fault error message

#### Signature

```apex
global faultMessage
```

#### Type

String

---

### `flowName`

`INVOCABLEVARIABLE`

The API name of the Flow creating the log entry.
Due to Salesforce limitations, this cannot be automatically determined

#### Signature

```apex
global flowName
```

#### Type

String

---

### `loggingLevelName`

`INVOCABLEVARIABLE`

Optionally specify a logging level - the default is &#x27;DEBUG&#x27;

#### Signature

```apex
global loggingLevelName
```

#### Type

String

---

### `message`

`INVOCABLEVARIABLE`

The message to log

#### Signature

```apex
global message
```

#### Type

String

---

### `record`

`INVOCABLEVARIABLE`

The record to relate to this log entry - the record&#x27;s JSON is automatically added to the log entry

#### Signature

```apex
global record
```

#### Type

SObject

---

### `saveLog`

`INVOCABLEVARIABLE`

Optionally choose to save any pending log entries

#### Signature

```apex
global saveLog
```

#### Type

Boolean

---

### `saveMethodName`

`INVOCABLEVARIABLE`

Optionally choose the save method to use when &#x27;Save Log&#x27; is true

#### Signature

```apex
global saveMethodName
```

#### Type

String

---

### `scenario`

`INVOCABLEVARIABLE`

Optionally specify the name to use for the current transaction&#x27;s scenario

#### Signature

```apex
global scenario
```

#### Type

String

---

### `shouldThrowFaultMessageException`

`INVOCABLEVARIABLE`

Optionally rollback Database operations executed until Apex action was called and save the log entry.

#### Signature

```apex
global shouldThrowFaultMessageException
```

#### Type

Boolean

---

### `tagsString`

`INVOCABLEVARIABLE`

Optionally provide a comma-separated String of tags to dynamically assign to the log entry

#### Signature

```apex
global tagsString
```

#### Type

String

## Methods

### `addFlowRecordEntries(flowRecordLogEntries)`

`INVOCABLEMETHOD`

Invocable method for adding record entries via flow or process builder

#### Signature

```apex
global static List<String> addFlowRecordEntries(List<FlowRecordLogEntry> flowRecordLogEntries)
```

#### Parameters

| Name                 | Type                     | Description                                      |
| -------------------- | ------------------------ | ------------------------------------------------ |
| flowRecordLogEntries | List<FlowRecordLogEntry> | The list of FlowRecordLogEntry instances to save |

#### Return Type

**List<String>**

The current transaction&#x27;s ID (based on `Logger.getTransactionId()` )
