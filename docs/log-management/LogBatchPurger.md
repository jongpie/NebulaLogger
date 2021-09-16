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

---

### Methods

#### `execute(Database.BatchableContext batchableContext, List<Log__c> logRecords)` → `void`

#### `execute(Database.BatchableContext batchableContext, List<SObject> loggerRecords)` → `void`

#### `finish(Database.BatchableContext batchableContext)` → `void`

#### `start(Database.BatchableContext batchableContext)` → `Database.QueryLocator`

---
