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
        System.Assert.isNull(logEntry.OriginLocation__c);
        System.Assert.areEqual('Flow', logEntry.OriginType__c);
        System.Assert.isNull(logEntry.StackTrace__c, 'Currently, there\'s no way to get a stack trace in Flow, so always expect null 😥');
        System.Assert.isNull(logEntry.FlowActiveVersionId__c);
        System.Assert.isNull(logEntry.FlowDescription__c);
        System.Assert.isNull(logEntry.FlowDurableId__c);
        System.Assert.isNull(logEntry.FlowLabel__c);
        System.Assert.isNull(logEntry.FlowLastModifiedByName__c);
        System.Assert.isNull(logEntry.FlowLastModifiedDate__c);
        System.Assert.isNull(logEntry.FlowProcessType__c);
        System.Assert.isNull(logEntry.FlowRecordTriggerType__c);
        System.Assert.isNull(logEntry.FlowTriggerSObjectType__c);
        System.Assert.isNull(logEntry.FlowTriggerOrder__c);
        System.Assert.isNull(logEntry.FlowTriggerType__c);
        System.Assert.isNull(logEntry.FlowVersionApiVersionRuntime__c);
        System.Assert.isNull(logEntry.FlowVersionNumber__c);
        System.Assert.isNull(logEntry.FlowVersionRunInMode__c);
        System.Assert.isFalse(logEntry.HasOriginSourceSnippet__c);
        System.Assert.isFalse(logEntry.HasStackTrace__c);
        System.Assert.isNull(logEntry.OriginSourceApiVersion__c);
        System.Assert.isNull(logEntry.OriginSourceCreatedById__c);
        System.Assert.isNull(logEntry.OriginSourceCreatedByUsername__c);
        System.Assert.isNull(logEntry.OriginSourceCreatedDate__c);
        System.Assert.isNull(logEntry.OriginSourceId__c);
        System.Assert.isNull(logEntry.OriginSourceLastModifiedById__c);
        System.Assert.isNull(logEntry.OriginSourceLastModifiedByUsername__c);
        System.Assert.isNull(logEntry.OriginSourceLastModifiedDate__c);
        System.Assert.isNull(logEntry.OriginSourceSnippet__c);
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
        System.Assert.areEqual(EXAMPLE_FLOW_API_NAME, logEntry.OriginLocation__c);
        System.Assert.areEqual('Flow', logEntry.OriginType__c);
        System.Assert.isNull(logEntry.StackTrace__c, 'Currently, there\'s no way to get a stack trace in Flow, so always expect null 😥');

        // Older Flow-specific fields
        System.Assert.areEqual(flowDefinitionView.ActiveVersionId, logEntry.FlowActiveVersionId__c);
        System.Assert.areEqual(flowDefinitionView.Description, logEntry.FlowDescription__c);
        System.Assert.areEqual(flowDefinitionView.DurableId, logEntry.FlowDurableId__c);
        System.Assert.areEqual(flowDefinitionView.Label, logEntry.FlowLabel__c);
        System.Assert.areEqual(flowDefinitionView.LastModifiedBy, logEntry.FlowLastModifiedByName__c);
        System.Assert.areEqual(flowDefinitionView.LastModifiedDate, logEntry.FlowLastModifiedDate__c);
        System.Assert.areEqual(flowDefinitionView.ProcessType, logEntry.FlowProcessType__c);
        System.Assert.areEqual(flowDefinitionView.RecordTriggerType, logEntry.FlowRecordTriggerType__c);
        System.Assert.areEqual(flowDefinitionView.TriggerOrder, logEntry.FlowTriggerOrder__c);
        System.Assert.areEqual(flowDefinitionView.TriggerObjectOrEvent.QualifiedApiName, logEntry.FlowTriggerSObjectType__c);
        System.Assert.areEqual(flowDefinitionView.TriggerType, logEntry.FlowTriggerType__c);
        System.Assert.areEqual(
            'v' + flowVersion.ApiVersionRuntime + '.0',
            logEntry.FlowVersionApiVersionRuntime__c,
            'FlowVersionApiVersionRuntime was incorrect.'
        );
        System.Assert.areEqual(flowVersion.RunInMode, logEntry.FlowVersionRunInMode__c, 'FlowVersionRunInMode was incorrect.');
        System.Assert.areEqual(flowVersion.VersionNumber, logEntry.FlowVersionNumber__c, 'FlowVersionNumber was incorrect.');
        // Newer, general-purpose 'origin source' fields
        System.Assert.areEqual(flowDefinitionView.ActiveVersionId, logEntry.OriginSourceId__c);
        System.Assert.areEqual('v' + flowVersion.ApiVersionRuntime + '.0', logEntry.OriginSourceApiVersion__c);
        System.Assert.areEqual(flowDefinitionView.LastModifiedDate, logEntry.OriginSourceLastModifiedDate__c);
        System.Assert.isNull(
            logEntry.OriginSourceCreatedById__c,
            'Neither FlowDefinitionView nor FlowVersionView seem to be have "created by/date" fields, so always expect null 😥'
        );
        System.Assert.isNull(
            logEntry.OriginSourceCreatedByUsername__c,
            'Neither FlowDefinitionView nor FlowVersionView seem to be have "created by/date" fields, so always expect null 😥'
        );
        System.Assert.isNull(
            logEntry.OriginSourceCreatedDate__c,
            'Neither FlowDefinitionView nor FlowVersionView seem to be have "created by/date" fields, so always expect null 😥'
        );
        System.Assert.isNull(
            logEntry.OriginSourceLastModifiedById__c,
            'Neither FlowDefinitionView nor FlowVersionView seem to be have "last modified by" fields (only the person\'s name is stored?!), so always expect null 😥'
        );
        System.Assert.isNull(
            logEntry.OriginSourceLastModifiedByUsername__c,
            'Neither FlowDefinitionView nor FlowVersionView seem to be have "last modified by" fields (only the person\'s name is stored?!), so always expect null 😥'
        );
        System.Assert.isNull(logEntry.OriginSourceSnippet__c, 'There\'s currently not a way to generate a snippet for a Flow, so always expect null 😥');
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
                FlowRecordTriggerType__c,
                FlowTriggerSObjectType__c,
                FlowTriggerOrder__c,
                FlowTriggerType__c,
                FlowVersionApiVersionRuntime__c,
                FlowVersionNumber__c,
                FlowVersionRunInMode__c,
                HasOriginSourceSnippet__c,
                HasStackTrace__c,
                OriginLocation__c,
                OriginSourceApiVersion__c,
                OriginSourceCreatedById__c,
                OriginSourceCreatedByUsername__c,
                OriginSourceCreatedDate__c,
                OriginSourceId__c,
                OriginSourceLastModifiedById__c,
                OriginSourceLastModifiedByUsername__c,
                OriginSourceLastModifiedDate__c,
                OriginSourceSnippet__c,
                OriginType__c,
                StackTrace__c
            FROM LogEntry__c
            ORDER BY CreatedDate
            LIMIT 1
        ];
    }

    private static FlowDefinitionView getFlowDefinitionView() {
        return [
            SELECT
                ActiveVersionId,
                ApiName,
                Description,
                DurableId,
                Label,
                LastModifiedBy,
                LastModifiedDate,
                ManageableState,
                ProcessType,
                RecordTriggerType,
                TriggerObjectOrEvent.QualifiedApiName,
                TriggerOrder,
                TriggerType
            FROM FlowDefinitionView
            WHERE ApiName = :EXAMPLE_FLOW_API_NAME AND IsActive = TRUE
        ];
    }

    private static FlowVersionView getFlowVersion(Id flowActiveVersionId) {
        return [SELECT ApiVersionRuntime, FlowDefinitionViewId, RunInMode, Status, VersionNumber FROM FlowVersionView WHERE DurableId = :flowActiveVersionId];
    }
}
