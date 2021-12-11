# Classes

## Logger Engine

### [ComponentLogger](/Logger-Engine/ComponentLogger.md)

Controller class used by the lightning web component `logger`

### [FlowCollectionLogEntry](/Logger-Engine/FlowCollectionLogEntry.md)

Handles adding new log entries in Flow for a particular `SObject` record collection

### [FlowLogEntry](/Logger-Engine/FlowLogEntry.md)

Handles adding new log entries in Flow

### [FlowLogger](/Logger-Engine/FlowLogger.md)

Handles some common logic used by `FlowLogEntry`, `FlowRecordLogEntry` and `FlowCollectionLogEntry`

### [FlowRecordLogEntry](/Logger-Engine/FlowRecordLogEntry.md)

Handles adding new log entries in Flow for a particular `SObject` record

### [LogEntryEventBuilder](/Logger-Engine/LogEntryEventBuilder.md)

Builder class that generates each `LogEntryEvent__e` record

### [LogMessage](/Logger-Engine/LogMessage.md)

Provides the ability to generate string messages on demand, using String.format()

### [Logger](/Logger-Engine/Logger.md)

The core class for logging

## Log Management

### [LogBatchPurgeScheduler](/Log-Management/LogBatchPurgeScheduler.md)

Schedulable class used to schedule the batch job `LogBatchPurger`

### [LogBatchPurger](/Log-Management/LogBatchPurger.md)

Batch class used to delete old logs, based on `Log__c.LogRetentionDate__c &lt;= :System.today()`

### [LogEntryEventHandler](/Log-Management/LogEntryEventHandler.md)

Processes `LogEntryEvent__e` platform events and normalizes the data into `Log__c` and `LogEntry__c` records

### [LogEntryFieldSetPicklist](/Log-Management/LogEntryFieldSetPicklist.md)

Dynamically returns `LogEntry__c` field sets in App Builder when configuring the component RelatedLogEntries

### [LogEntryHandler](/Log-Management/LogEntryHandler.md)

Manages setting fields on `LogEntry__c` before insert &amp; before update

### [LogEntryTagHandler](/Log-Management/LogEntryTagHandler.md)

Handles trigger events for the `LogEntryTag__c` object

### [LogHandler](/Log-Management/LogHandler.md)

Manages setting fields on `Log__c` before insert &amp; before update

### [LogMassDeleteExtension](/Log-Management/LogMassDeleteExtension.md)

Manages mass deleting `Log__c` records that have been selected by a user on a `Log__c` list view

### [LoggerSObjectHandler](/Log-Management/LoggerSObjectHandler.md)

Abstract class used by trigger handlers for shared logic

### [LoggerSettingsController](/Log-Management/LoggerSettingsController.md)

Controller class for lwc `loggerSettings`, used to manage records in `LoggerSettings__c`

### [LoggerTagHandler](/Log-Management/LoggerTagHandler.md)

Handles trigger events for the `LoggerTag__c` object

### [RelatedLogEntriesController](/Log-Management/RelatedLogEntriesController.md)

Controller class for the lightning web component `related-log-entries`

## Configuration

### [LoggerEmailUtils](/Configuration/LoggerEmailUtils.md)

Builds and sends email notifications when internal exceptions occur within the logging system

### [LoggerParameter](/Configuration/LoggerParameter.md)

Provides a centralized way to load parameters for SObject handlers &amp; plugins, and casts the parameters to common data types

## Plugin Framework

### [LoggerSObjectHandlerPlugin](/Plugin-Framework/LoggerSObjectHandlerPlugin.md)

Abstract class used to create custom Apex plugins to execute for all trigger operations on `Log__c` or `LogEntry__c`
