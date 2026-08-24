---
title: LogEntryEventBuilder
description: 'Nebula Logger class reference: LogEntryEventBuilder.'
---

# LogEntryEventBuilder Class

`SUPPRESSWARNINGS`

Builder class that generates each `LogEntryEvent__e` record

**Group** Logger Engine

**See** [Logger](Logger.md)

## Methods

### `addTag(tag)`

Appends the tag to the existing list of tags

#### Signature

```apex
global LogEntryEventBuilder addTag(String tag)
```

#### Parameters

| Name | Type   | Description                                      |
| ---- | ------ | ------------------------------------------------ |
| tag  | String | The string to use as a tag for the current entry |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `addTags(tags)`

Appends the tag to the existing list of tags

#### Signature

```apex
global LogEntryEventBuilder addTags(List<String> tags)
```

#### Parameters

| Name | Type         | Description                                              |
| ---- | ------------ | -------------------------------------------------------- |
| tags | List<String> | The list of strings to use as tags for the current entry |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `getLogEntryEvent()`

Returns the `LogEntryEvent__e` record for this instance of LogEntryEventBuilder

#### Signature

```apex
global LogEntryEvent__e getLogEntryEvent()
```

#### Return Type

**[LogEntryEvent\_\_e](..\custom-objects\LogEntryEvent__e.md)**

The `LogEntryEvent__e` record

---

### `parseStackTrace(stackTraceString)`

`SUPPRESSWARNINGS`

Parses the provided stack trace and sets the log entry&#x27;s origin &amp; stack trace fields

#### Signature

```apex
global LogEntryEventBuilder parseStackTrace(String stackTraceString)
```

#### Parameters

| Name             | Type   | Description                          |
| ---------------- | ------ | ------------------------------------ |
| stackTraceString | String | The Apex stack trace string to parse |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setApprovalResult(lockResult)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setApprovalResult(Approval.LockResult lockResult)
```

#### Parameters

| Name       | Type                | Description                                  |
| ---------- | ------------------- | -------------------------------------------- |
| lockResult | Approval.LockResult | The instance of `Approval.LockResult` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setApprovalResult(processResult)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setApprovalResult(Approval.ProcessResult processResult)
```

#### Parameters

| Name          | Type                   | Description                                     |
| ------------- | ---------------------- | ----------------------------------------------- |
| processResult | Approval.ProcessResult | The instance of `Approval.ProcessResult` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setApprovalResult(unlockResult)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setApprovalResult(Approval.UnlockResult unlockResult)
```

#### Parameters

| Name         | Type                  | Description                                    |
| ------------ | --------------------- | ---------------------------------------------- |
| unlockResult | Approval.UnlockResult | The instance of `Approval.UnlockResult` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setApprovalResult(lockResults)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setApprovalResult(List<Approval.LockResult> lockResults)
```

#### Parameters

| Name        | Type                      | Description                                        |
| ----------- | ------------------------- | -------------------------------------------------- |
| lockResults | List<Approval.LockResult> | The list of `Approval.LockResult` instances to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setApprovalResult(processResults)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setApprovalResult(List<Approval.ProcessResult> processResults)
```

#### Parameters

| Name           | Type                         | Description                                           |
| -------------- | ---------------------------- | ----------------------------------------------------- |
| processResults | List<Approval.ProcessResult> | The list of `Approval.ProcessResult` instances to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setApprovalResult(unlockResults)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setApprovalResult(List<Approval.UnlockResult> unlockResults)
```

#### Parameters

| Name          | Type                        | Description                                          |
| ------------- | --------------------------- | ---------------------------------------------------- |
| unlockResults | List<Approval.UnlockResult> | The list of `Approval.UnlockResult` instances to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(deleteResult)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(Database.DeleteResult deleteResult)
```

#### Parameters

| Name         | Type                  | Description                                    |
| ------------ | --------------------- | ---------------------------------------------- |
| deleteResult | Database.DeleteResult | The instance of `Database.DeleteResult` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(emptyRecycleBinResult)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(Database.EmptyRecycleBinResult emptyRecycleBinResult)
```

