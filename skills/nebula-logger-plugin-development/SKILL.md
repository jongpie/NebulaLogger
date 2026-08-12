---
name: nebula-logger-plugin-development
description: Use this skill when the user wants to build a new plugin that extends Nebula Logger - for example, custom trigger handlers on `LogEntryEvent__e` / `Log__c` / `LogEntry__c`, custom purge actions, or Slack-style outbound integrations. Covers the plugin framework interfaces, `LoggerPlugin__mdt` configuration, package layout, and testing considerations.
---

# Building Plugins for Nebula Logger

## Package Compatibility

The plugin framework is **only available in the unlocked package**. The managed package (namespace `Nebula`) does not currently expose the plugin extension points.

If you plan to write plugins, install the unlocked package. See [nebula-logger-install](../nebula-logger-install/SKILL.md) for the choice.

Note that `LoggerPlugin`, `LoggerPlugin.Triggerable`, `LoggerPlugin.Batchable`, `LoggerTriggerableContext`, and `LoggerBatchableContext` are all `public` (not `global`). Everywhere else in this skill collection, the guidance is "only rely on `global`" (see the "Supported API Surface" section of [nebula-logger-instrumentation](../nebula-logger-instrumentation/SKILL.md)). The plugin framework is a deliberate exception: the extension points are `public` because they're only reachable inside the unlocked package's own compilation unit. As with any `public` surface, breaking changes are possible - pin plugins to a Nebula Logger version you've tested against and re-verify after upgrades.

## Plugin Framework Overview

Nebula Logger's plugin framework lets you register Apex classes (or Flows) to run inside two extension points:

1. **Trigger extension point** - Runs during `LoggerSObjectHandler` execution on `LogEntryEvent__e`, `Log__c`, `LogEntry__c`, `LogEntryTag__c`, `LoggerScenario__c`, and `LoggerTag__c` triggers. Use this to add fields, enrich data, or send external notifications when a log is created.
2. **Batch extension point** - Runs during `LogBatchPurger` execution. Use this to archive logs to an external system, apply custom purge policies, or emit metrics on purged records before they're deleted.

Both extension points are driven by `LoggerPlugin__mdt` records. Adding a plugin means: writing an Apex class that implements the right interface, then creating a `LoggerPlugin__mdt` record that points at it.

## The Two Interfaces

Both interfaces live on `LoggerPlugin` in the `Nebula Logger - Core` package.

### `LoggerPlugin.Triggerable` (trigger extension point)

Implement one method:

```apex
void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input);
```

- `configuration` is the `LoggerPlugin__mdt` record that registered the plugin - use it to read plugin-specific settings.
- `input` describes the current trigger context and exposes `sobjectType`, `triggerOperationType`, `triggerNew`, `triggerNewMap`, `triggerOldMap`, and a `triggerRecords` list that pairs old/new record versions per record (populated for Flow-friendly access).

### `LoggerPlugin.Batchable` (batch extension point)

Implement three methods matching the `Database.Batchable` lifecycle:

```apex
void start(LoggerPlugin__mdt configuration, LoggerBatchableContext input);
void execute(LoggerPlugin__mdt configuration, LoggerBatchableContext input, List<SObject> scopeRecords);
void finish(LoggerPlugin__mdt configuration, LoggerBatchableContext input);
```

`scopeRecords` is the current batch of records `LogBatchPurger` is about to process. `LogBatchPurger` walks the object hierarchy from the lowest level up (`LogEntryTag__c`, then `LogEntry__c`, then `Log__c`), filtered to records whose parent `Log__c.LogRetentionDate__c` is past-due. Check `input.sobjectType` if the plugin behavior needs to differ per object.

## `LoggerPlugin__mdt` Configuration

Every plugin gets one `LoggerPlugin__mdt` record. Key fields:

