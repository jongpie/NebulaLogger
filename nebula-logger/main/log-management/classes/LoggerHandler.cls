//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Abstract class used by trigger handlers for shared logic
 */
 public abstract class LoggerHandler {
    @testVisible
    private static Map<SObjectType, LoggerHandlerConfiguration__mdt> configurationsbySObjectType = loadConfigurations();

    private static Map<SObjectType, LoggerHandlerConfiguration__mdt> loadConfigurations() {
        Map<SObjectType, LoggerHandlerConfiguration__mdt> configsbySObjectType = new Map<SObjectType, LoggerHandlerConfiguration__mdt>();
        for (LoggerHandlerConfiguration__mdt config : LoggerHandlerConfiguration__mdt.getAll().values()) {
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

        LoggerHandlerConfiguration__mdt loggerHandlerConfiguration = configurationsbySObjectType.get(loggerRecords.getSObjectType());

        this.executeApexClass(loggerHandlerConfiguration?.PostProcessorApexClassName__c, loggerRecords, oldLoggerRecordsById);
        this.executeFlow(loggerHandlerConfiguration?.PostProcessorFlowApiName__c, loggerRecords, oldLoggerRecordsById);
    }

    private void executeApexClass(String apexClassName, List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById) {
        if (String.isBlank(apexClassName) || Type.forName(apexClassName) == null) {
            return;
        }

        LoggerPostProcessor recordPostProcessor = (LoggerPostProcessor) Type.forName(apexClassName).newInstance();
        recordPostProcessor.execute(Trigger.operationType, loggerRecords, oldLoggerRecordsById);
    }

    private void executeFlow(String flowApiName, List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById) {
        if (String.isBlank(flowApiName)) {
            return;
        }

        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('triggerOperationType', Trigger.operationType);
        flowInputs.put('records', loggerRecords);
        flowInputs.put('oldRecords', oldLoggerRecordsById?.values());

        Flow.Interview recordFlow = Flow.Interview.createInterview(flowApiName, flowInputs);
        recordFlow.start();
    }
}
