/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
global without sharing class LoggerInstallHandler implements InstallHandler {
    // private static final PermissionSet LOGGER_END_USER_PERMISSION_SET = [
    //     SELECT Id
    //     FROM PermissionSet
    //     WHERE NamespacePrefix = :Namespace.getPrefix() AND Name = 'LoggerEndUser'
    // ];

    /***
     * @description Runs on package installation.
     * @param installContext The install context, provided by Salesforce
     * @return void
     */
    global void onInstall(System.InstallContext installContext) {
        if (installContext == null) {
            return;
        }

        //LoggerCache.initializeOrgCache();

        if (installContext.previousVersion() == null) {
            // First install of Logger
            insert LoggerSettings__c.getOrgDefaults();
            //assignLoggerEndUserPermissionSet();
        }
        // else if (installContext.isUpgrade() || installContext.isPush()) { }
    }

    // private void assignLoggerEndUserPermissionSet() {
    //     List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();

    //     for (User activeUser : [SELECT Id FROM User WHERE IsActive = TRUE]) {
    //         PermissionSetAssignment psa = new PermissionSetAssignment(
    //             AssigneeId = activeUser.Id,
    //             PermissionSetId = LOGGER_END_USER_PERMISSION_SET.Id
    //         );
    //     }

    //     Database.insert(permissionSetAssignments, false);
    // }
}
