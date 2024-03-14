---
layout: default
---

## LogEntryTagHandler class

Handles trigger events for the `LogEntryTag__c` object

---

### Methods

#### `generateUniqueId(LogEntryTag__c logEntryTag)` → `String`

Generates a unique composite key for the `LogEntryTag__c` record, which is used to set the field `LogEntryTag__c.UniqueId__c`

##### Parameters

| Param         | Description                                                   |
| ------------- | ------------------------------------------------------------- |
| `logEntryTag` | The `LogEntryTag__c` record to use for generating a unique ID |

##### Return

**Type**

String

**Description**

The unique composite key for the record

#### `getSObjectType()` → `Schema.SObjectType`

Returns SObject Type that the handler is responsible for processing

##### Return

**Type**

Schema.SObjectType

**Description**

The instance of `SObjectType`

---
