---
layout: default
---

## SlackLoggerPlugin class

Optional plugin that integrates with Slack to send alerts for important logs

---

### Constructors

#### `SlackLoggerPlugin()`

## Default constructor

### Properties

#### `actions` → `List<ActionDto>`

#### `attachments` → `List<LogDto>`

#### `author_icon` → `String`

#### `author_link` → `String`

#### `author_name` → `String`

#### `color` → `String`

#### `fallback` → `String`

#### `fields` → `List<FieldDto>`

#### `isShort` → `Boolean`

#### `pretext` → `String`

#### `text` → `String`

#### `text` → `String`

#### `text` → `String`

#### `title` → `String`

#### `title` → `String`

#### `title_link` → `String`

#### `type` → `String`

#### `url` → `String`

#### `value` → `String`

---

### Methods

#### `execute(LoggerPlugin_t configuration, LoggerTriggerableContext input)` → `void`

Handles the integration with Slack. This method is automatically called by Nebula Logger&apos;s plugin framework.

##### Parameters

| Param           | Description                                                                |
| --------------- | -------------------------------------------------------------------------- |
| `configuration` | The instance of `LoggerPlugin_t` configured for this specific plugin       |
| `input`         | The instance of `LoggerTriggerableContext`, provided by the logging system |

#### `execute(System.QueueableContext queueableContext)` → `void`

Handles the queuable execute logic. Required by the Queueable interface.

##### Parameters

| Param              | Description                               |
| ------------------ | ----------------------------------------- |
| `queueableContext` | Context of the current queuable instance. |

---
