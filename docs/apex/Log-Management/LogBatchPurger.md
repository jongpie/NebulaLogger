---
layout: default
---

## LogBatchPurger class

Batch class used to delete old logs, based on `Log__c.LogRetentionDate__c &lt;= :System.today()` Plugins can register additional SObject types by implementing `LoggerPlugin.Purgeable` and returning a list of `LogBatchPurger.PurgeableSObjectRegistration` values that specify the SObject type + the field that carries its retention date. Registered types are purged BEFORE the core log objects on each run so plugin data with parent-child references to `Log__c` / `LogEntry__c` gets cleaned up first and the core delete cascade is not blocked by dangling plugin rows.

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

### Inner Classes

#### LogBatchPurger.PurgeableSObjectRegistration class

Declarative registration payload returned by a `LoggerPlugin.Purgeable` plugin. Carries the SObject type the plugin wants included in the purge chain and the field token whose Date value the purger compares against `System.today()`. The purger builds the SOQL query internally from this declaration - plugins do NOT write query strings themselves - so the retention semantics (`&lt;= today` + `!= NULL`, ordering, and the `LOG_RETENTION_END_DATE` bind) stay consistent across every purgeable SObject. Design intent: keep this DTO append-only so we can add optional properties later (`additionalWhereClause`, custom `sortByField`, `batchSize`, etc.) without ever breaking the `LoggerPlugin.Purgeable` interface signature.

---

##### Constructors

###### `PurgeableSObjectRegistration(Schema.SObjectType sobjectType, Schema.SObjectField retentionDateField)`

Builds a registration for a purgeable SObject.
####### Parameters

| Param                | Description                                                              |
| -------------------- | ------------------------------------------------------------------------ |
| `sobjectType`        | The custom SObject type to include in the purge chain. Its API name must |
| `retentionDateField` | Date field on `sobjectType` whose value the purger reads to decide       |

---

##### Properties

###### `retentionDateField` → `Schema.SObjectField`

Date field on `sobjectType` whose value drives purge eligibility.

###### `sobjectType` → `Schema.SObjectType`

SObject type to include in the purge chain.

---
