//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Handles trigger events for the `LoggerTag__c` object
 */
public without sharing class LoggerTagHandler extends LoggerSObjectHandler {
    private static final Map<String, Log__c> TRANSACTION_ID_TO_LOG = new Map<String, Log__c>();

    @TestVisible
    private List<LoggerTag__c> loggerTags;

    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override SObjectType getSObjectType() {
        return Schema.LoggerTag__c.SObjectType;
    }

    /**
     * @description Returns the string value of the `LoggerParameter__mdt` record that controls if the handler is enabled.
     *          The `LoggerSObjectHandler` class uses this method to retrieve the corresponding `LoggerParameter__mdt` to
     *          determine if the class should execute.
     * @return   The `DeveloperName` value of the `LoggerParameter__mdt` that controls if the handler is enabled
     */
    public override String getHandlerControlParameterName() {
        return 'IsLoggerTagHandlerEnabled';
    }

    /**
     * @description Returns the `SObjectField` on `LoggerPlugin__mdt` that controls if plugins are enabled
     *          for the handler's `SObjectType`
     * @return   The instance of `Schema.SObjectField` on `LoggerPlugin__mdt` for the current `SObjectType`
     */
    public override Schema.SObjectField getHandlerPluginControlField() {
        return Schema.LoggerPlugin__mdt.IsLoggerTagEnabled__c;
    }

    /**
     * @description Returns the `SObjectField` on `LoggerPlugin__mdt` that controls the sorting of plugins
     *          for the handler's `SObjectType`
     * @return   The instance of `Schema.SObjectField` on `LoggerPlugin__mdt` for the current `SObjectType`
     */
    public override Schema.SObjectField getHandlerPluginSortField() {
        return Schema.LoggerPlugin__mdt.LoggerTagExecutionOrder__c;
    }

    protected override void executeBeforeInsert(List<SObject> triggerNew) {
        this.loggerTags = (List<LoggerTag__c>) triggerNew;

        this.setUniqueIdField();
    }

    protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.loggerTags = (List<LoggerTag__c>) triggerNewMap.values();

        this.setUniqueIdField();
    }

    private void setUniqueIdField() {
        for (LoggerTag__c loggerTag : this.loggerTags) {
            loggerTag.UniqueId__c = loggerTag.Name;
        }
    }
}
