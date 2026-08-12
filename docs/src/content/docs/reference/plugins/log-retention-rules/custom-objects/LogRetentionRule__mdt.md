---
title: LogRetentionRule__mdt
description: >-
  Nebula Logger log-retention-rules plugin customobject (public API):
  LogRetentionRule__mdt.
---

# Log Retention Rule

Used to configure rules that set the value of Log**c.LogRetentionDate**c - each rules consists of 1 or more conditions, stored in LogRetentionRuleCondition\_\_mdt

## API Name

`LogRetentionRule__mdt`

## Fields

### Condition Logic Type

**Required**

**API Name**

`ConditionLogicType__c`

**Type**

_Picklist_

#### Possible values are

- AND
- OR
- Custom

---

### Custom Condition Logic

**API Name**

`CustomConditionLogic__c`

**Type**

_Text_

---

### Execution Order

**API Name**

`ExecutionOrder__c`

**Type**

_Number_

---

### Is Enabled

**API Name**

`IsEnabled__c`

**Type**

_Checkbox_

---

### Number of Days to Retain Logs

**API Name**

`NumberOfDaysToRetainLogs__c`

**Type**

_Number_

## Records

### Sample Rule 1 - Error Logs

**API Name**

`LogRetentionRule.Sample_Rule_1_Error_Logs`

---

### Sample Rule 1 - Scenarios with Errors

**API Name**

`LogRetentionRule.Sample_Rule_1_Scenarios_With_Errors`

---

### Sample Rule 2 - Additional Error Logs

**API Name**

`LogRetentionRule.Sample_Rule_2_Additional_Error_Logs`
