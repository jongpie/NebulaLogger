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

#### `getHandler(Schema.SObjectType sobjectType)` → `LoggerSObjectHandler`

Returns an instance of `LoggerSObjectHandler` that has been built &amp; configured for the specified `SObjectType`

##### Parameters

| Param         | Description                                                                             |
| ------------- | --------------------------------------------------------------------------------------- |
| `sobjectType` | The instance `SObjectType` to check for a configured instance of `LoggerSObjectHandler` |

##### Return

**Type**

LoggerSObjectHandler

**Description**

The Apex class that extends `LoggerSObjectHandler` and has been configured for the specified `SObjectType`

#### `getHandler(Schema.SObjectType sobjectType, LoggerSObjectHandler defaultImplementation)` → `LoggerSObjectHandler`

Returns an instance of `LoggerSObjectHandler` that has been built &amp; configured for the specified `SObjectType`

##### Parameters

| Param                   | Description                                                                                                                         |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `sobjectType`           | The instance `SObjectType` to check for a configured instance of `LoggerSObjectHandler`                                             |
| `defaultImplementation` | A default implementation of `LoggerSObjectHandler` that should be used, if a configuration cannot be found `LoggerSObjectHandler_t` |

##### Return

**Type**

LoggerSObjectHandler

**Description**

The Apex class that extends `LoggerSObjectHandler` and has been configured for the specified `SObjectType`

#### `getSObjectType()` → `Schema.SObjectType`

Returns the SObject Type that the handler is responsible for processing

##### Return

**Type**

Schema.SObjectType

**Description**

The instance of `SObjectType`

#### `overrideTriggerableContext(LoggerTriggerableContext input)` → `LoggerSObjectHandler`

Provides the ability to override the instance `LoggerTriggerableContext` that is normally provided internally by `LoggerSObjectHandler`

##### Parameters

| Param   | Description                                                                        |
| ------- | ---------------------------------------------------------------------------------- |
| `input` | The instance of `LoggerTriggerableContext` to use within the trigger handler class |

##### Return

**Type**

LoggerSObjectHandler

**Description**

The same instance of `LoggerSObjectHandler`, useful for chaining methods

---
