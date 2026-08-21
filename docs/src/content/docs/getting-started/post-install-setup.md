---
title: Post-install setup
description: Assign permission sets, configure LoggerSettings__c, and verify the install.
---

Installing the package is step one. Before logs actually persist, you also need to assign permission sets, configure the `LoggerSettings__c` hierarchy, and (usually) schedule the log purge batch. This page walks through each.

## 1. Assign permission sets

Nebula Logger ships four permission sets. Pick the right one for each user population.

| Permission Set     | Purpose                                              | Typical users                                       |
| ------------------ | ---------------------------------------------------- | --------------------------------------------------- |
| `LoggerAdmin`      | Full control of Nebula Logger data and features      | Platform admins, support leads                      |
| `LoggerLogViewer`  | Read-only access to logs and console features        | Operations, QA, support analysts                    |
| `LoggerEndUser`    | Limited day-to-day access with controlled visibility | Business users who need log visibility              |
| `LoggerLogCreator` | Minimal access needed to generate logs               | Integration users, Experience Cloud component users |

Assign via UI (Setup > Permission Sets) or CLI:

```bash
sf org assign permset --name LoggerAdmin --target-org <alias>
```

Repeat per user or use permission set groups for bulk assignment.

## 2. Configure LoggerSettings\_\_c at the org default

`LoggerSettings__c` is a hierarchy custom setting - values cascade org default -> profile -> user. Start by setting an org-default record so _something_ is defined for every user.

### Via the Logger Console

1. Open the **Logger Console** Lightning app.
2. Open the **Logger Settings** utility bar item (or the settings component on the home page).
3. Set at least these fields at the org default level:

| Field                                | Recommended starting value                                                   |
| ------------------------------------ | ---------------------------------------------------------------------------- |
| `IsEnabled__c`                       | `true`                                                                       |
| `LoggingLevel__c`                    | `INFO` in production, `DEBUG` or `FINE` in lower environments                |
| `DefaultSaveMethod__c`               | `EVENT_BUS` (default is fine for most orgs)                                  |
| `DefaultLogPurgeAction__c`           | `Delete` (default)                                                           |
| `DefaultNumberOfDaysToRetainLogs__c` | Something reasonable for your storage budget (30-90 days is a common choice) |

### Via Apex

```apex
Nebula__LoggerSettings__c settings = new Nebula__LoggerSettings__c(
  SetupOwnerId = UserInfo.getOrganizationId(),
  IsEnabled__c = true,
  LoggingLevel__c = 'INFO',
  DefaultSaveMethod__c = 'EVENT_BUS',
  DefaultNumberOfDaysToRetainLogs__c = 30
);
insert settings;
```

Drop the `Nebula__` prefix if you installed the unlocked package.

Note: older references may mention `DefaultLoggingLevel__c`. The active field is `LoggingLevel__c`.

## 3. Schedule the log purge batch

Nebula Logger sets `LogRetentionDate__c` on new `Log__c` records automatically, but nothing purges old logs until you schedule the batch job.

Run once from anonymous Apex:

```apex
String cronExpression = '0 0 2 * * ?'; // Every day at 2:00 AM
System.schedule('Nebula Logger - Daily Purge', cronExpression, new LogBatchPurgeScheduler());
```

Verify: Setup > Scheduled Jobs. You should see `Nebula Logger - Daily Purge` listed. Without this step, retention dates get set but nothing acts on them.

## 4. Smoke test

Prove the install works end to end.

```apex
Logger.info('Nebula Logger install smoke test');
Logger.saveLog();
```

Then query:

```apex
[SELECT Id, TransactionId__c, LoggingLevel__c FROM Log__c ORDER BY CreatedDate DESC LIMIT 1];
[SELECT Id, LogRetentionDate__c FROM Log__c ORDER BY CreatedDate DESC LIMIT 1];
```

The `Log__c` record should exist with a populated `LogRetentionDate__c`. If it doesn't, the most common cause is missing permission set assignment - `LoggerEndUser` for user contexts, `LoggerLogCreator` for integration/component contexts.

## First-run troubleshooting

- **No `Log__c` records after calling `saveLog()`**: check that the calling user has one of the four permission sets assigned. This is by far the most common issue.
- **`LogRetentionDate__c` is null**: `LoggerSettings__c.DefaultNumberOfDaysToRetainLogs__c` is not set at the effective hierarchy level for the logging user. Retention date is only calculated when a value is present.
- **Logs never purge**: `LogBatchPurgeScheduler` was never scheduled. See step 3.
- **Entries at `DEBUG` / `FINE` / `FINER` / `FINEST` don't persist**: `LoggerSettings__c.LoggingLevel__c` is set higher than the level you're calling. Lower it.

## Where next

- [Logging Guide - Concepts](/NebulaLogger/logging-guide/concepts/) - the core model with code examples.
- [Console & Operations](/NebulaLogger/console/logger-console-app/) - what the console app gives you.
- [Configuration](/NebulaLogger/configuration/logger-settings/) - deeper `LoggerSettings__c` documentation.
