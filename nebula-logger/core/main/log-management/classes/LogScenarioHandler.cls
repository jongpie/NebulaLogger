//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Handles trigger events for the `LogScenario__c` object
 */
public without sharing class LogScenarioHandler extends LoggerSObjectHandler {
    private static final Map<String, Log__c> TRANSACTION_ID_TO_LOG = new Map<String, Log__c>();

    @TestVisible
    private List<LogScenario__c> logScenarios;

    /**
     * @description Generates a unique key for the `LogScenario__c` record, which
     *              is used to set the field `LogScenario__c.UniqueId__c`
     * @param  logScenario The `LogScenario__c` record to use for generating a unique ID
     * @return             The unique key for the record
     */
    public static String generateUniqueId(LogScenario__c logScenario) {
        return logScenario.Name?.trim();
    }

    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override Schema.SObjectType getSObjectType() {
        return Schema.LogScenario__c.SObjectType;
    }

    protected override void executeBeforeInsert(List<SObject> triggerNew) {
        this.logScenarios = (List<LogScenario__c>) triggerNew;

        this.setUniqueIdField();
    }

    protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.logScenarios = (List<LogScenario__c>) triggerNewMap.values();

        this.setUniqueIdField();
    }

    private void setUniqueIdField() {
        for (LogScenario__c logScenario : this.logScenarios) {
            logScenario.UniqueId__c = logScenario.Name;
        }
    }
}
