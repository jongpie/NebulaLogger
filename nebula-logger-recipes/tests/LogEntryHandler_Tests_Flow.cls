//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@IsTest
private class LogEntryHandler_Tests_Flow {
    private static final String EXAMPLE_FLOW_API_NAME = 'LogEntryHandler_Tests_Flow';

    @IsTest
    static void it_should_set_skip_setting_flow_details_when_origin_location_is_null() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginLocation__c = null, OriginType__c = 'Flow');
        insert logEntry;
        logEntry = getLogEntry();

        System.assertEquals(null, logEntry.OriginLocation__c);
        System.assertEquals('Flow', logEntry.OriginType__c);
        System.assertEquals(null, logEntry.FlowActiveVersionId__c);
        System.assertEquals(null, logEntry.FlowDescription__c);
        System.assertEquals(null, logEntry.FlowDurableId__c);
        System.assertEquals(null, logEntry.FlowLabel__c);
        System.assertEquals(null, logEntry.FlowLastModifiedByName__c);
        System.assertEquals(null, logEntry.FlowLastModifiedDate__c);
        System.assertEquals(null, logEntry.FlowProcessType__c);
        System.assertEquals(null, logEntry.FlowTriggerType__c);
        System.assertEquals(null, logEntry.FlowVersionApiVersionRuntime__c);
        System.assertEquals(null, logEntry.FlowVersionNumber__c);
        System.assertEquals(null, logEntry.FlowVersionRunInMode__c);
    }

    @IsTest
    static void it_should_set_flow_details() {
        FlowDefinitionView flowDefinition = getFlowDefinition();
        FlowVersionView flowVersion = getFlowVersion(flowDefinition.ActiveVersionId);

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginLocation__c = flowDefinition.ApiName, OriginType__c = 'Flow');
        insert logEntry;
        logEntry = getLogEntry();

        System.assertEquals('Flow', logEntry.OriginType__c);
        System.assertEquals(flowDefinition.ActiveVersionId, logEntry.FlowActiveVersionId__c);
        System.assertEquals(flowDefinition.Description, logEntry.FlowDescription__c);
        System.assertEquals(flowDefinition.DurableId, logEntry.FlowDurableId__c);
        System.assertEquals(flowDefinition.Label, logEntry.FlowLabel__c);
        System.assertEquals(flowDefinition.LastModifiedBy, logEntry.FlowLastModifiedByName__c);
        System.assertEquals(flowDefinition.LastModifiedDate, logEntry.FlowLastModifiedDate__c);
        System.assertEquals(flowDefinition.ProcessType, logEntry.FlowProcessType__c);
        System.assertEquals(flowDefinition.TriggerType, logEntry.FlowTriggerType__c);
        System.assertEquals('v' + flowVersion.ApiVersionRuntime + '.0', logEntry.FlowVersionApiVersionRuntime__c);
        System.assertEquals(flowVersion.RunInMode, logEntry.FlowVersionRunInMode__c);
        System.assertEquals(flowVersion.VersionNumber, logEntry.FlowVersionNumber__c);
    }

    private static LogEntry__c getLogEntry() {
        return [
            SELECT
                FlowActiveVersionId__c,
                FlowDescription__c,
                FlowDurableId__c,
                FlowLabel__c,
                FlowLastModifiedByName__c,
                FlowLastModifiedDate__c,
                FlowProcessType__c,
                FlowTriggerType__c,
                FlowVersionApiVersionRuntime__c,
                FlowVersionNumber__c,
                FlowVersionRunInMode__c,
                OriginLocation__c,
                OriginType__c
            FROM LogEntry__c
            // WHERE OriginType__c = 'Flow'
            ORDER BY CreatedDate
            LIMIT 1
        ];
    }

    private static FlowDefinitionView getFlowDefinition() {
        return [
            SELECT ActiveVersionId, ApiName, Description, DurableId, Label, LastModifiedBy, LastModifiedDate, ManageableState, ProcessType, TriggerType
            FROM FlowDefinitionView
            WHERE ApiName = :EXAMPLE_FLOW_API_NAME AND IsActive = TRUE
        ];
    }

    private static FlowVersionView getFlowVersion(Id flowActiveVersionId) {
        return [SELECT ApiVersionRuntime, FlowDefinitionViewId, RunInMode, Status, VersionNumber FROM FlowVersionView WHERE DurableId = :flowActiveVersionId];
    }
}
