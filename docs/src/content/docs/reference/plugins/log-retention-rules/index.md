---
title: log-retention-rules plugin reference
description: >-
  Auto-generated reference for the Nebula Logger log-retention-rules plugin's
  public Apex classes and metadata.
---

Auto-generated reference for the **log-retention-rules** plugin.

:::caution[Unlocked package only]
The log-retention-rules plugin's Apex API is exposed as `public` (not `global`) and is only available in the [unlocked package](/NebulaLogger/introduction/package-options/). `public` API is not covered by Nebula Logger's global compatibility guarantees - classes, methods, and fields on this page can change, be renamed, or be removed in a future release without a deprecation window. Pin plugin versions you've tested against and re-verify after upgrades.
:::

For install, configuration, and usage guidance, see the [log-retention-rules plugin narrative](/NebulaLogger/plugins/log-retention-rules/).

---

# log-retention-rules

## Custom Objects

### [LogRetentionRule\_\_mdt](custom-objects\LogRetentionRule__mdt.md)

Used to configure rules that set the value of Log**c.LogRetentionDate**c - each rules consists of 1 or more conditions, stored in LogRetentionRuleCondition\_\_mdt

### [LogRetentionRuleCondition\_\_mdt](custom-objects\LogRetentionRuleCondition__mdt.md)

Used to configure field-level conditions for retention rules - each condition checks a LogEntry**c or Log**c field for a specific value, regular expression (regex), or field comparisons

## Plugins

### [LogRetentionFilter](plugins\LogRetentionFilter.md)

Evaluates an `SObject` record to see if it matches the condition(s) defined in `LogRetentionRule__mdt` and its related
list of related `LogRetentionRuleCondition__mdt` records. The result is then used in `LogRententionRulesPlugin` to override
the value of `Log__c.LogRetentionDate__c` for any records that match the filters.

### [LogRetentionRulesPlugin](plugins\LogRetentionRulesPlugin.md)

Optional plugin that adds the ability to create &amp; deploy advanced, configurable rules
for setting the retention date of `Log__c` records, using custom metadata types
`LogRetentionRule__mdt` and `LogRetentionRuleCondition__mdt` .
