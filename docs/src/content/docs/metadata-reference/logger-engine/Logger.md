---
title: Logger
description: 'Nebula Logger class reference: Logger.'
---

# Logger Class

`SUPPRESSWARNINGS`

The core class for logging

**Group** Logger Engine

**See** [LogEntryEventBuilder](LogEntryEventBuilder.md)

**See** [LogMessage](LogMessage.md)

## Methods

### `debug(logMessage, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult       | The instance of `Database.DeleteResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                                               |
| --------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| logMessage            | [LogMessage](LogMessage.md)    | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                        | Description                                                               |
| ----------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage        | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult  | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult        | The instance of `Database.MergeResult` to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult         | The instance of `Database.SaveResult` to log                              |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                        | Description                                                               |
| -------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage     | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult     | The instance of `Database.UndeleteResult` to log                          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult       | The instance of `Database.UpsertResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The instance of `List<Database.DeleteResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                               |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------------------- |
| logMessage             | [LogMessage](LogMessage.md)          | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                                               |
| ------------------ | -------------------------------- | ------------------------------------------------------------------------- |
| logMessage         | [LogMessage](LogMessage.md)      | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult>  | The instance of `List<Database.MergeResult>` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult>   | The instance of `List<Database.SaveResult>` to log                        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                                               |
| --------------- | ----------------------------- | ------------------------------------------------------------------------- |
| logMessage      | [LogMessage](LogMessage.md)   | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The instance of `List<Database.UndeleteResult>` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The instance of `List<Database.UpsertResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, Id recordId)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| recordId   | Id                          | The record ID of an `SObject` to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, SObject record)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| record     | SObject                     | The `SObject` record to log                                               |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage, List<SObject> records)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| records    | List<SObject>               | The list of `SObject` records to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(logMessage)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(LogMessage logMessage)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult | The instance of `Database.DeleteResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                             |
| --------------------- | ------------------------------ | ------------------------------------------------------- |
| message               | String                         | The string to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                       | Description                                             |
| ----------------- | -------------------------- | ------------------------------------------------------- |
| message           | String                     | The string to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                 | Description                                             |
| ----------- | -------------------- | ------------------------------------------------------- |
| message     | String               | The string to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult | The instance of `Database.MergeResult` to log           |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                | Description                                             |
| ---------- | ------------------- | ------------------------------------------------------- |
| message    | String              | The string to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult | The instance of `Database.SaveResult` to log            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                    | Description                                             |
| -------------- | ----------------------- | ------------------------------------------------------- |
| message        | String                  | The string to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult | The instance of `Database.UndeleteResult` to log        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult | The instance of `Database.UpsertResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The list of `Database.DeleteResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                   |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------- |
| message                | String                               | The string to use to set the entry&#x27;s message field       |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                               |
| ------------------ | -------------------------------- | --------------------------------------------------------- |
| message            | String                           | The string to use to set the entry&#x27;s message field   |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                       | Description                                             |
| ------------ | -------------------------- | ------------------------------------------------------- |
| message      | String                     | The string to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult> | The list of `Database.MergeResult` instances to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                      | Description                                             |
| ----------- | ------------------------- | ------------------------------------------------------- |
| message     | String                    | The string to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult> | The list of `Database.SaveResult` instances to log      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                             |
| --------------- | ----------------------------- | ------------------------------------------------------- |
| message         | String                        | The string to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The list of `Database.UndeleteResult` instances to log  |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The list of `Database.UpsertResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, Id recordId)
```

#### Parameters

| Name     | Type   | Description                                             |
| -------- | ------ | ------------------------------------------------------- |
| message  | String | The string to use to set the entry&#x27;s message field |
| recordId | Id     | The record ID of an `SObject` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, SObject record)
```

#### Parameters

| Name    | Type    | Description                                             |
| ------- | ------- | ------------------------------------------------------- |
| message | String  | The string to use to set the entry&#x27;s message field |
| record  | SObject | The `SObject` record to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message, List<SObject> records)
```

#### Parameters

| Name    | Type          | Description                                             |
| ------- | ------------- | ------------------------------------------------------- |
| message | String        | The string to use to set the entry&#x27;s message field |
| records | List<SObject> | The list of `SObject` records to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `debug(message)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.DEBUG`

#### Signature

```apex
global static LogEntryEventBuilder debug(String message)
```

#### Parameters

| Name    | Type   | Description                                             |
| ------- | ------ | ------------------------------------------------------- |
| message | String | The string to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `endScenario(scenario)`

End the specified scenario, if it&#x27;s the currently active scenario,
and rolls back to the previous scenario (if a previous scenario was specified in the current transaction)

#### Signature

```apex
global static void endScenario(String scenario)
```

#### Parameters

| Name     | Type   | Description                     |
| -------- | ------ | ------------------------------- |
| scenario | String | The name of the scenario to end |

#### Return Type

**void**

---

### `error(logMessage, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult       | The instance of `Database.DeleteResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                                               |
| --------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| logMessage            | [LogMessage](LogMessage.md)    | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                        | Description                                                               |
| ----------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage        | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult  | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult        | The instance of `Database.MergeResult` to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult         | The instance of `Database.SaveResult` to log                              |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                        | Description                                                               |
| -------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage     | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult     | The instance of `Database.UndeleteResult` to log                          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult       | The instance of `Database.UpsertResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The instance of `List<Database.DeleteResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                               |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------------------- |
| logMessage             | [LogMessage](LogMessage.md)          | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                                               |
| ------------------ | -------------------------------- | ------------------------------------------------------------------------- |
| logMessage         | [LogMessage](LogMessage.md)      | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult>  | The instance of `List<Database.MergeResult>` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult>   | The instance of `List<Database.SaveResult>` to log                        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                                               |
| --------------- | ----------------------------- | ------------------------------------------------------------------------- |
| logMessage      | [LogMessage](LogMessage.md)   | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The instance of `List<Database.UndeleteResult>` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The instance of `List<Database.UpsertResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, System.Exception apexException)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| apexException | System.Exception            | The instance of `System.Exception` to log                                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, recordId, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId, System.Exception apexException)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| recordId      | Id                          | The record ID of an `SObject` to log                                      |
| apexException | System.Exception            | The instance of `System.Exception` to log                                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, Id recordId)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| recordId   | Id                          | The record ID of an `SObject` to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, record, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, SObject record, System.Exception apexException)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| record        | SObject                     | The `SObject` record to log                                               |
| apexException | System.Exception            | The instance of `System.Exception` to log                                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, SObject record)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| record     | SObject                     | The `SObject` record to log                                               |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, records, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, List<SObject> records, System.Exception apexException)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| records       | List<SObject>               | The list of `SObject` records to log                                      |
| apexException | System.Exception            | The instance of `System.Exception` to log                                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage, List<SObject> records)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| records    | List<SObject>               | The list of `SObject` records to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(logMessage)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(LogMessage logMessage)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult | The instance of `Database.DeleteResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                             |
| --------------------- | ------------------------------ | ------------------------------------------------------- |
| message               | String                         | The string to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                       | Description                                             |
| ----------------- | -------------------------- | ------------------------------------------------------- |
| message           | String                     | The string to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                 | Description                                             |
| ----------- | -------------------- | ------------------------------------------------------- |
| message     | String               | The string to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult | The instance of `Database.MergeResult` to log           |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                | Description                                             |
| ---------- | ------------------- | ------------------------------------------------------- |
| message    | String              | The string to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult | The instance of `Database.SaveResult` to log            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                    | Description                                             |
| -------------- | ----------------------- | ------------------------------------------------------- |
| message        | String                  | The string to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult | The instance of `Database.UndeleteResult` to log        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult | The instance of `Database.UpsertResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The list of `Database.DeleteResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                   |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------- |
| message                | String                               | The string to use to set the entry&#x27;s message field       |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                               |
| ------------------ | -------------------------------- | --------------------------------------------------------- |
| message            | String                           | The string to use to set the entry&#x27;s message field   |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                       | Description                                             |
| ------------ | -------------------------- | ------------------------------------------------------- |
| message      | String                     | The string to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult> | The list of `Database.MergeResult` instances to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                      | Description                                             |
| ----------- | ------------------------- | ------------------------------------------------------- |
| message     | String                    | The string to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult> | The list of `Database.SaveResult` instances to log      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                             |
| --------------- | ----------------------------- | ------------------------------------------------------- |
| message         | String                        | The string to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The list of `Database.UndeleteResult` instances to log  |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The list of `Database.UpsertResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, System.Exception apexException)
```

