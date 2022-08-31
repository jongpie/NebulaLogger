//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Handles trigger events for the `LogScenario__c` object
 */
public without sharing class LogScenarioHandler extends LoggerSObjectHandler {
    @TestVisible
    private List<LogScenario__c> logScenarios;

    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override Schema.SObjectType getSObjectType() {
        return Schema.LogScenario__c.SObjectType;
    }

    protected override void executeBeforeInsert(List<SObject> triggerNew) {
        this.logScenarios = (List<LogScenario__c>) triggerNew;

        this.setNameField();
    }

    private void setNameField() {
        for (LogScenario__c logScenario : this.logScenarios) {
            if (String.isBlank(logScenario.Name) == true && String.isNotBlank(logScenario.UniqueId__c) == true) {
                logScenario.Name = logScenario.UniqueId__c;
            }
            Integer nameFieldMaxLength = Schema.LogScenario__c.Name.getDescribe().getLength();
            logScenario.Name = logScenario.UniqueId__c.left(nameFieldMaxLength);
        }
    }
}
