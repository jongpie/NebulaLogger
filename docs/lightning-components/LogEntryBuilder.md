<a name="LogEntryBuilder"></a>

## LogEntryBuilder

**Kind**: global class

- [LogEntryBuilder](#LogEntryBuilder)
  - [new LogEntryBuilder(loggingLevel, isConsoleLoggingEnabled, isLightningLoggerEnabled)](#new_LogEntryBuilder_new)
  - [.setMessage(message)](#LogEntryBuilder+setMessage) [<code>LogEntryBuilder</code>](#LogEntryBuilder)
  - [.setRecordId(recordId)](#LogEntryBuilder+setRecordId) [<code>LogEntryBuilder</code>](#LogEntryBuilder)
  - [.setRecord(record)](#LogEntryBuilder+setRecord) [<code>LogEntryBuilder</code>](#LogEntryBuilder)
  - [.setScenario(scenario)](#LogEntryBuilder+setScenario) [<code>LogEntryBuilder</code>](#LogEntryBuilder)
  - [.setError(error)](#LogEntryBuilder+setError) [<code>LogEntryBuilder</code>](#LogEntryBuilder)
  - [.parseStackTrace(error)](#LogEntryBuilder+parseStackTrace) [<code>LogEntryBuilder</code>](#LogEntryBuilder)
  - [.addTag(tag)](#LogEntryBuilder+addTag) [<code>LogEntryBuilder</code>](#LogEntryBuilder)
  - [.addTags(tags)](#LogEntryBuilder+addTags) [<code>LogEntryBuilder</code>](#LogEntryBuilder)
  - [.getComponentLogEntry()](#LogEntryBuilder+getComponentLogEntry) <code>ComponentLogEntry</code>

<a name="new_LogEntryBuilder_new"></a>

### new LogEntryBuilder(loggingLevel, isConsoleLoggingEnabled, isLightningLoggerEnabled)

Constructor used to generate each JavaScript-based log entry event
This class is the JavaScript-equivalent of the Apex class `LogEntryBuilder`

| Param                    | Type                 | Description                                                                     |
| ------------------------ | -------------------- | ------------------------------------------------------------------------------- |
| loggingLevel             | <code>String</code>  | The `LoggingLevel` enum to use for the builder's instance of `LogEntryEvent__e` |
| isConsoleLoggingEnabled  | <code>Boolean</code> | Determines if `console.log()` methods are execute                               |
| isLightningLoggerEnabled | <code>Boolean</code> | Determines if `lightning-logger` LWC is called                                  |

<a name="LogEntryBuilder+setMessage"></a>

### logEntryBuilder.setMessage(message) [<code>LogEntryBuilder</code>](#LogEntryBuilder)

Sets the log entry event's message field

**Kind**: instance method of [<code>LogEntryBuilder</code>](#LogEntryBuilder)  
**Returns**: [<code>LogEntryBuilder</code>](#LogEntryBuilder) - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param   | Type                | Description                                        |
| ------- | ------------------- | -------------------------------------------------- |
| message | <code>String</code> | The string to use to set the entry's message field |

<a name="LogEntryBuilder+setRecordId"></a>

### logEntryBuilder.setRecordId(recordId) [<code>LogEntryBuilder</code>](#LogEntryBuilder)

Sets the log entry event's record fields

**Kind**: instance method of [<code>LogEntryBuilder</code>](#LogEntryBuilder)  
**Returns**: [<code>LogEntryBuilder</code>](#LogEntryBuilder) - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param    | Type                | Description                                       |
| -------- | ------------------- | ------------------------------------------------- |
| recordId | <code>String</code> | The ID of the SObject record related to the entry |

<a name="LogEntryBuilder+setRecord"></a>

### logEntryBuilder.setRecord(record) [<code>LogEntryBuilder</code>](#LogEntryBuilder)

Sets the log entry event's record fields

**Kind**: instance method of [<code>LogEntryBuilder</code>](#LogEntryBuilder)  
**Returns**: [<code>LogEntryBuilder</code>](#LogEntryBuilder) - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param  | Type                | Description                                                                                           |
| ------ | ------------------- | ----------------------------------------------------------------------------------------------------- |
| record | <code>Object</code> | The `SObject` record related to the entry. The JSON of the record is automatically added to the entry |

<a name="LogEntryBuilder+setScenario"></a>

### logEntryBuilder.setScenario(scenario) [<code>LogEntryBuilder</code>](#LogEntryBuilder)

Sets the log entry event's scenario field

**Kind**: instance method of [<code>LogEntryBuilder</code>](#LogEntryBuilder)  
**Returns**: [<code>LogEntryBuilder</code>](#LogEntryBuilder) - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param    | Type                | Description                                         |
| -------- | ------------------- | --------------------------------------------------- |
| scenario | <code>String</code> | The string to use to set the entry's scenario field |

<a name="LogEntryBuilder+setError"></a>

### logEntryBuilder.setError(error) [<code>LogEntryBuilder</code>](#LogEntryBuilder)

Sets the log entry event's exception fields

**Kind**: instance method of [<code>LogEntryBuilder</code>](#LogEntryBuilder)  
**Returns**: [<code>LogEntryBuilder</code>](#LogEntryBuilder) - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param | Type               | Description                                                                      |
| ----- | ------------------ | -------------------------------------------------------------------------------- |
| error | <code>Error</code> | The instance of a JavaScript `Error` object to use, or an Apex HTTP error to use |

<a name="LogEntryBuilder+parseStackTrace"></a>

### logEntryBuilder.parseStackTrace(error) [<code>LogEntryBuilder</code>](#LogEntryBuilder)

Parses the provided error's stack trace and sets the log entry's origin & stack trace fields

**Kind**: instance method of [<code>LogEntryBuilder</code>](#LogEntryBuilder)  
**Returns**: [<code>LogEntryBuilder</code>](#LogEntryBuilder) - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param | Type               | Description                                                             |
| ----- | ------------------ | ----------------------------------------------------------------------- |
| error | <code>Error</code> | The instance of a JavaScript `Error` object with a stack trace to parse |

<a name="LogEntryBuilder+addTag"></a>

### logEntryBuilder.addTag(tag) [<code>LogEntryBuilder</code>](#LogEntryBuilder)

Appends the tag to the existing list of tags

**Kind**: instance method of [<code>LogEntryBuilder</code>](#LogEntryBuilder)  
**Returns**: [<code>LogEntryBuilder</code>](#LogEntryBuilder) - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param | Type                | Description                                          |
| ----- | ------------------- | ---------------------------------------------------- |
| tag   | <code>String</code> | The string to add as a tag for the current log entry |

<a name="LogEntryBuilder+addTags"></a>

### logEntryBuilder.addTags(tags) [<code>LogEntryBuilder</code>](#LogEntryBuilder)

Appends the tag to the existing list of tags

**Kind**: instance method of [<code>LogEntryBuilder</code>](#LogEntryBuilder)  
**Returns**: [<code>LogEntryBuilder</code>](#LogEntryBuilder) - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param | Type                              | Description                                              |
| ----- | --------------------------------- | -------------------------------------------------------- |
| tags  | <code>Array.&lt;String&gt;</code> | The list of strings to add as tags for the current entry |

<a name="LogEntryBuilder+getComponentLogEntry"></a>

### logEntryBuilder.getComponentLogEntry() <code>ComponentLogEntry</code>

Returns the object used to save log entry data

**Kind**: instance method of [<code>LogEntryBuilder</code>](#LogEntryBuilder)  
**Returns**: <code>ComponentLogEntry</code> - An instance of `ComponentLogEntry` that matches the Apex class `ComponentLogger.ComponentLogEntry`
