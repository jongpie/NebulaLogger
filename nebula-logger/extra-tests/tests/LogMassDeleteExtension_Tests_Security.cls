//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=false)
private class LogMassDeleteExtension_Tests_Security {
    private static final Profile STANDARD_USER_PROFILE = [SELECT Id FROM Profile WHERE Name IN ('Standard User', 'Usuario estándar')];

    @TestSetup
    static void setupData() {
        LoggerSObjectHandler.shouldExecute(false);

        List<Log__c> logs = new List<Log__c>();
        for (Integer i = 0; i < 10; i++) {
            Log__c log = new Log__c(TransactionId__c = 'TXN-' + i);
            logs.add(log);
        }
        insert logs;
    }

    @IsTest
    static void it_should_add_error_to_page_when_user_does_not_have_delete_access() {
        List<Log__c> logs = [SELECT Id, Name FROM Log__c];
        List<Log__c> logsToDelete = new List<Log__c>();
        List<Log__c> logsToKeep = new List<Log__c>();
        Integer numberToKeep = 3;
        for (Integer i = 0; i < logs.size(); i++) {
            if (i < numberToKeep) {
                logsToDelete.add(logs.get(i));
            } else {
                logsToKeep.add(logs.get(i));
            }
        }
        ApexPages.StandardSetController controller = new ApexPages.StandardSetController(logs);
        controller.setSelected(logsToDelete);
        PageReference pageReference = Page.LogMassDelete;
        System.Test.setCurrentPage(pageReference);
        User standardUser = LoggerMockDataCreator.createUser(STANDARD_USER_PROFILE.Id);
        System.runAs(standardUser) {
            System.Assert.isFalse(Schema.Log__c.SObjectType.getDescribe().isDeletable());

            new LogMassDeleteExtension(controller);

            String deleteAccessError = 'You do not have access to delete logs records';
            System.Assert.isTrue(ApexPages.hasMessages(ApexPages.SEVERITY.ERROR));
            System.Assert.areEqual(deleteAccessError, ApexPages.getMessages().get(0).getSummary());
        }
    }
}
