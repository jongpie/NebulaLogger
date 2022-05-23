---
layout: default
---

## LoggerEngineDataSelector class

Selector class used for all queries that are specific to the logger engine layer

---

### Methods

#### `getCachedAuthSession()` → `AuthSession`

Returns a cached copy of `AuthSession` for the current user&apos;s current session, or `null` if there is not a current session

##### Return

**Type**

AuthSession

**Description**

The cached `AuthSession` record

#### `getCachedLoggerSObjectHandlers()` → `List<LoggerSObjectHandler_t>`

Returns a cached copy of the `LoggerSObjectHandler_t` records in the org, including the field `SObjectType__r.QualifiedApiName` that cannot be accessed via `LoggerSObjectHandler_t.getAll()`

##### Return

**Type**

List&lt;LoggerSObjectHandler_t&gt;

**Description**

The cached `List&lt;LoggerSObjectHandler_t&gt;` records

#### `getCachedNetwork()` → `SObject`

Returns a cached copy of the current user&apos;s `Network` site, or `null` if the current user is not associated with a `Network` site

##### Return

**Type**

SObject

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

---
