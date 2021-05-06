//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group packaging
 * @description Automatically enables org default settings when installing the managed package
 */
global without sharing class LoggerInstallHandler implements InstallHandler {
    /**
     * @description Automatically enables org default settings when installing the managed package
     * @param  installContext Context automatically provided by Salesforce when installing or upgrading the managed package
     */
    global void onInstall(System.InstallContext installContext) {
        // Make sure the new DefaultSaveMethod__c field is set in the org
        List<LoggerSettings__c> settings = [SELECT Id, DefaultSaveMethod__c FROM LoggerSettings__c WHERE DefaultSaveMethod__c = null];
        for (LoggerSettings__c setting : settings) {
            setting.DefaultSaveMethod__c = 'EVENT_BUS';
        }
        update settings;

        // Make sure the orgDefaults have been created
        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        upsert orgDefaults;
    }
}
