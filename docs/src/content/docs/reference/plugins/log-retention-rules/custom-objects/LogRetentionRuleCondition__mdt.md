---
title: LogRetentionRuleCondition__mdt
description: >-
  Nebula Logger log-retention-rules plugin customobject (public API):
  LogRetentionRuleCondition__mdt.
---

# Log Retention Rule Condition

Used to configure field-level conditions for retention rules - each condition checks a LogEntry**c or Log**c field for a specific value, regular expression (regex), or field comparisons

## API Name

`LogRetentionRuleCondition__mdt`

## Fields

### Field

**Required**

**API Name**

`FieldPath__c`

**Type**

_Text_

---

### Log Retention Rule

**Required**

**API Name**

`LogRetentionRule__c`

**Type**

_MetadataRelationship_

---

### Operator

**Required**

**API Name**

`Operator__c`

**Type**

_Picklist_

#### Possible values are

- EQUAL_TO
- NOT_EQUAL_TO
- LESS_THAN
- GREATER_THAN
- LESS_THAN_OR_EQUAL_TO
- GREATER_THAN_OR_EQUAL_TO
- STARTS_WITH
- CONTAINS
- ENDS_WITH

---

### Sort Order

**API Name**

`SortOrder__c`

**Type**

_Number_

---

### Value

**API Name**

`Value__c`

**Type**

_Text_

---

### Value Type

**Required**

**API Name**

`ValueType__c`

**Type**

_Picklist_

#### Possible values are

- Value
- Field
- RegEx

## Records

### Sample Rule 1 condition

**API Name**

`LogRetentionRuleCondition.Sample_Rule_1_condition`

---

### Sample Rule 1 - Error Condition

**API Name**

`LogRetentionRuleCondition.Sample_Rule_1_Error_Condition`

---

### Sample Rule 1 - Scenario A Condition

**API Name**

`LogRetentionRuleCondition.Sample_Rule_1_Scenario_A_Condition`

---

### Sample Rule 1 - Scenario B Condition

**API Name**

`LogRetentionRuleCondition.Sample_Rule_1_Scenario_B_Condition`

---

### Sample Rule 2 - Error Condition

**API Name**

`LogRetentionRuleCondition.Sample_Rule_2_Error_Condition`