#### Parameters

| Name          | Type             | Description                                             |
| ------------- | ---------------- | ------------------------------------------------------- |
| message       | String           | The string to use to set the entry&#x27;s message field |
| apexException | System.Exception | The instance of `System.Exception` to log               |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, recordId, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, Id recordId, System.Exception apexException)
```

#### Parameters

| Name          | Type             | Description                                             |
| ------------- | ---------------- | ------------------------------------------------------- |
| message       | String           | The string to use to set the entry&#x27;s message field |
| recordId      | Id               | The record ID of an `SObject` to log                    |
| apexException | System.Exception | The instance of `System.Exception` to log               |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, Id recordId)
```

#### Parameters

| Name     | Type   | Description                                             |
| -------- | ------ | ------------------------------------------------------- |
| message  | String | The string to use to set the entry&#x27;s message field |
| recordId | Id     | The record ID of an `SObject` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, record, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, SObject record, System.Exception apexException)
```

#### Parameters

| Name          | Type             | Description                                             |
| ------------- | ---------------- | ------------------------------------------------------- |
| message       | String           | The string to use to set the entry&#x27;s message field |
| record        | SObject          | The `SObject` record to log                             |
| apexException | System.Exception | The instance of `System.Exception` to log               |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, SObject record)
```

#### Parameters

| Name    | Type    | Description                                             |
| ------- | ------- | ------------------------------------------------------- |
| message | String  | The string to use to set the entry&#x27;s message field |
| record  | SObject | The `SObject` record to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, records, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, List<SObject> records, System.Exception apexException)
```

#### Parameters

| Name          | Type             | Description                                                               |
| ------------- | ---------------- | ------------------------------------------------------------------------- |
| message       | String           | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| records       | List<SObject>    | The list of `SObject` records to log                                      |
| apexException | System.Exception | The instance of `System.Exception` to log                                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message, List<SObject> records)
```

#### Parameters

| Name    | Type          | Description                                             |
| ------- | ------------- | ------------------------------------------------------- |
| message | String        | The string to use to set the entry&#x27;s message field |
| records | List<SObject> | The list of `SObject` records to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `error(message)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR`

#### Signature

```apex
global static LogEntryEventBuilder error(String message)
```

#### Parameters

| Name    | Type   | Description                                             |
| ------- | ------ | ------------------------------------------------------- |
| message | String | The string to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `exception(logMessage, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR` ,
automatically saves the log, and then throws the provided exception

#### Signature

```apex
global static void exception(LogMessage logMessage, System.Exception apexException)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| apexException | System.Exception            | The instance of `System.Exception` to log and throw                       |

#### Return Type

**void**

---

### `exception(logMessage, recordId, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR` ,
automatically saves the log, and then throws the provided exception

#### Signature

```apex
global static void exception(LogMessage logMessage, Id recordId, System.Exception apexException)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| recordId      | Id                          | The record ID of an `SObject` to log                                      |
| apexException | System.Exception            | The instance of `System.Exception` to log and throw                       |

#### Return Type

**void**

---

### `exception(logMessage, record, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR` ,
automatically saves the log, and then throws the provided exception

#### Signature

```apex
global static void exception(LogMessage logMessage, SObject record, System.Exception apexException)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| record        | SObject                     | The `SObject` record to log                                               |
| apexException | System.Exception            | The instance of `System.Exception` to log and throw                       |

#### Return Type

**void**

---

### `exception(logMessage, records, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR` ,
automatically saves the log, and then throws the provided exception

#### Signature

```apex
global static void exception(LogMessage logMessage, List<SObject> records, System.Exception apexException)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| records       | List<SObject>               | The list of `SObject` records to log                                      |
| apexException | System.Exception            | The instance of `System.Exception` to log and throw                       |

#### Return Type

**void**

---

### `exception(message, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR` ,
automatically saves the log, and then throws the provided exception

#### Signature

```apex
global static void exception(String message, System.Exception apexException)
```

#### Parameters

| Name          | Type             | Description                                             |
| ------------- | ---------------- | ------------------------------------------------------- |
| message       | String           | The string to use to set the entry&#x27;s message field |
| apexException | System.Exception | The instance of `System.Exception` to log and throw     |

#### Return Type

**void**

---

### `exception(message, recordId, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR` ,
automatically saves the log, and then throws the provided exception

#### Signature

```apex
global static void exception(String message, Id recordId, System.Exception apexException)
```

#### Parameters

| Name          | Type             | Description                                             |
| ------------- | ---------------- | ------------------------------------------------------- |
| message       | String           | The string to use to set the entry&#x27;s message field |
| recordId      | Id               | The record ID of an `SObject` to log                    |
| apexException | System.Exception | The instance of `System.Exception` to log and throw     |

#### Return Type

**void**

---

### `exception(message, record, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR` ,
automatically saves the log, and then throws the provided exception

#### Signature

```apex
global static void exception(String message, SObject record, System.Exception apexException)
```

#### Parameters

| Name          | Type             | Description                                             |
| ------------- | ---------------- | ------------------------------------------------------- |
| message       | String           | The string to use to set the entry&#x27;s message field |
| record        | SObject          | The `SObject` record to log                             |
| apexException | System.Exception | The instance of `System.Exception` to log and throw     |

#### Return Type

**void**

---

### `exception(message, records, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.ERROR` ,
automatically saves the log, and then throws the provided exception

#### Signature

```apex
global static void exception(String message, List<SObject> records, System.Exception apexException)
```

#### Parameters

| Name          | Type             | Description                                                               |
| ------------- | ---------------- | ------------------------------------------------------------------------- |
| message       | String           | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| records       | List<SObject>    | The list of `SObject` records to log                                      |
| apexException | System.Exception | The instance of `System.Exception` to log and throw                       |

#### Return Type

**void**

---

### `fine(logMessage, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult       | The instance of `Database.DeleteResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                                               |
| --------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| logMessage            | [LogMessage](LogMessage.md)    | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                        | Description                                                               |
| ----------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage        | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult  | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult        | The instance of `Database.MergeResult` to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult         | The instance of `Database.SaveResult` to log                              |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                        | Description                                                               |
| -------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage     | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult     | The instance of `Database.UndeleteResult` to log                          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult       | The instance of `Database.UpsertResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The instance of `List<Database.DeleteResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                               |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------------------- |
| logMessage             | [LogMessage](LogMessage.md)          | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                                               |
| ------------------ | -------------------------------- | ------------------------------------------------------------------------- |
| logMessage         | [LogMessage](LogMessage.md)      | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult>  | The instance of `List<Database.MergeResult>` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult>   | The instance of `List<Database.SaveResult>` to log                        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                                               |
| --------------- | ----------------------------- | ------------------------------------------------------------------------- |
| logMessage      | [LogMessage](LogMessage.md)   | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The instance of `List<Database.UndeleteResult>` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The instance of `List<Database.UpsertResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, Id recordId)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| recordId   | Id                          | The record ID of an `SObject` to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, SObject record)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| record     | SObject                     | The `SObject` record to log                                               |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage, List<SObject> records)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| records    | List<SObject>               | The list of `SObject` records to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(logMessage)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(LogMessage logMessage)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult | The instance of `Database.DeleteResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                             |
| --------------------- | ------------------------------ | ------------------------------------------------------- |
| message               | String                         | The string to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                       | Description                                             |
| ----------------- | -------------------------- | ------------------------------------------------------- |
| message           | String                     | The string to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                 | Description                                             |
| ----------- | -------------------- | ------------------------------------------------------- |
| message     | String               | The string to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult | The instance of `Database.MergeResult` to log           |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                | Description                                             |
| ---------- | ------------------- | ------------------------------------------------------- |
| message    | String              | The string to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult | The instance of `Database.SaveResult` to log            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                    | Description                                             |
| -------------- | ----------------------- | ------------------------------------------------------- |
| message        | String                  | The string to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult | The instance of `Database.UndeleteResult` to log        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult | The instance of `Database.UpsertResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The list of `Database.DeleteResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                   |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------- |
| message                | String                               | The string to use to set the entry&#x27;s message field       |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                               |
| ------------------ | -------------------------------- | --------------------------------------------------------- |
| message            | String                           | The string to use to set the entry&#x27;s message field   |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                       | Description                                             |
| ------------ | -------------------------- | ------------------------------------------------------- |
| message      | String                     | The string to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult> | The list of `Database.MergeResult` instances to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                      | Description                                             |
| ----------- | ------------------------- | ------------------------------------------------------- |
| message     | String                    | The string to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult> | The list of `Database.SaveResult` instances to log      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                             |
| --------------- | ----------------------------- | ------------------------------------------------------- |
| message         | String                        | The string to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The list of `Database.UndeleteResult` instances to log  |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The list of `Database.UpsertResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, Id recordId)
```

#### Parameters

| Name     | Type   | Description                                             |
| -------- | ------ | ------------------------------------------------------- |
| message  | String | The string to use to set the entry&#x27;s message field |
| recordId | Id     | The record ID of an `SObject` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, SObject record)
```

#### Parameters

| Name    | Type    | Description                                             |
| ------- | ------- | ------------------------------------------------------- |
| message | String  | The string to use to set the entry&#x27;s message field |
| record  | SObject | The `SObject` record to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message, List<SObject> records)
```

#### Parameters

| Name    | Type          | Description                                             |
| ------- | ------------- | ------------------------------------------------------- |
| message | String        | The string to use to set the entry&#x27;s message field |
| records | List<SObject> | The list of `SObject` records to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `fine(message)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINE`

#### Signature

```apex
global static LogEntryEventBuilder fine(String message)
```

#### Parameters

| Name    | Type   | Description                                             |
| ------- | ------ | ------------------------------------------------------- |
| message | String | The string to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult       | The instance of `Database.DeleteResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                                               |
| --------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| logMessage            | [LogMessage](LogMessage.md)    | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                        | Description                                                               |
| ----------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage        | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult  | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult        | The instance of `Database.MergeResult` to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult         | The instance of `Database.SaveResult` to log                              |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                        | Description                                                               |
| -------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage     | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult     | The instance of `Database.UndeleteResult` to log                          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult       | The instance of `Database.UpsertResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The instance of `List<Database.DeleteResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                               |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------------------- |
| logMessage             | [LogMessage](LogMessage.md)          | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                                               |
| ------------------ | -------------------------------- | ------------------------------------------------------------------------- |
| logMessage         | [LogMessage](LogMessage.md)      | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult>  | The instance of `List<Database.MergeResult>` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult>   | The instance of `List<Database.SaveResult>` to log                        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                                               |
| --------------- | ----------------------------- | ------------------------------------------------------------------------- |
| logMessage      | [LogMessage](LogMessage.md)   | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The instance of `List<Database.UndeleteResult>` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The instance of `List<Database.UpsertResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, Id recordId)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| recordId   | Id                          | The record ID of an `SObject` to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, SObject record)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| record     | SObject                     | The `SObject` record to log                                               |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage, List<SObject> records)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| records    | List<SObject>               | The list of `SObject` records to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(logMessage)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(LogMessage logMessage)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult | The instance of `Database.DeleteResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                             |
| --------------------- | ------------------------------ | ------------------------------------------------------- |
| message               | String                         | The string to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                       | Description                                             |
| ----------------- | -------------------------- | ------------------------------------------------------- |
| message           | String                     | The string to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                 | Description                                             |
| ----------- | -------------------- | ------------------------------------------------------- |
| message     | String               | The string to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult | The instance of `Database.MergeResult` to log           |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                | Description                                             |
| ---------- | ------------------- | ------------------------------------------------------- |
| message    | String              | The string to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult | The instance of `Database.SaveResult` to log            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                    | Description                                             |
| -------------- | ----------------------- | ------------------------------------------------------- |
| message        | String                  | The string to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult | The instance of `Database.UndeleteResult` to log        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult | The instance of `Database.UpsertResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The list of `Database.DeleteResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                   |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------- |
| message                | String                               | The string to use to set the entry&#x27;s message field       |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                               |
| ------------------ | -------------------------------- | --------------------------------------------------------- |
| message            | String                           | The string to use to set the entry&#x27;s message field   |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                       | Description                                             |
| ------------ | -------------------------- | ------------------------------------------------------- |
| message      | String                     | The string to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult> | The list of `Database.MergeResult` instances to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                      | Description                                             |
| ----------- | ------------------------- | ------------------------------------------------------- |
| message     | String                    | The string to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult> | The list of `Database.SaveResult` instances to log      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                             |
| --------------- | ----------------------------- | ------------------------------------------------------- |
| message         | String                        | The string to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The list of `Database.UndeleteResult` instances to log  |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The list of `Database.UpsertResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, Id recordId)
```

#### Parameters

| Name     | Type   | Description                                             |
| -------- | ------ | ------------------------------------------------------- |
| message  | String | The string to use to set the entry&#x27;s message field |
| recordId | Id     | The record ID of an `SObject` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, SObject record)
```

