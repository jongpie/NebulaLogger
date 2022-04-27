<a name="LogEntryBuilder"></a>

## LogEntryBuilder

**Kind**: global class

-   [LogEntryBuilder](#LogEntryBuilder)
    -   [new LogEntryBuilder(loggingLevel, shouldSave, isConsoleLoggingEnabled)](#new_LogEntryBuilder_new)
    -   [.setMessage(message)](#LogEntryBuilder+setMessage) [<code>LogEntryBuilder</code>](#LogEntryBuilder)
    -   [.setRecordId(recordId)](#LogEntryBuilder+setRecordId) [<code>LogEntryBuilder</code>](#LogEntryBuilder)
    -   [.setRecord(record)](#LogEntryBuilder+setRecord) [<code>LogEntryBuilder</code>](#LogEntryBuilder)
    -   [.setError(error)](#LogEntryBuilder+setError) [<code>LogEntryBuilder</code>](#LogEntryBuilder)
    -   [.addTag(tag)](#LogEntryBuilder+addTag) [<code>LogEntryBuilder</code>](#LogEntryBuilder)
    -   [.addTags(tags)](#LogEntryBuilder+addTags) [<code>LogEntryBuilder</code>](#LogEntryBuilder)

<a name="new_LogEntryBuilder_new"></a>

### new LogEntryBuilder(loggingLevel, shouldSave, isConsoleLoggingEnabled)

Constructor used to generate each JavaScript-based log entry event
This class is the JavaScript-equivalent of the Apex class `LogEntryBuilder`

| Param                   | Type                 | Description                                                                     |
| ----------------------- | -------------------- | ------------------------------------------------------------------------------- |
| loggingLevel            | <code>String</code>  | The `LoggingLevel` enum to use for the builder's instance of `LogEntryEvent__e` |
| shouldSave              | <code>Boolean</code> | Determines if the builder's instance of `LogEntryEvent__e` should be saved      |
| isConsoleLoggingEnabled | <code>Boolean</code> | Determines if `console.log()` methods are execute                               |

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

<a name="LogEntryBuilder+setError"></a>

### logEntryBuilder.setError(error) [<code>LogEntryBuilder</code>](#LogEntryBuilder)

Sets the log entry event's exception fields

**Kind**: instance method of [<code>LogEntryBuilder</code>](#LogEntryBuilder)
**Returns**: [<code>LogEntryBuilder</code>](#LogEntryBuilder) - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param | Type               | Description                                         |
| ----- | ------------------ | --------------------------------------------------- |
| error | <code>Error</code> | The instance of a JavaScript `Error` object to use. |

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
