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

#### `getApexClasses(Set<String> apexClassNames)` → `List<Schema.ApexClass>`

Returns a list of `Schema.ApexClass` records

##### Parameters

| Param            | Description                            |
| ---------------- | -------------------------------------- |
| `apexClassNames` | The names of the Apex classes to query |

##### Return

**Type**

List&lt;Schema.ApexClass&gt;

**Description**

`List&lt;Schema.ApexClass&gt;` containing any matching records

#### `getApexTriggers(Set<String> apexTriggerNames)` → `List<Schema.ApexTrigger>`

Returns a list of `Schema.ApexTrigger` records

##### Parameters

| Param              | Description                             |
| ------------------ | --------------------------------------- |
| `apexTriggerNames` | The names of the Apex triggers to query |

##### Return

**Type**

List&lt;Schema.ApexTrigger&gt;

**Description**

`List&lt;Schema.ApexTrigger&gt;` containing any matching records

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

#### `getCachedApexEmailNotifications()` → `List<Schema.ApexEmailNotification>`

Returns a cached copy of the `Schema.ApexEmailNotification` records in the org

##### Return

**Type**

List&lt;Schema.ApexEmailNotification&gt;

**Description**

The cached `List&lt;Schema.ApexEmailNotification&gt;` records

#### `getCachedRecentLogWithApiReleaseDetails()` → `Log__c`

Returns a cached `Log__c` record that has been created within the last 4 hours that has API details populated from calling https://api.status.salesforce.com

##### Return

**Type**

Log\_\_c

**Description**

The cached `Log__c` record, or `null` if no match is found

#### `getCountOfAsyncApexJobs(String apexClassName, String apexMethodName, List<String> jobStatuses)` → `Integer`

Returns the count of `Schema.AsyncApexJob` records with the specified Apex class name, method name &amp; job status

##### Parameters

| Param            | Description                                                                              |
| ---------------- | ---------------------------------------------------------------------------------------- |
| `apexClassName`  | The fully-qualified name of the Apex class associated with `Schema.AsyncApexJob`         |
| `apexMethodName` | The specific method (if any) within the Apex class associated with `Schema.AsyncApexJob` |
| `jobStatuses`    | The list of job statuses that should be used to filter `AsynxApexJob` records            |

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

#### `getDeleteableUserRecordAccess(List<Id> recordIds)` → `List<Schema.UserRecordAccess>`

Returns the list of `Schema.UserRecordAccess` records for any of the specified record IDs that the current user can delete

##### Parameters

| Param       | Description                                |
| ----------- | ------------------------------------------ |
| `recordIds` | The list of `ID` for records to be deleted |

##### Return

**Type**

List&lt;Schema.UserRecordAccess&gt;

**Description**

The matching `List&lt;Schema.UserRecordAccess&gt;` records

#### `getFlowDefinitionViewsByFlowApiName(List<String> flowApiNames)` → `List<Schema.FlowDefinitionView>`

Returns a list of `Schema.FlowDefinitionView` records

##### Parameters

| Param          | Description                            |
| -------------- | -------------------------------------- |
| `flowApiNames` | The names of the Apex classes to query |

##### Return

**Type**

List&lt;Schema.FlowDefinitionView&gt;

**Description**

`List&lt;Schema.FlowDefinitionView&gt;` containing any matching records

#### `getFlowVersionViewsByDurableId(List<String> durableIds)` → `List<Schema.FlowVersionView>`

Returns a list of `Schema.FlowVersionView` records description

##### Parameters

| Param        | Description                           |
| ------------ | ------------------------------------- |
| `durableIds` | The durable IDs of the Flows to query |

##### Return

**Type**

List&lt;Schema.FlowVersionView&gt;

**Description**

`List&lt;Schema.FlowDefinitionView&gt;` containing any matching records

#### `getInstance()` → `LogManagementDataSelector`

The instance `LogManagementDataSelector` used for any querying specific to the log management layer

##### Return

**Type**

LogManagementDataSelector

**Description**

The singleton instance of `LogManagementDataSelector`

#### `getLogById(Id logId)` → `Log__c`

Returns a `Log__c` record

##### Parameters

| Param   | Description                              |
| ------- | ---------------------------------------- |
| `logId` | The `ID` of the `Log__c` record to query |

##### Return

**Type**

Log\_\_c

**Description**

The matching `Log__c` record

#### `getLogEntriesByLogId(Id logId)` → `List<LogEntry__c>`

Returns a `List&lt;LogEntry__c&gt;` records for the specified `Log__c` ID

##### Parameters

| Param   | Description                                                           |
| ------- | --------------------------------------------------------------------- |
| `logId` | The `ID` of the `Log__c` record of the `LogEntry__c` records to query |

##### Return

**Type**

List&lt;LogEntry\_\_c&gt;

**Description**

The matching `List&lt;LogEntry__c&gt;` records