#### Parameters

| Name    | Type    | Description                                             |
| ------- | ------- | ------------------------------------------------------- |
| message | String  | The string to use to set the entry&#x27;s message field |
| record  | SObject | The `SObject` record to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message, List<SObject> records)
```

#### Parameters

| Name    | Type          | Description                                             |
| ------- | ------------- | ------------------------------------------------------- |
| message | String        | The string to use to set the entry&#x27;s message field |
| records | List<SObject> | The list of `SObject` records to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finer(message)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINER`

#### Signature

```apex
global static LogEntryEventBuilder finer(String message)
```

#### Parameters

| Name    | Type   | Description                                             |
| ------- | ------ | ------------------------------------------------------- |
| message | String | The string to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult       | The instance of `Database.DeleteResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                                               |
| --------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| logMessage            | [LogMessage](LogMessage.md)    | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                        | Description                                                               |
| ----------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage        | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult  | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult        | The instance of `Database.MergeResult` to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult         | The instance of `Database.SaveResult` to log                              |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                        | Description                                                               |
| -------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage     | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult     | The instance of `Database.UndeleteResult` to log                          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult       | The instance of `Database.UpsertResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The instance of `List<Database.DeleteResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                               |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------------------- |
| logMessage             | [LogMessage](LogMessage.md)          | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                                               |
| ------------------ | -------------------------------- | ------------------------------------------------------------------------- |
| logMessage         | [LogMessage](LogMessage.md)      | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult>  | The instance of `List<Database.MergeResult>` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult>   | The instance of `List<Database.SaveResult>` to log                        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                                               |
| --------------- | ----------------------------- | ------------------------------------------------------------------------- |
| logMessage      | [LogMessage](LogMessage.md)   | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The instance of `List<Database.UndeleteResult>` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The instance of `List<Database.UpsertResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, Id recordId)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| recordId   | Id                          | The record ID of an `SObject` to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, SObject record)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| record     | SObject                     | The `SObject` record to log                                               |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage, List<SObject> records)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| records    | List<SObject>               | The list of `SObject` records to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(logMessage)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(LogMessage logMessage)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult | The instance of `Database.DeleteResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                             |
| --------------------- | ------------------------------ | ------------------------------------------------------- |
| message               | String                         | The string to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                       | Description                                             |
| ----------------- | -------------------------- | ------------------------------------------------------- |
| message           | String                     | The string to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                 | Description                                             |
| ----------- | -------------------- | ------------------------------------------------------- |
| message     | String               | The string to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult | The instance of `Database.MergeResult` to log           |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                | Description                                             |
| ---------- | ------------------- | ------------------------------------------------------- |
| message    | String              | The string to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult | The instance of `Database.SaveResult` to log            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                    | Description                                             |
| -------------- | ----------------------- | ------------------------------------------------------- |
| message        | String                  | The string to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult | The instance of `Database.UndeleteResult` to log        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult | The instance of `Database.UpsertResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The list of `Database.DeleteResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                   |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------- |
| message                | String                               | The string to use to set the entry&#x27;s message field       |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                               |
| ------------------ | -------------------------------- | --------------------------------------------------------- |
| message            | String                           | The string to use to set the entry&#x27;s message field   |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                       | Description                                             |
| ------------ | -------------------------- | ------------------------------------------------------- |
| message      | String                     | The string to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult> | The list of `Database.MergeResult` instances to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                      | Description                                             |
| ----------- | ------------------------- | ------------------------------------------------------- |
| message     | String                    | The string to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult> | The list of `Database.SaveResult` instances to log      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                             |
| --------------- | ----------------------------- | ------------------------------------------------------- |
| message         | String                        | The string to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The list of `Database.UndeleteResult` instances to log  |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The list of `Database.UpsertResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, Id recordId)
```

#### Parameters

| Name     | Type   | Description                                             |
| -------- | ------ | ------------------------------------------------------- |
| message  | String | The string to use to set the entry&#x27;s message field |
| recordId | Id     | The record ID of an `SObject` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, SObject record)
```

