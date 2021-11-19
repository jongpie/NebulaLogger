---
layout: default
---

## LoggerPlugin class

Abstract class used to create custom Apex &amp; Flow plugins

---

### Methods

#### `execute(PluginInput input)` → `void`

This method is the entry point for plugins to execute any custom logic. It is automatically called by the logging system for any enabled plugins.

##### Parameters

| Param   | Description                                                                |
| ------- | -------------------------------------------------------------------------- |
| `input` | The instance of `LoggerPlugin.PluginInput`, provided by the logging system |

---

### Inner Classes

#### LoggerPlugin.PluginInput class

Class used by the logging system to provide context &amp; record details to logger plugins

---

##### Properties

###### `triggerOperationType` → `TriggerOperation`

###### `triggerOperationTypeName` → `String`

###### `triggerRecords` → `List<PluginRecordInput>`

---

#### LoggerPlugin.PluginRecordInput class

Class used by the logging system to provide record details to logger plugins

---

##### Properties

###### `triggerRecordNew` → `SObject`

###### `triggerRecordOld` → `SObject`

---
