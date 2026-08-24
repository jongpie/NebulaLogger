---
title: SlackLoggerPlugin
description: 'Nebula Logger slack plugin class (public API): SlackLoggerPlugin.'
---

# SlackLoggerPlugin Class

`SUPPRESSWARNINGS`

Optional plugin that integrates with Slack to send alerts for important logs

**Group** Plugins

**Implements**

LoggerPlugin.Triggerable,
System.Queueable,
Database.AllowsCallouts

## Constructors

### `SlackLoggerPlugin()`

`SUPPRESSWARNINGS`

Default constructor

#### Signature

```apex
public SlackLoggerPlugin()
```

## Methods

### `execute(configuration, context)`

Handles the integration with Slack. This method is automatically called by Nebula Logger&#x27;s plugin framework.

#### Signature

```apex
public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext context)
```

#### Parameters

| Name          | Type                     | Description                                                                 |
| ------------- | ------------------------ | --------------------------------------------------------------------------- |
| configuration | LoggerPlugin\_\_mdt      | The instance of `LoggerPlugin__mdt` configured for this specific plugin     |
| context       | LoggerTriggerableContext | The instance of `LoggerTriggerableContext` , provided by the logging system |

#### Return Type

**void**

---

### `execute(queueableContext)`

Handles the queuable execute logic. Required by the System.Queueable interface.

#### Signature

```apex
public void execute(System.QueueableContext queueableContext)
```

#### Parameters

| Name             | Type                    | Description                               |
| ---------------- | ----------------------- | ----------------------------------------- |
| queueableContext | System.QueueableContext | Context of the current queuable instance. |

#### Return Type

**void**