#### Parameters

| Name    | Type    | Description                                             |
| ------- | ------- | ------------------------------------------------------- |
| message | String  | The string to use to set the entry&#x27;s message field |
| record  | SObject | The `SObject` record to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message, List<SObject> records)
```

#### Parameters

| Name    | Type          | Description                                             |
| ------- | ------------- | ------------------------------------------------------- |
| message | String        | The string to use to set the entry&#x27;s message field |
| records | List<SObject> | The list of `SObject` records to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `finest(message)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.FINEST`

#### Signature

```apex
global static LogEntryEventBuilder finest(String message)
```

#### Parameters

| Name    | Type   | Description                                             |
| ------- | ------ | ------------------------------------------------------- |
| message | String | The string to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `flushBuffer()`

Discards any entries that have been generated but not yet saved

#### Signature

```apex
global static void flushBuffer()
```

#### Return Type

**void**

---

### `getBufferSize()`

Returns the number of entries that have been generated but not yet saved

#### Signature

```apex
global static Integer getBufferSize()
```

#### Return Type

**Integer**

Integer

---

### `getCurrentQuiddity()`

Returns the System.Quiddity context of the current transaction.

#### Signature

```apex
global static System.Quiddity getCurrentQuiddity()
```

#### Return Type

**System.Quiddity**

System.Quiddity - The value of System.Request.getCurrent().getQuiddity()

---

### `getLoggingLevel(loggingLevelName)`

Converts a String to an instance of LoggingLevel

#### Signature

```apex
global static System.LoggingLevel getLoggingLevel(String loggingLevelName)
```

#### Parameters

| Name             | Type   | Description                              |
| ---------------- | ------ | ---------------------------------------- |
| loggingLevelName | String | The string name of an Apex logging level |

#### Return Type

**System.LoggingLevel**

The matching instance of System.LoggingLevel (or a default value if a match is not found)

---

### `getParentLogTransactionId()`

Returns the transaction ID value that will be used to relate the current transaction&#x27;s log to a parent log

#### Signature

```apex
global static String getParentLogTransactionId()
```

#### Return Type

**String**

String - The parent log&#x27;s transaction ID. This must be explicitly set by calling setParentLogTransactionId(String)

---

### `getSaveMethod()`

Returns the default save method used when calling saveLog() - set via LoggerSettings\_\_c or by calling setSaveMethod(SaveMethod saveMethod)

#### Signature

```apex
global static SaveMethod getSaveMethod()
```

#### Return Type

**SaveMethod**

The enum value of Logger.SaveMethod to use for any calls to saveLog() in the current transaction

---

### `getScenario()`

Returns the scenario name for the current transaction - this is stored in `LogEntryEvent__e.Scenario__c`
and `Log__c.Scenario__c` , and can be used to filter &amp; group logs

#### Signature

```apex
global static String getScenario()
```

#### Return Type

**String**

The value currently set as the current transaction&#x27;s scenario

---

### `getTransactionId()`

Returns the unique ID generated by Nebula Logger for a particular transaction.
This value is stored in `LogEntryEvent__e.TransactionId__c` and `Log__c.TransactionId__c` .

#### Signature

```apex
global static String getTransactionId()
```

#### Return Type

**String**

String - A `UUID` value generated by Nebula Logger, using `System.UUID.randomUUID().toString()`

---

### `getUserLoggingLevel()`

Returns the logging level for the current user, based on the custom setting LoggerSettings\_\_c

#### Signature

```apex
global static System.LoggingLevel getUserLoggingLevel()
```

#### Return Type

**System.LoggingLevel**

System.LoggingLevel - The matching instance of LoggingLevel

---

### `getVersionNumber()`

Returns the current version number of Nebula Logger

#### Signature

```apex
global static String getVersionNumber()
```

#### Return Type

**String**

The current version number, in the format `v0.0.0`

---

### `ignoreOrigin(apexType)`

Adds the specified Apex type to the list of ignored origin locations for the current transaction.
Any ignored types will be removed from the StackTrace\_\_c field, and will be skipped when determining
the log entry&#x27;s origin location

#### Signature

```apex
global static void ignoreOrigin(System.Type apexType)
```

#### Parameters

| Name     | Type        | Description                          |
| -------- | ----------- | ------------------------------------ |
| apexType | System.Type | The Apex type of the class to ignore |

#### Return Type

**void**

---

### `info(logMessage, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult       | The instance of `Database.DeleteResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                                               |
| --------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| logMessage            | [LogMessage](LogMessage.md)    | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                        | Description                                                               |
| ----------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage        | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult  | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult        | The instance of `Database.MergeResult` to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult         | The instance of `Database.SaveResult` to log                              |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                        | Description                                                               |
| -------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage     | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult     | The instance of `Database.UndeleteResult` to log                          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult       | The instance of `Database.UpsertResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The instance of `List<Database.DeleteResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                               |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------------------- |
| logMessage             | [LogMessage](LogMessage.md)          | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                                               |
| ------------------ | -------------------------------- | ------------------------------------------------------------------------- |
| logMessage         | [LogMessage](LogMessage.md)      | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult>  | The instance of `List<Database.MergeResult>` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult>   | The instance of `List<Database.SaveResult>` to log                        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                                               |
| --------------- | ----------------------------- | ------------------------------------------------------------------------- |
| logMessage      | [LogMessage](LogMessage.md)   | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The instance of `List<Database.UndeleteResult>` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The instance of `List<Database.UpsertResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, Id recordId)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| recordId   | Id                          | The record ID of an `SObject` to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, SObject record)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| record     | SObject                     | The `SObject` record to log                                               |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage, List<SObject> records)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| records    | List<SObject>               | The list of `SObject` records to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(logMessage)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(LogMessage logMessage)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult | The instance of `Database.DeleteResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                             |
| --------------------- | ------------------------------ | ------------------------------------------------------- |
| message               | String                         | The string to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                       | Description                                             |
| ----------------- | -------------------------- | ------------------------------------------------------- |
| message           | String                     | The string to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                 | Description                                             |
| ----------- | -------------------- | ------------------------------------------------------- |
| message     | String               | The string to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult | The instance of `Database.MergeResult` to log           |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                | Description                                             |
| ---------- | ------------------- | ------------------------------------------------------- |
| message    | String              | The string to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult | The instance of `Database.SaveResult` to log            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                    | Description                                             |
| -------------- | ----------------------- | ------------------------------------------------------- |
| message        | String                  | The string to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult | The instance of `Database.UndeleteResult` to log        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult | The instance of `Database.UpsertResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The list of `Database.DeleteResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                   |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------- |
| message                | String                               | The string to use to set the entry&#x27;s message field       |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                               |
| ------------------ | -------------------------------- | --------------------------------------------------------- |
| message            | String                           | The string to use to set the entry&#x27;s message field   |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                       | Description                                             |
| ------------ | -------------------------- | ------------------------------------------------------- |
| message      | String                     | The string to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult> | The list of `Database.MergeResult` instances to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                      | Description                                             |
| ----------- | ------------------------- | ------------------------------------------------------- |
| message     | String                    | The string to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult> | The list of `Database.SaveResult` instances to log      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                             |
| --------------- | ----------------------------- | ------------------------------------------------------- |
| message         | String                        | The string to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The list of `Database.UndeleteResult` instances to log  |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The list of `Database.UpsertResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, Id recordId)
```

#### Parameters

| Name     | Type   | Description                                             |
| -------- | ------ | ------------------------------------------------------- |
| message  | String | The string to use to set the entry&#x27;s message field |
| recordId | Id     | The record ID of an `SObject` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, SObject record)
```

#### Parameters

