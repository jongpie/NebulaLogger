//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Abstract class used by trigger handlers for shared logic
 */
 public abstract class LoggerSObjectHandler {
    @testVisible
    private static Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt> configurationsBySObjectType = loadConfigurations();

    private static Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt> loadConfigurations() {
        Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt> configsBySObjectType = new Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt>();
        for (LoggerSObjectHandlerConfiguration__mdt config : LoggerSObjectHandlerConfiguration__mdt.getAll().values()) {
            // Schema.getGlobalDescribe() is the worst, so don't use it
            SObjectType sobjectType = ((SObject) Type.forName(config.SObjectType__r.QualifiedApiName + '__c').newInstance()).getSObjectType();

            configsBySObjectType.put(sobjectType, config);
        }
        return configsBySObjectType;
    }

    protected LoggerSObjectHandlerConfiguration__mdt configuration;

    public LoggerSObjectHandler() {
        this.configuration = getConfiguration(this.getSObjectType());
    }

    /**
     * @description Returns the SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public abstract SObjectType getSObjectType();

    protected void executePostProcessors(List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById) {
        if (loggerRecords == null) {
            return;
        }

        this.executePostProcessorApexClass(this.configuration?.PostProcessorApexClassName__c, loggerRecords, oldLoggerRecordsById);
        this.executePostProcessorFlow(this.configuration?.PostProcessorFlowApiName__c, loggerRecords, oldLoggerRecordsById);
    }

    private LoggerSObjectHandlerConfiguration__mdt getConfiguration(SObjectType sobjectType) {
        LoggerSObjectHandlerConfiguration__mdt configuration = configurationsBySObjectType.get(sobjectType);

        if (configuration == null || Test.isRunningTest()) {
            configuration =  new LoggerSObjectHandlerConfiguration__mdt();

            // Setting entity definition fields on CMDT is not properly supported, so here's some goofy workarounds for handling it
            // TODO cache entity definition query for Log__c, LogEntry__c and LogEntryEvent__e
            String entityDefinitionRelationshipName = Schema.LoggerSObjectHandlerConfiguration__mdt.SObjectType__c.getDescribe().getName().replace('__c', '__r');
            EntityDefinition sobjectEntityDefinition = [SELECT QualifiedApiName, DeveloperName FROM EntityDefinition WHERE QualifiedApiName = :sobjectType.getDescribe().getName()];
            Map<String, Object> configurationUntyped = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(configuration));
            configurationUntyped.put(entityDefinitionRelationshipName, sobjectEntityDefinition);

            configuration = (LoggerSObjectHandlerConfiguration__mdt) JSON.deserialize(JSON.serialize(configurationUntyped), LoggerSObjectHandlerConfiguration__mdt.class);
            configuration.IsEnabled__c = true;
        }

        return configuration;
    }

    private void executePostProcessorApexClass(String apexClassName, List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById) {
        if (String.isBlank(apexClassName) || Type.forName(apexClassName) == null) {
            return;
        }

        LoggerSObjectPostProcessor recordPostProcessor = (LoggerSObjectPostProcessor) Type.forName(apexClassName).newInstance();
        recordPostProcessor.execute(Trigger.operationType, loggerRecords, oldLoggerRecordsById);
    }

    private void executePostProcessorFlow(String flowApiName, List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById) {
        if (String.isBlank(flowApiName)) {
            return;
        }

        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('triggerOperationType', Trigger.operationType);
        flowInputs.put('records', loggerRecords);
        flowInputs.put('oldRecords', oldLoggerRecordsById?.values());

        Flow.Interview postProcessorFlow = Flow.Interview.createInterview(flowApiName, flowInputs);
        postProcessorFlow.start();
    }
}
