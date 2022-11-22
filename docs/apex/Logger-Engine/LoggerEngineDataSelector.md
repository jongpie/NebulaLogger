---
layout: default
---

## LoggerEngineDataSelector class

Selector class used for all queries that are specific to the logger engine layer

---

### Methods

#### `getAuthSessionProxies(List<Id> userIds)` → `Map<Id, LoggerSObjectProxy.AuthSession>`

Returns a `Map&lt;Id, AuthSession&gt;` for the specified user IDs &amp; their matching active sessions, or `null` if there is not a current session

##### Parameters

| Param     | Description         |
| --------- | ------------------- |
| `userIds` | userIds description |

##### Return

**Type**

Map&lt;Id, LoggerSObjectProxy.AuthSession&gt;

**Description**

The instance of `Map&lt;Id, AuthSession&gt;` containing any matching `AuthSession` records

#### `getCachedAuthSessionProxy()` → `LoggerSObjectProxy.AuthSession`

Returns a cached copy of `AuthSession` for the current user&apos;s current session, or `null` if there is not a current session

##### Return

**Type**

LoggerSObjectProxy.AuthSession

**Description**

The cached `AuthSession` record

#### `getCachedLoggerSObjectHandlers()` → `List<LoggerSObjectHandler_t>`

Returns a cached copy of the `LoggerSObjectHandler_t` records in the org, including the field `SObjectType__r.QualifiedApiName` that cannot be accessed via `LoggerSObjectHandler_t.getAll()`

##### Return

**Type**

List&lt;LoggerSObjectHandler_t&gt;

**Description**

The cached `List&lt;LoggerSObjectHandler_t&gt;` records

#### `getCachedNetworkProxy(Id networkId)` → `LoggerSObjectProxy.Network`

Returns a cached copy of the current user&apos;s `Network` site, or `null` if the current user is not associated with a `Network` site

##### Parameters

| Param       | Description                             |
| ----------- | --------------------------------------- |
| `networkId` | The record ID of the `Network` to query |

##### Return

**Type**

LoggerSObjectProxy.Network

**Description**

The cached `Network` record

#### `getCachedOrganization()` → `Organization`

Returns a cached copy of the `Organization` record in the org, including some fields that cannot be accessed via `UserInfo`

##### Return

**Type**

Organization

**Description**

The cached `Organization` record

#### `getCachedTagAssignmentRules()` → `List<LogEntryTagRule_t>`

Returns a cached copy of the `LogEntryTagRule_t` records in the org, including the field `SObjectField__r.QualifiedApiName` that cannot be accessed via `LogEntryTagRule_t.getAll()`

##### Return

**Type**

List&lt;LogEntryTagRule_t&gt;

**Description**

The cached `List&lt;LogEntryTagRule_t&gt;` records

#### `getCachedUser()` → `User`

Returns a cached copy of the current user, including some profile fields that cannot be accessed via `UserInfo`

##### Return

**Type**

User

**Description**

The cached `User` record for the current user

#### `getInstance()` → `LoggerEngineDataSelector`

The instance `LoggerEngineDataSelector` used for any querying specific to the logger engine layer

##### Return

**Type**

LoggerEngineDataSelector

**Description**

The singleton instance of `LoggerEngineDataSelector`

#### `getNetworkProxies(List<Id> networkIds)` → `Map<Id, LoggerSObjectProxy.Network>`

Returns a list of matching `Network` records based on the provided list of network IDs

##### Parameters

| Param        | Description                        |
| ------------ | ---------------------------------- |
| `networkIds` | The list of `Network` IDs to query |

##### Return

**Type**

Map&lt;Id, LoggerSObjectProxy.Network&gt;

**Description**

The instance of `Map&lt;Id, SObject&gt;` containing any matching `Network` records

#### `getUsers(List<Id> userIds)` → `Map<Id, User>`

Returns a list of matching `User` records based on the provided list of user IDs

##### Parameters

| Param     | Description                     |
| --------- | ------------------------------- |
| `userIds` | The list of `User` IDs to query |

##### Return

**Type**

Map&lt;Id, User&gt;

**Description**

The instance of `Map&lt;Id, User&gt;` containing any matching `User` records

---