| Name    | Type    | Description                                             |
| ------- | ------- | ------------------------------------------------------- |
| message | String  | The string to use to set the entry&#x27;s message field |
| record  | SObject | The `SObject` record to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message, List<SObject> records)
```

#### Parameters

| Name    | Type          | Description                                             |
| ------- | ------------- | ------------------------------------------------------- |
| message | String        | The string to use to set the entry&#x27;s message field |
| records | List<SObject> | The list of `SObject` records to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `info(message)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.INFO`

#### Signature

```apex
global static LogEntryEventBuilder info(String message)
```

#### Parameters

| Name    | Type   | Description                                             |
| ------- | ------ | ------------------------------------------------------- |
| message | String | The string to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `isDebugEnabled()`

Indicates if logging level &#x27;DEBUG&#x27; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

#### Signature

```apex
global static Boolean isDebugEnabled()
```

#### Return Type

**Boolean**

Boolean

---

### `isEnabled()`

Indicates if logging has been enabled for the current user, based on the custom setting LoggerSettings\_\_c

#### Signature

```apex
global static Boolean isEnabled()
```

#### Return Type

**Boolean**

Boolean

---

### `isEnabled(loggingLevel)`

Indicates if logging for the specified logging level is enabled for the current user, based on the custom setting LoggerSettings\_\_c

#### Signature

```apex
global static Boolean isEnabled(System.LoggingLevel loggingLevel)
```

#### Parameters

| Name         | Type                | Description                  |
| ------------ | ------------------- | ---------------------------- |
| loggingLevel | System.LoggingLevel | - The logging level to check |

#### Return Type

**Boolean**

Boolean

---

### `isErrorEnabled()`

Indicates if logging level &#x27;ERROR&#x27; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

#### Signature

```apex
global static Boolean isErrorEnabled()
```

#### Return Type

**Boolean**

Boolean

---

### `isFineEnabled()`

Indicates if logging level &#x27;FINE&#x27; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

#### Signature

```apex
global static Boolean isFineEnabled()
```

#### Return Type

**Boolean**

Boolean

---

### `isFinerEnabled()`

Indicates if logging level &#x27;FINER&#x27; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

#### Signature

```apex
global static Boolean isFinerEnabled()
```

#### Return Type

**Boolean**

Boolean

---

### `isFinestEnabled()`

Indicates if logging level &#x27;FINEST&#x27; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

#### Signature

```apex
global static Boolean isFinestEnabled()
```

#### Return Type

**Boolean**

Boolean

---

### `isInfoEnabled()`

Indicates if logging level &#x27;INFO&#x27; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

#### Signature

```apex
global static Boolean isInfoEnabled()
```

#### Return Type

**Boolean**

Boolean

---

### `isSavingSuspended()`

Indicates if saving has been temporarily suspended for the current transaction

#### Signature

```apex
global static Boolean isSavingSuspended()
```

#### Return Type

**Boolean**

Boolean

---

### `isWarnEnabled()`

Indicates if logging level &#x27;WARN&#x27; is enabled for the current user, based on the custom setting LoggerSettings\_\_c

#### Signature

```apex
global static Boolean isWarnEnabled()
```

#### Return Type

**Boolean**

Boolean

---

### `logDatabaseErrors(loggingLevel, logMessage, deleteResults)`

Creates a log entry for any results within the provided `List<DeleteResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| loggingLevel  | System.LoggingLevel         | The logging level to use for the log entry                                |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The instance of `List<Database.DeleteResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, logMessage, deleteResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<DeleteResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.DeleteResult> deleteResults, List<SObject> records)
```

#### Parameters

| Name          | Type                        | Description                                                                                             |
| ------------- | --------------------------- | ------------------------------------------------------------------------------------------------------- |
| loggingLevel  | System.LoggingLevel         | The logging level to use for the log entry                                                              |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field                               |
| deleteResults | List<Database.DeleteResult> | The instance of `List<Database.DeleteResult>` to log                                                    |
| records       | List<SObject>               | The instance of `List<SObject>` that correspond to the instance of `List<Database.DeleteResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, deleteResults)`

Creates a log entry for any results within the provided `List<DeleteResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| loggingLevel  | System.LoggingLevel         | The logging level to use for the log entry              |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The instance of `List<Database.DeleteResult>` to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, deleteResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<DeleteResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.DeleteResult> deleteResults, List<SObject> records)
```

#### Parameters

| Name          | Type                        | Description                                                                                             |
| ------------- | --------------------------- | ------------------------------------------------------------------------------------------------------- |
| loggingLevel  | System.LoggingLevel         | The logging level to use for the log entry                                                              |
| message       | String                      | The string to use to set the entry&#x27;s message field                                                 |
| deleteResults | List<Database.DeleteResult> | The instance of `List<Database.DeleteResult>` to log                                                    |
| records       | List<SObject>               | The instance of `List<SObject>` that correspond to the instance of `List<Database.DeleteResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, logMessage, emptyRecycleBinResults)`

Creates a log entry for any results within the provided `List<EmptyRecycleBinResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                               |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------------------- |
| loggingLevel           | System.LoggingLevel                  | The logging level to use for the log entry                                |
| logMessage             | [LogMessage](LogMessage.md)          | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, logMessage, emptyRecycleBinResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<EmptyRecycleBinResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults, List<SObject> records)
```

#### Parameters

| Name                   | Type                                 | Description                                                               |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------------------- |
| loggingLevel           | System.LoggingLevel                  | The logging level to use for the log entry                                |
| logMessage             | [LogMessage](LogMessage.md)          | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log             |
| records                | List<SObject>                        | The instance of `List<SObject>` having info about the actual record       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, emptyRecycleBinResults)`

Creates a log entry for any results within the provided `List<EmptyRecycleBinResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                   |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------- |
| loggingLevel           | System.LoggingLevel                  | The logging level to use for the log entry                    |
| message                | String                               | The string to use to set the entry&#x27;s message field       |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, emptyRecycleBinResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<EmptyRecycleBinResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults, List<SObject> records)
```

#### Parameters

| Name                   | Type                                 | Description                                                         |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------------- |
| loggingLevel           | System.LoggingLevel                  | The logging level to use for the log entry                          |
| message                | String                               | The string to use to set the entry&#x27;s message field             |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log       |
| records                | List<SObject>                        | The instance of `List<SObject>` having info about the actual record |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, logMessage, leadConvertResults)`

Creates a log entry for any results within the provided `List<LeadConvertResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                                               |
| ------------------ | -------------------------------- | ------------------------------------------------------------------------- |
| loggingLevel       | System.LoggingLevel              | The logging level to use for the log entry                                |
| logMessage         | [LogMessage](LogMessage.md)      | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, logMessage, leadConvertResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<LeadConvertResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults, List<SObject> records)
```

#### Parameters

| Name               | Type                             | Description                                                               |
| ------------------ | -------------------------------- | ------------------------------------------------------------------------- |
| loggingLevel       | System.LoggingLevel              | The logging level to use for the log entry                                |
| logMessage         | [LogMessage](LogMessage.md)      | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log                 |
| records            | List<SObject>                    | The instance of `List<SObject>` having info about the actual record       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, leadConvertResults)`

Creates a log entry for any results within the provided `List<LeadConvertResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                               |
| ------------------ | -------------------------------- | --------------------------------------------------------- |
| loggingLevel       | System.LoggingLevel              | The logging level to use for the log entry                |
| message            | String                           | The string to use to set the entry&#x27;s message field   |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, leadConvertResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<LeadConvertResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.LeadConvertResult> leadConvertResults, List<SObject> records)
```

#### Parameters

| Name               | Type                             | Description                                                         |
| ------------------ | -------------------------------- | ------------------------------------------------------------------- |
| loggingLevel       | System.LoggingLevel              | The logging level to use for the log entry                          |
| message            | String                           | The string to use to set the entry&#x27;s message field             |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log           |
| records            | List<SObject>                    | The instance of `List<SObject>` having info about the actual record |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, logMessage, mergeResults)`

Creates a log entry for any results within the provided `List<MergeResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| loggingLevel | System.LoggingLevel         | The logging level to use for the log entry                                |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult>  | The instance of `List<Database.MergeResult>` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, logMessage, mergeResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<MergeResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.MergeResult> mergeResults, List<SObject> records)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| loggingLevel | System.LoggingLevel         | The logging level to use for the log entry                                |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult>  | The instance of `List<Database.MergeResult>` to log                       |
| records      | List<SObject>               | The instance of `List<SObject>` having info about the actual record       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, mergeResults)`

