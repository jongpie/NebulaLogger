//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Handles trigger events for the `LoggerNotification__c` object
 */
public without sharing class LoggerNotificationHandler extends LoggerSObjectHandler {
    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override Schema.SObjectType getSObjectType() {
        return Schema.LoggerNotification__c.SObjectType;
    }

    protected override void executeBeforeInsert(List<SObject> triggerNew) {
        List<LoggerNotification__c> loggerNotifications = (List<LoggerNotification__c>) triggerNew;

        this.validateFilters(loggerNotifications);
        this.setOrganizationId(loggerNotifications);
    }

    private void validateFilters(List<LoggerNotification__c> loggerNotifications) {
        for (LoggerNotification__c loggerNotification : loggerNotifications) {
            if (new LoggerEvaluator().isValid(loggerNotification.SourceSObjectFilter__c, Schema.LogEntry__c.SObjectType) == false) {
                // TODO
                // loggerNotification.addError('Invalid SOQL WHERE clause: ' + loggerNotification.SourceSObjectFilter__c);
            }
        }
    }

    private void setOrganizationId(List<LoggerNotification__c> loggerNotifications) {
        for (LoggerNotification__c loggerNotification : loggerNotifications) {
            loggerNotification.OrganizationId__c = LoggerEngineDataSelector.getInstance().getCachedOrganization().Id;
        }
    }
}
