//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Manages setting fields on `LogEntry__c` before insert & before update
 */
@SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount, PMD.StdCyclomaticComplexity')
public without sharing class LogEntryHandler extends LoggerSObjectHandler {
    private static final Map<Schema.SObjectType, String> SOBJECT_TYPE_TO_DISPLAY_FIELD_NAME = new Map<Schema.SObjectType, String>();

    @TestVisible
    private List<LogEntry__c> logEntries;

    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override Schema.SObjectType getSObjectType() {
        return Schema.LogEntry__c.SObjectType;
    }

    protected override void executeBeforeInsert(List<SObject> triggerNew) {
        this.logEntries = (List<LogEntry__c>) triggerNew;

        this.setApexClassFields();
        this.setApexTriggerFields();
        this.setComponentFields();
        this.setFlowDefinitionFields();
        this.setFlowVersionFields();
        this.setRecordNames();
        this.setCheckboxFields();
    }

    protected override void executeBeforeUpdate(Map<Id, SObject> triggerNewMap, Map<Id, SObject> triggerOldMap) {
        this.logEntries = (List<LogEntry__c>) triggerNewMap.values();

        // Realistically, these checkbox fields probably only need to be set on insert
        // but some admins & devs might decide to update/append data in some of the related fields
        // and it conceptually feels weird for there to be scenarios where these fields could be inaccurate,
        // so keep them up to date just to be safe
        this.setCheckboxFields();
    }

    private void setApexClassFields() {
        String apexClassSObjectTypeName = Schema.ApexClass.SObjectType.getDescribe().getName();
        Set<String> apexClassNames = new Set<String>();
        Set<LogEntry__c> apexClassLogEntries = new Set<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (logEntry.OriginSourceMetadataType__c == apexClassSObjectTypeName && String.isNotBlank(logEntry.OriginSourceApiName__c)) {
                apexClassLogEntries.add(logEntry);
                apexClassNames.add(logEntry.OriginSourceApiName__c);
            }

            if (logEntry.ExceptionSourceMetadataType__c == apexClassSObjectTypeName && String.isNotBlank(logEntry.ExceptionSourceApiName__c)) {
                apexClassLogEntries.add(logEntry);
                apexClassNames.add(logEntry.ExceptionSourceApiName__c);
            }
        }

        if (apexClassNames.isEmpty()) {
            return;
        }

        Map<String, Schema.ApexClass> classNameToApexClass = new Map<String, Schema.ApexClass>();
        for (Schema.ApexClass apexClass : LogManagementDataSelector.getInstance().getApexClasses(apexClassNames)) {
            classNameToApexClass.put(apexClass.Name, apexClass);
        }

        if (classNameToApexClass.isEmpty()) {
            return;
        }

        for (LogEntry__c logEntry : apexClassLogEntries) {
            Schema.ApexClass originApexClass = classNameToApexClass.get(logEntry.OriginSourceApiName__c);
            new OriginApexMetadataFieldApplier().apply(logEntry, originApexClass);

            Schema.ApexClass exceptionApexClass = classNameToApexClass.get(logEntry.ExceptionSourceApiName__c);
            new ExceptionApexMetadataFieldApplier().apply(logEntry, exceptionApexClass);
        }
    }

    private void setApexTriggerFields() {
        String apexTriggerSObjectTypeName = Schema.ApexTrigger.SObjectType.getDescribe().getName();
        Set<String> apexTriggerNames = new Set<String>();
        Set<LogEntry__c> apexTriggerLogEntries = new Set<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (logEntry.OriginSourceMetadataType__c == apexTriggerSObjectTypeName && String.isNotBlank(logEntry.OriginSourceApiName__c)) {
                apexTriggerLogEntries.add(logEntry);
                apexTriggerNames.add(logEntry.OriginSourceApiName__c);
            }

            if (logEntry.ExceptionSourceMetadataType__c == apexTriggerSObjectTypeName && String.isNotBlank(logEntry.ExceptionSourceApiName__c)) {
                apexTriggerLogEntries.add(logEntry);
                apexTriggerNames.add(logEntry.ExceptionSourceApiName__c);
            }
        }

        if (apexTriggerNames.isEmpty()) {
            return;
        }

        Map<String, Schema.ApexTrigger> triggerNameToApexTrigger = new Map<String, Schema.ApexTrigger>();
        for (Schema.ApexTrigger apexTrigger : LogManagementDataSelector.getInstance().getApexTriggers(apexTriggerNames)) {
            triggerNameToApexTrigger.put(apexTrigger.Name, apexTrigger);
        }

        if (triggerNameToApexTrigger.isEmpty()) {
            return;
        }

        for (LogEntry__c logEntry : apexTriggerLogEntries) {
            Schema.ApexTrigger originApexTrigger = triggerNameToApexTrigger.get(logEntry.OriginSourceApiName__c);
            new OriginApexMetadataFieldApplier().apply(logEntry, originApexTrigger);

            Schema.ApexTrigger exceptionApexTrigger = triggerNameToApexTrigger.get(logEntry.ExceptionSourceApiName__c);
            new ExceptionApexMetadataFieldApplier().apply(logEntry, exceptionApexTrigger);
        }
    }

    private void setComponentFields() {
        for (LogEntry__c logEntry : this.logEntries) {
            if (logEntry.OriginType__c == 'Component' && String.isNotBlank(logEntry.OriginLocation__c)) {
                logEntry.ComponentApiName__c = logEntry.OriginLocation__c.substringBefore('.');
                logEntry.ComponentFunctionName__c = logEntry.OriginLocation__c.substringAfterLast('.');
            }
        }
    }

    private void setFlowDefinitionFields() {
        List<String> flowApiNames = new List<String>();
        List<LogEntry__c> flowLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (logEntry.OriginSourceMetadataType__c == 'Flow' && String.isNotBlank(logEntry.OriginSourceApiName__c)) {
                flowApiNames.add(logEntry.OriginSourceApiName__c);
                flowLogEntries.add(logEntry);
            }
        }

        if (flowApiNames.isEmpty()) {
            return;
        }

        Map<String, FlowDefinitionView> flowApiNameToDefinition = new Map<String, FlowDefinitionView>();
        for (FlowDefinitionView flowDefinition : LogManagementDataSelector.getInstance().getFlowDefinitionViewsByFlowApiName(flowApiNames)) {
            flowApiNameToDefinition.put(flowDefinition.ApiName, flowDefinition);
        }

        if (flowApiNameToDefinition.isEmpty()) {
            return;
        }

        for (LogEntry__c logEntry : flowLogEntries) {
            FlowDefinitionView flowDefinition = flowApiNameToDefinition.get(logEntry.OriginSourceApiName__c);
            if (flowDefinition == null) {
                continue;
            }

            // Older Flow-specific fields
            logEntry.FlowActiveVersionId__c = flowDefinition.ActiveVersionId;
            logEntry.FlowDescription__c = flowDefinition.Description;
            logEntry.FlowDurableId__c = flowDefinition.DurableId;
            logEntry.FlowLabel__c = flowDefinition.Label;
            logEntry.FlowLastModifiedByName__c = flowDefinition.LastModifiedBy;
            logEntry.FlowLastModifiedDate__c = flowDefinition.LastModifiedDate;
            logEntry.FlowProcessType__c = flowDefinition.ProcessType;
            logEntry.FlowRecordTriggerType__c = flowDefinition.RecordTriggerType;
            logEntry.FlowTriggerOrder__c = flowDefinition.TriggerOrder;
            logEntry.FlowTriggerSObjectType__c = flowDefinition.TriggerObjectOrEvent?.QualifiedApiName;
            logEntry.FlowTriggerType__c = flowDefinition.TriggerType;

            // Newer, general-purpose 'origin source' fields
            logEntry.OriginSourceId__c = flowDefinition.ActiveVersionId;
            logEntry.OriginSourceLastModifiedDate__c = flowDefinition.LastModifiedDate;
        }
    }

    private void setFlowVersionFields() {
        List<String> flowActiveVersionIds = new List<String>();
        List<LogEntry__c> flowLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (logEntry.OriginSourceMetadataType__c == 'Flow' && String.isNotBlank(logEntry.OriginSourceId__c)) {
                flowActiveVersionIds.add(logEntry.OriginSourceId__c);
                flowLogEntries.add(logEntry);
            }
        }

        if (flowActiveVersionIds.isEmpty()) {
            return;
        }

        Map<String, FlowVersionView> flowDurableIdToFlowVersionView = new Map<String, FlowVersionView>();
        for (FlowVersionView flowVersionView : LogManagementDataSelector.getInstance().getFlowVersionViewsByDurableId(flowActiveVersionIds)) {
            // Filtering on Status in SOQL seems to always return 0 results, so filter in code instead
            if (flowVersionView.Status == 'Active') {
                flowDurableIdToFlowVersionView.put(flowVersionView.FlowDefinitionViewId, flowVersionView);
            }
        }

        if (flowDurableIdToFlowVersionView.isEmpty()) {
            return;
        }

        for (LogEntry__c logEntry : flowLogEntries) {
            FlowVersionView flowVersionView = flowDurableIdToFlowVersionView.get(logEntry.FlowDurableId__c);
            if (flowVersionView == null) {
                continue;
            }

            // Older Flow-specific fields
            logEntry.FlowVersionApiVersionRuntime__c = 'v' + flowVersionView.ApiVersionRuntime + '.0';
            logEntry.FlowVersionRunInMode__c = flowVersionView.RunInMode;
            logEntry.FlowVersionNumber__c = flowVersionView.VersionNumber;

            // Newer, general-purpose 'origin source' fields
            logEntry.OriginSourceApiVersion__c = 'v' + flowVersionView.ApiVersionRuntime + '.0';
        }
    }

    @SuppressWarnings('PMD.OperationWithLimitsInLoop')
    private void setRecordNames() {
        if (LoggerParameter.QUERY_RELATED_RECORD_DATA == false) {
            return;
        }

        // Assumption - only valid record IDs will be populated in LogEntry__c.RecordId__c
        // If that changes, then extra checks may be needed before casting to Id, using getSObjectType(), etc.
        // TODO: This method is pretty long & it's doing multiple things - consider breaking it up into separate methods or an inner class

        // 1. Figure out which SObjects & record IDs to query
        Map<Schema.SObjectType, List<Id>> sobjectTypeToRecords = new Map<Schema.SObjectType, List<Id>>();
        for (LogEntry__c logEntry : this.logEntries) {
            // Skip the log entry if there's no related record ID
            if (logEntry.RecordId__c == null) {
                continue;
            }

            Id recordId = (Id) logEntry.RecordId__c;
            Schema.SObjectType sobjectType = getSObjectType(recordId);
            if (sobjectType == null) {
                continue;
            }

            List<Id> sobjectTypeRecordIds = sobjectTypeToRecords.get(sobjectType);
            if (sobjectTypeRecordIds == null) {
                sobjectTypeRecordIds = new List<Id>();
            }
            sobjectTypeRecordIds.add(recordId);
            sobjectTypeToRecords.put(sobjectType, sobjectTypeRecordIds);
        }

        // 2. Run the queries and store the results in the map
        Map<Id, SObject> recordIdToRecord = new Map<Id, SObject>();
        for (Schema.SObjectType sobjectType : sobjectTypeToRecords.keySet()) {
            // Stop if we've used up all the queries
            if (System.Limits.getQueries() == System.Limits.getLimitQueries()) {
                break;
            }

            List<Id> sobjectTypeRecordIds = sobjectTypeToRecords.get(sobjectType);
            String sobjectDisplayFieldName = this.getDisplayFieldApiName(sobjectType);

            if (sobjectDisplayFieldName == null) {
                continue;
            }

            List<SObject> results = LogManagementDataSelector.getInstance()
                .getById(sobjectType, new Set<String>{ sobjectDisplayFieldName }, sobjectTypeRecordIds);
            recordIdToRecord.putAll(results);
        }

        // 3. Finally, save the record name on the log entry
        for (LogEntry__c logEntry : this.logEntries) {
            // Skip the log entry if there's no related record ID
            if (logEntry.RecordId__c == null) {
                continue;
            }

            Id recordId = (Id) logEntry.RecordId__c;
            Schema.SObjectType sobjectType = getSObjectType(recordId);
            if (sobjectType == null) {
                continue;
            }

            String sobjectDisplayFieldName = this.getDisplayFieldApiName(sobjectType);
            if (sobjectDisplayFieldName != null) {
                if (recordIdToRecord.containsKey(logEntry.RecordId__c)) {
                    String recordName = (String) recordIdToRecord.get(logEntry.RecordId__c).get(sobjectDisplayFieldName);
                    logEntry.RecordName__c = recordName;
                }
            }
        }
    }

    private void setCheckboxFields() {
        // Long textarea fields can't be used in filters for SOQL, list views, etc, and a formula field can't be used
        // for checking if a long text area field is set/null...
        // So, this code handles maintaining some checkbox fields via Apex instead
        for (LogEntry__c logEntry : this.logEntries) {
            logEntry.HasDatabaseResultJson__c = logEntry.DatabaseResultJson__c != null;
            logEntry.HasExceptionSourceSnippet__c = logEntry.ExceptionSourceSnippet__c != null;
            logEntry.HasExceptionStackTrace__c = logEntry.ExceptionStackTrace__c != null;
            logEntry.HasHttpRequestBody__c = logEntry.HttpRequestBody__c != null;
            logEntry.HasHttpResponseBody__c = logEntry.HttpResponseBody__c != null;
            logEntry.HasHttpResponseHeaderKeys__c = logEntry.HttpResponseHeaderKeys__c != null;
            logEntry.HasHttpResponseHeaders__c = logEntry.HttpResponseHeaders__c != null;
            logEntry.HasInlineTags__c = logEntry.Tags__c != null;
            logEntry.HasOriginSourceSnippet__c = logEntry.OriginSourceSnippet__c != null;
            logEntry.HasRecordJson__c = logEntry.RecordJson__c != null;
            logEntry.HasRestRequestBody__c = logEntry.RestRequestBody__c != null;
            logEntry.HasRestRequestHeaderKeys__c = logEntry.RestRequestHeaderKeys__c != null;
            logEntry.HasRestRequestHeaders__c = logEntry.RestRequestHeaders__c != null;
            logEntry.HasRestResponseBody__c = logEntry.RestResponseBody__c != null;
            logEntry.HasRestResponseHeaderKeys__c = logEntry.RestResponseHeaderKeys__c != null;
            logEntry.HasRestResponseHeaders__c = logEntry.RestResponseHeaders__c != null;
            logEntry.HasStackTrace__c = logEntry.StackTrace__c != null;
        }
    }

    private String getDisplayFieldApiName(Schema.SObjectType sobjectType) {
        if (SOBJECT_TYPE_TO_DISPLAY_FIELD_NAME.containsKey(sobjectType)) {
            return SOBJECT_TYPE_TO_DISPLAY_FIELD_NAME.get(sobjectType);
        }

        // Use username instead of name for user
        if (sobjectType == Schema.User.SObjectType) {
            String userFieldName = Schema.User.Username.getDescribe().getName();
            SOBJECT_TYPE_TO_DISPLAY_FIELD_NAME.put(Schema.User.SObjectType, userFieldName);
            return userFieldName;
        }

        // There are several commonly used names for the display field name - typically, Name
        // The order of the field names has been sorted based on number of objects in a dev org with that field
        List<String> educatedGuesses = new List<String>{
            'Name',
            'DeveloperName',
            'ApiName',
            'Title',
            'Subject',
            'AssetRelationshipNumber',
            'CaseNumber',
            'ContractNumber',
            'Domain',
            'FriendlyName',
            'FunctionName',
            'Label',
            'LocalPart',
            'OrderItemNumber',
            'OrderNumber',
            'SolutionName',
            'TestSuiteName'
        };

        String displayFieldApiName;
        List<String> fallbackFieldApiNames = new List<String>();
        for (String fieldName : educatedGuesses) {
            Schema.SObjectField field = sobjectType.getDescribe().fields.getMap().get(fieldName);

            if (field == null) {
                continue;
            }

            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            if (fieldDescribe.isNameField()) {
                displayFieldApiName = fieldDescribe.getName();
                break;
            } else {
                fallbackFieldApiNames.add(fieldDescribe.getName());
            }
        }

        // Some objects don't have a proper 'display field', but they do have a reasonable alternative field to use instead.
        // For example, EmailMessage doesn't have a true display field, but it has a 'Subject' field. If one (and only one)
        // of the educated guess-fields exists on the object - and the object does not have a display field - then use the
        // educated guess-field as the fallback for the display field.
        if (String.isBlank(displayFieldApiName) && fallbackFieldApiNames.size() == 1) {
            displayFieldApiName = fallbackFieldApiNames.get(0);
        }

        SOBJECT_TYPE_TO_DISPLAY_FIELD_NAME.put(sobjectType, displayFieldApiName);
        return displayFieldApiName;
    }

    private static Schema.SObjectType getSObjectType(Id recordId) {
        Schema.SObjectType sobjectType;
        try {
            sobjectType = recordId?.getSObjectType();
        } catch (System.SObjectException sobjectException) {
            // Some SObject Types are considered template objects, such as CaseComment, AccountHistory,
            // ContactHistory, etc, so calling Id.getSObjectType() does not work for some types of record IDs
            if (sobjectException.getMessage().contains('Cannot locate Apex Type') == false) {
                throw sobjectException;
            }
        }
        return sobjectType;
    }

    // TODO consider making this a top-level, generically-named class (LoggerSourceMetadataSnippet?)
    @SuppressWarnings('PMD.ApexDoc, PMD.PropertyNamingConventions')
    public class SourceMetadataSnippet {
        public String Code { get; private set; }
        public String ApiVersion { get; private set; }
        public Integer TotalLinesOfCode { get; private set; }
        public Integer StartingLineNumber { get; private set; }
        public Integer TargetLineNumber { get; private set; }
        public Integer EndingLineNumber { get; private set; }

        public transient LoggerStackTrace StackTrace { get; private set; }
        // TODO decide if this is needed, it's duplicated from LoggerStackTrace.Language
        // But ultimately, the frontend needs to know the language to display in PrismJS
        public LoggerStackTrace.SourceLanguage Language {
            get {
                return this.StackTrace?.Language;
            }
        }

        public SourceMetadataSnippet(LoggerStackTrace stackTrace, Schema.ApexClass apexClass) {
            this(stackTrace, apexClass.Body, apexClass.ApiVersion);
        }

        public SourceMetadataSnippet(LoggerStackTrace stackTrace, Schema.ApexTrigger apexTrigger) {
            this(stackTrace, apexTrigger.Body, apexTrigger.ApiVersion);
        }

        private SourceMetadataSnippet(LoggerStackTrace stackTrace, String sourceCode, Decimal sourceApiVersion) {
            this.ApiVersion = 'v' + sourceApiVersion;
            this.StackTrace = stackTrace;

            List<String> allCodeLines = sourceCode.split('\n');
            this.setLineNumbers(stackTrace.Source.LineNumber, allCodeLines);
            this.setCode(allCodeLines);
        }

        private List<String> setLineNumbers(Integer targetLineNumber, List<String> allCodeLines) {
            Integer numberOfCodeLines = allCodeLines.size();

            // TODO consider making these values configurable with 2 new LoggerParameter__mdt records
            final Integer targetLeadingLines = 8;
            final Integer targetTrailingLines = 4;

            Integer calculcatedStartingLineNumber = targetLineNumber - targetLeadingLines;
            if (calculcatedStartingLineNumber <= 0) {
                calculcatedStartingLineNumber = 1;
            }

            Integer calculatedEndingLineNumber = targetLineNumber + targetTrailingLines;
            if (calculatedEndingLineNumber > numberOfCodeLines) {
                calculatedEndingLineNumber = numberOfCodeLines;
            }

            this.TotalLinesOfCode = numberOfCodeLines;
            this.StartingLineNumber = calculcatedStartingLineNumber;
            this.TargetLineNumber = targetLineNumber;
            this.EndingLineNumber = calculatedEndingLineNumber;

            return allCodeLines;
        }

        private void setCode(List<String> allCodeLines) {
            List<String> snippetCodeLines = new List<String>();
            for (Integer targetLineNumber = this.startingLineNumber; targetLineNumber <= this.endingLineNumber; targetLineNumber++) {
                // Code lines start with 1, but indexes in arrays start with 0
                Integer targetLineNumberIndex = targetLineNumber - 1;
                snippetCodeLines.add(allCodeLines.get(targetLineNumberIndex));
            }

            this.Code = String.join(snippetCodeLines, '\n');
        }
    }

    // Helper classes that are used to apply field values for each entry's related Schema.ApexClass or Schema.ApexTrigger
    @SuppressWarnings('PMD.ApexDoc')
    private abstract class ApexMetadataFieldApplier {
        public abstract void apply(LogEntry__c logEntry, Schema.ApexClass topLevelApexClass);
        public abstract void apply(LogEntry__c logEntry, Schema.ApexTrigger apexTrigger);
    }

    @SuppressWarnings('PMD.ApexDoc')
    private class ExceptionApexMetadataFieldApplier extends ApexMetadataFieldApplier {
        public override void apply(LogEntry__c logEntry, Schema.ApexClass apexClass) {
            if (apexClass == null) {
                return;
            }

            logEntry.ExceptionSourceApiVersion__c = 'v' + apexClass.ApiVersion;
            logEntry.ExceptionSourceCreatedById__c = apexClass.CreatedById;
            logEntry.ExceptionSourceCreatedByUsername__c = apexClass.CreatedBy.Username;
            logEntry.ExceptionSourceCreatedDate__c = apexClass.CreatedDate;
            logEntry.ExceptionSourceId__c = apexClass.Id;
            logEntry.ExceptionSourceLastModifiedById__c = apexClass.LastModifiedById;
            logEntry.ExceptionSourceLastModifiedByUsername__c = apexClass.LastModifiedBy.Username;
            logEntry.ExceptionSourceLastModifiedDate__c = apexClass.LastModifiedDate;

            LoggerStackTrace exceptionStackTrace = new LoggerStackTrace(logEntry.ExceptionStackTrace__c);
            logEntry.ExceptionSourceSnippet__c = JSON.serializePretty(new SourceMetadataSnippet(exceptionStackTrace, apexClass));
        }

        public override void apply(LogEntry__c logEntry, Schema.ApexTrigger apexTrigger) {
            if (apexTrigger == null) {
                return;
            }

            logEntry.ExceptionSourceApiVersion__c = 'v' + apexTrigger.ApiVersion;
            logEntry.ExceptionSourceCreatedById__c = apexTrigger.CreatedById;
            logEntry.ExceptionSourceCreatedByUsername__c = apexTrigger.CreatedBy.Username;
            logEntry.ExceptionSourceCreatedDate__c = apexTrigger.CreatedDate;
            logEntry.ExceptionSourceId__c = apexTrigger.Id;
            logEntry.ExceptionSourceLastModifiedById__c = apexTrigger.LastModifiedById;
            logEntry.ExceptionSourceLastModifiedByUsername__c = apexTrigger.LastModifiedBy.Username;
            logEntry.ExceptionSourceLastModifiedDate__c = apexTrigger.LastModifiedDate;

            LoggerStackTrace exceptionStackTrace = new LoggerStackTrace(logEntry.ExceptionStackTrace__c);
            logEntry.ExceptionSourceSnippet__c = JSON.serializePretty(new SourceMetadataSnippet(exceptionStackTrace, apexTrigger));
        }
    }

    @SuppressWarnings('PMD.ApexDoc')
    private class OriginApexMetadataFieldApplier extends ApexMetadataFieldApplier {
        public override void apply(LogEntry__c logEntry, Schema.ApexClass apexClass) {
            if (apexClass == null) {
                return;
            }

            LoggerStackTrace originStackTrace = new LoggerStackTrace(logEntry.StackTrace__c);

            // Older Schema.ApexClass-specific fields
            logEntry.ApexClassApiVersion__c = 'v' + apexClass.ApiVersion;
            logEntry.ApexClassCreatedDate__c = apexClass.CreatedDate;
            logEntry.ApexClassId__c = apexClass.Id;
            logEntry.ApexClassLastModifiedDate__c = apexClass.LastModifiedDate;
            if (originStackTrace.Source.MetadataType == LoggerStackTrace.SourceMetadataType.ApexClass) {
                logEntry.ApexClassName__c = originStackTrace.Source.ApiName;
                // TODO need to revisit how to best handle ApexInnerClassName__c
                // logEntry.ApexInnerClassName__c = originStackTraceApexClass?.InnerClassName;
                logEntry.ApexMethodName__c = originStackTrace.Source.ActionName;
            }

            // Newer, general-purpose 'origin source' fields
            logEntry.OriginSourceActionName__c = originStackTrace.Source.ActionName;
            logEntry.OriginSourceApiVersion__c = 'v' + apexClass.ApiVersion;
            logEntry.OriginSourceCreatedById__c = apexClass.CreatedById;
            logEntry.OriginSourceCreatedByUsername__c = apexClass.CreatedBy.Username;
            logEntry.OriginSourceCreatedDate__c = apexClass.CreatedDate;
            logEntry.OriginSourceId__c = apexClass.Id;
            logEntry.OriginSourceLastModifiedById__c = apexClass.LastModifiedById;
            logEntry.OriginSourceLastModifiedByUsername__c = apexClass.LastModifiedBy.Username;
            logEntry.OriginSourceLastModifiedDate__c = apexClass.LastModifiedDate;
            logEntry.OriginSourceSnippet__c = JSON.serializePretty(new SourceMetadataSnippet(originStackTrace, apexClass));
        }

        public override void apply(LogEntry__c logEntry, Schema.ApexTrigger apexTrigger) {
            if (apexTrigger == null) {
                return;
            }

            LoggerStackTrace originStackTrace = new LoggerStackTrace(logEntry.StackTrace__c);

            // Currently, there aren't any Schema.ApexTrigger-specific fields on LogEntry__c,
            // so only set the newer, general-purpose 'origin source' fields
            logEntry.OriginSourceApiVersion__c = 'v' + apexTrigger.ApiVersion;
            logEntry.OriginSourceCreatedById__c = apexTrigger.CreatedById;
            logEntry.OriginSourceCreatedByUsername__c = apexTrigger.CreatedBy.Username;
            logEntry.OriginSourceCreatedDate__c = apexTrigger.CreatedDate;
            logEntry.OriginSourceId__c = apexTrigger.Id;
            logEntry.OriginSourceLastModifiedById__c = apexTrigger.LastModifiedById;
            logEntry.OriginSourceLastModifiedByUsername__c = apexTrigger.LastModifiedBy.Username;
            logEntry.OriginSourceLastModifiedDate__c = apexTrigger.LastModifiedDate;
            logEntry.OriginSourceSnippet__c = JSON.serializePretty(new SourceMetadataSnippet(originStackTrace, apexTrigger));
        }
    }
}
