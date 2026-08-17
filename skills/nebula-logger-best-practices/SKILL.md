---
name: nebula-logger-best-practices
description: Use this skill when the user wants to review, harden, or standardize Nebula Logger usage across a Salesforce team. Covers operational logging standards, environment-aware settings, limit-aware design, and governance guardrails.
---

# Nebula Logger Best Practices and Governance

## Team-Wide Practices

Use these defaults when reviewing pull requests or designing logging conventions.

1. Reserve `ERROR`, `WARN`, and `INFO` for information that is operationally significant.
2. Use `DEBUG`, `FINE`, `FINER`, and `FINEST` for high-volume diagnostic detail. Combined with `LoggerSettings__c.LoggingLevel__c`, these can be left in code without adding runtime overhead in production and switched on only when deeper diagnostics are needed.
3. Tune `LoggerSettings__c` data by environment.
   - Configure `LoggingLevel__c` to `ERROR`, `WARN`, or `INFO` in production orgs to reduce logging noise (or change to `DEBUG`, `FINE`, `FINER`, or `FINEST` when trying to debug)
   - Configure scheduled purging and retention windows (`DefaultLogPurgeAction__c`, `DefaultNumberOfDaysToRetainLogs__c`)
4. Use static method `Logger.setScenario()`, and instance methods `LogEntryEventBuilder.addTag()` and `LogEntryEventBuilder.addTags()` for business-process grouping.
   - Define a controlled naming convention for scenarios & tags that make sense to your team
5. Use instance methods on `LogEntryEventBuilder` to further enrich data, instead of embedding extra data directly in message strings. There are several method overloads available:
   - `.setExceptionDetails(...)`
   - `.setApprovalResult(...)`
   - `.setDatabaseResult(...)`
   - `.setRecord(...)`
   - `.setHttpRequestDetails(...)`
   - `.setHttpResponseDetails(...)`
   - `.setRestRequestDetails(...)`
   - `.setRestResponseDetails(...)`
   - `.setField(...)`
6. Call `Logger.saveLog()` deliberately - don't call it after every log entry, and never inside a tight loop. Be strategic when calling it, just like when making DML calls in Apex.
   - `Logger.info(...)` / `.error(...)` / etc. only add entries to an in-memory buffer. Nothing persists until `saveLog()` runs. If a transaction ends without calling `saveLog()`, everything that was buffered is lost - so `saveLog()` still has to be called before the transaction commits.
   - Every `saveLog()` call is a real platform operation with real cost. With the default `EVENT_BUS` save method, each call to `saveLog()` calls `System.EventBus.publish(List<LogEntryEvent__e>)` once, which consumes one slot against `System.Limits.getLimitPublishImmediateDML()` (100 per transaction) and one increment against the org's daily platform event publish allocation. The other save methods have their own limits: `QUEUEABLE` consumes an async job slot (`System.Limits.getLimitQueueableJobs()`), `REST` consumes a callout, and `SYNCHRONOUS_DML` consumes regular DML rows and statements. None of them are free.
   - Multiple `saveLog()` calls in a transaction are fine, and often the right choice. Reasonable places to save intermediate state include after each chunk in a batch, at the end of each iteration of a long-running loop's outer scope (never the inner scope - see below), before an async handoff (Queueable / Future / Batchable), and inside a `finally` block that catches an exception you're about to rethrow. Each save publishes only what's in the buffer at that moment, so the entries persist even if the rest of the transaction later blows up.
   - What's wrong is calling `saveLog()` after every single log entry. That turns N log calls into N platform-event publishes, burns through `getLimitPublishImmediateDML()` (100 per transaction) fast, and eats into the org's daily platform event allocation for no operational benefit. If you find yourself typing `Logger.info(...); Logger.saveLog();` repeatedly, buffer the entries and save once after the group.
   - Never call `saveLog()` inside the innermost body of a loop over records. Buffer entries in the loop and call `saveLog()` after the loop (or at safe checkpoints - after N iterations, after a chunk of work, etc.), not after each record.
   - Place a `Logger.saveLog()` call in a `finally` block for transactional code paths so it still runs when an exception escapes the try. Pair it with `Logger.setSaveMethod(...)` at the top of the method if the default `EVENT_BUS` isn't right for that path (see the save-method notes in item 1).

## Environment-Aware Logging Levels

Treat logging verbosity as an operational control, not as a code constant.

| Environment | Suggested baseline              | Reason                                                           |
| ----------- | ------------------------------- | ---------------------------------------------------------------- |
| Production  | `ERROR` or `WARN`               | Reduce noise and storage impact while preserving incident signal |
| UAT         | `INFO`                          | Validate business flows without excessive detail                 |
| QA          | `DEBUG` or `FINE`               | Support defect reproduction and integration testing              |
| Sandbox/Dev | `FINE` to `FINEST` (time-boxed) | Deep diagnostics during active development                       |

Use hierarchy overrides (user/profile) for temporary incident windows, then revert.

## Review Checklist for Existing Code

- Does each execution path call `saveLog()` at deliberate checkpoints - and never after every entry or inside a per-record inner loop?
- Are exceptions logged with stack trace context?
- Are record references attached via `.setRecord(...)`?
- Are scenarios and tags consistent with team taxonomy?
- Is save method choice explicit when not using default `EVENT_BUS`?

## Governor and Capacity Considerations

Nebula Logger helps observability, but it still runs inside Salesforce governor boundaries.

| Constraint                 | Impact on logging                                             | Mitigation                                                                                  |
| -------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Data storage               | High-volume logs can consume custom object storage quickly    | Enforce retention policy and purge schedule; lower verbosity in production                  |
| Platform event daily limit | `EVENT_BUS` volume can hit org event allocations              | Use selective logging and switch targeted jobs to `QUEUEABLE`/`SYNCHRONOUS_DML` when needed |
| SOQL queries               | Extra enrichment queries in logging paths can compound limits | Reuse queried records and avoid logging-only query fanout                                   |
| CPU time                   | Heavy serialization/tagging in loops increases CPU usage      | Log aggregate milestones, not every iteration, and prefer async save paths                  |
| Async job allocation       | Overusing `QUEUEABLE` can compete with business async work    | Reserve queueable saves for high-cost or mixed-DML-sensitive contexts                       |
| Heap size                  | Large payloads/exceptions can inflate transaction memory      | Truncate oversized payloads and avoid dumping full object graphs                            |

## When Not to Use Nebula Logger

Nebula Logger is not a substitute for sound architecture.

- Do not use logging as a workaround for unclear domain design.
- Do not store secrets, credentials, or unnecessary PII in log messages.

Use Nebula Logger as a structured observability layer, combined with clean service boundaries, resilient error handling, and purposeful telemetry.
