---
title: LogFlowExecutionErrorEventHandler
description: >-
  Nebula Logger async-failure-additions plugin class (public API):
  LogFlowExecutionErrorEventHandler.
---

# LogFlowExecutionErrorEventHandler Class

`FlowExecutionErrorEvent` messages are created and fired by the platform when Screen Flows have unhandled errors, and this creates logs for them

**Group** Plugins

## Methods

### `logErrors(flowErrorEvents)`

`INVOCABLEMETHOD`

Invocable method called by platform event-triggered flow to add errors to logs

#### Signature

```apex
public static void logErrors(List<Schema.FlowExecutionErrorEvent> flowErrorEvents)
```

#### Parameters

| Name            | Type                                 | Description                                                                           |
| --------------- | ------------------------------------ | ------------------------------------------------------------------------------------- |
| flowErrorEvents | List<Schema.FlowExecutionErrorEvent> | The `List<Schema.FlowExecutionErrorEvent>` associated with the unhandled exception(s) |

#### Return Type

**void**
