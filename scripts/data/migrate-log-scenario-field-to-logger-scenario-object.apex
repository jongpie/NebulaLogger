// Prior to v4.8.1, a log's scenario was stored in the text field Log__c.Scenario__c.
// In v4.8.1, a new LoggerScenario__c object was introduced, and the new lookup field Log__c.TransactionScenario__c
// replaces the text field Log__c.Scenario__c. This script handles migrating the text field's data into the new
// LoggerScenario__c object, and relates each Log__c record to the corresponding LoggerScenario__c record
Integer countOfRecordsToUpdate = [SELECT COUNT() FROM Log__c WHERE TransactionScenario__c = null AND Scenario__c != null];
if (countOfRecordsToUpdate == 0) {
    System.debug('No Log__c records to update! All data has been successfully migrated from Log__c.Scenario__c to the new lookup Log__c.TransactionScenario__c');
    return;
}

System.debug(countOfRecordsToUpdate + ' Log__c records have legacy field Scenario__c set but not LoggerScenario__c');

Map<String, LoggerScenario__c> scenarioNameToLogScenario = new Map<String, LoggerScenario__c>();
List<Log__c> logsToUpdate = [SELECT Id, TransactionScenario__c, Scenario__c FROM Log__c WHERE TransactionScenario__c = null AND Scenario__c != null LIMIT :Limits.getLimitDmlRows()];
for (Log__c log : logsToUpdate) {
    scenarioNameToLogScenario.put(log.TransactionScenario__r.UniqueId__c, log.TransactionScenario__r.clone());
    log.TransactionScenario__r = new LoggerScenario__c(UniqueId__c = log.Scenario__c);
}
upsert scenarioNameToLogScenario.values() UniqueId__c;
update logsToUpdate;

countOfRecordsToUpdate = [SELECT COUNT() FROM Log__c WHERE TransactionScenario__c = null AND Scenario__c != null];
if (countOfRecordsToUpdate > 0) {
    System.debug(countOfRecordsToUpdate + ' additional Log__c records still to be updated! You will need to re-run this script to update additional Log__c records');
}