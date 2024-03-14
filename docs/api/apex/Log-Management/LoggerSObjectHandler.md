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

#### `getSObjectType()` → `Schema.SObjectType`

Returns the SObject Type that the handler is responsible for processing

##### Return

**Type**

Schema.SObjectType

**Description**

The instance of `SObjectType`

---
