/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
trigger LogEntryEvent on LogEntryEvent__e(after insert) {

    Set<Log__c> logs = new Set<Log__c>();
    List<LogEntry__c > logEntries = new List<LogEntry__c>();
    for(LogEntryEvent__e logEntryEvent : Trigger.new) {
        logs.add(new Log__c(
            OwnerId                    = logEntryEvent.CreatedById,
            TransactionId__c           = logEntryEvent.TransactionId__c,
            UserLoggingLevel__c        = logEntryEvent.UserLoggingLevel__c,
            UserLoggingLevelOrdinal__c = logEntryEvent.UserLoggingLevelOrdinal__c
        ));
        logEntries.add(new LogEntry__c (
            ClassName__c           = logEntryEvent.ClassName__c,
            ExceptionStackTrace__c = logEntryEvent.ExceptionStackTrace__c,
            ExceptionTypeName__c   = logEntryEvent.ExceptionTypeName__c,
            FlowName__c            = logEntryEvent.FlowName__c,
            Log__r                 = new Log__c(TransactionId__c = logEntryEvent.TransactionId__c),
            LoggingLevel__c        = logEntryEvent.LoggingLevel__c,
            LoggingLevelOrdinal__c = logEntryEvent.LoggingLevelOrdinal__c,
            Message__c             = logEntryEvent.Message__c,
            MessageTruncated__c    = logEntryEvent.MessageTruncated__c,
            MethodName__c          = logEntryEvent.MethodName__c,
            Name                   = logEntryEvent.TransactionEntryId__c,
            ParentId__c            = logEntryEvent.ParentId__c,
            ParentSobjectType__c   = logEntryEvent.ParentSobjectType__c,
            SourceType__c          = logEntryEvent.SourceType__c,
            Timestamp__c           = logEntryEvent.Timestamp__c,
            TransactionEntryId__c  = logEntryEvent.TransactionEntryId__c,
            Type__c                = logEntryEvent.Type__c
        ));
    }
    upsert new List<Log__c>(logs) TransactionId__c;
    upsert logEntries TransactionEntryId__c;

}