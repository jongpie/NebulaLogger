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

    @testVisible
    protected List<SObject> records;
    @testVisible
    protected Map<Id, SObject> oldRecordsById;
    @testVisible
    protected TriggerOperation triggerOperationType;

    private LoggerSObjectHandlerConfiguration__mdt configuration;

    public LoggerSObjectHandler() {
        this.configuration = getConfiguration(this.getSObjectType());

        if (this.configuration.IsEnabled__c == true) {
            this.records = Trigger.new;
            this.oldRecordsById = Trigger.oldMap;
            this.triggerOperationType = Trigger.operationType;
        }
    }

    /**
     * @description Returns the SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public abstract SObjectType getSObjectType();

    protected Boolean isEnabled() {
        return this.configuration.IsEnabled__c;
    }

    protected void executePostProcessors(List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById) {
        if (loggerRecords == null) {
            return;
        }

        this.executePostProcessorApexClass();
        this.executePostProcessorFlow();
    }

    private LoggerSObjectHandlerConfiguration__mdt getConfiguration(SObjectType sobjectType) {
        LoggerSObjectHandlerConfiguration__mdt configuration = configurationsBySObjectType.get(sobjectType);

        if (configuration == null) {
            configuration = new LoggerSObjectHandlerConfiguration__mdt(IsEnabled__c = true, SObjectType__c = sobjectType.getDescribe().getName());

            configurationsBySObjectType.put(sobjectType, configuration);
        }

        return configuration;
    }

    private void executePostProcessorApexClass() {
        if (String.isBlank(this.configuration.PostProcessorApexClassName__c) || Type.forName(this.configuration.PostProcessorApexClassName__c) == null) {
            return;
        }

        LoggerSObjectPostProcessor apexPostProcessor = (LoggerSObjectPostProcessor) Type.forName(this.configuration.PostProcessorApexClassName__c).newInstance();
        apexPostProcessor.execute(this.triggerOperationType, this.records, this.oldRecordsById);
    }

    private void executePostProcessorFlow() {
        if (String.isBlank(this.configuration.PostProcessorFlowApiName__c)) {
            return;
        }

        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('triggerOperationType', this.triggerOperationType?.name());
        flowInputs.put('records', this.records);
        flowInputs.put('oldRecords', this.oldRecordsById?.values());

        Flow.Interview flowPostProcessor = Flow.Interview.createInterview(this.configuration.PostProcessorFlowApiName__c, flowInputs);
        flowPostProcessor.start();
    }
}
