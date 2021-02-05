/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
global without sharing class LoggerInstallHandler implements InstallHandler {
    global void onInstall(System.InstallContext installContext) {
        LoggerSettings__c orgDefaults = LoggerSettings__c.getOrgDefaults();
        upsert orgDefaults;

        if (loggerSettings__c.getInstance().EnableSystemMessages__c) {
            LogMessage logMessage = new logMessage('Upserting Org Defaults: {0}', orgDefaults);
            List<String> logTopics = new List<String>{ 'Logger-Installation' };
            Logger.info(logMessage, logTopics);
            Logger.saveLog();
        }
    }
}
