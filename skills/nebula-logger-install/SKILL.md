---
name: nebula-logger-install
description: Use this skill when the user wants to install and configure Nebula Logger in a Salesforce org for the first time. Covers package selection, installation paths, permissions, LoggerSettings__c hierarchy, and first-run troubleshooting.
---

# Nebula Logger Installation and Initial Configuration

## Why Nebula Logger Instead of Only System.debug()

`System.debug()` is useful during active debugging, but it is not a durable observability strategy for production operations.

- Debug logs have short retention windows and are hard to query for historical analysis.
- Searching by business record, process scenario, or tags is limited compared to purpose-built logging objects.
- It does not provide a unified approach across Apex, LWC, Aura, Flow, and OmniStudio.

Nebula Logger gives teams a consistent, queryable logging model across Salesforce runtime contexts.

## Package Choice: Unlocked vs Managed

Nebula Logger supports both package types with the same core metadata, but the operating model differs.

| Area                   | Unlocked Package                     | Managed Package                                                                                                          |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| Namespace              | None                                 | `Nebula`                                                                                                                 |
| Release cadence        | Faster patch cadence                 | Slower, stabilized cadence (roughly three managed releases per year)                                                     |
| Source visibility      | Full source access in org            | Packaged global API surface                                                                                              |
| Plugin framework       | Available                            | Not currently available                                                                                                  |
| Feature coverage       | All features (plugins, latest fixes) | Subset - trails the unlocked package                                                                                     |
| Distribution model     | GitHub-first OSS workflow            | AppExchange-friendly for managed delivery                                                                                |
| Typical recommendation | Default choice for almost every team | Only when a namespaced package is a hard requirement (ISV / AppExchange delivery, orgs that require namespace isolation) |

Start with the unlocked package unless a namespaced package is a hard requirement. The unlocked package has more features (plugin framework, faster patches) and full source visibility; the managed package exists specifically for cases where the `Nebula` namespace is needed.

## Installation Options

Always confirm the latest version on:

- https://github.com/jongpie/NebulaLogger/releases

### Unlocked Package - v4.19.5

- Sandbox install link: `https://test.salesforce.com/packaging/installPackage.apexp?p0=04tg7000000IzRdAAK`
- Production install link: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04tg7000000IzRdAAK`
- Salesforce CLI: `sf package install --wait 20 --security-type AdminsOnly --package 04tg7000000IzRdAAK`

### Managed Package - v4.19.0

- Sandbox install link: `https://test.salesforce.com/packaging/installPackage.apexp?mgd=true&p0=04tg7000000GZbJAAW`
- Production install link: `https://login.salesforce.com/packaging/installPackage.apexp?mgd=true&p0=04tg7000000GZbJAAW`
- Salesforce CLI: `sf package install --wait 30 --security-type AdminsOnly --package 04tg7000000GZbJAAW`

## Permission Sets to Assign

Assign permission sets as part of rollout. Exact API names in the repo are:

| Permission Set     | Purpose                                                | Typical users                                       |
| ------------------ | ------------------------------------------------------ | --------------------------------------------------- |
| `LoggerAdmin`      | Full control of Nebula Logger data and features        | Platform admins, support leads                      |
| `LoggerLogViewer`  | Read-only access to logs and console features          | Operations, QA, support analysts                    |
| `LoggerEndUser`    | Limited day-to-day access with controlled visibility   | Business users who need log visibility              |
| `LoggerLogCreator` | Minimal metadata/object access needed to generate logs | Integration users, Experience Cloud component users |

## Configure `LoggerSettings__c` Hierarchy

Nebula Logger uses a hierarchy custom setting so behavior can be tuned at multiple scopes:

1. Org default baseline.
2. Profile-level override.
3. User-level override.

Prioritize these settings during onboarding:

| Field                                | What it controls                                                           |
| ------------------------------------ | -------------------------------------------------------------------------- |
| `IsEnabled__c`                       | Global on/off switch for logging behavior at the effective hierarchy level |
| `LoggingLevel__c`                    | Effective minimum logging level for the user/profile/org context           |
| `DefaultSaveMethod__c`               | Default save strategy used by `Logger.saveLog()`                           |
| `DefaultLogPurgeAction__c`           | Default cleanup behavior for old logs                                      |
| `DefaultNumberOfDaysToRetainLogs__c` | Retention window for generated logs                                        |

Note: older references may mention `DefaultLoggingLevel__c`; in this codebase the active field is `LoggingLevel__c`.

