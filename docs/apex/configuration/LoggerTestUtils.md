---
layout: default
---

## LoggerTestUtils class

Utility class used to help with writing Apex tests Nebula Logger. These methods can be used when writing Apex tests for plugins.

### Related

[LoggerSObjectTestDataGenerator](LoggerSObjectTestDataGenerator)

---

### Methods

#### `assignAdminPermissionSet(Id userId)` → `void`

Assigns the permission set `LoggerAdmin` to the specified user ID

##### Parameters

| Param    | Description                                                   |
| -------- | ------------------------------------------------------------- |
| `userId` | The ID of the user that should be assigned the permission set |

#### `assignEndUserPermissionSet(Id userId)` → `void`

Assigns the permission set `LoggerEndUser` to the specified user ID

##### Parameters

| Param    | Description                                                   |
| -------- | ------------------------------------------------------------- |
| `userId` | The ID of the user that should be assigned the permission set |

#### `assignLogCreatorPermissionSet(Id userId)` → `void`

Assigns the permission set `LoggerLogCreator` to the specified user ID

##### Parameters

| Param    | Description                                                   |
| -------- | ------------------------------------------------------------- |
| `userId` | The ID of the user that should be assigned the permission set |

#### `assignLogViewerPermissionSet(Id userId)` → `void`

Assigns the permission set `LoggerLogViewer` to the specified user ID

##### Parameters

| Param    | Description                                                   |
| -------- | ------------------------------------------------------------- |
| `userId` | The ID of the user that should be assigned the permission set |

#### `createMockAggregateResult()` → `AggregateResult`

Instances of `AggregateResult` can not be created directly in Apex. This method uses a workaround to generate a mock.

##### Return

**Type**

AggregateResult

**Description**

The mock instance of `AggregateResult`

#### `createMockAggregateResult(Map<String, Object> mockAggregateKeyValues)` → `AggregateResult`

Instances of `AggregateResult` can not be created directly in Apex. This method uses a workaround to generate a mock, using the provided map of aliases &amp; aggregate values

##### Parameters

| Param                    | Description                                                                             |
| ------------------------ | --------------------------------------------------------------------------------------- |
| `mockAggregateKeyValues` | A map of aliases &amp; aggregate values to use when creating the mock `AggregateResult` |

##### Return

**Type**

AggregateResult

**Description**

The mock instance of `AggregateResult`

#### `createMockDatabaseDeleteResult(Boolean isSuccess)` → `Database.DeleteResult`

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

#### `createMockDatabaseDeleteResult(Boolean isSuccess, Id recordId)` → `Database.DeleteResult`

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

#### `createMockDatabaseMergeResult(Boolean isSuccess)` → `Database.MergeResult`

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

#### `createMockDatabaseMergeResult(Boolean isSuccess, Id recordId)` → `Database.MergeResult`

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

#### `createMockDatabaseSaveResult(Boolean isSuccess)` → `Database.SaveResult`

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

#### `createMockDatabaseSaveResult(Boolean isSuccess, Id recordId)` → `Database.SaveResult`

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

#### `createMockDatabaseUndeleteResult(Boolean isSuccess)` → `Database.UndeleteResult`

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

#### `createMockDatabaseUndeleteResult(Boolean isSuccess, Id recordId)` → `Database.UndeleteResult`

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

#### `createMockDatabaseUpsertResult(Boolean isSuccess)` → `Database.UpsertResult`

Creates a mock instance of `Database.UpsertResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests). A fake record ID is automatically included.

##### Parameters

| Param       | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` == true |

##### Return

**Type**

Database.UpsertResult

**Description**

The mock instance of `Database.UpsertResult`

#### `createMockDatabaseUpsertResult(Boolean isSuccess, Id recordId)` → `Database.UpsertResult`

Creates a mock instance of `Database.UpsertResult` - a mock is used instead of an actual instance to help speed up tests, and to support writing unit tests (instead of integration tests)

##### Parameters

| Param       | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `isSuccess` | Indicates if the generated mock should have `isSuccess` == true |
| `recordId`  | The record ID to use within the mock result                     |

##### Return

**Type**

Database.UpsertResult

**Description**

The mock instance of `Database.UpsertResult`

#### `createMockId(Schema.SObjectType sobjectType)` → `String`

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

#### `insertQueue(Schema.SObjectType sobjectType)` → `Group`

Creates and inserts a `Group` record for testing queues, using the specified SObject Type

##### Parameters

| Param         | Description                                                                     |
| ------------- | ------------------------------------------------------------------------------- |
| `sobjectType` | The SObjectType that the queue should be able to own (stored in `QueueSObject`) |

##### Return

**Type**

Group

**Description**

The inserted `Group` record - it is automatically inserted into the database, as well as 1 child `QueueSObject` record.

#### `setMock(LogEntryDataMaskRule_t mock)` → `void`

Loads the mock `LogEntryDataMaskRule_t` during test execution

##### Parameters

| Param  | Description                                           |
| ------ | ----------------------------------------------------- |
| `mock` | The mock instance of `LogEntryDataMaskRule_t` to load |

#### `setMock(LogEntryTagRule_t mock)` → `void`

Loads the mock `LogEntryTagRule_t` during test execution

##### Parameters

| Param  | Description                                      |
| ------ | ------------------------------------------------ |
| `mock` | The mock instance of `LogEntryTagRule_t` to load |

#### `setMock(LoggerParameter_t mock)` → `void`

Loads the mock `LoggerParameter_t` during test execution

##### Parameters

| Param  | Description                                      |
| ------ | ------------------------------------------------ |
| `mock` | The mock instance of `LoggerParameter_t` to load |

#### `setMock(LoggerPlugin_t mock)` → `void`

Loads the mock `LoggerPlugin_t` during test execution

##### Parameters

| Param  | Description                                   |
| ------ | --------------------------------------------- |
| `mock` | The mock instance of `LoggerPlugin_t` to load |

#### `setMock(LogScenarioRule_t mock)` → `void`

Loads the mock `LogScenarioRule_t` during test execution

##### Parameters

| Param  | Description                                      |
| ------ | ------------------------------------------------ |
| `mock` | The mock instance of `LogScenarioRule_t` to load |

#### `setMock(LogStatus_t mock)` → `void`

Loads the mock `LogStatus_t` during test execution

##### Parameters

| Param  | Description                                |
| ------ | ------------------------------------------ |
| `mock` | The mock instance of `LogStatus_t` to load |

---
