---
layout: default
---

## LoggerTestConfigurator class

Utility class used to help with setting up Nebula Logger&apos;s configurations within a test context. These methods are specific to metadata implemented within Nebula Logger. These methods can be used when writing Apex tests for plugins.

### Related

[LoggerMockDataCreator](../Test-Utilities/LoggerMockDataCreator)

[LoggerMockDataStore](../Test-Utilities/LoggerMockDataStore)

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

#### `getSObjectHandlerConfiguration(Schema.SObjectType sobjectType)` → `LoggerSObjectHandler_t`

Returns an instance of `LoggerSObjectHandler_t` that has been built &amp; configured for the specified `SObjectType`

##### Parameters

| Param         | Description                                                                             |
| ------------- | --------------------------------------------------------------------------------------- |
| `sobjectType` | The instance `SObjectType` to check for a configured instance of `LoggerSObjectHandler` |

##### Return

**Type**

LoggerSObjectHandler_t

**Description**

The ``LoggerSObjectHandler_t` record that has been configured for the specified `SObjectType` (if any)

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

#### `setMock(LoggerSObjectHandler_t mock)` → `void`

Loads the mock `LoggerSObjectHandler_t` during test execution

##### Parameters

| Param  | Description                                           |
| ------ | ----------------------------------------------------- |
| `mock` | The mock instance of `LoggerSObjectHandler_t` to load |

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

#### `setupMockSObjectHandlerConfigurations()` → `void`

Creates mock instances of `LoggerSObjectHandler_t` for each `SObjectType` used by Nebula Logger, with each `LoggerSObjectHandler_t` automatically set to `IsEnabled__c == true`

#### `setupMockSObjectHandlerConfigurations(Boolean isEnabled)` → `void`

Creates mock instances of `LoggerSObjectHandler_t` for each `SObjectType` used by Nebula Logger, with each `LoggerSObjectHandler_t` enabled/disabled based on the provided boolean

##### Parameters

| Param       | Description                                                                                                                |
| ----------- | -------------------------------------------------------------------------------------------------------------------------- |
| `isEnabled` | The Boolean value to control if all mock `LoggerSObjectHandler_t` records should be enabled (`true`) or disabled (`false`) |

---
