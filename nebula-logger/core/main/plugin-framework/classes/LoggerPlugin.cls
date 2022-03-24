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
    private static final Map<String, LoggerPlugin__mdt> DEVELOPER_NAME_TO_RECORD = loadRecords();

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

    public static List<LoggerPlugin__mdt> getBatchPurgerPluginConfigurations() {
        List<PluginConfigurationSorter> matchingPluginConfigurationSorters = new List<PluginConfigurationSorter>();
        for (LoggerPlugin__mdt pluginConfiguration : DEVELOPER_NAME_TO_RECORD.values()) {
            if (pluginConfiguration.BatchPurgerApexClass__c != null || pluginConfiguration.BatchPurgerFlowName__c != null) {
                matchingPluginConfigurationSorters.add(
                    new PluginConfigurationSorter(pluginConfiguration)
                        .sortBy(Schema.LoggerPlugin__mdt.BatchPurgerExecutionOrder__c)
                        .sortBy(Schema.LoggerPlugin__mdt.DeveloperName)
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

    public static List<LoggerPlugin__mdt> getSObjectHandlerPluginConfigurations() {
        List<PluginConfigurationSorter> matchingPluginConfigurationSorters = new List<PluginConfigurationSorter>();
        for (LoggerPlugin__mdt pluginConfiguration : DEVELOPER_NAME_TO_RECORD.values()) {
            if (pluginConfiguration.SObjectHandlerApexClass__c != null || pluginConfiguration.SObjectHandlerFlowName__c != null) {
                matchingPluginConfigurationSorters.add(
                    new PluginConfigurationSorter(pluginConfiguration)
                        .sortBy(Schema.LoggerPlugin__mdt.SObjectHandlerExecutionOrder__c)
                        .sortBy(Schema.LoggerPlugin__mdt.DeveloperName)
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

    public static Batchable newBatchableInstance(LoggerPlugin__mdt pluginConfiguration) {
        return (Batchable) Type.forName(pluginConfiguration?.BatchPurgerApexClass__c)?.newInstance();
    }

    public static Triggerable newTriggerableInstance(LoggerPlugin__mdt pluginConfiguration) {
        return (Triggerable) Type.forName(pluginConfiguration?.SObjectHandlerApexClass__c)?.newInstance();
    }

    private static Map<String, LoggerPlugin__mdt> loadRecords() {
        Map<String, LoggerPlugin__mdt> pluginConfigurations = LoggerPlugin__mdt.getAll().clone();
        if (System.Test.isRunningTest() == true) {
            pluginConfigurations.clear();
        }
        return pluginConfigurations;
    }

    @TestVisible
    private static void setMock(LoggerPlugin__mdt pluginConfiguration) {
        if (String.isBlank(pluginConfiguration.DeveloperName) == true) {
            throw new IllegalArgumentException('DeveloperName is required on mock LoggerPlugin__mdt: \n' + JSON.serializePretty(pluginConfiguration));
        }
        if (pluginConfiguration.IsEnabled__c == true) {
            DEVELOPER_NAME_TO_RECORD.put(pluginConfiguration.DeveloperName, pluginConfiguration);
        }
    }

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
                if (
                    field.getDescribe().getSoapType() == Schema.SoapType.DOUBLE &&
                    (Decimal) this.pluginConfiguration.get(field) > (Decimal) that.pluginConfiguration.get(field)
                ) {
                    thisIsGreaterThanThat = true;
                } else if ((String) this.pluginConfiguration.get(field) > (String) that.pluginConfiguration.get(field)) {
                    thisIsGreaterThanThat = true;
                }

                // Now, the actual comparisons
                if (this.pluginConfiguration.get(field) == that.pluginConfiguration.get(field)) {
                    continue;
                } else if (this.pluginConfiguration.get(field) == null && that.pluginConfiguration.get(field) != null || thisIsGreaterThanThat == true) {
                    return 1;
                } else {
                    return -1;
                }
            }
            return 0;
        }
    }
}
