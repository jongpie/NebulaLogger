---
title: Data mask rules
description: Configuring LogEntryDataMaskRule__mdt records to redact sensitive substrings before entries persist.
---

Nebula Logger masks sensitive substrings in log entries via regex rules stored in `LogEntryDataMaskRule__mdt`. Masking runs _before_ entries are persisted, so masked values never reach `LogEntry__c`.

See [Logging Guide - Data masking](/NebulaLogger/logging-guide/data-masking/) for the user-facing narrative. This page focuses on the configuration surface.

## Rule fields

| Field                     | Purpose                                                                       |
| ------------------------- | ----------------------------------------------------------------------------- |
| `DeveloperName` / `Label` | Identify the rule.                                                            |
| `IsEnabled__c`            | Toggle the rule without deleting the record.                                  |
| `SensitiveDataRegEx__c`   | Regex pattern that matches the sensitive substring.                           |
| `ReplacementRegEx__c`     | Replacement string for the matched substring (supports regex backreferences). |

## Where rules apply

Masking runs against:

- `LogEntry__c.Message__c` - the log message.
- `LogEntry__c.ExceptionStackTrace__c` - exception stack traces.
- Record snapshot fields captured by `.setRecord(...)`.

## Shipped defaults

Nebula Logger ships default rules for common patterns - credit card numbers, US Social Security Numbers, some API-key-shaped strings. Check the `LogEntryDataMaskRule__mdt` records in your org for the current defaults.

## Adding a rule

Two ways:

1. **Setup UI**: Custom Metadata Types > Log Entry Data Mask Rule > Manage Records > New.
2. **Metadata deploy**: create `LogEntryDataMaskRule.<Name>.md-meta.xml` under your project.

Either way, the rule takes effect on the next log entry after it deploys - no restart required.

## Overriding a shipped rule

If a shipped rule is too aggressive or not aggressive enough for your org, edit its `IsEnabled__c` or `SensitiveDataRegEx__c` / `ReplacementRegEx__c` in place. The changes are subscriber-controllable where the shipped record allows it.

## Guidance

- **Do not rely on masking as a substitute for not logging sensitive data.** If your code shouldn't log a value, don't pass it to Logger.
- **Test every rule.** A too-loose regex can wipe out useful content; a too-strict one can miss the value.
- **Namespace `ReplacementRegEx__c` values.** `***REDACTED-SSN***` is more useful in investigation than a bare `***REDACTED***`.
- **Masking is one-way and applies at log time.** It cannot retroactively mask entries that were persisted before the rule was added.

## Where next

- [Logging Guide - Data masking](/NebulaLogger/logging-guide/data-masking/) - the same content in the logging-guide section.
- [`LogEntryDataMaskRule__mdt` reference](/NebulaLogger/metadata-reference/custom-objects/logentrydatamaskrule__mdt/) - full field list.
