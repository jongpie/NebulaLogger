---
layout: default
---
# Nebula Logger: Documentation
# Classes
## logger-engine

### [FlowLogEntry](/logger-engine/FlowLogEntry.md)


Handles adding new log entryies in Flow



### [FlowRecordLogEntry](/logger-engine/FlowRecordLogEntry.md)


Handles adding new log entryies in Flow for a particular SObject record



### [LogEntryEventBuilder](/logger-engine/LogEntryEventBuilder.md)


Builder class that generates each LogEntryEvent__c record



### [LogMessage](/logger-engine/LogMessage.md)


Provides the ability to generate string messages on demand, using String.format()



### [Logger](/logger-engine/Logger.md)


The core class for logging


## log-management

### [LogBatchPurgeScheduler](/log-management/LogBatchPurgeScheduler.md)


Schedulable class used schedule the batch job LogBatchPurger



### [LogBatchPurger](/log-management/LogBatchPurger.md)


Batch class used to delete old logs, based on Log__c.LogRetentionDate__c <= :System.today()



### [LogEntryEventHandler](/log-management/LogEntryEventHandler.md)


Subscribes to LogEntryEvent__e platform events and normalizes the data into Log__c and LogEntry__c records



### [LogEntryHandler](/log-management/LogEntryHandler.md)


Manages setting fields on LogEntry__c before insert & update



### [LogHandler](/log-management/LogHandler.md)


Manages setting fields on Log__c before insert & update


## packaging

### [LoggerInstallHandler](/packaging/LoggerInstallHandler.md)


Automatically enables org default settings when installing the managed package


