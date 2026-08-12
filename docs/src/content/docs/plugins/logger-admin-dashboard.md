---
title: Logger Admin Dashboard plugin
description: A Lightning dashboard giving admins a high-level view of Nebula Logger activity.
---

The Logger Admin Dashboard plugin adds a curated Lightning dashboard for admins to monitor Nebula Logger's overall health and activity.

## What it adds

- A Lightning dashboard with prebuilt charts showing log activity by level, scenario, origin, user, and time.
- Reports backing the dashboard's charts, available for admins to drill into or clone.

## Installation

Ships as its own unlocked package. Install after the core Nebula Logger unlocked package. See the [GitHub releases page](https://github.com/jongpie/NebulaLogger/releases) for the current package ID.

## Configuration

Once installed, open the App Launcher > Reports & Dashboards > look for the "Logger Admin Dashboard" folder. The dashboard should be ready to view immediately - it queries `Log__c` and `LogEntry__c` records with the standard permissions.

Filters on the dashboard let admins scope by:

- Time window (last 24h, 7d, 30d).
- Environment (via user context).
- Level thresholds.

## When to use it

- Weekly ops review: a five-minute scan of the dashboard tells you if log volume is trending up or down and where the noise is coming from.
- Post-deploy verification: after a big release, watch for a spike in `ERROR` entries.
- Capacity planning: log growth trends inform when to adjust retention or install the Big Object Archiving plugin.

## Where next

- [Big Object Archiving plugin](/plugins/big-object-archiving/) - offload aged data to keep storage bounded.
- [Configuration - Environment defaults](/configuration/environment-defaults/) - tuning verbosity based on what the dashboard shows.
