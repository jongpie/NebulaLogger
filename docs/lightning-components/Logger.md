## Functions

<dl>
<dt><a href="#getUserSettings">getUserSettings()</a> ΓçÆ</dt>
<dd><p>Returns the current user&#39;s instance of <code>LoggerSettings__c</code></p>
</dd>
<dt><a href="#setScenario">setScenario(scenario)</a></dt>
<dd><p>Sets the scenario name for the current transaction - this is stored in <code>LogEntryEvent__e.Scenario__c</code>
             and <code>Log__c.Scenario__c</code>, and can be used to filter &amp; group logs</p>
</dd>
<dt><a href="#error">error()</a> ΓçÆ</dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.ERROR</code></p>
</dd>
<dt><a href="#warn">warn()</a> ΓçÆ</dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.WARN</code></p>
</dd>
<dt><a href="#info">info()</a> ΓçÆ</dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.INFO</code></p>
</dd>
<dt><a href="#debug">debug()</a> ΓçÆ</dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.DEBUG</code></p>
</dd>
<dt><a href="#fine">fine()</a> ΓçÆ</dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.FINE</code></p>
</dd>
<dt><a href="#finer">finer()</a> ΓçÆ</dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.FINER</code></p>
</dd>
<dt><a href="#finest">finest()</a> ΓçÆ</dt>
<dd><p>Creates a new log entry with logging level == <code>LoggingLevel.FINEST</code></p>
</dd>
<dt><a href="#getBufferSize">getBufferSize()</a> ΓçÆ</dt>
<dd><p>Returns the number of entries that have been generated but not yet saved</p>
</dd>
<dt><a href="#flushBuffer">flushBuffer()</a></dt>
<dd><p>Discards any entries that have been generated but not yet saved</p>
</dd>
<dt><a href="#saveLog">saveLog(saveMethod)</a></dt>
<dd><p>Saves any entries in Logger&#39;s buffer, using the specified save method for only this call.
             All subsequent calls to saveLog() will use the transaction save method.</p>
</dd>
</dl>

<a name="getUserSettings"></a>

## getUserSettings() ΓçÆ

Returns the current user's instance of `LoggerSettings__c`

**Kind**: global function  
**Returns**: The current user's instance of the custom settings  
<a name="setScenario"></a>

## setScenario(scenario)

Sets the scenario name for the current transaction - this is stored in `LogEntryEvent__e.Scenario__c`
and `Log__c.Scenario__c`, and can be used to filter & group logs

**Kind**: global function

| Param    | Description                                            |
| -------- | ------------------------------------------------------ |
| scenario | The name to use for the current transaction's scenario |

<a name="error"></a>

## error() ΓçÆ

Creates a new log entry with logging level == `LoggingLevel.ERROR`

**Kind**: global function  
**Returns**: The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods  
<a name="warn"></a>

## warn() ΓçÆ

Creates a new log entry with logging level == `LoggingLevel.WARN`

**Kind**: global function  
**Returns**: The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods  
<a name="info"></a>

## info() ΓçÆ

Creates a new log entry with logging level == `LoggingLevel.INFO`

**Kind**: global function  
**Returns**: The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods  
<a name="debug"></a>

## debug() ΓçÆ

Creates a new log entry with logging level == `LoggingLevel.DEBUG`

**Kind**: global function  
**Returns**: The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods  
<a name="fine"></a>

## fine() ΓçÆ

Creates a new log entry with logging level == `LoggingLevel.FINE`

**Kind**: global function  
**Returns**: The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods  
<a name="finer"></a>

## finer() ΓçÆ

Creates a new log entry with logging level == `LoggingLevel.FINER`

**Kind**: global function  
**Returns**: The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods  
<a name="finest"></a>

## finest() ΓçÆ

Creates a new log entry with logging level == `LoggingLevel.FINEST`

**Kind**: global function  
**Returns**: The new entry's instance of `LogEntryEventBuilder`, useful for chaining methods  
<a name="getBufferSize"></a>

## getBufferSize() ΓçÆ

Returns the number of entries that have been generated but not yet saved

**Kind**: global function  
**Returns**: Integer  
<a name="flushBuffer"></a>

## flushBuffer()

Discards any entries that have been generated but not yet saved

**Kind**: global function  
<a name="saveLog"></a>

## saveLog(saveMethod)

Saves any entries in Logger's buffer, using the specified save method for only this call.
All subsequent calls to saveLog() will use the transaction save method.

**Kind**: global function

| Param      | Description                                                               |
| ---------- | ------------------------------------------------------------------------- |
| saveMethod | The enum value of Logger.SaveMethod to use for this specific save action. |
