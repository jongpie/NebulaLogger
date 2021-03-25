//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

public with sharing class LogMassDeleteExtension {

    public class LogMassDeleteException extends Exception {}

    private ApexPages.StandardSetController controller;

    public LogMassDeleteExtension(ApexPages.StandardSetController controller) {
        if (Schema.Log__c.SObjectType.getDescribe().isDeletable() == false) {
            String deleteAccessError = 'You do not have access to delete logs records';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, deleteAccessError));
        }

        this.controller = controller;
    }

    public List<Log__c> getDeletableLogs() {
        List<String> logIds = new List<String>();
        for (Log__c selectedLog : (List<Log__c>)this.controller.getSelected()) {
            logIds.add(selectedLog.Id);
        }

        List<Log__c> deletableLogs = new List<Log__c>();
        for (UserRecordAccess recordAccess : [SELECT RecordId FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId IN :logIds AND HasDeleteAccess = true]) {
            deletableLogs.add(new Log__c(Id = recordAccess.RecordId));
        }

        return deletableLogs;
    }

    public PageReference deleteSelectedLogs() {
        try {
            delete getDeletableLogs();
        } catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }

        return this.controller.cancel();
    }
}