public with sharing class RelatedLogEntriesController {
    private static final SObjectType LOG_ENTRY_SOBJECT_TYPE = Schema.LogEntry__c.SObjectType;

    @AuraEnabled(cacheable=true)
    public static FieldSetMetadata getFieldSetMetadata(String fieldSetName) {
        return new FieldSetMetadata(LOG_ENTRY_SOBJECT_TYPE, fieldSetName);
    }

    @AuraEnabled(cacheable=true)
    public static List<LogEntry__c> getRelatedLogEntries(Id recordId, String fieldSetName, String sortByFieldName, String sortDirection, Integer rowLimit) {
        FieldSetMetadata fieldSetMetdata = new FieldSetMetadata(LOG_ENTRY_SOBJECT_TYPE, fieldSetName);
        List<String> fieldNames = new List<String>();
        for (FieldMetadata fieldMetadata : fieldSetMetdata.fields) {
            fieldNames.add(fieldMetadata.fieldName);
        }

        List<Object> queryTextReplacements = new List<Object>{
            String.join(fieldNames, ','),
            String.valueOf(Schema.LogEntry__c.SObjectType),
            String.valueOf(Schema.LogEntry__c.RecordId__c),
            sortByFieldName,
            sortDirection,
            rowLimit
        };

        String logEntryQuery = 'SELECT {0} FROM {1} WHERE {2} = :recordId ORDER BY {3} {4} LIMIT {5}';
        logEntryQuery = String.escapeSingleQuotes(String.format(logEntryQuery, queryTextReplacements));
        System.debug('logEntryQuery==' + logEntryQuery);

        SObjectAccessDecision securityDecision = Security.stripInaccessible(
            AccessType.READABLE,
            Database.query(logEntryQuery)
        );
        return (List<LogEntry__c>) securityDecision.getRecords();
    }

    public class FieldSetMetadata {
        @AuraEnabled
        public List<FieldMetadata> fields { get; set; }

        public FieldSetMetadata(SObjectType sobjectType, String fieldSetName) {
            this.fields = new List<FieldMetadata>();

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
        @AuraEnabled
        public Boolean sortable { get; set; }

        public FieldMetadata(FieldSetMember fieldSetMember) {
            // TODO add support for display types (especially to handle lookup fields & html formula fields)
            this.label = fieldSetMember.getLabel();
            this.fieldName = fieldSetMember.getFieldPath();
            this.sortable = true; // FIXME make this more intelligent, some fields can't be sorted
        }
    }
}
