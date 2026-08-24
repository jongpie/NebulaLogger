---
title: LogEntryArchiveBuilder
description: >-
  Nebula Logger big-object-archiving plugin class (public API):
  LogEntryArchiveBuilder.
---

# LogEntryArchiveBuilder Class

Builder class to create an instance of `LogEntryArchive__b` , used by the Big Object plugin

**Group** Plugins

**See** [LogEntryArchivePlugin](LogEntryArchivePlugin.md)

**See** LogEntryEventBuilder

## Constructors

### `LogEntryArchiveBuilder(logEntryEvent)`

Used by `LogEntryArchivePlugin` to instantiate a new instance of `LogEntryArchiveBuilder`

#### Signature

```apex
public LogEntryArchiveBuilder(LogEntryEvent__e logEntryEvent)
```

#### Parameters

| Name          | Type               | Description                                                                           |
| ------------- | ------------------ | ------------------------------------------------------------------------------------- |
| logEntryEvent | LogEntryEvent\_\_e | The `LogEntryEvent__e` record that will be converted to a `LogEntryArchive__b` record |

---

### `LogEntryArchiveBuilder(logEntry)`

Used by `LogEntryArchivePlugin` to instantiate a new instance of `LogEntryArchiveBuilder`

#### Signature

```apex
public LogEntryArchiveBuilder(LogEntry__c logEntry)
```

#### Parameters

| Name     | Type          | Description                                                                      |
| -------- | ------------- | -------------------------------------------------------------------------------- |
| logEntry | LogEntry\_\_c | The `LogEntry__c` record that will be converted to a `LogEntryArchive__b` record |

## Methods

### `getLogEntryArchive()`

Returns the `LogEntryArchive__b` record for this instance of LogEntryEventBuilder

#### Signature

```apex
public LogEntryArchive__b getLogEntryArchive()
```

#### Return Type

**[LogEntryArchive\_\_b](..\custom-objects\LogEntryArchive__b.md)**

The `LogEntryArchive__b` record
