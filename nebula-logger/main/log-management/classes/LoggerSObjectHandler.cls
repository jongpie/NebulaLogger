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
    private static Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt> configurationsBySObjectType;
    @testVisible
    private static Map<SObjectType, List<LoggerSObjectPostProcessor__mdt>> postProcessorsBySObjectType;

    static {
        // When using CMDT's getAll(), it does not return relationship fields for EntityDefinition fields or child CMDT objects...
        // ... so instead query the LoggerSObjectHandlerConfiguration__mdt CMDT object
        List<LoggerSObjectHandlerConfiguration__mdt> configurations = [
            SELECT
                Id,
                IsEnabled__c,
                SObjectType__r.QualifiedApiName,
                (
                    SELECT Id, PostProcessorType__c, PostProcessorApiName__c
                    FROM LoggerSObjectPostProcessors__r
                    WHERE IsEnabled__c = TRUE
                    ORDER BY ExecutionOrder__c NULLS LAST, DeveloperName
                )
            FROM LoggerSObjectHandlerConfiguration__mdt
        ];

        configurationsBySObjectType = new Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt>();
        postProcessorsBySObjectType = new Map<SObjectType, List<LoggerSObjectPostProcessor__mdt>>();
        for (LoggerSObjectHandlerConfiguration__mdt config : configurations) {
            // CMDT entity-definition relationship fields are weird, so skip some headaches by copying the Qualified API name
            config.SObjectType__c = config.SObjectType__r.QualifiedApiName;

            // Schema.getGlobalDescribe() is the worst, so don't use it
            SObjectType sobjectType = ((SObject) Type.forName(config.SObjectType__c).newInstance()).getSObjectType();

            configurationsBySObjectType.put(sobjectType, config);
            postProcessorsBySObjectType.put(sobjectType, config?.LoggerSObjectPostProcessors__r);
        }

        if (Test.isRunningTest() == true) {
            // Test shouldn't rely on the actual CMDT rules in the org - clear the loaded values, and defaults will be used
            configurationsBySObjectType.clear();
            postProcessorsBySObjectType.clear();
        }
    }

    @testVisible
    protected TriggerOperation triggerOperationType;
    @testVisible
    protected List<SObject> records;
    @testVisible
    protected Map<Id, SObject> oldRecordsById;

    private LoggerSObjectHandlerConfiguration__mdt handlerConfiguration;
    private List<LoggerSObjectPostProcessor__mdt> postProcessors;

    public LoggerSObjectHandler() {
        this.setConfigurations();

        if (this.handlerConfiguration.IsEnabled__c == true) {
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
        return this.handlerConfiguration.IsEnabled__c;
    }

    protected void executePostProcessors() {
        if (this.records == null || this.postProcessors == null || this.postProcessors.isEmpty()) {
            return;
        }

        for (LoggerSObjectPostProcessor__mdt postProcessorConfiguration : this.postProcessors) {
            switch on postProcessorConfiguration.PostProcessorType__c {
                when 'Apex' {
                    this.executePostProcessorApexClass(postProcessorConfiguration.PostProcessorApiName__c);
                }
                when 'Flow' {
                    this.executePostProcessorFlow(postProcessorConfiguration.PostProcessorApiName__c);
                }
            }
        }
    }

    private void setConfigurations() {
        this.handlerConfiguration = configurationsBySObjectType.get(this.getSObjectType());
        this.postProcessors = postProcessorsBySObjectType.get(this.getSObjectType());

        if (this.handlerConfiguration == null) {
            // If no config exists in the org, then load some in-memory defaults
            this.handlerConfiguration = new LoggerSObjectHandlerConfiguration__mdt(IsEnabled__c = true, SObjectType__c = this.getSObjectType().getDescribe().getName());

            configurationsBySObjectType.put(this.getSObjectType(), this.handlerConfiguration);
        }
    }

    private void executePostProcessorApexClass(String apexClassName) {
        LoggerSObjectPostProcessor apexPostProcessor = (LoggerSObjectPostProcessor) Type.forName(apexClassName).newInstance();
        apexPostProcessor.execute(this.triggerOperationType, this.records, this.oldRecordsById);
    }

    private void executePostProcessorFlow(String flowApiName) {
        if (String.isBlank(flowApiName)) {
            return;
        }

        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('triggerOperationType', this.triggerOperationType?.name());
        flowInputs.put('records', this.records);
        flowInputs.put('oldRecords', this.oldRecordsById?.values());

        Flow.Interview flowPostProcessor = Flow.Interview.createInterview(flowApiName, flowInputs);
        flowPostProcessor.start();
    }
}
