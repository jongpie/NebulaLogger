---
title: Logger Console app
description: A tour of the Logger Console Lightning app that ships with Nebula Logger.
---

The **Logger Console** is a Salesforce Lightning app that ships with Nebula Logger. It gives admins, support engineers, and developers a purpose-built place to browse logs without hand-writing SOQL against `Log__c` and `LogEntry__c` every time something happens in production.

![Logger Console app](/images/logger-console-app.png)

## Finding the app

- App API name: `LoggerConsole`.
- Open from the App Launcher > "Logger Console".
- Users need one of the four Logger permission sets - typically `LoggerAdmin` or `LoggerLogViewer`.

## What's in the app

### Navigation entries

The app's navigation surfaces the objects most useful for investigation:

- `Log__c` - transactions.
- `LogEntry__c` - individual entries.
- `LoggerScenario__c` - scenario definitions.
- `LoggerTag__c` - tag definitions.
- `LogEntryTag__c` - the junction between entries and tags.

### Utility bar

A **Logger Settings** utility bar item (from the `LoggerConsoleUtilityBar` FlexiPage) surfaces the effective `LoggerSettings__c` record without leaving the console. Use it to toggle logging on/off or adjust the effective level while investigating.

### Home page

The console's home page (`LoggerHomePage` FlexiPage) is where the console's most operational tools live:

- **`logEntryEventStream`** - subscribes to the `LogEntryEvent__e` platform event and shows log entries in real time. This is the fastest way to confirm logging is firing during a test scenario without waiting for the async save path.

  ![Log Entry Event Stream](/images/log-entry-event-stream.png)

- **`logBatchPurge`** - triggers the log purge batch on demand and reports counts.
- **`loggerSettings`** - the same settings editor exposed in the utility bar, on a full-page canvas.
- **`loggerHomeHeader`** - navigation header with quick links to release notes, GitHub, and the docs.
- Embedded reports and dashboards showing recent activity across `Log__c` and `LogEntry__c`.

Together, these give an admin one page to answer "is logging healthy right now, and what does it look like?"

## Where next

- [Log record page](/console/log-record-page/) - the shipped record page for `Log__c`.
- [Related Log Entries component](/console/related-log-entries/) - embed on any Lightning record page.
- [Investigation playbooks](/console/investigation-playbooks/) - concrete workflows for common tasks.
