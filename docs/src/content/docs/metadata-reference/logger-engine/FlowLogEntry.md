---
title: FlowLogEntry
description: 'Nebula Logger class reference: FlowLogEntry.'
---

# FlowLogEntry Class

`SUPPRESSWARNINGS`

Handles adding new log entries in Flow

**Group** Logger Engine

**See** [FlowRecordLogEntry](FlowRecordLogEntry.md)

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
Due to Salesforce limitations, this cannot be automatically determined.

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

### `recordId`

`INVOCABLEVARIABLE`

Optionally relate the log entry to a particular record ID

#### Signature

```apex
global recordId
```

#### Type

Id

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

### `addFlowEntries(flowLogEntries)`

`INVOCABLEMETHOD`

Invocable method, that can be called via flow.

#### Signature

```apex
global static List<String> addFlowEntries(List<FlowLogEntry> flowLogEntries)
```

#### Parameters

| Name           | Type               | Description                                |
| -------------- | ------------------ | ------------------------------------------ |
| flowLogEntries | List<FlowLogEntry> | The list of FlowLogEntry instances to save |

#### Return Type

**List<String>**

The current transaction&#x27;s ID (based on `Logger.getTransactionId()` )
