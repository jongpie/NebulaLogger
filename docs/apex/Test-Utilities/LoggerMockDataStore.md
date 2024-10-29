---
layout: default
---

## LoggerMockDataStore class

Utility class used to mock any data-related operations for the database, event bus, and queueable jobs. These methods are generic, and should work in any Salesforce org. These methods can be used when writing Apex tests for plugins.

### Related

[LoggerDataStore](LoggerDataStore)

[LoggerMockDataCreator](../Test-Utilities/LoggerMockDataCreator)

[LoggerTestConfigurator](../Test-Utilities/LoggerTestConfigurator)

---

### Methods

#### `getDatabase()` → `MockDatabase`

#### `getEventBus()` → `MockEventBus`

#### `getJobQueue()` → `MockJobQueue`

---

### Inner Classes

#### LoggerMockDataStore.MockDatabase class

---

##### Methods

###### `insertRecords(List<SObject> records)` → `List<Database.SaveResult>`

---

#### LoggerMockDataStore.MockEventBus class

---

##### Methods

###### `deliver()` → `void`

###### `deliver(Schema.SObjectType sobjectType)` → `void`

###### `deliver(LoggerSObjectHandler sobjectHandlerInstance)` → `void`

###### `getMatchingPublishedPlatformEvents(SObject comparisonPlatformEvent)` → `List<SObject>`

Returns a list of published platform events that have the same field values as the provided platform event record `comparisonPlatformEvent`. This is useful for easily filtering to only the `LogEntryEvent__e` records relevant to a particular test method in a transaction/test scenario where multiple `LogEntryEvent__e` are being generated. Long-term, this helper method might be moved elsewhere, or replaced with something else, but for now, the mock event bus is a good-enough spot for it.

####### Parameters

| Param                     | Description                                                   |
| ------------------------- | ------------------------------------------------------------- |
| `comparisonPlatformEvent` | An instance of the platform event record to use for comparing |

####### Return

**Type**

List&lt;SObject&gt;

**Description**

A list containing any matches. When no matches are found, the list is empty.

###### `getPublishCallCount()` → `Integer`

###### `getPublishedPlatformEvents()` → `List<SObject>`

###### `publishRecord(SObject platformEvent)` → `Database.SaveResult`

###### `publishRecords(List<SObject> platformEvents)` → `List<Database.SaveResult>`

---

#### LoggerMockDataStore.MockJobQueue class

---

##### Methods

###### `enqueueJob(System.Queueable queueableJob)` → `Id`

###### `executeJobs()` → `void`

###### `getEnqueuedJobs()` → `List<System.Queueable>`

---
