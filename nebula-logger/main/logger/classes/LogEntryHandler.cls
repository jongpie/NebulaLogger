/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
public without sharing class LogEntryHandler {
    public void execute() {
        if (Trigger.operationType != TriggerOperation.BEFORE_INSERT) {
            return;
        }

        List<LogEntry__c> logEntries = (List<LogEntry__c>) Trigger.new;
        this.setBooleanCheckFields(logEntries);
        this.setRelatedRecordNames(logEntries);
    }

    private void setBooleanCheckFields(List<LogEntry__c> logEntries) {
        // A formula field can't be used for checking if a long text area field is set/null
        // So, this code handles maintaing some checkbox fields via Apex instead
        for (LogEntry__c logEntry : logEntries) {
            logEntry.HasExceptionStackTrace__c = logEntry.ExceptionStackTrace__c != null;
            logEntry.HasRelatedRecordJson__c = logEntry.RelatedRecordJson__c != null;
            logEntry.HasStackTrace__c = logEntry.StackTrace__c != null;
        }
    }

    private void setRelatedRecordNames(List<LogEntry__c> logEntries) {
        // Assumption - only valid record IDs will be populated in LogEntry__c.RelatedRecordId__c
        // If that changes, then extra checks may be needed before casting to Id, using getSObjectType(), etc.

        // 1. Figure out which SObjects & record IDs to query
        Map<Schema.SObjectType, List<Id>> sobjectTypeToRecords = new Map<Schema.SObjectType, List<Id>>();
        for (LogEntry__c logEntry : logEntries) {
            // Skip the log entry if there's no related record ID
            if (logEntry.RelatedRecordId__c == null) {
                continue;
            }

            // Based on the related record ID, get the SObject Type
            Id relatedRecordId = (Id) logEntry.RelatedRecordId__c;
            Schema.SObjectType sobjectType = relatedRecordId.getSObjectType();

            List<Id> sobjectTypeRecordIds = sobjectTypeToRecords.get(sobjectType);
            if (sobjectTypeRecordIds == null) {
                sobjectTypeRecordIds = new List<Id>();
            }
            sobjectTypeRecordIds.add(relatedRecordId);
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
        for (LogEntry__c logEntry : logEntries) {
            // Skip the log entry if there's no related record ID
            if (logEntry.RelatedRecordId__c == null) {
                continue;
            }

            Id relatedRecordId = (Id) logEntry.RelatedRecordId__c;
            Schema.SObjectType sobjectType = relatedRecordId.getSObjectType();

            logEntry.RelatedRecordSObject__c = String.valueOf(sobjectType);

            String sobjectDisplayFieldName = this.getDisplayFieldApiName(sobjectType);

            if (sobjectDisplayFieldName == null) {
                continue;
            }

            String recordName = (String) recordIdToRecord.get(logEntry.RelatedRecordId__c).get(sobjectDisplayFieldName);
            logEntry.RelatedRecordName__c = recordName;
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
