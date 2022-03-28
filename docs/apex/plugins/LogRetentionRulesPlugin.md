---
layout: default
---

## LogRetentionRulesPlugin class

Optional plugin that adds the ability to create &amp; deploy advanced, configurable rules for setting the retention date of `Log__c` records, using custom metadata types `LogRetentionRule_t` and `LogRetentionRuleCondition_t`.

---

### Properties

#### `conditions` → `List<String>`

#### `conditionsLogic` → `String`

#### `conditionsLogicType` → `String`

#### `matchesFilter` → `Boolean`

#### `record` → `SObject`

#### `rule` → `LogRetentionRule_t`

---

### Methods

#### `FieldPath(Schema.SObjectType sobjectType, String fieldPath)` → `public`

#### `FilterResult(SObject record, LogRetentionRule_t rule, List<LogRetentionRuleCondition_t> filterConditions)` → `public`

#### `evaluate(String x)` → `Boolean`

#### `execute(LoggerPlugin_t configuration, LoggerTriggerableContext input)` → `void`

Handles converting Logger&apos;s buffer of `LogEntryEvent__e` records into `LogEntryArchive__b` records for any user with the included custom save method &apos;BIG_OBJECT&apos;

##### Parameters

| Param           | Description                                                                |
| --------------- | -------------------------------------------------------------------------- |
| `configuration` | The instance of `LoggerPlugin_t` configured for this specific plugin       |
| `input`         | The instance of `LoggerTriggerableContext`, provided by the logging system |

#### `getCondition()` → `String`

#### `getField()` → `Schema.SObjectField`

#### `getValue(SObject record)` → `Object`

#### `matchesFilter()` → `Boolean`

---
