---
layout: default
---

## LogManagementDataSelector class

Selector class used for all queries that are specific to the log management layer

---

### Methods

#### `getAll(Schema.SObjectType sobjectType, Set<String> fieldNames)` → `List<SObject>`

Dynamically queries &amp; returns all records in the specified `SObjectType`

##### Parameters

| Param         | Description                                                         |
| ------------- | ------------------------------------------------------------------- |
| `sobjectType` | The `SObjectType` to query                                          |
| `fieldNames`  | `Set&lt;String&gt;` API names of any fields to include in the query |

##### Return

**Type**

List&lt;SObject&gt;

**Description**

`List&lt;SObject&gt;` containing any records in the specified `SObjectType`

#### `getApexClasses(List<String> apexClassNames)` → `List<ApexClass>`

Returns a list of `ApexClass` records

##### Parameters

| Param            | Description                            |
| ---------------- | -------------------------------------- |
| `apexClassNames` | The names of the Apex classes to query |

##### Return

**Type**

List&lt;ApexClass&gt;

**Description**

`List&lt;ApexClass&gt;` containing any matching records

#### `getById(Schema.SObjectType sobjectType, Set<String> fieldNames, List<Id> recordIds)` → `List<SObject>`

Dynamically queries &amp; returns records in the specified `SObjectType` based on the specified record IDs

##### Parameters

| Param         | Description                                                         |
| ------------- | ------------------------------------------------------------------- |
| `sobjectType` | The `SObjectType` to query                                          |
| `fieldNames`  | `Set&lt;String&gt;` API names of any fields to include in the query |
| `recordIds`   | `List&lt;Id&gt;` of record IDs to include in the query results      |

##### Return

**Type**

List&lt;SObject&gt;

**Description**

`List&lt;SObject&gt;` containing any matching records in the specified `SObjectType`

#### `getCachedApexEmailNotifications()` → `List<ApexEmailNotification>`

Returns a cached copy of the `ApexEmailNotification` records in the org

##### Return

**Type**

List&lt;ApexEmailNotification&gt;

**Description**

The cached `List&lt;ApexEmailNotification&gt;` records

#### `getCountOfAsyncApexJobs(String apexClassName, String apexMethodName, List<String> jobStatuses)` → `Integer`

Returns the count of `AsyncApexJob` records with the specified Apex class name, method name &amp; job status

##### Parameters

| Param            | Description                                                                       |
| ---------------- | --------------------------------------------------------------------------------- |
| `apexClassName`  | The fully-qualified name of the Apex class associated with `AsyncApexJob`         |
| `apexMethodName` | The specific method (if any) within the Apex class associated with `AsyncApexJob` |
| `jobStatuses`    | The list of job statuses that should be used to filter `AsynxApexJob` records     |

##### Return

**Type**

Integer

**Description**

The `Integer` count of matching `AsynxApexJob` records

#### `getCountOfRelatedRecordLogEntries(Id recordId)` → `Integer`

Returns the count of `LogEntry__c` records related to the specified record ID

##### Parameters

| Param      | Description                                         |
| ---------- | --------------------------------------------------- |
| `recordId` | The `ID` to use for filtering `LogEntry__c` records |

##### Return

**Type**

Integer

**Description**

The `Integer` count of matching `LogEntry__c` records

#### `getDeleteableUserRecordAccess(List<Id> recordIds)` → `List<UserRecordAccess>`

Returns the list of `UserRecordAccess` records for any of the specified record IDs that the current user can delete

##### Parameters

| Param       | Description                                |
| ----------- | ------------------------------------------ |
| `recordIds` | The list of `ID` for records to be deleted |

##### Return

**Type**

List&lt;UserRecordAccess&gt;

**Description**

The matching `List&lt;UserRecordAccess&gt;` records

#### `getFlowDefinitionViewsByFlowApiName(List<String> flowApiNames)` → `List<FlowDefinitionView>`

Returns a list of `FlowDefinitionView` records

##### Parameters

| Param          | Description                            |
| -------------- | -------------------------------------- |
| `flowApiNames` | The names of the Apex classes to query |

##### Return

**Type**

List&lt;FlowDefinitionView&gt;

**Description**

`List&lt;FlowDefinitionView&gt;` containing any matching records

#### `getFlowVersionViewsByDurableId(List<String> durableIds)` → `List<FlowVersionView>`

Returns a list of `FlowVersionView` records description

##### Parameters

| Param        | Description                           |
| ------------ | ------------------------------------- |
| `durableIds` | The durable IDs of the Flows to query |

##### Return

**Type**

List&lt;FlowVersionView&gt;

**Description**

`List&lt;FlowDefinitionView&gt;` containing any matching records

#### `getInstance()` → `LogManagementDataSelector`

The instance `LogManagementDataSelector` used for any querying specific to the log management layer

##### Return

**Type**

LogManagementDataSelector

**Description**

The singleton instance of `LogManagementDataSelector`

#### `getLogById(Id logId)` → `Log__c`

Returns a `Log__c` record and its related `LogEntry__c` records, using the relationship `LogEntries__r`

##### Parameters

| Param   | Description                              |
| ------- | ---------------------------------------- |
| `logId` | The `ID` of the `Log__c` record to query |

##### Return

**Type**

Log\_\_c

**Description**

The matching `Log__c` record

#### `getLoggerScenariosById(List<Id> logScenarioIds)` → `List<LoggerScenario__c>`

