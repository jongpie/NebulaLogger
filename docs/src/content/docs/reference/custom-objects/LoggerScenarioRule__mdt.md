---
title: LoggerScenarioRule__mdt
description: 'Nebula Logger customobject reference: LoggerScenarioRule__mdt.'
---

# Logger Scenario Rule

Used to configure rules in Nebula Logger to provide scenario-specific customizations

## API Name

`LoggerScenarioRule__mdt`

## Fields

### End Time

**API Name**

`EndTime__c`

**Type**

_DateTime_

---

### Enable Anonymous Mode

**API Name**

`IsAnonymousModeEnabled__c`

**Type**

_Picklist_

#### Possible values are

- true
- false

---

### Enable Apex System.debug()

**API Name**

`IsApexSystemDebugLoggingEnabled__c`

**Type**

_Picklist_

#### Possible values are

- true
- false

---

### Enable Data Masking

**API Name**

`IsDataMaskingEnabled__c`

**Type**

_Picklist_

#### Possible values are

- true
- false

---

### Is Enabled

**API Name**

`IsEnabled__c`

**Type**

_Checkbox_

---

### Enable JavaScript console.log()

**API Name**

`IsJavaScriptConsoleLoggingEnabled__c`

**Type**

_Picklist_

#### Possible values are

- true
- false

---

### Enable JavaScript lightning-logger

**API Name**

`IsJavaScriptLightningLoggerEnabled__c`

**Type**

_Picklist_

#### Possible values are

- true
- false

---

### Assign Logs To Logger Scenario Owner

**API Name**

`IsLogAssignmentEnabled__c`

**Type**

_Picklist_

#### Possible values are

- true
- false

---

### Is Logger Enabled

**API Name**

`IsLoggerEnabled__c`

**Type**

_Picklist_

#### Possible values are

- true
- false

---

### Enable Log Retention Override

**API Name**

`IsLogRetentionOverrideEnabled__c`

**Type**

_Picklist_

#### Possible values are

- true
- false

---

### Enable Platform Event Storage Override

**API Name**

`IsPlatformEventStorageLocationEnabled__c`

**Type**

_Picklist_

#### Possible values are

- true
- false

---

### Strip Inaccessible Record Fields

**API Name**

`IsRecordFieldStrippingEnabled__c`

**Type**

_Picklist_

#### Possible values are

- true
- false

---

### Enable Saving

**API Name**

`IsSavingEnabled__c`

**Type**

_Picklist_

#### Possible values are

- true
- false

---

### Days to Retain Logs

**API Name**

`NumberOfDaysToRetainLogs__c`

**Type**

_Number_

---

### Platform Event Storage Location

**API Name**

`PlatformEventStorageLocation__c`

**Type**

_Text_

---

### Save Method

**API Name**

`SaveMethod__c`

**Type**

_Text_

---

### Scenario

**Required**

**API Name**

`Scenario__c`

**Type**

_Text_

---

### Start Time

**API Name**

`StartTime__c`

**Type**

_DateTime_

---

### User Logging Level

**API Name**

`UserLoggingLevel__c`

**Type**

_Picklist_

#### Possible values are

- ERROR
- WARN
- INFO
- DEBUG
- FINE
- FINER
- FINEST
