---
layout: default
---

## CallableLogger class

A class that implements the standard interface `System.Callable` to provide a loosely-coupled way to interact with Nebula Logger. This can be used for OmniStudio, as well as for optionally &amp; dynamically integrating other packages/code with Nebula Logger&apos;s code (when available).

### Related

[Logger](Logger)

[LogEntryEventBuilder](LogEntryEventBuilder)

---

### Methods

#### `call(String action, Map<String, Object> arguments)` → `Object`

The one method required by the interface `System.Callable` description. It provides a `String`-based way to dynamically call Nebula Logger&apos;s code.

##### Parameters

| Param       | Description                                                                                                            |
| ----------- | ---------------------------------------------------------------------------------------------------------------------- |
| `action`    | The `String` name of the `Logger` method to call. The supported actions are                                            |
| `arguments` | An instance of `Map&lt;String, Object&gt;` containing any named arguments expected by the `Logger` method being called |

##### Return

**Type**

Object

**Description**

The value returned by the `Logger` method called as an `Object` instance, or `null` if the method being called does not have a return value

---
