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
    public override Schema.SObjectType getSObjectType() {
        return Schema.LoggerTag__c.SObjectType;
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
