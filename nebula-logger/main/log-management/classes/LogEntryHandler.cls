//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Manages setting fields on `LogEntry__c` before insert & before update
 */
public without sharing class LogEntryHandler extends LoggerSObjectHandler {
    // Trigger-based variables - tests can override these with mock objects
    @TestVisible
    private List<LogEntry__c> logEntries {
        get {
            return (List<LogEntry__c>) this.triggerNew;
        }
    }

    public LogEntryHandler() {
    }

    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override SObjectType getSObjectType() {
        return Schema.LogEntry__c.SObjectType;
    }

    /**
     * @description Runs the trigger handler's logic for the `LogEntry__c` custom object
     */
    public override void execute() {
        if (this.isEnabled() == false) {
            return;
        }

        switch on this.triggerOperationType {
            when BEFORE_INSERT {
                this.setCheckboxFields();
                this.setApexClassFields();
                this.setFlowDefinitionFields();
                this.setFlowVersionFields();
                this.setFlowInterviewFields();
                this.setRecordNames();
            }
            when BEFORE_UPDATE {
                // Realistically, these checkbox fields probably only need to be set on insert
                // but some admins & devs might decide to update/append data in some of the related fields
                // and it conceptually feels weird for there to be scenarios where these fields could be inaccurate,
                // so keep them up to date just to be safe
                this.setCheckboxFields();
            }
        }

        // Run any plugins configured in the LoggerSObjectHandlerPlugin__mdt custom metadata type
        this.executePlugins();
    }

    private void setCheckboxFields() {
        // A formula field can't be used for checking if a long text area field is set/null
        // So, this code handles maintaing some checkbox fields via Apex instead
        for (LogEntry__c logEntry : this.logEntries) {
            logEntry.HasExceptionStackTrace__c = logEntry.ExceptionStackTrace__c != null;
            logEntry.HasRecordJson__c = logEntry.RecordJson__c != null;
            logEntry.HasStackTrace__c = logEntry.StackTrace__c != null;
        }
    }

    private void setApexClassFields() {
        List<String> apexClassNames = new List<String>();
        List<LogEntry__c> apexLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (logEntry.OriginType__c == 'Apex') {
                // OriginLocation__c contains the class name + method name. Examples:
                // MyClass.someMethod
                // MyClass.MyInnerClass.someMethod
                String apexClassName = logEntry.OriginLocation__c.substringBefore('.');
                apexClassNames.add(apexClassName);
                apexLogEntries.add(logEntry);
            }
        }

        if (apexClassNames.isEmpty() == true) {
            return;
        }

        Map<String, ApexClass> classNameToApexClass = new Map<String, ApexClass>();
        for (ApexClass apexClass : [
            SELECT ApiVersion, CreatedById, CreatedDate, Id, LastModifiedById, LastModifiedDate, Name
            FROM ApexClass
            WHERE Name IN :apexClassNames
        ]) {
            classNameToApexClass.put(apexClass.Name, apexClass);
        }

        for (LogEntry__c logEntry : apexLogEntries) {
            String apexClassName = logEntry.OriginLocation__c.substringBefore('.');
            ApexClass apexClass = classNameToApexClass.get(apexClassName);
            if (apexClass == null) {
                continue;
            }

            logEntry.ApexClassApiVersion__c = 'v' + apexClass.ApiVersion;
            // TODO confirm if there any issues with automated users (e.g., PackagePushJob uses a not-quite-a-user)
            // logEntry.ApexClassCreatedById__c = apexClass.CreatedById;
            logEntry.ApexClassCreatedDate__c = apexClass.CreatedDate;
            logEntry.ApexClassId__c = apexClass.Id;
            // TODO confirm if there any issues with automated users (e.g., PackagePushJob uses a not-quite-a-user)
            // logEntry.ApexClassLastModifiedById__c = apexClass.LastModifiedById;
            logEntry.ApexClassLastModifiedDate__c = apexClass.LastModifiedDate;
        }
    }

    private void setFlowDefinitionFields() {
        List<String> flowApiNames = new List<String>();
        List<LogEntry__c> flowLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (logEntry.OriginType__c == 'Flow') {
                flowApiNames.add(logEntry.OriginLocation__c);
                flowLogEntries.add(logEntry);
            }
        }

        if (flowApiNames.isEmpty() == true) {
            return;
        }

        Map<String, FlowDefinitionView> flowApiNameToDefinition = new Map<String, FlowDefinitionView>();
        for (
            FlowDefinitionView flowDefinition : [
                SELECT
                    ActiveVersionId,
                    ApiName,
                    Description,
                    DurableId,
                    Label,
                    LastModifiedBy, // This is a text field of the person's name - it's NOT a lookup to User :'(
                    LastModifiedDate,
                    ManageableState,
                    ProcessType,
                    TriggerType
                FROM FlowDefinitionView
                WHERE ApiName IN :flowApiNames AND IsActive = TRUE
            ]
        ) {
            flowApiNameToDefinition.put(flowDefinition.ApiName, flowDefinition);
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
            logEntry.FlowTriggerType__c = flowDefinition.TriggerType;
        }
    }

    private void setFlowVersionFields() {
        List<String> flowActiveVersionIds = new List<String>();
        List<LogEntry__c> flowLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (String.isNotBlank(logEntry.FlowActiveVersionId__c)) {
                flowActiveVersionIds.add(logEntry.FlowActiveVersionId__c);
                flowLogEntries.add(logEntry);
            }
        }

        if (flowActiveVersionIds.isEmpty() == true) {
            return;
        }

        Map<String, FlowVersionView> flowDurableId = new Map<String, FlowVersionView>();
        for (FlowVersionView flowVersionView : [
            SELECT ApiVersionRuntime, FlowDefinitionViewId, RunInMode, Status, VersionNumber
            FROM FlowVersionView
            WHERE DurableId IN :flowActiveVersionIds
        ]) {
            // Filtering on Status in SOQL seems to always return 0 results, so filter in code instead
            if (flowVersionView.Status == 'Active') {
                flowDurableId.put(flowVersionView.FlowDefinitionViewId, flowVersionView);
            }
        }

        for (LogEntry__c logEntry : flowLogEntries) {
            FlowVersionView flowVersionView = flowDurableId.get(logEntry.FlowDurableId__c);
            if (flowVersionView == null) {
                continue;
            }

            logEntry.FlowVersionApiVersionRuntime__c = 'v' + flowVersionView.ApiVersionRuntime + '.0';
            logEntry.FlowVersionRunInMode__c = flowVersionView.RunInMode;
            logEntry.FlowVersionNumber__c = flowVersionView.VersionNumber;
        }
    }

    private void setFlowInterviewFields() {
        List<String> flowInterviewGuids = new List<String>();
        List<LogEntry__c> flowLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (String.isNotBlank(logEntry.FlowInterviewGuid__c)) {
                flowInterviewGuids.add(logEntry.FlowInterviewGuid__c);
                flowLogEntries.add(logEntry);
            }
        }

        if (flowInterviewGuids.isEmpty() == true) {
            return;
        }

        Map<String, FlowInterview> flowInterviewGuidToInterview = new Map<String, FlowInterview>();
        for (FlowInterview flowInterview : [SELECT CurrentElement, Guid, InterviewLabel, PauseLabel FROM FlowInterview WHERE Guid IN :flowInterviewGuids]) {
            flowInterviewGuidToInterview.put(flowInterview.Guid, flowInterview);
        }

        for (LogEntry__c logEntry : flowLogEntries) {
            FlowInterview flowInterview = flowInterviewGuidToInterview.get(logEntry.FlowDurableId__c);
            if (flowInterview == null) {
                continue;
            }

            logEntry.FlowInterviewCurrentElement__c = flowInterview.CurrentElement;
            logEntry.FlowInterviewLabel__c = flowInterview.InterviewLabel;
            logEntry.FlowInterviewPauseLabel__c = flowInterview.PauseLabel;
        }
    }

    private void setRecordNames() {
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

            // Based on the related record ID, get the SObject Type
            Id recordId = (Id) logEntry.RecordId__c;
            Schema.SObjectType sobjectType = recordId.getSObjectType();

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
            if (Limits.getQueries() == Limits.getLimitQueries()) {
                return;
            }
            List<Id> sobjectTypeRecordIds = sobjectTypeToRecords.get(sobjectType);
            String sobjectDisplayFieldName = this.getDisplayFieldApiName(sobjectType);

            if (sobjectDisplayFieldName == null) {
                continue;
            }

            String query = String.format(
                'SELECT Id, {0} FROM {1} WHERE Id IN :sobjectTypeRecordIds',
                new List<Object>{ sobjectDisplayFieldName, sobjectType, sobjectTypeRecordIds }
            );

            List<SObject> results = Database.query(query);
            recordIdToRecord.putAll(results);
        }

        // 3. Finally, save the record name on the log entry
        for (LogEntry__c logEntry : this.logEntries) {
            // Skip the log entry if there's no related record ID
            if (logEntry.RecordId__c == null) {
                continue;
            }

            Id recordId = (Id) logEntry.RecordId__c;
            Schema.SObjectType sobjectType = recordId.getSObjectType();

            String sobjectDisplayFieldName = this.getDisplayFieldApiName(sobjectType);
            if (sobjectDisplayFieldName != null) {
                if (recordIdToRecord.containsKey(logEntry.RecordId__c)) {
                    String recordName = (String) recordIdToRecord.get(logEntry.RecordId__c).get(sobjectDisplayFieldName);
                    logEntry.RecordName__c = recordName;
                }
            }
        }
    }

    private String getDisplayFieldApiName(Schema.SObjectType sobjectType) {
        // Use username instead of name for user
        if (sobjectType == Schema.User.SObjectType) {
            return Schema.User.Username.getDescribe().getName();
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
        for (String fieldName : educatedGuesses) {
            Schema.SObjectField field = sobjectType.getDescribe().fields.getMap().get(fieldName);

            if (field == null) {
                continue;
            }

            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            if (fieldDescribe.isNameField()) {
                displayFieldApiName = fieldDescribe.getName();
                break;
            }
        }

        return displayFieldApiName;
    }
}
