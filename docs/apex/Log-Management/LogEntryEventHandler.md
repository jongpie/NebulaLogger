---
layout: default
---

## LogEntryEventHandler class

Processes `LogEntryEvent__e` platform events and normalizes the data into `Log__c` and `LogEntry__c` records

---

### Constructors

#### `LogEntryEventHandler()`

## Default constructor, used by the trigger `LogEntryEvent.trigger`

### Properties

#### `releaseNumber` → `String`

String containing the release number.

#### `releaseVersion` → `String`

String containing the release version.

---

### Methods

#### `getSObjectType()` → `Schema.SObjectType`

Returns SObject Type that the handler is responsible for processing

##### Return

**Type**

Schema.SObjectType

**Description**

The instance of `SObjectType`

---
