---
layout: default
---

## LoggerEngineDataSelector class

Selector class used for all queries that are specific to the logger engine layer

---

### Methods

#### `getAuthSessionProxies(List<Id> userIds)` → `Map<Id, LoggerSObjectProxy.AuthSession>`

Returns a `Map&lt;Id, LoggerSObjectProxy.AuthSession&gt;` for the specified user IDs &amp; their matching active sessions, or `null` if there is not a current session

##### Parameters

| Param     | Description         |
| --------- | ------------------- |
| `userIds` | userIds description |

##### Return

**Type**

Map&lt;Id, LoggerSObjectProxy.AuthSession&gt;

**Description**

The instance of `Map&lt;Id, LoggerSObjectProxy.AuthSession&gt;` containing any matching `Schema.AuthSession` records

#### `getCachedAuthSessionProxy()` → `LoggerSObjectProxy.AuthSession`

Returns a cached copy of `LoggerSObjectProxy.AuthSession` for the current user&apos;s current session, or `null` if there is not a current session

##### Return

**Type**

LoggerSObjectProxy.AuthSession

**Description**

The cached `LoggerSObjectProxy.AuthSession` record

#### `getCachedNetworkProxy(Id networkId)` → `LoggerSObjectProxy.Network`

Returns a cached copy of the current user&apos;s `Schema.Network` site, or `null` if the current user is not associated with a `Schema.Network` site

##### Parameters

| Param       | Description                                    |
| ----------- | ---------------------------------------------- |
| `networkId` | The record ID of the `Schema.Network` to query |

##### Return

**Type**

LoggerSObjectProxy.Network

**Description**

The cached `Schema.Network` record

#### `getCachedOrganization()` → `Schema.Organization`

Returns a cached copy of the `Schema.Organization` record in the org, including some fields that cannot be accessed via `UserInfo`

##### Return

**Type**

Schema.Organization

**Description**

The cached `Schema.Organization` record

#### `getCachedUser()` → `Schema.User`

Returns a cached copy of the current user, including some profile fields that cannot be accessed via `UserInfo`

##### Return

**Type**

Schema.User

**Description**

The cached `Schema.User` record for the current user

#### `getInstance()` → `LoggerEngineDataSelector`

The instance `LoggerEngineDataSelector` used for any querying specific to the logger engine layer

##### Return

**Type**

LoggerEngineDataSelector

**Description**

The singleton instance of `LoggerEngineDataSelector`

#### `getNetworkProxies(List<Id> networkIds)` → `Map<Id, LoggerSObjectProxy.Network>`

Returns a list of matching `Schema.Network` records based on the provided list of network IDs

##### Parameters

| Param        | Description                               |
| ------------ | ----------------------------------------- |
| `networkIds` | The list of `Schema.Network` IDs to query |

##### Return

**Type**

Map&lt;Id, LoggerSObjectProxy.Network&gt;

**Description**

The instance of `Map&lt;Id, SObject&gt;` containing any matching `Schema.Network` records

#### `getUsers(List<Id> userIds)` → `Map<Id, Schema.User>`

Returns a list of matching `Schema.User` records based on the provided list of user IDs

##### Parameters

| Param     | Description                            |
| --------- | -------------------------------------- |
| `userIds` | The list of `Schema.User` IDs to query |

##### Return

**Type**

Map&lt;Id, Schema.User&gt;

**Description**

The instance of `Map&lt;Id, Schema.User&gt;` containing any matching `Schema.User` records

---
