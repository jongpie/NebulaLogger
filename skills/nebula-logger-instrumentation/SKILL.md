---
name: nebula-logger-instrumentation
description: Use this skill when the user wants to add or update Nebula Logger instrumentation in Apex, LWC, Aura, Flow, or OmniStudio. Covers logging APIs, save patterns, record association, scenarios, tags, async transaction linking, and save method selection.
---

# Instrumenting Code with Nebula Logger

## Supported API Surface

Nebula Logger's supported API surface is everything marked `global` in Apex, and everything exported from the `c/logger` LWC module. The managed package (namespace `Nebula`) exposes only the `global` surface; the unlocked package technically exposes `public` classes and methods too, since there's no namespace boundary blocking access.

**Do not rely on `public` Apex classes or methods from your own code.** They are internal to Nebula Logger and can change, be renamed, or be removed in any release without a deprecation window. `LoggerDataStore`, `LoggerConfigurationSelector`, `LogEntryHandler`, `LoggerPlugin` (the class itself, not the `LoggerPlugin__mdt` records), and everything else without a `global` modifier is subject to change without notice.

If a capability you need isn't available through the `global` surface, file an issue at https://github.com/jongpie/NebulaLogger/issues rather than reaching into `public` methods. This skill and its companions only reference `global` APIs.

## The Core Model

Every Nebula Logger runtime context follows the same pattern:

1. Add one or more log entries at a level (`ERROR`, `WARN`, `INFO`, `DEBUG`, `FINE`, `FINER`, `FINEST`).
2. Optionally enrich each entry with a record, exception details, or tags.
3. Persist the buffered entries by calling `saveLog()` once at the end of the transaction.

The rest of this skill shows what that looks like in each runtime context.

## Cross-Cutting Concepts

### Logging levels

Every context supports these seven levels: `ERROR`, `WARN`, `INFO`, `DEBUG`, `FINE`, `FINER`, `FINEST`. Which levels actually persist depends on the effective `LoggerSettings__c.LoggingLevel__c` for the user - see [nebula-logger-install](../nebula-logger-install/SKILL.md) for the hierarchy setup and [nebula-logger-best-practices](../nebula-logger-best-practices/SKILL.md) for level selection guidance.

### Scenarios and tags

Scenarios coarsely group a whole transaction under a business process; tags finely slice individual entries. Both are supported across every runtime.

- Set the transaction scenario once with `setScenario('Order Fulfillment')`.
- Attach tags per-entry: chain `.addTag('inventory')` off the level-specific call.

### Record association

Prefer structured record association (`setRecord(...)`) over embedding IDs in message strings. Nebula Logger stores a JSON snapshot of the record so the log page can render the record's state at the time of the entry.

### Async transaction linking

Async work (batch, queueable, scheduled) runs in a new Apex transaction, which by default produces an unrelated `Log__c`. To link a child transaction back to its parent:

- Capture the parent's transaction ID with `Logger.getTransactionId()`.
- Pass it to the child, then call `Logger.setParentLogTransactionId(parentId)` at the start of the child transaction.

This creates a `ParentLog__c` link between the two `Log__c` records so investigation can walk the chain.

## Apex

Use level-specific methods to add entries, then persist once with `Logger.saveLog()`.

```apex
public with sharing class InvoiceService {
  public static void processInvoice(Id invoiceId) {
    try {
      Logger.info('Starting invoice processing for ' + invoiceId);
      Logger.debug('Loading invoice and related records');

      // Business logic here

      Logger.info('Invoice processing completed successfully');
    } catch (System.Exception ex) {
      Logger.error('Invoice processing failed', ex);
      throw ex;
    } finally {
      Logger.saveLog();
    }
  }
}
```

### Exception logging

`Logger.exception(...)` writes an `ERROR` log entry with the full exception context, saves the log, and rethrows the exception in one call. Do not add a separate `Logger.saveLog()` or `throw ex;` after it - both are redundant (and the `throw` is unreachable, since `Logger.exception(...)` already threw).

```apex
try {
  update accountsToUpdate;
} catch (System.DmlException ex) {
  Logger.exception('Failed to update accounts', ex);
}
```

If you want to log the exception but decide separately whether to rethrow it, use `Logger.error(message, ex)` with an explicit `Logger.saveLog()` and `throw`:

```apex
try {
  update accountsToUpdate;
} catch (System.DmlException ex) {
  Logger.error('Failed to update accounts', ex);
  Logger.saveLog();
  throw ex;
}
```

### Attaching records

```apex
Schema.Account acct = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];

Logger
  .warn('Credit check returned warnings')
  .setRecord(acct)
  .addTag('credit-check')
  .addTag('customer-onboarding');

Logger.saveLog();
```

