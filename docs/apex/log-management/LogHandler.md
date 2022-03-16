---
layout: default
---

## LogHandler class

Manages setting fields on `Log__c` before insert &amp; before update

---

### Methods

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

#### `getHandlerPluginSortField()` → `Schema.SObjectField`

Returns the `SObjectField` on `LoggerPlugin_t` that controls the sorting of plugins for the handler&apos;s `SObjectType`

##### Return

**Type**

Schema.SObjectField

**Description**

The instance of `Schema.SObjectField` on `LoggerPlugin_t` for the current `SObjectType`

#### `getSObjectType()` → `SObjectType`

Returns SObject Type that the handler is responsible for processing

##### Return

**Type**

SObjectType

**Description**

The instance of `SObjectType`

---
