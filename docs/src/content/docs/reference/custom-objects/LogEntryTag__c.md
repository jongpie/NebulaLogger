---
title: LogEntryTag__c
description: 'Nebula Logger customobject reference: LogEntryTag__c.'
---

# Log Entry Tag

Used by Nebula Logger as a junction object to represent a unique relationship between a LogEntry**c record and a LoggerTag**c record

## API Name

`LogEntryTag__c`

## Fields

### Impersonated By Username

**API Name**

`ImpersonatedByUsernameLink__c`

**Type**

_Text_

---

### Log Entry

**API Name**

`LogEntry__c`

**Type**

_MasterDetail_

---

### Log Entry Origin

**API Name**

`LogEntryOrigin__c`

**Type**

_Text_

---

### Log Entry Timestamp

**API Name**

`LogEntryTimestamp__c`

**Type**

_DateTime_

---

### Username

**API Name**

`LoggedByUsernameLink__c`

**Type**

_Text_

---

### Log

**API Name**

`LogLink__c`

**Type**

_Text_

---

### Parent Log

**API Name**

`ParentLogLink__c`

**Type**

_Text_

---

### Profile

**API Name**

`ProfileLink__c`

**Type**

_Text_

---

### Logger Tag

**API Name**

`Tag__c`

**Type**

_MasterDetail_

---

### Unique ID

An external ID field used to ensure that Log Entry Tag records are unique

**API Name**

`UniqueId__c`

**Type**

_Text_
