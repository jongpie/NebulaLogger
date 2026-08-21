---
title: Extending the data model
description: Add custom fields to LogEntryEvent__e, Log__c, LogEntry__c, and LoggerScenario__c and populate them from Apex or LWC.
---

Nebula Logger supports adding your own custom fields to its data model and populating them from Apex or LWC. Use this when a project needs to attach org-specific context to every log entry - business unit, environment tag, feature area, tenant ID - that isn't already in the shipped schema.

Requires Apex support from `v4.13.14` and LWC support from `v4.14.6`. Flow support isn't available yet.

## The pattern

Two steps for a field visible only on `LogEntryEvent__e`; four steps if you want the same value on `Log__c`, `LogEntry__c`, or `LoggerScenario__c`.

1. Add a custom field to `LogEntryEvent__e`.
2. Set the field's value from Apex or LWC using `setField(...)`.
3. (Optional) Add an equivalent field to `Log__c`, `LogEntry__c`, or `LoggerScenario__c`.
4. (Optional) Add a `LoggerFieldMapping__mdt` record to map the source field on `LogEntryEvent__e` to the target field on the custom object.

## Step 1: Add a field on `LogEntryEvent__e`

Create the field in Setup or via source metadata. Any data type supported by platform events is fair game.

Example: a text field `SomeCustomField__c` on `LogEntryEvent__e`.

![Custom field on LogEntryEvent__e](/images/custom-field-log-entry-event.png)

## Step 2: Set the value from your code

Two granularities in every runtime:

- **Transaction-wide**: set once, every entry in the transaction picks it up. Used for values that apply to a whole `Log__c` or `LoggerScenario__c` (environment, tenant, feature).
- **Per-entry**: set on a specific entry. Used for values that vary by entry and map to `LogEntry__c`.

### Apex

```apex
// Transaction-wide - every entry in this transaction gets My_Field__c set
Logger.setField(LogEntryEvent__e.My_Field__c, 'some value that applies to the whole Apex transaction');

// Per-entry - only these two entries get Some_Other_Field__c set
Logger.warn('First entry').setField(LogEntryEvent__e.Some_Other_Field__c, 'a value');
Logger.warn('Second entry').setField(LogEntryEvent__e.Some_Other_Field__c, 'different value');
Logger.info('Third entry with no custom field value');

Logger.saveLog();
```

Static overloads on `Logger`:

- `Logger.setField(Schema.SObjectField field, Object fieldValue)`
- `Logger.setField(Map<Schema.SObjectField, Object> fieldToValue)`

Instance overloads on `LogEntryEventBuilder` (returned by the level methods):

- `.setField(Schema.SObjectField field, Object fieldValue)`
- `.setField(Map<Schema.SObjectField, Object> fieldToValue)`

### LWC

```js
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';

export default class LoggerDemo extends LightningElement {
  logger = getLogger();

  connectedCallback() {
    // Component-wide - every entry from this component gets My_Field__c set
    this.logger.setField({ My_Field__c: 'some value that applies to any subsequent entry' });

    // Per-entry
    this.logger.warn('First entry').setField({ Some_Other_Field__c: 'a value' });
    this.logger.warn('Second entry').setField({ Some_Other_Field__c: 'different value' });
    this.logger.info('Third entry with no custom field value');

    this.logger.saveLog();
  }
}
```

Same two granularities:

- `logger.setField({ FieldApiName__c: value })` on the logger instance sets a component-wide default.
- `.setField({ FieldApiName__c: value })` on the builder returned by a level method sets it for that entry only.

## Step 3 (optional): Add the field on the custom object

If you want the value to end up on `Log__c`, `LogEntry__c`, or `LoggerScenario__c` in addition to `LogEntryEvent__e`, add a matching field on the target custom object. Only those three objects are supported as targets.

![Custom field on Log__c](/images/custom-field-log.png)

Common patterns:

- Field lives on `Log__c` for transaction-wide values (via `Logger.setField(...)`).
- Field lives on `LogEntry__c` for per-entry values (via `.setField(...)` on the builder).
- Field lives on `LoggerScenario__c` for values that describe the whole business process.

The custom-object field doesn't have to share the API name with the `LogEntryEvent__e` source field, but matching names keep things obvious.

## Step 4 (optional): Map source to target via `LoggerFieldMapping__mdt`

To make Nebula Logger auto-populate the custom-object field from the platform event, create a `LoggerFieldMapping__mdt` record with:

- Source object: `LogEntryEvent__e`.
- Source field: your new `LogEntryEvent__e.<Field>__c`.
- Target object: `Log__c`, `LogEntry__c`, or `LoggerScenario__c`.
- Target field: the custom field you added in Step 3.

Nebula Logger reads these mapping records during the platform event trigger and copies values across automatically. No trigger customization required.

![Custom field mapping CMDT record](/images/custom-field-mapping.png)

## What this pattern is not

- **Not a substitute for scenarios and tags**. Scenarios group transactions, tags label entries - both are cross-cutting features designed for filtering and reporting. Custom fields are for org-specific data that doesn't map to the tag/scenario model.
- **Not a supported way to modify built-in fields**. Adding new fields is supported; overriding or reinterpreting existing Nebula Logger fields is not.
- **Not available in Flow**. Flow support is planned but not shipped as of this documentation.
- **Not available in OmniStudio directly**. `CallableLogger` doesn't expose `setField` yet - use Apex or LWC contexts for now.

## Where next

- [Concepts](/NebulaLogger/logging-guide/concepts/) - the model these fields extend.
- [Scenarios](/NebulaLogger/logging-guide/scenarios/) - when a scenario is a better fit than a custom field.
- [Tags](/NebulaLogger/logging-guide/tags/) - when a tag is a better fit than a custom field.
- [`LoggerFieldMapping__mdt` reference](/NebulaLogger/reference/custom-objects/loggerfieldmapping__mdt/) - the mapping CMDT.