`setRecord(...)` is defined on `LogEntryEventBuilder` (returned by `Logger.info(...)` / `Logger.warn(...)` / etc.), not on `Logger` itself. Global overloads include `setRecord(SObject)`, `setRecord(Id)`, `setRecord(List<SObject>)`, `setRecord(Map<Id, SObject>)`, `setRecord(System.Iterable<Id>)`, and `setRecordId(Id)`. Chain them off the level-specific call as shown above.

### Async parent/child linking

```apex
public with sharing class ParentQueueable implements System.Queueable {
  public void execute(System.QueueableContext context) {
    String parentTransactionId = Logger.getTransactionId();
    Logger.info('Parent job started');
    Logger.saveLog();

    System.enqueueJob(new ChildQueueable(parentTransactionId));
  }
}

public with sharing class ChildQueueable implements System.Queueable {
  private final String parentLogTransactionId;

  public ChildQueueable(String parentLogTransactionId) {
    this.parentLogTransactionId = parentLogTransactionId;
  }

  public void execute(System.QueueableContext context) {
    Logger.setParentLogTransactionId(this.parentLogTransactionId);
    Logger.info('Child job linked to parent log transaction');
    Logger.saveLog();
  }
}
```

### Optional dependency via `CallableLogger`

Code that wants to log to Nebula Logger _when it's installed_ but not hard-depend on it - for example, ISV packages that want to emit rich telemetry in customer orgs that happen to have Nebula Logger, without requiring every customer to install it - should call `CallableLogger` dynamically via `System.Callable` instead of referencing the `Logger` class directly.

`CallableLogger` is `global` in both the unlocked and managed packages, and it exposes every logging operation as a string action with a `Map<String, Object>` input. Because the caller never compile-time-references `Logger`, the calling package compiles and installs cleanly whether Nebula Logger is present or not.

```apex
public with sharing class OptionalLogger {
  // An example of how to dynamically check first for the managed package ('Nebula' namespace), then the unlocked package (no namespace)
  private static final System.Type CALLABLE_LOGGER_TYPE = System.Type.forName('Nebula', 'CallableLogger') ?? System.Type.forName('CallableLogger');

  public static void info(String message) {
    logEntry(System.LoggingLevel.INFO, message);
  }

  public static void error(String message, System.Exception apexException) {
    Map<String, Object> input = new Map<String, Object>{
      'loggingLevel' => System.LoggingLevel.ERROR.name(),
      'message' => message,
      'exception' => apexException,
      'saveLog' => true
    };
    invoke('newEntry', input);
  }

  private static void logEntry(System.LoggingLevel level, String message) {
    invoke('newEntry', new Map<String, Object>{ 'loggingLevel' => level.name(), 'message' => message, 'saveLog' => true });
  }

  private static void invoke(String action, Map<String, Object> input) {
    if (CALLABLE_LOGGER_TYPE == null) {
      return;
    }
    System.Callable logger = (System.Callable) CALLABLE_LOGGER_TYPE.newInstance();
    logger.call(action, input);
  }
}
```

Callers of `OptionalLogger.info(...)` / `OptionalLogger.error(...)` get logging in orgs that have Nebula Logger installed and a no-op in orgs that don't - no runtime error, no compile-time dependency, no post-install step for the customer.

#### Supported actions on `CallableLogger`

Every action accepts a `Map<String, Object>` and returns a `Map<String, Object>` output (with keys `isSuccess`, `transactionId`, `parentLogTransactionId`, `requestId`, and error details on failure).

| Action                                                    | Purpose                                                                                                              |
| --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `newEntry`                                                | Add a log entry. Supports every enrichment key in the table below.                                                   |
| `saveLog`                                                 | Persist buffered entries. Optionally accepts `saveMethodName`.                                                       |
| `getTransactionId`                                        | Return the current transaction ID (for async parent/child linking).                                                  |
| `getParentLogTransactionId` / `setParentLogTransactionId` | Read / set the parent transaction ID.                                                                                |
| `getScenario` / `setScenario` / `endScenario`             | Read / set / end the transaction's scenario.                                                                         |
| `tryCatch`                                                | Shorthand for `newEntry` with `loggingLevel=ERROR` and a serialized-input message; useful in generic `catch` blocks. |

#### Supported input keys for `newEntry`

The same input keys are used by both the ISV pattern above and OmniStudio's Remote Action steps.

| Key                                                | Purpose                                                                                       |
| -------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `loggingLevel`                                     | Level name (`INFO`, `ERROR`, `WARN`, `DEBUG`, `FINE`, `FINER`, `FINEST`).                     |
| `message`                                          | Entry message.                                                                                |
| `saveLog`                                          | Set to `true` to persist immediately after adding the entry.                                  |
| `saveMethodName`                                   | Override the save method for this call (`EVENT_BUS`, `QUEUEABLE`, `REST`, `SYNCHRONOUS_DML`). |
| `tags`                                             | `List<String>` of tag names.                                                                  |
| `exception`                                        | `System.Exception` instance to attach.                                                        |
| `recordId` / `record` / `recordList` / `recordMap` | Record association, same shape as the Apex `setRecord(...)` overloads.                        |
| `scenario`                                         | Scenario for the transaction.                                                                 |
| `parentLogTransactionId`                           | Parent transaction ID for async linking.                                                      |

