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
        List<String> apexClassNames = new List<String>();
        List<LogEntry__c> apexLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (logEntry.OriginType__c == 'Apex' && String.isNotBlank(logEntry.OriginLocation__c)) {
                // OriginLocation__c contains the class name + method name. Examples:
                // MyClass.someMethod
                // MyClass.MyInnerClass.someMethod
                String apexClassName = logEntry.OriginLocation__c.substringBefore('.');
                apexClassNames.add(apexClassName);
                apexLogEntries.add(logEntry);
            }
        }

        if (apexClassNames.isEmpty()) {
            return;
        }

        Map<String, ApexClass> classNameToApexClass = new Map<String, ApexClass>();
        for (ApexClass apexClass : LogManagementDataSelector.getInstance().getApexClasses(apexClassNames)) {
            classNameToApexClass.put(apexClass.Name, apexClass);
        }

        if (classNameToApexClass.isEmpty()) {
            return;
        }

        for (LogEntry__c logEntry : apexLogEntries) {
            String topLevelApexClassName = logEntry.OriginLocation__c?.substringBefore('.');
            ApexClass topLevelApexClass = classNameToApexClass.get(topLevelApexClassName);
            if (topLevelApexClass == null) {
                continue;
            }

            String methodName = logEntry.OriginLocation__c.substringAfterLast('.');
            String innerApexClassName = logEntry.OriginLocation__c.substringAfter(topLevelApexClassName + '.').substringBeforeLast('.');
            if (innerApexClassName == topLevelApexClassName || innerApexClassName == methodName) {
                innerApexClassName = null;
            } else if (innerApexClassName.startsWith(topLevelApexClassName + '.')) {
                innerApexClassName = innerApexClassName.substringAfter(topLevelApexClassName + '.');
            }

            logEntry.ApexClassApiVersion__c = 'v' + topLevelApexClass.ApiVersion;
            logEntry.ApexClassCreatedDate__c = topLevelApexClass.CreatedDate;
            logEntry.ApexClassId__c = topLevelApexClass.Id;
            logEntry.ApexClassLastModifiedDate__c = topLevelApexClass.LastModifiedDate;
            logEntry.ApexClassName__c = topLevelApexClassName;
            logEntry.ApexInnerClassName__c = innerApexClassName;
            logEntry.ApexMethodName__c = methodName;
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
            if (logEntry.OriginType__c == 'Flow' && String.isNotBlank(logEntry.OriginLocation__c)) {
                flowApiNames.add(logEntry.OriginLocation__c);
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
            FlowDefinitionView flowDefinition = flowApiNameToDefinition.get(logEntry.OriginLocation__c);
            if (flowDefinition == null) {
                continue;
            }

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
        }
    }

    private void setFlowVersionFields() {
        List<String> flowActiveVersionIds = new List<String>();
        List<LogEntry__c> flowLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (logEntry.OriginType__c == 'Flow' && String.isNotBlank(logEntry.FlowActiveVersionId__c)) {
                flowActiveVersionIds.add(logEntry.FlowActiveVersionId__c);
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

            logEntry.FlowVersionApiVersionRuntime__c = 'v' + flowVersionView.ApiVersionRuntime + '.0';
            logEntry.FlowVersionRunInMode__c = flowVersionView.RunInMode;
            logEntry.FlowVersionNumber__c = flowVersionView.VersionNumber;
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
            logEntry.HasExceptionStackTrace__c = logEntry.ExceptionStackTrace__c != null;
            logEntry.HasHttpRequestBody__c = logEntry.HttpRequestBody__c != null;
            logEntry.HasHttpResponseBody__c = logEntry.HttpResponseBody__c != null;
            logEntry.HasHttpResponseHeaderKeys__c = logEntry.HttpResponseHeaderKeys__c != null;
            logEntry.HasHttpResponseHeaders__c = logEntry.HttpResponseHeaders__c != null;
            logEntry.HasInlineTags__c = logEntry.Tags__c != null;
            logEntry.HasRecordJson__c = logEntry.RecordJson__c != null;
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
}
