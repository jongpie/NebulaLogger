---
title: Log Retention Rules plugin
description: CMDT-driven retention override rules that go beyond scenario rules.
---

The Log Retention Rules plugin adds a rule engine that overrides `LogRetentionDate__c` based on arbitrary log attributes - beyond the scenario-driven overrides `LoggerScenarioRule__mdt` supports natively.

## What it adds

- A `LogRetentionRule__mdt` custom metadata type. Each rule defines a match condition and a target retention.
- A trigger plugin that evaluates rules against new `Log__c` records and adjusts `LogRetentionDate__c` before the record settles.

## When to use it vs scenario rules

- **Scenario rules** (`LoggerScenarioRule__mdt`) - built into the core. Use when retention differs by business process name. Simple, no plugin required.
- **Log Retention Rules plugin** - use when retention should vary by log attributes other than scenario (user profile, origin type, presence of specific tags, custom logic). More flexible, requires the plugin install.

If scenario rules cover your needs, you don't need this plugin.

## Installation

The Log Retention Rules plugin ships as its own unlocked package. See the [plugin page](/plugins/log-retention-rules/) in the Plugins section for install details.

## Rule model

Each `LogRetentionRule__mdt` record defines one rule. Fields (subject to change - always check the CMDT in your org):

- `IsEnabled__c` - toggle without deleting.
- Match criteria - which logs the rule applies to.
- Target retention - the number of days to override with.
- Precedence - if multiple rules match, which one wins.

## Where next

- [Retention date semantics](/retention/retention-dates/) - how retention gets set in the first place.
- [Plugins - Log Retention Rules](/plugins/log-retention-rules/) - the plugin's own page.
- [Log Retention Rules plugin reference](/reference/plugins/log-retention-rules/) - auto-generated Apex + CMDT reference.
