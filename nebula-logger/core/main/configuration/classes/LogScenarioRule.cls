//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Provides a centralized way to load scenario rules that override behavior
 *              within Nebula Logger
 */
public without sharing class LogScenarioRule {
    private static final Map<String, LogScenarioRule__mdt> SCENARIO_NAME_TO_SCENARIO_RULE = loadLogScenarioRules();

    /**
     * @description Returns a map containing any enabled `LogScenarioRule__mdt` records with
     *              valid `StartTime__c` and `EndTime__c` values (null is considered valid)
     * @return   The current transaction's cached `Map<String, LogScenarioRule__mdt>`, where the key
     *           is the log scenario (configured in `LogScenarioRule__mdt.Scenario__c`)
     */
    public static Map<String, LogScenarioRule__mdt> getAll() {
        return SCENARIO_NAME_TO_SCENARIO_RULE;
    }

    /**
     * @description Returns the `LogScenarioRule__mdt` with the matching scenario,
     *              based on the field `LogScenarioRule__mdt.Scenario__c`
     * @param  scenario The name of the scenario
     * @return          The matching `LogScenarioRule__mdt` if one is found, or `null`
     */
    public static LogScenarioRule__mdt getInstance(String scenario) {
        return SCENARIO_NAME_TO_SCENARIO_RULE.get(scenario);
    }

    @TestVisible
    private static void setMock(LogScenarioRule__mdt scenarioRule) {
        if (String.isBlank(scenarioRule.Scenario__c) == true) {
            throw new IllegalArgumentException('Scenario__c is required on `LogScenarioRule__mdt: \n' + JSON.serializePretty(scenarioRule));
        }

        if (isValid(scenarioRule) == true) {
            SCENARIO_NAME_TO_SCENARIO_RULE.put(scenarioRule.Scenario__c, scenarioRule);
        }
    }

    private static Map<String, LogScenarioRule__mdt> loadLogScenarioRules() {
        Map<String, LogScenarioRule__mdt> scenarioRules = new Map<String, LogScenarioRule__mdt>();
        for (LogScenarioRule__mdt scenarioRule : LogScenarioRule__mdt.getAll().values()) {
            if (isValid(scenarioRule) == true) {
                scenarioRules.put(scenarioRule.Scenario__c, scenarioRule);
            }
        }

        if (System.Test.isRunningTest() == true) {
            scenarioRules.clear();
        }

        return scenarioRules;
    }

    private static Boolean isValid(LogScenarioRule__mdt scenarioRule) {
        Boolean isValid = false;
        if (scenarioRule.IsEnabled__c == true) {
            Datetime currentTime = System.now();
            Boolean startTimeIsValid = scenarioRule.StartTime__c == null || scenarioRule.StartTime__c <= currentTime;
            Boolean endTimeIsValid = scenarioRule.EndTime__c == null || scenarioRule.EndTime__c >= currentTime;

            isValid = startTimeIsValid == true && endTimeIsValid == true;
        }
        return isValid;
    }
}
