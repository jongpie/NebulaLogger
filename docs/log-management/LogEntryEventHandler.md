---
layout: default
---

## LogEntryEventHandler class

Processes `LogEntryEvent__e` platform events and normalizes the data into `Log__c` and `LogEntry__c` records

---

### Constructors

#### `LogEntryEventHandler()`

#### `LogEntryEventHandler(List<LogEntryEvent__e> logEntryEvents)`

---

### Properties

#### `releaseNumber` → `String`

#### `releaseVersion` → `String`

---

### Methods

#### `execute()` → `void`

Runs the trigger handler's logic for the `LogEntryEvent__e` platform event object

#### `getSObjectType()` → `SObjectType`

Returns SObject Type that the handler is responsible for processing

##### Return

**Type**

SObjectType

**Description**

The instance of `SObjectType`

---