## Review and Customize `LoggerParameter__mdt`

Nebula Logger ships a `LoggerParameter__mdt` CMDT populated with ~40 records that control cross-cutting runtime behavior - things like which supporting objects are queried, how tags are stored, whether the stack trace is parsed, and whether transaction limits get captured. The out-of-the-box values are the recommended defaults for most orgs, but they are opinionated defaults, and some orgs will want to adjust them. Review the list after install and change the ones that matter for your org. A few representative examples of the kinds of tradeoffs these records expose:

- **SOQL-sensitive orgs**: if the extra queries Nebula Logger makes are a concern (e.g. very complex codebases that are already close to the 100-SOQL transaction limit), the `Query*Synchronously` records - `QueryUserDataSynchronously`, `QueryNetworkDataSynchronously`, `QueryOrganizationDataSynchronously`, `QueryAuthSessionDataSynchronously` - can be flipped to `false` so the enrichment queries only run async on the `Log__c` insert side. Setting the corresponding `Query*Data` record to `false` disables the query entirely if the extra fields aren't needed at all.
- **CPU-sensitive orgs**: `EnableStackTraceParsing` and `StoreHeapSizeLimit` are `true` by default. Flipping them to `false` skips the per-entry stack-trace parse and heap-limit capture, which trades some observability for lower CPU consumption on high-volume log paths.
- **Callout-restricted orgs**: `CallStatusApi` (async callout to `api.status.salesforce.com` for release info) can be set to `false` if outbound callouts to the Salesforce status endpoint aren't allowed or aren't wanted.
- **Feature toggles**: `EnableTagging`, `EnableLogEntryEventStream`, `NormalizeScenarioData`, `NormalizeTagData`, and similar records switch entire subsystems on or off - useful when a feature isn't needed and the associated storage / trigger work should be avoided.

Every `LoggerParameter__mdt` record has an inline `Description__c` field explaining what it controls and how to change it; open the record in Setup or the Logger Console to see the guidance rather than trying to memorize the catalog. Treat any change to these records as a behavior change and re-run the affected tests afterwards - see the "Nebula Logger's CMDT Records Are Live in Tests" section of [nebula-logger-testing-your-code](../nebula-logger-testing-your-code/SKILL.md).

## Review Data Masking with `LogEntryDataMaskRule__mdt`

Nebula Logger also ships a small starter catalog of `LogEntryDataMaskRule__mdt` records that regex-mask sensitive data before it gets persisted: `SocialSecurityNumber`, `VisaCreditCardNumber`, `MastercardCreditCardNumber`, and `AmericanExpressCreditCardNumber`. Each record has:

- `SensitiveDataRegEx__c` - the regex that matches the sensitive substring.
- `ReplacementRegEx__c` - the replacement pattern (typically preserves surrounding context and masks the middle digits).
- `ApplyToMessage__c` / `ApplyToRecordJson__c` - whether the rule runs against the log entry message text, against the `RecordJson__c` captured by `.setRecord(...)`, or both.
- `IsEnabled__c` - toggle without deleting the record.

The shipped rules are a reasonable baseline but they're not exhaustive. Any org that logs domain data with its own sensitive patterns (customer IDs, national ID numbers outside the US, API tokens, internal case numbers, etc.) should deploy additional `LogEntryDataMaskRule__mdt` records for those patterns rather than relying on developers to remember to strip the values manually before calling `Logger.info(...)`. Test the regex against representative strings before shipping - a too-greedy pattern can mangle unrelated substrings, and a too-narrow pattern lets the sensitive value through.

## First Troubleshooting Check

If logs are not created after deployment, check permission set assignment first, especially `LoggerEndUser` (or `LoggerLogCreator` for component/integration contexts). Missing permissions are the most common post-install issue.

## Next Steps

Once Nebula Logger is installed and permissioned, most teams' next step is one of:

- **Start logging** - see [nebula-logger-instrumentation](../nebula-logger-instrumentation/SKILL.md) for the APIs across Apex, LWC, Aura, Flow, and OmniStudio.
- **Set retention** - see [nebula-logger-purging-and-retention](../nebula-logger-purging-and-retention/SKILL.md) for `LogBatchPurger` scheduling and retention-day configuration.
- **Adopt team standards** - see [nebula-logger-best-practices](../nebula-logger-best-practices/SKILL.md) for environment-aware logging levels and review guardrails.
- **Investigate existing logs** - see [nebula-logger-console](../nebula-logger-console/SKILL.md) for the console app and its list views.
