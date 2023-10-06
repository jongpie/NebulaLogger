//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Provides a centralized way to load scenario rules that override behavior
 *              within Nebula Logger
 */
public without sharing class LoggerScenarioRule {
    private static final Map<String, LoggerScenarioRule__mdt> SCENARIO_NAME_TO_SCENARIO_RULE = loadLogScenarioRules();

    /**
     * @description Returns a map containing any enabled `LoggerScenarioRule__mdt` records with
     *              valid `StartTime__c` and `EndTime__c` values (null is considered valid)
     * @return   The current transaction's cached `Map<String, LoggerScenarioRule__mdt>`, where the key
     *           is the log scenario (configured in `LoggerScenarioRule__mdt.Scenario__c`)
     */
    public static Map<String, LoggerScenarioRule__mdt> getAll() {
        return SCENARIO_NAME_TO_SCENARIO_RULE;
    }

    /**
     * @description Returns the `LoggerScenarioRule__mdt` with the matching scenario,
     *              based on the field `LoggerScenarioRule__mdt.Scenario__c`
     * @param  scenario The name of the scenario
     * @return          The matching `LoggerScenarioRule__mdt` if one is found, or `null`
     */
    public static LoggerScenarioRule__mdt getInstance(String scenario) {
        return SCENARIO_NAME_TO_SCENARIO_RULE.get(scenario);
    }

    @TestVisible
    private static void setMock(LoggerScenarioRule__mdt scenarioRule) {
        if (String.isBlank(scenarioRule.Scenario__c)) {
            throw new System.IllegalArgumentException('Scenario__c is required on `LoggerScenarioRule__mdt: \n' + JSON.serializePretty(scenarioRule));
        }

        if (isValid(scenarioRule)) {
            SCENARIO_NAME_TO_SCENARIO_RULE.put(scenarioRule.Scenario__c, scenarioRule);
        }
    }

    private static Map<String, LoggerScenarioRule__mdt> loadLogScenarioRules() {
        Map<String, LoggerScenarioRule__mdt> scenarioRules = new Map<String, LoggerScenarioRule__mdt>();
        for (LoggerScenarioRule__mdt scenarioRule : LoggerScenarioRule__mdt.getAll().values()) {
            if (isValid(scenarioRule)) {
                scenarioRules.put(scenarioRule.Scenario__c, scenarioRule);
            }
        }

        if (System.Test.isRunningTest()) {
            scenarioRules.clear();
        }

        return scenarioRules;
    }

    private static Boolean isValid(LoggerScenarioRule__mdt scenarioRule) {
        Boolean isValid = false;
        if (scenarioRule.IsEnabled__c) {
            Datetime currentTime = System.now();
            Boolean startTimeIsValid = scenarioRule.StartTime__c == null || scenarioRule.StartTime__c <= currentTime;
            Boolean endTimeIsValid = scenarioRule.EndTime__c == null || scenarioRule.EndTime__c >= currentTime;

            isValid = startTimeIsValid && endTimeIsValid;
        }
        return isValid;
    }
}
