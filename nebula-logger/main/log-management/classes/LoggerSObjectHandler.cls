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
        DescribeSObjectResult configDescribe = Schema.LoggerSObjectHandlerConfiguration__mdt.SObjectType.getDescribe();

        // When using CMDT's getAll(), it does not return relationship fields for EntityDefinition fields...
        // ... so instead query the LoggerSObjectHandlerConfiguration__mdt CMDT object
        List<LoggerSObjectHandlerConfiguration__mdt> configurations = [
            SELECT Id, IsEnabled__c, PostProcessorApexClassName__c, PostProcessorFlowApiName__c, SObjectType__r.QualifiedApiName
            FROM LoggerSObjectHandlerConfiguration__mdt
        ];

        Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt> configsBySObjectType = new Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt>();
        for (LoggerSObjectHandlerConfiguration__mdt config : configurations) {
            // CMDT entity-definition relationship fields are weird, so skip some headaches by copying the Qualified API name
            config.SObjectType__c = config.SObjectType__r.QualifiedApiName;

            // Schema.getGlobalDescribe() is the worst, so don't use it
            SObjectType sobjectType = ((SObject) Type.forName(config.SObjectType__c).newInstance()).getSObjectType();

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

        if (configuration == null) {
            configuration = new LoggerSObjectHandlerConfiguration__mdt(IsEnabled__c = true, SObjectType__c = sobjectType.getDescribe().getName());

            configurationsBySObjectType.put(sobjectType, configuration);
        }

        return configuration;
    }

    private void executePostProcessorApexClass(String apexClassName, List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById) {
        if (String.isBlank(apexClassName) || Type.forName(apexClassName) == null) {
            return;
        }

        LoggerSObjectPostProcessor apexPostProcessor = (LoggerSObjectPostProcessor) Type.forName(apexClassName).newInstance();
        apexPostProcessor.execute(Trigger.operationType, loggerRecords, oldLoggerRecordsById);
    }

    private void executePostProcessorFlow(String flowApiName, List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById) {
        if (String.isBlank(flowApiName)) {
            return;
        }

        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('triggerOperationType', Trigger.operationType?.name());
        flowInputs.put('records', loggerRecords);
        flowInputs.put('oldRecords', oldLoggerRecordsById?.values());

        Flow.Interview flowPostProcessor = Flow.Interview.createInterview(flowApiName, flowInputs);
        flowPostProcessor.start();
    }
}