#### Parameters

| Name                  | Type                           | Description                                             |
| --------------------- | ------------------------------ | ------------------------------------------------------- |
| emptyRecycleBinResult | Database.EmptyRecycleBinResult | The instance of `Database.EmptyRecycleBinResult` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(leadConvertResult)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(Database.LeadConvertResult leadConvertResult)
```

#### Parameters

| Name              | Type                       | Description                                         |
| ----------------- | -------------------------- | --------------------------------------------------- |
| leadConvertResult | Database.LeadConvertResult | The instance of `Database.LeadConvertResult` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(mergeResult)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(Database.MergeResult mergeResult)
```

#### Parameters

| Name        | Type                 | Description                                   |
| ----------- | -------------------- | --------------------------------------------- |
| mergeResult | Database.MergeResult | The instance of `Database.MergeResult` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(saveResult)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(Database.SaveResult saveResult)
```

#### Parameters

| Name       | Type                | Description                                  |
| ---------- | ------------------- | -------------------------------------------- |
| saveResult | Database.SaveResult | The instance of `Database.SaveResult` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(upsertResult)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(Database.UpsertResult upsertResult)
```

#### Parameters

| Name         | Type                  | Description                                    |
| ------------ | --------------------- | ---------------------------------------------- |
| upsertResult | Database.UpsertResult | The instance of `Database.UpsertResult` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(undeleteResult)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(Database.UndeleteResult undeleteResult)
```

#### Parameters

| Name           | Type                    | Description                                      |
| -------------- | ----------------------- | ------------------------------------------------ |
| undeleteResult | Database.UndeleteResult | The instance of `Database.UndeleteResult` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(deleteResults)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(List<Database.DeleteResult> deleteResults)
```

#### Parameters

| Name          | Type                        | Description                                          |
| ------------- | --------------------------- | ---------------------------------------------------- |
| deleteResults | List<Database.DeleteResult> | The list of `Database.DeleteResult` instances to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(emptyRecycleBinResults)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(List<Database.EmptyRecycleBinResult> emptyRecycleBinResults)
```

#### Parameters

| Name                   | Type                                 | Description                                                   |
| ---------------------- | ------------------------------------ | ------------------------------------------------------------- |
| emptyRecycleBinResults | List<Database.EmptyRecycleBinResult> | The list of `Database.EmptyRecycleBinResult` instances to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(leadConvertResults)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(List<Database.LeadConvertResult> leadConvertResults)
```

#### Parameters

| Name               | Type                             | Description                                       |
| ------------------ | -------------------------------- | ------------------------------------------------- |
| leadConvertResults | List<Database.LeadConvertResult> | The list of `Database.LeadConvertResult` s to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(mergeResults)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(List<Database.MergeResult> mergeResults)
```

#### Parameters

| Name         | Type                       | Description                                         |
| ------------ | -------------------------- | --------------------------------------------------- |
| mergeResults | List<Database.MergeResult> | The list of `Database.MergeResult` instances to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(saveResults)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(List<Database.SaveResult> saveResults)
```

#### Parameters

| Name        | Type                      | Description                                        |
| ----------- | ------------------------- | -------------------------------------------------- |
| saveResults | List<Database.SaveResult> | The list of `Database.SaveResult` instances to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(upsertResults)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(List<Database.UpsertResult> upsertResults)
```

#### Parameters

| Name          | Type                        | Description                                          |
| ------------- | --------------------------- | ---------------------------------------------------- |
| upsertResults | List<Database.UpsertResult> | The list of `Database.UpsertResult` instances to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setDatabaseResult(undeleteResults)`

Sets the log entry event&#x27;s database operation result fields

#### Signature

