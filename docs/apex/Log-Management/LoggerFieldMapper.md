---
layout: default
---

## LoggerFieldMapper class

Maps fields values from custom fields on `LogEntryEvent__e` to equivalent fields on `Log__c`, `LogEntry__c`, and `LoggerScenario__c`

---

### Methods

#### `mapFieldValues(SObject sourceRecord, SObject targetRecord)` → `void`

Copies field values from the `sourceRecord` to the `targetRecord`, based on rules configured in `LoggerFieldMapping_t`

##### Parameters

| Param          | Description                                                                     |
| -------------- | ------------------------------------------------------------------------------- |
| `sourceRecord` | The source `SObject` record containing the data to copy                         |
| `targetRecord` | The target `SObject` record that should have fields &amp; field values appended |

---
