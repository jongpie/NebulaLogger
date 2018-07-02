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
            LoggedBy__c                = logEntryEvent.CreatedById,
            OwnerId                    = logEntryEvent.CreatedById,
            TransactionId__c           = logEntryEvent.TransactionId__c,
            UserLoggingLevel__c        = logEntryEvent.UserLoggingLevel__c,
            UserLoggingLevelOrdinal__c = logEntryEvent.UserLoggingLevelOrdinal__c
        ));
        LogEntry__c logEntry = new LogEntry__c(
            ExceptionStackTrace__c = logEntryEvent.ExceptionStackTrace__c,
            ExceptionType__c       = logEntryEvent.ExceptionType__c,
            Log__r                 = new Log__c(TransactionId__c = logEntryEvent.TransactionId__c),
            LoggingLevel__c        = logEntryEvent.LoggingLevel__c,
            LoggingLevelOrdinal__c = logEntryEvent.LoggingLevelOrdinal__c,
            Message__c             = logEntryEvent.Message__c,
            MessageTruncated__c    = logEntryEvent.MessageTruncated__c,
            Name                   = logEntryEvent.TransactionEntryId__c,
            OriginType__c          = logEntryEvent.OriginType__c,
            OriginLocation__c      = logEntryEvent.OriginLocation__c,
            Timestamp__c           = logEntryEvent.Timestamp__c,
            TransactionEntryId__c  = logEntryEvent.TransactionEntryId__c,
            Type__c                = logEntryEvent.Type__c
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