```apex
global LogEntryEventBuilder setDatabaseResult(List<Database.UndeleteResult> undeleteResults)
```

#### Parameters

| Name            | Type                          | Description                                            |
| --------------- | ----------------------------- | ------------------------------------------------------ |
| undeleteResults | List<Database.UndeleteResult> | The list of `Database.UndeleteResult` instances to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setExceptionDetails(apexException)`

Sets the log entry event&#x27;s exception fields

#### Signature

```apex
global LogEntryEventBuilder setExceptionDetails(System.Exception apexException)
```

#### Parameters

| Name          | Type             | Description                                   |
| ------------- | ---------------- | --------------------------------------------- |
| apexException | System.Exception | The instance of an `System.Exception` to use. |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setField(field, fieldValue)`

Sets a field value on the builder&#x27;s `LogEntryEvent__e` record

#### Signature

```apex
global LogEntryEventBuilder setField(Schema.SObjectField field, Object fieldValue)
```

#### Parameters

| Name                                            | Type                | Description                                              |
| ----------------------------------------------- | ------------------- | -------------------------------------------------------- |
| field                                           | Schema.SObjectField | The `Schema.SObjectField` token of the field to populate |
| on the builder&#x27;s `LogEntryEvent__e` record |
| fieldValue                                      | Object              | The `Object` value to populate in the provided field     |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setField(fieldToValue)`

`SUPPRESSWARNINGS`

Sets multiple field values on the builder&#x27;s `LogEntryEvent__e` record

#### Signature

```apex
global LogEntryEventBuilder setField(Map<Schema.SObjectField,Object> fieldToValue)
```

#### Parameters

| Name                                                                                | Type                            | Description                                                      |
| ----------------------------------------------------------------------------------- | ------------------------------- | ---------------------------------------------------------------- |
| fieldToValue                                                                        | Map<Schema.SObjectField,Object> | An instance of `Map<Schema.SObjectField, Object>` containing the |
| the fields &amp; values to populate on the builder&#x27;s `LogEntryEvent__e` record |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setHttpRequestDetails(request)`

Sets the log entry event&#x27;s HTTP Request fields

#### Signature

```apex
global LogEntryEventBuilder setHttpRequestDetails(System.HttpRequest request)
```

#### Parameters

| Name    | Type               | Description                          |
| ------- | ------------------ | ------------------------------------ |
| request | System.HttpRequest | The instance of `HttpRequest` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setHttpRequestDetails(request, headersToLog)`

Sets the log entry event&#x27;s HTTP Request fields

#### Signature

```apex
global LogEntryEventBuilder setHttpRequestDetails(System.HttpRequest request, List<String> headersToLog)
```

#### Parameters

| Name         | Type               | Description                                                     |
| ------------ | ------------------ | --------------------------------------------------------------- |
| request      | System.HttpRequest | The instance of `HttpRequest` to log                            |
| headersToLog | List<String>       | An instance of `List<String>` containing the header keys to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setHttpResponseDetails(response)`

Sets the log entry event&#x27;s HTTP Response fields

#### Signature

```apex
global LogEntryEventBuilder setHttpResponseDetails(System.HttpResponse response)
```

#### Parameters

| Name     | Type                | Description                           |
| -------- | ------------------- | ------------------------------------- |
| response | System.HttpResponse | The instance of `HttpResponse` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setMessage(logMessage)`

Sets the log entry event&#x27;s message field

#### Signature

```apex
global LogEntryEventBuilder setMessage(LogMessage logMessage)
```

#### Parameters

| Name       | Type                        | Description                                                               |
| ---------- | --------------------------- | ------------------------------------------------------------------------- |
| logMessage | [LogMessage](LogMessage.md) | The instance of `LogMessage` to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setMessage(message)`

Sets the log entry event&#x27;s message field

#### Signature

```apex
global LogEntryEventBuilder setMessage(String message)
```

#### Parameters

