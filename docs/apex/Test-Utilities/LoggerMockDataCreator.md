---
layout: default
---

## LoggerMockDataCreator class

Utility class used to help with generating mock data when writing Apex tests for Nebula Logger. These methods are generic, and should work in any Salesforce org. These methods can be used when writing Apex tests for plugins.

### Related

[LoggerMockDataStore](../Test-Utilities/LoggerMockDataStore)

[LoggerTestConfigurator](../Test-Utilities/LoggerTestConfigurator)

---

### Methods

#### `createAggregateResult()` → `AggregateResult`

Instances of `AggregateResult` can not be created directly in Apex. This method uses a workaround to generate a mock, although it will not have any fields or aggregate values populated on the object.

##### Return

**Type**

AggregateResult

**Description**

The mock instance of `AggregateResult`

#### `createDataBuilder(Schema.SObjectType sobjectType)` → `SObjectTestDataBuilder`

Creates a new builder instance for the specified `SObjectType`, including creating a new `SObject` record. The new `SObject` record is created with any default field values that have been configured on the `SObjectType`.

##### Parameters

| Param         | Description                                                         |
| ------------- | ------------------------------------------------------------------- |
| `sobjectType` | The `SObjectType` to use for generating a new test `SObject` record |

##### Return

**Type**

SObjectTestDataBuilder

**Description**

A new instance of `SObjectTestDataBuilder` for the specified `SObjectType`

#### `createDataBuilder(SObject record)` → `SObjectTestDataBuilder`

Creates a new builder instance for the specified `SObject` record

##### Parameters

| Param    | Description                                                     |
| -------- | --------------------------------------------------------------- |
| `record` | The existing test `SObject` record to populate with sample data |

##### Return

**Type**

SObjectTestDataBuilder

**Description**

A new instance of `SObjectTestDataBuilder` for the specified `SObject`

#### `createApprovalLockResult(Boolean isSuccess)` → `Approval.LockResult`

Creates a mock instance of `Approval.LockResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |

##### Return

**Type**

Approval.LockResult

**Description**

The mock instance of `Approval.LockResult`

#### `createApprovalLockResult(Boolean isSuccess, Id recordId)` → `Approval.LockResult`

Creates a mock instance of `Approval.LockResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |
| `recordId`  | The record ID to use within the mock result             |

##### Return

**Type**

Approval.LockResult

**Description**

The mock instance of `Approval.LockResult`

#### `createApprovalProcessResult(Boolean isSuccess)` → `Approval.ProcessResult`

Creates a mock instance of `Approval.ProcessResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |

##### Return

**Type**

Approval.ProcessResult

**Description**

The mock instance of `Approval.ProcessResult`

#### `createApprovalProcessResult(Boolean isSuccess, Id recordId)` → `Approval.ProcessResult`

Creates a mock instance of `Approval.ProcessResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |
| `recordId`  | The record ID to use within the mock result             |

##### Return

**Type**

Approval.ProcessResult

**Description**

The mock instance of `Approval.ProcessResult`

#### `createApprovalUnlockResult(Boolean isSuccess)` → `Approval.UnlockResult`

Creates a mock instance of `Approval.UnlockResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |

##### Return

**Type**

Approval.UnlockResult

**Description**

The mock instance of `Approval.UnlockResult`

#### `createApprovalUnlockResult(Boolean isSuccess, Id recordId)` → `Approval.UnlockResult`

Creates a mock instance of `Approval.UnlockResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |
| `recordId`  | The record ID to use within the mock result             |

##### Return

**Type**

Approval.UnlockResult

**Description**

The mock instance of `Approval.UnlockResult`

#### `createDatabaseDeleteResult(Boolean isSuccess)` → `Database.DeleteResult`

Creates a mock instance of `Database.DeleteResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |

##### Return

**Type**

Database.DeleteResult

**Description**

The mock instance of `Database.DeleteResult`

#### `createDatabaseDeleteResult(Boolean isSuccess, Id recordId)` → `Database.DeleteResult`

Creates a mock instance of `Database.DeleteResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |
| `recordId`  | The record ID to use within the mock result             |

