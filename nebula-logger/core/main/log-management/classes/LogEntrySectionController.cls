public without sharing class LogEntrySectionController {
    @AuraEnabled(cacheable=true)
    public static LogEntryContext getLogEntry(Id logEntryId, Boolean showUnmaskedData) {
        // TODO pass boolean from LWC, then default to false
        if (showUnmaskedData == null) {
            showUnmaskedData = true;
        }

        Logger.info('running controller method for id', logEntryId);
        LogEntry__c logEntry = [
            SELECT
                ApexClassId__c,
                ApexClassName__c,
                ExceptionApexClassName__c,
                ExceptionApexClassSnippet__c,
                FlowActiveVersionId__c,
                Id,
                OriginType__c,
                RecordCollectionType__c,
                RecordJson__c,
                Timestamp__c
            FROM LogEntry__c
            WHERE Id = :logEntryId
        ];
        Logger.info('found matching record', logEntry);
        Logger.saveLog();

        LogEntryContext context = new LogEntryContext();
        context.logEntry = logEntry;
        context.logEntryTags = [SELECT Id, Tag__c, Tag__r.IconName__c, Tag__r.Name FROM LogEntryTag__c WHERE LogEntry__c = :logEntry.Id];
        context.permissionAccess = [SELECT id, PermissionsAuthorApex FROM UserPermissionAccess];

        if (logEntry.ExceptionApexClassSnippet__c != null) {
            context.exceptionApexClassSnippet = (Map<String, Object>) System.JSON.deserializeUntyped(logEntry.ExceptionApexClassSnippet__c);
        }
        // TODO consolidate queries
        if (logEntry.ApexClassId__c != null) {
            context.loggingApexClass = [
                SELECT Id, Body, LastModifiedBy.Name, LastModifiedBy.Username, LastModifiedDate
                FROM ApexClass
                WHERE Id = :logEntry.ApexClassId__c
            ];
        }
        if (logEntry.ExceptionApexClassName__c != null) {
            context.exceptionApexClass = [
                SELECT Id, Body, LastModifiedBy.Name, LastModifiedBy.Username, LastModifiedDate
                FROM ApexClass
                WHERE Name = :logEntry.ExceptionApexClassName__c
            ];
        }

        context.relatedRecords = getRelatedRecords(logEntry, showUnmaskedData);

        return context;
    }

    private static List<SObject> getRelatedRecords(LogEntry__c logEntry, Boolean showUnmaskedData) {
        if (logEntry.RecordJson__c == null) {
            return null;
            // return new List<SObject>();
        }

        // TODO 1. Optionally apply data masking rules to JSON string
        List<SObject> relatedRecords = parseRecordJson(logEntry);
        // TODO 2. Strip inaccessible fields on relatedRecords before returning
        return relatedRecords;
    }

    private static List<SObject> parseRecordJson(LogEntry__c logEntry) {
        switch on logEntry.RecordCollectionType__c {
            when 'Single' {
                SObject relatedRecord = (SObject) JSON.deserialize(logEntry.RecordJson__c, SObject.class);
                return new List<SObject>{ relatedRecord };
            }
            when 'List' {
                return (List<SObject>) JSON.deserialize(logEntry.RecordJson__c, List<SObject>.class);
            }
            when 'Map' {
                Map<Id, SObject> relatedRecordIdToRelatedRecord = (Map<Id, SObject>) JSON.deserialize(logEntry.RecordJson__c, Map<Id, SObject>.class);
                return relatedRecordIdToRelatedRecord.values();
            }
            when else {
                return null;
            }
        }
    }

    public class LogEntryContext {
        @AuraEnabled
        public LogEntry__c logEntry;
        @AuraEnabled
        public List<LogEntryTag__c> logEntryTags;
        @AuraEnabled
        public ApexClass exceptionApexClass;
        @AuraEnabled
        public Map<String, Object> exceptionApexClassSnippet;
        @AuraEnabled
        public ApexClass loggingApexClass;
        @AuraEnabled
        public UserPermissionAccess permissionAccess;
        @AuraEnabled
        public List<SObject> relatedRecords;

        public LogEntryContext() {
            // public LogEntryContext(LogEntry__c logEntry) {
            // this.logEntry = logEntry;
            // this.permissionAccess = [select id, PermissionsAuthorApex FROM UserPermissionAccess];

            // this.exceptionApexClassSnippet = (Map<String, Object>) System.JSON.deserializeUntyped(logEntry.ExceptionApexClassSnippet__c);
            // // TODO consolidate queries
            // if (this.logEntry.ApexClassId__c != null) {
            //     this.loggingApexClass = [SELECT Id, Body, LastModifiedBy.Name, LastModifiedBy.Username, LastModifiedDate FROM ApexClass WHERE Id = :this.logEntry.ApexClassId__c];
            // }
            // if (this.logEntry.ExceptionApexClassName__c != null) {
            //     this.exceptionApexClass = [SELECT Id, Body, LastModifiedBy.Name, LastModifiedBy.Username, LastModifiedDate FROM ApexClass WHERE Name = :this.logEntry.ExceptionApexClassName__c];
            // }
        }
    }
}
