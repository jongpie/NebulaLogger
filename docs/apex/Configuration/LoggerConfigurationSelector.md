---
layout: default
---

## LoggerConfigurationSelector class

Selector class used for all queries that are specific to the configuration layer.

---

### Methods

#### `getInstance()` → `LoggerConfigurationSelector`

The instance of `LoggerConfigurationSelector` used for any querying specific to the configuration layer

##### Return

**Type**

LoggerConfigurationSelector

**Description**

The singleton instance of `LoggerConfigurationSelector`

#### `getLogEntryDataMaskRules()` → `List<LogEntryDataMaskRule_t>`

Returns the `LogEntryDataMaskRule_t` records in the org.

##### Return

**Type**

List&lt;LogEntryDataMaskRule_t&gt;

**Description**

`List&lt;LogEntryDataMaskRule_t&gt;` containing records in the org

#### `getLogEntryTagRules()` → `List<LogEntryTagRule_t>`

Returns the enabled `LogEntryTagRule_t` records in the org, including the field `SObjectField__r.QualifiedApiName` that cannot be accessed via `LogEntryTagRule_t.getAll()`. The value of `SObjectField__c` is automatically set to the value of `SObjectField__r.QualifiedApiName`

##### Return

**Type**

List&lt;LogEntryTagRule_t&gt;

**Description**

`List&lt;LogEntryTagRule_t&gt;` containing enabled records in the org

#### `getLogStatuses()` → `List<LogStatus_t>`

Returns the `LogStatus_t` records in the org.

##### Return

**Type**

List&lt;LogStatus_t&gt;

**Description**

`List&lt;LogStatus_t&gt;` containing records in the org

#### `getLoggerFieldMappings()` → `List<LoggerFieldMapping_t>`

Returns the enabled `LoggerFieldMapping_t` records in the org.

##### Return

**Type**

List&lt;LoggerFieldMapping_t&gt;

**Description**

`List&lt;LoggerFieldMapping_t&gt;` containing enabled records in the org

#### `getLoggerParameters()` → `Map<String, LoggerParameter_t>`

Returns the `LoggerParameter_t` records in the org.

##### Return

**Type**

Map&lt;String, LoggerParameter_t&gt;

**Description**

`List&lt;LoggerParameter_t&gt;` containing records in the org

#### `getLoggerPlugins()` → `List<LoggerPlugin_t>`

Returns the `LoggerPlugin_t` records in the org.

##### Return

**Type**

List&lt;LoggerPlugin_t&gt;

**Description**

`List&lt;LoggerPlugin_t&gt;` containing records in the org

#### `getLoggerSObjectHandlers()` → `List<LoggerSObjectHandler_t>`

Returns the `LoggerSObjectHandler_t` records in the org.

##### Return

**Type**

List&lt;LoggerSObjectHandler_t&gt;

**Description**

`List&lt;LoggerSObjectHandler_t&gt;` containing records in the org

#### `getLoggerScenarioRules()` → `List<LoggerScenarioRule_t>`

Returns the `LoggerScenarioRule_t` records in the org.

##### Return

**Type**

List&lt;LoggerScenarioRule_t&gt;

**Description**

`List&lt;LoggerScenarioRule_t&gt;` containing records in the org

---
