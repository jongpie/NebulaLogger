---
title: Feature tour
description: A walkthrough of what Nebula Logger ships out of the box.
---

## One logging API across runtimes

Every runtime uses the same core model: add entries, optionally enrich them, save once.

- **Apex** - `Logger.info(...)`, `Logger.error(...)`, level-specific methods with chainable builders.
- **Lightning Web Components** - `getLogger()` from the `c/logger` module.
- **Aura** - `<c:logger>` component, `component.find('logger')`.
- **Flow** - three invocable actions (`Add Log Entry`, `Add Log Entry for an SObject Record`, `Add Log Entry for an SObject Record Collection`) plus `Save Log`.
- **OmniStudio** - Remote Action steps invoking `CallableLogger`.

## Structured records

Every `Log__c` and `LogEntry__c` record captures:

- Message and logging level.
- User, profile, and org context.
- Transaction ID, save method, timestamps.
- Optional record reference plus a JSON snapshot of the record's state at log time.
- Exception message, stack trace, and type.
- Scenario and tags.
- Origin (Apex class, LWC bundle, Flow name, OmniStudio process).

## The Logger Console app

A Lightning app with a home page, prebuilt list views, a rich `Log__c` record page, and utility-bar access to `LoggerSettings__c` from any page in the app.

- **Home page** - live `LogEntryEvent__e` stream, batch-purge controls, settings editor, embedded reports.
- **Log record page** - all entries in the transaction in order, roll-up counts by level, parent/child log links.
- **Log entry record page** - message, level, record snapshot, stack trace, tags, origin.
- **Prebuilt list views** - `AllLogs`, `AllOpenLogs`, `AllLogsWithERROREntries`, `AllAsynchronousLogs`, `AllBatchLogs`, and many more.

## Declarative configuration

- `LoggerSettings__c` - hierarchy custom setting (org / profile / user) controls enabled state, logging level, save method, retention days, purge action.
- `LoggerParameter__mdt` - global feature flags.
- `LogEntryDataMaskRule__mdt` - regex-based masking for sensitive substrings.
- `LoggerScenarioRule__mdt` - override retention or logging level per business process.

## Async transaction linking

Chain logs across batchable, queueable, and scheduled jobs. Every child `Log__c` records its parent's transaction ID, so the console shows the whole chain from a single record.

## Related record snapshots

`.setRecord(record)` captures the record's state at log time as JSON. The `Log Entry` record page renders the snapshot alongside the current live record, so admins investigating an old log can see what the record looked like _then_ even if it has since changed.

## Data masking

Regex rules in `LogEntryDataMaskRule__mdt` mask sensitive substrings (credit card numbers, SSNs, custom patterns) before entries are persisted. Rules apply to messages, record snapshots, and stack traces.

## Related list on any record page

Drop the `relatedLogEntries` LWC on any Lightning record page to show the log entries that reference the current record. Works with the record snapshot: if any `LogEntry__c` was created with `.setRecord(currentRecord)`, it shows up here.

## Plugin framework

Two extension points, both driven by `LoggerPlugin__mdt` records:

- **Trigger plugins** run inside `LoggerSObjectHandler` execution on `LogEntryEvent__e`, `Log__c`, `LogEntry__c`, and the tag junctions. Used for enrichment, external notifications, and per-record automation.
- **Batch plugins** run inside `LogBatchPurger` execution. Used for archival, custom purge policies, and metrics.

Bundled plugins:

- **Slack** - sends configured entries to a Slack workspace.
- **Big Object Archiving** - copies logs to a `LogEntryArchive__b` big object before purging.
- **Log Retention Rules** - CMDT-driven retention overrides beyond the built-in scenario rules.
- **Logger Admin Dashboard** - Lightning dashboard for admins.
- **Async Failure Additions** - enriches log entries produced by failed async jobs.

## AI agent skills

Included [Agent Skills](https://www.skills.sh/docs) teach Claude Code, GitHub Copilot, Cursor, and similar tools how to install, use, and extend Nebula Logger. Install with `npx skills add jongpie/NebulaLogger`.

## Where next

- [Package options](/introduction/package-options/) - unlocked vs managed vs bundled.
- [Getting Started](/getting-started/install-unlocked/) - install and configure.
