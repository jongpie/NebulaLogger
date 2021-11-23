//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for lwc `loggerSettings`, used to manage records in `LoggerSettings__c`
 */
public without sharing class LoggerSettingsController {
    private static final Map<Id, Profile> CACHED_PROFILES {
        get {
            if (CACHED_PROFILES == null) {
                CACHED_PROFILES = queryProfiles();
            }
            return CACHED_PROFILES;
        }
        set;
    }

    @AuraEnabled
    public static List<SettingsRecordInfo> getSettings() {
        try {
            if (FeatureManagement.checkPermission('CanManageLoggerSettings') == false) {
                return null;
            }

            return getLoggerSettingsRecordInfos();
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<SettingsRecordInfo> saveRecord(LoggerSettings__c settingsRecord) {
        System.debug('saveRecord==' + settingsRecord);
        try {
            upsert settingsRecord;
            return getSettings();
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<SettingsRecordInfo> deleteRecord(LoggerSettings__c settingsRecord) {
        System.debug('deleteRecord==' + settingsRecord);
        try {
            delete settingsRecord;
            return getSettings();
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getLoggingLevelOptions() {
        try {
            List<PicklistOption> picklistOptions = initializePicklistOptions();
            for (LoggingLevel logLevel : LoggingLevel.values()) {
                if (logLevel != LoggingLevel.NONE && logLevel != LoggingLevel.INTERNAL) {
                    PicklistOption picklistOption = new PicklistOption();
                    picklistOption.label = logLevel.name();
                    picklistOption.value = logLevel.name();

                    picklistOptions.add(picklistOption);
                }
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
                picklistOption.label = picklistEntry.label;
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
        for (
            LoggerSettings__c settingsRecord : [
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
            ]
        ) {
            SettingsRecordInfo settingsRecordInfo = new SettingsRecordInfo();
            settingsRecordInfo.setupOwnerType = getSetupOwnerType(settingsRecord);
            settingsRecordInfo.setupOwnerName = getSetupOwnerName(settingsRecord);
            settingsRecordInfo.record = settingsRecord;

            settingsRecordInfos.add(settingsRecordInfo);
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

    private static String getSetupOwnerName(LoggerSettings__c settingsRecord) {
        String setupOwnerName;
        switch on settingsRecord.SetupOwner.Type {
            when '00e' {
                setupOwnerName = CACHED_PROFILES.get(settingsRecord.SetupOwnerId).Name;
            }
            when else {
                setupOwnerName = settingsRecord.SetupOwner.Name;
            }
        }
        return setupOwnerName;
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
