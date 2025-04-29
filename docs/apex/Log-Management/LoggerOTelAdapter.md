---
layout: default
---

## LoggerOTelAdapter class

Class used to handle the translation between Nebula Logger-specific concepts/data model and OpenTelemetry&apos;s (OTel) schema. All of this is specific to Nebula Logger.

### Related

[LoggerOTelSchema](LoggerOTelSchema)

[LoggerRestResource](LoggerRestResource)

[LogEntryEventBuilder](LogEntryEventBuilder)

[LogViewerController](LogViewerController)

---

### Methods

#### `LogEntryEventConverter(List<LoggerOTelSchema.LogsPayload> payloads)` → `public`

#### `convertToCustomObjects(List<LoggerOTelSchema.LogsPayload> payloads)` → `List<SObject>>`

#### `convertToOTel(Log__c log)` → `LoggerOTelSchema.LogsPayload`

#### `convertToOTel(List<Log__c> logs)` → `List<LoggerOTelSchema.LogsPayload>`

#### `convertToOTel(List<LogEntryEvent__e> logEntryEvents)` → `List<LoggerOTelSchema.LogsPayload>`

#### `convertToPlatformEvents(List<LoggerOTelSchema.LogsPayload> payloads)` → `List<LogEntryEvent__e>`

#### `getLogEntryEvents()` → `List<LogEntryEvent__e>`

---
