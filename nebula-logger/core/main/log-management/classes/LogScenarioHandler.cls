//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Handles trigger events for the `LogScenario__c` object
 */
public without sharing class LogScenarioHandler extends LoggerSObjectHandler {
    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override Schema.SObjectType getSObjectType() {
        return Schema.LogScenario__c.SObjectType;
    }
}
