/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
trigger LogEntryEvent on LogEntryEvent__e(after insert) {

    Set<Log__c> logs = new Set<Log__c>();
    List<LogEntry__c> logEntries = new List<LogEntry__c>();
    Set<String> topicNames = new Set<String>();
    Map<LogEntry__c, List<String>> logEntryToTopics = new Map<LogEntry__c, List<String>>();

    for(LogEntryEvent__e logEntryEvent : Trigger.new) {
        logs.add(new Log__c(
            ContextIsApexRest__c       = logEntryEvent.ContextIsApexRest__c,
            ContextIsBatch__c          = logEntryEvent.ContextIsBatch__c,
            ContextIsFuture__c         = logEntryEvent.ContextIsFuture__c,
            ContextIsQueueable__c      = logEntryEvent.ContextIsQueueable__c,
            ContextIsScheduledJob__c   = logEntryEvent.ContextIsScheduledJob__c,
            ContextThemeDisplayed__c   = logEntryEvent.ContextThemeDisplayed__c,
            LoggedBy__c                = logEntryEvent.CreatedById,
            OwnerId                    = logEntryEvent.CreatedById,
            TransactionId__c           = logEntryEvent.TransactionId__c,
            UserLoggingLevel__c        = logEntryEvent.UserLoggingLevel__c,
            UserLoggingLevelOrdinal__c = logEntryEvent.UserLoggingLevelOrdinal__c
        ));
        LogEntry__c logEntry = new LogEntry__c(
            ContextIsTriggerExecuting__c      = logEntryEvent.ContextIsTriggerExecuting__c,
            ContextIsVisualforce__c           = logEntryEvent.ContextIsVisualforce__c,
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
            Log__r                            = new Log__c(TransactionId__c = logEntryEvent.TransactionId__c),
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
        logEntries.add(logEntry);

        if(logEntryEvent.Topics__c != null) {
            topicNames.addAll(logEntryEvent.Topics__c.split(','));
            logEntryToTopics.put(logEntry, LogEntryEvent.Topics__c.split(','));
        }
    }
    upsert new List<Log__c>(logs) TransactionId__c;
    upsert logEntries TransactionEntryId__c;

    if(topicNames.isEmpty()) return;

    // Query for existing topics
    Map<String, Topic> topicNameToTopics = new Map<String, Topic>();
    for(Topic topic : [SELECT Id, Name FROM Topic WHERE Name IN :topicNames]) {
        topicNameToTopics.put(topic.Name, topic);
    }
    // Create any new topics
    List<Topic> topicsToCreate = new List<Topic>();
    for(String topicName : topicNames) {
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
            // Add all topics to the parent log
            topicAssignments.add(new TopicAssignment(
                EntityId = new List<Log__c>(logs)[0].Id,
                TopicId  = topicNameToTopics.get(topicName).Id
            ));
            // Add log entry-specific topics
            topicAssignments.add(new TopicAssignment(
                EntityId = logEntry.Id,
                TopicId  = topicNameToTopics.get(topicName).Id
            ));
        }
    }
    insert new List<TopicAssignment>(topicAssignments);

}