---
title: Data masking
description: Configuring regex-based rules that mask sensitive substrings before entries are persisted.
---

Nebula Logger masks sensitive substrings from log entries using regex rules stored in `LogEntryDataMaskRule__mdt` records. Masking happens _before_ entries are persisted, so masked values never reach `LogEntry__c` in the first place.

## The rule model

Each `LogEntryDataMaskRule__mdt` record defines one masking rule. Key fields:

| Field                     | Purpose                                             |
| ------------------------- | --------------------------------------------------- |
| `DeveloperName` / `Label` | Identify the rule.                                  |
| `IsEnabled__c`            | Toggle the rule without deleting the record.        |
| `SensitiveDataRegEx__c`   | Regex pattern that matches the sensitive substring. |
| `ReplacementRegEx__c`     | Replacement string for the matched substring.       |

The rules apply to log entry messages, exception stack traces, and record snapshots - anywhere a sensitive value might land.

## Shipped rules

Nebula Logger ships default rules for common patterns:

- Credit card numbers.
- US Social Security Numbers.
- Some tokens and API-key-shaped strings.

Check the `LogEntryDataMaskRule__mdt` records in your org for the exact set. New Nebula Logger releases may add or refine defaults.

## Adding a custom rule

Create a new `LogEntryDataMaskRule__mdt` record with:

- `SensitiveDataRegEx__c` = the pattern to match (e.g. an internal customer-ID format).
- `ReplacementRegEx__c` = what to replace matches with (e.g. `***REDACTED***`).
- `IsEnabled__c` = `true`.

The rule applies immediately - no restart or deploy needed beyond creating the CMDT record.

## Testing masking

The safest way to verify a rule works is to write a log entry with a value that should be masked and query the persisted record:

```apex
Logger.info('Card: 4111 1111 1111 1111');
Logger.saveLog();

// After Test.stopTest() / saveLog completion
LogEntry__c entry = [SELECT Message__c FROM LogEntry__c ORDER BY CreatedDate DESC LIMIT 1];
System.Assert.isFalse(entry.Message__c.contains('4111'));
```

## What masking does not do

- It does not mask _record field values_ on the actual Salesforce record. Masking applies only to what Nebula Logger writes to log entries.
- It does not remove entries entirely. Even fully masked messages persist - the entry itself, its metadata, its tags all remain.
- It does not mask historical `LogEntry__c` records that were persisted before the rule was added.

If a rule needs to apply to historical data, run an anonymous Apex job that queries and rewrites the affected `Message__c` values.

## Guidance

- **Do not rely on masking as a substitute for not logging sensitive data in the first place.** If your code shouldn't log a value, don't pass it to Logger. Masking is a defense-in-depth layer.
- **Test every rule.** A too-loose regex can wipe out useful content; a too-strict one can miss the value.
- **Namespace `ReplacementRegEx__c` values.** `***REDACTED-SSN***` is more useful in investigation than a bare `***REDACTED***` because it tells you what got masked.

## Where next

- [Configuration - Data mask rules](/NebulaLogger/configuration/data-mask-rules/) - the same content in the configuration section for cross-reference.
- [Best practices - What not to log](/NebulaLogger/logging-guide/apex/) - avoiding sensitive data at the source.
