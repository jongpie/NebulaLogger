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

#### `getSObjectType()` → `SObjectType`

Returns SObject Type that the handler is responsible for processing

##### Return

**Type**

SObjectType

**Description**

The instance of `SObjectType`

---
