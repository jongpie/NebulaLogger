---
layout: default
---

## LoggerSObjectPostProcessor interface

Interface used to define custom logic to run when DML statements occur on `Log__c` or `LogEntry__c`

---

### Methods

#### `execute(TriggerOperation triggerOperationType, List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById)` → `void`

---
