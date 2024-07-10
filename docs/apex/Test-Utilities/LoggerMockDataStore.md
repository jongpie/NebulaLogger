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
