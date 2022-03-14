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

Runs the handler class&apos;s logic, as well as any configured plugins

#### `getHandlerControlParameterName()` → `String`

Returns the string value of the `LoggerParameter_t` record that controls if the handler is enabled. The `LoggerSObjectHandler` class uses this method to retrieve the corresponding `LoggerParameter_t` to determine if the class should execute.

##### Return

**Type**

String

**Description**

The `DeveloperName` value of the `LoggerParameter_t` that controls if the handler is enabled

#### `getHandlerPluginControlField()` → `Schema.SObjectField`

Returns the `SObjectField` on `LoggerPlugin_t` that controls if plugins are enabled for the handler&apos;s `SObjectType`

##### Return

**Type**

Schema.SObjectField

**Description**

The instance of `Schema.SObjectField` on `LoggerPlugin_t` for the current `SObjectType`

#### `getSObjectType()` → `Schema.SObjectType`

Returns the SObject Type that the handler is responsible for processing

##### Return

**Type**

Schema.SObjectType

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
