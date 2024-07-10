---
layout: default
---

## LoggerSettingsController class

Controller class for lwc `loggerSettings`, used to manage records in `LoggerSettings__c`

---

### Methods

#### `canUserModifyLoggerSettings()` → `Boolean`

Indicates if the current user has access to modify `LoggerSettings__c` records, based on either object-level access on `LoggerSettings__c`, or access to the custom permission `CanModifyLoggerSettings`

##### Return

**Type**

Boolean

**Description**

return description

#### `createRecord()` → `LoggerSettings__c`

Creates a new, unsaved `LoggerSettings__c` record

##### Return

**Type**

LoggerSettings\_\_c

**Description**

A new `LoggerSettings__c` record, with all fields populated with default values

#### `deleteRecord(LoggerSettings__c settingsRecord)` → `void`

Deletes the specified `LoggerSettings__c` record

##### Parameters

| Param            | Description          |
| ---------------- | -------------------- |
| `settingsRecord` | The record to delete |

#### `getOrganization()` → `Schema.Organization`

Returns the `Schema.Organization` record for the current environment

##### Return

**Type**

Schema.Organization

**Description**

The current environment&apos;s `Schema.Organization` record

#### `getPicklistOptions()` → `LoggerSettingsPicklistOptions`

Returns all of the `List&lt;PicklistOption&gt;` used in the frontend for displaying certain text fields as picklist fields

##### Return

**Type**

LoggerSettingsPicklistOptions

**Description**

The instance of `LoggerSettingsPicklistOptions`, containing all picklist options for any fields treated as picklists

#### `getRecords()` → `List<SettingsRecordResult>`

Returns all existing `LoggerSettings__c` records as instances of `SettingsRecordResult`

##### Return

**Type**

List&lt;SettingsRecordResult&gt;

**Description**

The list of existing records

#### `saveRecord(LoggerSettings__c settingsRecord)` → `void`

Upserts the specified `LoggerSettings__c` record

##### Parameters

| Param            | Description        |
| ---------------- | ------------------ |
| `settingsRecord` | The record to save |

#### `searchForSetupOwner(String setupOwnerType, String searchTerm)` → `List<SetupOwnerSearchResult>`

searchForSetupOwner description

##### Parameters

| Param            | Description                                              |
| ---------------- | -------------------------------------------------------- |
| `setupOwnerType` | The object to search (`Schema.Profile` or `Schema.User`) |
| `searchTerm`     | The search term to use when searching records            |

##### Return

**Type**

List&lt;SetupOwnerSearchResult&gt;

**Description**

The list of `SetupOwnerSearchResult`, based on any matching SObject records

---

### Inner Classes

#### LoggerSettingsController.LoggerSettingsPicklistOptions class

Inner class for returning all custom `List&lt;PicklistOption&gt;` in a single Apex method call

---

##### Properties

###### `loggingLevelOptions` → `List<PicklistOption>`

###### `platformEventStorageLocationOptions` → `List<PicklistOption>`

###### `purgeActionOptions` → `List<PicklistOption>`

###### `saveMethodOptions` → `List<PicklistOption>`

###### `setupOwnerTypeOptions` → `List<PicklistOption>`

###### `shareAccessLevelOptions` → `List<PicklistOption>`

---

#### LoggerSettingsController.PicklistOption class

Inner DTO class for picklist options since Schema.PicklistEntry isn&apos;t supported for aura-enabled methods

---

##### Properties

###### `label` → `String`

###### `value` → `String`

---

#### LoggerSettingsController.SettingsRecordResult class

Inner class used for sorting LoggerSettings\_\_c, used for 3 reasons: 1. Trying to sort in SOQL on SetupOwner.Type, SetupOwner.Name results in only user-specific records being returned (no idea why - seems like a bug) 2. Records tied to profiles do not return the actual profile name in SetupOwner.Name - example: System Admin returns as &apos;PT1&apos; in query results 3. Records tied to the org or profiles return unhelpful values in SetupOwner.Type - org returns &apos;00D&apos;, profiles return &apos;00e&apos;

---

##### Properties

###### `createdByUsername` → `String`

###### `lastModifiedByUsername` → `String`

###### `record` → `LoggerSettings__c`

###### `setupOwnerName` → `String`

###### `setupOwnerType` → `String`

---

##### Methods

###### `compareTo(Object compareTo)` → `Integer`

Implements sorting logic for the `System.Comparable` interface

####### Parameters

| Param       | Description                                            |
| ----------- | ------------------------------------------------------ |
| `compareTo` | The object to compare to when sorting the current item |

####### Return

**Type**

Integer

**Description**

The sorting result

---

#### LoggerSettingsController.SetupOwnerSearchResult class

Inner class used for returning search results for `Schema.Profile` and `Schema.User` records

---

##### Properties

###### `icon` → `String`

###### `image` → `String`

###### `label` → `String`

###### `recordId` → `Id`

###### `secondaryLabel` → `String`

---
