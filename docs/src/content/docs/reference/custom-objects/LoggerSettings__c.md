---
title: LoggerSettings__c
description: 'Nebula Logger customobject reference: LoggerSettings__c.'
---

# Logger Settings

Used to configure hierarchial settings in Nebula Logger to provide user-specific &amp; profile-specific customizations

## API Name

`LoggerSettings__c`

## Fields

### Log Owner

**API Name**

`DefaultLogOwner__c`

**Type**

_Text_

---

### Log Purge Action

**API Name**

`DefaultLogPurgeAction__c`

**Type**

_Text_

---

### Log Access Level

Uses Apex managed sharing to grants users read or edit access to their log records (on insert only). When no access level is specified, no Apex sharing logic is executed. This only gives record-level access - users will still need to be granted access to the Log\_\_c object using permission sets or profiles.

**API Name**

`DefaultLogShareAccessLevel__c`

**Type**

_Text_

---

### Days to Retain Logs

This value is used to set the field Log**c.LogRetentionDate**c, which is then used by LogBatchPurger to delete old logs. To keep logs indefinitely, set this field to blank (null).

**API Name**

`DefaultNumberOfDaysToRetainLogs__c`

**Type**

_Number_

---

### Platform Event Storage Location

Defaults to CUSTOM_OBJECTS. This controls the default location where LogEntryEvent**e records are stored - when null, LogEntryEvent**e records will not be stored.

**API Name**

`DefaultPlatformEventStorageLocation__c`

**Type**

_Text_

---

### Platform Event Storage Logging Level

**API Name**

`DefaultPlatformEventStorageLoggingLevel__c`

**Type**

_Text_

---

### Save Method

**Required**

Defaults to EVENT_BUS. This controls the default save method used by Logger when calling saveLog(). In most situations, EVENT_BUS should be used.

**API Name**

`DefaultSaveMethod__c`

**Type**

_Text_

---

### Scenario

Sets a default scenario for the transaction

**API Name**

`DefaultScenario__c`

**Type**

_Text_

---

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

_Checkbox_

---

### Enable Apex System.debug()

**API Name**

`IsApexSystemDebugLoggingEnabled__c`

**Type**

_Checkbox_

---

### Enable Data Masking

**API Name**

`IsDataMaskingEnabled__c`

**Type**

_Checkbox_

---

### Enabled

**API Name**

`IsEnabled__c`

**Type**

_Checkbox_

---

### Enable JavaScript console.log()

**API Name**

`IsJavaScriptConsoleLoggingEnabled__c`

**Type**

_Checkbox_

---

### Enable JavaScript lightning-logger

**API Name**

`IsJavaScriptLightningLoggerEnabled__c`

**Type**

_Checkbox_

---

### Strip Inaccessible Record Fields

**API Name**

`IsRecordFieldStrippingEnabled__c`

**Type**

_Checkbox_

---

### Enable Saving

Controls if saving is enabled - when disabled, any calls to saveLog() are ignored.

**API Name**

`IsSavingEnabled__c`

**Type**

_Checkbox_

---

### Logging Level

**Required**

**API Name**

`LoggingLevel__c`

**Type**

_Text_

---

### Start Time

**API Name**

`StartTime__c`

**Type**

_DateTime_
