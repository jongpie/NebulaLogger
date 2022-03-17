---
layout: default
---

## LogEntryArchiveBuilder class

Optional plugin that provides a BigObject, `LogEntryArchive__b`, as an alternative option to the platform event `LogEntryEvent__e`

---

### Methods

#### `execute(LoggerPlugin_t configuration, LoggerSObjectHandler.SObjectHandlerInput input)` → `void`

Handles converting Logger&apos;s buffer of `LogEntryEvent__e` records into `LogEntryArchive__b` records for any user with the included custom save method &apos;BIG_OBJECT&apos;

##### Parameters

| Param           | Description                                                                                      |
| --------------- | ------------------------------------------------------------------------------------------------ |
| `configuration` | The instance of `LoggerPlugin_t` configured for this specific plugin                             |
| `input`         | The instance of `LoggerSObjectHandlerPlugin.SObjectHandlerInput`, provided by the logging system |

---
