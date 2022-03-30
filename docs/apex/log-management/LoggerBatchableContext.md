---
layout: default
---

## LoggerBatchableContext class

Class used by the logging system for batch contextual details

### Related

[LogBatchPurger](LogBatchPurger)

[LoggerPlugin](LoggerPlugin)

---

### Constructors

#### `LoggerBatchableContext(Database.BatchableContext batchableContext, Schema.SObjectType sobjectType)`

Constructor used to set the 2 properties

##### Parameters

| Param              | Description                                                                                       |
| ------------------ | ------------------------------------------------------------------------------------------------- |
| `batchableContext` | The instance of `Database.BatchableContextbatchableContext`, provided by the platform at run-time |
| `sobjectType`      | The `SObjectType` that will be queried &amp; purged                                               |

---

### Properties

#### `batchableContext` → `Database.BatchableContext`

#### `sobjectType` → `Schema.SObjectType`

#### `sobjectTypeName` → `String`

---