| Field                                             | Purpose                                                                                                               |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `DeveloperName` / `Label`                         | Identify the plugin.                                                                                                  |
| `IsEnabled__c`                                    | Toggle without deleting the record. Marked as `SubscriberControlled` so admins can flip it in installed orgs.         |
| `SObjectHandlerApexClass__c`                      | Apex class name implementing `LoggerPlugin.Triggerable`. Use this OR `SObjectHandlerFlowName__c`, not both.           |
| `SObjectHandlerFlowName__c`                       | Flow API name for a Flow-based trigger plugin.                                                                        |
| `SObjectHandlerExecutionOrder__c`                 | Integer that orders multiple plugins on the same handler. Lower numbers run first. Ties are broken by developer name. |
| `BatchPurgerApexClass__c`                         | Apex class name implementing `LoggerPlugin.Batchable`. Runs inside `LogBatchPurger`.                                  |
| `BatchPurgerFlowName__c`                          | Flow API name for a Flow-based batch plugin.                                                                          |
| `BatchPurgerExecutionOrder__c`                    | Ordering across multiple batch plugins.                                                                               |
| `Description__c` / `Link__c` / `VersionNumber__c` | Metadata surfaced in the Logger Console for admin awareness.                                                          |

Leave whichever fields are not relevant (Apex vs Flow, trigger vs batch) as null.

## Plugin Folder Layout

Existing plugins under `nebula-logger/plugins/<name>/` follow a consistent layout. When scaffolding a new plugin, mirror it:

```
nebula-logger/plugins/<name>/
  plugin/
    <name>/
      classes/               # Apex classes (impl + tests)
      customMetadata/        # LoggerPlugin.<Name>.md-meta.xml
      objects/               # Any plugin-specific custom objects/fields
      permissionsets/        # <Name>PluginAdmin.permissionset-meta.xml
  tests/                     # Additional test artifacts (test suite, test permsets)
  README.md
```

The `LoggerPlugin.<Name>.md-meta.xml` file is the registration record - point `SObjectHandlerApexClass__c` (or `BatchPurgerApexClass__c`) at your class name. Existing plugins to reference:

- `nebula-logger/plugins/slack/` - trigger plugin that sends Slack notifications.
- `nebula-logger/plugins/log-retention-rules/` - trigger plugin that sets `LogRetentionDate__c` based on CMDT rules.
- `nebula-logger/plugins/big-object-archiving/` - batch plugin that copies logs to a big object before purge.
- `nebula-logger/plugins/async-failure-additions/` - trigger plugin that enriches async-failure log entries.

## Ordering and Composition

- Trigger plugins run **after** the built-in `LoggerSObjectHandler` logic for that object.
- Multiple plugins on the same handler run in `SObjectHandlerExecutionOrder__c` order (nulls last, then by `DeveloperName`).
- Plugins that mutate the trigger records (adding tags, populating fields) should run before plugins that publish outbound notifications, so notifications see the enriched data.

## Testing Plugins

- Ship each plugin with a matching `<PluginClass>_Tests.cls` under `plugin/<name>/classes/`.
- Add the plugin's test class to a Logger test suite so `npm run test:apex:suite:<name>` covers it.
- For trigger plugins, construct a `LoggerTriggerableContext` manually with the trigger records you want to exercise, then call `execute(configuration, input)` directly. Do not require a real trigger fire in tests.
- For batch plugins, construct a `LoggerBatchableContext` and pass a synthesized `scopeRecords` list. Assert on the side effects (DML, callouts via `System.Test.setMock`, published events).

## New Plugin Checklist

Before shipping a new plugin:

1. Apex class implements exactly one of `LoggerPlugin.Triggerable` / `LoggerPlugin.Batchable`.
2. `LoggerPlugin.<Name>.md-meta.xml` exists, has `IsEnabled__c=true` (or `false` if opt-in), and points at the class.
3. `<Name>PluginAdmin.permissionset-meta.xml` grants full access on plugin-owned objects and CMDT.
4. `<PluginClass>_Tests.cls` covers happy path, empty scope, and disabled-configuration cases.
5. `README.md` in the plugin folder documents install steps and any prerequisites.
6. `sfdx-project.json` has a `packageDirectories` entry for the plugin so it can be built and installed as its own unlocked package.

## Related Skills

- [nebula-logger-console](../nebula-logger-console/SKILL.md) - The `LoggerPlugin__mdt` list view in the console is where admins toggle plugins on and off.
- [nebula-logger-purging-and-retention](../nebula-logger-purging-and-retention/SKILL.md) - Where `LoggerPlugin.Batchable` plugins slot in.
