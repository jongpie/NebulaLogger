//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for lwc `loggerSettings`, used to manage records in `LoggerSettings__c`
 */
public without sharing class LoggerSettingsController {
    // Data methods
    @AuraEnabled(cacheable=true)
    public static Boolean canUserModifyLoggerSettings() {
        return Schema.LoggerSettings__c.SObjectType.getDescribe().isUpdateable() == true ||
            FeatureManagement.checkPermission('CanModifyLoggerSettings') == true;
    }

    @AuraEnabled
    public static List<SettingsRecordInfo> getRecords() {
        try {
            return getLoggerSettingsRecordInfos();
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static LoggerSettings__c createNewRecord() {
        try {
            return (LoggerSettings__c) Schema.LoggerSettings__c.SObjectType.newSObject(null, true);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void saveRecord(LoggerSettings__c settingsRecord) {
        System.debug('saveRecord==' + settingsRecord);
        try {
            upsert settingsRecord;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteRecord(LoggerSettings__c settingsRecord) {
        System.debug('deleteRecord==' + settingsRecord);
        try {
            delete settingsRecord;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    // Setup Owner methods
    @AuraEnabled
    public static Organization getOrganization() {
        try {
            return [SELECT Id, Name FROM Organization];
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<SObject> searchForSetupOwner(String setupOwnerType, String searchTerm) {
        try {
            String query = 'FIND \'' + searchTerm + '\' IN ALL FIELDS RETURNING ' + setupOwnerType + '(Id, Mame)';
            List<SObject> searchResults = Search.query(query).get(0);
            return searchResults;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    // Picklist methods
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getLoggingLevelOptions() {
        try {
            List<PicklistOption> picklistOptions = initializePicklistOptions();
            for (Integer i = LoggingLevel.values().size() - 1; i > 0; i--) {
                LoggingLevel currentLoggingLevel = LoggingLevel.values().get(i);

                if (currentLoggingLevel == LoggingLevel.NONE || currentLoggingLevel == LoggingLevel.INTERNAL) {
                    continue;
                }

                PicklistOption picklistOption = new PicklistOption();
                picklistOption.label = currentLoggingLevel.name();
                picklistOption.value = currentLoggingLevel.name();

                picklistOptions.add(picklistOption);
            }
            return picklistOptions;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getSaveMethodOptions() {
        try {
            List<PicklistOption> picklistOptions = initializePicklistOptions();
            for (Logger.SaveMethod saveMethod : Logger.SaveMethod.values()) {
                PicklistOption picklistOption = new PicklistOption();
                picklistOption.label = saveMethod.name();
                picklistOption.value = saveMethod.name();

                picklistOptions.add(picklistOption);
            }
            return picklistOptions;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getSetupOwnerTypeOptions() {
        try {
            List<PicklistOption> picklistOptions = initializePicklistOptions();
            List<String> optionNames = new List<String>{ 'Organization', 'Profile', 'User' };
            for (String optionName : optionNames) {
                PicklistOption picklistOption = new PicklistOption();
                picklistOption.label = optionName;
                picklistOption.value = optionName;

                picklistOptions.add(picklistOption);
            }
            return picklistOptions;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getShareAccessLevelOptions() {
        try {
            List<PicklistOption> picklistOptions = initializePicklistOptions();
            for (Schema.PicklistEntry picklistEntry : Schema.Log__Share.AccessLevel.getDescribe().getPicklistValues()) {
                // The 'All' access level is an internal value and can't be granted
                // Source: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_bulk_sharing_creating_with_apex.htm
                if (picklistEntry.value == 'All') {
                    continue;
                }

                PicklistOption picklistOption = new PicklistOption();
                picklistOption.label = picklistEntry.value;
                picklistOption.value = picklistEntry.value;

                picklistOptions.add(picklistOption);
            }
            return picklistOptions;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static List<PicklistOption> initializePicklistOptions() {
        PicklistOption emptyPicklistOption = new PicklistOption();
        emptyPicklistOption.label = '--None--';
        emptyPicklistOption.value = '';
        List<PicklistOption> picklistOptions = new List<PicklistOption>();
        picklistOptions.add(emptyPicklistOption);
        return picklistOptions;
    }

    private static List<SettingsRecordInfo> getLoggerSettingsRecordInfos() {
        List<SettingsRecordInfo> settingsRecordInfos = new List<SettingsRecordInfo>();
        List<Id> setupOwnerIds = new List<Id>();
        for (LoggerSettings__c settingsRecord : [
            SELECT
                Id,
                SetupOwnerId,
                SetupOwner.Type,
                SetupOwner.Name,
                AnonymousMode__c,
                ApplyDataMaskRules__c,
                DefaultLogShareAccessLevel__c,
                DefaultNumberOfDaysToRetainLogs__c,
                DefaultSaveMethod__c,
                IsApexSystemDebugLoggingEnabled__c,
                IsComponentConsoleLoggingEnabled__c,
                IsEnabled__c,
                LoggingLevel__c,
                StripInaccessibleRecordFields__c
            FROM LoggerSettings__c
        ]) {
            SettingsRecordInfo settingsRecordInfo = new SettingsRecordInfo();
            settingsRecordInfo.SetupOwnerType = getSetupOwnerType(settingsRecord);
            settingsRecordInfo.SetupOwnerName = settingsRecord.SetupOwner.Name;
            settingsRecordInfo.Record = settingsRecord;
            settingsRecordInfos.add(settingsRecordInfo);

            setupOwnerIds.add(settingsRecord.SetupOwnerId);
        }

        Map<Id, String> setupOwnerIdToName = querySetupOwnerNames(setupOwnerIds);
        for (SettingsRecordInfo settingsRecordInfo : settingsRecordInfos) {
            if (setupOwnerIdToName.containsKey((settingsRecordInfo.Record.SetupOwnerId)) == true) {
                settingsRecordInfo.SetupOwnerName = setupOwnerIdToName.get(settingsRecordInfo.Record.SetupOwnerId);
            }
        }

        settingsRecordInfos.sort();
        return settingsRecordInfos;
    }

    private static String getSetupOwnerType(LoggerSettings__c settingsRecord) {
        String setupOwnerType;
        switch on settingsRecord.SetupOwner.Type {
            when '00D' {
                setupOwnerType = 'Organization';
            }
            when '00e' {
                setupOwnerType = 'Profile';
            }
            when else {
                setupOwnerType = settingsRecord.SetupOwner.Type;
            }
        }
        return setupOwnerType;
    }

    private static Map<Id, String> querySetupOwnerNames(List<Id> setupOwnerIds) {
        Map<Id, String> setupOwnerIdToName = new Map<Id, String>();
        for (Profile profile : [SELECT Id, Name FROM Profile WHERE Id IN :setupOwnerIds]) {
            setupOwnerIdToName.put(profile.Id, profile.Name);
        }
        for (User user : [SELECT Id, Username FROM User WHERE Id IN :setupOwnerIds]) {
            setupOwnerIdToName.put(user.Id, user.Username);
        }
        return setupOwnerIdToName;
    }

    private static Map<Id, Profile> queryProfiles() {
        return new Map<Id, Profile>([SELECT Id, Name FROM Profile]);
    }

    // DTO for picklist options since Schema.PicklistEntry isn't supported for aura-enabled methods
    public class PicklistOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
    }

    // Inner class used for sorting LoggerSettings__c, used for 3 reasons:
    // 1. Trying to sort in SOQL on SetupOwner.Type, SetupOwner.Name results in only user-specific records being returned (no idea why - seems like a bug)
    // 2. Records tied to profiles do not return the actual profile name in SetupOwner.Name - example: System Admin returns as 'PT1' in query results
    // 3. Records tied to the org or profiles return unhelpful values in SetupOwner.Type - org returns '00D', profiles return '00e'
    public class SettingsRecordInfo implements Comparable {
        @AuraEnabled
        public String SetupOwnerType;
        @AuraEnabled
        public String SetupOwnerName;
        @AuraEnabled
        public LoggerSettings__c Record;

        public Integer compareTo(Object compareTo) {
            SettingsRecordInfo that = (SettingsRecordInfo) compareTo;
            if (this.setupOwnerType == that.setupOwnerType && this.setupOwnerName == that.setupOwnerName) {
                return 0;
            } else if (this.setupOwnerType > that.setupOwnerType || this.setupOwnerName > that.setupOwnerName) {
                return 1;
            } else {
                return -1;
            }
        }
    }
}
