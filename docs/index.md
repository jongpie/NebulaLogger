---
layout: default
---

# Classes

## Logger Engine

### [ComponentLogger](logger-engine/ComponentLogger)

Controller class used by the lightning web component `logger`

### [FlowCollectionLogEntry](logger-engine/FlowCollectionLogEntry)

Handles adding new log entries in Flow for a particular `SObject` record collection

### [FlowLogEntry](logger-engine/FlowLogEntry)

Handles adding new log entries in Flow

### [FlowLogger](logger-engine/FlowLogger)

Handles some common logic used by `FlowLogEntry`, `FlowRecordLogEntry` and `FlowCollectionLogEntry`

### [FlowRecordLogEntry](logger-engine/FlowRecordLogEntry)

Handles adding new log entries in Flow for a particular `SObject` record

### [LogEntryEventBuilder](logger-engine/LogEntryEventBuilder)

Builder class that generates each `LogEntryEvent__e` record

### [LogMessage](logger-engine/LogMessage)

Provides the ability to generate string messages on demand, using String.format()

### [Logger](logger-engine/Logger)

The core class for logging

## Log Management

### [LogBatchPurgeScheduler](log-management/LogBatchPurgeScheduler)

Schedulable class used to schedule the batch job `LogBatchPurger`

### [LogBatchPurger](log-management/LogBatchPurger)

Batch class used to delete old logs, based on `Log__c.LogRetentionDate__c &lt;= :System.today()`

### [LogEntryEventHandler](log-management/LogEntryEventHandler)

Processes `LogEntryEvent__e` platform events and normalizes the data into `Log__c` and `LogEntry__c` records

### [LogEntryFieldSetPicklist](log-management/LogEntryFieldSetPicklist)

Dynamically returns `LogEntry__c` field sets in App Builder when configuring the component RelatedLogEntries

### [LogEntryHandler](log-management/LogEntryHandler)

Manages setting fields on `LogEntry__c` before insert &amp; before update

### [LogEntryTagHandler](log-management/LogEntryTagHandler)

Handles trigger events for the `LogEntryTag__c` object

### [LogHandler](log-management/LogHandler)

Manages setting fields on `Log__c` before insert &amp; before update

### [LogMassDeleteExtension](log-management/LogMassDeleteExtension)

Manages mass deleting `Log__c` records that have been selected by a user on a `Log__c` list view

### [LoggerSObjectHandler](log-management/LoggerSObjectHandler)

Abstract class used by trigger handlers for shared logic

### [LoggerTagHandler](log-management/LoggerTagHandler)

Handles trigger events for the `LoggerTag__c` object

### [RelatedLogEntriesController](log-management/RelatedLogEntriesController)

Controller class for the lightning web component `related-log-entries`

## Plugin Framework

### [LoggerParameter](plugin-framework/LoggerParameter)

Provides a centralized way to load parameters for SObject handlers &amp; plugins, and casts the parameters to common data types

### [LoggerSObjectHandlerPlugin](plugin-framework/LoggerSObjectHandlerPlugin)

Abstract class used to create custom Apex plugins to execute for all trigger operations on `Log__c` or `LogEntry__c`
