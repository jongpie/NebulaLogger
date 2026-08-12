---
title: Apex
description: Logging from Apex classes, triggers, batch, queueable, and scheduled jobs.
---

Use level-specific methods on the `Logger` class to add entries, then persist once with `Logger.saveLog()`. Prefix identifiers with `Nebula.` if you installed the managed package.

## Basic usage

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

Guidelines:

- Call `Logger.saveLog()` exactly once per transaction, in a `finally` block for transactional code paths.
- Reserve `ERROR`, `WARN`, `INFO` for operationally significant information.
- Use `DEBUG` / `FINE` / `FINER` / `FINEST` for high-volume diagnostic detail - `LoggerSettings__c.LoggingLevel__c` filters them out until you need them.

## Level methods

Each of the seven levels has a corresponding method on `Logger`. Each method returns a `LogEntryEventBuilder` so you can chain enrichment calls.

```apex
Logger.error('Critical failure');
Logger.warn('Recoverable issue detected');
Logger.info('Business milestone reached');
Logger.debug('Debug detail');
Logger.fine('Verbose detail');
Logger.finer('More verbose detail');
Logger.finest('Most verbose detail');
```

Each level method has overloads for common enrichment patterns:

- `Logger.error(String message, SObject record)`
- `Logger.error(String message, Id recordId)`
- `Logger.error(String message, System.Exception ex)`
- `Logger.error(String message, Database.SaveResult saveResult)`

See the [`Logger` reference](/reference/logger-engine/logger/) for the full list.

## Exception logging

`Logger.exception(...)` writes an `ERROR` entry with full exception context, saves the log, and rethrows in one call.

```apex
try {
  update accountsToUpdate;
} catch (System.DmlException ex) {
  Logger.exception('Failed to update accounts', ex);
}
```

Do not add a separate `Logger.saveLog()` or `throw ex;` after `Logger.exception(...)` - both are redundant, and the `throw` is unreachable.

If you want to log without rethrowing, use `Logger.error(message, ex)` with an explicit `saveLog()`:

```apex
try {
  update accountsToUpdate;
} catch (System.DmlException ex) {
  Logger.error('Failed to update accounts', ex);
  Logger.saveLog();
  // continue processing
}
```

## Attaching records

`.setRecord(...)` is defined on `LogEntryEventBuilder` (the return value of the level methods), not on `Logger` itself. Chain it off the level call:

```apex
Schema.Account account = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];

Logger
  .warn('Credit check returned warnings')
  .setRecord(account)
  .addTag('credit-check')
  .addTag('customer-onboarding');

Logger.saveLog();
```

Global overloads:

- `.setRecord(SObject)` - single record, captured as snapshot.
- `.setRecord(Id)` - just the record ID.
- `.setRecord(List<SObject>)` - collection of records.
- `.setRecord(Map<Id, SObject>)` - map of records by ID.
- `.setRecord(System.Iterable<Id>)` - iterable of IDs.
- `.setRecordId(Id)` - alias for `.setRecord(Id)`.

## The fluent interface

Every level method returns a `LogEntryEventBuilder`. Three equivalent ways to log a message with a record:

```apex
User currentUser = [SELECT Id, Name, Username FROM User WHERE Id = :UserInfo.getUserId()];

// Overload
Logger.debug('User loaded', currentUser);

// Builder variable
LogEntryEventBuilder builder = Logger.debug('User loaded');
builder.setRecord(currentUser);

// Chained
Logger.debug('User loaded').setRecord(currentUser);

Logger.saveLog();
```

Chaining is the most common pattern in the codebase because it keeps the log call on one visual unit.

## Dynamic message formatting with LogMessage

`LogMessage` builds formatted strings on demand using `String.format()`. Two benefits:

1. If the level is filtered out by `LoggerSettings__c.LoggingLevel__c`, the format call is skipped entirely - no CPU spent building a string that gets thrown away.
2. Multi-parameter format strings are cleaner than manual concatenation.

```apex
LogMessage logMessage = new LogMessage('Processed {0} records with {1} errors', totalRecords, errorCount);
Logger.fine(logMessage);
```

There are constructors for zero through five arguments, plus a `List<Object>` variant for more. See the [`LogMessage` reference](/reference/logger-engine/logmessage/).

## Transaction controls

Occasionally you need finer control over the buffer than `saveLog()` gives you.

- `Logger.suspendSaving()` - `saveLog()` still runs, but records are not persisted. Useful for reducing DML in bulk contexts.
- `Logger.resumeSaving()` - re-enables persistence after `suspendSaving()`.
- `Logger.flushBuffer()` - discards buffered entries without persisting.
- `Logger.setSaveMethod(SaveMethod)` - overrides the default for the rest of the transaction.
- `Logger.saveLog(SaveMethod)` - overrides the save method for just this call.

See [Concepts - Save methods](/logging-guide/concepts/#save-methods) for the trade-offs of each method.

## Async parent/child linking

Async work runs in a new Apex transaction. To link a child transaction back to its parent, capture the parent's transaction ID and set it on the child.

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

The child `Log__c` records populate `ParentLog__c` pointing at the parent. The console walks the chain from either end.

Batchable jobs use the same pattern:

```apex
public with sharing class SomeBatch implements Database.Batchable<SObject>, Database.Stateful {
  private String originalTransactionId;

  public Database.QueryLocator start(Database.BatchableContext context) {
    this.originalTransactionId = Logger.getTransactionId();
    Logger.info('Starting batch');
    Logger.saveLog();
    return Database.getQueryLocator([SELECT Id FROM Account]);
  }

  public void execute(Database.BatchableContext context, List<Account> scope) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Processing scope of ' + scope.size() + ' accounts');
    Logger.saveLog();
  }

  public void finish(Database.BatchableContext context) {
    Logger.setParentLogTransactionId(this.originalTransactionId);
    Logger.info('Batch complete');
    Logger.saveLog();
  }
}
```

`Database.Stateful` preserves `originalTransactionId` across batch chunks. Each chunk still runs in its own transaction, so `setParentLogTransactionId(...)` must be called at the top of each `execute` invocation.

## Where next

- [Testing your instrumentation](/logging-guide/testing/) - asserting on buffered and persisted entries in tests.
- [Scenarios](/logging-guide/scenarios/) - grouping transactions by business process.
- [Tags](/logging-guide/tags/) - labeling individual entries.
- [`Logger` reference](/reference/logger-engine/logger/) - the full API surface.
