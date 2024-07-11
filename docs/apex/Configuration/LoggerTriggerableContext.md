---
layout: default
---

## LoggerTriggerableContext class

Class used by the logging system for trigger contextual details

### Related

[LoggerSObjectHandler](LoggerSObjectHandler)

[LoggerPlugin](LoggerPlugin)

---

### Constructors

#### `LoggerTriggerableContext(Schema.SObjectType sobjectType, System.TriggerOperation triggerOperationType, List<SObject> triggerNew)`

#### `LoggerTriggerableContext(Schema.SObjectType sobjectType,System.TriggerOperation triggerOperationType,List<SObject> triggerNew,Map<Id, SObject> triggerNewMap,Map<Id, SObject> triggerOldMap)`

---

### Properties

#### `sobjectType` → `Schema.SObjectType`

#### `sobjectTypeName` → `String`

#### `triggerNew` → `List<SObject>`

#### `triggerNewMap` → `Map<Id, SObject>`

#### `triggerOldMap` → `Map<Id, SObject>`

#### `triggerOperationType` → `System.TriggerOperation`

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
