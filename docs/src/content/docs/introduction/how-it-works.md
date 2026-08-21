---
title: How it works
description: Nebula Logger's runtime architecture - buffered entries, save methods, and the objects that hold your log data.
---

Nebula Logger is a native Salesforce app. All storage, execution, and enrichment happen inside the org. There are no external dependencies.

## The runtime flow

1. Your code calls a level-specific method (`Logger.info(...)`, `logger.error(...)`, an invocable action, or a `CallableLogger` action). The framework appends an in-memory `LogEntryEvent__e` payload to a per-transaction buffer.
2. Optional enrichment methods (`.setRecord(...)`, `.addTag(...)`, `.setScenario(...)`, `.setExceptionDetails(...)`) modify that buffered entry.
3. Your code calls `saveLog()` at the end of the transaction. The buffer is handed to the configured **save method**, which decides how the data reaches durable storage.
4. The save path publishes `LogEntryEvent__e` platform events (or writes directly, depending on save method). A platform event trigger materializes each event into `LogEntry__c` records and their parent `Log__c` record.
5. Trigger and batch plugins fire during the materialization step and during the eventual purge, giving you extension points for enrichment, notification, archival, and custom purge behavior.

## The objects

| Object              | Role                                                                                                                                          |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `Log__c`            | The transaction. One record per `saveLog()` call. Rolls up totals, holds the scenario, save method, transaction ID, and user context.         |
| `LogEntry__c`       | An individual log entry. Multiple per `Log__c`. Holds level, message, timestamp, record snapshot, exception details, origin, and stack trace. |
| `LoggerScenario__c` | A named business process a transaction belongs to (e.g. "Order Fulfillment"). One per unique scenario name across the org.                    |
| `LoggerTag__c`      | A tag definition. One per unique tag name.                                                                                                    |
| `LogEntryTag__c`    | Junction between `LogEntry__c` and `LoggerTag__c`.                                                                                            |
| `LogEntryEvent__e`  | The platform event used by the default save method. Never persisted directly - always materialized into `LogEntry__c`.                        |

## Save methods

`saveLog()` picks a save method - the default is `EVENT_BUS`, but three others exist to handle constraints the default cannot.

- **`EVENT_BUS`** (default) - publishes a `LogEntryEvent__e` for each buffered entry. A platform event trigger materializes them into `LogEntry__c` and `Log__c` records.
- **`QUEUEABLE`** - defers work to an async queueable job. Useful when the current transaction is CPU-bound.
- **`REST`** - makes a synchronous callout to the org's REST API. Useful when you are already inside a platform event trigger or need to avoid mixed-DML restrictions.
- **`SYNCHRONOUS_DML`** - writes `Log__c` and `LogEntry__c` records directly, skipping the platform event. Fastest but rolls back with the transaction if anything throws.

The default is set org-wide on `LoggerSettings__c.DefaultSaveMethod__c` and overridable per call via `Logger.saveLog(SaveMethod)`.

## Configuration surface

Nebula Logger avoids code-based configuration.

- **`LoggerSettings__c`** is a hierarchy custom setting - values cascade org default -> profile -> user. Controls whether logging is enabled, the effective logging level, default save method, retention days, and default purge action.
- **`LoggerParameter__mdt`** provides global feature flags for the framework itself (enable/disable subsystems, tune internal behavior).
- **`LogEntryDataMaskRule__mdt`** defines regex-based data masking rules applied to entries before persist.
- **`LoggerScenarioRule__mdt`** overrides logging level and retention days for specific scenarios.
- **`LoggerPlugin__mdt`** registers plugins against the trigger and batch extension points.

## Async transaction linking

Async work (queueable, batch, scheduled) runs in a new Apex transaction with its own `Log__c` record. To keep an investigation walkable across the chain:

1. Capture the parent transaction ID with `Logger.getTransactionId()`.
2. Pass it to the child transaction.
3. Call `Logger.setParentLogTransactionId(parentId)` at the top of the child transaction.

The child `Log__c` populates `ParentLog__c` pointing at the parent, so the console shows the chain.

## Where next

- [Feature tour](/NebulaLogger/introduction/feature-tour/) - a broader walkthrough.
- [Concepts](/NebulaLogger/logging-guide/concepts/) - the runtime model with code examples.
- [Configuration](/NebulaLogger/configuration/logger-settings/) - the settings hierarchy in depth.
