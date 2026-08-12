---
name: nebula-logger-console
description: Use this skill when the user wants to browse, filter, or investigate Nebula Logger data in the Salesforce UI. Covers the Logger Console app, list views on `Log__c` and `LogEntry__c`, related-list navigation, the Log record page and its LWCs, and how admins and support engineers use the console day-to-day.
---

# Using the Nebula Logger Console

## What the Console Is

The Logger Console is a Salesforce Lightning App shipped with Nebula Logger. It gives admins, support engineers, and developers a purpose-built place to browse logs without hand-writing SOQL against `Log__c` and `LogEntry__c` every time something happens in production.

- App API name: `LoggerConsole`.
- Navigation entries include `Log__c`, `LogEntry__c`, `LoggerScenario__c`, `LoggerTag__c`, and `LogEntryTag__c`.
- A utility bar (`LoggerConsoleUtilityBar` FlexiPage) surfaces a `Logger Settings` panel for editing the effective hierarchy record without leaving the console.

## Standard List Views

Nebula Logger ships a broad set of list views on `Log__c` and `LogEntry__c` so most day-one investigations don't require a custom view. Examples include:

- **`Log__c`**: `AllLogs`, `AllOpenLogs`, `AllClosedLogs`, `AllResolvedLogs`, `AllLogsWithERROREntries`, `AllLogsWithERRORorWARNEntries`, `AllAsynchronousLogs`, `AllBatchLogs`, `AllChildLogs`, `AllImpersonatedLogs`.
- **`LogEntry__c`**: `AllERRORLogEntries`, `AllERRORandWARNLogEntries`, `AllApexLogEntries`, `AllComponentLogEntries`, `AllFlowLogEntries`, `AllHttpRequestLogEntries`, `AllHttpResponseLogEntries`, `AllExceptionLogEntries`, `AllImpersonatedLogEntries`.

When investigating an incident, start with the pre-built views and narrow with column filters before creating a new custom list view.

## Log Record Page

The `Log__c` record page (`LogRecordPage` FlexiPage) surfaces:

- Standard `Log__c` fields (transaction ID, save method, user, scenario, tags, totals).
- The related `LogEntry__c` list, chronological within the log.
- Roll-up counts (`TotalERRORLogEntries__c`, `TotalWARNLogEntries__c`, etc.) to spot severity at a glance.
- Related child logs when a parent log transaction ID has been set (see the parent/child log association pattern documented in the Apex logging skill).

## Log Entry Record Page

The `LogEntry__c` record page (`LogEntryRecordPage` FlexiPage) shows:

- Message, logging level, origin type / API name, and timestamp.
- Related record ID and record JSON snapshot when the entry was created with `.setRecord(...)`.
- Stack trace and exception fields when the entry came from an exception.
- Tags applied to the entry (via the `LogEntryTag__c` junction).

## Home Page and Live Streaming

The console's home page (`LoggerHomePage` FlexiPage) is where the console's most operational tools live:

- `logEntryEventStream` - subscribes to the `LogEntryEvent__e` platform event and shows log entries in real time as they are published. This is the fastest way to confirm logging is firing during a test scenario without waiting for the async save path to persist records.
- `logBatchPurge` - triggers the log purge batch on demand and reports counts.
- `loggerSettings` - the same settings editor exposed in the utility bar, on a full-page canvas.
- `loggerHomeHeader` - navigation header with quick links to release notes, GitHub, and the docs.
- Embedded reports and dashboards showing recent activity across `Log__c` and `LogEntry__c`.

Together these give an admin one page to answer "is logging healthy right now, and what does it look like?".

## Typical Workflows

### Investigating a specific error

1. Open the `AllERRORLogEntries` list view.
2. Filter to the time window of interest.
3. Open a `LogEntry__c` record - the linked `Log__c` shows the full transaction; the related list on the `Log__c` shows every entry in that transaction, in order.
4. If the transaction is part of an async chain, follow `ParentLog__c` upward to the parent transaction.

### Investigating a user's session

1. Open the `AllLogs` list view.
2. Filter by `LoggedBy__c` and time window.
3. Sort by `StartTime__c` to see the user's transactions in order.

### Confirming logging is firing during a repro

1. Open the Logger Console home page (`LoggerHomePage`).
2. Locate the `Log Entry Event Stream` component.
3. Reproduce the scenario in another tab.
4. Watch entries appear as `LogEntryEvent__e` platform events publish. When entries stop appearing, the async save has completed and the persisted `Log__c` / `LogEntry__c` records are queryable.

## Related Skills

- [nebula-logger-instrumentation](../nebula-logger-instrumentation/SKILL.md) - Writing the log entries that show up here.
- [nebula-logger-purging-and-retention](../nebula-logger-purging-and-retention/SKILL.md) - How long records stay visible in these views.
