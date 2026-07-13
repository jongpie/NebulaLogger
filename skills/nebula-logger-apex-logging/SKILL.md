---
name: nebula-logger-apex-logging
description: Use this skill when the user wants to implement or update Nebula Logger usage in Apex, LWC, Aura, Flow, or OmniStudio. Covers logging APIs, save patterns, record association, scenarios, tags, async transaction linking, and save method selection.
---

# Writing Logging Code with Nebula Logger

## Core Apex Pattern

Use level-specific methods to add entries, then persist once with `Logger.saveLog()`.

```apex
public with sharing class InvoiceService {
  public static void processInvoice(Id invoiceId) {
    try {
      Logger.info('Starting invoice processing for ' + invoiceId);
      Logger.debug('Loading invoice and related records');

      // Business logic here

      Logger.info('Invoice processing completed successfully');
    } catch (Exception ex) {
      Logger.error('Invoice processing failed', ex);
      throw ex;
    } finally {
      Logger.saveLog();
    }
  }
}
```

Supported level methods include `error()`, `warn()`, `info()`, `debug()`, `fine()`, `finer()`, and `finest()`.

## Exception Logging with Stack Trace

Use exception overloads to capture the full exception context.

```apex
try {
  update accountsToUpdate;
} catch (DmlException ex) {
  Logger.error('Failed to update accounts', ex);
  Logger.saveLog();
  throw ex;
}
```

## Attach Records Instead of String IDs

Prefer structured record association over embedding IDs in free text.

```apex
Account acct = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];

Logger
  .warn('Credit check returned warnings')
  .setRecord(acct)
  .addTag('credit-check')
  .addTag('customer-onboarding');

Logger.saveLog();
```

You can also use list/map overloads such as `setRecord(List<SObject>)` and `setRecord(Map<Id, SObject>)`.

## Tags and Scenarios

Use scenarios for coarse process grouping and tags for fine-grained slicing.

```apex
Logger.setScenario('Order Fulfillment');

Logger
  .info('Picking inventory started')
  .addTag('inventory')
  .addTag('fulfillment');

Logger.saveLog();
```

## Relate Async Child Transactions

Batch/queueable/scheduled executions run in separate transactions. Link children to a parent transaction ID.

```apex
public with sharing class ParentQueueable implements Queueable {
  public void execute(QueueableContext context) {
    String rootTxId = Logger.getTransactionId();
    Logger.info('Parent job started');
    Logger.saveLog();

    System.enqueueJob(new ChildQueueable(rootTxId));
  }
}

public with sharing class ChildQueueable implements Queueable {
  private final String parentLogTransactionId;

  public ChildQueueable(String parentLogTransactionId) {
    this.parentLogTransactionId = parentLogTransactionId;
  }

  public void execute(QueueableContext context) {
    Logger.setParentLogTransactionId(this.parentLogTransactionId);
    Logger.info('Child job linked to parent log transaction');
    Logger.saveLog();
  }
}
```

## LWC Pattern

Use the `logger` module and call `getLogger()` once per component instance.

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

## Aura Pattern

Add the logger component in markup and call it via `component.find('logger')`.

```html
<aura:component>
  <c:logger aura:id="logger" />
</aura:component>
```

```javascript
({
  doInit: function (component) {
    const logger = component.find('logger');
    logger.info('Aura component initialized');
    logger.saveLog();
  }
});
```

## Flow Pattern

Use Nebula Logger invocable actions in this sequence:

1. Add one or more log entries using `Add Log Entry`, `Add Log Entry for an SObject Record`, or `Add Log Entry for an SObject Record Collection`.
2. End the flow path with `Save Log`.

Flow variable references can be passed in messages and inputs using standard merge syntax such as `{!recordId}`.

## OmniStudio Pattern

Use `CallableLogger` as a Remote Action and provide action/input maps.

```apex
Type loggerType = Type.forName('Nebula', 'CallableLogger') ?? Type.forName('CallableLogger');
if (loggerType != null) {
  System.Callable logger = (System.Callable) loggerType.newInstance();

  Map<String, Object> args = new Map<String, Object>{
    'loggingLevel' => 'INFO',
    'message' => 'OmniStudio remote action completed',
    'saveLog' => true,
    'tags' => new List<String>{'omnistudio', 'remote-action'}
  };

  logger.call('newEntry', args);
}
```

## Save Method Selection Guide

`Logger.SaveMethod` values in this repo are `EVENT_BUS`, `QUEUEABLE`, `REST`, and `SYNCHRONOUS_DML`.

| Save Method | Use when | Trade-off |
| --- | --- | --- |
| `EVENT_BUS` (default) | General-purpose app logging | Depends on platform event capacity |
| `QUEUEABLE` | You want to defer work and reduce synchronous CPU pressure | Adds async dependency and queueable execution timing |
| `REST` | You need to avoid mixed-DML constraints in current context | Requires callout path and valid session context |
| `SYNCHRONOUS_DML` | You need immediate persistence and can tolerate rollback risk | Log inserts are rolled back if transaction fails |
