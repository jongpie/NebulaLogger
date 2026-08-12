---
title: Log record page
description: The shipped Lightning record pages for Log__c and LogEntry__c.
---

Nebula Logger ships two custom record pages that make each transaction and each entry immediately usable without customization.

## `Log__c` record page

The `LogRecordPage` FlexiPage powers the `Log__c` record view. It surfaces:

- **Standard fields** - transaction ID, save method, user, profile, scenario, tags, start/end times, totals.
- **Roll-up counts by level** - `TotalERRORLogEntries__c`, `TotalWARNLogEntries__c`, `TotalINFOLogEntries__c`, etc. Instantly tells you how severe the transaction was.
- **Related `LogEntry__c` list** - all entries in the transaction, chronological within the log.
- **Related child logs** - when the transaction was linked to a parent via `Logger.setParentLogTransactionId(...)`, the parent shows the child logs and vice versa.

## `LogEntry__c` record page

The `LogEntryRecordPage` FlexiPage powers `LogEntry__c` records. It shows:

- **Message, level, origin type / API name, and timestamp** - the "what and when" of the entry.
- **Related record snapshot** - if the entry was created with `.setRecord(...)`, the JSON snapshot of the record at log time is rendered here. Compare against the live record to see what changed.
- **Stack trace and exception details** - populated when the entry came from an exception.
- **Tags** - via the `LogEntryTag__c` junction. Clickable through to the `LoggerTag__c` records for taxonomy navigation.
- **Origin details** - Apex class + method, LWC bundle, Flow name, or OmniStudio process, depending on the entry's source.

## Customizing the pages

The shipped pages are a starting point. To customize:

1. In App Builder, open `LogRecordPage` or `LogEntryRecordPage`.
2. Save As under a new name.
3. Assign the new page to your Logger Console app for the profiles you want.

The shipped pages remain the default for other apps and profiles.

## Where next

- [Related Log Entries component](/console/related-log-entries/) - reuse the entry list on any record page.
- [Investigation playbooks](/console/investigation-playbooks/) - workflows using these pages.
