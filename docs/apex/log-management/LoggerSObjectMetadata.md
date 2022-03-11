---
layout: default
---

## LoggerSObjectMetadata class

Provides details to LWCs about Logger&apos;s `SObjects`, using `@AuraEnabled` properties

---

### Methods

#### `getLogEntryEventSchema()` → `SObjectSchema`

Provides schema details about the the platform event object `LogEntryEvent__e`

##### Return

**Type**

SObjectSchema

**Description**

An instance of `LoggerSObjectMetadata.SObjectSchema` for the platform event `LogEntryEvent__e`

#### `getLoggerSettingsSchema()` → `SObjectSchema`

Provides schema details about the the custom settings object `LoggerSettings__c`

##### Return

**Type**

SObjectSchema

**Description**

An instance of `LoggerSObjectMetadata.SObjectSchema` for the platform event `LoggerSettings__c`

---

### Inner Classes

#### LoggerSObjectMetadata.FieldSchema class

Inner class for `SObjectField` details to LWCs, using `@AuraEnabled` properties

---

##### Properties

###### `apiName` → `String`

###### `inlineHelpText` → `String`

###### `label` → `String`

###### `localApiName` → `String`

###### `type` → `String`

---

#### LoggerSObjectMetadata.SObjectSchema class

Inner class for `SObject` details to LWCs, using `@AuraEnabled` properties

---

##### Properties

###### `apiName` → `String`

###### `fields` → `Map<String, FieldSchema>`

###### `label` → `String`

###### `labelPlural` → `String`

###### `localApiName` → `String`

###### `namespacePrefix` → `String`

---