##### Return

**Type**

Database.DeleteResult

**Description**

The mock instance of `Database.DeleteResult`

#### `createDatabaseEmptyRecycleBinResult(Boolean isSuccess)` → `Database.EmptyRecycleBinResult`

Creates a mock instance of `Database.EmptyRecycleBinResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |

##### Return

**Type**

Database.EmptyRecycleBinResult

**Description**

The mock instance of `Database.EmptyRecycleBinResult`

#### `createDatabaseEmptyRecycleBinResult(Boolean isSuccess, Id recordId)` → `Database.EmptyRecycleBinResult`

Creates a mock instance of `Database.EmptyRecycleBinResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |
| `recordId`  | The record ID to use within the mock result             |

##### Return

**Type**

Database.EmptyRecycleBinResult

**Description**

The mock instance of `Database.EmptyRecycleBinResult`

#### `createDatabaseLeadConvertResult(Boolean isSuccess)` → `Database.LeadConvertResult`

Creates a mock instance of `Database.LeadConvertResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |

##### Return

**Type**

Database.LeadConvertResult

**Description**

The mock instance of `Database.LeadConvertResult`

#### `createDatabaseLeadConvertResult(Boolean isSuccess, Id recordId)` → `Database.LeadConvertResult`

Creates a mock instance of `Database.LeadConvertResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |
| `recordId`  | The record ID to use within the mock result             |

##### Return

**Type**

Database.LeadConvertResult

**Description**

The mock instance of `Database.LeadConvertResult`

#### `createDatabaseMergeResult(Boolean isSuccess)` → `Database.MergeResult`

Creates a mock instance of `Database.MergeResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |

##### Return

**Type**

Database.MergeResult

**Description**

The mock instance of `Database.MergeResult`

#### `createDatabaseMergeResult(Boolean isSuccess, Id recordId)` → `Database.MergeResult`

Creates a mock instance of `Database.MergeResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |
| `recordId`  | The record ID to use within the mock result             |

##### Return

**Type**

Database.MergeResult

**Description**

The mock instance of `Database.MergeResult`

#### `createDatabaseSaveResult(Boolean isSuccess)` → `Database.SaveResult`

Creates a mock instance of `Database.SaveResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |

##### Return

**Type**

Database.SaveResult

**Description**

The mock instance of `Database.SaveResult`

#### `createDatabaseSaveResult(Boolean isSuccess, Id recordId)` → `Database.SaveResult`

Creates a mock instance of `Database.SaveResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |
| `recordId`  | The record ID to use within the mock result             |

##### Return

**Type**

Database.SaveResult

**Description**

The mock instance of `Database.SaveResult`

#### `createDatabaseUndeleteResult(Boolean isSuccess)` → `Database.UndeleteResult`

Creates a mock instance of `Database.UndeleteResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |

##### Return

**Type**

Database.UndeleteResult

**Description**

The mock instance of `Database.UndeleteResult`

#### `createDatabaseUndeleteResult(Boolean isSuccess, Id recordId)` → `Database.UndeleteResult`

Creates a mock instance of `Database.UndeleteResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |
| `recordId`  | The record ID to use within the mock result             |

##### Return

**Type**

Database.UndeleteResult

**Description**

The mock instance of `Database.UndeleteResult`

#### `createDatabaseUpsertResult(Boolean isSuccess, Boolean isCreated)` → `Database.UpsertResult`

