// This script runs in the pipeline to validate different custom metadata records to ensure that they're configured correctly
// before being added to the unlocked & managed packages.

// LogEntryDataMaskRule__mdt checks
// The field LogEntryDataMaskRule__mdt.IsEnabled__c should be set to true for any records included in the packages.
for (LogEntryDataMaskRule__mdt record : [SELECT DeveloperName, IsEnabled__c FROM LogEntryDataMaskRule__mdt ORDER BY DeveloperName]) {
    if (record.IsEnabled__c == false) {
        throw new System.IllegalArgumentException('😡 IsEnabled__c field should be set to true for LogEntryDataMaskRule.' + record.DeveloperName);
    }
}
System.debug('🥳 LogEntryDataMaskRule__mdt records have been correctly configured!');

// LoggerParameter__mdt checks
// The field LoggerParameter__mdt.Description__c is a long textarea field, so it can't be marked as required - but every record
// should have the field populated before being added to the unlocked & managed packages.
for (LoggerParameter__mdt record : [SELECT DeveloperName, Description__c FROM LoggerParameter__mdt ORDER BY DeveloperName]) {
    if (record.Description__c == null) {
        throw new System.IllegalArgumentException('😡 Description__c field should be populated for LoggerParameter.' + record.DeveloperName);
    }
}
System.debug('🥳 LoggerParameter__mdt records have been correctly configured!');

// LoggerSObjectHandler__mdt checks
// The field LoggerSObjectHandler__mdt.IsEnabled__c should be set to true for any records included in the packages.
for (LoggerSObjectHandler__mdt record : [SELECT DeveloperName, IsEnabled__c FROM LoggerSObjectHandler__mdt ORDER BY DeveloperName]) {
    if (record.IsEnabled__c == false) {
        throw new System.IllegalArgumentException('😡 IsEnabled__c field should be set to true for LoggerSObjectHandler.' + record.DeveloperName);
    }
}
System.debug('🥳 LoggerSObjectHandler__mdt records have been correctly configured!');

// LogStatus__mdt checks
// The field LogStatus__mdt.IsActive__c should be set to true for any records included in the packages.
for (LogStatus__mdt record : [SELECT DeveloperName, IsActive__c FROM LogStatus__mdt ORDER BY DeveloperName]) {
    // TODO rename LogStatus__mdt.IsActive__c to IsEnabled__c for consistency with other objects
    if (record.IsActive__c == false) {
        throw new System.IllegalArgumentException('😡 IsActive__c field should be set to true for LogStatus.' + record.DeveloperName);
    }
}
System.debug('🥳 LogStatus__mdt records have been correctly configured!');
