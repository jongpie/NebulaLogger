---
title: Optional dependency via Callable
description: Use CallableLogger to log to Nebula Logger when it's installed, without hard-requiring it.
---

If you're building a Salesforce package and want to emit rich telemetry in customer orgs _when Nebula Logger is installed_, without forcing customers to install it, use `CallableLogger`. Your package compiles and installs cleanly whether Nebula Logger is present or not.

## Why this pattern

Hard-depending on Nebula Logger means:

- Every customer must install Nebula Logger before they can install your package.
- Your package's install failure surface expands.
- Customers who don't want logging can't opt out cleanly.

The optional-dependency pattern lets:

- Customers with Nebula Logger installed get rich, structured logs.
- Customers without get a no-op - no runtime error, no compile-time dependency, no post-install step.

## How it works

`CallableLogger` is a `global` class in both the unlocked and managed packages. It implements `System.Callable`:

```apex
Object call(String action, Map<String, Object> args)
```

Your package resolves the class at runtime via `System.Type.forName(...)` - not via a compile-time reference. If neither package is installed, the type resolution returns null, and your code no-ops.

## Minimal wrapper

```apex
public with sharing class OptionalLogger {
  private static final System.Type CALLABLE_LOGGER_TYPE = System.Type.forName('Nebula', 'CallableLogger') ?? System.Type.forName('CallableLogger');

  public static void info(String message) {
    logEntry(System.LoggingLevel.INFO, message);
  }

  public static void error(String message, System.Exception apexException) {
    invoke(
      'newEntry',
      new Map<String, Object>{ 'loggingLevel' => System.LoggingLevel.ERROR.name(), 'message' => message, 'exception' => apexException, 'saveLog' => true }
    );
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

Callers of `OptionalLogger.info(...)` / `OptionalLogger.error(...)` get logging when Nebula Logger is installed, no-ops otherwise.

## Supported actions

Every action accepts a `Map<String, Object>` input and returns a `Map<String, Object>` output (with `isSuccess`, `transactionId`, `parentLogTransactionId`, `requestId`, and error details on failure).

| Action                                                    | Purpose                                                                                                              |
| --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `newEntry`                                                | Add a log entry. Supports every enrichment key in the table below.                                                   |
| `saveLog`                                                 | Persist buffered entries. Optionally accepts `saveMethodName`.                                                       |
| `getTransactionId`                                        | Return the current transaction ID (for async parent/child linking).                                                  |
| `getParentLogTransactionId` / `setParentLogTransactionId` | Read / set the parent transaction ID.                                                                                |
| `getScenario` / `setScenario` / `endScenario`             | Read / set / end the transaction's scenario.                                                                         |
| `tryCatch`                                                | Shorthand for `newEntry` with `loggingLevel=ERROR` and a serialized-input message; useful in generic `catch` blocks. |

## Supported input keys for `newEntry`

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

## Version requirement

`CallableLogger` requires Nebula Logger `v4.14.10` or newer. Customers on older versions won't have the class - the type resolution returns null and the wrapper no-ops, which is the same behavior as not having Nebula Logger installed at all.

## Where next

- [Hard dependency](/for-package-developers/hard-dependency/) - if you want to require Nebula Logger.
- [No dependency (bundling)](/for-package-developers/no-dependency/) - if you want to ship a copy in your own package.
- [`CallableLogger` reference](/reference/logger-engine/callablelogger/) - full API.
