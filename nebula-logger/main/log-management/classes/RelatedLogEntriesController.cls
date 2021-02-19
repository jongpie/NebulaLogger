public with sharing class RelatedLogEntriesController {
    private static final SObjectType LOG_ENTRY_SOBJECT_TYPE = Schema.LogEntry__c.SObjectType;

    @AuraEnabled(cacheable=true)
    public static FieldSetMetadata getFieldSetMetadata(String fieldSetName) {
        // TODO
        System.debug('getFieldSetMetadata(String fieldSetName)');
        System.debug('fieldSetName==' + fieldSetName);

        //SObjectType sobjectType = Schema.getGlobalDescribe().get(sobjectName);

        FieldSetMetadata fieldSetMetdata = new FieldSetMetadata(LOG_ENTRY_SOBJECT_TYPE, fieldSetName);

        System.debug('fieldSetMetdata==' + fieldSetMetdata);

        return fieldSetMetdata;
    }

    @AuraEnabled(cacheable=true)
    public static List<LogEntry__c> getRelatedLogEntries(Id recordId, String fieldSetName, Integer rowLimit) {
        FieldSetMetadata fieldSetMetdata = new FieldSetMetadata(LOG_ENTRY_SOBJECT_TYPE, fieldSetName);
        List<String> fieldNames = new List<String>();
        for (FieldMetadata fieldMetadata : fieldSetMetdata.fields) {
            fieldNames.add(fieldMetadata.fieldName);
        }

        String logEntryQuery = 'SELECT {0} FROM LogEntry__c WHERE RecordId__c = :recordId ORDER BY Timestamp__c DESC LIMIT :rowLimit';
        logEntryQuery = String.format(logEntryQuery, new List<Object>{ String.join(fieldNames, ',') });

        SObjectAccessDecision securityDecision = Security.stripInaccessible(
            AccessType.READABLE,
            Database.query(logEntryQuery)
        );
        if (securityDecision.getRecords().isEmpty()) {
            return null;
        } else {
            return (List<LogEntry__c>) securityDecision.getRecords();
        }
    }

    public class FieldSetMetadata {
        @AuraEnabled
        public List<FieldMetadata> fields { get; set; }

        //private String fieldSetName;

        public FieldSetMetadata(SObjectType sobjectType, String fieldSetName) {
            //this.fieldSetName = fieldSetName;
            this.fields = new List<FieldMetadata>();

            System.debug('FieldSetMetadata(SObjectType sobjectType, String fieldSetName)');
            System.debug('sobjectType==' + sobjectType);
            System.debug('fieldSetName==' + fieldSetName);

            Schema.FieldSet fieldSet = sobjectType.getDescribe().fieldSets.getMap().get(fieldSetName);

            for (FieldSetMember fieldSetMember : fieldSet.getFields()) {
                this.fields.add(new FieldMetadata(fieldSetMember));
            }
        }
    }

    public class FieldMetadata {
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String fieldName { get; set; }

        public FieldMetadata(FieldSetMember fieldSetMember) {
            this.label = fieldSetMember.getLabel();
            this.fieldName = fieldSetMember.getFieldPath();
        }
    }
}
