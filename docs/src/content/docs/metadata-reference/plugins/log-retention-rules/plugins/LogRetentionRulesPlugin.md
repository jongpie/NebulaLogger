---
title: LogRetentionRulesPlugin
description: >-
  Nebula Logger log-retention-rules plugin class (public API):
  LogRetentionRulesPlugin.
---

# LogRetentionRulesPlugin Class

Optional plugin that adds the ability to create &amp; deploy advanced, configurable rules
for setting the retention date of `Log__c` records, using custom metadata types
`LogRetentionRule__mdt` and `LogRetentionRuleCondition__mdt` .

**Group** Plugins

**See** [LogRetentionFilter](LogRetentionFilter.md)

**Implements**

LoggerPlugin.Triggerable

## Methods

### `execute(configuration, input)`

Handles converting Logger&#x27;s buffer of `LogEntryEvent__e` records into `LogEntryArchive__b` records
for any user with the included custom save method &#x27;BIG_OBJECT&#x27;

#### Signature

```apex
public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input)
```

#### Parameters

| Name          | Type                     | Description                                                                 |
| ------------- | ------------------------ | --------------------------------------------------------------------------- |
| configuration | LoggerPlugin\_\_mdt      | The instance of `LoggerPlugin__mdt` configured for this specific plugin     |
| input         | LoggerTriggerableContext | The instance of `LoggerTriggerableContext` , provided by the logging system |

#### Return Type

**void**
