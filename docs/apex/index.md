---
layout: default
---

# Nebula Logger for Apex

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

### [LoggerBatchableContext](log-management/LoggerBatchableContext)

Class used by the logging system for batch contextual details

### [LoggerEmailUtils](log-management/LoggerEmailUtils)

Builds and sends email notifications when internal exceptions occur within the logging system

### [LoggerSObjectHandler](log-management/LoggerSObjectHandler)

Abstract class used by trigger handlers for shared logic

### [LoggerSObjectMetadata](log-management/LoggerSObjectMetadata)

Provides details to LWCs about Logger&apos;s `SObjects`, using `@AuraEnabled` properties

### [LoggerSettingsController](log-management/LoggerSettingsController)

Controller class for lwc `loggerSettings`, used to manage records in `LoggerSettings__c`

### [LoggerTagHandler](log-management/LoggerTagHandler)

Handles trigger events for the `LoggerTag__c` object

### [LoggerTriggerableContext](log-management/LoggerTriggerableContext)

Class used by the logging system for trigger contextual details

### [RelatedLogEntriesController](log-management/RelatedLogEntriesController)

Controller class for the lightning web component `related-log-entries`

## Plugins

### [LogEntryArchiveBuilder](plugins/LogEntryArchiveBuilder)

Builder class to create an instance of `LogEntryArchive__b`, used by the BigObject plugin

### [LogEntryArchiveController](plugins/LogEntryArchiveController)

Controller class used by the LWC `logEntryArchives` to display `LogEntryArchive__b` data

### [LogEntryArchivePlugin](plugins/LogEntryArchivePlugin)

Optional plugin that provides a BigObject, `LogEntryArchive__b`, as an alternative option to the platform event `LogEntryEvent__e`

### [LogRetentionRulesPlugin](plugins/LogRetentionRulesPlugin)

Optional plugin that adds the ability to create &amp; deploy advanced, configurable rules for setting the retention date of `Log__c` records, using custom metadata types `LogRetentionRule_t` and `LogRetentionRuleCondition_t`.

### [SlackLoggerPlugin](plugins/SlackLoggerPlugin)

Optional plugin that integrates with Slack to send alerts for important logs

## Configuration

### [LoggerParameter](configuration/LoggerParameter)

Provides a centralized way to load parameters for SObject handlers &amp; plugins, and casts the parameters to common data types

### [LoggerPlugin](configuration/LoggerPlugin)

The core of the plugin framework, used to create custom Apex &amp; Flow plugins for `LoggerSObjectHandler` and `LogBatchPurger` based on configurations stored in the custom metadata type `LoggerPlugin_t`

### [LoggerSObjectTestDataGenerator](configuration/LoggerSObjectTestDataGenerator)

Class used to create or update an `SObject` record with static fake data. This is useful in situations where you need to have fields populated, but the specific values used are not relevant to a particular test. This class can be used when Apex writing tests for plugins.

### [LoggerTestUtils](configuration/LoggerTestUtils)

Utility class used to help with writing Apex tests Nebula Logger. These methods can be used when writing Apex tests for plugins.
