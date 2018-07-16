/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class LogEntryEventHandler {

    private static final Log__c LOG = new Log__c();

    List<LogEntry__c> logEntries;
    Map<LogEntry__c, List<String>> logEntryToTopics;
    Set<String> topicNames;
    List<Topic> topics;
    List<TopicAssignment> topicAssignments;

    public LogEntryEventHandler() {
        this.logEntries       = new List<LogEntry__c>();
        this.logEntryToTopics = new Map<LogEntry__c, List<String>>();
        this.topicNames       = new Set<String>();
        this.topics           = new List<Topic>();
        this.topicAssignments = new List<TopicAssignment>();
    }

    public void execute() {
        this.insertLog();
        this.insertLogEntries();
        this.insertTopics();
    }

    private void insertLog() {
        if(LOG.Id != null) return; // Log only needs to be saved once
        if(Trigger.new == null) return; // This class should only be used in a trigger context...
        if(Trigger.new.getSobjectType() != Schema.LogEntryEvent__e.SobjectType) return; //...for the LogEntryEvent__e object

        // The LogEntryEvent__e object stores a denormalized version of Log__c & LogEntry__c data
        // The first LogEntryEvent__e record is used to normalize the data
        LogEntryEvent__e logEntryEvent = (LogEntryEvent__e)Trigger.new[0];

        LOG.ContextIsApexRest__c       = logEntryEvent.ContextIsApexRest__c;
        LOG.ContextIsBatch__c          = logEntryEvent.ContextIsBatch__c;
        LOG.ContextIsFuture__c         = logEntryEvent.ContextIsFuture__c;
        LOG.ContextIsQueueable__c      = logEntryEvent.ContextIsQueueable__c;
        LOG.ContextIsScheduledJob__c   = logEntryEvent.ContextIsScheduledJob__c;
        LOG.ContextThemeDisplayed__c   = logEntryEvent.ContextThemeDisplayed__c;
        LOG.LoggedBy__c                = logEntryEvent.CreatedById;
        LOG.OwnerId                    = logEntryEvent.CreatedById;
        LOG.TransactionId__c           = logEntryEvent.TransactionId__c;
        LOG.UserLoggingLevel__c        = logEntryEvent.UserLoggingLevel__c;
        LOG.UserLoggingLevelOrdinal__c = logEntryEvent.UserLoggingLevelOrdinal__c;
        insert log;
    }

    private void insertLogEntries() {
        if(LOG.Id == null) return; // Avoid an exception - if there is no log, we can't save log entries

        for(LogEntryEvent__e logEntryEvent : (List<LogEntryEvent__e>)Trigger.new) {
            LogEntry__c logEntry = new LogEntry__c(
                ContextIsLightningComponent__c    = logEntryEvent.ContextIsLightningComponent__c,
                ContextIsTriggerExecuting__c      = logEntryEvent.ContextIsTriggerExecuting__c,
                ContextIsVisualforce__c           = logEntryEvent.ContextIsVisualforce__c,
                ContextLightningComponentName__c  = logEntryEvent.ContextLightningComponentName__c,
                ContextTriggerOperationType__c    = logEntryEvent.ContextTriggerOperationType__c,
                ContextTriggerSobjectType__c      = logEntryEvent.ContextTriggerSobjectType__c,
                ContextVisualforcePage__c         = logEntryEvent.ContextVisualforcePage__c,
                ExceptionStackTrace__c            = logEntryEvent.ExceptionStackTrace__c,
                ExceptionType__c                  = logEntryEvent.ExceptionType__c,
                LimitsAggregateQueriesMax__c      = logEntryEvent.LimitsAggregateQueriesMax__c,
                LimitsAggregateQueriesUsed__c     = logEntryEvent.LimitsAggregateQueriesUsed__c,
                LimitsAsyncCallsMax__c            = logEntryEvent.LimitsAsyncCallsMax__c,
                LimitsAsyncCallsUsed__c           = logEntryEvent.LimitsAsyncCallsUsed__c,
                LimitsCalloutsMax__c              = logEntryEvent.LimitsCalloutsMax__c,
                LimitsCalloutsUsed__c             = logEntryEvent.LimitsCalloutsUsed__c,
                LimitsCpuTimeMax__c               = logEntryEvent.LimitsCpuTimeMax__c,
                LimitsCpuTimeUsed__c              = logEntryEvent.LimitsCpuTimeUsed__c,
                LimitsDmlRowsMax__c               = logEntryEvent.LimitsDmlRowsMax__c,
                LimitsDmlRowsUsed__c              = logEntryEvent.LimitsDmlRowsUsed__c,
                LimitsDmlStatementsMax__c         = logEntryEvent.LimitsDmlStatementsMax__c,
                LimitsDmlStatementsUsed__c        = logEntryEvent.LimitsDmlStatementsUsed__c,
                LimitsEmailInvocationsMax__c      = logEntryEvent.LimitsEmailInvocationsMax__c,
                LimitsEmailInvocationsUsed__c     = logEntryEvent.LimitsEmailInvocationsUsed__c,
                LimitsFutureCallsMax__c           = logEntryEvent.LimitsFutureCallsMax__c,
                LimitsFutureCallsUsed__c          = logEntryEvent.LimitsFutureCallsUsed__c,
                LimitsHeapSizeMax__c              = logEntryEvent.LimitsHeapSizeMax__c,
                LimitsHeapSizeUsed__c             = logEntryEvent.LimitsHeapSizeUsed__c,
                LimitsMobilePushApexCallsMax__c   = logEntryEvent.LimitsMobilePushApexCallsMax__c,
                LimitsMobilePushApexCallsUsed__c  = logEntryEvent.LimitsMobilePushApexCallsUsed__c,
                LimitsQueueableJobsMax__c         = logEntryEvent.LimitsQueueableJobsMax__c,
                LimitsQueueableJobsUsed__c        = logEntryEvent.LimitsQueueableJobsUsed__c,
                LimitsSoqlQueriesMax__c           = logEntryEvent.LimitsSoqlQueriesMax__c,
                LimitsSoqlQueriesUsed__c          = logEntryEvent.LimitsSoqlQueriesUsed__c,
                LimitsSoqlQueryLocatorRowsMax__c  = logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c,
                LimitsSoqlQueryLocatorRowsUsed__c = logEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c,
                LimitsSoqlQueryRowsMax__c         = logEntryEvent.LimitsSoqlQueryRowsMax__c,
                LimitsSoqlQueryRowsUsed__c        = logEntryEvent.LimitsSoqlQueryRowsUsed__c,
                LimitsSoslSearchesUsed__c         = logEntryEvent.LimitsSoslSearchesUsed__c,
                LimitsSoslSearchesMax__c          = logEntryEvent.LimitsSoslSearchesMax__c,
                Log__c                            = LOG.Id,
                LoggingLevel__c                   = logEntryEvent.LoggingLevel__c,
                LoggingLevelOrdinal__c            = logEntryEvent.LoggingLevelOrdinal__c,
                Message__c                        = logEntryEvent.Message__c,
                MessageTruncated__c               = logEntryEvent.MessageTruncated__c,
                Name                              = logEntryEvent.TransactionEntryId__c,
                OriginType__c                     = logEntryEvent.OriginType__c,
                OriginLocation__c                 = logEntryEvent.OriginLocation__c,
                Timestamp__c                      = logEntryEvent.Timestamp__c,
                TransactionEntryId__c             = logEntryEvent.TransactionEntryId__c,
                Type__c                           = logEntryEvent.Type__c
            );
            this.logEntries.add(logEntry);

            if(logEntryEvent.Topics__c != null) {
                this.topicNames.addAll(logEntryEvent.Topics__c.split(','));
                this.logEntryToTopics.put(logEntry, LogEntryEvent.Topics__c.split(','));
            }
        }
        insert logEntries;
    }

    private void insertTopics() {
        if(this.topicNames.isEmpty()) return;

        // Query for existing topics
        Map<String, Topic> topicNameToTopics = new Map<String, Topic>();
        for(Topic topic : [SELECT Id, Name FROM Topic WHERE Name IN :this.topicNames]) {
            topicNameToTopics.put(topic.Name, topic);
        }
        // Create any new topics
        List<Topic> topicsToCreate = new List<Topic>();
        for(String topicName : this.topicNames) {
            if(topicNameToTopics.get(topicName) != null) continue;

            topicsToCreate.add(new Topic(Name = topicName));
        }
        if(!topicsToCreate.isEmpty()) {
            insert topicsToCreate;
            for(Topic topic : topicsToCreate) {
                topicNameToTopics.put(topic.Name, topic);
            }
        }

        // Assign the topics to the records
        Set<TopicAssignment> topicAssignments = new Set<TopicAssignment>();
        for(LogEntry__c logEntry : logEntryToTopics.keySet()) {
            for(String topicName : logEntryToTopics.get(logEntry)) {
                // Add log entry-specific topics
                topicAssignments.add(new TopicAssignment(
                    EntityId = logEntry.Id,
                    TopicId  = topicNameToTopics.get(topicName).Id
                ));

                if(!LoggerSettings__c.getInstance().AddLogEntryTopicsToLog__c) continue;

                // Add all topics to the parent log when enabled
                topicAssignments.add(new TopicAssignment(
                    EntityId = LOG.Id,
                    TopicId  = topicNameToTopics.get(topicName).Id
                ));
            }
        }
        insert new List<TopicAssignment>(topicAssignments);
    }

}