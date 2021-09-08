---
layout: default
---

## LogEntryEventHandler class

Processes `LogEntryEvent__e` platform events and normalizes the data into `Log__c` and `LogEntry__c` records

---

### Properties

#### `releaseNumber` → `String`

#### `releaseVersion` → `String`

---

### Methods

#### `executeAfterInsert(List<SObject> triggerNew)` → `void`

#### `executeBeforeInsert(List<SObject> triggerNew)` → `void`

#### `getSObjectType()` → `SObjectType`

Returns SObject Type that the handler is responsible for processing

##### Return

**Type**

SObjectType

**Description**

The instance of `SObjectType`

---
