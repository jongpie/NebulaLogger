//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Handles trigger events for the `LogEntryTag__c` object
 */
public without sharing class LogEntryTagHandler extends LoggerSObjectHandler {
    private static final Map<String, Log__c> TRANSACTION_ID_TO_LOG = new Map<String, Log__c>();

    @TestVisible
    private List<LogEntryTag__c> logEntryTags;

    /**
     * @description Generates a unique composite key for the `LogEntryTag__c` record, which
     *              is used to set the field `LogEntryTag__c.UniqueId__c`
     * @param  logEntryTag The `LogEntryTag__c` record to use for generating a unique ID
     * @return             The unique composite key for the record
     */
    public static String generateUniqueId(LogEntryTag__c logEntryTag) {
        return logEntryTag.LogEntry__c + '' + logEntryTag.Tag__c;
    }

    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override Schema.SObjectType getSObjectType() {
        return Schema.LogEntryTag__c.SObjectType;
    }

    protected override void executeBeforeInsert(List<SObject> triggerNew) {
        this.logEntryTags = (List<LogEntryTag__c>) triggerNew;

        this.setUniqueIdField();
    }

    protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.logEntryTags = (List<LogEntryTag__c>) triggerNewMap.values();

        this.setUniqueIdField();
    }

    private void setUniqueIdField() {
        for (LogEntryTag__c logEntryTag : this.logEntryTags) {
            logEntryTag.UniqueId__c = generateUniqueId(logEntryTag);
        }
    }
}
