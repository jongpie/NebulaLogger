## Functions

<dl>
<dt><a href="#getUserSettings">getUserSettings(parameters)</a> <code>Promise.&lt;ComponentLogger.ComponentLoggerSettings&gt;</code></dt>
<dd><p>Returns <strong>read-only</strong> information about the current user&#39;s settings, stored in <code>LoggerSettings__c</code></p>
</dd>
<dt><a href="#setScenario">setScenario(scenario)</a> <code>Array.&lt;Promise&gt;</code></dt>
<dd><p>Sets the scenario name for the current transaction - this is stored in <code>LogEntryEvent__e.Scenario__c</code>
             and <code>Log__c.Scenario__c</code>, and can be used to filter &amp; group logs</p>
</dd>
<dt><a href="#error">error(message)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.ERROR</code></p>
</dd>
<dt><a href="#warn">warn(message)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.WARN</code></p>
</dd>
<dt><a href="#info">info(message)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.INFO</code></p>
</dd>
<dt><a href="#debug">debug(message)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.DEBUG</code></p>
</dd>
<dt><a href="#fine">fine(message)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.FINE</code></p>
</dd>
<dt><a href="#finer">finer(message)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.FINER</code></p>
</dd>
<dt><a href="#finest">finest(message)</a> <code>LogEntryBuilder</code></dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.FINEST</code></p>
</dd>
<dt><a href="#getBufferSize">getBufferSize()</a> <code>Integer</code></dt>
<dd><p>Returns the number of entries that have been generated but not yet saved</p>
</dd>
<dt><a href="#flushBuffer">flushBuffer()</a> <code>Promise.&lt;void&gt;</code></dt>
<dd><p>Discards any entries that have been generated but not yet saved</p>
</dd>
<dt><a href="#saveLog">saveLog(saveMethod)</a></dt>
<dd><p>Saves any entries in Logger&#39;s buffer, using the specified save method for only this call
             All subsequent calls to saveLog() will use the transaction save method</p>
</dd>
<dt><a href="#createLogger">createLogger()</a> <code>LoggerService</code></dt>
<dd></dd>
</dl>

<a name="getUserSettings"></a>

## getUserSettings(parameters) <code>Promise.&lt;ComponentLogger.ComponentLoggerSettings&gt;</code>

Returns **read-only** information about the current user's settings, stored in `LoggerSettings__c`

**Kind**: global function  
**Returns**: <code>Promise.&lt;ComponentLogger.ComponentLoggerSettings&gt;</code> - The current user's instance of the Apex class `ComponentLogger.ComponentLoggerSettings`

| Param      | Type                | Description                                                                                                              |
| ---------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| parameters | <code>Object</code> | Object used to provide control over how user settings are retrieved. Currently, only the property `forceReload` is used. |

<a name="setScenario"></a>

## setScenario(scenario) <code>Array.&lt;Promise&gt;</code>

Sets the scenario name for the current transaction - this is stored in `LogEntryEvent__e.Scenario__c`
and `Log__c.Scenario__c`, and can be used to filter & group logs

**Kind**: global function  
**Returns**: <code>Array.&lt;Promise&gt;</code> - A list of promises that be resolved before all scenarios are set

| Param    | Type                | Description                                            |
| -------- | ------------------- | ------------------------------------------------------ |
| scenario | <code>String</code> | The name to use for the current transaction's scenario |

<a name="error"></a>

## error(message) <code>LogEntryBuilder</code>

Creates a new log entry with logging level == `LoggingLevel.ERROR`

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

| Param   | Type                | Description                                        |
| ------- | ------------------- | -------------------------------------------------- |
| message | <code>String</code> | The string to use to set the entry's message field |

<a name="warn"></a>

## warn(message) <code>LogEntryBuilder</code>

Creates a new log entry with logging level == `LoggingLevel.WARN`

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

| Param   | Type                | Description                                        |
| ------- | ------------------- | -------------------------------------------------- |
| message | <code>String</code> | The string to use to set the entry's message field |

<a name="info"></a>

## info(message) <code>LogEntryBuilder</code>

Creates a new log entry with logging level == `LoggingLevel.INFO`

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

| Param   | Type                | Description                                        |
| ------- | ------------------- | -------------------------------------------------- |
| message | <code>String</code> | The string to use to set the entry's message field |

<a name="debug"></a>

## debug(message) <code>LogEntryBuilder</code>

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

| Param   | Type                | Description                                        |
| ------- | ------------------- | -------------------------------------------------- |
| message | <code>String</code> | The string to use to set the entry's message field |

<a name="fine"></a>

## fine(message) <code>LogEntryBuilder</code>

Creates a new log entry with logging level == `LoggingLevel.FINE`

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

| Param   | Type                | Description                                        |
| ------- | ------------------- | -------------------------------------------------- |
| message | <code>String</code> | The string to use to set the entry's message field |

<a name="finer"></a>

## finer(message) <code>LogEntryBuilder</code>

Creates a new log entry with logging level == `LoggingLevel.FINER`

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

| Param   | Type                | Description                                        |
| ------- | ------------------- | -------------------------------------------------- |
| message | <code>String</code> | The string to use to set the entry's message field |

<a name="finest"></a>

## finest(message) <code>LogEntryBuilder</code>

Creates a new log entry with logging level == `LoggingLevel.FINEST`

**Kind**: global function  
**Returns**: <code>LogEntryBuilder</code> - The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods

| Param   | Type                | Description                                        |
| ------- | ------------------- | -------------------------------------------------- |
| message | <code>String</code> | The string to use to set the entry's message field |

<a name="getBufferSize"></a>

## getBufferSize() <code>Integer</code>

Returns the number of entries that have been generated but not yet saved

**Kind**: global function  
**Returns**: <code>Integer</code> - The buffer's current size  
<a name="flushBuffer"></a>

## flushBuffer() <code>Promise.&lt;void&gt;</code>

Discards any entries that have been generated but not yet saved

**Kind**: global function  
**Returns**: <code>Promise.&lt;void&gt;</code> - A promise to clear the entries  
<a name="saveLog"></a>

## saveLog(saveMethod)

Saves any entries in Logger's buffer, using the specified save method for only this call
All subsequent calls to saveLog() will use the transaction save method

**Kind**: global function

| Param      | Type                | Description                                                              |
| ---------- | ------------------- | ------------------------------------------------------------------------ |
| saveMethod | <code>String</code> | The enum value of Logger.SaveMethod to use for this specific save action |

<a name="createLogger"></a>

## createLogger() <code>LoggerService</code>

**Kind**: global function  
**Returns**: <code>LoggerService</code> - a LoggerService instance
