//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description The core of the plugin framework, used to create custom Apex & Flow plugins for `LoggerSObjectHandler` and `LogBatchPurger`
 *              based on configurations stored in the custom metadata type `LoggerPlugin__mdt`
 */
public without sharing class LoggerPlugin {
    private static final Map<String, LoggerPlugin__mdt> DEVELOPER_NAME_TO_RECORD = loadEnabledRecords();

    /**
     * @description Interface used to create plugins that can be used within Logger's batch job `LogBatchPurger`
     */
    @SuppressWarnings('PMD.ApexDoc')
    public interface Batchable {
        void start(LoggerPlugin__mdt configuration, LoggerBatchableContext input);
        void execute(LoggerPlugin__mdt configuration, LoggerBatchableContext input, List<SObject> scopeRecords);
        void finish(LoggerPlugin__mdt configuration, LoggerBatchableContext input);
    }

    /**
     * @description Interface used to create plugins that can be used within Logger's trigger handler framework `LoggerSObjectHandler`
     */
    @SuppressWarnings('PMD.ApexDoc')
    public interface Triggerable {
        void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input);
    }

    /**
     * @description Returns all enabled `LoggerPlugin__mdt` records (where `IsEnabled__c` is set to `true`)
     * @return      The list of enabled `LoggerPlugin__mdt` records
     */
    public static List<LoggerPlugin__mdt> getPluginConfigurations() {
        return DEVELOPER_NAME_TO_RECORD.values();
    }

    /**
     * @description Filters the configured `LoggerPlugin__mdt` records based on a list of `SObjectField` - only records that have a value for 1 or more
     *              of the specified `populatedFilterFields` will be returned, sorted by the specified `SObjectField` parameter `sortByField`
     * @param  populatedFilterFields The list of `SObjectField` to check on each `LoggerPlugin__mdt` record - filtering logic checks for a non-null value
     * @param  sortByField           The `SObjectField` to use to sort the list of matches. The method also uses `DeveloperName` as a secondary field for sorting.
     * @return                       The list of matching `LoggerPlugin__mdt` records
     */
    public static List<LoggerPlugin__mdt> getFilteredPluginConfigurations(List<Schema.SObjectField> populatedFilterFields, Schema.SObjectField sortByField) {
        List<PluginConfigurationSorter> matchingPluginConfigurationSorters = new List<PluginConfigurationSorter>();
        for (LoggerPlugin__mdt pluginConfiguration : DEVELOPER_NAME_TO_RECORD.values()) {
            Boolean matchesFilterFields = false;
            for (Schema.SObjectField filterField : populatedFilterFields) {
                if (pluginConfiguration.get(filterField) != null) {
                    matchesFilterFields = true;
                    break;
                }
            }
            if (matchesFilterFields) {
                matchingPluginConfigurationSorters.add(
                    new PluginConfigurationSorter(pluginConfiguration).sortBy(sortByField).sortBy(Schema.LoggerPlugin__mdt.DeveloperName)
                );
            }
        }
        matchingPluginConfigurationSorters.sort();
        List<LoggerPlugin__mdt> matchingPluginConfigurations = new List<LoggerPlugin__mdt>();
        for (PluginConfigurationSorter sorter : matchingPluginConfigurationSorters) {
            matchingPluginConfigurations.add(sorter.pluginConfiguration);
        }
        return matchingPluginConfigurations;
    }

    /**
     * @description Creates an instance of the class `LoggerPlugin.Batchable` based on the provided `LoggerPlugin__mdt` configuration
     * @param  apexClassTypeName The name of the Apex class that implements `LoggerPlugin.Batchable`
     * @return                     The dynamically created instance of `LoggerPlugin.Batchable`,
     *                             or null if an instance could not be created based on the provided configuration
     */
    public static Batchable newBatchableInstance(String apexClassTypeName) {
        Object pluginInstance = newPluginInstance(apexClassTypeName);
        Boolean isValidInstance = pluginInstance instanceof Batchable;
        if (isValidInstance == false) {
            pluginInstance = null;
        }
        return (Batchable) pluginInstance;
    }

    /**
     * @description Creates an instance of the class `LoggerPlugin.Triggerable` based on the provided `LoggerPlugin__mdt` configuration
     * @param  apexClassTypeName The name of the Apex class that implements `LoggerPlugin.Triggerable`
     * @return                     The dynamically created instance of `LoggerPlugin.Triggerable`,
     *                             or null if an instance could not be created based on the provided configuration
     */
    public static Triggerable newTriggerableInstance(String apexClassTypeName) {
        Object pluginInstance = newPluginInstance(apexClassTypeName);
        Boolean isValidInstance = pluginInstance instanceof Triggerable;
        if (isValidInstance == false) {
            pluginInstance = null;
        }
        return (Triggerable) pluginInstance;
    }

    private static Object newPluginInstance(String apexClassTypeName) {
        return System.Type.forName(apexClassTypeName)?.newInstance();
    }

    private static Map<String, LoggerPlugin__mdt> loadEnabledRecords() {
        Map<String, LoggerPlugin__mdt> pluginDeveloperNameToConfiguration = new Map<String, LoggerPlugin__mdt>();
        for (LoggerPlugin__mdt pluginConfiguration : LoggerPlugin__mdt.getAll().values()) {
            if (pluginConfiguration.IsEnabled__c) {
                pluginDeveloperNameToConfiguration.put(pluginConfiguration.DeveloperName, pluginConfiguration);
            }
        }
        if (System.Test.isRunningTest()) {
            pluginDeveloperNameToConfiguration.clear();
        }
        return pluginDeveloperNameToConfiguration;
    }

    @TestVisible
    private static void setMock(LoggerPlugin__mdt pluginConfiguration) {
        if (String.isBlank(pluginConfiguration.DeveloperName)) {
            throw new System.IllegalArgumentException('DeveloperName is required on mock LoggerPlugin__mdt: \n' + JSON.serializePretty(pluginConfiguration));
        }
        if (pluginConfiguration.IsEnabled__c) {
            DEVELOPER_NAME_TO_RECORD.put(pluginConfiguration.DeveloperName, pluginConfiguration);
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    private class PluginConfigurationSorter implements Comparable {
        public LoggerPlugin__mdt pluginConfiguration;
        private List<Schema.SObjectField> sortByFields = new List<Schema.SObjectField>();

        public PluginConfigurationSorter(LoggerPlugin__mdt pluginConfiguration) {
            this.pluginConfiguration = pluginConfiguration;
        }

        public PluginConfigurationSorter sortBy(Schema.SObjectField field) {
            sortByFields.add(field);
            return this;
        }

        public Integer compareTo(Object compareTo) {
            PluginConfigurationSorter that = (PluginConfigurationSorter) compareTo;

            for (Schema.SObjectField field : this.sortByFields) {
                // Ugly block to handle numeric comparisons vs string comparisons (based on the field type)
                Boolean thisIsGreaterThanThat = false;
                if (field.getDescribe().getSoapType() == Schema.SoapType.DOUBLE) {
                    thisIsGreaterThanThat = (Decimal) this.pluginConfiguration.get(field) > (Decimal) that.pluginConfiguration.get(field);
                } else {
                    thisIsGreaterThanThat = (String) this.pluginConfiguration.get(field) > (String) that.pluginConfiguration.get(field);
                }

                // Now, the actual comparisons
                if (this.pluginConfiguration.get(field) == that.pluginConfiguration.get(field)) {
                    continue;
                } else if (this.pluginConfiguration.get(field) == null && that.pluginConfiguration.get(field) != null || thisIsGreaterThanThat) {
                    return 1;
                } else {
                    return -1;
                }
            }
            return 0;
        }
    }
}
