//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for the LWC `logViewer`, used to provided different views on a `Log__c` record
 */
public with sharing class LogViewerController {
    /**
     * @description Returns a Log__c record from the database, using either the Salesforce ID or transaction ID
     * @param  logId The Salesforce ID or TransactionId__c of the Log__c
     * @return       The matching record, with all fields that the current user can access
     */
    @AuraEnabled(cacheable=true)
    public static Log__c getLog(Id logId) {
        SObjectAccessDecision securityDecision = Security.stripInaccessible(
            AccessType.READABLE,
            new List<Log__c>{ LogManagementDataSelector.getInstance().getLogById(logId) }
        );
        return securityDecision.getRecords().isEmpty() ? null : (Log__c) securityDecision.getRecords().get(0);
    }
}
