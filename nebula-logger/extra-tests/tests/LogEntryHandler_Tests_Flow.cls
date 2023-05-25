//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LogEntryHandler_Tests_Flow {
    private static final String EXAMPLE_FLOW_API_NAME = 'LogEntryHandler_Tests_Flow';

    @IsTest
    static void it_should_set_skip_setting_flow_details_when_origin_location_is_null() {
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginLocation__c = null, OriginType__c = 'Flow');

        insert logEntry;

        logEntry = getLogEntry();
        System.Assert.isNull(logEntry.OriginLocation__c, 'Origin Location was not null.');
        System.Assert.areEqual('Flow', logEntry.OriginType__c, 'Origin Type was not equal to Flow.');
        System.Assert.isNull(logEntry.FlowActiveVersionId__c, 'FlowActiveVersionId was not null.');
        System.Assert.isNull(logEntry.FlowDescription__c, 'Flow Description was not null.');
        System.Assert.isNull(logEntry.FlowDurableId__c, 'FlowDurableId was not null.');
        System.Assert.isNull(logEntry.FlowLabel__c, 'Flow Label was not null.');
        System.Assert.isNull(logEntry.FlowLastModifiedByName__c, 'FlowLastModifiedByName was not null.');
        System.Assert.isNull(logEntry.FlowLastModifiedDate__c, 'FlowLastModifiedDate was not null.');
        System.Assert.isNull(logEntry.FlowProcessType__c, 'FlowProcessType was not null.');
        System.Assert.isNull(logEntry.FlowTriggerType__c, 'FlowTriggerType was not null.');
        System.Assert.isNull(logEntry.FlowVersionApiVersionRuntime__c, 'FlowVersionApiVersionRuntime was not null.');
        System.Assert.isNull(logEntry.FlowVersionNumber__c, 'FlowVersionNumber was not null.');
        System.Assert.isNull(logEntry.FlowVersionRunInMode__c, 'FlowVersionRunInMode was not null.');
    }

    @IsTest
    static void it_should_set_flow_details_when_origin_location_is_a_flow() {
        FlowDefinitionView flowDefinitionView = getFlowDefinitionView();
        FlowVersionView flowVersion = getFlowVersion(flowDefinitionView.ActiveVersionId);
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, OriginLocation__c = flowDefinitionView.ApiName, OriginType__c = 'Flow');

        insert logEntry;

        logEntry = getLogEntry();
        System.Assert.areEqual(EXAMPLE_FLOW_API_NAME, logEntry.OriginLocation__c, 'Origin Location was not null.');
        System.Assert.areEqual('Flow', logEntry.OriginType__c, 'OriginType was not flow.');
        System.Assert.areEqual(flowDefinitionView.ActiveVersionId, logEntry.FlowActiveVersionId__c, 'FlowActiveVersionId was incorrect.');
        System.Assert.areEqual(flowDefinitionView.Description, logEntry.FlowDescription__c, 'FlowDescription was incorrect.');
        System.Assert.areEqual(flowDefinitionView.DurableId, logEntry.FlowDurableId__c, 'FlowDurableId was incorrect.');
        System.Assert.areEqual(flowDefinitionView.Label, logEntry.FlowLabel__c, 'FlowLabel was incorrect');
        System.Assert.areEqual(flowDefinitionView.LastModifiedBy, logEntry.FlowLastModifiedByName__c, 'FlowLastModifiedByName was incorrect.');
        System.Assert.areEqual(flowDefinitionView.LastModifiedDate, logEntry.FlowLastModifiedDate__c, 'FlowLastModifiedDate was incorrect.');
        System.Assert.areEqual(flowDefinitionView.ProcessType, logEntry.FlowProcessType__c, 'FlowProcessType was incorrect.');
        System.Assert.areEqual(flowDefinitionView.TriggerType, logEntry.FlowTriggerType__c, 'FlowTriggerType was incorrect.');
        System.Assert.areEqual(
            'v' + flowVersion.ApiVersionRuntime + '.0',
            logEntry.FlowVersionApiVersionRuntime__c,
            'FlowVersionApiVersionRuntime was incorrect.'
        );
        System.Assert.areEqual(flowVersion.RunInMode, logEntry.FlowVersionRunInMode__c, 'FlowVersionRunInMode was incorrect.');
        System.Assert.areEqual(flowVersion.VersionNumber, logEntry.FlowVersionNumber__c, 'FlowVersionNumber was incorrect.');
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

    private static FlowDefinitionView getFlowDefinitionView() {
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