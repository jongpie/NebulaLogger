---
layout: default
---

## LogBatchPurger class

Batch class used to delete old logs, based on `Log__c.LogRetentionDate__c &lt;= :System.today()`

### Related

[LogBatchPurgeScheduler](LogBatchPurgeScheduler)

---

### Constructors

#### `LogBatchPurger()`

## Default constructor, sets up instance of LogBatchPurger class.

### Methods

#### `execute(Database.BatchableContext batchableContext, List<Log__c> logRecords)` → `void`

Required by the Database.Batchable interface, this method executes the logic for purging log records.

##### Parameters

| Param              | Description                             |
| ------------------ | --------------------------------------- |
| `batchableContext` | - The context of the current batch job. |
| `logRecords`       | - The log records to purge.             |

#### `execute(Database.BatchableContext batchableContext, List<SObject> loggerRecords)` → `void`

Required by the Database.Batchable interface, this method executes the logic for purging log records.

##### Parameters

| Param              | Description                             |
| ------------------ | --------------------------------------- |
| `batchableContext` | - The context of the current batch job. |
| `loggerRecords`    | - The log records to purge.             |

#### `finish(Database.BatchableContext batchableContext)` → `void`

Required by the Database.Batchable interface. This method runs after all batch jobs are complete. This method writes a status to the Log\_\_c object indicating that the purge has finished.

##### Parameters

| Param              | Description                     |
| ------------------ | ------------------------------- |
| `batchableContext` | - The context of the batch jobs |

#### `start(Database.BatchableContext batchableContext)` → `Database.QueryLocator`

Required by the Database.Batchable interface. Collects the records / objects passed in to the batch instance and returns a Databae.QueryLocator reference representing the current iteration.

##### Parameters

| Param              | Description                           |
| ------------------ | ------------------------------------- |
| `batchableContext` | contains the context of the batch job |

##### Return

**Type**

Database.QueryLocator

**Description**

an instance of the Database.QueryLocator class

##### Throws

| Exception           | Description                            |
| ------------------- | -------------------------------------- |
| `NoAccessException` | when there is no delete access to Logs |

---
