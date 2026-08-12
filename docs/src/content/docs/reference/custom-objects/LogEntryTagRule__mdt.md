---
title: LogEntryTagRule__mdt
description: 'Nebula Logger customobject reference: LogEntryTagRule__mdt.'
---

# Log Entry Tag Rule

Used to configure rules in Nebula Logger to assign additional tags to LogEntry\_\_c records based on field values

## API Name

`LogEntryTagRule__mdt`

## Fields

### Comparison Type

**Required**

**API Name**

`ComparisonType__c`

**Type**

_Picklist_

#### Possible values are

- CONTAINS
- EQUALS
- MATCHES_REGEX
- STARTS_WITH

---

### Comparison Value

**API Name**

`ComparisonValue__c`

**Type**

_LongTextArea_

---

### Is Enabled

**API Name**

`IsEnabled__c`

**Type**

_Checkbox_

---

### Field

**Required**

**API Name**

`SObjectField__c`

**Type**

_MetadataRelationship_

---

### Logger SObject

**Required**

**API Name**

`SObjectType__c`

**Type**

_MetadataRelationship_

---

### Tag(s) to Apply

1 or more tags to assign - each tag should be listed on a separate line

**API Name**

`Tags__c`

**Type**

_LongTextArea_
