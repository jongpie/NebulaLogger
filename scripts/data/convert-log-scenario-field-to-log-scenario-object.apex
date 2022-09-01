// Prior to v4.8.2 (?), a log's scenario was stored in the text field Log__c.Scenario__c.
// In v4.8.2, a new LogScenario__c object was introduced, and replaces Log__c.Scenario__c.
// This script handles migrating the text field's data into the new LogScenario__c object,
// and relates each Log__c record to the corresponding LogScenario__c record
Integer countOfRecordsToUpdate = [SELECT COUNT() FROM Log__c WHERE LogScenario__c = null AND Scenario__c != null];
if (countOfRecordsToUpdate == 0) {
    System.debug('No Log__c records to update! All data has been successfully migrated from Log__c.Scenario__c to the new lookup Log__c.LogScenario__c');
    return;
}

System.debug(countOfRecordsToUpdate + ' Log__c records have legacy field Scenario__c set but not LogScenario__c');

Map<String, LogScenario__c> scenarioNameToLogScenario = new Map<String, LogScenario__c>();
List<Log__c> logsToUpdate = [SELECT Id, LogScenario__c, Scenario__c FROM Log__c WHERE LogScenario__c = null AND Scenario__c != null LIMIT :Limits.getLimitDmlRows()];
for (Log__c log : logsToUpdate) {
    scenarioNameToLogScenario.put(log.LogScenario__r.UniqueId__c, log.LogScenario__r.clone());
    log.LogScenario__r = new LogScenario__c(UniqueId__c = log.Scenario__c);
}
upsert scenarioNameToLogScenario.values() UniqueId__c;
update logsToUpdate;

countOfRecordsToUpdate = [SELECT COUNT() FROM Log__c WHERE LogScenario__c = null AND Scenario__c != null];
if (countOfRecordsToUpdate > 0) {
    System.debug(countOfRecordsToUpdate + ' additional Log__c records still to be updated! You will need to re-run this script to update additional Log__c records');
}