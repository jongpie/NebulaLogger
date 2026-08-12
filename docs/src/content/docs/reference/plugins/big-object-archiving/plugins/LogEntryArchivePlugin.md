---
title: LogEntryArchivePlugin
description: >-
  Nebula Logger big-object-archiving plugin class (public API):
  LogEntryArchivePlugin.
---

# LogEntryArchivePlugin Class

Optional plugin that provides a Big Object, `LogEntryArchive__b` , as an alternative option
to the platform event `LogEntryEvent__e`

**Group** Plugins

**See** LoggerPlugin

**Implements**

LoggerPlugin.Batchable,
LoggerPlugin.Triggerable

## Constructors

### `LogEntryArchivePlugin()`

`SUPPRESSWARNINGS`

Default constructor

#### Signature

```apex
public LogEntryArchivePlugin()
```

## Methods

### `execute(configuration, input, loggerRecords)`

Converts any `LogEntry__c` records into `LogEntryArchive__b` records

#### Signature

```apex
public void execute(LoggerPlugin__mdt configuration, LoggerBatchableContext input, List<SObject> loggerRecords)
```

#### Parameters

| Name          | Type                   | Description                                                               |
| ------------- | ---------------------- | ------------------------------------------------------------------------- |
| configuration | LoggerPlugin\_\_mdt    | The instance of `LoggerPlugin__mdt` configured for this specific plugin   |
| input         | LoggerBatchableContext | The instance of `LoggerBatchableContext` , provided by the logging system |
| loggerRecords | List<SObject>          | The list of `SObject` scope records provider by `LogBatchPurger`          |

#### Return Type

**void**

---

### `execute(configuration, input)`

Handles converting Logger&#x27;s buffer of `LogEntryEvent__e` records into `LogEntryArchive__b` records
for any user with the included custom save method &#x27;BIG_OBJECT&#x27;

#### Signature

```apex
public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input)
```

#### Parameters

| Name          | Type                     | Description                                                                 |
| ------------- | ------------------------ | --------------------------------------------------------------------------- |
| configuration | LoggerPlugin\_\_mdt      | The instance of `LoggerPlugin__mdt` configured for this specific plugin     |
| input         | LoggerTriggerableContext | The instance of `LoggerTriggerableContext` , provided by the logging system |

#### Return Type

**void**

---

### `finish(configuration, input)`

`SUPPRESSWARNINGS`

No-op method, required by the interface `LoggerPlugin.Batchable`

#### Signature

```apex
public void finish(LoggerPlugin__mdt configuration, LoggerBatchableContext input)
```

#### Parameters

| Name          | Type                   | Description                                                               |
| ------------- | ---------------------- | ------------------------------------------------------------------------- |
| configuration | LoggerPlugin\_\_mdt    | The instance of `LoggerPlugin__mdt` configured for this specific plugin   |
| input         | LoggerBatchableContext | The instance of `LoggerBatchableContext` , provided by the logging system |

#### Return Type

**void**

---

### `start(configuration, input)`

Skips directly deleting `LogEntryTag__c` records in `LogBatchPurger` so that the tags
can be included when `LogEntry__c` records are archived into `LogEntryArchive__b`

#### Signature

```apex
public void start(LoggerPlugin__mdt configuration, LoggerBatchableContext input)
```

#### Parameters

| Name          | Type                   | Description                                                               |
| ------------- | ---------------------- | ------------------------------------------------------------------------- |
| configuration | LoggerPlugin\_\_mdt    | The instance of `LoggerPlugin__mdt` configured for this specific plugin   |
| input         | LoggerBatchableContext | The instance of `LoggerBatchableContext` , provided by the logging system |

#### Return Type

**void**
