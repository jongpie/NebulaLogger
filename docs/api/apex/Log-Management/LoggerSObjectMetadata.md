---
layout: default
---

## LoggerSObjectMetadata class

Provides details to LWCs about Logger&apos;s `SObjects`, using `@AuraEnabled` properties

---

### Methods

#### `getSchema(Schema.SObjectType sobjectType)` → `SObjectSchema`

Provides schema details about the specified `SObjectType`

##### Parameters

| Param         | Description                                                                                      |
| ------------- | ------------------------------------------------------------------------------------------------ |
| `sobjectType` | The instance of `SObjectType` to convert to an instance of `LoggerSObjectMetadata.SObjectSchema` |

##### Return

**Type**

SObjectSchema

**Description**

An instance of `LoggerSObjectMetadata.SObjectSchema` for the specified `SObjectType`

#### `getSchemaForName(String sobjectApiName)` → `SObjectSchema`

Provides schema details about the specified `SObjectType`

##### Parameters

| Param            | Description                                                                                          |
| ---------------- | ---------------------------------------------------------------------------------------------------- |
| `sobjectApiName` | The API name of the `SObjectType` to convert to an instance of `LoggerSObjectMetadata.SObjectSchema` |

##### Return

**Type**

SObjectSchema

**Description**

An instance of `LoggerSObjectMetadata.SObjectSchema` for the specified `SObjectType`

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
