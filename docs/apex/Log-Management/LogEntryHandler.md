---
layout: default
---

## LogEntryHandler class

Manages setting fields on `LogEntry__c` before insert &amp; before update

---

### Methods

#### `apply(LogEntry__c logEntry, Schema.ApexClass topLevelApexClass)` → `void`

#### `apply(LogEntry__c logEntry, Schema.ApexTrigger apexTrigger)` → `void`

#### `apply(LogEntry__c logEntry, Schema.ApexClass apexClass)` → `void`

#### `apply(LogEntry__c logEntry, Schema.ApexTrigger apexTrigger)` → `void`

#### `apply(LogEntry__c logEntry, Schema.ApexClass apexClass)` → `void`

#### `apply(LogEntry__c logEntry, Schema.ApexTrigger apexTrigger)` → `void`

#### `getSObjectType()` → `Schema.SObjectType`

Returns SObject Type that the handler is responsible for processing

##### Return

**Type**

Schema.SObjectType

**Description**

The instance of `SObjectType`

---

### Inner Classes

#### LogEntryHandler.SourceMetadataSnippet class

---

##### Constructors

###### `SourceMetadataSnippet(LoggerStackTrace stackTrace, Schema.ApexClass apexClass)`

###### `SourceMetadataSnippet(LoggerStackTrace stackTrace, Schema.ApexTrigger apexTrigger)`

---

##### Properties

###### `ApiVersion` → `String`

###### `Code` → `String`

###### `EndingLineNumber` → `Integer`

###### `Language` → `LoggerStackTrace.Source`

###### `StackTrace` → `Logger`

###### `StartingLineNumber` → `Integer`

###### `TargetLineNumber` → `Integer`

###### `TotalLinesOfCode` → `Integer`

---
