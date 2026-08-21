---
title: Plugin framework overview
description: How Nebula Logger's two extension points work and how plugins register themselves.
---

Nebula Logger's plugin framework lets you register Apex classes (or Flows) to run inside two extension points. Both are driven by `LoggerPlugin__mdt` records, so adding a plugin is:

1. Write an Apex class implementing the right interface.
2. Create a `LoggerPlugin__mdt` record that points at it.

## Package compatibility

**The plugin framework is only available in the unlocked package.** The managed package (namespace `Nebula`) does not currently expose the plugin extension points. If you plan to consume or write plugins, install the unlocked package.

Note: `LoggerPlugin`, `LoggerPlugin.Triggerable`, `LoggerPlugin.Batchable`, `LoggerTriggerableContext`, and `LoggerBatchableContext` are `public`, not `global`. This is a deliberate exception to the general "only rely on `global`" guidance - the extension points are only reachable inside the unlocked package's own compilation unit.

## The two extension points

### Trigger extension point

Runs during `LoggerSObjectHandler` execution on:

- `LogEntryEvent__e`
- `Log__c`
- `LogEntry__c`
- `LogEntryTag__c`
- `LoggerScenario__c`
- `LoggerTag__c`

Use it to add fields, enrich data, or send external notifications when a log is created or updated.

### Batch extension point

Runs during `LogBatchPurger` execution. Use it to archive logs to an external system, apply custom purge policies, or emit metrics on purged records before they're deleted.

## The interfaces

Both interfaces live on `LoggerPlugin` in the `Nebula Logger - Core` package.

**`LoggerPlugin.Triggerable`** - one method:

```apex
void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input);
```

**`LoggerPlugin.Batchable`** - three methods matching `Database.Batchable`:

```apex
void start(LoggerPlugin__mdt configuration, LoggerBatchableContext input);
void execute(LoggerPlugin__mdt configuration, LoggerBatchableContext input, List<SObject> scopeRecords);
void finish(LoggerPlugin__mdt configuration, LoggerBatchableContext input);
```

## `LoggerPlugin__mdt` configuration

One `LoggerPlugin__mdt` record per plugin. Key fields:

| Field                                             | Purpose                                                                                   |
| ------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `DeveloperName` / `Label`                         | Identify the plugin.                                                                      |
| `IsEnabled__c`                                    | Toggle without deleting. `SubscriberControlled`, so admins can flip it in installed orgs. |
| `SObjectHandlerApexClass__c`                      | Apex class implementing `LoggerPlugin.Triggerable`. Use this OR the Flow field, not both. |
| `SObjectHandlerFlowName__c`                       | Flow API name for a Flow-based trigger plugin.                                            |
| `SObjectHandlerExecutionOrder__c`                 | Ordering when multiple plugins hit the same handler. Lower runs first.                    |
| `BatchPurgerApexClass__c`                         | Apex class implementing `LoggerPlugin.Batchable`. Runs inside `LogBatchPurger`.           |
| `BatchPurgerFlowName__c`                          | Flow API name for a Flow-based batch plugin.                                              |
| `BatchPurgerExecutionOrder__c`                    | Ordering across multiple batch plugins.                                                   |
| `Description__c` / `Link__c` / `VersionNumber__c` | Metadata surfaced in the Logger Console for admin awareness.                              |

Leave whichever fields aren't relevant (Apex vs Flow, trigger vs batch) as null.

## Ordering and composition

- Trigger plugins run **after** the built-in `LoggerSObjectHandler` logic for that object.
- Multiple plugins on the same handler run in `SObjectHandlerExecutionOrder__c` order (nulls last, then by `DeveloperName`).
- Plugins that mutate the trigger records (adding tags, populating fields) should run before plugins that publish outbound notifications, so notifications see the enriched data.

## Where next

- [Building your own plugin](/NebulaLogger/plugins/building-your-own/) - full walkthrough of writing and registering a plugin.
- [Slack](/NebulaLogger/plugins/slack/), [Big Object Archiving](/NebulaLogger/plugins/big-object-archiving/), [Log Retention Rules](/NebulaLogger/plugins/log-retention-rules/), [Logger Admin Dashboard](/NebulaLogger/plugins/logger-admin-dashboard/), [Async Failure Additions](/NebulaLogger/plugins/async-failure-additions/) - shipped plugins.
