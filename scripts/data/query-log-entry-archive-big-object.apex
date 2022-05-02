Id userId = UserInfo.getUserId();
List<String> loggingLevelNames = new List<String>();
for (LoggingLevel logLevel : LoggingLevel.values()) {
    loggingLevelNames.add(logLevel.name());
}

List<LogEntryArchive__b> archives = [
    SELECT Timestamp__c, LoggedBy__c, LoggingLevel__c, TransactionId__c, TransactionEntryNumber__c, Message__c, Tags__c
    FROM LogEntryArchive__b
    WHERE LoggedBy__c = :userId
    AND LoggingLevel__c IN :loggingLevelNames
    AND Timestamp__c >= LAST_WEEK
    ORDER BY LoggedBy__c, LoggingLevel__c, Timestamp__c DESC
];
System.debug('Matching LogEntryArchive__b records:\n' + JSON.serializePretty(archives));