Creates a mock instance of `Database.UpsertResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |
| `isCreated` | Indicates if the generated mock should have `isCreated` |

##### Return

**Type**

Database.UpsertResult

**Description**

The mock instance of `Database.UpsertResult`

#### `createDatabaseUpsertResult(Boolean isSuccess, Boolean isCreated, Id recordId)` → `Database.UpsertResult`

Creates a mock instance of `Database.UpsertResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                             |
| ----------- | ------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` |
| `isCreated` | Indicates if the generated mock should have `isCreated` |
| `recordId`  | The record ID to use within the mock result             |

##### Return

**Type**

Database.UpsertResult

**Description**

The mock instance of `Database.UpsertResult`

#### `createHttpCallout()` → `MockHttpCallout`

Generates an instance of the class `MockHttpCallout` that implements the interface `System.HttpCalloutMock`. This can be used when testing batch jobs.

##### Return

**Type**

MockHttpCallout

**Description**

The instance of `MockHttpCallout`

#### `createHttpRequest()` → `System.HttpRequest`

Generates an instance of `HttpRequest`. This can be used when testing logging capabilities for instances of `HttpRequest`.

##### Return

**Type**

System.HttpRequest

**Description**

The instance of `HttpRequest`

#### `createHttpResponse()` → `System.HttpResponse`

Generates an instance of `HttpResponse`. This can be used when testing logging capabilities for instances of `HttpResponse`.

##### Return

**Type**

System.HttpResponse

**Description**

The instance of `HttpResponse`

#### `createId(Schema.SObjectType sobjectType)` → `String`

Generates a mock record ID for the provided SObject Type

##### Parameters

| Param         | Description                                       |
| ------------- | ------------------------------------------------- |
| `sobjectType` | The SObject Type for the generated mock record ID |

##### Return

**Type**

String

**Description**

The mock record ID for the specified SObject Type

#### `createUser()` → `Schema.User`

Creates a `Schema.User` record for testing purposes, using the current user&apos;s profile

##### Return

**Type**

Schema.User

**Description**

The generated `Schema.User` record - it is not automatically inserted into the database.

#### `createUser(Id profileId)` → `Schema.User`

Creates a `Schema.User` record for testing purposes, using the specified profile ID

##### Parameters

| Param       | Description                                                  |
| ----------- | ------------------------------------------------------------ |
| `profileId` | The `Schema.Profile` ID to use for the created `Schema.User` |

##### Return

**Type**

Schema.User

**Description**

The generated `Schema.User` record - it is not automatically inserted into the database.

#### `getOrganization()` → `Schema.Organization`

Queries for the `Schema.Organization` record for the current environment.

##### Return

**Type**

Schema.Organization

**Description**

The matching `Schema.Organization` record

#### `getOrganizationEnvironmentType()` → `String`

Returns the current environment&apos;s type - Scratch Org, Sandbox, or Production.

##### Return

**Type**

String

**Description**

The environment type

#### `getUser()` → `Schema.User`

Returns the current user

##### Return

**Type**

Schema.User

**Description**

The matching `Schema.User` record

#### `getUser(Id userId)` → `Schema.User`

Returns the specified user

##### Parameters

| Param    | Description                                 |
| -------- | ------------------------------------------- |
| `userId` | The ID of the `Schema.User` record to query |

##### Return

**Type**

Schema.User

**Description**

The matching `Schema.User` record

#### `insertQueue(String queueDeveloperName, Schema.SObjectType sobjectType)` → `Schema.Group`

Creates and inserts a `Schema.Group` record for testing queues, using the specified SObject Type

##### Parameters

| Param                | Description                                                                                   |
| -------------------- | --------------------------------------------------------------------------------------------- |
| `queueDeveloperName` | The developer name to use for the new queue (stored in `Schema.Group.DeveloperName`)          |
| `sobjectType`        | The `SObjectType` that the queue should be able to own (stored in `QueueSObject.SObjectType`) |

##### Return

**Type**

Schema.Group

**Description**

The inserted `Schema.Group` record - it is automatically inserted into the database, as well as 1 child `QueueSObject` record.

#### `setReadOnlyField(SObject record, Schema.SObjectField field, Object value)` → `SObject`

Sets a value for read-only fields that typically cannot be directly set on some SObjects

##### Parameters

| Param    | Description                                                 |
| -------- | ----------------------------------------------------------- |
| `record` | The `SObject` record to update                              |
| `field`  | The `Schema.SObjectField` for the field to update           |
| `value`  | The field value to populate on the provied `SObject` record |

##### Return

**Type**

SObject

**Description**

A new copy of the original `SObject` record that has the specified read-only field populated

#### `setReadOnlyField(SObject record, Map<Schema.SObjectField, Object> changesToFields)` → `SObject`

Sets values for read-only fields that typically cannot be directly set on some SObjects

##### Parameters

| Param             | Description                                                                                              |
| ----------------- | -------------------------------------------------------------------------------------------------------- |
| `record`          | record description                                                                                       |
| `changesToFields` | An instance of `Map&lt;Schema.SObjectField, Object&gt; containing the read-only fields and corresponding |

