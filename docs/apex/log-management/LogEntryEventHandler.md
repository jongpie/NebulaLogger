---
layout: default
---

## LogEntryEventHandler class

Processes `LogEntryEvent__e` platform events and normalizes the data into `Log__c` and `LogEntry__c` records

---

### Properties

#### `releaseNumber` → `String`

String containing the release number.

#### `releaseVersion` → `String`

String containing the release version.

---

### Methods

#### `executeAfterInsert(List<SObject> triggerNew)` → `void`

Public method so it can be called from Logger - this is unique to LogEntryEventHandler

##### Parameters

| Param        | Description                      |
| ------------ | -------------------------------- |
| `triggerNew` | list of new LogEntryEvent events |

#### `executeBeforeInsert(List<SObject> triggerNew)` → `void`

method so it can be called from Logger - this is unique to LogEntryEventHandler

##### Parameters

| Param        | Description                      |
| ------------ | -------------------------------- |
| `triggerNew` | list of new LogEntryEvent events |

#### `getSObjectType()` → `SObjectType`

Returns SObject Type that the handler is responsible for processing

##### Return

**Type**

SObjectType

**Description**

The instance of `SObjectType`

---
