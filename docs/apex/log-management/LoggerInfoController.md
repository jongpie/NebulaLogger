---
layout: default
---

## LoggerInfoController class

Controller class for lwc `loggerInfo`, used to display system information about Nebula Logger

### Related

[LogEntryEventBuilder](LogEntryEventBuilder)

[LogMessage](LogMessage)

---

### Methods

#### `getNamespacePrefix()` → `String`

Returns the current namespace of Nebula Logger

##### Return

**Type**

String

**Description**

The current namespace prefix, or an empty string when no namespace is being used

#### `getPlugins()` → `List<LoggerPlugin_t>`

Returns the list of plugins installed/deployed to the org

##### Return

**Type**

List&lt;LoggerPlugin_t&gt;

**Description**

The list of configured plugins, based on the custom metadata type `LoggerPlugin_t`

#### `getVersionNumber()` → `String`

Returns the current version number of Nebula Logger

##### Return

**Type**

String

**Description**

The current version number, in the format `v0.0.0`

---