Creates a log entry for any results within the provided `List<MergeResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                       | Description                                             |
| ------------ | -------------------------- | ------------------------------------------------------- |
| loggingLevel | System.LoggingLevel        | The logging level to use for the log entry              |
| message      | String                     | The string to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult> | The instance of `List<Database.MergeResult>` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, mergeResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<MergeResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.MergeResult> mergeResults, List<SObject> records)
```

#### Parameters

| Name         | Type                       | Description                                                         |
| ------------ | -------------------------- | ------------------------------------------------------------------- |
| loggingLevel | System.LoggingLevel        | The logging level to use for the log entry                          |
| message      | String                     | The string to use to set the entry&#x27;s message field             |
| mergeResults | List<Database.MergeResult> | The instance of `List<Database.MergeResult>` to log                 |
| records      | List<SObject>              | The instance of `List<SObject>` having info about the actual record |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, logMessage, saveResults)`

Creates a log entry for any results within the provided `List<SaveResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| loggingLevel | System.LoggingLevel         | The logging level to use for the log entry                                |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResults  | List<Database.SaveResult>   | The instance of `List<Database.SaveResult>` to log                        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, logMessage, saveResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<SaveResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.SaveResult> saveResults, List<SObject> records)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| loggingLevel | System.LoggingLevel         | The logging level to use for the log entry                                |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResults  | List<Database.SaveResult>   | The instance of `List<Database.SaveResult>` to log                        |
| records      | List<SObject>               | The instance of `List<SObject>` having info about the actual record       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, saveResults)`

Creates a log entry for any results within the provided `List<SaveResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name         | Type                      | Description                                             |
| ------------ | ------------------------- | ------------------------------------------------------- |
| loggingLevel | System.LoggingLevel       | The logging level to use for the log entry              |
| message      | String                    | The string to use to set the entry&#x27;s message field |
| saveResults  | List<Database.SaveResult> | The instance of `List<Database.SaveResult>` to log      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, saveResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<SaveResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.SaveResult> saveResults, List<SObject> records)
```

#### Parameters

| Name         | Type                      | Description                                                         |
| ------------ | ------------------------- | ------------------------------------------------------------------- |
| loggingLevel | System.LoggingLevel       | The logging level to use for the log entry                          |
| message      | String                    | The string to use to set the entry&#x27;s message field             |
| saveResults  | List<Database.SaveResult> | The instance of `List<Database.SaveResult>` to log                  |
| records      | List<SObject>             | The instance of `List<SObject>` having info about the actual record |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, logMessage, upsertResults)`

Creates a log entry for any results within the provided `List<UpsertResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| loggingLevel  | System.LoggingLevel         | The logging level to use for the log entry                                |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The instance of `List<Database.UpsertResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, logMessage, upsertResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<UpsertResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.UpsertResult> upsertResults, List<SObject> records)
```

#### Parameters

| Name          | Type                        | Description                                                                                             |
| ------------- | --------------------------- | ------------------------------------------------------------------------------------------------------- |
| loggingLevel  | System.LoggingLevel         | The logging level to use for the log entry                                                              |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field                               |
| upsertResults | List<Database.UpsertResult> | The instance of `List<Database.UpsertResult>` to log                                                    |
| records       | List<SObject>               | The instance of `List<SObject>` that correspond to the instance of `List<Database.UpsertResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, upsertResults)`

Creates a log entry for any results within the provided `List<UpsertResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| loggingLevel  | System.LoggingLevel         | The logging level to use for the log entry              |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The instance of `List<Database.UpsertResult>` to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, upsertResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<UpsertResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.UpsertResult> upsertResults, List<SObject> records)
```

#### Parameters

| Name          | Type                        | Description                                                                                             |
| ------------- | --------------------------- | ------------------------------------------------------------------------------------------------------- |
| loggingLevel  | System.LoggingLevel         | The logging level to use for the log entry                                                              |
| message       | String                      | The string to use to set the entry&#x27;s message field                                                 |
| upsertResults | List<Database.UpsertResult> | The instance of `List<Database.UpsertResult>` to log                                                    |
| records       | List<SObject>               | The instance of `List<SObject>` that correspond to the instance of `List<Database.UpsertResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, logMessage, undeleteResults)`

Creates a log entry for any results within the provided `List<UndeleteResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                                               |
| --------------- | ----------------------------- | ------------------------------------------------------------------------- |
| loggingLevel    | System.LoggingLevel           | The logging level to use for the log entry                                |
| logMessage      | [LogMessage](LogMessage.md)   | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The instance of `List<Database.UndeleteResult>` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, logMessage, undeleteResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<UndeleteResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, LogMessage logMessage, List<Database.UndeleteResult> undeleteResults, List<SObject> records)
```

#### Parameters

| Name            | Type                          | Description                                                               |
| --------------- | ----------------------------- | ------------------------------------------------------------------------- |
| loggingLevel    | System.LoggingLevel           | The logging level to use for the log entry                                |
| logMessage      | [LogMessage](LogMessage.md)   | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The instance of `List<Database.UndeleteResult>` to log                    |
| records         | List<SObject>                 | The instance of `List<SObject>` having info about the actual record       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, undeleteResults)`

