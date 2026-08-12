---
title: LoggerSObjectHandler__mdt
description: 'Nebula Logger customobject reference: LoggerSObjectHandler__mdt.'
---

# Logger SObject Handler

Used to configure Apex trigger handler classes in Nebula Logger that run on the included objects LogEntryEvent**e, LoggerScenario**c, Log**c, LogEntry**c, LogEntryTag**c, and LoggerTag**c

## API Name

`LoggerSObjectHandler__mdt`

## Fields

### Is Enabled

Controls if the SObject&#x27;s trigger handler class should execute. This is useful for temporary disabling the logger&#x27;s trigger handlers, but should typically be enabled.

**API Name**

`IsEnabled__c`

**Type**

_Checkbox_

---

### Trigger Handler Apex Class

**API Name**

`SObjectHandlerApexClass__c`

**Type**

_Text_

---

### SObject Type

**API Name**

`SObjectType__c`

**Type**

_MetadataRelationship_

---

### SObjectType Override

Not all base platform types can be selected using the SObjectType picklist. If your object is not supported, supply the API name for the object here instead.

**API Name**

`SObjectTypeOverride__c`

**Type**

_Text_

## Records

### LogEntryEventHandler config

**API Name**

`LoggerSObjectHandler.LogEntryEventHandler`

---

### LogEntryHandler config

**API Name**

`LoggerSObjectHandler.LogEntryHandler`

---

### LogEntryTagHandler config

**API Name**

`LoggerSObjectHandler.LogEntryTagHandler`

---

### LoggerScenarioHandler config

**API Name**

`LoggerSObjectHandler.LoggerScenarioHandler`

---

### LoggerTagHandler config

**API Name**

`LoggerSObjectHandler.LoggerTagHandler`

---

### LogHandler config

**API Name**

`LoggerSObjectHandler.LogHandler`
