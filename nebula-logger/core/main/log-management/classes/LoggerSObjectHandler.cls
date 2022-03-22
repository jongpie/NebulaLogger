//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Abstract class used by trigger handlers for shared logic
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.CyclomaticComplexity, PMD.EmptyStatementBlock, PMD.FieldDeclarationsShouldBeAtStart')
public without sharing abstract class LoggerSObjectHandler {
    // private static final List<String> PLUGIN_TYPES = new List<String>{ 'SObject Handler - Apex', 'SObject Handler - Flow' };
    private static final Map<Schema.SObjectType, List<LoggerSObjectHandler>> SOBJECT_TYPE_TO_EXECUTED_HANDLERS = new Map<Schema.SObjectType, List<LoggerSObjectHandler>>();
    private static final Map<String, LoggerPlugin__mdt> MOCK_PLUGIN_CONFIGURATIONS = new Map<String, LoggerPlugin__mdt>();

    /**
     * @description Class used by the logging system to for trigger context details
     */
    public class SObjectHandlerInput {
        public Schema.SObjectType sobjectType;
        public TriggerOperation triggerOperationType;
        public List<SObject> triggerNew;
        public Map<Id, SObject> triggerNewMap;
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

    // Instance variables for top-level class
    protected SObjectHandlerInput input {
        get {
            if (input == null) {
                input = this.createSObjectHandlerInput();
            }
            return input;
        }
        set;
    }

    @TestVisible
    private TriggerOperation triggerOperationType;
    @TestVisible
    private List<SObject> triggerNew;
    @TestVisible
    private Map<Id, SObject> triggerNewMap;
    @TestVisible
    private Map<Id, SObject> triggerOldMap;
    private List<LoggerPlugin__mdt> pluginConfigurations = new List<LoggerPlugin__mdt>();
    private List<LoggerPlugin.Triggerable> executedApexPlugins = new List<LoggerPlugin.Triggerable>();

    /**
     * @description Default constructor
     */
    public LoggerSObjectHandler() {
        this.triggerOperationType = Trigger.operationType;
        this.triggerNew = Trigger.new;
        this.triggerNewMap = Trigger.newMap;
        this.triggerOldMap = Trigger.oldMap;
        this.pluginConfigurations = LoggerPlugin.getSObjectHandlerPluginConfigurations();
        if (Test.isRunningTest() == true) {
            this.pluginConfigurations.clear();
            this.pluginConfigurations = MOCK_PLUGIN_CONFIGURATIONS.values();
        }
    }

    /**
     * @description Returns the SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public abstract Schema.SObjectType getSObjectType();

    /**
     * @description Returns the string value of the `LoggerParameter__mdt` record that controls if the handler is enabled.
     *          The `LoggerSObjectHandler` class uses this method to retrieve the corresponding `LoggerParameter__mdt` to
     *          determine if the class should execute.
     * @return   The `DeveloperName` value of the `LoggerParameter__mdt` that controls if the handler is enabled
     */
    public abstract String getHandlerControlParameterName();

    /**
     * @description Runs the handler class's logic, as well as any configured plugins
     */
    public void execute() {
        Boolean shouldExecute = LoggerParameter.getBoolean(this.getHandlerControlParameterName(), true);
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

    private SObjectHandlerInput createSObjectHandlerInput() {
        SObjectHandlerInput input = new SObjectHandlerInput();

        // Trigger variables for Apex Developers
        input.sobjectType = this.getSObjectType();
        input.triggerOperationType = this.triggerOperationType;
        input.triggerNew = this.triggerNew;
        input.triggerNewMap = this.triggerNewMap;
        input.triggerOldMap = this.triggerOldMap;

        // Additional invocable variables for Flow Builders (and Apex Developers too, if they want to use them)
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
        } else if (input.triggerOldMap != null) {
            for (SObject record : input.triggerOldMap.values()) {
                SObjectHandlerRecordInput recordInput = new SObjectHandlerRecordInput();
                recordInput.triggerRecordOld = record;

                input.triggerRecords.add(recordInput);
            }
        }

        return input;
    }

    private void executePlugins() {
        if (this.pluginConfigurations == null || this.pluginConfigurations.isEmpty() == true) {
            return;
        }

        for (LoggerPlugin__mdt pluginConfiguration : this.pluginConfigurations) {
            if (String.isNotBlank(pluginConfiguration.SObjectHandlerApexClass__c)) {
                this.executeApexPlugin(pluginConfiguration);
            }
            if (String.isNotBlank(pluginConfiguration.SObjectHandlerFlowName__c)) {
                this.executeFlowPlugin(pluginConfiguration);
            }
        }
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private void executeApexPlugin(LoggerPlugin__mdt configuration) {
        LoggerPlugin.Triggerable apexPlugin = LoggerPlugin.newTriggerableInstance(configuration);
        apexPlugin?.execute(configuration, this.input);

        if (Test.isRunningTest() == true && apexPlugin != null) {
            this.executedApexPlugins.add(apexPlugin);
        }
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private void executeFlowPlugin(LoggerPlugin__mdt configuration) {
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('pluginConfiguration', configuration);
        flowInputs.put('pluginInput', this.input);

        // TODO Legacy approach, remove in a future release
        flowInputs.put('triggerOperationType', this.input.triggerOperationType?.name());
        flowInputs.put('triggerNew', this.input.triggerNew);
        flowInputs.put('triggerOld', this.input.triggerOldMap?.values());

        try {
            Flow.Interview flowPlugin = Flow.Interview.createInterview(configuration.SObjectHandlerFlowName__c, flowInputs);
            flowPlugin.start();

            List<SObject> updatedTriggerNew = (List<SObject>) flowPlugin.getVariableValue('updatedTriggerNew');
            if (updatedTriggerNew != null && updatedTriggerNew.size() == this.input.triggerNew.size()) {
                this.input.triggerNew = updatedTriggerNew;
                if (this.input.triggerNewMap != null) {
                    this.input.triggerNewMap = new Map<Id, SObject>(updatedTriggerNew);
                }
            }
        } catch (TypeException ex) {
            System.debug(LoggingLevel.INFO, 'Unknown Flow ' + configuration.SObjectHandlerFlowName__c + ', skipping plugin execution');
        }
    }

    // Instance test helper methods, used for unit tests
    @TestVisible
    private List<LoggerPlugin__mdt> getPluginConfigurations() {
        return this.pluginConfigurations;
    }

    @TestVisible
    private List<LoggerPlugin.Triggerable> getExecutedApexPlugins() {
        return this.executedApexPlugins;
    }

    // Static test helper methods, used for integration tests
    @TestVisible
    private static Map<Schema.SObjectType, List<LoggerSObjectHandler>> getExecutedHandlers() {
        return SOBJECT_TYPE_TO_EXECUTED_HANDLERS;
    }

    @TestVisible
    private static void setMockPlugin(LoggerPlugin__mdt plugin) {
        MOCK_PLUGIN_CONFIGURATIONS.put(plugin.DeveloperName, plugin);
    }
}
