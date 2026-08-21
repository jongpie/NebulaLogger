---
title: async-failure-additions plugin reference
description: >-
  Auto-generated reference for the Nebula Logger async-failure-additions
  plugin's public Apex classes and metadata.
---

Auto-generated reference for the **async-failure-additions** plugin.

:::caution[Unlocked package only]
The async-failure-additions plugin's Apex API is exposed as `public` (not `global`) and is only available in the [unlocked package](/NebulaLogger/introduction/package-options/). `public` API is not covered by Nebula Logger's global compatibility guarantees - classes, methods, and fields on this page can change, be renamed, or be removed in a future release without a deprecation window. Pin plugin versions you've tested against and re-verify after upgrades.
:::

For install, configuration, and usage guidance, see the [async-failure-additions plugin narrative](/NebulaLogger/plugins/async-failure-additions/).

---

# async-failure-additions

## Plugins

### [LogBatchApexErrorEventHandler](plugins\LogBatchApexErrorEventHandler.md)

`Schema.BatchApexErrorEvent` handler to log unexpected batch errors for classes that implement `Database.RaisesPlatformEvents` and opt into processing via `LoggerParameter__mdt`

### [LogFinalizer](plugins\LogFinalizer.md)

`System.Finalizer` implementation that can be used by subscribers to log errors

### [LogFlowExecutionErrorEventHandler](plugins\LogFlowExecutionErrorEventHandler.md)

`FlowExecutionErrorEvent` messages are created and fired by the platform when Screen Flows have unhandled errors, and this creates logs for them

## Triggers

### [LogBatchApexErrorEventTrigger](triggers\LogBatchApexErrorEventTrigger.md)
