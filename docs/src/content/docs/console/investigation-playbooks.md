---
title: Investigation playbooks
description: Concrete workflows for common Nebula Logger investigations.
---

Three playbooks for the most common investigation patterns. Each uses only the shipped list views and record pages - no custom setup required.

## Investigating a specific error

1. Open the **`AllERRORLogEntries`** list view on `LogEntry__c`.
2. Filter to the time window of interest (usually "This Hour" or "Today").
3. Open a `LogEntry__c` record.
4. The linked `Log__c` shows the full transaction; the related list on the `Log__c` shows every entry in that transaction, in order.
5. If the transaction is part of an async chain, follow `ParentLog__c` upward to the parent.

The chronological entry list on the parent `Log__c` is usually the most useful single view - it shows the sequence that led to the error.

## Investigating a user's session

1. Open the **`AllLogs`** list view on `Log__c`.
2. Filter by `LoggedBy__c` (the user field) and time window.
3. Sort by `StartTime__c` ascending to see the user's transactions in order.
4. Open each `Log__c` to see the entries within the transaction.

## Confirming logging is firing during a repro

Great for "we deployed but I'm not sure logging is working" or "we added a new logger call and I want to see it fire before waiting for the async save."

1. Open the Logger Console **home page** (`LoggerHomePage`).
2. Locate the **Log Entry Event Stream** component.
3. Reproduce the scenario in another tab or window.
4. Watch entries appear in real time as `LogEntryEvent__e` platform events publish.
5. When entries stop appearing, the async save has completed and the persisted `Log__c` / `LogEntry__c` records are queryable.

The stream shows entries as platform events fire, which is _before_ the trigger materializes them into records. That's the fastest signal you'll get.

## Common patterns for narrowing

- **By severity**: `AllLogsWithERROREntries`, `AllLogsWithERRORorWARNEntries`.
- **By runtime**: `AllApexLogEntries`, `AllComponentLogEntries`, `AllFlowLogEntries`.
- **By status**: `AllOpenLogs`, `AllClosedLogs`, `AllResolvedLogs`.
- **By async context**: `AllAsynchronousLogs`, `AllBatchLogs`, `AllChildLogs`.
- **By HTTP callout**: `AllHttpRequestLogEntries`, `AllHttpResponseLogEntries`.
- **By exception**: `AllExceptionLogEntries`.
- **By impersonation**: `AllImpersonatedLogs`, `AllImpersonatedLogEntries`.

Start with the shipped list views and narrow with column filters before creating a custom view. There's almost always a shipped view close to what you want.

## Where next

- [Logger Console app](/NebulaLogger/console/logger-console-app/) - the console tour.
- [Log record page](/NebulaLogger/console/log-record-page/) - what each `Log__c` and `LogEntry__c` page shows.
