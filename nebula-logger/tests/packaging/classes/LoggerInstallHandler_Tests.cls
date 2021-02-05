/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
@isTest
private class LoggerInstallHandler_Tests {
    @isTest
    static void it_should_initialize_logger_settings_when_installed() {
        // Quick sanity check to make sure there are no existing records
        List<LoggerSettings__c> existingSettings = [SELECT Id FROM LoggerSettings__c];
        System.assertEquals(0, existingSettings.size());

        // Currently, there's no logic in LoggerInstallerHandler that checks for a specific version number,
        // so null is fine for this test
        // TODO update this if/when version-specific logic is added in future releases
        Version version = null;

        Test.startTest();
        LoggerInstallHandler installHandler = new LoggerInstallHandler();
        Test.testInstall(installHandler, version, true);
        Test.stopTest();

        // Verify that we now have 1 record...
        List<LoggerSettings__c> loggerSettings = [SELECT Id FROM LoggerSettings__c];
        System.assertEquals(1, loggerSettings.size());

        // ..and verify that it's the org defaults
        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        System.assertEquals(orgDefaults.Id, loggerSettings.get(0).Id);
    }
}
