global without sharing class LoggerInstallHandler implements InstallHandler {
    private static final PermissionSet LOGGER_END_USER_PERMISSION_SET = [
        SELECT Id
        FROM PermissionSet
        WHERE NamespacePrefix = :Namespace.getNamespace() AND Name = 'LoggerEndUser'
    ];

    /***
     * @description Runs on package installation.
     * @param installContext The install context, provided by Salesforce
     * @return void
     */
    global void onInstall(System.InstallContext installContext) {
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

    /*******************************************************************************************************
     * @description Sends an email to the user installing the package notifying them about failed installation steps.
     * @return void
     */
    /* private void sendInstallNotificationEmail() {
        try {
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            emailMessage.setUseSignature(false);
            emailMessage.setReplyTo('no.reply@salesforce.com');
            emailMessage.setSenderDisplayName('Nebula Logger Managed Package Success Pack');
            emailMessage.setSubject('NPSP Install Errors');

            emailMessage.setPlainTextBody(buildEmailBody());

            emailMessage.setToAddresses(new List<String>{ 'errors@salesforce.org', getUserEmail() });

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception e) {
            //Nothing to do here, as we don't want the install script to fail because emails could not be sent.
        }
    } */
}
