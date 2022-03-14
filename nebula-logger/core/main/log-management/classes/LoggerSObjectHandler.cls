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
    private static final Map<Schema.SObjectType, List<LoggerSObjectHandler>> SOBJECT_TYPE_TO_EXECUTED_HANDLERS = new Map<Schema.SObjectType, List<LoggerSObjectHandler>>();
    private static final Map<Schema.SObjectType, Boolean> SOBJECT_TYPE_TO_HANDLER_CONTROL = new Map<Schema.SObjectType, Boolean>{
        Schema.Log__c.SObjectType => LoggerParameter.getBoolean('IsLogHandlerEnabled', true),
        Schema.LogEntry__c.SObjectType => LoggerParameter.getBoolean('IsLogEntryHandlerEnabled', true),
        Schema.LogEntryEvent__e.SObjectType => LoggerParameter.getBoolean('IsLogEntryEventHandlerEnabled', true),
        Schema.LogEntryTag__c.SObjectType => LoggerParameter.getBoolean('IsLogEntryTagHandlerEnabled', true),
        Schema.LoggerTag__c.SObjectType => LoggerParameter.getBoolean('IsLoggerTagHandlerEnabled', true)
    };
    private static final Map<SObjectType, Schema.SObjectField> SOBJECT_TYPE_TO_PLUGIN_CONTROL_FIELD = new Map<Schema.SObjectType, Schema.SObjectField>{
        Schema.Log__c.SObjectType => Schema.LoggerPlugin__mdt.IsLogEnabled__c,
        Schema.LogEntry__c.SObjectType => Schema.LoggerPlugin__mdt.IsLogEntryEnabled__c,
        Schema.LogEntryEvent__e.SObjectType => Schema.LoggerPlugin__mdt.IsLogEntryEventEnabled__c,
        Schema.LogEntryTag__c.SObjectType => Schema.LoggerPlugin__mdt.IsLogEntryTagEnabled__c,
        Schema.LoggerTag__c.SObjectType => Schema.LoggerPlugin__mdt.IsLoggerTagEnabled__c
    };
    private static final Map<Schema.SObjectType, List<LoggerPlugin__mdt>> SOBJECT_TYPE_TO_MOCK_PLUGIN_CONFIGURATIONS = new Map<Schema.SObjectType, List<LoggerPlugin__mdt>>();

    private SObjectHandlerInput input;
    private List<LoggerPlugin__mdt> pluginConfigurations;

    /**
     * @description Default constructor
     */
    public LoggerSObjectHandler() {
        this.createSObjectHandlerInput();
        this.queryPluginConfigurations();
    }

    /**
     * @description Returns the SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public abstract SObjectType getSObjectType();

    /**
     * @description Runs the handler class's logic, as well as any configured plugins
     */
    public void execute() {
        Boolean shouldExecute = SOBJECT_TYPE_TO_HANDLER_CONTROL.get(this.getSObjectType());
        if (shouldExecute == false) {
            return;
        }

        switch on this.input.triggerOperationType {
            when BEFORE_INSERT {
                this.executeBeforeInsert(this.input.triggerNew);
            }
            when BEFORE_UPDATE {
                this.executeBeforeUpdate(this.input.triggerNewMap, this.input.triggerOldMap);
            }
            when BEFORE_DELETE {
                this.executeBeforeDelete(this.input.triggerNewMap);
            }
            when AFTER_INSERT {
                // Platform Events don't have an ID field, thus Trigger.newMap doesn't work for LogEntryEvent__e
                // For custom objects, Map<Id, SObject> is more convenient since it provides both the keys & values
                // 2 AFTER_INSERT methods are used here in the framework, with the expectation that only 1 will be implemented per handler class
                this.executeAfterInsert(this.input.triggerNew);
                this.executeAfterInsert(this.input.triggerNewMap);
            }
            when AFTER_UPDATE {
                this.executeAfterUpdate(this.input.triggerNewMap, this.input.triggerOldMap);
            }
            when AFTER_DELETE {
                this.executeAfterDelete(this.input.triggerNewMap);
            }
            when AFTER_UNDELETE {
                this.executeAfterUndelete(this.input.triggerNewMap);
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

    private void createSObjectHandlerInput() {
        this.input = new SObjectHandlerInput();

        // Trigger variables for Apex Developers
        input.sobjectType = this.getSObjectType();
        input.triggerOperationType = Trigger.operationType;
        input.triggerNew = Trigger.new;
        input.triggerNewMap = Trigger.newMap;
        input.triggerOld = Trigger.old;
        input.triggerOldMap = Trigger.oldMap;

        // Additional variables for Flow Builders (and Apex Developers too, if they want to use them)
        input.sobjectTypeName = this.getSObjectType().getDescribe().getName();
        input.triggerOperationTypeName = Trigger.operationType?.name();
        input.triggerRecords = new List<SObjectHandlerRecordInput>();
        if (input.triggerNew != null) {
            for (SObject record : input.triggerNew) {
                SObjectHandlerRecordInput recordInput = new SObjectHandlerRecordInput();
                recordInput.triggerRecordNew = record;
                if (input.triggerOldMap != null && record.Id != null) {
                    recordInput.triggerRecordOld = input.triggerOldMap.get(record.Id);
                }

                input.triggerRecords.add(recordInput);
            }
        } else if (input.triggerOld != null) {
            for (SObject record : input.triggerOld) {
                SObjectHandlerRecordInput recordInput = new SObjectHandlerRecordInput();
                recordInput.triggerRecordOld = record;

                input.triggerRecords.add(recordInput);
            }
        }
    }

    private void executePlugins() {
        if (this.pluginConfigurations == null || this.pluginConfigurations.isEmpty() == true) {
            return;
        }

        for (LoggerPlugin__mdt pluginConfiguration : this.pluginConfigurations) {
            switch on pluginConfiguration.PluginType__c {
                when 'Apex' {
                    this.executeApexPlugin(pluginConfiguration);
                }
                when 'Flow' {
                    this.executeFlowPlugin(pluginConfiguration);
                }
            }
        }
    }

    private void executeApexPlugin(LoggerPlugin__mdt configuration) {
        LoggerSObjectHandlerPlugin apexPlugin = (LoggerSObjectHandlerPlugin) Type.forName(configuration.PluginApiName__c).newInstance();
        apexPlugin.execute(configuration, this.input);

        // TODO Legacy approach, remove in a future release
        apexPlugin.execute(this.input.triggerOperationType, this.input.triggerNew, this.input.triggerNewMap, this.input.triggerOld, this.input.triggerOldMap);
    }

    private void executeFlowPlugin(LoggerPlugin__mdt configuration) {
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('pluginConfiguration', configuration);
        flowInputs.put('pluginInput', this.input);

        // TODO Legacy approach, remove in a future release
        flowInputs.put('triggerOperationType', this.input.triggerOperationType?.name());
        flowInputs.put('triggerNew', this.input.triggerNew);
        flowInputs.put('triggerOld', this.input.triggerOld);

        Flow.Interview flowPlugin = Flow.Interview.createInterview(configuration.PluginApiName__c, flowInputs);
        flowPlugin.start();

        List<SObject> updatedTriggerNew = (List<SObject>) flowPlugin.getVariableValue('updatedTriggerNew');
        if (updatedTriggerNew != null && updatedTriggerNew.size() == this.input.triggerNew.size()) {
            this.input.triggerNew = updatedTriggerNew;
            if (this.input.triggerNewMap != null) {
                this.input.triggerNewMap = new Map<Id, SObject>(updatedTriggerNew);
            }
        }
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
     * @description Class used by the logging system to for trigger context details
     */
    public class SObjectHandlerInput {
        public Schema.SObjectType sobjectType;
        public TriggerOperation triggerOperationType;
        public List<SObject> triggerNew;
        public Map<Id, SObject> triggerNewMap;
        public List<SObject> triggerOld;
        public Map<Id, SObject> triggerOldMap;

        @InvocableVariable(label='SObject Type Name')
        public String sobjectTypeName;

        @InvocableVariable(label='Trigger Operation Name')
        public String triggerOperationTypeName;

        @InvocableVariable(label='Trigger Records')
        public List<SObjectHandlerRecordInput> triggerRecords;
    }

    /**
     * @description Class used by the logging system to provide trigger record details
     */
    public class SObjectHandlerRecordInput {
        @InvocableVariable(label='Trigger.new Record')
        public SObject triggerRecordNew;

        @InvocableVariable(label='Trigger.old Record')
        public SObject triggerRecordOld;
    }
}
