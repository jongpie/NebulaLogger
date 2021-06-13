---
layout: default
---

## LoggerSObjectHandlerPlugin class

Abstract class used to define custom plugins to execute when DML statements occur on `Log__c` or `LogEntry__c`

---

### Methods

#### `execute(TriggerOperation triggerOperationType,List<SObject> triggerNew,Map<Id, SObject> triggerNewMap,List<SObject> triggerOld,Map<Id, SObject> triggerOldMap)` → `void`

execute description

##### Parameters

| Param                  | Description                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| `triggerOperationType` | The enum instance of `Trigger.operationType` at the time that the handler class is created |
| `triggerNew`           | The value `Trigger.new` at the time that the handler class is created                      |
| `triggerNewMap`        | The value `Trigger.newMap` at the time that the handler class is created                   |
| `triggerOld`           | The value `Trigger.old` at the time that the handler class is created                      |
| `triggerOldMap`        | The value `Trigger.oldMap` at the time that the handler class is created                   |

---
