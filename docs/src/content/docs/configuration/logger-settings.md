---
title: LoggerSettings__c hierarchy
description: The hierarchy custom setting that controls Nebula Logger runtime behavior.
---

`LoggerSettings__c` is a hierarchy custom setting - values cascade **org default -> profile -> user**. It's the primary knob for controlling how Nebula Logger behaves at runtime.

## The hierarchy

Salesforce hierarchy custom settings resolve at read time by walking three levels:

1. If a user-level record exists for the current user, its values win.
2. Otherwise, if a profile-level record exists for the current user's profile, its values win.
3. Otherwise, the org default record's values win.

Nebula Logger reads the effective record every time it needs a setting - so changes take effect immediately without a code deploy.

## Fields you'll use most

| Field                                | Purpose                                                                                        |
| ------------------------------------ | ---------------------------------------------------------------------------------------------- |
| `IsEnabled__c`                       | Master on/off switch. When `false`, no entries are added to the buffer.                        |
| `LoggingLevel__c`                    | Effective minimum level. Entries below this level are dropped at the framework level.          |
| `DefaultSaveMethod__c`               | Default value for `Logger.saveLog()` - `EVENT_BUS`, `QUEUEABLE`, `REST`, or `SYNCHRONOUS_DML`. |
| `DefaultLogPurgeAction__c`           | What the purge batch does when a log ages out. Default `Delete`.                               |
| `DefaultNumberOfDaysToRetainLogs__c` | Days between log insert and eligibility for purging. Null = no automatic purge.                |

Older docs may reference `DefaultLoggingLevel__c`. The active field is `LoggingLevel__c`.

## Where to edit

- **Logger Console utility bar** - the "Logger Settings" panel edits the effective record for the current user without leaving the console.
- **Setup > Custom Settings > Logger Settings** - full org-wide view. Manage user and profile-level records here.
- **Anonymous Apex** - `insert new LoggerSettings__c(SetupOwnerId = ..., ...)`. Useful in test setup and deploy scripts.

## Common patterns

### Environment-aware defaults

Tune the org default record to match the environment:

| Environment | Suggested `LoggingLevel__c` | Reason                                                           |
| ----------- | --------------------------- | ---------------------------------------------------------------- |
| Production  | `INFO` or `WARN`            | Reduce noise and storage impact while preserving incident signal |
| UAT         | `INFO`                      | Validate business flows without excessive detail                 |
| QA          | `DEBUG` or `FINE`           | Support defect reproduction and integration testing              |
| Sandbox/Dev | `FINE` to `FINEST`          | Deep diagnostics during active development                       |

### Temporary incident window

Increase verbosity temporarily for a specific user or profile:

1. Create a user- or profile-level `LoggerSettings__c` record.
2. Set `LoggingLevel__c` to `DEBUG` or `FINE` for that scope.
3. Investigate.
4. Delete the record when done, so the org default reasserts.

### Debug users retain longer, integration users retain shorter

Because retention lives in the same hierarchy, you can tune it per profile:

- **Developer profile**: longer `DefaultNumberOfDaysToRetainLogs__c` so investigation work isn't lost.
- **Integration user profile**: shorter retention so their (much larger) log volume doesn't dominate storage.

Other profiles inherit from the org default.

## Save method

`DefaultSaveMethod__c` sets the default `Logger.saveLog()` behavior at the hierarchy level. Values:

| Value             | Use when                                               | Trade-off                                             |
| ----------------- | ------------------------------------------------------ | ----------------------------------------------------- |
| `EVENT_BUS`       | General-purpose app logging (default).                 | Depends on platform event capacity.                   |
| `QUEUEABLE`       | Deferring work to reduce synchronous CPU pressure.     | Adds async dependency and queueable execution timing. |
| `REST`            | Avoiding mixed-DML constraints in the current context. | Requires callout path and valid session context.      |
| `SYNCHRONOUS_DML` | Immediate persistence, tolerating rollback risk.       | Log inserts are rolled back if transaction fails.     |

Individual calls can override this via `Logger.saveLog(SaveMethod.QUEUEABLE)`.

## Where next

- [LoggerParameter\_\_mdt feature flags](/NebulaLogger/configuration/logger-parameters/) - global framework flags.
- [Logging levels](/NebulaLogger/configuration/logging-levels/) - level precedence in depth.
- [Retention date semantics](/NebulaLogger/retention/retention-dates/) - retention field behavior.
- [`LoggerSettings__c` reference](/NebulaLogger/reference/custom-objects/loggersettings__c/) - full field list.
