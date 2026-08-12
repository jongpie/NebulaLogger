---
title: Log Retention Rules plugin
description: CMDT-driven retention overrides that go beyond scenario rules.
---

The Log Retention Rules plugin adds a rule engine that overrides `LogRetentionDate__c` on new `Log__c` records based on arbitrary log attributes - going beyond the scenario-driven overrides `LoggerScenarioRule__mdt` supports natively.

## Installation

The Log Retention Rules plugin ships as its own unlocked package. Install after the core Nebula Logger unlocked package. See the [GitHub releases page](https://github.com/jongpie/NebulaLogger/releases) for the package ID.

After installation, assign the `LoggerLogRetentionRulesAdmin` (or similarly named) permission set.

## What it adds

- A `LogRetentionRule__mdt` custom metadata type for defining rules.
- A trigger plugin registered on `Log__c` that evaluates rules against new records and adjusts `LogRetentionDate__c` before the record settles.

## When to use it

Use this plugin when retention should vary by attributes other than scenario:

- User profile (e.g. integration users retain 7 days regardless of scenario).
- Origin type (e.g. all OmniStudio logs retain 90 days).
- Presence of specific tags (e.g. anything tagged `incident:*` retains 1 year).
- Custom logic (any combination of the above).

If your retention differs only by scenario name, the built-in `LoggerScenarioRule__mdt` is simpler. Use this plugin when scenario rules aren't expressive enough.

## Rule model

Each `LogRetentionRule__mdt` record defines one rule. Fields (subject to change - always check the CMDT in your org):

- `IsEnabled__c` - toggle without deleting.
- Match criteria - which logs the rule applies to.
- Target retention - the number of days to override with.
- Precedence - if multiple rules match, which one wins.

Check the plugin's README in the [nebula-logger/plugins/log-retention-rules](https://github.com/jongpie/NebulaLogger/tree/main/nebula-logger/plugins/log-retention-rules) directory for the current field list and example rule records.

## Composition with scenario rules

If both a scenario rule and a retention rule match the same log, the plugin's precedence rules determine which wins. Check the plugin's documentation for the exact resolution order.

## Where next

- [Log Retention Rules plugin reference](/reference/plugins/log-retention-rules/) - auto-generated Apex + CMDT reference.
- [Retention date semantics](/retention/retention-dates/) - how retention gets set in the core framework.
- [Plugin framework overview](/plugins/overview/) - how plugins hook in.
