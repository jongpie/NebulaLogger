---
title: Retention date semantics
description: How Log__c.LogRetentionDate__c gets populated and how it drives purging.
---

Every `Log__c` record has a `LogRetentionDate__c`. When that date passes, the log becomes eligible for purging by `LogBatchPurger`. This page documents how the retention date is set.

## When retention date is set

At `Log__c` insert time. The framework combines:

1. **Scenario override** - if the log has a scenario and a matching `LoggerScenarioRule__mdt` has `IsLogRetentionOverrideEnabled__c = true`, that rule's `NumberOfDaysToRetainLogs__c` wins.
2. **Hierarchy default** - otherwise `LoggerSettings__c.DefaultNumberOfDaysToRetainLogs__c` for the logging user (walking user -> profile -> org default).

If neither yields a value, `LogRetentionDate__c` is left null and the log is never auto-purged.

## Semantics

- `LogRetentionDate__c = CreatedDate + N days`, where N is the resolved retention days.
- Once set, the date is not automatically updated. Editing `LoggerSettings__c` or the scenario rule after a log is inserted does not change the log's retention date.
- The purge batch treats logs as eligible when `LogRetentionDate__c <= System.today()`.

## What "eligible" means

`LogBatchPurger` (see [LogBatchPurger](/retention/log-batch-purger/)) queries for eligible logs and runs the configured **purge action** (see [Purge actions](/retention/purge-actions/)) on each.

If no `LogBatchPurger` is scheduled, retention dates are populated but nothing acts on them. That is the single most common cause of "we set retention to 30 days but logs from six months ago are still there."

## Overriding retention on a specific log

Two supported mechanisms:

- **Per-scenario via `LoggerScenarioRule__mdt`** - the intended path for policy-level overrides. Regulated processes (keep 7 years) or high-volume test scenarios (purge in 24 hours) fit here.
- **Direct edit** - admins with edit access on `Log__c` can change `LogRetentionDate__c` on an individual record. Useful for holding onto a specific log longer than default (e.g. an incident record).

For bulk overrides beyond scenario rules, install the [Log Retention Rules plugin](/plugins/log-retention-rules/), which adds a CMDT-driven rule engine that sets retention based on log attributes.

## Verifying retention is working

```apex
Logger.info('Test entry');
Logger.saveLog();

// After Test.stopTest() / saveLog completes
Log__c latest = [SELECT LogRetentionDate__c FROM Log__c ORDER BY CreatedDate DESC LIMIT 1];
System.Assert.isNotNull(latest.LogRetentionDate__c);
```

If `LogRetentionDate__c` is null, either `LoggerSettings__c.DefaultNumberOfDaysToRetainLogs__c` is not set for the current user's hierarchy, or an enabled `LoggerScenarioRule__mdt` matched but had `IsLogRetentionOverrideEnabled__c = false` and no other retention source resolved.

## Where next

- [LogBatchPurger](/retention/log-batch-purger/) - the batch job that acts on retention dates.
- [Purge actions](/retention/purge-actions/) - what happens when a log ages out.
- [Log Retention Rules plugin](/plugins/log-retention-rules/) - CMDT-driven retention overrides.
