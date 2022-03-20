//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugin Framework
 * @description The core of the plugin framework, used to create custom Apex & Flow plugins for `LoggerSObjectHandler` and `LogBatchPurger`
 *              based on configurations stored in the custom metadata type `LoggerPlugin__mdt`
 */
public without sharing class LoggerPlugin {
    /**
     * @description Interface used to create plugins that can be used within Logger's batch job `LogBatchPurger`
     */
    public interface Batchable {
        void start(LoggerPlugin__mdt configuration, LogBatchPurger.BatchPurgerInput input);
        void execute(LoggerPlugin__mdt configuration, LogBatchPurger.BatchPurgerInput input, List<SObject> loggerRecords);
        void finish(LoggerPlugin__mdt configuration, LogBatchPurger.BatchPurgerInput input);
    }

    /**
     * @description Interface used to create plugins that can be used within Logger's trigger handler framework `LoggerSObjectHandler`
     */
    public interface Triggerable {
        void execute(LoggerPlugin__mdt configuration, LoggerSObjectHandler.SObjectHandlerInput input);
    }

    public static Batchable newBatchableInstance(LoggerPlugin__mdt pluginConfiguration) {
        return (Batchable) Type.forName(pluginConfiguration.BatchPurgerApexClass__c)?.newInstance();
    }

    public static Triggerable newTriggerableInstance(LoggerPlugin__mdt pluginConfiguration) {
        return (Triggerable) Type.forName(pluginConfiguration.SObjectHandlerApexClass__c)?.newInstance();
    }

    public static List<LoggerPlugin__mdt> getBatchPurgerPluginConfigurations() {
        List<String> orderByConditions = new List<String>{ Schema.LoggerPlugin__mdt.BatchPurgerExecutionOrder__c.getDescribe().getName() + ' NULLS LAST' };

        // CMDT objects don't support OR statements in SOQL, but (these) CMDT queries don't count towards query limits,
        // so run 2 queries in place of using OR statements
        List<LoggerPlugin__mdt> plugins = new List<LoggerPlugin__mdt>();
        plugins.addAll(
            queryPluginConfigurations(
                new List<String>{ Schema.LoggerPlugin__mdt.BatchPurgerApexClass__c.getDescribe().getName() + ' != NULL' },
                orderByConditions
            )
        );
        plugins.addAll(
            queryPluginConfigurations(
                new List<String>{ Schema.LoggerPlugin__mdt.BatchPurgerFlowName__c.getDescribe().getName() + ' != NULL' },
                orderByConditions
            )
        );
        return plugins;
    }

    public static List<LoggerPlugin__mdt> getSObjectHandlerPluginConfigurations(Schema.SObjectField handlerPluginSortField) {
        List<String> orderByConditions = new List<String>{ handlerPluginSortField.getDescribe().getName() + ' NULLS LAST' };

        // CMDT objects don't support OR statements in SOQL, but (these) CMDT queries don't count towards query limits,
        // so run 2 queries in place of using OR statements
        List<LoggerPlugin__mdt> plugins = new List<LoggerPlugin__mdt>();
        plugins.addAll(
            queryPluginConfigurations(
                new List<String>{ Schema.LoggerPlugin__mdt.SObjectHandlerApexClass__c.getDescribe().getName() + ' != NULL' },
                orderByConditions
            )
        );
        plugins.addAll(
            queryPluginConfigurations(
                new List<String>{ Schema.LoggerPlugin__mdt.SObjectHandlerFlowName__c.getDescribe().getName() + ' != NULL' },
                orderByConditions
            )
        );
        return plugins;
    }

    private static List<LoggerPlugin__mdt> queryPluginConfigurations(List<String> filterConditions, List<String> orderByConditions) {
        // Dynamically query the LoggerPlugin__mdt CMDT object so the records are filtered and sorted correctly
        List<String> fieldsToQuery = new List<String>(Schema.LoggerPlugin__mdt.SObjectType.getDescribe().fields.getMap().keySet());
        filterConditions.add(Schema.LoggerPlugin__mdt.IsEnabled__c.getDescribe().getName() + ' = TRUE');
        orderByConditions.add(Schema.LoggerPlugin__mdt.DeveloperName.getDescribe().getName());

        String queryTemplate = 'SELECT {0} FROM {1} WHERE {2} ORDER BY {3}';
        List<Object> queryInputs = new List<Object>{
            String.join(fieldsToQuery, ', '),
            Schema.LoggerPlugin__mdt.SObjectType.getDescribe().getName(),
            String.join(filterConditions, ' AND '),
            String.join(orderByConditions, ', ')
        };
        String query = String.format(queryTemplate, queryInputs);
        return (List<LoggerPlugin__mdt>) Database.query(query);
    }
}
