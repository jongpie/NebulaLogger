---
title: Slack plugin
description: Send Nebula Logger entries to a Slack workspace.
---

The Slack plugin sends configured log entries to a Slack workspace as messages. Useful for surfacing production errors and warnings in a team channel without waiting for someone to notice a `LogEntry__c` record.

## What it does

- Registers a trigger plugin on `LogEntryEvent__e`.
- When a log entry matches configured criteria, posts a message to Slack via a Slack webhook (or configured Slack app).
- Includes message, level, user context, and a link back to the `Log__c` record in Salesforce.

## Installation

The Slack plugin ships as its own unlocked package. Install it _after_ the core Nebula Logger unlocked package - it depends on the core types.

Install via URL or `sf package install`. The exact package ID is on the [GitHub releases page](https://github.com/jongpie/NebulaLogger/releases) - look for releases tagged with `slack`.

After installation, assign the `LoggerSlackPluginAdmin` permission set to admins who need to configure it.

## Configuration

- Configure a Slack webhook URL as a named credential (Salesforce Setup > Named Credentials).
- Enable the Slack plugin by editing its `LoggerPlugin__mdt` record - `IsEnabled__c = true`.
- Filter which entries trigger a Slack message via the plugin's CMDT configuration (typically level threshold and/or scenario / tag matches).

## When to use it

- Production `ERROR` entries you want visible in a team's Slack channel.
- Specific business scenarios (e.g. failed payments, integration errors) where a Slack alert is more useful than a periodic log review.

## What to watch for

- **Volume**: Slack rate limits messages. If your `ERROR` volume is high, filter more aggressively or route to a dedicated channel.
- **Sensitive data**: Slack messages leave Salesforce. If any log message might contain sensitive data, verify [data masking](/NebulaLogger/configuration/data-mask-rules/) covers it - or filter those entries out entirely.
- **Chatty transactions**: if a single transaction adds 20 error entries, each triggers a Slack post. Consider adjusting the plugin's filter to only fire once per transaction rather than per entry.

## Where next

- [Slack plugin reference](/NebulaLogger/reference/plugins/slack/) - auto-generated `SlackLoggerPlugin` API reference.
- [Plugin framework overview](/NebulaLogger/plugins/overview/) - how plugins hook in.
- [Building your own plugin](/NebulaLogger/plugins/building-your-own/) - write a similar outbound integration.
