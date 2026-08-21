---
title: Concepts
description: The runtime model that every Nebula Logger context follows.
---

Every Nebula Logger runtime context uses the same three-step model.

1. **Add** one or more log entries at a level (`ERROR`, `WARN`, `INFO`, `DEBUG`, `FINE`, `FINER`, `FINEST`).
2. **Enrich** each entry optionally with a record, exception, scenario, or tags.
3. **Persist** the buffered entries once at the end of the transaction with `saveLog()`.

Because every runtime writes to the same `Log__c` / `LogEntry__c` schema, a single transaction can span multiple runtimes and the console shows all of it in one place:

![Combined Apex + Flow log](/images/combined-apex-flow-log.png)

The runtime-specific pages that follow this one ([Apex](/NebulaLogger/logging-guide/apex/), [LWC](/NebulaLogger/logging-guide/lwc/), [Aura](/NebulaLogger/logging-guide/aura/), [Flow](/NebulaLogger/logging-guide/flow/), [OmniStudio](/NebulaLogger/logging-guide/omnistudio/)) show what this looks like in each context.

## Logging levels

Every context supports the same seven levels:

`ERROR`, `WARN`, `INFO`, `DEBUG`, `FINE`, `FINER`, `FINEST`.

Which levels actually persist depends on the effective `LoggerSettings__c.LoggingLevel__c` for the user. If the user's effective level is `WARN`, then `INFO` / `DEBUG` / `FINE` / `FINER` / `FINEST` calls are dropped at the framework level - no CPU spent, no record inserted. See [Configuration - Logging levels](/NebulaLogger/configuration/logging-levels/) for the full precedence.

Rule of thumb:

- `ERROR` / `WARN` / `INFO` - operationally significant. Keep on in production.
- `DEBUG` / `FINE` / `FINER` / `FINEST` - high-volume diagnostic detail. Leave in code, enable via settings when investigating.

## The buffer model

All log entries are buffered in memory during the transaction. `saveLog()` moves the buffer to the configured save method.

Because the buffer lives in memory, it is accessible during a test:

- `Logger.getBufferSize()` - how many entries are currently buffered.
- `Logger.flushBuffer()` - drop the buffer without persisting.
- `Logger.suspendSaving()` / `Logger.resumeSaving()` - gate persistence temporarily.

See [Testing your instrumentation](/NebulaLogger/logging-guide/testing/) for how to use these in tests.

## Save methods

`saveLog()` picks a save method. Four are supported:

- **`EVENT_BUS`** (default) - publishes a `LogEntryEvent__e` per entry. A trigger materializes them into `LogEntry__c` records.
- **`QUEUEABLE`** - defers work to an async job.
- **`REST`** - synchronous callout to the org's REST API.
- **`SYNCHRONOUS_DML`** - direct DML, skipping the platform event.

Override globally on `LoggerSettings__c.DefaultSaveMethod__c` or per-call via `Logger.saveLog(SaveMethod.QUEUEABLE)`. See [Configuration - Save methods](/NebulaLogger/configuration/logger-settings/#save-method) for the trade-offs.

## Scenarios

A **scenario** groups an entire transaction under a business process name (e.g. "Order Fulfillment", "Nightly Sync").

- Set once per transaction: `Logger.setScenario('Order Fulfillment')` (or `logger.setScenario(...)` in LWC).
- Every entry in the transaction inherits the scenario.
- Scenarios drive per-scenario retention overrides via `LoggerScenarioRule__mdt` - see [Retention & Purging](/NebulaLogger/retention/retention-dates/).

## Tags

A **tag** labels a specific entry (not the whole transaction).

- Add per entry: chain `.addTag('inventory')` off the level-specific call.
- Multiple tags per entry are supported: chain `.addTag('inventory').addTag('customer-onboarding')`.
- Tags are stored as `LoggerTag__c` records joined to entries via `LogEntryTag__c`. New tag names auto-create new `LoggerTag__c` records.

A common team convention is a controlled tag taxonomy: `domain:*`, `feature:*`, `incident:*`. See [Tags in depth](/NebulaLogger/logging-guide/tags/).

## Record association

Instead of embedding record IDs in message strings, attach the record structurally.

```apex
Logger.info('Credit check completed').setRecord(account);
```

`.setRecord(...)` captures a JSON snapshot of the record's state at log time. The log entry page renders both the current record and the snapshot, so investigating an old log shows what the record looked like _then_.

Overloads: `SObject`, `Id`, `List<SObject>`, `Map<Id, SObject>`, `System.Iterable<Id>`, and `setRecordId(Id)`. See [Apex logging](/NebulaLogger/logging-guide/apex/#attaching-records) for the full list.

## Async transaction linking

Async work (batch, queueable, scheduled) runs in a new Apex transaction, which produces its own `Log__c`. To keep the investigation walkable across the chain:

1. Capture the parent's transaction ID: `String parentId = Logger.getTransactionId();`
2. Pass it to the child.
3. Call `Logger.setParentLogTransactionId(parentId)` at the top of the child transaction.

The child `Log__c` populates `ParentLog__c` pointing at the parent, so the console can walk the chain. See [Apex logging - Async parent/child linking](/NebulaLogger/logging-guide/apex/#async-parentchild-linking) for a complete example.

## Where next

- [Apex](/NebulaLogger/logging-guide/apex/) - level methods, exception handling, record association, async linking.
- [Lightning Web Components](/NebulaLogger/logging-guide/lwc/) - the `c/logger` module.
- [Aura](/NebulaLogger/logging-guide/aura/) - `<c:logger>` component.
- [Flow](/NebulaLogger/logging-guide/flow/) - the four invocable actions.
- [OmniStudio](/NebulaLogger/logging-guide/omnistudio/) - Remote Action steps.
- [Testing your instrumentation](/NebulaLogger/logging-guide/testing/) - assert on the buffer and on persisted records.
