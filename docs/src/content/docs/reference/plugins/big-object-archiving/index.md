---
title: big-object-archiving plugin reference
description: >-
  Auto-generated reference for the Nebula Logger big-object-archiving plugin's
  public Apex classes and metadata.
---

Auto-generated reference for the **big-object-archiving** plugin.

:::caution[Unlocked package only]
The big-object-archiving plugin's Apex API is exposed as `public` (not `global`) and is only available in the [unlocked package](/NebulaLogger/introduction/package-options/). `public` API is not covered by Nebula Logger's global compatibility guarantees - classes, methods, and fields on this page can change, be renamed, or be removed in a future release without a deprecation window. Pin plugin versions you've tested against and re-verify after upgrades.
:::

For install, configuration, and usage guidance, see the [big-object-archiving plugin narrative](/NebulaLogger/plugins/big-object-archiving/).

---

# big-object-archiving

## Custom Objects

### [LogEntryArchive\_\_b](custom-objects\LogEntryArchive__b.md)

Big Object representation of Logger data, used as an alternative to the platform event LogEntryEvent**e, as well as a way to archive Logger data stored in Log**c, LogEntry**, and LogEntryTag**c

## Plugins

### [LogEntryArchiveBuilder](plugins\LogEntryArchiveBuilder.md)

Builder class to create an instance of `LogEntryArchive__b` , used by the Big Object plugin

### [LogEntryArchiveController](plugins\LogEntryArchiveController.md)

Controller class used by the LWC `logEntryArchives` to display `LogEntryArchive__b` data

### [LogEntryArchivePlugin](plugins\LogEntryArchivePlugin.md)

Optional plugin that provides a Big Object, `LogEntryArchive__b` , as an alternative option
to the platform event `LogEntryEvent__e`
