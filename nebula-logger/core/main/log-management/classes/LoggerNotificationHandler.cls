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

    protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        List<LoggerNotification__c> loggerNotifications = (List<LoggerNotification__c>) triggerNewMap.values();
        Map<Id, LoggerNotification__c> loggerNotificationIdToOldLoggerNotification = (Map<Id, LoggerNotification__c>) triggerOldMap;

        this.validateFilters(loggerNotifications, loggerNotificationIdToOldLoggerNotification);
        this.setOrganizationId(loggerNotifications);
    }

    private void validateFilters(List<LoggerNotification__c> loggerNotifications) {
        for (LoggerNotification__c loggerNotification : loggerNotifications) {
            LoggerNotificationService.validateFilterFormula(loggerNotification.LogEntryFilter__c);
        }
    }

    private void validateFilters(List<LoggerNotification__c> loggerNotifications, Map<Id, LoggerNotification__c> loggerNotificationIdToOldLoggerNotification) {
        for (LoggerNotification__c loggerNotification : loggerNotifications) {
            LoggerNotification__c oldLoggerNotification = loggerNotificationIdToOldLoggerNotification.get(loggerNotification.Id);
            if (loggerNotification.LogEntryFilter__c != oldLoggerNotification.LogEntryFilter__c) {
                LoggerNotificationService.validateFilterFormula(loggerNotification.LogEntryFilter__c);
            }
        }
    }

    private void setOrganizationId(List<LoggerNotification__c> loggerNotifications) {
        for (LoggerNotification__c loggerNotification : loggerNotifications) {
            loggerNotification.OriginOrganizationId__c = System.UserInfo.getOrganizationId();
        }
    }
}
