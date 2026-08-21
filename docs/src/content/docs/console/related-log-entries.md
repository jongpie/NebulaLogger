---
title: Related Log Entries component
description: Embed the relatedLogEntries LWC on any Lightning record page to show log entries that reference the record.
---

The `relatedLogEntries` LWC shows every `LogEntry__c` record whose `RecordId__c` matches the current record. Drop it on any Lightning record page and it Just Works - no configuration required beyond adding the component.

![Related Log Entries component on a record page](/images/relate-log-entries-lwc.png)

## Adding it to a record page

1. Open the record page in Lightning App Builder (Setup > Object Manager > (your object) > Lightning Record Pages, or edit-in-page from the record).
2. Drag **Related Log Entries** onto the page.
3. Save and activate.

The component reads the record ID from the page's `recordId` and queries `LogEntry__c` for matches.

## What it shows

- Every `LogEntry__c` where `RecordId__c` equals the current record's ID.
- Chronological, most recent first.
- Level, message, timestamp, and a link to the entry's record page.

![Related entries list view](/images/component-entries-list-view.png)

Clicking through to a specific entry drills into the standard `LogEntry__c` record page:

![Log entry detail](/images/component-entry-record-detail.png)

## When to use it

- **On business objects** - drop it on `Account`, `Case`, `Opportunity`, or any custom object where you want to see logging history alongside the record.
- **On support records** - a `Case` with Related Log Entries visible turns "there was an error somewhere" into "here's the exact stack trace on this exact case."
- **On integration user records** - the `User` record page with Related Log Entries visible shows every log entry that referenced that user's ID.

## What it doesn't show

- Log entries that reference the record only through `.setRecord(List<SObject>)` or `.setRecord(Map<Id, SObject>)` may or may not appear, depending on how the framework populated `RecordId__c` for that entry. The single-record `.setRecord(record)` case is the reliable path.
- Entries logged from Flow that didn't set the SObject Record input will not appear against that record - only entries created with structured record association show up.

## Where next

- [Logging Guide - Apex - Attaching records](/NebulaLogger/logging-guide/apex/#attaching-records) - how entries get associated with a record.
- [`relatedLogEntries` reference](/NebulaLogger/reference/lwc/) - LWC API reference.
