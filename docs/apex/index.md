---
layout: default
---

# Nebula Logger for Apex

## Logger Engine

### [ComponentLogger](Logger-Engine/ComponentLogger)

Controller class used by the lightning web component `logger`

### [FlowCollectionLogEntry](Logger-Engine/FlowCollectionLogEntry)

Handles adding new log entries in Flow for a particular `SObject` record collection

### [FlowLogEntry](Logger-Engine/FlowLogEntry)

Handles adding new log entries in Flow

### [FlowLogger](Logger-Engine/FlowLogger)

Handles some common logic used by `FlowLogEntry`, `FlowRecordLogEntry` and `FlowCollectionLogEntry`

### [FlowRecordLogEntry](Logger-Engine/FlowRecordLogEntry)

Handles adding new log entries in Flow for a particular `SObject` record

### [LogEntryEventBuilder](Logger-Engine/LogEntryEventBuilder)

Builder class that generates each `LogEntryEvent__e` record

### [LogMessage](Logger-Engine/LogMessage)

Provides the ability to generate string messages on demand, using String.format()

### [Logger](Logger-Engine/Logger)

The core class for logging

### [LoggerCache](Logger-Engine/LoggerCache)

Class used to cache query results returned by the selector classes

### [LoggerDataStore](Logger-Engine/LoggerDataStore)

Class used to manage any data-related operations, including database DML statements, publishing platform events via the event bus, and enqueueing queueable jobs

### [LoggerEngineDataSelector](Logger-Engine/LoggerEngineDataSelector)

Selector class used for all queries that are specific to the logger engine layer

### [LoggerSObjectHandler](Logger-Engine/LoggerSObjectHandler)

Abstract class used by trigger handlers for shared logic

### [LoggerTriggerableContext](Logger-Engine/LoggerTriggerableContext)

Class used by the logging system for trigger contextual details

## Log Management

### [LogBatchPurgeController](Log-Management/LogBatchPurgeController)

Controller class for lwc `logBatchPurge`, used to provide metrics of `Log__c`, `LogEntry__c`, `LogEntryTag__c` records to purge and allow user to manually run `LogBatchPurger` from the UI.

### [LogBatchPurgeScheduler](Log-Management/LogBatchPurgeScheduler)

Schedulable class used to schedule the batch job `LogBatchPurger`

### [LogBatchPurger](Log-Management/LogBatchPurger)

Batch class used to delete old logs, based on `Log__c.LogRetentionDate__c &lt;= :System.today()`

### [LogEntryEventHandler](Log-Management/LogEntryEventHandler)

Processes `LogEntryEvent__e` platform events and normalizes the data into `Log__c` and `LogEntry__c` records

### [LogEntryFieldSetPicklist](Log-Management/LogEntryFieldSetPicklist)

Dynamically returns `LogEntry__c` field sets in App Builder when configuring the component RelatedLogEntries

### [LogEntryHandler](Log-Management/LogEntryHandler)

Manages setting fields on `LogEntry__c` before insert &amp; before update

### [LogEntryTagHandler](Log-Management/LogEntryTagHandler)

Handles trigger events for the `LogEntryTag__c` object

### [LogHandler](Log-Management/LogHandler)

Manages setting fields on `Log__c` before insert &amp; before update

### [LogManagementDataSelector](Log-Management/LogManagementDataSelector)

Selector class used for all queries that are specific to the log management layer

### [LogMassDeleteExtension](Log-Management/LogMassDeleteExtension)

Manages mass deleting `Log__c` records that have been selected by a user on a `Log__c` list view

### [LogViewerController](Log-Management/LogViewerController)

Controller class for the LWC `logViewer`, used to provided different views on a `Log__c` record

### [LoggerBatchableContext](Log-Management/LoggerBatchableContext)

Class used by the logging system for batch contextual details

### [LoggerEmailSender](Log-Management/LoggerEmailSender)

Builds and sends email notifications when internal exceptions occur within the logging system

### [LoggerSObjectMetadata](Log-Management/LoggerSObjectMetadata)

Provides details to LWCs about Logger&apos;s `SObjects`, using `@AuraEnabled` properties

### [LoggerScenarioHandler](Log-Management/LoggerScenarioHandler)

Handles trigger events for the `LoggerScenario__c` object

### [LoggerSettingsController](Log-Management/LoggerSettingsController)

Controller class for lwc `loggerSettings`, used to manage records in `LoggerSettings__c`

### [LoggerTagHandler](Log-Management/LoggerTagHandler)

Handles trigger events for the `LoggerTag__c` object

### [RelatedLogEntriesController](Log-Management/RelatedLogEntriesController)

Controller class for the lightning web component `related-log-entries`

## Test Utilities

### [LoggerMockDataCreator](/Test-Utilities/LoggerMockDataCreator)

Utility class used to help with generating mock data when writing Apex tests for Nebula Logger. These methods are generic, and should work in any Salesforce org. These methods can be used when writing Apex tests for plugins.

### [LoggerMockDataStore](/Test-Utilities/LoggerMockDataStore)

Utility class used to mock any data-related operations for the database, event bus, and queueable jobs. These methods are generic, and should work in any Salesforce org. These methods can be used when writing Apex tests for plugins.

### [LoggerTestConfigurator](/Test-Utilities/LoggerTestConfigurator)

Utility class used to help with setting up Nebula Logger&apos;s configurations within a test context. These methods are specific to metadata implemented within Nebula Logger. These methods can be used when writing Apex tests for plugins.

## Configuration

### [LoggerParameter](Configuration/LoggerParameter)

Provides a centralized way to load parameters for SObject handlers &amp; plugins, and casts the parameters to common data types

### [LoggerPlugin](Configuration/LoggerPlugin)

The core of the plugin framework, used to create custom Apex &amp; Flow plugins for `LoggerSObjectHandler` and `LogBatchPurger` based on configurations stored in the custom metadata type `LoggerPlugin_t`
