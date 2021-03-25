public with sharing class LogMassDeleteExtension {
    private List<Log__c> selectedLogs;
    public LogMassDeleteExtension(ApexPages.StandardSetController controller) {
        if (Schema.Log__c.SObjectType.getDescribe().isDeletable() == false) {
            throw new AuraHandledException('You do not have access to delete logs records');
        }

        this.selectedLogs = controller.getSelected();
    }

    public Integer getCountOfSelected() {
        return this.selectedLogs.size();
    }

    public List<Log__c> getDeletableLogs() {
        List<String> logIds = new List<String>();
        for (Log__c selectedLog : this.selectedLogs) {
            logIds.add(selectedLog.Id);
        }

        List<Log__c> deletableLogs = new List<Log__c>();
        for (UserRecordAccess recordAccess : [SELECT RecordId FROM UserRecordAccess WHERE UserId = :UserInfo.getUserId() AND RecordId IN :logIds AND HasDeleteAccess = true]) {
            deletableLogs.add(new Log__c(Id = recordAccess.RecordId));
        }

        return deletableLogs;
    }
    public void deleteSelectedLogs() {
        // TODO
    }
}