Returns a `List&lt;LoggerScenario__c&gt;` of records with the specified log scenario IDs

##### Parameters

| Param            | Description                                       |
| ---------------- | ------------------------------------------------- |
| `logScenarioIds` | The list of `ID` of the `Log__c` records to query |

##### Return

**Type**

List&lt;LoggerScenario\_\_c&gt;

**Description**

The list of matching `LoggerScenario__c` records

#### `getLogsById(List<Id> logIds)` → `List<Log__c>`

Returns a `Log__c` record and its related `LogEntry__c` records

##### Parameters

| Param    | Description                                       |
| -------- | ------------------------------------------------- |
| `logIds` | The list of `ID` of the `Log__c` records to query |

##### Return

**Type**

List&lt;Log\_\_c&gt;

**Description**

The list of matching `Log__c` records

#### `getLogsByTransactionId(List<String> transactionIds)` → `List<Log__c>`

Returns a `List&lt;Log__c&gt;` of records with the specified transaction IDs

##### Parameters

| Param            | Description                                                           |
| ---------------- | --------------------------------------------------------------------- |
| `transactionIds` | The list of `String` transaction IDs of the `Log__c` records to query |

##### Return

**Type**

List&lt;Log\_\_c&gt;

**Description**

The list of matching `Log__c` records

#### `getProfilesById(List<Id> profileIds)` → `List<Profile>`

Returns a `List&lt;Profile&gt;` of records with the specified profile IDs

##### Parameters

| Param        | Description                                        |
| ------------ | -------------------------------------------------- |
| `profileIds` | The list of `ID` of the `Profile` records to query |

##### Return

**Type**

List&lt;Profile&gt;

**Description**

The list of matching `Profile` records

#### `getProfilesByNameSearch(String searchTerm)` → `List<Profile>`

Returns a `List&lt;Profile&gt;` of records where the profile&apos;s names partially matches the specified search term

##### Parameters

| Param        | Description                                                     |
| ------------ | --------------------------------------------------------------- |
| `searchTerm` | The `String` search term to use for searching `Profile` records |

##### Return

**Type**

List&lt;Profile&gt;

**Description**

The list of matching `Profile` records

#### `getQueuesByDeveloperName(List<String> queueDeveloperNames)` → `List<Group>`

Returns a `List&lt;Group&gt;` of records with the specified developer names and type == &apos;Queue&apos;

##### Parameters

| Param                 | Description                                         |
| --------------------- | --------------------------------------------------- |
| `queueDeveloperNames` | The list of `String` queue developer names to query |

##### Return

**Type**

List&lt;Group&gt;

**Description**

The list of matching `Group` records

#### `getRecordLogEntries(Id recordId, String fieldsClause, String orderByClause, Integer rowLimit)` → `List<LogEntry__c>`

Returns the list of `LogEntry__c` records related to the specified record ID

##### Parameters

| Param           | Description                                                                        |
| --------------- | ---------------------------------------------------------------------------------- |
| `recordId`      | The `ID` to use for filtering `LogEntry__c` records                                |
| `fieldsClause`  | A comma-separated `String` of field API names to include in the query              |
| `orderByClause` | A comma-separated `String` of field API names to use for sorting the query results |
| `rowLimit`      | The maximum number of records to return                                            |

##### Return

**Type**

List&lt;LogEntry\_\_c&gt;

**Description**

The list of matching `LogEntry__c` records

#### `getTagsByName(Set<String> tagNames)` → `List<LoggerTag__c>`

Returns a list of `LoggerTag__c` records with one of the specified tag names

##### Parameters

| Param      | Description                            |
| ---------- | -------------------------------------- |
| `tagNames` | The set of `String` tag names to query |

##### Return

**Type**

List&lt;LoggerTag\_\_c&gt;

**Description**

The list of matching `LoggerTag__c` records

#### `getTopicsByName(Set<String> topicNames)` → `List<Topic>`

Returns a list of `Topic` records with one of the specified topic names

##### Parameters

| Param        | Description                              |
| ------------ | ---------------------------------------- |
| `topicNames` | The set of `String` topic names to query |

##### Return

**Type**

List&lt;Topic&gt;

**Description**

The list of matching `Topic` records

#### `getUsersById(List<Id> userIds)` → `List<User>`

Returns a `List&lt;User&gt;` of records with the specified user IDs

##### Parameters

| Param     | Description                                     |
| --------- | ----------------------------------------------- |
| `userIds` | The list of `ID` of the `User` records to query |

##### Return

**Type**

List&lt;User&gt;

**Description**

The list of matching `User` records

#### `getUsersByNameSearch(String searchTerm)` → `List<User>`

Returns a `List&lt;User&gt;` of records where the User&apos;s names or username partially matches the specified search term

##### Parameters

| Param        | Description                                                  |
| ------------ | ------------------------------------------------------------ |
| `searchTerm` | The `String` search term to use for searching `User` records |

##### Return

**Type**

List&lt;User&gt;

**Description**

The list of matching `User` records

#### `getUsersByUsername(List<String> usernames)` → `List<User>`

Returns a `List&lt;User&gt;` of records with the specified usernames (`Schema.User.Username`)

##### Parameters

| Param       | Description                                  |
| ----------- | -------------------------------------------- |
| `usernames` | The list of `String` user usernames to query |

##### Return

**Type**

List&lt;User&gt;

**Description**

Tje list of matching `User` records

---
