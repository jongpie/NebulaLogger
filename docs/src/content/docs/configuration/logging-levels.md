---
title: Logging levels
description: How Nebula Logger decides which entries persist based on the effective logging level.
---

Nebula Logger supports seven logging levels, in descending severity:

**`ERROR` > `WARN` > `INFO` > `DEBUG` > `FINE` > `FINER` > `FINEST`**

Whether an entry persists depends on the **effective logging level** for the transaction. Entries below the effective level are dropped at the framework layer - no CPU spent formatting them, no record inserted.

## Precedence

The framework picks the effective level in this order (highest priority first):

1. **Per-scenario override** - if the transaction has a scenario and a matching `LoggerScenarioRule__mdt` exists with a level override enabled, that level wins for the whole transaction.
2. **User-level `LoggerSettings__c.LoggingLevel__c`** - if the current user has a user-level record, its level wins.
3. **Profile-level `LoggerSettings__c.LoggingLevel__c`** - if the user's profile has a record, its level wins.
4. **Org default `LoggerSettings__c.LoggingLevel__c`** - the fallback.

If no level is defined anywhere, entries do not persist. This is intentional - it forces every org to make an explicit choice.

## What each level means

There is no framework enforcement of what belongs at each level - the levels are conventions. The one most teams settle on:

| Level    | Convention                                                              |
| -------- | ----------------------------------------------------------------------- |
| `ERROR`  | Something failed. Requires investigation.                               |
| `WARN`   | Something is suspicious but not a failure. Might require investigation. |
| `INFO`   | Business milestone. Useful in a normal transaction.                     |
| `DEBUG`  | Diagnostic detail useful when investigating.                            |
| `FINE`   | Verbose diagnostic detail - method entry/exit, decision points.         |
| `FINER`  | More verbose - individual iterations, intermediate values.              |
| `FINEST` | Most verbose - everything.                                              |

**Rule of thumb**: run production at `INFO` or `WARN`. Leave `DEBUG` / `FINE` / `FINER` / `FINEST` calls in the code - they cost nothing at runtime because the framework drops them before they cost anything. Turn them on via `LoggerSettings__c` when investigating.

## Per-scenario overrides

To temporarily raise the level for one business process without lifting it org-wide, create a `LoggerScenarioRule__mdt` record whose `Scenario__c` matches the value passed to `Logger.setScenario(...)`.

Set:

- `IsEnabled__c` = `true`.
- The relevant "override enabled" flag for logging level on the CMDT.
- The target level.

The scenario rule beats the hierarchy for transactions with a matching scenario.

## Where next

- [LoggerSettings\_\_c hierarchy](/configuration/logger-settings/) - the hierarchy custom setting.
- [Scenarios](/logging-guide/scenarios/) - how to set the scenario on a transaction.
- [`LoggerScenarioRule__mdt` reference](/reference/custom-objects/loggerscenariorule__mdt/) - full field list.
