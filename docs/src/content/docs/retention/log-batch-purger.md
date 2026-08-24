---
title: LogBatchPurger
description: The batch job that deletes or archives logs whose LogRetentionDate__c has passed.
---

`LogBatchPurger` is the Apex batch job that acts on retention dates. It queries for logs whose `LogRetentionDate__c` is past-due and runs the configured [purge action](/NebulaLogger/retention/purge-actions/) on each.

## The batch does not run automatically

Nebula Logger sets `LogRetentionDate__c` on new `Log__c` records automatically. Actually purging them requires scheduling `LogBatchPurger` via `LogBatchPurgeScheduler`.

Run once from anonymous Apex:

```apex
String cronExpression = '0 0 2 * * ?'; // Every day at 2:00 AM
System.schedule('Nebula Logger - Daily Purge', cronExpression, new LogBatchPurgeScheduler());
```

Verify: Setup > Scheduled Jobs. You should see the job listed.

## Cron expression cookbook

Salesforce cron format is `Seconds Minutes Hours Day-of-Month Month Day-of-Week Year`. Common patterns:

| Cadence             | Expression        |
| ------------------- | ----------------- |
| Daily at 2am        | `0 0 2 * * ?`     |
| Every 6 hours       | `0 0 */6 * * ?`   |
| Every Sunday at 3am | `0 0 3 ? * SUN *` |
| First of the month  | `0 0 3 1 * ?`     |

## Adjusting batch size

The default batch size is fine for most orgs. For very large log volumes, tune:

```apex
Integer batchSize = 500;
System.schedule('Nebula Logger - Daily Purge', cronExpression, new LogBatchPurgeScheduler(batchSize));
```

`LogBatchPurgeScheduler` has a no-arg constructor for the default and an `Integer batchSize` constructor for override. Higher batch sizes reduce total execution time at the cost of longer individual transactions.

## What LogBatchPurger processes

`LogBatchPurger` walks the object hierarchy from the lowest level up:

1. `LogEntryTag__c` (junction records)
2. `LogEntry__c` (child entries)
3. `Log__c` (parent transactions)

It processes records whose parent `Log__c.LogRetentionDate__c` is past-due. This ordering matters because `LogEntry__c` records reference `Log__c` - deleting the parent first would fail.

## Manually triggering a purge

The Logger Console home page has a **`logBatchPurge`** component that triggers the batch on demand and reports counts. Useful for:

- Verifying the job runs correctly after a fresh install.
- Cleaning up test-generated logs immediately.
- Investigating retention behavior without waiting for the scheduled run.

## What happens to each record

The purge **action** determines the fate of each aged-out record. See [Purge actions](/NebulaLogger/retention/purge-actions/) for the options - by default, records are hard-deleted (no Recycle Bin).

## Where next

- [Purge actions](/NebulaLogger/retention/purge-actions/) - options for what happens when a log ages out.
- [Log Retention Rules plugin](/NebulaLogger/plugins/log-retention-rules/) - CMDT-driven retention overrides.
- [`LogBatchPurger` reference](/NebulaLogger/metadata-reference/) - class-level details (see the Metadata Reference section).
