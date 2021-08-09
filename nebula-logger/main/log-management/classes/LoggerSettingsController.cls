public with sharing class LoggerSettingsController {
    @AuraEnabled
    public static List<LoggerSettings__c> getSettings() {
        try {
            if (SObjectType.LoggerSettings__c.isUpdateable() == false) {
                return null;
            }

            return [
                SELECT
                    Id,
                    SetupOwnerId,
                    SetupOwner.Type,
                    SetupOwner.Name,
                    IsEnabled__c,
                    LoggingLevel__c,
                    EnableSystemMessages__c,
                    DefaultLogShareAccessLevel__c,
                    DefaultSaveMethod__c
                FROM LoggerSettings__c
                // ORDER BY SetupOwner.Type, SetupOwner.Name
            ];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<LoggerSettings__c> saveSettings(List<LoggerSettings__c> settings) {
        try {
            upsert settings;
            return getSettings();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getLoggingLevelOptions() {
        try {
            List<PicklistOption> picklistOptions = new List<PicklistOption>();
            for (LoggingLevel logLevel : LoggingLevel.values()) {
                if (logLevel != LoggingLevel.NONE && logLevel != LoggingLevel.INTERNAL) {
                    PicklistOption picklistOption = new PicklistOption();
                    picklistOption.label = logLevel.name();
                    picklistOption.value = logLevel.name();

                    picklistOptions.add(picklistOption);
                }
            }
            return picklistOptions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getShareAccessLevelOptions() {
        try {
            List<PicklistOption> picklistOptions = new List<PicklistOption>();
            for (Schema.PicklistEntry picklistEntry : Schema.Log__Share.AccessLevel.getDescribe().getPicklistValues()) {
                PicklistOption picklistOption = new PicklistOption();
                picklistOption.label = picklistEntry.label;
                picklistOption.value = picklistEntry.value;

                picklistOptions.add(picklistOption);
            }
            return picklistOptions;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // DTO for picklist options since Schema.PicklistEntry isn't supported for aura-enabled methods
    public class PicklistOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
    }
}
