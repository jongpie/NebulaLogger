## Functions

<dl>
<dt><a href="#setMessage">setMessage(message)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Sets the log entry event&#39;s message field</p>
</dd>
<dt><a href="#setRecordId">setRecordId(recordId)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Sets the log entry event&#39;s record fields</p>
</dd>
<dt><a href="#setRecord">setRecord(record)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Sets the log entry event&#39;s record fields</p>
</dd>
<dt><a href="#setScenario">setScenario(scenario)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Sets the log entry event&#39;s scenario field</p>
</dd>
<dt><a href="#setError">setError(error)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Deprecated - use <code>setExceptionDetails(exception)</code> instead
             The name of this method is very similar to the logger function logger.error(),
             resulting in confusion when used together:
               <code>logger.error(&#39;Unexpected error&#39;).setError(someErrorObject);</code>
             The new <code>setExceptionDetails(exception)</code> function provides the exact same functionality,
             but aligns with the Apex builder&#39;s method name, and helps reduce the confusion with <code>logger.error()</code></p>
</dd>
<dt><a href="#setExceptionDetails">setExceptionDetails(exception)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Sets the log entry event&#39;s exception fields</p>
</dd>
<dt><a href="#setField">setField(fieldToValue)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Sets multiple field values on the builder&#39;s <code>LogEntryEvent__e</code> record</p>
</dd>
<dt><a href="#parseStackTrace">parseStackTrace(originStackTraceError)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Parses the provided error&#39;s stack trace and sets the log entry&#39;s origin &amp; stack trace fields</p>
</dd>
<dt><a href="#addTag">addTag(tag)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Appends the tag to the existing list of tags</p>
</dd>
<dt><a href="#addTags">addTags(tags)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Appends the tag to the existing list of tags</p>
</dd>
<dt><a href="#getComponentLogEntry">getComponentLogEntry()</a> <code>ComponentLogEntry</code></dt>
<dd><p>Returns the object used to save log entry data</p>
</dd>
</dl>

<a name="setMessage"></a>

## setMessage(message) <code>LogEntryBuilder</code>

Sets the log entry event's message field

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param   | Type                | Description                                        |
| ------- | ------------------- | -------------------------------------------------- |
| message | <code>String</code> | The string to use to set the entry's message field |

<a name="setRecordId"></a>

## setRecordId(recordId) <code>LogEntryBuilder</code>

Sets the log entry event's record fields

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param    | Type                | Description                                       |
| -------- | ------------------- | ------------------------------------------------- |
| recordId | <code>String</code> | The ID of the SObject record related to the entry |

<a name="setRecord"></a>

## setRecord(record) <code>LogEntryBuilder</code>

Sets the log entry event's record fields

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param  | Type                | Description                                                                                           |
| ------ | ------------------- | ----------------------------------------------------------------------------------------------------- |
| record | <code>Object</code> | The `SObject` record related to the entry. The JSON of the record is automatically added to the entry |

<a name="setScenario"></a>

## setScenario(scenario) <code>LogEntryBuilder</code>

Sets the log entry event's scenario field

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param    | Type                | Description                                         |
| -------- | ------------------- | --------------------------------------------------- |
| scenario | <code>String</code> | The string to use to set the entry's scenario field |

<a name="setError"></a>

## setError(error) <code>LogEntryBuilder</code>

Deprecated - use `setExceptionDetails(exception)` instead
The name of this method is very similar to the logger function logger.error(),
resulting in confusion when used together:
`logger.error('Unexpected error').setError(someErrorObject);`
The new `setExceptionDetails(exception)` function provides the exact same functionality,
but aligns with the Apex builder's method name, and helps reduce the confusion with `logger.error()`

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param | Type               | Description                                                                      |
| ----- | ------------------ | -------------------------------------------------------------------------------- |
| error | <code>Error</code> | The instance of a JavaScript `Error` object to use, or an Apex HTTP error to use |

<a name="setExceptionDetails"></a>

## setExceptionDetails(exception) <code>LogEntryBuilder</code>

Sets the log entry event's exception fields

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param     | Type               | Description                                                                      |
| --------- | ------------------ | -------------------------------------------------------------------------------- |
| exception | <code>Error</code> | The instance of a JavaScript `Error` object to use, or an Apex HTTP error to use |

<a name="setField"></a>

## setField(fieldToValue) <code>LogEntryBuilder</code>

Sets multiple field values on the builder's `LogEntryEvent__e` record

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param        | Type                | Description                                                                                                                                                               |
| ------------ | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| fieldToValue | <code>Object</code> | An object containing the custom field name as a key, with the corresponding value to store. Example: `{"SomeField__c": "some value", "AnotherField__c": "another value"}` |

<a name="parseStackTrace"></a>

## parseStackTrace(originStackTraceError) <code>LogEntryBuilder</code>

Parses the provided error's stack trace and sets the log entry's origin & stack trace fields

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param                 | Type               | Description                                                             |
| --------------------- | ------------------ | ----------------------------------------------------------------------- |
| originStackTraceError | <code>Error</code> | The instance of a JavaScript `Error` object with a stack trace to parse |

<a name="addTag"></a>

## addTag(tag) <code>LogEntryBuilder</code>

Appends the tag to the existing list of tags

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param | Type                | Description                                          |
| ----- | ------------------- | ---------------------------------------------------- |
| tag   | <code>String</code> | The string to add as a tag for the current log entry |

<a name="addTags"></a>

## addTags(tags) <code>LogEntryBuilder</code>

Appends the tag to the existing list of tags

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The same instance of `LogEntryBuilder`, useful for chaining methods

| Param | Type                              | Description                                              |
| ----- | --------------------------------- | -------------------------------------------------------- |
| tags  | <code>Array.&lt;String&gt;</code> | The list of strings to add as tags for the current entry |

<a name="getComponentLogEntry"></a>

## getComponentLogEntry() <code>ComponentLogEntry</code>

Returns the object used to save log entry data

**Kind**: global function  
**Returns**: <code>ComponentLogEntry</code> - An instance of `ComponentLogEntry` that matches the Apex class `ComponentLogger.ComponentLogEntry`
