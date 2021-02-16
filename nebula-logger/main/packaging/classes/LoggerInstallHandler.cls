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
     * Automatically enables org default settings when installing the managed package
     * @param  installContext Context automatically provided by Salesforce when installing or upgrading
     */
    global void onInstall(System.InstallContext installContext) {
        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        upsert orgDefaults;
    }
}
