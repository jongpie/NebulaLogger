//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Abstract class used by trigger handlers for shared logic
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.EmptyStatementBlock')
public without sharing abstract class LoggerSObjectHandler {
    private static Map<SObjectType, List<LoggerPlugin__mdt>> pluginsBySObjectType = new Map<SObjectType, List<LoggerPlugin__mdt>>();

    @TestVisible
    private TriggerOperation triggerOperationType;
    @TestVisible
    private List<SObject> triggerNew;
    @TestVisible
    private Map<Id, SObject> triggerNewMap;
    @TestVisible
    private List<SObject> triggerOld;
    @TestVisible
    private Map<Id, SObject> triggerOldMap;

    private List<LoggerPlugin__mdt> plugins;

    static {
        // Query the LoggerPlugin__mdt CMDT object so the records are sorted correctly
        List<LoggerPlugin__mdt> plugins = [
            SELECT SObjectType__r.QualifiedApiName, PluginType__c, PluginApiName__c
            FROM LoggerPlugin__mdt
            WHERE IsEnabled__c = TRUE
            ORDER BY ExecutionOrder__c NULLS LAST, DeveloperName
        ];

        for (LoggerPlugin__mdt plugin : plugins) {
            // CMDT entity-definition relationship fields are weird, so skip some headaches by copying the Qualified API name
            plugin.SObjectType__c = plugin.SObjectType__r.QualifiedApiName;

            // Schema.getGlobalDescribe() is the worst, so don't use it
            SObjectType sobjectType = ((SObject) Type.forName(plugin.SObjectType__c).newInstance()).getSObjectType();

            List<LoggerPlugin__mdt> sobjectTypePlugins = new List<LoggerPlugin__mdt>();
            if (pluginsBySObjectType.containsKey(sobjectType) == true) {
                sobjectTypePlugins = pluginsBySObjectType.get(sobjectType);
            }
            sobjectTypePlugins.add(plugin);
            pluginsBySObjectType.put(sobjectType, sobjectTypePlugins);
        }

        if (System.Test.isRunningTest() == true) {
            // Tests shouldn't rely on the actual CMDT rules in the org
            // Clear the org's loaded records during tests, and mock via setMockConfiguration()
            pluginsBySObjectType.clear();
        }
    }

    @TestVisible
    private static void setMockPlugin(Schema.SObjectType sobjectType, LoggerPlugin__mdt plugin) {
        List<LoggerPlugin__mdt> plugins = pluginsBySObjectType.get(sobjectType);
        if (plugins == null) {
            plugins = new List<LoggerPlugin__mdt>();
        }
        plugins.add(plugin);
        pluginsBySObjectType.put(sobjectType, plugins);
    }

    /**
     * @description Default constructor
     */
    public LoggerSObjectHandler() {
        this.triggerOperationType = Trigger.operationType;
        this.triggerNew = Trigger.new;
        this.triggerNewMap = Trigger.newMap;
        this.triggerOld = Trigger.old;
        this.triggerOldMap = Trigger.oldMap;
        this.plugins = pluginsBySObjectType.get(this.getSObjectType());
    }

    /**
     * @description Returns the SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public abstract SObjectType getSObjectType();

    /**
     * @description Runs the handler class's logic
     */
    public void execute() {
        switch on this.triggerOperationType {
            when BEFORE_INSERT {
                this.executeBeforeInsert(this.triggerNew);
            }
            when BEFORE_UPDATE {
                this.executeBeforeUpdate(this.triggerNewMap, this.triggerOldMap);
            }
            when BEFORE_DELETE {
                this.executeBeforeDelete(this.triggerNewMap);
            }
            when AFTER_INSERT {
                // Platform Events don't have an ID field, thus Trigger.newMap doesn't work for LogEntryEvent__e
                // For custom objects, Map<Id, SObject> is more convenient since it provides both the keys & values
                // 2 AFTER_INSERT methods are used here in the framework, with the expectation that only 1 will be implemented per handler class
                this.executeAfterInsert(this.triggerNew);
                this.executeAfterInsert(this.triggerNewMap);
            }
            when AFTER_UPDATE {
                this.executeAfterUpdate(this.triggerNewMap, this.triggerOldMap);
            }
            when AFTER_DELETE {
                this.executeAfterDelete(this.triggerNewMap);
            }
            when AFTER_UNDELETE {
                this.executeAfterUndelete(this.triggerNewMap);
            }
        }

        this.executePlugins();
    }

    protected virtual void executeBeforeInsert(List<SObject> triggerNew) {
    }

    protected virtual void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
    }

    protected virtual void executeBeforeDelete(Map<Id, SObject> triggerNewMap) {
    }

    // executeAfterInsert(List<SObject triggerNew) is used for LogEntryEvent__e, which does not have an ID field
    protected virtual void executeAfterInsert(List<SObject> triggerNew) {
    }

    protected virtual void executeAfterInsert(Map<Id, SObject> triggerNewMap) {
    }

    protected virtual void executeAfterUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
    }

    protected virtual void executeAfterDelete(Map<Id, SObject> triggerNewMap) {
    }

    protected virtual void executeAfterUndelete(Map<Id, SObject> triggerNewMap) {
    }

    private void executePlugins() {
        if (this.plugins == null || this.plugins.isEmpty() == true) {
            return;
        }

        LoggerPlugin.PluginInput pluginInput = this.createPluginInput();
        for (LoggerPlugin__mdt pluginConfiguration : this.plugins) {
            switch on pluginConfiguration.PluginType__c {
                when 'Apex' {
                    this.executeApexPlugin(pluginConfiguration.PluginApiName__c, pluginInput);
                }
                when 'Flow' {
                    this.executeFlowPlugin(pluginConfiguration.PluginApiName__c, pluginInput);
                }
            }
        }
    }

    private void executeApexPlugin(String apexClassName, LoggerPlugin.PluginInput pluginInput) {
        Object untypedApexPlugin = Type.forName(apexClassName).newInstance();
        // Legacy approach - TODO, eliminate long term
        if (untypedApexPlugin instanceof LoggerSObjectHandlerPlugin) {
            LoggerSObjectHandlerPlugin legacyApexPlugin = (LoggerSObjectHandlerPlugin) Type.forName(apexClassName).newInstance();
            legacyApexPlugin.execute(this.triggerOperationType, this.triggerNew, this.triggerNewMap, this.triggerOld, this.triggerOldMap);
        } else {
            LoggerPlugin fancyApexPlugin = (LoggerPlugin) Type.forName(apexClassName).newInstance();
            fancyApexPlugin.execute(pluginInput);
        }
    }

    private void executeFlowPlugin(String flowApiName, LoggerPlugin.PluginInput pluginInput) {
        // TODO - switch using new plugin implementation LoggerPlugin
        Map<String, Object> flowInputs = new Map<String, Object>();

        // Legacy inputs - TODO, eliminate long term
        flowInputs.put('triggerOperationType', this.triggerOperationType?.name());
        flowInputs.put('triggerNew', this.triggerNew);
        flowInputs.put('triggerOld', this.triggerOld);

        // New input
        flowInputs.put('pluginInput', pluginInput);

        Flow.Interview flowPlugin = Flow.Interview.createInterview(flowApiName, flowInputs);
        flowPlugin.start();

        List<SObject> updatedTriggerNew = (List<SObject>) flowPlugin.getVariableValue('updatedTriggerNew');
        if (updatedTriggerNew != null && updatedTriggerNew.size() == this.triggerNew.size()) {
            this.triggerNew = updatedTriggerNew;
        }
    }

    private LoggerPlugin.PluginInput createPluginInput() {
        LoggerPlugin.PluginInput pluginInput = new LoggerPlugin.PluginInput();
        pluginInput.triggerOperationType = this.triggerOperationType;
        pluginInput.triggerOperationTypeName = this.triggerOperationType?.name();

        // PluginRecordInput for Apex Developers
        pluginInput.triggerNew = this.triggerNew;
        pluginInput.triggerNewMap = this.triggerNewMap;
        pluginInput.triggerOld = this.triggerOld;
        pluginInput.triggerOldMap = this.triggerOldMap;

        // PluginRecordInput for Flow Builders (and Apex Developers too, if they want to use them)
        pluginInput.triggerRecords = new List<LoggerPlugin.PluginRecordInput>();
        // TODO - handle triggerOperationTypes where triggerNew is null (e.g., AFTER_DELETE)
        for (SObject record : this.triggerNew) {
            LoggerPlugin.PluginRecordInput recordInput = new LoggerPlugin.PluginRecordInput();
            recordInput.triggerRecordNew = record;
            if (this.triggerOldMap != null && record.Id != null) {
                recordInput.triggerRecordOld = this.triggerOldMap.get(record.Id);
            }

            pluginInput.triggerRecords.add(recordInput);
        }
        return pluginInput;
    }
}
