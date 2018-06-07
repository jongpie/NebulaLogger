trigger LogEntryEvent on LogEntryEvent__e(after insert) {

    Set<Log__c> logs = new Set<Log__c>();
    List<LogEntry__c > logEntries = new List<LogEntry__c>();
    for(LogEntryEvent__e logEntryEvent : Trigger.new) {
        logs.add(new Log__c(
            OwnerId          = logEntryEvent.CreatedById,
            TransactionId__c = logEntryEvent.TransactionId__c
        ));
        logEntries.add(new LogEntry__c (
            ClassName__c           = logEntryEvent.ClassName__c,
            ExceptionLineNumber__c = logEntryEvent.ExceptionLineNumber__c,
            ExceptionStackTrace__c = logEntryEvent.ExceptionStackTrace__c,
            ExceptionTypeName__c   = logEntryEvent.ExceptionTypeName__c,
            Log__r                 = new Log__c(TransactionId__c = logEntryEvent.TransactionId__c),
            LoggingLevel__c        = logEntryEvent.LoggingLevel__c,
            Message__c             = logEntryEvent.Message__c,
            MethodName__c          = logEntryEvent.MethodName__c,
            ParentId__c            = logEntryEvent.ParentId__c,
            ProcessBuilderName__c  = logEntryEvent.ProcessBuilderName__c,
            Timestamp__c           = logEntryEvent.Timestamp__c,
            Type__c                = logEntryEvent.Type__c
        ));
    }
    upsert new List<Log__c>(logs) TransactionId__c;
    upsert logEntries;

}