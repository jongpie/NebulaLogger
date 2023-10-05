//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for lwc `loggerSettings`, used to manage records in `LoggerSettings__c`
 */
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.ExcessivePublicCount')
public without sharing class LoggerSettingsController {
    @TestVisible
    private static final String CUSTOM_SAVE_METHOD_PREFIX = 'CustomSaveMethod';
    @TestVisible
    private static final String CUSTOM_OBJECTS_STORAGE_LOCATION = 'CUSTOM_OBJECTS';
    @TestVisible
    private static final String CUSTOM_LOG_PURGE_ACTION_PREFIX = 'CustomLogPurgeAction';
    @TestVisible
    private static final String CUSTOM_STORAGE_LOCATION_PREFIX = 'CustomStorageLocation';
    @TestVisible
    private static final String DELETE_LOG_PURGE_ACTION = 'Delete';

    // Data methods
    /**
     * @description Indicates if the current user has access to modify `LoggerSettings__c` records,
     *              based on either object-level access on `LoggerSettings__c`, or access to the custom permission `CanModifyLoggerSettings`
     * @return   return description
     */
    @AuraEnabled(cacheable=true)
    public static Boolean canUserModifyLoggerSettings() {
        return Schema.LoggerSettings__c.SObjectType.getDescribe().isUpdateable() || System.FeatureManagement.checkPermission('CanModifyLoggerSettings');
    }

    /**
     * @description Returns all of the `List<PicklistOption>` used in the frontend for displaying certain text fields as picklist fields
     * @return   The instance of `LoggerSettingsPicklistOptions`, containing all picklist options for any fields treated as picklists
     */
    @AuraEnabled(cacheable=true)
    public static LoggerSettingsPicklistOptions getPicklistOptions() {
        LoggerSettingsPicklistOptions loggerSettingsPicklistOptions = new LoggerSettingsPicklistOptions();
        loggerSettingsPicklistOptions.loggingLevelOptions = getLoggingLevelOptions();
        loggerSettingsPicklistOptions.platformEventStorageLocationOptions = getPlatformEventStorageLocationOptions();
        loggerSettingsPicklistOptions.purgeActionOptions = getPurgeActionOptions();
        loggerSettingsPicklistOptions.saveMethodOptions = getSaveMethodOptions();
        loggerSettingsPicklistOptions.setupOwnerTypeOptions = getSetupOwnerTypeOptions();
        loggerSettingsPicklistOptions.shareAccessLevelOptions = getShareAccessLevelOptions();
        return loggerSettingsPicklistOptions;
    }

    /**
     * @description Returns all existing `LoggerSettings__c` records as instances of `SettingsRecordResult`
     * @return   The list of existing records
     */
    @AuraEnabled
    public static List<SettingsRecordResult> getRecords() {
        List<SettingsRecordResult> settingsRecordResults = new List<SettingsRecordResult>();
        List<Id> setupOwnerIds = new List<Id>();
        for (LoggerSettings__c settingsRecord : queryLoggerSettings()) {
            SettingsRecordResult settingsRecordResult = new SettingsRecordResult();
            settingsRecordResult.setupOwnerType = getSetupOwnerType(settingsRecord);
            settingsRecordResult.setupOwnerName = settingsRecord.SetupOwner.Name;
            settingsRecordResult.createdByUsername = settingsRecord.CreatedBy.Username;
            settingsRecordResult.lastModifiedByUsername = settingsRecord.LastModifiedBy.Username;
            settingsRecordResult.record = settingsRecord;
            settingsRecordResults.add(settingsRecordResult);

            setupOwnerIds.add(settingsRecord.SetupOwnerId);
        }

        Map<Id, String> setupOwnerIdToName = querySetupOwnerNames(setupOwnerIds);
        for (SettingsRecordResult settingsRecordResult : settingsRecordResults) {
            if (setupOwnerIdToName.containsKey((settingsRecordResult.record.SetupOwnerId))) {
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
    @AuraEnabled(cacheable=true)
    public static LoggerSettings__c createRecord() {
        LoggerSettings__c defaultSettings = Logger.createSettings();
        if (LoggerEngineDataSelector.getInstance().getCachedOrganization()?.IsSandbox == false) {
            defaultSettings.IsApexSystemDebugLoggingEnabled__c = false;
            defaultSettings.IsJavaScriptConsoleLoggingEnabled__c = false;
            defaultSettings.LoggingLevel__c = System.LoggingLevel.INFO.name();
        }
        return defaultSettings;
    }

    /**
     * @description Upserts the specified `LoggerSettings__c` record
     * @param  settingsRecord The record to save
     */
    @AuraEnabled
    public static void saveRecord(LoggerSettings__c settingsRecord) {
        try {
            if (canUserModifyLoggerSettings()) {
                LoggerDataStore.getDatabase().upsertRecord(settingsRecord, Schema.LoggerSettings__c.Id);
            }
        } catch (System.Exception ex) {
            throw createAuraHandledException(ex);
        }
    }

    /**
     * @description Deletes the specified `LoggerSettings__c` record
     * @param  settingsRecord The record to delete
     */
    @AuraEnabled
    public static void deleteRecord(LoggerSettings__c settingsRecord) {
        try {
            if (canUserModifyLoggerSettings()) {
                LoggerDataStore.getDatabase().deleteRecord(settingsRecord);
            }
        } catch (System.Exception ex) {
            throw createAuraHandledException(ex);
        }
    }

    // Setup Owner methods
    /**
     * @description Returns the `Organization` record for the current environment
     * @return   The current environment's `Organization` record
     */
    @AuraEnabled(cacheable=true)
    public static Organization getOrganization() {
        return LoggerEngineDataSelector.getInstance().getCachedOrganization();
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
                    for (Profile matchingProfile : LogManagementDataSelector.getInstance().getProfilesByNameSearch(searchTerm)) {
                        SetupOwnerSearchResult result = new SetupOwnerSearchResult();
                        result.recordId = matchingProfile.Id;
                        result.label = matchingProfile.Name;
                        result.secondaryLabel = 'License: ' + matchingProfile.UserLicense.Name;
                        result.icon = 'utility:profile';
                        searchResults.add(result);
                    }
                }
                when 'User' {
                    for (User matchingUser : LogManagementDataSelector.getInstance().getUsersByNameSearch(searchTerm)) {
                        SetupOwnerSearchResult result = new SetupOwnerSearchResult();
                        result.recordId = matchingUser.Id;
                        result.label = matchingUser.Username;
                        result.secondaryLabel = 'Name: ' + matchingUser.Name;
                        result.icon = 'standard:people';
                        result.image = matchingUser.SmallPhotoUrl;
                        searchResults.add(result);
                    }
                }
                when else {
                    throw new System.IllegalArgumentException('Invalid SetupOwnerType: ' + setupOwnerType);
                }
            }
            return searchResults;
        } catch (System.Exception ex) {
            throw createAuraHandledException(ex);
        }
    }

    private static System.AuraHandledException createAuraHandledException(System.Exception ex) {
        System.AuraHandledException auraHandledException = new System.AuraHandledException(ex.getMessage());
        auraHandledException.setMessage(ex.getMessage());
        return auraHandledException;
    }

    private static List<PicklistOption> getLoggingLevelOptions() {
        List<PicklistOption> picklistOptions = initializePicklistOptions();
        for (Integer i = System.LoggingLevel.values().size() - 1; i > 0; i--) {
            System.LoggingLevel currentLoggingLevel = System.LoggingLevel.values().get(i);

            if (currentLoggingLevel == System.LoggingLevel.NONE || currentLoggingLevel == System.LoggingLevel.INTERNAL) {
                continue;
            }

            PicklistOption picklistOption = new PicklistOption();
            picklistOption.label = currentLoggingLevel.name();
            picklistOption.value = currentLoggingLevel.name();

            picklistOptions.add(picklistOption);
        }
        return picklistOptions;
    }

    private static List<PicklistOption> getPlatformEventStorageLocationOptions() {
        List<String> storageLocationNames = new List<String>{ CUSTOM_OBJECTS_STORAGE_LOCATION };
        for (LoggerParameter__mdt matchingAdditionalParameter : LoggerParameter.matchOnPrefix(CUSTOM_STORAGE_LOCATION_PREFIX)) {
            storageLocationNames.add(matchingAdditionalParameter.Value__c);
        }
        storageLocationNames.sort();

        List<PicklistOption> picklistOptions = initializePicklistOptions();
        for (String storageLocationName : storageLocationNames) {
            PicklistOption picklistOption = new PicklistOption();
            picklistOption.label = storageLocationName;
            picklistOption.value = storageLocationName;

            picklistOptions.add(picklistOption);
        }
        return picklistOptions;
    }

    private static List<PicklistOption> getPurgeActionOptions() {
        List<String> logPurgeActionNames = new List<String>{ DELETE_LOG_PURGE_ACTION };
        for (LoggerParameter__mdt matchingAdditionalParameter : LoggerParameter.matchOnPrefix(CUSTOM_LOG_PURGE_ACTION_PREFIX)) {
            logPurgeActionNames.add(matchingAdditionalParameter.Value__c);
        }
        logPurgeActionNames.sort();

        List<PicklistOption> picklistOptions = initializePicklistOptions();
        for (String logPurgeActionName : logPurgeActionNames) {
            PicklistOption picklistOption = new PicklistOption();
            picklistOption.label = logPurgeActionName;
            picklistOption.value = logPurgeActionName;

            picklistOptions.add(picklistOption);
        }
        return picklistOptions;
    }

    private static List<PicklistOption> getSaveMethodOptions() {
        List<String> saveMethodNames = new List<String>();
        for (Logger.SaveMethod saveMethod : Logger.SaveMethod.values()) {
            saveMethodNames.add(saveMethod.name());
        }
        for (LoggerParameter__mdt matchingAdditionalParameter : LoggerParameter.matchOnPrefix(CUSTOM_SAVE_METHOD_PREFIX)) {
            saveMethodNames.add(matchingAdditionalParameter.Value__c);
        }
        saveMethodNames.sort();

        List<PicklistOption> picklistOptions = initializePicklistOptions();
        for (String saveMethodName : saveMethodNames) {
            PicklistOption picklistOption = new PicklistOption();
            picklistOption.label = saveMethodName;
            picklistOption.value = saveMethodName;

            picklistOptions.add(picklistOption);
        }
        return picklistOptions;
    }

    private static List<PicklistOption> getSetupOwnerTypeOptions() {
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

    private static List<PicklistOption> getShareAccessLevelOptions() {
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

    private static List<LoggerSettings__c> queryLoggerSettings() {
        Set<String> fieldNames = new Set<String>(Schema.LoggerSettings__c.SObjectType.getDescribe().fields.getMap().keySet());
        fieldNames.add('CreatedBy.Username');
        fieldNames.add('LastModifiedBy.Username');
        fieldNames.add('SetupOwner.Name');
        fieldNames.add('SetupOwner.Type');
        return (List<LoggerSettings__c>) LogManagementDataSelector.getInstance().getAll(Schema.LoggerSettings__c.SObjectType, fieldNames);
    }

    private static Map<Id, String> querySetupOwnerNames(List<Id> setupOwnerIds) {
        Map<Id, String> setupOwnerIdToName = new Map<Id, String>();
        for (Profile profile : LogManagementDataSelector.getInstance().getProfilesById(setupOwnerIds)) {
            setupOwnerIdToName.put(profile.Id, profile.Name);
        }
        for (User user : LogManagementDataSelector.getInstance().getUsersById(setupOwnerIds)) {
            setupOwnerIdToName.put(user.Id, user.Username);
        }
        return setupOwnerIdToName;
    }

    /**
     * @description Inner class for returning all custom `List<PicklistOption>` in a single Apex method call
     */
    public class LoggerSettingsPicklistOptions {
        @AuraEnabled
        public List<PicklistOption> loggingLevelOptions;
        @AuraEnabled
        public List<PicklistOption> platformEventStorageLocationOptions;
        @AuraEnabled
        public List<PicklistOption> purgeActionOptions;
        @AuraEnabled
        public List<PicklistOption> saveMethodOptions;
        @AuraEnabled
        public List<PicklistOption> setupOwnerTypeOptions;
        @AuraEnabled
        public List<PicklistOption> shareAccessLevelOptions;
    }

    /**
     * @description Inner DTO class for picklist options since Schema.PicklistEntry isn't supported for aura-enabled methods
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
        public String createdByUsername;
        @AuraEnabled
        public String lastModifiedByUsername;
        @AuraEnabled
        public LoggerSettings__c record;

        /**
         * @description Implements sorting logic for the `Comparable` interface
         * @param  compareTo The object to compare to when sorting the current item
         * @return           The sorting result
         */
        public Integer compareTo(Object compareTo) {
            SettingsRecordResult that = (SettingsRecordResult) compareTo;
            if (this.getCompositeName() == that.getCompositeName()) {
                return 0;
            } else if (this.getCompositeName() > that.getCompositeName()) {
                return 1;
            } else {
                return -1;
            }
        }

        private String getCompositeName() {
            return this.setupOwnerType + '.' + this.setupOwnerName;
        }
    }

    /**
     * @description Inner class used for returning search results for `Profile` and `User` records
     */
    public class SetupOwnerSearchResult {
        @AuraEnabled
        public Id recordId;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String secondaryLabel;
        @AuraEnabled
        public String icon;
        @AuraEnabled
        public String image;
    }
}
