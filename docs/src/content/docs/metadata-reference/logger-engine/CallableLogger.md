---
title: CallableLogger
description: 'Nebula Logger class reference: CallableLogger.'
---

# CallableLogger Class

`SUPPRESSWARNINGS`

A class that implements the standard interface `System.Callable` . This provides 2 benefits:

1. A loosely-coupled way to optionally integrate with Nebula Logger (useful for ISVs/package developers).
2. The ability to log in OmniStudio&#x27;s OmniScripts &amp; Integration Procedures.

**Group** Logger Engine

**See** [Logger](Logger.md)

**See** [LogEntryEventBuilder](LogEntryEventBuilder.md)

**Implements**

System.Callable

## Methods

### `call(action, arguments)`

The one method required by the interface `System.Callable` description. It provides a `String` -based way to dynamically call Nebula Logger&#x27;s code.

#### Signature

```apex
global Object call(String action, Map<String,Object> arguments)
```

#### Parameters

| Name      | Type               | Description                                                                                                      |
| --------- | ------------------ | ---------------------------------------------------------------------------------------------------------------- |
| action    | String             | The `String` name of the `Logger` method to call. The supported actions are                                      |
| arguments | Map<String,Object> | An instance of `Map<String, Object>` containing any named arguments expected by the `Logger` method being called |

#### Return Type

**Object**

The value returned by the `Logger` method called as an `Object` instance, or `null` if the method being called does not have a return value
