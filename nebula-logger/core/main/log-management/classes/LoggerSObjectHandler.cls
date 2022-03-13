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
    @TestVisible
    private static final Map<Schema.SObjectType, List<LoggerSObjectHandler>> SOBJECT_TYPE_TO_EXECUTED_HANDLERS = new Map<Schema.SObjectType, List<LoggerSObjectHandler>>();
    @TestVisible
    private static final Map<Schema.SObjectType, Boolean> SOBJECT_TYPE_TO_HANDLER_CONTROL = new Map<Schema.SObjectType, Boolean>{
        Schema.Log__c.SObjectType => LoggerParameter.getBoolean('EnableLogHandler', true),
        Schema.LogEntry__c.SObjectType => LoggerParameter.getBoolean('EnableLogEntryHandler', true),
        Schema.LogEntryEvent__e.SObjectType => LoggerParameter.getBoolean('EnableLogEntryEventHandler', true),
        Schema.LogEntryTag__c.SObjectType => LoggerParameter.getBoolean('EnableLogEntryTagHandler', true),
        Schema.LoggerTag__c.SObjectType => LoggerParameter.getBoolean('EnableLoggerTagHandler', true)
    };
    private static final Map<SObjectType, Schema.SObjectField> SOBJECT_TYPE_TO_PLUGIN_CONTROL_FIELD = new Map<Schema.SObjectType, Schema.SObjectField>{
        Schema.Log__c.SObjectType => Schema.LoggerPlugin__mdt.IsLogEnabled__c,
        Schema.LogEntry__c.SObjectType => Schema.LoggerPlugin__mdt.IsLogEntryEnabled__c,
        Schema.LogEntryEvent__e.SObjectType => Schema.LoggerPlugin__mdt.IsLogEntryEventEnabled__c,
        Schema.LogEntryTag__c.SObjectType => Schema.LoggerPlugin__mdt.IsLogEntryTagEnabled__c,
        Schema.LoggerTag__c.SObjectType => Schema.LoggerPlugin__mdt.IsLoggerTagEnabled__c
    };
    private static final Map<Schema.SObjectType, List<LoggerPlugin__mdt>> SOBJECT_TYPE_TO_MOCK_PLUGIN_CONFIGURATIONS = new Map<Schema.SObjectType, List<LoggerPlugin__mdt>>();

    private List<LoggerPlugin__mdt> pluginConfigurations;
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

    @TestVisible
    private static Map<Schema.SObjectType, List<LoggerSObjectHandler>> getExecutedHandlers() {
        return SOBJECT_TYPE_TO_EXECUTED_HANDLERS;
    }

    @TestVisible
    private static void setMockPlugin(Schema.SObjectType sobjectType, LoggerPlugin__mdt plugin) {
        if (SOBJECT_TYPE_TO_MOCK_PLUGIN_CONFIGURATIONS.containsKey(sobjectType) == false) {
            SOBJECT_TYPE_TO_MOCK_PLUGIN_CONFIGURATIONS.put(sobjectType, new List<LoggerPlugin__mdt>());
        }
        SOBJECT_TYPE_TO_MOCK_PLUGIN_CONFIGURATIONS.get(sobjectType).add(plugin);
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

        this.queryPluginConfigurations();
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
        Boolean shouldExecute = SOBJECT_TYPE_TO_HANDLER_CONTROL.get(this.getSObjectType());
        if (shouldExecute == false) {
            return;
        }

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

        if (Test.isRunningTest() == true) {
            if (SOBJECT_TYPE_TO_EXECUTED_HANDLERS.containsKey(this.getSObjectType()) == false) {
                SOBJECT_TYPE_TO_EXECUTED_HANDLERS.put(this.getSObjectType(), new List<LoggerSObjectHandler>());
            }
            SOBJECT_TYPE_TO_EXECUTED_HANDLERS.get(this.getSObjectType()).add(this);
        }
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

    private void queryPluginConfigurations() {
        // Dynamically query the LoggerPlugin__mdt CMDT object so the records are filtered by the current SObjectType, and so the records are sorted correctly
        List<String> fieldsToQuery = new List<String>{
            Schema.LoggerPlugin__mdt.PluginApiName__c.getDescribe().getName(),
            Schema.LoggerPlugin__mdt.PluginType__c.getDescribe().getName()
        };
        List<String> filterConditions = new List<String>{
            Schema.LoggerPlugin__mdt.IsEnabled__c.getDescribe().getName() + ' = TRUE',
            SOBJECT_TYPE_TO_PLUGIN_CONTROL_FIELD.get(this.getSObjectType()).getDescribe().getName() + ' = TRUE'
        };
        List<String> orderByConditions = new List<String>{
            Schema.LoggerPlugin__mdt.ExecutionOrder__c.getDescribe().getName() + ' NULLS LAST',
            Schema.LoggerPlugin__mdt.DeveloperName.getDescribe().getName()
        };

        String queryTemplate = 'SELECT {0} FROM {1} WHERE {2} ORDER BY {3}';
        List<Object> queryInputs = new List<Object>{
            String.join(fieldsToQuery, ', '),
            Schema.LoggerPlugin__mdt.SObjectType.getDescribe().getName(),
            String.join(filterConditions, ' AND '),
            String.join(orderByConditions, ', ')
        };
        String query = String.format(queryTemplate, queryInputs);
        this.pluginConfigurations = (List<LoggerPlugin__mdt>) Database.query(query);

        if (System.Test.isRunningTest() == true) {
            // Tests shouldn't rely on the actual CMDT rules in the org
            // Clear the org's loaded records during tests, and mock via setMockConfiguration()
            this.pluginConfigurations.clear();

            List<LoggerPlugin__mdt> mockPluginConfigurations = SOBJECT_TYPE_TO_MOCK_PLUGIN_CONFIGURATIONS.get(this.getSObjectType());
            if (mockPluginConfigurations != null && mockPluginConfigurations.isEmpty() == false) {
                this.pluginConfigurations.addAll(mockPluginConfigurations);
            }
        }
    }

    private LoggerSObjectHandlerPlugin.PluginInput createPluginInput() {
        LoggerSObjectHandlerPlugin.PluginInput pluginInput = new LoggerSObjectHandlerPlugin.PluginInput();

        // Trigger variables for Apex Developers
        pluginInput.sobjectType = this.getSObjectType();
        pluginInput.triggerOperationType = this.triggerOperationType;
        pluginInput.triggerNew = this.triggerNew;
        pluginInput.triggerNewMap = this.triggerNewMap;
        pluginInput.triggerOld = this.triggerOld;
        pluginInput.triggerOldMap = this.triggerOldMap;

        // PluginRecordInput for Flow Builders (and Apex Developers too, if they want to use them)
        pluginInput.sobjectTypeName = this.getSObjectType().getDescribe().getName();
        pluginInput.triggerOperationTypeName = this.triggerOperationType?.name();
        pluginInput.triggerRecords = new List<LoggerSObjectHandlerPlugin.PluginRecordInput>();
        if (this.triggerNew != null) {
            for (SObject record : this.triggerNew) {
                LoggerSObjectHandlerPlugin.PluginRecordInput recordInput = new LoggerSObjectHandlerPlugin.PluginRecordInput();
                recordInput.triggerRecordNew = record;
                if (this.triggerOldMap != null && record.Id != null) {
                    recordInput.triggerRecordOld = this.triggerOldMap.get(record.Id);
                }

                pluginInput.triggerRecords.add(recordInput);
            }
        } else if (this.triggerOld != null) {
            for (SObject record : this.triggerOld) {
                LoggerSObjectHandlerPlugin.PluginRecordInput recordInput = new LoggerSObjectHandlerPlugin.PluginRecordInput();
                recordInput.triggerRecordOld = record;

                pluginInput.triggerRecords.add(recordInput);
            }
        }

        return pluginInput;
    }

    private void executePlugins() {
        if (this.pluginConfigurations == null || this.pluginConfigurations.isEmpty() == true) {
            return;
        }

        LoggerSObjectHandlerPlugin.PluginInput pluginInput = this.createPluginInput();
        for (LoggerPlugin__mdt pluginConfiguration : this.pluginConfigurations) {
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

    private void executeApexPlugin(String apexClassName, LoggerSObjectHandlerPlugin.PluginInput pluginInput) {
        LoggerSObjectHandlerPlugin apexPlugin = (LoggerSObjectHandlerPlugin) Type.forName(apexClassName).newInstance();
        // TODO Legacy approach - eliminate long term
        apexPlugin.execute(this.triggerOperationType, this.triggerNew, this.triggerNewMap, this.triggerOld, this.triggerOldMap);
        // TODO Potentially new approach - still a WIP
        apexPlugin.execute(pluginInput);
    }

    private void executeFlowPlugin(String flowApiName, LoggerSObjectHandlerPlugin.PluginInput pluginInput) {
        Map<String, Object> flowInputs = new Map<String, Object>();

        // TODO Legacy inputs - eliminate long term
        flowInputs.put('triggerOperationType', this.triggerOperationType?.name());
        flowInputs.put('triggerNew', this.triggerNew);
        flowInputs.put('triggerOld', this.triggerOld);

        // TODO New input - still a WIP
        flowInputs.put('pluginInput', pluginInput);

        Flow.Interview flowPlugin = Flow.Interview.createInterview(flowApiName, flowInputs);
        flowPlugin.start();

        List<SObject> updatedTriggerNew = (List<SObject>) flowPlugin.getVariableValue('updatedTriggerNew');
        if (updatedTriggerNew != null && updatedTriggerNew.size() == this.triggerNew.size()) {
            this.triggerNew = updatedTriggerNew;
        }
        // FIXME Possibly need to capture output parameters from Flow?
    }
}
