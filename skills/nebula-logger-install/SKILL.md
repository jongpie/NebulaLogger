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

| Area | Unlocked Package | Managed Package |
| --- | --- | --- |
| Namespace | None | `Nebula` |
| Release cadence | Faster patch cadence | Slower, stabilized cadence |
| Source visibility | Full source access in org | Packaged global API surface |
| Plugin framework | Available | Not currently available |
| Distribution model | GitHub-first OSS workflow | AppExchange-friendly for managed delivery |
| Typical recommendation | Best for most internal Salesforce teams | Best when managed namespace packaging is required |

If your team is not constrained by managed-package requirements, start with the unlocked package.

## Installation Options

Always confirm the latest version on:

- https://github.com/jongpie/NebulaLogger/releases

At the time of writing, the project README lists these install links and package IDs. These links might be outdated in the future, so always check the README for the latest.

### Browser install links

- Unlocked sandbox: `https://test.salesforce.com/packaging/installPackage.apexp?p0=04tg70000009GaDAAU`
- Unlocked production: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04tg70000009GaDAAU`
- Managed sandbox: `https://test.salesforce.com/packaging/installPackage.apexp?mgd=true&p0=04tg700000086RdAAI`
- Managed production: `https://login.salesforce.com/packaging/installPackage.apexp?mgd=true&p0=04tg700000086RdAAI`

### Salesforce CLI install

```bash
# Unlocked package (from README)
sf package install --wait 20 --security-type AdminsOnly --package 04tg70000009GaDAAU

# Managed package (from README)
sf package install --wait 30 --security-type AdminsOnly --package 04tg700000086RdAAI
```

## Permission Sets to Assign

Assign permission sets as part of rollout. Exact API names in the repo are:

| Permission Set | Purpose | Typical users |
| --- | --- | --- |
| `LoggerAdmin` | Full control of Nebula Logger data and features | Platform admins, support leads |
| `LoggerLogViewer` | Read-only access to logs and console features | Operations, QA, support analysts |
| `LoggerEndUser` | Limited day-to-day access with controlled visibility | Business users who need log visibility |
| `LoggerLogCreator` | Minimal metadata/object access needed to generate logs | Integration users, Experience Cloud component users |

## Configure LoggerSettings__c Hierarchy

Nebula Logger uses a hierarchy custom setting so behavior can be tuned at multiple scopes:

1. Org default baseline.
2. Profile-level override.
3. User-level override.

Prioritize these settings during onboarding:

| Field | What it controls |
| --- | --- |
| `IsEnabled__c` | Global on/off switch for logging behavior at the effective hierarchy level |
| `LoggingLevel__c` | Effective minimum logging level for the user/profile/org context |
| `DefaultSaveMethod__c` | Default save strategy used by `Logger.saveLog()` |
| `DefaultLogPurgeAction__c` | Default cleanup behavior for old logs |
| `DefaultNumberOfDaysToRetainLogs__c` | Retention window for generated logs |

Note: older references may mention `DefaultLoggingLevel__c`; in this codebase the active field is `LoggingLevel__c`.

## First Troubleshooting Check

If logs are not created after deployment, check permission set assignment first, especially `LoggerEndUser` (or `LoggerLogCreator` for component/integration contexts). Missing permissions are the most common post-install issue.
