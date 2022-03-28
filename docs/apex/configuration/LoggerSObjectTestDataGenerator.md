---
layout: default
---

## LoggerSObjectTestDataGenerator class

Class used to create or update an `SObject` record with static fake data. This is useful in situations where you need to have fields populated, but the specific values used are not relevant to a particular test. This class can be used when Apex writing tests for plugins.

### Related

[LoggerTestUtils](LoggerTestUtils)

---

### Constructors

#### `LoggerSObjectTestDataGenerator(Schema.SObjectType sobjectType)`

Creates a new generator instance for the specified `SObjectType`, including creating a new `SObject` record. The new `SObject` record is created with any default field values that have been configured on the `SObjectType`.

##### Parameters

| Param         | Description                                                         |
| ------------- | ------------------------------------------------------------------- |
| `sobjectType` | The `SObjectType` to use for generating a new test `SObject` record |

#### `LoggerSObjectTestDataGenerator(SObject record)`

Creates a new generator instance for the specified `SObject` record

##### Parameters

| Param    | Description                                                     |
| -------- | --------------------------------------------------------------- |
| `record` | The existing test `SObject` record to populate with sample data |

---

### Methods

#### `populateAllFields()` → `SObject`

Sets a value on all editable fields, unless the `SObject` record already had a value specified for a field (including `null`)

##### Return

**Type**

SObject

**Description**

The `SObject` record, with all editable fields populated

#### `populateRequiredFields()` → `SObject`

Sets a value on all editable required fields, unless the `SObject` record already had a value specified for a field (including `null`)

##### Return

**Type**

SObject

**Description**

The `SObject` record, with all editable required fields populated

---
