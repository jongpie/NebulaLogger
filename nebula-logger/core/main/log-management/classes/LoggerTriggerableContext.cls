//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description DTO class used by the logging system to for trigger contextual details
 * @see LoggerSObjectHandler
 * @see LoggerPlugin
 */
public without sharing class LoggerTriggerableContext {
    public Schema.SObjectType sobjectType;
    public TriggerOperation triggerOperationType;
    public List<SObject> triggerNew;
    public Map<Id, SObject> triggerNewMap;
    public Map<Id, SObject> triggerOldMap;

    @AuraEnabled
    public String sobjectTypeName;

    @AuraEnabled
    public String triggerOperationTypeName;

    @AuraEnabled
    public List<RecordInput> triggerRecords;

    /**
     * @description Class used by the logging system to provide trigger record details to Flow
     */
    public class RecordInput {
        @AuraEnabled
        public SObject triggerRecordNew;

        @AuraEnabled
        public SObject triggerRecordOld;
    }
}
