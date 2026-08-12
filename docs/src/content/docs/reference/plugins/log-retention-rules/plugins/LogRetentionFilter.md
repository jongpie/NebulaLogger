---
title: LogRetentionFilter
description: >-
  Nebula Logger log-retention-rules plugin class (public API):
  LogRetentionFilter.
---

# LogRetentionFilter Class

`SUPPRESSWARNINGS`

Evaluates an `SObject` record to see if it matches the condition(s) defined in `LogRetentionRule__mdt` and its related
list of related `LogRetentionRuleCondition__mdt` records. The result is then used in `LogRententionRulesPlugin` to override
the value of `Log__c.LogRetentionDate__c` for any records that match the filters.

**Group** Plugins

**See** LogRententionRulesPlugin

## Constructors

### `LogRetentionFilter(record, rule, ruleFilterConditions)`

Creates a new instance of `LogRetentionFilter` , used to determine if an `SObject` record
meets the criteria of the provided rule &amp; filter conditions

#### Signature

```apex
public LogRetentionFilter(SObject record, LogRetentionRule__mdt rule, List<LogRetentionRuleCondition__mdt> ruleFilterConditions)
```

#### Parameters

| Name                 | Type                                                                  | Description                                                                                              |
| -------------------- | --------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| record               | SObject                                                               | The `SObject` record to compare                                                                          |
| rule                 | [LogRetentionRule\_\_mdt](..\custom-objects\LogRetentionRule__mdt.md) | The filter rule to apply to the `SObject` record, stored as an instance of `LogRetentionRule__mdt`       |
| ruleFilterConditions | List<LogRetentionRuleCondition\_\_mdt>                                | The list of `LogRetentionRuleCondition__mdt` for the rule that should be applied to the `SObject` record |

## Methods

### `getFilterResult()`

Returns an instance of `FilterResult` that provides information regarding
if the `SObject` record matches the provided rule &amp; filter conditions

#### Signature

```apex
public FilterResult getFilterResult()
```

#### Return Type

**FilterResult**

The new instance of `FilterResult`

## Classes

### FilterResult Class

Inner class used to handle determining if the provided `SObject` record meets
the criteria for the provided `LogRetentionRule__mdt` rule and associated `List<LogRetentionRuleCondition__mdt>` ruleFilterConditions

#### Methods

##### `getRule()`

Returns the `LogRetentionRule__mdt` rule that was used to create the instance of `FilterResult`

###### Signature

```apex
public LogRetentionRule__mdt getRule()
```

###### Return Type

**[LogRetentionRule\_\_mdt](..\custom-objects\LogRetentionRule__mdt.md)**

The instance of `LogRetentionRule__mdt`

---

##### `getRecord()`

Returns the `SObject` record that was used to create the instance of `FilterResult`

###### Signature

```apex
public SObject getRecord()
```

###### Return Type

**SObject**

The instance of `SObject`

---

##### `matchesFilter()`

Indicates if the provided `SObject` record matches all of the criteria defined in
the `LogRetentionRule__mdt` rule and associated `List<LogRetentionRuleCondition__mdt>` ruleFilterConditions

###### Signature

```apex
public Boolean matchesFilter()
```

###### Return Type

**Boolean**

The `Boolean` value that indicates if the `SObject` record matches the provided rule &amp; conditions ( `true` )
or if the record does not match the rule &amp; conditions ( `false` )
