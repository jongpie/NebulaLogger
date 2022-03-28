---
layout: default
---

## LoggerTriggerableContext class

DTO class used by the logging system to for trigger contextual details

### Related

[LoggerSObjectHandler](LoggerSObjectHandler)

[LoggerPlugin](LoggerPlugin)

---

### Properties

#### `sobjectType` → `Schema.SObjectType`

#### `sobjectTypeName` → `String`

#### `triggerNew` → `List<SObject>`

#### `triggerNewMap` → `Map<Id, SObject>`

#### `triggerOldMap` → `Map<Id, SObject>`

#### `triggerOperationType` → `TriggerOperation`

#### `triggerOperationTypeName` → `String`

#### `triggerRecords` → `List<RecordInput>`

---

### Inner Classes

#### LoggerTriggerableContext.RecordInput class

Class used by the logging system to provide trigger record details to Flow

---

##### Properties

###### `triggerRecordNew` → `SObject`

###### `triggerRecordOld` → `SObject`

---
