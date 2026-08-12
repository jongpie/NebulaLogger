---
title: LogFinalizer
description: 'Nebula Logger async-failure-additions plugin class (public API): LogFinalizer.'
---

# LogFinalizer Class

`virtual`

`System.Finalizer` implementation that can be used by subscribers to log errors

**Group** Plugins

**Implements**

System.Finalizer

## Methods

### `execute(finalizerContext)`

Is called by any `System.Queueable` where the finalizer is attached after the System.Queueable&#x27;s `execute` method finishes

#### Signature

```apex
public void execute(System.FinalizerContext finalizerContext)
```

#### Parameters

| Name             | Type                    | Description                                                 |
| ---------------- | ----------------------- | ----------------------------------------------------------- |
| finalizerContext | System.FinalizerContext | The `System.FinalizerContext` associated with the finalizer |

#### Return Type

**void**
