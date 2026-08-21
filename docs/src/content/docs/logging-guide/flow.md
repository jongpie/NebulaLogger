---
title: Flow
description: Logging from Flow and Process Builder using the four shipped invocable actions.
---

Nebula Logger ships four invocable actions in the **Logging** category. Every Flow type that supports invocable actions can call them.

![Flow logger actions](/images/flow-logger-actions.png)

## The four actions

| Action                                           | Purpose                                                                                  |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| `Add Log Entry`                                  | Add an entry with a message and logging level.                                           |
| `Add Log Entry for an SObject Record`            | Add an entry linked to one record. Captures a JSON snapshot of the record.               |
| `Add Log Entry for an SObject Record Collection` | Add an entry linked to a collection of records.                                          |
| `Save Log`                                       | Persist buffered entries. Call this once at the end of any Flow path that added entries. |

## Building a Flow that logs

The pattern is the same as Apex: add entries, then save.

1. Add one or more `Add Log Entry*` actions at the points in the Flow where you want a log entry.
2. Add a single `Save Log` action at the end of every Flow path that added entries.
3. Fill in the action inputs.

![Flow builder: logging invocable actions](/images/flow-builder-logging-invocable-actions.png)

Example: a Flow that logs a Case record with the `Add Log Entry for an SObject Record` action.

![Flow builder: logging a Case](/images/flow-builder-log-case.png)

Example: an `Add Log Entry` action with tags applied.

![Flow builder: log entry with tags](/images/flow-builder-log-with-tags.png)

The resulting `Log__c` and `LogEntry__c` records in the console:

![Flow log results](/images/flow-log.png)

Every `Add Log Entry*` action accepts these inputs (some optional):

| Input                          | Purpose                                                                                    |
| ------------------------------ | ------------------------------------------------------------------------------------------ |
| `Logging Level`                | `ERROR`, `WARN`, `INFO`, `DEBUG`, `FINE`, `FINER`, `FINEST`.                               |
| `Message`                      | The log message. Use merge syntax to include Flow variables: `{!recordId}`.                |
| `Scenario`                     | Business process this transaction belongs to. Set on any action - applies to whole.        |
| `Tags` (semicolon-delimited)   | Tag names to apply to this entry.                                                          |
| `Record` / `Record Collection` | The record(s) to attach (for the SObject variants).                                        |
| `Save Log`                     | If true, persist immediately after adding the entry (skip the separate `Save Log` action). |

Setting `Scenario` on any `Add Log Entry*` action applies to the whole transaction - Flow calls `Logger.setScenario(...)` under the hood.

## Merge syntax

Standard Flow merge syntax works in the `Message` input. Anything Flow can resolve at run time can be interpolated:

- `{!recordId}` - the current record ID.
- `{!Account.Name}` - a field from a Flow variable.
- `{!$User.Username}` - global variables.

## When to save inline vs at the end

- **Inline (`Save Log = true` on the action)** - simplest for single-entry Flows. One action call, one log entry, one save.
- **Batch save at the end** - preferred when the Flow adds multiple entries. One `Log__c` record with several `LogEntry__c` children is more useful for investigation than several unrelated single-entry logs.

Every path through the Flow that added entries needs to hit `Save Log`. Miss a path and the entries on that path never persist.

## Where next

- [Concepts](/NebulaLogger/logging-guide/concepts/) - the core model these actions implement.
- [Scenarios](/NebulaLogger/logging-guide/scenarios/) - grouping Flow-driven transactions under a business process.
- [Tags](/NebulaLogger/logging-guide/tags/) - tag taxonomy conventions.