| Name    | Type   | Description                                             |
| ------- | ------ | ------------------------------------------------------- |
| message | String | The string to use to set the entry&#x27;s message field |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setRecord(recordId)`

Sets the log entry event&#x27;s record fields

#### Signature

```apex
global LogEntryEventBuilder setRecord(Id recordId)
```

#### Parameters

| Name     | Type | Description                                       |
| -------- | ---- | ------------------------------------------------- |
| recordId | Id   | The ID of the SObject record related to the entry |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setRecord(record)`

Sets the log entry event&#x27;s record fields

#### Signature

```apex
global LogEntryEventBuilder setRecord(SObject record)
```

#### Parameters

| Name   | Type    | Description                                                                                           |
| ------ | ------- | ----------------------------------------------------------------------------------------------------- |
| record | SObject | The `SObject` record related to the entry. The JSON of the record is automatically added to the entry |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setRecord(records)`

Sets the log entry event&#x27;s record fields

#### Signature

```apex
global LogEntryEventBuilder setRecord(List<SObject> records)
```

#### Parameters

| Name    | Type          | Description                                                                                                  |
| ------- | ------------- | ------------------------------------------------------------------------------------------------------------ |
| records | List<SObject> | The list of `SObject` records related to the entry. The JSON of the list is automatically added to the entry |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setRecord(recordIdToRecord)`

Sets the log entry event&#x27;s record fields

#### Signature

```apex
global LogEntryEventBuilder setRecord(Map<Id,SObject> recordIdToRecord)
```

#### Parameters

| Name             | Type            | Description                                                                                                |
| ---------------- | --------------- | ---------------------------------------------------------------------------------------------------------- |
| recordIdToRecord | Map<Id,SObject> | The map of `SObject` records related to the entry. The JSON of the map is automatically added to the entry |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setRecord(recordIds)`

Sets the log entry event&#x27;s record fields

#### Signature

```apex
global LogEntryEventBuilder setRecord(System.Iterable<Id> recordIds)
```

#### Parameters

| Name      | Type                | Description                                                                                                                                   |
| --------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| recordIds | System.Iterable<Id> | The Set of `SObject` records ids related to the entry. Will be converted to list and the JSON of the list is automatically added to the entry |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setRecordId(recordId)`

Deprecated - use `setRecord(Id recordId)` instead

#### Signature

```apex
global LogEntryEventBuilder setRecordId(Id recordId)
```

#### Parameters

| Name     | Type | Description                  |
| -------- | ---- | ---------------------------- |
| recordId | Id   | The id of the record to set. |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

An instance of LogEntryEventBuilder with a record associated wit recordId.

---

### `setRecordId(record)`

Deprecated - use `setRecord(SObject record)` instead

#### Signature

```apex
global LogEntryEventBuilder setRecordId(SObject record)
```

#### Parameters

| Name   | Type    | Description        |
| ------ | ------- | ------------------ |
| record | SObject | the record to set. |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

An instance of LogEntryEventBuilder with the given record.

---

### `setRestRequestDetails(request)`

Sets the log entry event&#x27;s REST Request fields

#### Signature

```apex
global LogEntryEventBuilder setRestRequestDetails(System.RestRequest request)
```

#### Parameters

| Name    | Type               | Description                                 |
| ------- | ------------------ | ------------------------------------------- |
| request | System.RestRequest | The instance of `System.RestRequest` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods

---

### `setRestResponseDetails(response)`

Sets the log entry event&#x27;s REST Response fields

#### Signature

```apex
global LogEntryEventBuilder setRestResponseDetails(System.RestResponse response)
```

#### Parameters

| Name     | Type                | Description                                  |
| -------- | ------------------- | -------------------------------------------- |
| response | System.RestResponse | The instance of `System.RestResponse` to log |

#### Return Type

**[LogEntryEventBuilder](LogEntryEventBuilder.md)**

The same instance of `LogEntryEventBuilder` , useful for chaining methods