##### Return

**Type**

SObject

**Description**

A new copy of the original `SObject` record that has the specified read-only fields populated

---

### Inner Classes

#### LoggerMockDataCreator.MockBatchableContext class

---

##### Constructors

###### `MockBatchableContext()`

###### `MockBatchableContext(Id jobId)`

###### `MockBatchableContext(Id jobId, Id childJobId)`

---

##### Methods

###### `getChildJobId()` → `Id`

###### `getJobId()` → `Id`

---

#### LoggerMockDataCreator.MockFinalizerContext class

---

##### Constructors

###### `MockFinalizerContext()`

###### `MockFinalizerContext(Id asyncApexJobId)`

###### `MockFinalizerContext(Exception ex)`

---

##### Methods

###### `getAsyncApexJobId()` → `Id`

###### `getException()` → `Exception`

###### `getRequestId()` → `String`

###### `getResult()` → `System.ParentJobResult`

---

#### LoggerMockDataCreator.MockHttpCallout class

---

##### Constructors

###### `MockHttpCallout()`

---

##### Properties

###### `request` → `System.HttpRequest`

###### `response` → `System.HttpResponse`

###### `responseBody` → `String`

###### `statusCode` → `Integer`

###### `statusMessage` → `String`

---

##### Methods

###### `respond(System.HttpRequest request)` → `System.HttpResponse`

###### `setResponseBody(String responseBody)` → `MockHttpCallout`

###### `setStatus(String statusMessage)` → `MockHttpCallout`

###### `setStatusCode(Integer statusCode)` → `MockHttpCallout`

---

#### LoggerMockDataCreator.MockQueueableContext class

---

##### Constructors

###### `MockQueueableContext()`

###### `MockQueueableContext(Id jobId)`

---

##### Methods

###### `getJobId()` → `Id`

---

#### LoggerMockDataCreator.MockSchedulableContext class

---

##### Constructors

###### `MockSchedulableContext()`

###### `MockSchedulableContext(Id triggerId)`

---

##### Methods

###### `getTriggerId()` → `Id`

---

#### LoggerMockDataCreator.SObjectTestDataBuilder class

Class used to create or update an `SObject` record with static fake data. This is useful in situations where you need to have fields populated, but the specific values used are not relevant to a particular test method. This class can be used when Apex writing tests for plugins.

---

##### Methods

###### `getRecord()` → `SObject`

Returns the builder&apos;s `SObject` record with fields populated based on which builder methods have been called

####### Return

**Type**

SObject

**Description**

The builder&apos;s `SObject` record that was either provided by the calling code, or generated

###### `populateAllFields()` → `SObjectTestDataBuilder`

Sets a value on all editable fields, unless the `SObject` record already had a value specified for a field (including `null`)

####### Return

**Type**

SObjectTestDataBuilder

**Description**

The `SObject` record, with all editable fields populated

###### `populateMockId()` → `SObjectTestDataBuilder`

Generates a mock record ID for the builder&apos;s `SObject` record

####### Parameters

| Param         | Description                                                         |
| ------------- | ------------------------------------------------------------------- |
| `sobjectType` | The `SObjectType` to use for generating a new test `SObject` record |
| `record`      | The existing test `SObject` record to populate with sample data     |

####### Return

**Type**

SObjectTestDataBuilder

**Description**

The same instance of `SObjectTestDataBuilder`, useful for chaining methods

###### `populateRequiredFields()` → `SObjectTestDataBuilder`

Sets a value on all editable required fields, unless the `SObject` record already had a value specified for a field (including `null`)

####### Return

**Type**

SObjectTestDataBuilder

**Description**

The `SObject` record, with all editable required fields populated

---
