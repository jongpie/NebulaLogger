---
layout: default
---
# Nebula Logger: Documentation
# Classes
## logger-engine

### [FlowLogEntry](nebula-logger-docs/logger-engine/FlowLogEntry.md)


Handles adding new log entryies in Flow



### [FlowRecordLogEntry](nebula-logger-docs/logger-engine/FlowRecordLogEntry.md)


Handles adding new log entryies in Flow for a particular SObject record



### [LogEntryEventBuilder](nebula-logger-docs/logger-engine/LogEntryEventBuilder.md)


Builder class that generates each LogEntryEvent__c record



### [LogMessage](nebula-logger-docs/logger-engine/LogMessage.md)


Provides the ability to generate string messages on demand, using String.format()



### [Logger](nebula-logger-docs/logger-engine/Logger.md)


The core class for logging


## log-management

### [LogBatchPurgeScheduler](nebula-logger-docs/log-management/LogBatchPurgeScheduler.md)


Schedulable class used schedule the batch job LogBatchPurger



### [LogBatchPurger](nebula-logger-docs/log-management/LogBatchPurger.md)


Batch class used to delete old logs, based on Log__c.LogRetentionDate__c <= :System.today()



### [LogEntryEventHandler](nebula-logger-docs/log-management/LogEntryEventHandler.md)


Subscribes to LogEntryEvent__e platform events and normalizes the data into Log__c and LogEntry__c records



### [LogEntryHandler](nebula-logger-docs/log-management/LogEntryHandler.md)


Manages setting fields on LogEntry__c before insert & update



### [LogHandler](nebula-logger-docs/log-management/LogHandler.md)


Manages setting fields on Log__c before insert & update


## packaging

### [LoggerInstallHandler](nebula-logger-docs/packaging/LoggerInstallHandler.md)


Automatically enables org default settings when installing the managed package


