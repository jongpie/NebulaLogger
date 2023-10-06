//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Abstract class used by trigger handlers for shared logic
 */
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.EmptyStatementBlock, PMD.FieldDeclarationsShouldBeAtStart')
public without sharing abstract class LoggerSObjectHandler {
    private static final String FLOW_PLUGIN_CONFIGURATION_INPUT_NAME = 'pluginConfiguration';
    private static final String FLOW_PLUGIN_INPUT_NAME = 'pluginInput';
    private static final Map<Schema.SObjectType, List<LoggerSObjectHandler>> SOBJECT_TYPE_TO_EXECUTED_HANDLERS = new Map<Schema.SObjectType, List<LoggerSObjectHandler>>();
    private static final Map<Schema.SObjectType, LoggerSObjectHandler__mdt> SOBJECT_TYPE_TO_HANDLER_CONFIGURATIONS = queryHandlerConfigurations();

    private static Boolean isEnabled = true;

    // Instance variables for top-level class
    @TestVisible
    protected LoggerTriggerableContext input {
        get {
            if (input == null) {
                input = new LoggerTriggerableContext(this.getSObjectType(), this.triggerOperationType, this.triggerNew, this.triggerNewMap, this.triggerOldMap);
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
    @TestVisible
    private LoggerSObjectHandler__mdt handlerConfiguration;
    private List<LoggerPlugin__mdt> pluginConfigurations = new List<LoggerPlugin__mdt>();
    private List<LoggerPlugin.Triggerable> executedApexPlugins = new List<LoggerPlugin.Triggerable>();
    private List<Flow.Interview> executedFlowPlugins = new List<Flow.Interview>();

    /**
     * @description Returns an instance of `LoggerSObjectHandler` that has been built & configured for the specified `SObjectType`
     * @param  sobjectType The instance `SObjectType` to check for a configured instance of `LoggerSObjectHandler`
     * @return             The Apex class that extends `LoggerSObjectHandler` and has been configured for the specified `SObjectType`
     */
    public static LoggerSObjectHandler getHandler(Schema.SObjectType sobjectType) {
        return getHandler(sobjectType, null);
    }

    /**
     * @description Returns an instance of `LoggerSObjectHandler` that has been built & configured for the specified `SObjectType`
     * @param  sobjectType           The instance `SObjectType` to check for a configured instance of `LoggerSObjectHandler`
     * @param  defaultImplementation A default implementation of `LoggerSObjectHandler` that should be used, if a configuration cannot be found `LoggerSObjectHandler__mdt`
     * @return                       The Apex class that extends `LoggerSObjectHandler` and has been configured for the specified `SObjectType`
     */
    public static LoggerSObjectHandler getHandler(Schema.SObjectType sobjectType, LoggerSObjectHandler defaultImplementation) {
        String handlerApexClassName = getHandlerConfiguration(sobjectType)?.SObjectHandlerApexClass__c;
        // TODO need to handle namespace prefix for Apex classes
        return handlerApexClassName == null ? defaultImplementation : (LoggerSObjectHandler) System.Type.forName(handlerApexClassName)?.newInstance();
    }

    /**
     * @description Default constructor
     */
    public LoggerSObjectHandler() {
        this.triggerOperationType = Trigger.operationType;
        this.triggerNew = Trigger.new;
        this.triggerNewMap = Trigger.newMap;
        this.triggerOldMap = Trigger.oldMap;
        this.handlerConfiguration = SOBJECT_TYPE_TO_HANDLER_CONFIGURATIONS.get(this.getSObjectType());
        this.pluginConfigurations = LoggerPlugin.getFilteredPluginConfigurations(
            new List<Schema.SObjectField>{ Schema.LoggerPlugin__mdt.SObjectHandlerApexClass__c, Schema.LoggerPlugin__mdt.SObjectHandlerFlowName__c },
            Schema.LoggerPlugin__mdt.SObjectHandlerExecutionOrder__c
        );
    }

    /**
     * @description Returns the SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public abstract Schema.SObjectType getSObjectType();

    /**
     * @description  Provides the ability to override the instance `LoggerTriggerableContext` that is normally
     *               provided internally by `LoggerSObjectHandler`
     * @param  input The instance of `LoggerTriggerableContext` to use within the trigger handler class
     * @return       The same instance of `LoggerSObjectHandler`, useful for chaining methods
     */
    public LoggerSObjectHandler overrideTriggerableContext(LoggerTriggerableContext input) {
        this.input = input;
        return this;
    }

    /**
     * @description Runs the handler class's logic, as well as any configured plugins
     */
    public void execute() {
        if (System.Test.isRunningTest() && SOBJECT_TYPE_TO_EXECUTED_HANDLERS.containsKey(this.getSObjectType()) == false) {
            SOBJECT_TYPE_TO_EXECUTED_HANDLERS.put(this.getSObjectType(), new List<LoggerSObjectHandler>());
        }

        Boolean shouldExecute = isEnabled && (this.handlerConfiguration == null || this.handlerConfiguration.IsEnabled__c);
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

        if (System.Test.isRunningTest()) {
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

    private void executePlugins() {
        if (this.pluginConfigurations == null || this.pluginConfigurations.isEmpty()) {
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

    private void executeApexPlugin(LoggerPlugin__mdt configuration) {
        LoggerPlugin.Triggerable apexPlugin = LoggerPlugin.newTriggerableInstance(configuration.SObjectHandlerApexClass__c);
        apexPlugin?.execute(configuration, this.input);

        if (System.Test.isRunningTest() && apexPlugin != null) {
            this.executedApexPlugins.add(apexPlugin);
        }
    }

    private void executeFlowPlugin(LoggerPlugin__mdt configuration) {
        try {
            Map<String, Object> flowInputs = new Map<String, Object>();
            flowInputs.put(FLOW_PLUGIN_CONFIGURATION_INPUT_NAME, configuration);
            flowInputs.put(FLOW_PLUGIN_INPUT_NAME, this.input);

            Flow.Interview flowPlugin = Flow.Interview.createInterview(configuration.SObjectHandlerFlowName__c, flowInputs);
            flowPlugin.start();

            List<SObject> updatedTriggerNew = (List<SObject>) flowPlugin.getVariableValue('updatedTriggerNew');
            if (updatedTriggerNew != null && updatedTriggerNew.size() == this.input.triggerNew.size()) {
                this.input.triggerNew.clear();
                this.input.triggerNew.addAll(updatedTriggerNew);
                if (this.input.triggerNewMap != null) {
                    this.input.triggerNewMap.clear();
                    this.input.triggerNewMap.putAll(new Map<Id, SObject>(updatedTriggerNew));
                }
            }
            if (System.Test.isRunningTest() && flowPlugin != null) {
                this.executedFlowPlugins.add(flowPlugin);
            }
        } catch (TypeException ex) {
            if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
                Logger.warn('Unknown Flow ' + configuration.SObjectHandlerFlowName__c + ', skipping plugin execution', configuration, ex);
            }
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

    @TestVisible
    private List<Flow.Interview> getExecutedFlowPlugins() {
        return this.executedFlowPlugins;
    }

    // Static test helper methods, used for integration tests
    @TestVisible
    private static Map<Schema.SObjectType, List<LoggerSObjectHandler>> getExecutedHandlers() {
        return SOBJECT_TYPE_TO_EXECUTED_HANDLERS;
    }

    private static Map<Schema.SObjectType, LoggerSObjectHandler__mdt> queryHandlerConfigurations() {
        Map<Schema.SObjectType, LoggerSObjectHandler__mdt> sobjectTypeToHandlerConfiguration = new Map<Schema.SObjectType, LoggerSObjectHandler__mdt>();
        for (LoggerSObjectHandler__mdt handlerConfiguration : LoggerEngineDataSelector.getInstance().getCachedLoggerSObjectHandlers()) {
            handlerConfiguration.SObjectType__c = handlerConfiguration.SObjectType__r.QualifiedApiName;
            Schema.SObjectType sobjectType = prepHandlerType(handlerConfiguration);
            sobjectTypeToHandlerConfiguration.put(sobjectType, handlerConfiguration);
        }

        if (System.Test.isRunningTest()) {
            sobjectTypeToHandlerConfiguration.clear();
        }

        return sobjectTypeToHandlerConfiguration;
    }

    private static Schema.SObjectType prepHandlerType(LoggerSObjectHandler__mdt handlerConfiguration) {
        if (String.isNotBlank(handlerConfiguration.SObjectTypeOverride__c)) {
            handlerConfiguration.SObjectType__c = handlerConfiguration.SObjectTypeOverride__c;
        }

        return ((SObject) System.Type.forName(handlerConfiguration.SObjectType__c).newInstance()).getSObjectType();
    }

    @TestVisible
    private static LoggerSObjectHandler__mdt getHandlerConfiguration(Schema.SObjectType sobjectType) {
        return SOBJECT_TYPE_TO_HANDLER_CONFIGURATIONS.get(sobjectType);
    }

    @TestVisible
    private static void setMock(LoggerSObjectHandler__mdt handlerConfiguration) {
        Schema.SObjectType sobjectType = prepHandlerType(handlerConfiguration);
        SOBJECT_TYPE_TO_HANDLER_CONFIGURATIONS.put(sobjectType, handlerConfiguration);
    }

    @TestVisible
    private static void shouldExecute(Boolean shouldExecute) {
        // Only used for testing purposes so tests can disable triggers to speed up
        // DML statements that don't rely on trigger logic to run
        isEnabled = shouldExecute;
    }
}