Creates a log entry for any results within the provided `List<UndeleteResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                             |
| --------------- | ----------------------------- | ------------------------------------------------------- |
| loggingLevel    | System.LoggingLevel           | The logging level to use for the log entry              |
| message         | String                        | The string to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The instance of `List<Database.UndeleteResult>` to log  |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `logDatabaseErrors(loggingLevel, message, undeleteResults, records)`

`SUPPRESSWARNINGS`

Creates a log entry for any results within the provided `List<UndeleteResult>` where `isSuccess() != true`

#### Signature

```apex
global static LogEntryEventBuilder logDatabaseErrors(System.LoggingLevel loggingLevel, String message, List<Database.UndeleteResult> undeleteResults, List<SObject> records)
```

#### Parameters

| Name            | Type                          | Description                                                         |
| --------------- | ----------------------------- | ------------------------------------------------------------------- |
| loggingLevel    | System.LoggingLevel           | The logging level to use for the log entry                          |
| message         | String                        | The string to use to set the entry&#x27;s message field             |
| undeleteResults | List<Database.UndeleteResult> | The instance of `List<Database.UndeleteResult>` to log              |
| records         | List<SObject>                 | The instance of `List<SObject>` having info about the actual record |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The instance of `LogEntryBuilder` was generated to log any errors, or `null` if there are no errors

---

### `meetsUserLoggingLevel(logEntryLoggingLevel)`

Indicates if the specified logging level is enabled for the current user, based on the custom setting LoggerSettings\_\_c

#### Signature

```apex
global static Boolean meetsUserLoggingLevel(System.LoggingLevel logEntryLoggingLevel)
```

#### Parameters

| Name                 | Type                | Description                 |
| -------------------- | ------------------- | --------------------------- |
| logEntryLoggingLevel | System.LoggingLevel | the logging level to check. |

#### Return Type

**Boolean**

Boolean

---

### `newEntry(loggingLevel, logMessage, shouldSave)`

`SUPPRESSWARNINGS`

Adds a new instance of LogEntryEventBuilder to Logger&#x27;s buffer, when `shouldSave` is `true`

#### Signature

```apex
global static LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel, LogMessage logMessage, Boolean shouldSave)
```

#### Parameters

| Name         | Type                        | Description                                                                                                                                                   |
| ------------ | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| loggingLevel | System.LoggingLevel         | The logging level enum value for the new entry                                                                                                                |
| logMessage   | [LogMessage](LogMessage.md) | The instance of LogMessage to use as the entry&#x27;s message                                                                                                 |
| shouldSave   | Boolean                     | Controls if the new entry will be saved. This can be used to save entries, even if the entry&#x27;s logging level does not meet the user&#x27;s logging level |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of LogEntryEventBuilder

---

### `newEntry(loggingLevel, logMessage)`

Adds a new instance of LogEntryEventBuilder to Logger&#x27;s buffer, if it meets the user&#x27;s logging level

#### Signature

```apex
global static LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel, LogMessage logMessage)
```

#### Parameters

| Name         | Type                        | Description                                                   |
| ------------ | --------------------------- | ------------------------------------------------------------- |
| loggingLevel | System.LoggingLevel         | The logging level enum value for the new entry                |
| logMessage   | [LogMessage](LogMessage.md) | The instance of LogMessage to use as the entry&#x27;s message |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of LogEntryEventBuilder

---

### `newEntry(loggingLevel, message, shouldSave)`

`SUPPRESSWARNINGS`

Adds a new instance of LogEntryEventBuilder to Logger&#x27;s buffer, if it meets the user&#x27;s logging level

#### Signature

```apex
global static LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel, String message, Boolean shouldSave)
```

#### Parameters

| Name         | Type                | Description                                                                                                                                                   |
| ------------ | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| loggingLevel | System.LoggingLevel | The logging level enum value for the new entry                                                                                                                |
| message      | String              | The string to use as the entry&#x27;s message                                                                                                                 |
| shouldSave   | Boolean             | Controls if the new entry will be saved. This can be used to save entries, even if the entry&#x27;s logging level does not meet the user&#x27;s logging level |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of LogEntryEventBuilder

---

### `newEntry(loggingLevel, message)`

Adds a new instance of LogEntryEventBuilder to Logger&#x27;s buffer, if it meets the user&#x27;s logging level

#### Signature

```apex
global static LogEntryEventBuilder newEntry(System.LoggingLevel loggingLevel, String message)
```

#### Parameters

| Name         | Type                | Description                                    |
| ------------ | ------------------- | ---------------------------------------------- |
| loggingLevel | System.LoggingLevel | The logging level enum value for the new entry |
| message      | String              | The string to use as the entry&#x27;s message  |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of LogEntryEventBuilder

---

### `resumeSaving()`

Resumes saving for the current transaction, used to reverse suspendSaving().
Any calls to saveLog() are ignored until saving is resumed.

#### Signature

```apex
global static void resumeSaving()
```

#### Return Type

**void**

---

### `saveLog()`

`INVOCABLEMETHOD`

Saves any entries in Logger&#x27;s buffer. By default, entries are saved via Apex&#x27;s EventBus and can be overridden with setSaveMethod(SaveMethod saveMethod)

#### Signature

```apex
global static void saveLog()
```

#### Return Type

**void**

---

### `saveLog(saveMethod)`

Saves any entries in Logger&#x27;s buffer, using the specified save method for only this call.
All subsequent calls to saveLog() will use the transaction save method.

#### Signature

```apex
global static void saveLog(SaveMethod saveMethod)
```

#### Parameters

| Name       | Type       | Description                                                               |
| ---------- | ---------- | ------------------------------------------------------------------------- |
| saveMethod | SaveMethod | The enum value of Logger.SaveMethod to use for this specific save action. |

#### Return Type

**void**

---

### `setAsyncContext(batchableContext)`

Stores additional details about the current transacation&#x27;s async context

#### Signature

```apex
global static void setAsyncContext(Database.BatchableContext batchableContext)
```

#### Parameters

| Name             | Type                      | Description                                            |
| ---------------- | ------------------------- | ------------------------------------------------------ |
| batchableContext | Database.BatchableContext | - The instance of `Database.BatchableContext` to track |

#### Return Type

**void**

---

### `setAsyncContext(finalizerContext)`

Stores additional details about the current transacation&#x27;s async context

#### Signature

```apex
global static void setAsyncContext(System.FinalizerContext finalizerContext)
```

#### Parameters

| Name             | Type                    | Description                                          |
| ---------------- | ----------------------- | ---------------------------------------------------- |
| finalizerContext | System.FinalizerContext | - The instance of `System.FinalizerContext` to track |

#### Return Type

**void**

---

### `setAsyncContext(queueableContext)`

Stores additional details about the current transacation&#x27;s async context

#### Signature

```apex
global static void setAsyncContext(System.QueueableContext queueableContext)
```

#### Parameters

| Name             | Type                    | Description                                          |
| ---------------- | ----------------------- | ---------------------------------------------------- |
| queueableContext | System.QueueableContext | - The instance of `System.QueueableContext` to track |

#### Return Type

**void**

---

### `setAsyncContext(schedulableContext)`

Stores additional details about the current transacation&#x27;s async context

#### Signature

```apex
global static void setAsyncContext(System.SchedulableContext schedulableContext)
```

#### Parameters

| Name               | Type                      | Description                                            |
| ------------------ | ------------------------- | ------------------------------------------------------ |
| schedulableContext | System.SchedulableContext | - The instance of `System.SchedulableContext` to track |

#### Return Type

**void**

---

### `setField(field, fieldValue)`

Sets a field value on every generated `LogEntryEvent__e` record

#### Signature

```apex
global static void setField(Schema.SObjectField field, Object fieldValue)
```

#### Parameters

| Name                                                         | Type                | Description                                              |
| ------------------------------------------------------------ | ------------------- | -------------------------------------------------------- |
| field                                                        | Schema.SObjectField | The `Schema.SObjectField` token of the field to populate |
| on each `LogEntryEvent__e` record in the current transaction |
| fieldValue                                                   | Object              | The `Object` value to populate in the provided field     |

#### Return Type

**void**

---

### `setField(fieldToValue)`

Sets multiple field values oon every generated `LogEntryEvent__e` record

#### Signature

```apex
global static void setField(Map<Schema.SObjectField,Object> fieldToValue)
```

#### Parameters

| Name                                                                                             | Type                            | Description                                                      |
| ------------------------------------------------------------------------------------------------ | ------------------------------- | ---------------------------------------------------------------- |
| fieldToValue                                                                                     | Map<Schema.SObjectField,Object> | An instance of `Map<Schema.SObjectField, Object>` containing the |
| the fields &amp; values to populate on each `LogEntryEvent__e` record in the current transaction |

#### Return Type

**void**

---

### `setParentLogTransactionId(parentTransactionId)`

Relates the current transaction&#x27;s log to a parent log via the field Log**c.ParentLog**c
This is useful for relating multiple asynchronous operations together, such as batch &amp; queueable jobs.

#### Signature

```apex
global static void setParentLogTransactionId(String parentTransactionId)
```

#### Parameters

| Name                | Type   | Description                                             |
| ------------------- | ------ | ------------------------------------------------------- |
| parentTransactionId | String | - The transaction ID of the original parent transaction |

#### Return Type

**void**

---

### `setSaveMethod(saveMethod)`

Sets the default save method used when calling saveLog() - any subsequent calls to saveLog() will use the specified save method

#### Signature

```apex
global static void setSaveMethod(SaveMethod saveMethod)
```

#### Parameters

| Name       | Type       | Description                                                                                            |
| ---------- | ---------- | ------------------------------------------------------------------------------------------------------ |
| saveMethod | SaveMethod | The enum value of Logger.SaveMethod to use for any other calls to saveLog() in the current transaction |

#### Return Type

**void**

---

### `setScenario(scenario)`

`SUPPRESSWARNINGS`

Sets the current scenario, which can be used to identify modules or groupings of for the current transaction

#### Signature

```apex
global static void setScenario(String scenario)
```

#### Parameters

| Name     | Type   | Description                                                 |
| -------- | ------ | ----------------------------------------------------------- |
| scenario | String | The name to use for the current transaction&#x27;s scenario |

#### Return Type

**void**

---

### `suspendSaving()`

Pauses saving for the current transaction.
Any calls to saveLog() are ignored until saving is resumed.

#### Signature

```apex
global static void suspendSaving()
```

#### Return Type

**void**

---

### `warn(logMessage, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult       | The instance of `Database.DeleteResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                                               |
| --------------------- | ------------------------------ | ------------------------------------------------------------------------- |
| logMessage            | [LogMessage](LogMessage.md)    | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                        | Description                                                               |
| ----------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage        | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult  | The instance of `Database.LeadConvertResult` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult        | The instance of `Database.MergeResult` to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult         | The instance of `Database.SaveResult` to log                              |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                        | Description                                                               |
| -------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage     | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult     | The instance of `Database.UndeleteResult` to log                          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult       | The instance of `Database.UpsertResult` to log                            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The instance of `List<Database.DeleteResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                               |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------------------- |
| logMessage             | [LogMessage](LogMessage.md)          | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                                               |
| ------------------ | -------------------------------- | ------------------------------------------------------------------------- |
| logMessage         | [LogMessage](LogMessage.md)      | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                        | Description                                                               |
| ------------ | --------------------------- | ------------------------------------------------------------------------- |
| logMessage   | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult>  | The instance of `List<Database.MergeResult>` to log                       |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                        | Description                                                               |
| ----------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage  | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult>   | The instance of `List<Database.SaveResult>` to log                        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                                               |
| --------------- | ----------------------------- | ------------------------------------------------------------------------- |
| logMessage      | [LogMessage](LogMessage.md)   | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The instance of `List<Database.UndeleteResult>` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The instance of `List<Database.UpsertResult>` to log                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, System.Exception apexException)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| apexException | System.Exception            | The instance of `System.Exception` to log                                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, recordId, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId, System.Exception apexException)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| recordId      | Id                          | The record ID of an `SObject` to log                                      |
| apexException | System.Exception            | The instance of `System.Exception` to log                                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, Id recordId)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| recordId   | Id                          | The record ID of an `SObject` to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, record, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, SObject record, System.Exception apexException)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| record        | SObject                     | The `SObject` record to log                                               |
| apexException | System.Exception            | The instance of `System.Exception` to log                                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, SObject record)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| record     | SObject                     | The `SObject` record to log                                               |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, records, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, List<SObject> records, System.Exception apexException)
```

#### Parameters

| Name          | Type                        | Description                                                               |
| ------------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage    | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| records       | List<SObject>               | The list of `SObject` records to log                                      |
| apexException | System.Exception            | The instance of `System.Exception` to log                                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage, List<SObject> records)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| records    | List<SObject>               | The list of `SObject` records to log                                      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(logMessage)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(LogMessage logMessage)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, deleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| deleteResult | Database.DeleteResult | The instance of `Database.DeleteResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, emptyRecycleBinResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                             |
| --------------------- | ------------------------------ | ------------------------------------------------------- |
| message               | String                         | The string to use to set the entry&#x27;s message field |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, leadConvertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                       | Description                                             |
| ----------------- | -------------------------- | ------------------------------------------------------- |
| message           | String                     | The string to use to set the entry&#x27;s message field |
| leadConvertResult | Database.LeadConvertResult | The instance of `Database.LeadConvertResult` to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, mergeResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                 | Description                                             |
| ----------- | -------------------- | ------------------------------------------------------- |
| message     | String               | The string to use to set the entry&#x27;s message field |
| mergeResult | Database.MergeResult | The instance of `Database.MergeResult` to log           |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, saveResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                | Description                                             |
| ---------- | ------------------- | ------------------------------------------------------- |
| message    | String              | The string to use to set the entry&#x27;s message field |
| saveResult | Database.SaveResult | The instance of `Database.SaveResult` to log            |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, undeleteResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                    | Description                                             |
| -------------- | ----------------------- | ------------------------------------------------------- |
| message        | String                  | The string to use to set the entry&#x27;s message field |
| undeleteResult | Database.UndeleteResult | The instance of `Database.UndeleteResult` to log        |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, upsertResult)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                  | Description                                             |
| ------------ | --------------------- | ------------------------------------------------------- |
| message      | String                | The string to use to set the entry&#x27;s message field |
| upsertResult | Database.UpsertResult | The instance of `Database.UpsertResult` to log          |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, deleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| deleteResults | List<Database.DeleteResult> | The list of `Database.DeleteResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, emptyRecycleBinResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                   |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------- |
| message                | String                               | The string to use to set the entry&#x27;s message field       |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The instance of `List<Database.EmptyRecycleBinResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, leadConvertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                               |
| ------------------ | -------------------------------- | --------------------------------------------------------- |
| message            | String                           | The string to use to set the entry&#x27;s message field   |
| leadConvertResults | List<Database.LeadConvertResult> | The instance of `List<Database.LeadConvertResult>` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, mergeResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                       | Description                                             |
| ------------ | -------------------------- | ------------------------------------------------------- |
| message      | String                     | The string to use to set the entry&#x27;s message field |
| mergeResults | List<Database.MergeResult> | The list of `Database.MergeResult` instances to log     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, saveResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                      | Description                                             |
| ----------- | ------------------------- | ------------------------------------------------------- |
| message     | String                    | The string to use to set the entry&#x27;s message field |
| saveResults | List<Database.SaveResult> | The list of `Database.SaveResult` instances to log      |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, undeleteResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                             |
| --------------- | ----------------------------- | ------------------------------------------------------- |
| message         | String                        | The string to use to set the entry&#x27;s message field |
| undeleteResults | List<Database.UndeleteResult> | The list of `Database.UndeleteResult` instances to log  |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, upsertResults)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                             |
| ------------- | --------------------------- | ------------------------------------------------------- |
| message       | String                      | The string to use to set the entry&#x27;s message field |
| upsertResults | List<Database.UpsertResult> | The list of `Database.UpsertResult` instances to log    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, System.Exception apexException)
```

#### Parameters

| Name          | Type             | Description                                             |
| ------------- | ---------------- | ------------------------------------------------------- |
| message       | String           | The string to use to set the entry&#x27;s message field |
| apexException | System.Exception | The instance of `System.Exception` to log               |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, recordId, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, Id recordId, System.Exception apexException)
```

