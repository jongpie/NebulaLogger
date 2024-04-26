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
    @TestVisible
    private static final Map<Schema.SObjectType, LoggerSObjectHandler__mdt> SOBJECT_TYPE_TO_HANDLER_CONFIGURATION = queryHandlerConfigurations();
    @TestVisible
    private static final List<LoggerPlugin__mdt> PLUGIN_CONFIGURATIONS = queryPluginConfigurations();

    private static final String FLOW_PLUGIN_CONFIGURATION_INPUT_NAME = 'pluginConfiguration';
    private static final String FLOW_PLUGIN_INPUT_NAME = 'pluginInput';

    public static void execute() {
        execute(new LoggerTriggerableContext());
    }

    public static void execute(LoggerTriggerableContext triggerableContext) {
        if (triggerableContext == null) {
            return;
        }

        LoggerSObjectHandler__mdt handlerConfiguration = SOBJECT_TYPE_TO_HANDLER_CONFIGURATION.get(triggerableContext.sobjectType);
        String handlerApexClassName = handlerConfiguration?.SObjectHandlerApexClass__c;
        // TODO need to handle namespace prefix for Apex classes
        if (String.isNotBlank(handlerApexClassName)) {
            LoggerSObjectHandler handler = (LoggerSObjectHandler) System.Type.forName(handlerApexClassName)?.newInstance();
            handler?.execute(handlerConfiguration, PLUGIN_CONFIGURATIONS, triggerableContext);
        }
    }

    public void execute(
        LoggerSObjectHandler__mdt handlerConfiguration,
        List<LoggerPlugin__mdt> pluginConfigurations,
        LoggerTriggerableContext triggerableContext
    ) {
        if (handlerConfiguration?.IsEnabled__c != true) {
            return;
        }

        switch on triggerableContext.triggerOperationType {
            when BEFORE_INSERT {
                this.executeBeforeInsert(triggerableContext.triggerNew);
            }
            when BEFORE_UPDATE {
                this.executeBeforeUpdate(triggerableContext.triggerNewMap, triggerableContext.triggerOldMap);
            }
            when BEFORE_DELETE {
                this.executeBeforeDelete(triggerableContext.triggerNewMap);
            }
            when AFTER_INSERT {
                // Platform Events don't have an ID field, thus Trigger.newMap doesn't work for LogEntryEvent__e
                // For custom objects, Map<Id, SObject> is more convenient since it provides both the keys & values
                // 2 AFTER_INSERT methods are used here in the framework, with the expectation that only 1 will be implemented per handler class
                this.executeAfterInsert(triggerableContext.triggerNew);
                this.executeAfterInsert(triggerableContext.triggerNewMap);
            }
            when AFTER_UPDATE {
                this.executeAfterUpdate(triggerableContext.triggerNewMap, triggerableContext.triggerOldMap);
            }
            when AFTER_DELETE {
                this.executeAfterDelete(triggerableContext.triggerNewMap);
            }
            when AFTER_UNDELETE {
                this.executeAfterUndelete(triggerableContext.triggerNewMap);
            }
        }

        this.executePlugins(pluginConfigurations, triggerableContext);
    }

    /**
     * @description Returns the SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public abstract Schema.SObjectType getSObjectType();

    protected virtual void executeBeforeInsert(List<SObject> triggerNew) {
    }

    protected virtual void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
    }

    protected virtual void executeBeforeDelete(Map<Id, SObject> triggerNewMap) {
    }

    // This overload can be used for platform event objects, which do not have an ID field
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

    private void executePlugins(List<LoggerPlugin__mdt> pluginConfigurations, LoggerTriggerableContext triggerableContext) {
        if (pluginConfigurations == null || pluginConfigurations.isEmpty()) {
            return;
        }

        for (LoggerPlugin__mdt pluginConfiguration : pluginConfigurations) {
            if (pluginConfiguration.IsEnabled__c == false) {
                return;
            }

            this.executeApexPlugin(pluginConfiguration, triggerableContext);
            this.executeFlowPlugin(pluginConfiguration, triggerableContext);
        }
    }

    private void executeApexPlugin(LoggerPlugin__mdt pluginConfiguration, LoggerTriggerableContext triggerableContext) {
        if (String.isBlank(pluginConfiguration.SObjectHandlerApexClass__c)) {
            return;
        }

        LoggerPlugin.Triggerable apexPlugin = LoggerPlugin.newTriggerableInstance(pluginConfiguration.SObjectHandlerApexClass__c);
        apexPlugin?.execute(pluginConfiguration, triggerableContext);
    }

    private void executeFlowPlugin(LoggerPlugin__mdt pluginConfiguration, LoggerTriggerableContext triggerableContext) {
        if (String.isBlank(pluginConfiguration.SObjectHandlerFlowName__c)) {
            return;
        }

        try {
            Map<String, Object> flowInputs = new Map<String, Object>();
            flowInputs.put(FLOW_PLUGIN_CONFIGURATION_INPUT_NAME, pluginConfiguration);
            flowInputs.put(FLOW_PLUGIN_INPUT_NAME, triggerableContext);

            Flow.Interview flowPlugin = Flow.Interview.createInterview(pluginConfiguration.SObjectHandlerFlowName__c, flowInputs);
            flowPlugin.start();

            List<SObject> updatedTriggerNew = (List<SObject>) flowPlugin.getVariableValue('updatedTriggerNew');
            if (updatedTriggerNew != null && updatedTriggerNew.size() == triggerableContext.triggerNew.size()) {
                triggerableContext.triggerNew.clear();
                triggerableContext.triggerNew.addAll(updatedTriggerNew);
                if (triggerableContext.triggerNewMap != null) {
                    triggerableContext.triggerNewMap.clear();
                    triggerableContext.triggerNewMap.putAll(new Map<Id, SObject>(updatedTriggerNew));
                }
            }
        } catch (System.TypeException ex) {
            if (LoggerParameter.ENABLE_SYSTEM_MESSAGES) {
                Logger.warn('Unknown Flow ' + pluginConfiguration.SObjectHandlerFlowName__c + ', skipping plugin execution', pluginConfiguration, ex);
            }
        }
    }

    // Static helper methods
    @TestVisible
    private static void setMock(LoggerSObjectHandler__mdt handlerConfiguration) {
        Schema.SObjectType sobjectType = getHandlerSObjectType(handlerConfiguration);
        SOBJECT_TYPE_TO_HANDLER_CONFIGURATION.put(sobjectType, handlerConfiguration);
    }

    private static Map<Schema.SObjectType, LoggerSObjectHandler__mdt> queryHandlerConfigurations() {
        Map<Schema.SObjectType, LoggerSObjectHandler__mdt> sobjectTypeToHandlerConfiguration = new Map<Schema.SObjectType, LoggerSObjectHandler__mdt>();
        for (LoggerSObjectHandler__mdt handlerConfiguration : LoggerEngineDataSelector.getInstance().getCachedLoggerSObjectHandlers()) {
            handlerConfiguration.SObjectType__c = handlerConfiguration.SObjectType__r.QualifiedApiName;
            Schema.SObjectType sobjectType = getHandlerSObjectType(handlerConfiguration);
            sobjectTypeToHandlerConfiguration.put(sobjectType, handlerConfiguration);
        }

        return sobjectTypeToHandlerConfiguration;
    }

    private static List<LoggerPlugin__mdt> queryPluginConfigurations() {
        return LoggerPlugin.getFilteredPluginConfigurations(
            new List<Schema.SObjectField>{ Schema.LoggerPlugin__mdt.SObjectHandlerApexClass__c, Schema.LoggerPlugin__mdt.SObjectHandlerFlowName__c },
            Schema.LoggerPlugin__mdt.SObjectHandlerExecutionOrder__c
        );
    }

    private static Schema.SObjectType getHandlerSObjectType(LoggerSObjectHandler__mdt handlerConfiguration) {
        // TODO consider replacing 2 existing fields SObjectType__c & SObjectTypeOverride__c
        // with a single, new text field (SObjectTypeName__c?) and deprecate the existing fields
        // TODO this would cause complications with the managed package names requiring a namespace prefix
        // so maybe sticking with the 2 current fields is better
        if (String.isNotBlank(handlerConfiguration.SObjectTypeOverride__c)) {
            handlerConfiguration.SObjectType__c = handlerConfiguration.SObjectTypeOverride__c;
        }

        return ((SObject) System.Type.forName(handlerConfiguration.SObjectType__c).newInstance()).getSObjectType();
    }
}