## LWC

Import `getLogger` from the `c/logger` module and call it once per component instance.

```js
import { LightningElement } from 'lwc';
import { getLogger } from 'c/logger';

export default class PaymentPanel extends LightningElement {
  logger = getLogger();

  connectedCallback() {
    this.logger.setScenario('Payment UI');
    this.logger.info('Payment panel initialized');
    this.logger.saveLog();
  }

  async handleSave() {
    try {
      this.logger.debug('Submitting payment request');
      // async work
      this.logger.info('Payment submitted');
    } catch (error) {
      this.logger.error('Payment submit failed').setExceptionDetails(error);
    } finally {
      await this.logger.saveLog();
    }
  }
}
```

- `getLogger()` returns a scoped logger instance. Call it once and reuse.
- `saveLog()` is async - `await` it when the surrounding code needs the save to complete before returning.
- Level methods return a builder that supports `.setRecord(...)`, `.setExceptionDetails(...)`, `.setScenario(...)`, and `.addTag(...)`.

## Aura

Embed the `<c:logger>` component in markup and access it via `component.find('logger')`.

```html
<aura:component>
  <c:logger aura:id="logger" />
</aura:component>
```

```javascript
({
  handleRender: function (component) {
    const logger = component.find('logger');
    logger.info('Aura component initialized');
    logger.saveLog();
  },

  logButtonClick: function (component, event) {
    const logger = component.find('logger');
    logger.info('Save button clicked').addTag('user-action');
    logger.saveLog();
  }
});
```

Access the logger from `handleRender` or user-driven handlers rather than `doInit`. The embedded `<c:logger>` is an LWC-under-Aura, and LWC child methods are not yet available when `doInit` fires. If instrumentation must run at initialization time, wrap it in `setTimeout(..., 0)` so it runs after the render cycle.

## Flow

Nebula Logger ships three invocable actions (all in the `Logging` category) plus a save action:

- `Add Log Entry` - Add a plain log entry with a message and logging level.
- `Add Log Entry for an SObject Record` - Add an entry linked to a single record.
- `Add Log Entry for an SObject Record Collection` - Add an entry linked to a collection of records.
- `Save Log` - Persist the buffered entries. End every flow path that added entries with this action.

Flow variable references pass through the invocable inputs using standard merge syntax (`{!recordId}`, `{!Account.Name}`, etc.). Set the scenario on any `Add Log Entry*` action to group the whole flow's entries under one business process.

## OmniStudio

OmniStudio's OmniScripts and Integration Procedures log via the same `CallableLogger` class described under the Apex section's "Optional dependency" subsection. Instead of writing Apex, configure a **Remote Action** step in the OmniScript / IP:

- `Remote Class`: `Nebula.CallableLogger` if the managed package is installed, otherwise `CallableLogger`.
- `Remote Method`: `newEntry` to add an entry (optionally saving in the same call), or `saveLog` to persist pending entries. See the "Supported actions" and "Supported input keys" tables in the Apex section above for the full menu.
- `Additional Input`: pass the input keys declaratively. Anything in the input map beyond the known keys is appended to the entry's message as an "OmniStudio Input" block, so process-specific context flows into the log without extra plumbing.

`CallableLogger` automatically stamps `OriginType__c = 'OmniStudio'` and captures the `omniProcessId` from OmniStudio's default input so console filtering shows OmniStudio-sourced entries distinctly.

## Save Method Selection Guide

`Logger.SaveMethod` values are `EVENT_BUS`, `QUEUEABLE`, `REST`, and `SYNCHRONOUS_DML`.

| Save Method           | Use when                                                      | Trade-off                                            |
| --------------------- | ------------------------------------------------------------- | ---------------------------------------------------- |
| `EVENT_BUS` (default) | General-purpose app logging                                   | Depends on platform event capacity                   |
| `QUEUEABLE`           | You want to defer work and reduce synchronous CPU pressure    | Adds async dependency and queueable execution timing |
| `REST`                | You need to avoid mixed-DML constraints in current context    | Requires callout path and valid session context      |
| `SYNCHRONOUS_DML`     | You need immediate persistence and can tolerate rollback risk | Log inserts are rolled back if transaction fails     |

Override the default globally via `LoggerSettings__c.DefaultSaveMethod__c`, or per-transaction via `Logger.saveLog(Logger.SaveMethod.QUEUEABLE)`.

## Related Skills

- [nebula-logger-testing-your-code](../nebula-logger-testing-your-code/SKILL.md) - Testing code that calls the APIs above.
- [nebula-logger-console](../nebula-logger-console/SKILL.md) - Browsing the log records these APIs produce.
- [nebula-logger-best-practices](../nebula-logger-best-practices/SKILL.md) - Team-wide instrumentation standards.
