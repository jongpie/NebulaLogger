---
title: Environment-aware defaults
description: Recommended LoggerSettings__c posture across production, UAT, QA, and sandbox environments.
---

Logging verbosity is an operational control, not a code constant. Treat it as something the org tunes per environment, and adjust the `LoggerSettings__c` org default record accordingly during deploys.

## Suggested baselines

| Environment | `LoggingLevel__c`               | `DefaultNumberOfDaysToRetainLogs__c` | Rationale                                                                             |
| ----------- | ------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------- |
| Production  | `INFO` or `WARN`                | 30-90 days                           | Reduce noise and storage impact while preserving incident signal.                     |
| UAT         | `INFO`                          | 30 days                              | Validate business flows without excessive detail.                                     |
| QA          | `DEBUG` or `FINE`               | 14 days                              | Support defect reproduction and integration testing.                                  |
| Sandbox/Dev | `FINE` to `FINEST` (time-boxed) | 7-14 days                            | Deep diagnostics during active development; short retention prevents runaway storage. |

Adjust to your org's storage budget and audit requirements.

## Per-profile overrides

Common patterns worth adopting even in production:

- **Developer profile**: bump to `DEBUG` or `FINE` and retain longer. Investigation work isn't lost, and diagnostic detail is on hand when needed.
- **Integration user profile**: shorter retention because integration users produce dramatically more log volume than end users.
- **Support staff profile**: whatever level makes their day-to-day tools work - usually the same as the org default.

## Temporary incident windows

When investigating a live issue:

1. Create a user- or profile-level `LoggerSettings__c` record for the affected user(s).
2. Bump `LoggingLevel__c` to `DEBUG` or `FINE`.
3. Reproduce and investigate.
4. Delete the user/profile record when done, so the org default reasserts.

This is faster and safer than editing the org default - other users' logging behavior is unaffected.

## Coordinating with retention

Higher verbosity produces more entries per transaction. Combine environment-appropriate levels with environment-appropriate retention windows to keep storage growth bounded.

If storage is genuinely tight, the levers in descending order of impact:

1. Lower `LoggingLevel__c` in production. `DEBUG` -> `INFO` typically drops volume by an order of magnitude.
2. Shorten `DefaultNumberOfDaysToRetainLogs__c`.
3. Install the [Big Object Archiving plugin](/NebulaLogger/plugins/big-object-archiving/) to offload aged data.

## Where next

- [LoggerSettings\_\_c hierarchy](/NebulaLogger/configuration/logger-settings/) - the settings surface.
- [Logging levels](/NebulaLogger/configuration/logging-levels/) - precedence and semantics.
- [Retention & Purging](/NebulaLogger/retention/retention-dates/) - retention configuration in depth.
