---
layout: default
---

## LoggerSObjectProxy class

Proxy class used as a middle layer between some problematic SObject Types and the rest of Nebula Logger&apos;s codebase. Each inner class maps to a corresponding `SObjectType` that is difficult to work with Apex for some reason or another, such as not being mockable or creatable, or not existing in all orgs.

---

### Methods

#### `serialize()` → `String`

---

### Inner Classes

#### LoggerSObjectProxy.AuthSession class

All `Schema.AuthSession` SObjects are read-only in Apex, which makes them more difficult to work with, and impossible to mock field values directly during unit tests - even using tricks like System.JSON.deserialize() do not work. The `LoggerSObjectProxy.AuthSession` class acts as a substitute for a `Schema.AuthSession` record to provide the abilility to mock the data during unit &amp; integration tests.

---

##### Properties

###### `Id` → `public`

###### `LoginHistory` → `public`

###### `LoginHistoryId` → `Id`

###### `LoginType` → `String`

###### `LogoutUrl` → `String`

###### `ParentId` → `Id`

###### `SessionSecurityLevel` → `String`

###### `SessionType` → `String`

###### `SourceIp` → `String`

###### `UsersId` → `Id`

---

#### LoggerSObjectProxy.LoginHistory class

All `Schema.LoginHistory` SObjects are read-only in Apex, which makes them more difficult to work with, and impossible to mock field values directly during unit tests - even using tricks like System.JSON.deserialize() do not work. The `LoggerSObjectProxy.LoginHistory` class acts as a substitute for a `Schema.LoginHistory` record to provide the abilility to mock the data during unit &amp; integration tests.

---

##### Properties

###### `Application` → `String`

###### `Browser` → `String`

###### `Platform` → `String`

###### `UserId` → `Id`

---

#### LoggerSObjectProxy.Network class

Not all orgs have the SObject `Schema.Network` - it is only present in orgs that have enabled Experience Cloud Sites (communities/networks), so `Schema.Network` has to be referenced dynamically, including using hardcoded `String` values for field API names. The `LoggerSObjectProxy.Network` class acts as a substitute for a `Schema.Network` record so that the rest of the codebase can rely on strongly-typed references to fields (properties).

---

##### Properties

###### `Id` → `String`

###### `Name` → `String`

###### `UrlPathPrefix` → `String`

---

#### LoggerSObjectProxy.OmniProcess class

Not all orgs have the SObject `Schema.OmniProcess` - it is only present in orgs that have enabled OmniStudio, so `Schema.OmniProcess` has to be referenced dynamically, including using hardcoded `String` values for field API names. The `LoggerSObjectProxy.OmniProcess` class acts as a substitute for a `Schema.OmniProcess` record so that the rest of the codebase can rely on strongly-typed references to fields (properties).

---

##### Properties

###### `CreatedBy` → `Schema.User`

###### `CreatedById` → `Id`

###### `CreatedDate` → `Datetime`

###### `Id` → `String`

###### `LastModifiedBy` → `Schema.User`

###### `LastModifiedById` → `Id`

###### `LastModifiedDate` → `Datetime`

###### `OmniProcessType` → `String`

###### `UniqueName` → `String`

---
