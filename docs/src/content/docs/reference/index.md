---
title: Reference
description: >-
  Auto-generated reference for Nebula Logger Apex classes, custom objects,
  triggers, and LWCs.
---

Auto-generated reference for Nebula Logger.

Groupings:

- **logger-engine** - global Apex classes for adding entries, building payloads, and orchestrating saves.
- **custom-objects** - `Log__c`, `LogEntry__c`, and every custom metadata type Nebula Logger ships.
- **triggers** - platform-event and object triggers that materialize entries and drive plugins.
- **lwc** - `logger` and `logEntryBuilder` client-side APIs.

For narrative and code examples, see the [Logging Guide](/logging-guide/concepts/).

---

# Reference

## Custom Objects

### [Log\_\_c](custom-objects\Log__c.md)

Used by Nebula Logger to unify all log entries generated in a single transaction

### [LogEntry\_\_c](custom-objects\LogEntry__c.md)

Used by Nebula Logger to represent a single log message within a transaction - log entries can be generated via Apex, Flow, Process Builder, Lightning Web Components, and Aura Components.

### [LogEntryDataMaskRule\_\_mdt](custom-objects\LogEntryDataMaskRule__mdt.md)

Used to configure regex-based rules in Nebula Logger to mask sensitive data in log entry fields, such as LogEntryEvent**e.Message**c and LogEntry**c.Message**c

### [LogEntryEvent\_\_e](custom-objects\LogEntryEvent__e.md)

Platform Event object used by Nebula Logger for publishing debug and exception log entries

### [LogEntryTag\_\_c](custom-objects\LogEntryTag__c.md)

Used by Nebula Logger as a junction object to represent a unique relationship between a LogEntry**c record and a LoggerTag**c record

### [LogEntryTagRule\_\_mdt](custom-objects\LogEntryTagRule__mdt.md)

Used to configure rules in Nebula Logger to assign additional tags to LogEntry\_\_c records based on field values

### [LoggerFieldMapping\_\_mdt](custom-objects\LoggerFieldMapping__mdt.md)

Used to configure custom field mappings in Nebula Logger to map data between LogEntryEvent**e and the custom objects Log**c, LogEntry**c, and LoggerScenario**c

### [LoggerParameter\_\_mdt](custom-objects\LoggerParameter__mdt.md)

Used to configure key-value pair parameters in Nebula Logger to control systemwide features

### [LoggerScenario\_\_c](custom-objects\LoggerScenario__c.md)

Used by Nebula Logger to store unique scenarios (text/String) that can be used to identify Log**c and LogEntry**c records via the lookup fields Log**c.TransactionScenario**c and LogEntry**c.EntryScenario**c

### [LoggerScenarioRule\_\_mdt](custom-objects\LoggerScenarioRule__mdt.md)

Used to configure rules in Nebula Logger to provide scenario-specific customizations

### [LoggerSettings\_\_c](custom-objects\LoggerSettings__c.md)

Used to configure hierarchial settings in Nebula Logger to provide user-specific &amp; profile-specific customizations

### [LoggerSObjectHandler\_\_mdt](custom-objects\LoggerSObjectHandler__mdt.md)

Used to configure Apex trigger handler classes in Nebula Logger that run on the included objects LogEntryEvent**e, LoggerScenario**c, Log**c, LogEntry**c, LogEntryTag**c, and LoggerTag**c

### [LoggerTag\_\_c](custom-objects\LoggerTag__c.md)

Used by Nebula Logger for storing unique tags (text/String) that can be associated with LogEntry**c records via the junction object LogEntryTag**c

### [LogStatus\_\_mdt](custom-objects\LogStatus__mdt.md)

Used to configure in Nebula Logger which picklist values in Log**c.Status**c are considered open/closed and resolved/unresolved

## Logger Engine

### [CallableLogger](logger-engine\CallableLogger.md)

A class that implements the standard interface `System.Callable` . This provides 2 benefits:

1. A loosely-coupled way to optionally integrate with Nebula Logger (useful for ISVs/package developers).
2. The ability to log in OmniStudio&#x27;s OmniScripts &amp; Integration Procedures.

### [FlowCollectionLogEntry](logger-engine\FlowCollectionLogEntry.md)

Handles adding new log entries in Flow for a particular `SObject` record collection

### [FlowLogEntry](logger-engine\FlowLogEntry.md)

Handles adding new log entries in Flow

### [FlowRecordLogEntry](logger-engine\FlowRecordLogEntry.md)

Handles adding new log entries in Flow for a particular `SObject` record

### [LogEntryEventBuilder](logger-engine\LogEntryEventBuilder.md)

Builder class that generates each `LogEntryEvent__e` record

### [Logger](logger-engine\Logger.md)

The core class for logging

### [LogMessage](logger-engine\LogMessage.md)

Provides the ability to generate string messages on demand, using String.format()

## Triggers

### [Log](triggers\Log.md)

### [LogEntry](triggers\LogEntry.md)

### [LogEntryEvent](triggers\LogEntryEvent.md)

### [LogEntryTag](triggers\LogEntryTag.md)

### [LoggerScenario](triggers\LoggerScenario.md)

### [LoggerTag](triggers\LoggerTag.md)
