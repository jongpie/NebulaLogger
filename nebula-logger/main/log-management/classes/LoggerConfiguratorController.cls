//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//


/**
 * @group Log Management
 * @description Controller class for the lightning web component `loggerConfigurator`
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class LoggerConfiguratorController {
    @AuraEnabled
    public static List<LoggerSettings__c> getSettings() {
        try {
            if (SObjectType.LoggerSettings__c.isUpdateable() == false) {
                return null;
            }

            List<LoggerSettings__c> queriedSettingsRecords = [
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
                ORDER BY SetupOwner.Name
            ];

            Map<String, List<LoggerSettings__c>> settingsRecordsByOwnerType = new Map<String, List<LoggerSettings__c>>();
            for (LoggerSettings__c settingsRecord : queriedSettingsRecords) {
                List<LoggerSettings__c> ownerTypeLoggerSettingsRecords = settingsRecordsByOwnerType.get(settingsRecord.SetupOwner.Type);
                if (ownerTypeLoggerSettingsRecords == null) {
                    ownerTypeLoggerSettingsRecords = new List<LoggerSettings__c>();
                }
                ownerTypeLoggerSettingsRecords.add(settingsRecord);
                settingsRecordsByOwnerType.put(settingsRecord.SetupOwner.Type, ownerTypeLoggerSettingsRecords);
            }

            List<LoggerSettings__c> sortedSettingsRecords = new List<LoggerSettings__c>();
            sortedSettingsRecords.addAll(settingsRecordsByOwnerType.get('00D'));
            sortedSettingsRecords.addAll(settingsRecordsByOwnerType.get('00e'));
            sortedSettingsRecords.addAll(settingsRecordsByOwnerType.get('User'));
            return sortedSettingsRecords;
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

    @AuraEnabled
    public static List<LoggerParameter__mdt> getParameters() {
        try {
            return [SELECT DeveloperName, MasterLabel, Description__c, Value__c FROM LoggerParameter__mdt ORDER BY DeveloperName];
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
