---
layout: default
---

## LoggerSObjectHandlerPlugin class

Abstract class used to create custom Apex plugins to execute for all trigger operations on `Log__c` or `LogEntry__c`

---

### Constructors

#### `LoggerSObjectHandlerPlugin()`

## All instances of `LoggerSObjectHandlerPlugin` are dynamically created, which requires aparameterless constructor

### Methods

#### `execute(TriggerOperation triggerOperationType,List<SObject> triggerNew,Map<Id, SObject> triggerNewMap,List<SObject> triggerOld,Map<Id, SObject> triggerOldMap)` → `void`

This method is the entry point for plugins to execute any custom logic. It is automatically called by the logging system for any enabled plugins. Several trigger-based parameters are provided - these parameters should be used by plugins, instead of calling the platform&apos;s static variables directly (e.g., use the provided `triggerNew` variable instead of using `Trigger.new` directly, and so on).

##### Parameters

| Param                  | Description                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| `triggerOperationType` | The enum instance of `Trigger.operationType` at the time that the handler class is created |
| `triggerNew`           | The value `Trigger.new` at the time that the handler class is created                      |
| `triggerNewMap`        | The value `Trigger.newMap` at the time that the handler class is created                   |
| `triggerOld`           | The value `Trigger.old` at the time that the handler class is created                      |
| `triggerOldMap`        | The value `Trigger.oldMap` at the time that the handler class is created                   |

---
