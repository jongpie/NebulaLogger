---
title: Big Object Archiving plugin
description: Archive aged-out logs to a big object before purging.
---

The Big Object Archiving plugin copies logs to a `LogEntryArchive__b` big object _before_ `LogBatchPurger` deletes them. Data remains queryable long-term without counting against custom object storage.

## What it does

- Registers a batch plugin on `LogBatchPurger`.
- Adds a new `Archive` value to `LogPurgeAction__c`. When set, `LogBatchPurger` calls the plugin to copy entries to the big object, then deletes the original records.
- Provides a `LogEntryArchive__b` big object with fields mirroring `LogEntry__c` for archival storage.

## Big object storage

Big objects are Salesforce's high-volume, asynchronous storage. They:

- Count against a separate storage bucket than regular custom objects.
- Are queried via SOQL (with limitations - only indexed fields, no `LIMIT` or `ORDER BY`).
- Are much cheaper per record than custom objects.
- Are effectively write-once; updates and deletes have significant restrictions.

Trade-off: archived logs are still there, but investigation is less flexible than querying `LogEntry__c` directly.

## Installation

The Big Object Archiving plugin ships as its own unlocked package. Install it after the core Nebula Logger unlocked package.

Install via URL or `sf package install`. See the [GitHub releases page](https://github.com/jongpie/NebulaLogger/releases) for the current package ID.

After installation, assign the `LoggerLogEntryArchiveAdmin` permission set to admins who need to configure it or query the big object.

## Configuration

- Ensure the plugin's `LoggerPlugin__mdt` record has `IsEnabled__c = true`.
- Set `LoggerSettings__c.DefaultLogPurgeAction__c = 'Archive'` at the org default (or the profile / user level for the populations you want to archive).
- Optionally use scenario rules to keep certain scenarios archived while others get deleted.

## When to use it

- Regulated processes that require long-term retention.
- Orgs where dropping `LoggingLevel__c` to production levels still generates enough log volume to strain storage.
- Post-incident forensics - archived data remains queryable for months or years without inflating live storage.

## Querying archived logs

```apex
List<LogEntryArchive__b> archived = [
  SELECT Message__c, LoggingLevel__c, Timestamp__c
  FROM LogEntryArchive__b
  WHERE UserId__c = :UserInfo.getUserId()
];
```

Big object SOQL only supports filters on indexed fields, and there's no `LIMIT` or `ORDER BY` on non-indexed columns. Check the big object's field definitions for what's indexed before writing queries.

## Where next

- [Big Object Archiving plugin reference](/NebulaLogger/reference/plugins/big-object-archiving/) - auto-generated Apex + `LogEntryArchive__b` big object reference.
- [Purge actions](/NebulaLogger/retention/purge-actions/) - how the `Archive` action fits into the purge flow.
- [Retention date semantics](/NebulaLogger/retention/retention-dates/) - what "aged out" means.
