---
name: nebula-logger-best-practices
description: Use this skill when the user wants to review, harden, or standardize Nebula Logger usage across a Salesforce team. Covers operational logging standards, environment-aware settings, limit-aware design, and governance guardrails.
---

# Nebula Logger Best Practices and Governance

## Team-Wide Practices

Use these defaults when reviewing pull requests or designing logging conventions.

1. Always call `Logger.saveLog()`.
2. Place `Logger.saveLog()` in `finally` blocks for transactional code paths.
3. Use logging levels strategically. Fine-grained levels such as `FINE`, `FINER`, and `FINEST` can be combined with Logger Settings to avoid unnecessary logging overhead in performance-sensitive code paths and enable deeper diagnostics only when needed. Reserve higher-level logging (`ERROR`, `WARN`, and `INFO`) for information that is operationally significant.
4. Tune `LoggerSettings__c.LoggingLevel__c` by environment.
5. Use `Logger.setScenario()` for business-process grouping.
6. Associate records with `.setRecord(...)` instead of embedding IDs in message strings.
7. Define a controlled tag taxonomy (for example: `domain:*`, `feature:*`, `incident:*`).
8. Configure scheduled purging and retention windows (`DefaultLogPurgeAction__c`, `DefaultNumberOfDaysToRetainLogs__c`).

## Environment-Aware Logging Levels

Treat logging verbosity as an operational control, not as a code constant.

| Environment | Suggested baseline | Reason |
| --- | --- | --- |
| Production | `ERROR` or `WARN` | Reduce noise and storage impact while preserving incident signal |
| UAT | `INFO` | Validate business flows without excessive detail |
| QA | `DEBUG` or `FINE` | Support defect reproduction and integration testing |
| Sandbox/Dev | `FINE` to `FINEST` (time-boxed) | Deep diagnostics during active development |

Use hierarchy overrides (user/profile) for temporary incident windows, then revert.

## Review Checklist for Existing Code

- Does each execution path persist logs (`saveLog`) exactly once?
- Are exceptions logged with stack trace context?
- Are record references attached via `.setRecord(...)`?
- Are scenarios and tags consistent with team taxonomy?
- Is save method choice explicit when not using default `EVENT_BUS`?

## Governor and Capacity Considerations

Nebula Logger helps observability, but it still runs inside Salesforce governor boundaries.

| Constraint | Impact on logging | Mitigation |
| --- | --- | --- |
| Data storage | High-volume logs can consume custom object storage quickly | Enforce retention policy and purge schedule; lower verbosity in production |
| Platform event daily limit | `EVENT_BUS` volume can hit org event allocations | Use selective logging and switch targeted jobs to `QUEUEABLE`/`SYNCHRONOUS_DML` when needed |
| SOQL queries | Extra enrichment queries in logging paths can compound limits | Reuse queried records and avoid logging-only query fanout |
| CPU time | Heavy serialization/tagging in loops increases CPU usage | Log aggregate milestones, not every iteration, and prefer async save paths |
| Async job allocation | Overusing `QUEUEABLE` can compete with business async work | Reserve queueable saves for high-cost or mixed-DML-sensitive contexts |
| Heap size | Large payloads/exceptions can inflate transaction memory | Truncate oversized payloads and avoid dumping full object graphs |

## When Not to Use Nebula Logger

Nebula Logger is not a substitute for sound architecture.

- Do not use logging as a workaround for unclear domain design.
- Do not store secrets, credentials, or unnecessary PII in log messages.

Use Nebula Logger as a structured observability layer, combined with clean service boundaries, resilient error handling, and purposeful telemetry.