#### Parameters

| Name          | Type             | Description                                             |
| ------------- | ---------------- | ------------------------------------------------------- |
| message       | String           | The string to use to set the entry&#x27;s message field |
| recordId      | Id               | The record ID of an `SObject` to log                    |
| apexException | System.Exception | The instance of `System.Exception` to log               |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, recordId)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, Id recordId)
```

#### Parameters

| Name     | Type   | Description                                             |
| -------- | ------ | ------------------------------------------------------- |
| message  | String | The string to use to set the entry&#x27;s message field |
| recordId | Id     | The record ID of an `SObject` to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, record, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, SObject record, System.Exception apexException)
```

#### Parameters

| Name          | Type             | Description                                             |
| ------------- | ---------------- | ------------------------------------------------------- |
| message       | String           | The string to use to set the entry&#x27;s message field |
| record        | SObject          | The `SObject` record to log                             |
| apexException | System.Exception | The instance of `System.Exception` to log               |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, record)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, SObject record)
```

#### Parameters

| Name    | Type    | Description                                             |
| ------- | ------- | ------------------------------------------------------- |
| message | String  | The string to use to set the entry&#x27;s message field |
| record  | SObject | The `SObject` record to log                             |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, records, apexException)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, List<SObject> records, System.Exception apexException)
```

#### Parameters

| Name          | Type             | Description                                                               |
| ------------- | ---------------- | ------------------------------------------------------------------------- |
| message       | String           | The instance of `LogMessage` to use to set the entry&#x27;s message field |
| records       | List<SObject>    | The list of `SObject` records to log                                      |
| apexException | System.Exception | The instance of `System.Exception` to log                                 |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message, records)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message, List<SObject> records)
```

#### Parameters

| Name    | Type          | Description                                             |
| ------- | ------------- | ------------------------------------------------------- |
| message | String        | The string to use to set the entry&#x27;s message field |
| records | List<SObject> | The list of `SObject` records to log                    |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `warn(message)`

Creates a new log entry with logging level &#x3D;&#x3D; `System.LoggingLevel.WARN`

#### Signature

```apex
global static LogEntryEventBuilder warn(String message)
```

#### Parameters

| Name    | Type   | Description                                             |
| ------- | ------ | ------------------------------------------------------- |
| message | String | The string to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The new entry&#x27;s instance of `LogEntryEventBuilder` , useful for chaining methods

## Classes

### QueueableSaver Class

Inner class for publishing log entries via the System.Queueable interface.

**Implements**

System.Queueable

#### Methods

##### `execute(queueableContext)`

Asynchronoulsy publishes the list of `LogEntryEvent__e` records

###### Signature

```apex
global void execute(System.QueueableContext queueableContext)
```

###### Parameters

| Name             | Type                    | Description                                                |
| ---------------- | ----------------------- | ---------------------------------------------------------- |
| queueableContext | System.QueueableContext | The context of the current queue, provided by the platform |

###### Return Type

**void**

## Enums

### SaveMethod Enum

Enum used to control how LogEntryEvent\_\_e records are inserted

#### Values

| Value           | Description |
| --------------- | ----------- |
| EVENT_BUS       |             |
| QUEUEABLE       |             |
| REST            |             |
| SYNCHRONOUS_DML |             |
