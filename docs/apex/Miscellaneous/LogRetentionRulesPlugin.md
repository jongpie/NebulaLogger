---
layout: default
---

## LogRetentionRulesPlugin class

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

#### `execute(LoggerPlugin_t configuration, LoggerSObjectHandler.SObjectHandlerInput input)` → `void`

#### `getCondition()` → `String`

#### `getField()` → `Schema.SObjectField`

#### `getValue(SObject record)` → `Object`

#### `matchesFilter()` → `Boolean`

---
