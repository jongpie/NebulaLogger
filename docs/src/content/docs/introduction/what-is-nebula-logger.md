---
title: What is Nebula Logger
description: An introduction to Nebula Logger, the observability framework for Salesforce Apex, Lightning Components, Flow, and OmniStudio.
---

Nebula Logger is a native Salesforce logging framework. It gives one API for producing structured log records across Apex, Lightning Web Components, Aura, Flow, and OmniStudio, plus a Logger Console app for browsing what those records produced.

Every runtime context - synchronous Apex, batch, queueable, LWC, Aura, Flow, OmniStudio, and platform-event triggers - uses the same core model: add entries at a level, optionally enrich them with a record or exception, then persist the buffer once at the end of the transaction. The `Log__c` and `LogEntry__c` records that come out are queryable, reportable, and linkable to any Salesforce record.

## Why not just System.debug()

`System.debug()` is fine during active debugging. It is not a durable observability strategy.

- Debug logs have short retention windows and are hard to query historically.
- Searching by user, business record, scenario, or tag is not something debug logs support.
- Debug logs are single-runtime - they do not help Flow, LWC, OmniStudio, or async chains.
- Debug logs cannot be routed to Slack, archived to a big object, or filtered by scenario rules.

Nebula Logger gives teams a consistent, queryable logging model that survives past the debug log's short retention window and works the same way in every runtime context.

## What ships

- One core unlocked or managed package containing Apex, LWCs, custom objects, custom metadata types, and permission sets.
- Five plugins that extend the core: Slack, Big Object Archiving, Log Retention Rules, Logger Admin Dashboard, Async Failure Additions.
- A Logger Console Lightning app with prebuilt list views, a log record page, and live log-entry streaming.
- Optional AI agent skills that teach Claude Code, Copilot, Cursor, and similar tools how to install, use, and extend Nebula Logger.

## Who uses it

- **Platform developers** who want a durable, queryable log record instead of debug logs.
- **Support and operations engineers** who need to investigate production incidents without asking a developer to reproduce them.
- **Admins** who want to see who did what, when, in the same UI they already use.
- **ISVs and package developers** who want to emit rich telemetry in customer orgs when Nebula Logger is installed, without hard-requiring it.

## Where next

- [How it works](/introduction/how-it-works/) - the architecture.
- [Feature tour](/introduction/feature-tour/) - a walkthrough of the shipped features.
- [Package options](/introduction/package-options/) - unlocked vs managed vs bundled.
- [Getting Started](/getting-started/install-unlocked/) - install and configure.
