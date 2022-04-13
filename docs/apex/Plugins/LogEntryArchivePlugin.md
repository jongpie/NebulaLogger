---
layout: default
---

## LogEntryArchivePlugin class

Optional plugin that provides a BigObject, `LogEntryArchive__b`, as an alternative option to the platform event `LogEntryEvent__e`

### Related

[LoggerPlugin](LoggerPlugin)

---

### Constructors

#### `LogEntryArchivePlugin()`

## Default constructor

### Methods

#### `execute(LoggerPlugin_t configuration, LoggerBatchableContext input, List<SObject> loggerRecords)` → `void`

Converts any `LogEntry__c` records into `LogEntryArchive__b` records

##### Parameters

| Param           | Description                                                              |
| --------------- | ------------------------------------------------------------------------ |
| `configuration` | The instance of `LoggerPlugin_t` configured for this specific plugin     |
| `input`         | The instance of `LoggerBatchableContext`, provided by the logging system |
| `loggerRecords` | The list of `SObject` scope records provider by `LogBatchPurger`         |

#### `execute(LoggerPlugin_t configuration, LoggerTriggerableContext input)` → `void`

Handles converting Logger&apos;s buffer of `LogEntryEvent__e` records into `LogEntryArchive__b` records for any user with the included custom save method &apos;BIG_OBJECT&apos;

##### Parameters

| Param           | Description                                                                |
| --------------- | -------------------------------------------------------------------------- |
| `configuration` | The instance of `LoggerPlugin_t` configured for this specific plugin       |
| `input`         | The instance of `LoggerTriggerableContext`, provided by the logging system |

#### `finish(LoggerPlugin_t configuration, LoggerBatchableContext input)` → `void`

No-op method, required by the interface `LoggerPlugin.Batchable`

##### Parameters

| Param           | Description                                                              |
| --------------- | ------------------------------------------------------------------------ |
| `configuration` | The instance of `LoggerPlugin_t` configured for this specific plugin     |
| `input`         | The instance of `LoggerBatchableContext`, provided by the logging system |

#### `start(LoggerPlugin_t configuration, LoggerBatchableContext input)` → `void`

Skips directly deleting `LogEntryTag__c` records in `LogBatchPurger` so that the tags can be included when `LogEntry__c` records are archived into `LogEntryArchive__b`

##### Parameters

| Param           | Description                                                              |
| --------------- | ------------------------------------------------------------------------ |
| `configuration` | The instance of `LoggerPlugin_t` configured for this specific plugin     |
| `input`         | The instance of `LoggerBatchableContext`, provided by the logging system |

---