#### `getLogEntryById(Id logEntryId)` → `LogEntry__c`

Returns a `LogEntry__c` record

##### Parameters

| Param        | Description                                   |
| ------------ | --------------------------------------------- |
| `logEntryId` | The `ID` of the `LogEntry__c` record to query |

##### Return

**Type**

LogEntry\_\_c

**Description**

The matching `LogEntry__c` record

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

#### `getLogsWithoutParentLogByParentTransactionId(List<String> parentTransactionIds)` → `List<Log__c>`

Returns a `List&lt;Log__c&gt;` of records with the specified parent transaction IDs and a `null` value in `ParentLog__c`

##### Parameters

| Param                  | Description                                                                  |
| ---------------------- | ---------------------------------------------------------------------------- |
| `parentTransactionIds` | The list of `String` parent transaction IDs of the `Log__c` records to query |

##### Return

**Type**

List&lt;Log\_\_c&gt;

**Description**

The list of matching `Log__c` records

#### `getOmniProcessProxies(List<Id> omniProcessIds)` → `Map<Id, LoggerSObjectProxy.OmniProcess>`

Returns a list of matching `Schema.OmniProcess` records based on the provided list of OmniProcess IDs

##### Parameters

| Param            | Description                                   |
| ---------------- | --------------------------------------------- |
| `omniProcessIds` | The list of `Schema.OmniProcess` IDs to query |

##### Return

**Type**

Map&lt;Id, LoggerSObjectProxy.OmniProcess&gt;

**Description**

The instance of `Map&lt;Id, SObject&gt;` containing any matching `Schema.OmniProcess` records

#### `getProfilesById(List<Id> profileIds)` → `List<Schema.Profile>`

Returns a `List&lt;Schema.Profile&gt;` of records with the specified profile IDs

##### Parameters

| Param        | Description                                               |
| ------------ | --------------------------------------------------------- |
| `profileIds` | The list of `ID` of the `Schema.Profile` records to query |

##### Return

**Type**

List&lt;Schema.Profile&gt;

**Description**

The list of matching `Schema.Profile` records

#### `getProfilesByNameSearch(String searchTerm)` → `List<Schema.Profile>`

Returns a `List&lt;Schema.Profile&gt;` of records where the profile&apos;s names partially matches the specified search term

##### Parameters

| Param        | Description                                                            |
| ------------ | ---------------------------------------------------------------------- |
| `searchTerm` | The `String` search term to use for searching `Schema.Profile` records |

##### Return

**Type**

List&lt;Schema.Profile&gt;

**Description**

The list of matching `Schema.Profile` records

#### `getQueuesByDeveloperName(List<String> queueDeveloperNames)` → `List<Schema.Group>`

Returns a `List&lt;Schema.Group&gt;` of records with the specified developer names and type == &apos;Queue&apos;

##### Parameters

| Param                 | Description                                         |
| --------------------- | --------------------------------------------------- |
| `queueDeveloperNames` | The list of `String` queue developer names to query |

##### Return

**Type**

List&lt;Schema.Group&gt;

**Description**

The list of matching `Schema.Group` records

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

#### `getTopicsByName(Set<String> topicNames)` → `List<Schema.Topic>`

Returns a list of `Schema.Topic` records with one of the specified topic names

##### Parameters

| Param        | Description                              |
| ------------ | ---------------------------------------- |
| `topicNames` | The set of `String` topic names to query |

##### Return

**Type**

List&lt;Schema.Topic&gt;

**Description**

The list of matching `Schema.Topic` records

#### `getUsersById(List<Id> userIds)` → `List<Schema.User>`

Returns a `List&lt;Schema.User&gt;` of records with the specified user IDs

##### Parameters

| Param     | Description                                            |
| --------- | ------------------------------------------------------ |
| `userIds` | The list of `ID` of the `Schema.User` records to query |

##### Return

**Type**

List&lt;Schema.User&gt;

**Description**

The list of matching `Schema.User` records

#### `getUsersByNameSearch(String searchTerm)` → `List<Schema.User>`

Returns a `List&lt;Schema.User&gt;` of records where the User&apos;s names or username partially matches the specified search term

##### Parameters

| Param        | Description                                                         |
| ------------ | ------------------------------------------------------------------- |
| `searchTerm` | The `String` search term to use for searching `Schema.User` records |

##### Return

**Type**

List&lt;Schema.User&gt;

**Description**

The list of matching `Schema.User` records

#### `getUsersByUsername(List<String> usernames)` → `List<Schema.User>`

Returns a `List&lt;Schema.User&gt;` of records with the specified usernames (`Schema.User.Username`)

##### Parameters

| Param       | Description                                  |
| ----------- | -------------------------------------------- |
| `usernames` | The list of `String` user usernames to query |

##### Return

**Type**

List&lt;Schema.User&gt;

**Description**

Tje list of matching `Schema.User` records

---
