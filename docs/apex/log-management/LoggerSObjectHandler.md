---
layout: default
---

## LoggerSObjectHandler class

Abstract class used by trigger handlers for shared logic

---

### Constructors

#### `LoggerSObjectHandler()`

## Default constructor

### Methods

#### `execute()` → `void`

Runs the handler class&apos;s logic

#### `getSObjectType()` → `SObjectType`

Returns the SObject Type that the handler is responsible for processing

##### Return

**Type**

SObjectType

**Description**

The instance of `SObjectType`

---

### Inner Classes

#### LoggerSObjectHandler.SObjectHandlerInput class

Class used by the logging system to for trigger context details

---

##### Properties

###### `sobjectType` → `Schema.SObjectType`

###### `sobjectTypeName` → `String`

###### `triggerNew` → `List<SObject>`

###### `triggerNewMap` → `Map<Id, SObject>`

###### `triggerOld` → `List<SObject>`

###### `triggerOldMap` → `Map<Id, SObject>`

###### `triggerOperationType` → `TriggerOperation`

###### `triggerOperationTypeName` → `String`

###### `triggerRecords` → `List<SObjectHandlerRecordInput>`

---

#### LoggerSObjectHandler.SObjectHandlerRecordInput class

Class used by the logging system to provide trigger record details

---

##### Properties

###### `triggerRecordNew` → `SObject`

###### `triggerRecordOld` → `SObject`

---
