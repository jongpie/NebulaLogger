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
    private static Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt> configurationsbySObjectType = loadConfigurations();

    private static Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt> loadConfigurations() {
        Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt> configsbySObjectType = new Map<SObjectType, LoggerSObjectHandlerConfiguration__mdt>();
        for (LoggerSObjectHandlerConfiguration__mdt config : LoggerSObjectHandlerConfiguration__mdt.getAll().values()) {
            // Schema.getGlobalDescribe() is the worst, so don't use it
            SObjectType sobjectType = ((SObject) Type.forName(config.LoggerSObject__r.DeveloperName + '__c').newInstance()).getSObjectType();

            configsbySObjectType.put(sobjectType, config);
        }
        return configsbySObjectType;
    }

    protected void executePostProcessors(List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById) {
        if (loggerRecords == null) {
            return;
        }

        LoggerSObjectHandlerConfiguration__mdt loggerHandlerConfiguration = configurationsbySObjectType.get(loggerRecords.getSObjectType());

        this.executePostProcessorApexClass(loggerHandlerConfiguration?.PostProcessorApexClassName__c, loggerRecords, oldLoggerRecordsById);
        this.executePostProcessorFlow(loggerHandlerConfiguration?.PostProcessorFlowApiName__c, loggerRecords, oldLoggerRecordsById);
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
