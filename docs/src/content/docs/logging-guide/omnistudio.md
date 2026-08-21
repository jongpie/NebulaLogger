---
title: OmniStudio
description: Logging from OmniScripts and Integration Procedures using CallableLogger Remote Action steps.
---

OmniScripts and Integration Procedures log via the `CallableLogger` Apex class, invoked declaratively as a Remote Action step. No Apex authoring required.

## The Remote Action step

Configure a **Remote Action** step in the OmniScript or Integration Procedure with:

- **Remote Class**: `Nebula.CallableLogger` if the managed package is installed, otherwise `CallableLogger`.
- **Remote Method**: `newEntry` to add an entry (optionally saving in the same call), or `saveLog` to persist pending entries.
- **Additional Input**: pass the input keys documented below declaratively.

## Input keys

The same keys used by the [ISV optional-dependency pattern](/NebulaLogger/for-package-developers/optional-dependency/) apply here.

| Key                                                | Purpose                                                                                       |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `loggingLevel`                                     | Level name (`INFO`, `ERROR`, `WARN`, `DEBUG`, `FINE`, `FINER`, `FINEST`).                     |
| `message`                                          | Entry message.                                                                                |
| `saveLog`                                          | Set to `true` to persist immediately after adding the entry.                                  |
| `saveMethodName`                                   | Override the save method for this call (`EVENT_BUS`, `QUEUEABLE`, `REST`, `SYNCHRONOUS_DML`). |
| `tags`                                             | `List<String>` of tag names.                                                                  |
| `exception`                                        | An exception instance to attach.                                                              |
| `recordId` / `record` / `recordList` / `recordMap` | Record association, same shape as the Apex `setRecord(...)` overloads.                        |
| `scenario`                                         | Scenario for the transaction.                                                                 |
| `parentLogTransactionId`                           | Parent transaction ID for async linking.                                                      |

## Automatic OmniStudio context

`CallableLogger` automatically:

- Stamps `OriginType__c = 'OmniStudio'` on entries produced by OmniStudio Remote Action steps.
- Captures the `omniProcessId` from OmniStudio's default input into the entry, so console filtering can slice by OmniStudio process.
- Appends any extra input keys beyond the known ones as an "OmniStudio Input" block on the entry's message, so process-specific context flows into the log without extra plumbing.

## Actions

Every action accepts a `Map<String, Object>` and returns a `Map<String, Object>` output (with `isSuccess`, `transactionId`, `parentLogTransactionId`, `requestId`, and error details on failure).

| Action                                                    | Purpose                                                                                                              |
| --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `newEntry`                                                | Add a log entry. Supports every enrichment key above.                                                                |
| `saveLog`                                                 | Persist buffered entries. Optionally accepts `saveMethodName`.                                                       |
| `getTransactionId`                                        | Return the current transaction ID (for async parent/child linking).                                                  |
| `getParentLogTransactionId` / `setParentLogTransactionId` | Read / set the parent transaction ID.                                                                                |
| `getScenario` / `setScenario` / `endScenario`             | Read / set / end the transaction's scenario.                                                                         |
| `tryCatch`                                                | Shorthand for `newEntry` with `loggingLevel=ERROR` and a serialized-input message; useful in generic `catch` blocks. |

## Where next

- [Optional dependency via Callable](/NebulaLogger/for-package-developers/optional-dependency/) - the same `CallableLogger` class from Apex.
- [Concepts](/NebulaLogger/logging-guide/concepts/) - the core model.
