---
title: LogBatchApexErrorEventHandler
description: >-
  Nebula Logger async-failure-additions plugin class (public API):
  LogBatchApexErrorEventHandler.
---

# LogBatchApexErrorEventHandler Class

`Schema.BatchApexErrorEvent` handler to log unexpected batch errors for classes that implement `Database.RaisesPlatformEvents` and opt into processing via `LoggerParameter__mdt`

**Group** Plugins

**See** LoggerSObjectHandler

**Inheritance**

LoggerSObjectHandler

## Fields

### `BATCH_ERROR_LOGGER`

#### Signature

```apex
public static final BATCH_ERROR_LOGGER
```

#### Type

String

---

### `LOG_MESSAGE`

#### Signature

```apex
public static final LOG_MESSAGE
```

#### Type

String

## Constructors

### `LogBatchApexErrorEventHandler()`

Opts into the default constructor

#### Signature

```apex
public LogBatchApexErrorEventHandler()
```

## Methods

### `getSObjectType()`

#### Signature

```apex
public override Schema.SObjectType getSObjectType()
```

#### Return Type

**Schema.SObjectType**
