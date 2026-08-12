---
title: LoggerParameter__mdt feature flags
description: Global framework feature flags stored as custom metadata type records.
---

`LoggerParameter__mdt` is Nebula Logger's global feature flag surface. Where `LoggerSettings__c` controls per-user runtime behavior, `LoggerParameter__mdt` controls framework-wide subsystems - whether specific behaviors are enabled at all in the org.

## Structure

Each `LoggerParameter__mdt` record represents one named parameter. Key fields:

| Field                     | Purpose                                                                                   |
| ------------------------- | ----------------------------------------------------------------------------------------- |
| `DeveloperName` / `Label` | Identify the parameter.                                                                   |
| `Value__c`                | The parameter's value. Interpreted as a string, boolean, or number depending on the flag. |

Nebula Logger ships default records for every parameter it uses. You can override defaults by editing existing records or deploying new ones with the same `DeveloperName`.

## Common parameters

The specific set changes over time - always check the `LoggerParameter__mdt` records in your org for the current list. Common categories:

- **Feature toggles** - enable or disable specific framework subsystems (e.g. whether async transaction linking is on).
- **Behavior tuning** - adjust internal thresholds or fallbacks.
- **Integration flags** - opt in to newer behaviors while keeping legacy ones available for transitional orgs.

## Editing parameters

- **Metadata deploy**: parameters are CMDT, so they deploy as XML files under `nebula-logger/core/main/configuration/customMetadata/`. Overriding one means deploying a `LoggerParameter.<Name>.md-meta.xml` with the new `Value__c`.
- **Setup UI**: Custom Metadata Types > Logger Parameter > Manage Records lets admins edit values without a deploy.

## `SubscriberControlled` behavior

Where a parameter is marked `SubscriberControlled`, admins in installed orgs can edit the value directly - useful for parameters that need to be tunable without touching source. Everywhere else, editing requires a metadata deploy.

## Where next

- [LoggerSettings\_\_c hierarchy](/configuration/logger-settings/) - per-user runtime settings.
- [`LoggerParameter__mdt` reference](/reference/custom-objects/loggerparameter__mdt/) - full field list.
