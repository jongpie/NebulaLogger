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

#### `createBatchableContext(String jobId)` → `MockBatchableContext`

Creates an instance of the class `MockBatchableContext` that implements the interface `Database.BatchableContext`. This can be used when testing batch jobs.

##### Parameters

| Param   | Description                                                                             |
| ------- | --------------------------------------------------------------------------------------- |
| `jobId` | A string value to use as the batchable job ID - this can be a true ID, or just a string |

##### Return

**Type**

MockBatchableContext

**Description**

The instance of `MockBatchableContext`

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

#### `createDatabaseDeleteResult(Boolean isSuccess)` → `Database.DeleteResult`

Creates a mock instance of `Database.DeleteResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` == true |

##### Return

**Type**

Database.DeleteResult

**Description**

The mock instance of `Database.DeleteResult`

#### `createDatabaseDeleteResult(Boolean isSuccess, Id recordId)` → `Database.DeleteResult`

Creates a mock instance of `Database.DeleteResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` == true |
| `recordId`  | The record ID to use within the mock result                     |

##### Return

**Type**

Database.DeleteResult

**Description**

The mock instance of `Database.DeleteResult`

#### `createDatabaseMergeResult(Boolean isSuccess)` → `Database.MergeResult`

Creates a mock instance of `Database.MergeResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` == true |

##### Return

**Type**

Database.MergeResult

**Description**

The mock instance of `Database.MergeResult`

#### `createDatabaseMergeResult(Boolean isSuccess, Id recordId)` → `Database.MergeResult`

Creates a mock instance of `Database.MergeResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` == true |
| `recordId`  | The record ID to use within the mock result                     |

##### Return

**Type**

Database.MergeResult

**Description**

The mock instance of `Database.MergeResult`

#### `createDatabaseSaveResult(Boolean isSuccess)` → `Database.SaveResult`

Creates a mock instance of `Database.SaveResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` == true |

##### Return

**Type**

Database.SaveResult

**Description**

The mock instance of `Database.SaveResult`

#### `createDatabaseSaveResult(Boolean isSuccess, Id recordId)` → `Database.SaveResult`

Creates a mock instance of `Database.SaveResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` == true |
| `recordId`  | The record ID to use within the mock result                     |

##### Return

**Type**

Database.SaveResult

**Description**

The mock instance of `Database.SaveResult`

#### `createDatabaseUndeleteResult(Boolean isSuccess)` → `Database.UndeleteResult`

Creates a mock instance of `Database.UndeleteResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` == true |

##### Return

**Type**

Database.UndeleteResult

**Description**

The mock instance of `Database.UndeleteResult`

#### `createDatabaseUndeleteResult(Boolean isSuccess, Id recordId)` → `Database.UndeleteResult`

Creates a mock instance of `Database.UndeleteResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` == true |
| `recordId`  | The record ID to use within the mock result                     |

##### Return

**Type**

Database.UndeleteResult

**Description**

The mock instance of `Database.UndeleteResult`

#### `createDatabaseUpsertResult(Boolean isSuccess, Boolean isCreated)` → `Database.UpsertResult`

Creates a mock instance of `Database.UpsertResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` == true |
| `isCreated` | Indicates if the generated mock should have `isCreated` == true |

##### Return

**Type**

Database.UpsertResult

**Description**

The mock instance of `Database.UpsertResult`

#### `createDatabaseUpsertResult(Boolean isSuccess, Boolean isCreated, Id recordId)` → `Database.UpsertResult`

Creates a mock instance of `Database.UpsertResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` == true |
| `isCreated` | Indicates if the generated mock should have `isCreated` == true |
| `recordId`  | The record ID to use within the mock result                     |

##### Return

**Type**

Database.UpsertResult

**Description**

The mock instance of `Database.UpsertResult`

#### `createHttpCallout()` → `MockHttpCallout`

Generates an instance of the class `MockHttpCallout` that implements the interface `HttpCalloutMock`. This can be used when testing batch jobs.

##### Return

**Type**

MockHttpCallout

**Description**

The instance of `MockHttpCallout`

#### `createHttpRequest()` → `HttpRequest`

Generates an instance of `HttpRequest`. This can be used when testing logging capabilities for instances of `HttpRequest`.

##### Return

**Type**

HttpRequest

**Description**

The instance of `HttpRequest`

#### `createHttpResponse()` → `HttpResponse`

Generates an instance of `HttpResponse`. This can be used when testing logging capabilities for instances of `HttpResponse`.

##### Return

**Type**

HttpResponse

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

#### `createUser()` → `User`

Creates a `User` record for testing purposes, using the current user&apos;s profile

##### Return

**Type**

User

**Description**

The generated `User` record - it is not automatically inserted into the database.

#### `createUser(Id profileId)` → `User`

Creates a `User` record for testing purposes, using the specified profile ID

##### Parameters

| Param       | Description                                    |
| ----------- | ---------------------------------------------- |
| `profileId` | The `Profile` ID to use for the created `User` |

##### Return

**Type**

User

**Description**

The generated `User` record - it is not automatically inserted into the database.

#### `getNetwork()` → `SObject`

Returns the current user&apos;s `Network` (Experience Cloud site)

##### Return

**Type**

SObject

**Description**

The matching `Network` record

#### `getOrganization()` → `Organization`

Queries for the `Organization` record for the current environment.

##### Return

**Type**

Organization

**Description**

The matching `Organization` record

#### `getOrganizationEnvironmentType()` → `String`

Returns the current environment&apos;s type - Scratch Org, Sandbox, or Production.

##### Return

**Type**

String

**Description**

The environment type

#### `getUser()` → `User`

Returns the current user

##### Return

**Type**

User

**Description**

The matching `User` record

#### `getUser(Id userId)` → `User`

Returns the specified user

##### Parameters

| Param    | Description                          |
| -------- | ------------------------------------ |
| `userId` | The ID of the `User` record to query |

##### Return

**Type**

User

**Description**

The matching `User` record

#### `insertQueue(String queueDeveloperName, Schema.SObjectType sobjectType)` → `Group`

Creates and inserts a `Group` record for testing queues, using the specified SObject Type

##### Parameters

| Param                | Description                                                                                   |
| -------------------- | --------------------------------------------------------------------------------------------- |
| `queueDeveloperName` | The developer name to use for the new queue (stored in `Group.DeveloperName`)                 |
| `sobjectType`        | The `SObjectType` that the queue should be able to own (stored in `QueueSObject.SObjectType`) |

##### Return

**Type**

Group

**Description**

The inserted `Group` record - it is automatically inserted into the database, as well as 1 child `QueueSObject` record.

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

###### `MockBatchableContext(String jobId)`

###### `MockBatchableContext(String jobId, Id childJobId)`

---

##### Methods

###### `getChildJobId()` → `String`

###### `getJobId()` → `String`

---

#### LoggerMockDataCreator.MockHttpCallout class

---

##### Constructors

###### `MockHttpCallout()`

---

##### Properties

###### `request` → `HttpRequest`

###### `response` → `HttpResponse`

###### `responseBody` → `String`

###### `statusCode` → `Integer`

---

##### Methods

###### `respond(HttpRequest request)` → `HttpResponse`

###### `setResponseBody(String responseBody)` → `MockHttpCallout`

###### `setStatusCode(Integer statusCode)` → `MockHttpCallout`

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
