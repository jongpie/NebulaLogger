//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Manages mass deleting `Log__c` records that have been selected by a user on a `Log__c` list view
 */
public with sharing class LogMassDeleteExtension {
    @TestVisible
    private static final String DELETE_ACCESS_ERROR = 'You do not have access to delete logs records';

    @TestVisible
    private static Boolean userHasLogDeleteAccess = Schema.Log__c.SObjectType.getDescribe().isDeletable();

    private ApexPages.StandardSetController controller;

    /**
     * @description Constructor for Visual Force list page / StandardSetController.
     * @param  controller The standard set controller (passed in automatically via VF page)
     */
    public LogMassDeleteExtension(ApexPages.StandardSetController controller) {
        if (userHasLogDeleteAccess == false) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, DELETE_ACCESS_ERROR));
        }

        this.controller = controller;
    }

    /**
     * @description Filters the list of selected `Log__c` records to only include records that the current user can delete (based on object-level access)
     * @return      The matching `Log__c` records that the current user has access to delete
     */
    public List<Log__c> getDeletableLogs() {
        // The UserRecordAccess object is weird - RecordId is not an actual ID field, so you can't filter using `List<SObject>` or `List<Id>`, you have to use strings
        // So, here's some code that would be unnecessary if RecordId were a polymorphic ID field instead
        List<String> logIds = new List<String>();
        for (Log__c selectedLog : (List<Log__c>) this.controller.getSelected()) {
            logIds.add(selectedLog.Id);
        }

        // Get the list of record IDs that the current user can delete
        List<Id> deletableLogIds = new List<Id>();
        for (UserRecordAccess recordAccess : LogManagementDataSelector.getInstance().getDeleteableUserRecordAccess(logIds)) {
            deletableLogIds.add(recordAccess.RecordId);
        }

        // Get the logs + any fields shown in the VF page
        return LogManagementDataSelector.getInstance().getLogsById(deletableLogIds);
    }

    /**
     * @description Deletes the list of selected `Log__c` records (if the current user has delete access for the `Log__c` object)
     * @return      The PageReference of the previous page (based on `controller.cancel()`)
     */
    public PageReference deleteSelectedLogs() {
        LoggerDataStore.getDatabase().deleteRecords(getDeletableLogs());

        // The controller's method cancel() just returns the user to the previous page - it doesn't rollback any DML statements (like the delete above)
        return this.controller.cancel();
    }
}
