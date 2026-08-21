---
title: Building your own plugin
description: End-to-end walkthrough of writing and registering a Nebula Logger plugin.
---

Writing a plugin is: pick the right interface, implement it, register it with a `LoggerPlugin__mdt` record, ship it.

## Which interface

- **Trigger plugin** (`LoggerPlugin.Triggerable`) - runs during `LoggerSObjectHandler` execution. Use for enrichment, outbound notifications, and per-record automation on `LogEntryEvent__e`, `Log__c`, `LogEntry__c`, and the tag junctions.
- **Batch plugin** (`LoggerPlugin.Batchable`) - runs during `LogBatchPurger` execution. Use for archival, custom purge policies, and metrics.

A plugin implements exactly one of the two.

## Example: trigger plugin

Suppose you want to auto-tag every `ERROR` entry with `severity:actionable`.

```apex
public with sharing class AutoSeverityTagPlugin implements LoggerPlugin.Triggerable {
  public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input) {
    if (input.sobjectType != Schema.LogEntry__c.SObjectType) {
      return;
    }
    if (input.triggerOperationType != System.TriggerOperation.BEFORE_INSERT) {
      return;
    }
    for (LogEntry__c entry : (List<LogEntry__c>) input.triggerNew) {
      if (entry.LoggingLevel__c == 'ERROR') {
        entry.Tags__c = (entry.Tags__c == null ? '' : entry.Tags__c + ',') + 'severity:actionable';
      }
    }
  }
}
```

## Example: batch plugin

Suppose you want to emit a platform event with counts of purged entries.

```apex
public with sharing class PurgeMetricsPlugin implements LoggerPlugin.Batchable {
  private Integer totalPurged = 0;

  public void start(LoggerPlugin__mdt configuration, LoggerBatchableContext input) {
    this.totalPurged = 0;
  }

  public void execute(LoggerPlugin__mdt configuration, LoggerBatchableContext input, List<SObject> scopeRecords) {
    if (input.sobjectType == Schema.LogEntry__c.SObjectType) {
      this.totalPurged += scopeRecords.size();
    }
  }

  public void finish(LoggerPlugin__mdt configuration, LoggerBatchableContext input) {
    EventBus.publish(new PurgeMetric__e(TotalPurged__c = this.totalPurged));
  }
}
```

## Register the plugin

Create a `LoggerPlugin__mdt` record. For the trigger plugin above:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" fqn="LoggerPlugin.AutoSeverityTag">
    <label>Auto Severity Tag</label>
    <protected>false</protected>
    <values>
        <field>IsEnabled__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
    <values>
        <field>SObjectHandlerApexClass__c</field>
        <value xsi:type="xsd:string">AutoSeverityTagPlugin</value>
    </values>
    <values>
        <field>SObjectHandlerExecutionOrder__c</field>
        <value xsi:type="xsd:double">10</value>
    </values>
</CustomMetadata>
```

For a batch plugin, populate `BatchPurgerApexClass__c` instead.

## Plugin folder layout

If you're shipping the plugin as its own package (rather than inline in an existing project), mirror the layout used by the shipped plugins:

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

The `LoggerPlugin.<Name>.md-meta.xml` file is the registration record.

## Testing plugins

- Write a `<PluginClass>_Tests.cls` alongside the implementation under `plugin/<name>/classes/`.
- Add the plugin's test class to a Logger test suite so `npm run test:apex:suite:<name>` covers it.
- **For trigger plugins**: construct a `LoggerTriggerableContext` manually with the trigger records you want to exercise, then call `execute(configuration, input)` directly. Do not require a real trigger fire in tests.
- **For batch plugins**: construct a `LoggerBatchableContext` and pass a synthesized `scopeRecords` list. Assert on side effects (DML, callouts via `System.Test.setMock`, published events).

## Ordering

- Trigger plugins run **after** the built-in `LoggerSObjectHandler` logic for that object.
- Multiple plugins on the same handler run in `SObjectHandlerExecutionOrder__c` order (nulls last, then by `DeveloperName`).
- Plugins that mutate records (adding tags, populating fields) should run before plugins that publish outbound notifications, so notifications see the enriched data.

## New plugin checklist

Before shipping:

1. Apex class implements exactly one of `LoggerPlugin.Triggerable` / `LoggerPlugin.Batchable`.
2. `LoggerPlugin.<Name>.md-meta.xml` exists, has `IsEnabled__c = true` (or `false` if opt-in), and points at the class.
3. `<Name>PluginAdmin.permissionset-meta.xml` grants full access on plugin-owned objects and CMDT.
4. `<PluginClass>_Tests.cls` covers happy path, empty scope, and disabled-configuration cases.
5. `README.md` in the plugin folder documents install steps and any prerequisites.
6. `sfdx-project.json` has a `packageDirectories` entry for the plugin so it can be built as its own unlocked package.

## Where next

- [Plugin framework overview](/NebulaLogger/plugins/overview/) - interface details.
- Existing plugins to read for reference: [Slack](/NebulaLogger/plugins/slack/), [Big Object Archiving](/NebulaLogger/plugins/big-object-archiving/), [Log Retention Rules](/NebulaLogger/plugins/log-retention-rules/), [Async Failure Additions](/NebulaLogger/plugins/async-failure-additions/).
