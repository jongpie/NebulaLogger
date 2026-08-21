---
title: Purge actions
description: What LogBatchPurger does when a log ages out - and how plugins can add new actions.
---

`Log__c.LogPurgeAction__c` tells `LogBatchPurger` what to do when a log ages out. The value is set at insert time from `LoggerSettings__c.DefaultLogPurgeAction__c` on the effective hierarchy record.

## Built-in action

- **`Delete`** (default) - the batch hard-deletes the `Log__c` and its child `LogEntry__c` records. They do not sit in the Recycle Bin. Once deleted, they are gone.

## Plugin-provided actions

Plugins can register additional purge actions. When installed, their action value becomes selectable in `LoggerSettings__c.DefaultLogPurgeAction__c`.

- **Big Object Archiving plugin** - adds an `Archive` action that copies logs to a `LogEntryArchive__b` big object _before_ deletion, so the data remains queryable long-term. See [Big Object Archiving plugin](/NebulaLogger/plugins/big-object-archiving/).

## Choosing an action per log

`LogPurgeAction__c` is populated at `Log__c` insert time from the hierarchy default. To use different actions for different logs:

1. Set the org default to your most common action.
2. Use user- or profile-level `LoggerSettings__c` records to override for populations that need different behavior.
3. Or, for scenario-driven differentiation, use `LoggerScenarioRule__mdt` retention rules combined with policy about which action applies to which scenario.

## Overriding on a specific log

Admins with edit access on `Log__c` can change `LogPurgeAction__c` on an individual record before the retention date passes. Useful for holding an incident record's data via a different action than the default.

## Where next

- [Retention date semantics](/NebulaLogger/retention/retention-dates/) - how retention dates get populated.
- [LogBatchPurger](/NebulaLogger/retention/log-batch-purger/) - the batch that acts on retention.
- [Big Object Archiving plugin](/NebulaLogger/plugins/big-object-archiving/) - the archival plugin.
