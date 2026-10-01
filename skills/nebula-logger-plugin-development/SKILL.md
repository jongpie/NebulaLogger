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

Nebula Logger's plugin framework lets you register Apex classes to run inside two extension points:

1. **Trigger extension point** - Runs during `LoggerSObjectHandler` execution on `LogEntryEvent__e`, `Log__c`, `LogEntry__c`, `LogEntryTag__c`, `LoggerScenario__c`, and `LoggerTag__c` triggers. Use this to add fields, enrich data, or send external notifications when a log is created.
2. **Batch extension point** - Runs during `LogBatchPurger` execution. Use this to archive logs to an external system, apply custom purge policies, or emit metrics on purged records before they're deleted.

Both extension points are driven by `LoggerPlugin__mdt` records. Adding a plugin means: writing an Apex class that implements the right interface (or both, if the plugin has trigger and batch responsibilities), then creating a `LoggerPlugin__mdt` record that points at it.

**Strongly prefer Apex over Flow for both extension points.** The framework technically supports Flow-based plugins via `SObjectHandlerFlowName__c` / `BatchPurgerFlowName__c`, but Flow support currently has known issues with no fixed ETA - it may be deprecated altogether in a future release. New plugins should implement the Apex interfaces below and leave the Flow fields on the `LoggerPlugin__mdt` record blank.

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

| Field                                             | Purpose                                                                                                                 |
| ------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `DeveloperName` / `Label`                         | Identify the plugin.                                                                                                    |
| `IsEnabled__c`                                    | Toggle without deleting the record. Marked as `SubscriberControlled` so admins can flip it in installed orgs.           |
| `SObjectHandlerApexClass__c`                      | Apex class name implementing `LoggerPlugin.Triggerable`. Set this to register the class at the trigger extension point. |
| `SObjectHandlerFlowName__c`                       | Flow API name for a Flow-based trigger plugin. Leave null - see the "prefer Apex" note above.                           |
| `SObjectHandlerExecutionOrder__c`                 | Integer that orders multiple plugins on the same handler. Lower numbers run first. Ties are broken by developer name.   |
| `BatchPurgerApexClass__c`                         | Apex class name implementing `LoggerPlugin.Batchable`. Set this to register the class at the batch extension point.     |
| `BatchPurgerFlowName__c`                          | Flow API name for a Flow-based batch plugin. Leave null - see the "prefer Apex" note above.                             |
| `BatchPurgerExecutionOrder__c`                    | Ordering across multiple batch plugins.                                                                                 |
| `Description__c` / `Link__c` / `VersionNumber__c` | Metadata surfaced in the Logger Console for admin awareness.                                                            |

Set whichever combination of the Apex class fields matches what the class implements: `SObjectHandlerApexClass__c` for a `LoggerPlugin.Triggerable`, `BatchPurgerApexClass__c` for a `LoggerPlugin.Batchable`, or both fields pointing at the same class when it implements both interfaces (like `LogEntryArchivePlugin`). Leave the Flow fields null.

## Plugin Folder Layout

Existing plugins under `nebula-logger/plugins/<name>/` follow a consistent layout. When scaffolding a new plugin, mirror it:

```
nebula-logger/plugins/<name>/
  plugin/
    classes/               # Apex classes (both implementation and *_Tests.cls test classes)
    customMetadata/        # LoggerPlugin.<Name>.md-meta.xml
    objects/               # Any plugin-specific custom objects/fields (optional)
    permissionsets/        # <Name>PluginAdmin.permissionset-meta.xml (optional)
    testSuites/            # <Name>Plugin.testSuite-meta.xml grouping the plugin's test classes
  README.md
```

Test classes live in the same `plugin/classes/` folder as the code under test - they aren't split into a separate top-level `tests/` folder. The Slack plugin's `plugin/slack/` subfolder is a plugin-specific quirk from packaging around some shared `core/main` metadata; new plugins should drop the extra nesting and put everything directly under `plugin/`.

The `LoggerPlugin.<Name>.md-meta.xml` file is the registration record - populate `SObjectHandlerApexClass__c` and/or `BatchPurgerApexClass__c` per the guidance above. Existing plugins to reference:

- `nebula-logger/plugins/slack/` - trigger plugin that sends Slack notifications.
- `nebula-logger/plugins/log-retention-rules/` - trigger plugin that sets `LogRetentionDate__c` based on CMDT rules.
- `nebula-logger/plugins/big-object-archiving/` - implements BOTH interfaces on a single class (`LogEntryArchivePlugin`) - the trigger side captures records to the big object, the batch side archives before purge.
- `nebula-logger/plugins/async-failure-additions/` - adds logging for `FlowExecutionErrorEvent`, unexpected batch failures, and Queueable finalizers.

## Ordering and Composition

- Trigger plugins run **after** the built-in `LoggerSObjectHandler` logic for that object.
- Multiple plugins on the same handler run in `SObjectHandlerExecutionOrder__c` order (nulls last, then by `DeveloperName`).
- Plugins that mutate the trigger records (adding tags, populating fields) should run before plugins that publish outbound notifications, so notifications see the enriched data.

## Testing Plugins

- Ship each plugin with a matching `<PluginClass>_Tests.cls` alongside the implementation class in `plugin/classes/`.
- Add the plugin's test classes to a `<Name>Plugin.testSuite-meta.xml` under `plugin/testSuites/` (see `LoggerLogEntryArchivePlugin.testSuite-meta.xml` and `LoggerLogRetentionRulesPlugin.testSuite-meta.xml` for the pattern). The suite becomes the target of a `sf apex run test --suite-names <Name>Plugin` invocation. Only the core package currently has a dedicated `npm run test:apex:suite:core` script; plugin suites are exercised through `npm run test:apex` (which runs `RunLocalTests`) or an ad-hoc `sf apex run test --suite-names` call.
- For trigger plugins, construct a `LoggerTriggerableContext` manually with the trigger records you want to exercise, then call `execute(configuration, input)` directly. Do not require a real trigger fire in tests.
- For batch plugins, construct a `LoggerBatchableContext` and pass a synthesized `scopeRecords` list. Assert on the side effects (DML, callouts via `System.Test.setMock`, published events).

## New Plugin Checklist

Before shipping a new plugin:

1. Apex class implements at least one of `LoggerPlugin.Triggerable` / `LoggerPlugin.Batchable` - both is fine when a single class needs to react to trigger events and participate in the purge batch.
2. `LoggerPlugin.<Name>.md-meta.xml` exists, has `IsEnabled__c=true` (or `false` if opt-in), and populates the class-name field(s) that match the interfaces the class implements: `SObjectHandlerApexClass__c` for `Triggerable`, `BatchPurgerApexClass__c` for `Batchable`, or both fields when the class implements both interfaces.
3. `<Name>PluginAdmin.permissionset-meta.xml` grants full access on plugin-owned objects and CMDT.
4. `<PluginClass>_Tests.cls` covers happy path, empty scope, and disabled-configuration cases.
5. `README.md` in the plugin folder documents install steps and any prerequisites.
6. `sfdx-project.json` has a `packageDirectories` entry for the plugin so it can be built and installed as its own unlocked package.

## Related Skills

- [nebula-logger-console](../nebula-logger-console/SKILL.md) - The `LoggerPlugin__mdt` list view in the console is where admins toggle plugins on and off.
- [nebula-logger-purging-and-retention](../nebula-logger-purging-and-retention/SKILL.md) - Where `LoggerPlugin.Batchable` plugins slot in.
