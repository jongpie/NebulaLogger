---
layout: default
---

## LoggerPlugin class

The core of the plugin framework, used to create custom Apex &amp; Flow plugins for `LoggerSObjectHandler` and `LogBatchPurger` based on configurations stored in the custom metadata type `LoggerPlugin_t`

---

### Properties

#### `pluginConfiguration` → `LoggerPlugin_t`

---

### Methods

#### `PluginConfigurationSorter(LoggerPlugin_t pluginConfiguration)` → `public`

#### `compareTo(Object compareTo)` → `Integer`

#### `getFilteredPluginConfigurations(List<Schema.SObjectField> populatedFilterFields, Schema.SObjectField sortByField)` → `List<LoggerPlugin_t>`

Filters the configured `LoggerPlugin_t` records based on a list of `SObjectField` - only records that have a value for 1 or more of the specified `populatedFilterFields` will be returned, sorted by the specified `SObjectField` parameter `sortByField`

##### Parameters

| Param                   | Description                                                                                                                   |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `populatedFilterFields` | The list of `SObjectField` to check on each `LoggerPlugin_t` record - filtering logic checks for a non-null value             |
| `sortByField`           | The `SObjectField` to use to sort the list of matches. The method also uses `DeveloperName` as a secondary field for sorting. |

##### Return

**Type**

List&lt;LoggerPlugin_t&gt;

**Description**

The list of matching `LoggerPlugin_t` records

#### `newBatchableInstance(String apexClassTypeName)` → `Batchable`

Creates an instance of the class `LoggerPlugin.Batchable` based on the provided `LoggerPlugin_t` configuration

##### Parameters

| Param               | Description                                                         |
| ------------------- | ------------------------------------------------------------------- |
| `apexClassTypeName` | The name of the Apex class that implements `LoggerPlugin.Batchable` |

##### Return

**Type**

Batchable

**Description**

The dynamically created instance of `LoggerPlugin.Batchable`,

#### `newTriggerableInstance(String apexClassTypeName)` → `Triggerable`

Creates an instance of the class `LoggerPlugin.Triggerable` based on the provided `LoggerPlugin_t` configuration

##### Parameters

| Param               | Description                                                           |
| ------------------- | --------------------------------------------------------------------- |
| `apexClassTypeName` | The name of the Apex class that implements `LoggerPlugin.Triggerable` |

##### Return

**Type**

Triggerable

**Description**

The dynamically created instance of `LoggerPlugin.Triggerable`,

#### `sortBy(Schema.SObjectField field)` → `PluginConfigurationSorter`

---

### Inner Classes

#### LoggerPlugin.Batchable interface

Interface used to create plugins that can be used within Logger&apos;s batch job `LogBatchPurger`

---

##### Methods

###### `execute(LoggerPlugin_t configuration, LoggerBatchableContext input, List<SObject> scopeRecords)` → `void`

###### `finish(LoggerPlugin_t configuration, LoggerBatchableContext input)` → `void`

###### `start(LoggerPlugin_t configuration, LoggerBatchableContext input)` → `void`

---

#### LoggerPlugin.Triggerable interface

Interface used to create plugins that can be used within Logger&apos;s trigger handler framework `LoggerSObjectHandler`

---

##### Methods

###### `execute(LoggerPlugin_t configuration, LoggerTriggerableContext input)` → `void`

---
