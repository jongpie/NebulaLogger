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

#### `execute(Database.BatchableContext batchableContext, List<SObject> scopeRecords)` → `void`

Required by the Database.Batchable interface, this method executes the logic for purging log records.

##### Parameters

| Param              | Description                             |
| ------------------ | --------------------------------------- |
| `batchableContext` | - The context of the current batch job. |
| `scopeRecords`     | - The log records to purge.             |

#### `finish(Database.BatchableContext batchableContext)` → `void`

Required by the Database.Batchable interface. This method runs after all batch jobs are complete. This method writes a status to the Log\_\_c object indicating that the purge has finished.

##### Parameters

| Param              | Description                     |
| ------------------ | ------------------------------- |
| `batchableContext` | - The context of the batch jobs |

#### `getDefaultBatchSize()` → `Integer`

Returns the default batch size used when running `LogBatchPurger`

##### Return

**Type**

Integer

**Description**

The `Integer` value configured in the custom metadata record `LoggerParameter.LogBatchPurgerDefaultBatchSize`, or `500` as the default

#### `setChainedBatchSize(Integer chainedBatchSize)` → `LogBatchPurger`

The `LogBatchPurger` job is designed to run several instances - typically, it runs on `LogEntryTag__c`, then `LogEntry__c`, and finally `Log__c`. This method provides a way to control the batch size used for the chained instances of `LogBachPurger`

##### Parameters

| Param              | Description                                                                    |
| ------------------ | ------------------------------------------------------------------------------ |
| `chainedBatchSize` | The batch size to use for any subsequent chained instances of `LogBatchPurger` |

##### Return

**Type**

LogBatchPurger

**Description**

The same instance of `LogBatchPurger`, useful for chaining methods

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
