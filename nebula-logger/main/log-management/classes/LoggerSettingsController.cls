//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for lwc `loggerSettings`, used to manage records in `LoggerSettings__c`
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class LoggerSettingsController {
    // Data methods
    /**
     * @description Indicates if the current user has access to modify `LoggerSettings__c` records,
     *              based on either object-level access on `LoggerSettings__c`, or access to the custom permission `CanModifyLoggerSettings`
     * @return   return description
     */
    @AuraEnabled(cacheable=true)
    public static Boolean canUserModifyLoggerSettings() {
        return Schema.LoggerSettings__c.SObjectType.getDescribe().isUpdateable() == true ||
            FeatureManagement.checkPermission('CanModifyLoggerSettings') == true;
    }

    /**
     * @description Returns all existing `LoggerSettings__c` records as instances of `SettingsRecordResult`
     * @return   The list of existing records
     */
    @AuraEnabled
    public static List<SettingsRecordResult> getRecords() {
        List<SettingsRecordResult> settingsRecordResults = new List<SettingsRecordResult>();
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
            SettingsRecordResult settingsRecordResult = new SettingsRecordResult();
            settingsRecordResult.setupOwnerType = getSetupOwnerType(settingsRecord);
            settingsRecordResult.setupOwnerName = settingsRecord.SetupOwner.Name;
            settingsRecordResult.record = settingsRecord;
            settingsRecordResults.add(settingsRecordResult);

            setupOwnerIds.add(settingsRecord.SetupOwnerId);
        }

        Map<Id, String> setupOwnerIdToName = querySetupOwnerNames(setupOwnerIds);
        for (SettingsRecordResult settingsRecordResult : settingsRecordResults) {
            if (setupOwnerIdToName.containsKey((settingsRecordResult.record.SetupOwnerId)) == true) {
                settingsRecordResult.setupOwnerName = setupOwnerIdToName.get(settingsRecordResult.record.SetupOwnerId);
            }
        }

        settingsRecordResults.sort();
        return settingsRecordResults;
    }


    /**
     * @description Creates a new, unsaved `LoggerSettings__c` record
     * @return   A new `LoggerSettings__c` record, with all fields populated with default values
     */
    @AuraEnabled
    public static LoggerSettings__c createNewRecord() {
        return (LoggerSettings__c) Schema.LoggerSettings__c.SObjectType.newSObject(null, true);
    }

    /**
     * @description Upserts the specified `LoggerSettings__c` record
     * @param  settingsRecord The record to save
     */
    @AuraEnabled
    public static void saveRecord(LoggerSettings__c settingsRecord) {
        try {
            upsert settingsRecord;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * @description Deletes the specified `LoggerSettings__c` record
     * @param  settingsRecord The record to delete
     */
    @AuraEnabled
    public static void deleteRecord(LoggerSettings__c settingsRecord) {
        try {
            delete settingsRecord;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    // Setup Owner methods
    /**
     * @description Returns the `Organization` record for the current environment
     * @return   The current environment's `Organization` record
     */
    @AuraEnabled
    public static Organization getOrganization() {
        return [SELECT Id, Name FROM Organization];
    }

    /**
     * @description searchForSetupOwner description
     * @param  setupOwnerType The object to search (`Profile` or `User`)
     * @param  searchTerm     The search term to use when searching records
     * @return                The list of `SetupOwnerSearchResult`, based on any matching SObject records
     */
    @AuraEnabled
    public static List<SetupOwnerSearchResult> searchForSetupOwner(String setupOwnerType, String searchTerm) {
        try {
            searchTerm = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            List<SetupOwnerSearchResult> searchResults = new List<SetupOwnerSearchResult>();
            switch on setupOwnerType {
                when 'Profile' {
                    for (Profile matchingProfile : [SELECT Id, Name FROM Profile WHERE Name LIKE :searchTerm ORDER BY Name]) {
                        SetupOwnerSearchResult result = new SetupOwnerSearchResult();
                        result.label = matchingProfile.Name;
                        result.recordId = matchingProfile.Id;
                        searchResults.add(result);
                    }
                }
                when 'User' {
                    for (User matchingUser : [SELECT Id, Username FROM User WHERE Name LIKE :searchTerm OR Username LIKE :searchTerm ORDER BY Username]) {
                        SetupOwnerSearchResult result = new SetupOwnerSearchResult();
                        result.label = matchingUser.Username;
                        result.recordId = matchingUser.Id;
                        searchResults.add(result);
                    }
                }
            }
            return searchResults;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    // Picklist methods
    /**
     * @description Returns the values of `LoggingLevel` enum, converted to `PicklistOption` that can be used in lwc
     * @return   The converted list of `LoggingLevel` values
     */
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getLoggingLevelOptions() {
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
    }

    /**
     * @description Returns the values of `Logger.SaveMethod` enum, converted to `PicklistOption` that can be used in lwc
     * @return   The converted list of `Logger.SaveMethod` values
     */
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getSaveMethodOptions() {
        List<PicklistOption> picklistOptions = initializePicklistOptions();
        for (Logger.SaveMethod saveMethod : Logger.SaveMethod.values()) {
            PicklistOption picklistOption = new PicklistOption();
            picklistOption.label = saveMethod.name();
            picklistOption.value = saveMethod.name();

            picklistOptions.add(picklistOption);
        }
        return picklistOptions;
    }

    /**
     * @description Returns the 3 supported values for custom hiearchy settings (`Organization`, `Profile`, and `User`), converted to `PicklistOption` that can be used in lwc
     * @return   The converted list of supported values
     */
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getSetupOwnerTypeOptions() {
        List<PicklistOption> picklistOptions = initializePicklistOptions();
        List<String> optionNames = new List<String>{ 'Organization', 'Profile', 'User' };
        for (String optionName : optionNames) {
            PicklistOption picklistOption = new PicklistOption();
            picklistOption.label = optionName;
            picklistOption.value = optionName;

            picklistOptions.add(picklistOption);
        }
        return picklistOptions;
    }

    /**
     * @description Returns the values of `Log__Share.AccessLevel.getDescribe().getPicklistValues()`, converted to `PicklistOption` that can be used in lwc
     * @return   The converted list of `AccessLevel` values
     */
    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getShareAccessLevelOptions() {
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
    }

    private static List<PicklistOption> initializePicklistOptions() {
        PicklistOption emptyPicklistOption = new PicklistOption();
        emptyPicklistOption.label = '--None--';
        emptyPicklistOption.value = '';
        List<PicklistOption> picklistOptions = new List<PicklistOption>();
        picklistOptions.add(emptyPicklistOption);
        return picklistOptions;
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

    /**
     * @description DTO for picklist options since Schema.PicklistEntry isn't supported for aura-enabled methods
     */
    public class PicklistOption {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
    }

    /**
     * @description Inner class used for sorting LoggerSettings__c, used for 3 reasons:
     *      1. Trying to sort in SOQL on SetupOwner.Type, SetupOwner.Name results in only user-specific records being returned (no idea why - seems like a bug)
     *      2. Records tied to profiles do not return the actual profile name in SetupOwner.Name - example: System Admin returns as 'PT1' in query results
     *      3. Records tied to the org or profiles return unhelpful values in SetupOwner.Type - org returns '00D', profiles return '00e'
     */
    public class SettingsRecordResult implements Comparable {
        @AuraEnabled
        public String setupOwnerType;
        @AuraEnabled
        public String setupOwnerName;
        @AuraEnabled
        public LoggerSettings__c record;

        public Integer compareTo(Object compareTo) {
            SettingsRecordResult that = (SettingsRecordResult) compareTo;
            String thisCompositeName = this.setupOwnerType + '.' + this.setupOwnerName;
            String thatCompositeName = that.setupOwnerType + '.' + that.setupOwnerName;
            if (thisCompositeName == thatCompositeName) {
                return 0;
            } else if (thisCompositeName > thatCompositeName) {
                return 1;
            } else {
                return -1;
            }
        }
    }

    /**
     * @description Inner class used for returning search results for `Profile` and `User` records
     */
    public class SetupOwnerSearchResult {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Id recordId;
    }
}
