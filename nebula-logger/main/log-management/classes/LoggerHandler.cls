global class LoggerHandler {
    private LoggerHandler() {
    }

    global interface PostProcessor {
        void execute(TriggerOperation triggerOperation, List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById);
    }

    public static void executePostProcessors(List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById) {
        if (loggerRecords == null) {
            return;
        }

        String sobjectTypeCmdtName = loggerRecords.getSObjectType().getDescribe().getName().replace('__c', '');

        List<LoggerHandlerConfiguration__mdt> loggerHandlerConfigurations = [
            SELECT ApexClassName__c, FlowName__c
            FROM LoggerHandlerConfiguration__mdt
            WHERE LoggerSObject__r.DeveloperName = :sobjectTypeCmdtName AND IsActive__c = TRUE
        ];
        LoggerHandlerConfiguration__mdt loggerHandlerConfiguration = loggerHandlerConfigurations.isEmpty() ? null : loggerHandlerConfigurations.get(0);

        executeApexClass(loggerHandlerConfiguration?.ApexClassName__c, loggerRecords, oldLoggerRecordsById);
        executeFlow(loggerHandlerConfiguration?.FlowName__c, loggerRecords, oldLoggerRecordsById);
    }

    private static void executeApexClass(String apexClassName, List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById) {
        if (String.isBlank(apexClassName)) {
            return;
        }

        Type postProcessorType = Type.forName(apexClassName);
        PostProcessor recordPostProcessor = (PostProcessor) postProcessorType.newInstance();
        recordPostProcessor.execute(Trigger.operationType, loggerRecords, oldLoggerRecordsById);
    }

    private static void executeFlow(String flowName, List<SObject> loggerRecords, Map<Id, SObject> oldLoggerRecordsById) {
        if (String.isBlank(flowName)) {
            return;
        }

        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('records', loggerRecords);
        flowInputs.put('oldRecords', oldLoggerRecordsById?.values());
        flowInputs.put('triggerOperation', Trigger.operationType);

        Flow.Interview recordFlow = Flow.Interview.createInterview(flowName, flowInputs);
        recordFlow.start();
    }
}
