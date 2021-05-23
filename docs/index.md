---
layout: default
---
# Classes
## Logger Engine

### [FlowLogEntry](Logger-Engine/FlowLogEntry)


Handles adding new log entries in Flow



### [FlowRecordLogEntry](Logger-Engine/FlowRecordLogEntry)


Handles adding new log entries in Flow for a particular `SObject` record



### [LogEntryEventBuilder](Logger-Engine/LogEntryEventBuilder)


Builder class that generates each `LogEntryEvent__e` record



### [LogMessage](Logger-Engine/LogMessage)


Provides the ability to generate string messages on demand, using String.format()



### [Logger](Logger-Engine/Logger)


The core class for logging


## Log Management

### [LogBatchPurgeScheduler](Log-Management/LogBatchPurgeScheduler)


Schedulable class used to schedule the batch job `LogBatchPurger`



### [LogBatchPurger](Log-Management/LogBatchPurger)


Batch class used to delete old logs, based on `Log__c.LogRetentionDate__c <= :System.today()`



### [LogEntryEventHandler](Log-Management/LogEntryEventHandler)


Subscribes to `LogEntryEvent__e` platform events and normalizes the data into `Log__c` and `LogEntry__c` records



### [LogEntryFieldSetPicklist](Log-Management/LogEntryFieldSetPicklist)


Dynamically returns `LogEntry__c` field sets in App Builder when configuring the component RelatedLogEntries



### [LogEntryHandler](Log-Management/LogEntryHandler)


Manages setting fields on `LogEntry__c` before insert & before update



### [LogHandler](Log-Management/LogHandler)


Manages setting fields on `Log__c` before insert & before update



### [LogMassDeleteExtension](Log-Management/LogMassDeleteExtension)


Manages mass deleting `Log__c` records that have been selected by a user on a `Log__c` list view



### [RelatedLogEntriesController](Log-Management/RelatedLogEntriesController)


Controller class for the component RelatedLogEntries


