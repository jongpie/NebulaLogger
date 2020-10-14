/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class LogEntryEventHandler {

    private static final Log__c LOG = new Log__c();

    private List<LogEntry__c> logEntries;
    private Map<LogEntry__c, List<String>> logEntryToTopics;
    private Set<String> topicNames;
    private List<Topic> topics;
    private List<TopicAssignment> topicAssignments;

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
        if(Trigger.new.getSObjectType() != Schema.LogEntryEvent__e.SObjectType) return; //...for the LogEntryEvent__e object

        // The LogEntryEvent__e object stores a denormalized version of Log__c & LogEntry__c data
        // The first LogEntryEvent__e record is used to normalize the data
        LogEntryEvent__e logEntryEvent  = (LogEntryEvent__e)Trigger.new[0];
        Log__c parentLog                = new Log__c(TransactionId__c = logEntryEvent.ParentLogTransactionId__c);

        LOG.ApiVersion__c               = logEntryEvent.ApiVersion__c;
        LOG.ContextThemeDisplayed__c    = logEntryEvent.ContextThemeDisplayed__c;
        LOG.Locale__c                   = logEntryEvent.Locale__c;
        LOG.LoggedBy__c                 = logEntryEvent.CreatedById;
        LOG.LoginDomain__c              = logEntryEvent.LoginDomain__c;
        LOG.LoginHistoryId__c           = logEntryEvent.LoginHistoryId__c;
        LOG.LoginType__c                = logEntryEvent.LoginType__c;
        LOG.LogoutUrl__c                = logEntryEvent.LogoutUrl__c;
        LOG.NetworkId__c                = logEntryEvent.NetworkId__c;
        LOG.OwnerId                     = logEntryEvent.CreatedById;
        LOG.ParentLog__r                = logEntryEvent.ParentLogTransactionId__c == null ? null : parentLog;
        LOG.ProfileId__c                = logEntryEvent.ProfileId__c;
        LOG.ProfileName__c              = logEntryEvent.ProfileName__c;
        LOG.SessionId__c                = logEntryEvent.SessionId__c;
        LOG.SessionId__c                = logEntryEvent.SessionId__c;
        LOG.SessionSecurityLevel__c     = logEntryEvent.SessionSecurityLevel__c;
        LOG.SessionType__c              = logEntryEvent.SessionType__c;
        LOG.SourceIp__c                 = logEntryEvent.SourceIp__c;
        LOG.SystemModeIsApexRest__c     = logEntryEvent.SystemModeIsApexRest__c;
        LOG.SystemModeIsBatch__c        = logEntryEvent.SystemModeIsBatch__c;
        LOG.SystemModeIsFuture__c       = logEntryEvent.SystemModeIsFuture__c;
        LOG.SystemModeIsQueueable__c    = logEntryEvent.SystemModeIsQueueable__c;
        LOG.SystemModeIsScheduledJob__c = logEntryEvent.SystemModeIsScheduledJob__c;
        LOG.TimeZoneId__c               = logEntryEvent.TimeZoneId__c;
        LOG.TimeZoneName__c             = logEntryEvent.TimeZoneName__c;
        LOG.TransactionId__c            = logEntryEvent.TransactionId__c;
        LOG.UserLoggingLevel__c         = logEntryEvent.UserLoggingLevel__c;
        LOG.UserLoggingLevelOrdinal__c  = logEntryEvent.UserLoggingLevelOrdinal__c;
        LOG.UserRoleId__c               = logEntryEvent.UserRoleId__c;
        LOG.UserRoleName__c             = logEntryEvent.UserRoleName__c;
        LOG.UserType__c                 = logEntryEvent.UserType__c;

        if(LOG.SystemModeIsApexRest__c)          LOG.SystemMode__c = 'REST';
        else if(LOG.SystemModeIsBatch__c)        LOG.SystemMode__c = 'Batch';
        else if(LOG.SystemModeIsFuture__c)       LOG.SystemMode__c = 'Future';
        else if(LOG.SystemModeIsQueueable__c)    LOG.SystemMode__c = 'Queueable';
        else if(LOG.SystemModeIsScheduledJob__c) LOG.SystemMode__c = 'Scheduled';
        else                                     LOG.SystemMode__c = 'Standard';

        upsert log TransactionId__c;
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
                ContextTriggerSObjectType__c      = logEntryEvent.ContextTriggerSObjectType__c,
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
                Name                              = null, // Salesforce will auto-set the record ID as the name when null
                OriginType__c                     = logEntryEvent.OriginType__c,
                OriginLocation__c                 = logEntryEvent.OriginLocation__c,
                RelatedRecordId__c                = logEntryEvent.RelatedRecordId__c,
                RelatedRecordJson__c              = logEntryEvent.RelatedRecordJson__c,
                StackTrace__c                     = logEntryEvent.StackTrace__c,
                Timestamp__c                      = logEntryEvent.Timestamp__c,
                Type__c                           = logEntryEvent.Type__c
            );

            if(logEntry.ContextLightningComponentName__c != null) logEntry.Context__c = 'Component';
            else if(logEntry.FlowName__c != null) logEntry.Context__c = 'Flow';
            else if(logEntry.ContextIsTriggerExecuting__c) logEntry.Context__c = 'Trigger';
            else if(logEntry.ContextIsVisualforce__c) logEntry.Context__c = 'Visualforce';

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