---
title: Scenarios
description: Grouping transactions under a business process name for filtering, reporting, and per-scenario retention.
---

A **scenario** names the business process a transaction belongs to. It applies to the whole transaction - every entry inherits it - and it's the mechanism the framework uses for per-process retention and filtering.

## Setting a scenario

Call once per transaction, at the start:

```apex
Logger.setScenario('Order Fulfillment');

Logger.info('Started');
// work
Logger.info('Completed');

Logger.saveLog();
```

Every `LogEntry__c` in the resulting `Log__c` has `Scenario__c = 'Order Fulfillment'`.

In LWC:

```js
this.logger.setScenario('Order Fulfillment');
this.logger.info('Started');
await this.logger.saveLog();
```

In Flow, set the `Scenario` input on any `Add Log Entry*` invocable action - the framework applies it to the whole transaction.

In OmniStudio, pass `scenario` as an input to any `newEntry` Remote Action call.

## What scenarios are for

- **Investigation filtering**: the Logger Console lets you filter logs by scenario, so a support engineer can pull up "all logs from Order Fulfillment in the last hour" without walking user or record filters.
- **Reporting**: scenario names populate `LoggerScenario__c` records, which are reportable.
- **Per-scenario retention**: `LoggerScenarioRule__mdt` overrides retention days for logs whose scenario matches. See [Retention & Purging](/retention/retention-dates/).
- **Per-scenario logging level**: same CMDT can override the effective logging level for a scenario, so you can turn up verbosity for one process without lifting the org-wide level.

## Naming conventions

Scenario names are free-text - there's no enforced taxonomy. Team conventions worth adopting:

- Use a business-facing name, not a technical one. `Order Fulfillment` is better than `OrderProcessor::run`.
- Keep names stable. If a scenario name changes, historical logs still reference the old name.
- Aim for coarse - one scenario per business process, not one per method. Use tags for finer slicing.

## Ending a scenario

`Logger.endScenario()` clears the current scenario. Rarely needed - most transactions end when `saveLog()` fires, at which point the scenario stops mattering.

Use it only when a single transaction spans multiple business processes (uncommon):

```apex
Logger.setScenario('Order Fulfillment');
Logger.info('Fulfilled order');

Logger.endScenario();
Logger.setScenario('Inventory Sync');
Logger.info('Synced inventory');

Logger.saveLog();
```

## Where next

- [Tags](/logging-guide/tags/) - the fine-grained counterpart to scenarios.
- [Retention & Purging](/retention/retention-dates/) - per-scenario retention overrides.
- [Configuration - Logging levels](/configuration/logging-levels/) - per-scenario logging level overrides.
