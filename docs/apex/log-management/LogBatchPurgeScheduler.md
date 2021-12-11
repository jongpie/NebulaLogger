---
layout: default
---

## LogBatchPurgeScheduler class

Schedulable class used to schedule the batch job `LogBatchPurger`

### Related

[LogBatchPurger](LogBatchPurger)

---

### Constructors

#### `LogBatchPurgeScheduler()`

Default constructor. Sets initial batch size to 200.

#### `LogBatchPurgeScheduler(Integer batchSize)`

Construct that accepts the batch size as a parameter.

##### Parameters

| Param       | Description                                                                   |
| ----------- | ----------------------------------------------------------------------------- |
| `batchSize` | - The size of the records per batch job / instance. Max is 5000. Minium is 1. |

---

### Methods

#### `execute(SchedulableContext schedulableContext)` → `void`

Required by the Database.Schedulable interface, this method kicks off the LogBatchPurger batch class on a scheduled basis.

##### Parameters

| Param                | Description                                                                                                                    |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `schedulableContext` | Required for the Schedulable interface, this method contains contextual information about when this instance is/was scheduled. |

---
