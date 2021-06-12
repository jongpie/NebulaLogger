//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Interface used to define custom logic to run when DML statements occur on `Log__c` or `LogEntry__c`
 */
global abstract class LoggerSObjectHandlerPlugin {
    global abstract void execute(
        TriggerOperation triggerOperationType,
        List<SObject> triggerNew,
        Map<Id, SObject> triggerNewMap,
        List<SObject> triggerOld,
        Map<Id, SObject> triggerOldMap
    );

    global virtual LoggerSObjectHandlerPlugin__mdt getConfiguration() {
        // By default, check to see if there is a plugin named after the current Apex class name
        // Implementations of LoggerSObjectHandlerPlugin can override this behavior if desired
        String currentClassName = String.valueOf(this).substring(0, String.valueOf(this).indexOf(':'));
        return LoggerSObjectHandlerPlugin__mdt.getInstance(currentClassName);
    }

    // protected LoggerSObjectHandlerPlugin__mdt getConfiguration(String configurationDeveloperName) {
    //     // To include the child object LoggerSObjectHandlerPluginParameter__mdt, we have to query the object...
    //     // ...instead of using getAll()

    //     // TODO Consider caching the query results... maybe...
    //     return [
    //         SELECT
    //             Id,
    //             MasterLabel,
    //             DeveloperName,
    //             (SELECT Id, MasterLabel, DeveloperName, DataType__c, Value__c FROM LoggerSObjectHandlerPluginParameters__r WHERE IsEnabled__c = TRUE)
    //         FROM LoggerSObjectHandlerPlugin__mdt
    //         WHERE IsEnabled__c = TRUE AND DeveloperName = :configurationDeveloperName
    //     ];
    // }

    protected String getParameterValue(String parameterDeveloperName) {
        return this.getParameter(parameterDeveloperName)?.Value__c;
    }

    private LoggerSObjectHandlerPluginParameter__mdt getParameter(String parameterDeveloperName) {
        LoggerSObjectHandlerPluginParameter__mdt parameter = LoggerSObjectHandlerPluginParameter__mdt.getInstance(parameterDeveloperName);

        if (parameter == null || parameter.IsEnabled__c == false) {
            return null;
        }

        return parameter;
    }
}
