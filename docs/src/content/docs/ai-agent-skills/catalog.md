---
title: Skill catalog
description: What each Nebula Logger AI agent skill covers.
---

Seven skills ship with Nebula Logger. Each has a specific scope, so agents load only what's relevant to the current task rather than dumping the whole documentation set into context.

## Setup

**`nebula-logger-install`**
Installing Nebula Logger in a Salesforce org for the first time. Covers package selection, installation paths, permissions, `LoggerSettings__c` hierarchy, and first-run troubleshooting. See also: [Getting Started](/getting-started/install-unlocked/).

## Usage

**`nebula-logger-instrumentation`**
Adding or updating instrumentation across Apex, LWC, Aura, Flow, and OmniStudio. Covers the logging APIs, save patterns, record association, scenarios, tags, async transaction linking, and save method selection. See also: [Logging Guide](/logging-guide/concepts/).

**`nebula-logger-testing-your-code`**
Writing Apex or LWC tests for code that calls Nebula Logger. Covers observing that the right entries were buffered, controlling logging levels inside tests, isolating tests from persisted records, and the `global` APIs safe for use from external test suites. See also: [Testing your instrumentation](/logging-guide/testing/).

## Operations

**`nebula-logger-console`**
Browsing, filtering, and investigating log data in the Salesforce UI. Covers the Logger Console app, list views on `Log__c` and `LogEntry__c`, related-list navigation, the Log record page and its LWCs, and typical admin/support workflows. See also: [Console & Operations](/console/logger-console-app/).

**`nebula-logger-purging-and-retention`**
Configuring how long Nebula Logger keeps log records before deleting or archiving them. Covers retention date semantics on `Log__c`, the `LogBatchPurger` batch job, `LogBatchPurgeScheduler`, purge action values, and how to tune retention per user, profile, or scenario. See also: [Retention & Purging](/retention/retention-dates/).

## Governance

**`nebula-logger-best-practices`**
Reviewing, hardening, or standardizing Nebula Logger usage across a team. Covers operational logging standards, environment-aware settings, limit-aware design, and governance guardrails. See also: [Environment-aware defaults](/configuration/environment-defaults/).

## Extending

**`nebula-logger-plugin-development`**
Building a new plugin that extends Nebula Logger - custom trigger handlers, custom purge actions, outbound integrations. Covers the plugin framework interfaces, `LoggerPlugin__mdt` configuration, package layout, and testing considerations. See also: [Plugin framework overview](/plugins/overview/).

## How skills relate to this documentation

- **Skills** are prescriptive - they tell an AI agent "do X, then Y" for a specific task.
- **This documentation** is descriptive - it explains how the framework works, in narrative form for humans.

Both share the same underlying facts. Skills are optimized for agents making a change; docs are optimized for humans reading to learn. Each cross-links to the other.

## Where next

- [Installing the skills](/ai-agent-skills/installing/) - how to add them to your project.
- [Logging Guide](/logging-guide/concepts/) - the human-facing counterpart to `nebula-logger-instrumentation`.
