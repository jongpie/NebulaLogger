---
name: nebula-logger-purging-and-retention
description: Use this skill when the user wants to configure how long Nebula Logger keeps log records before deleting or archiving them. Covers retention date semantics on `Log__c`, the `LogBatchPurger` batch job, `LogBatchPurgeScheduler`, purge action values, and how to tune retention per user, profile, or scenario.
---

# Log Retention and Purging in Nebula Logger

## The Retention Model

Every `Log__c` record has a `LogRetentionDate__c`. When that date passes, the log becomes eligible for purging by `LogBatchPurger`. The retention date is set at insert time on `Log__c` from a combination of:

- `LoggerSettings__c.DefaultNumberOfDaysToRetainLogs__c` on the effective hierarchy record.
- Optionally, `LoggerScenarioRule__mdt.NumberOfDaysToRetainLogs__c` when the log's scenario matches a scenario rule (scenario-specific overrides win over the hierarchy default).

If no retention days are configured, `LogRetentionDate__c` is left null and the log is never auto-purged.

## `LoggerSettings__c` Retention Fields

The retention side of `LoggerSettings__c` is a hierarchy custom setting - values cascade org default -> profile -> user. The relevant fields:

| Field                                | Purpose                                                                                                                   |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| `DefaultNumberOfDaysToRetainLogs__c` | Days between log insert and eligibility for purging. Null = no automatic purge.                                           |
| `DefaultLogPurgeAction__c`           | What the batch job does when it processes an eligible log. Default value is `Delete`.                                     |
| `IsEnabled__c`                       | Master switch; disabling logging at a hierarchy level also stops new `Log__c` records from being written for those users. |

## Purge Actions

`Log__c.LogPurgeAction__c` (populated from `LoggerSettings__c.DefaultLogPurgeAction__c` at insert time) tells `LogBatchPurger` what to do when a log ages out:

- **`Delete`** (default): The batch job hard-deletes the `Log__c` and its child `LogEntry__c` records. They do not sit in the Recycle Bin.
- Plugin-provided actions: Some Nebula Logger plugins add their own purge actions. For example, the `big-object-archiving` plugin copies logs into a big object before deletion so the data remains queryable long-term. When such a plugin is installed, its purge action becomes a valid value for `LogPurgeAction__c`.

## Scheduling the Purge Job

`LogBatchPurger` does not run automatically. Schedule it via `LogBatchPurgeScheduler`:

```apex
// Run daily at 2am - adjust the cron expression for your org
String cronExpression = '0 0 2 * * ?';
System.schedule('Nebula Logger - Daily Purge', cronExpression, new LogBatchPurgeScheduler());
```

`LogBatchPurgeScheduler` has a no-arg constructor for default batch size and a `LogBatchPurgeScheduler(Integer batchSize)` constructor for tuning throughput.

Without a scheduled job, `LogRetentionDate__c` still gets set correctly on new logs, but nothing ever purges them. An unscheduled purger is the most common cause of "we set retention to 30 days but logs from six months ago are still there."

## Per-Scenario Retention

To keep certain business processes' logs longer (or shorter) than the default, create a `LoggerScenarioRule__mdt` record whose `Scenario__c` matches the value passed to `Logger.setScenario(...)`. Set:

- `IsEnabled__c` = `true` (otherwise the rule is inert).
- `IsLogRetentionOverrideEnabled__c` = `true` (this is the gate that actually enables the retention override - a `NumberOfDaysToRetainLogs__c` value with this flag off does nothing).
- `NumberOfDaysToRetainLogs__c` = the target retention in days for logs matching this scenario.

Use scenario rules for regulated processes ("keep financial-audit logs for 7 years") or for high-volume test scenarios ("purge integration-smoke-test logs after 24 hours") rather than trying to tune the hierarchy globally.

## Per-User / Per-Profile Retention

Because `LoggerSettings__c` is a hierarchy custom setting, retention can be tuned per user or per profile. Common patterns:

- **Debug users retain longer**: Give developer profiles a longer `DefaultNumberOfDaysToRetainLogs__c` so investigation work isn't lost.
- **High-volume integration users retain shorter**: Give integration user profiles a shorter retention so their (much larger) log volume doesn't dominate storage.

Set the profile-level value in `LoggerSettings__c` for those profiles; it inherits from org default for everyone else.

## Verifying Retention Setup

Before assuming retention is working, verify these three things in the target org:

1. `LoggerSettings__c` at the org default level has a non-null `DefaultNumberOfDaysToRetainLogs__c`.
2. `LogBatchPurgeScheduler` is scheduled (check Setup -> Scheduled Jobs).
3. New `Log__c` records get a `LogRetentionDate__c` populated. Run a quick test log and query `SELECT Id, LogRetentionDate__c FROM Log__c ORDER BY CreatedDate DESC LIMIT 1`.

If any of those three is missing, retention is not actually in effect.

## Storage Considerations

- `Log__c` and `LogEntry__c` count against custom object storage. `LogEntry__c` is typically the volume driver (many entries per log).
- Higher `LoggerSettings__c.LoggingLevel__c` values (`FINE`, `FINER`, `FINEST`) produce dramatically more entries. Combine environment-appropriate logging levels with retention windows to control storage growth - see [nebula-logger-best-practices](../nebula-logger-best-practices/SKILL.md).
- If storage becomes a real constraint, either shorten retention, raise logging level thresholds in production, or install the `big-object-archiving` plugin to offload aged data to a big object.

## Related Skills

- [nebula-logger-install](../nebula-logger-install/SKILL.md) - Initial `LoggerSettings__c` configuration.
- [nebula-logger-best-practices](../nebula-logger-best-practices/SKILL.md) - Environment-aware logging levels that pair with retention.
- [nebula-logger-plugin-development](../nebula-logger-plugin-development/SKILL.md) - Building a custom purge-action plugin (e.g. archive to an external system).
