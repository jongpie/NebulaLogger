//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group log-management
 * @description Controller class for the component RelatedLogEntries
 */
public with sharing class RelatedLogEntriesController {
    private static final SObjectType LOG_ENTRY_SOBJECT_TYPE = Schema.LogEntry__c.SObjectType;

    // @AuraEnabled(cacheable=true)
    // public static FieldSetMetadata getMetadata(String fieldSetName) {
    //     return new FieldSetMetadata(LOG_ENTRY_SOBJECT_TYPE, fieldSetName);
    // }

    @AuraEnabled(cacheable=true) //FIXME don't cache this, but need to change lwc call
    public static LogEntryResult getRelatedLogEntries(
        Id recordId,
        String fieldSetName,
        Integer rowLimit,
        String sortByFieldName,
        String sortDirection,
        String searchTerm
    ) {
        //System.assert(false, 'expected failure');
        System.debug('searchTerm==' + searchTerm);

        FieldSetMetadata fieldSetMetdata = new FieldSetMetadata(LOG_ENTRY_SOBJECT_TYPE, fieldSetName);
        List<String> fieldNames = new List<String>();
        for (FieldMetadata fieldMetadata : fieldSetMetdata.fields) {
            fieldNames.add(fieldMetadata.fieldName);
        }

        // Handle null parameter values
        sortByFieldName = String.isNotBlank(sortByFieldName)
            ? sortByFieldName
            : String.valueOf(Schema.LogEntry__c.Timestamp__c);
        sortDirection = String.isNotBlank(sortDirection) ? sortDirection : 'DESC';

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

        // Somewhat redudant security check for FLS (but extra security > less security)
        SObjectAccessDecision securityDecision = Security.stripInaccessible(
            AccessType.READABLE,
            Database.query(logEntryQuery)
        );
        List<LogEntry__c> records = (List<LogEntry__c>) securityDecision.getRecords();

        return new LogEntryResult(fieldSetMetdata, records);
    }

    public class LogEntryResult {
        @AuraEnabled
        public FieldSetMetadata fieldSet { get; set; }
        @AuraEnabled
        public List<LogEntry__c> records { get; set; }
        @AuraEnabled
        public Boolean sobjectIsAccessible { get; set; }

        private LogEntryResult(FieldSetMetadata fieldSetMetadata, List<LogEntry__c> records) {
            this.fieldSet = fieldSetMetadata;
            this.records = records;
            this.sobjectIsAccessible = LOG_ENTRY_SOBJECT_TYPE.getDescribe().isAccessible();
        }
    }

    public class FieldSetMetadata {
        @AuraEnabled
        public List<FieldMetadata> fields { get; set; }

        public FieldSetMetadata(SObjectType sobjectType, String fieldSetName) {
            this.fields = new List<FieldMetadata>();

            Schema.FieldSet fieldSet = sobjectType.getDescribe().fieldSets.getMap().get(fieldSetName);
            for (FieldSetMember fieldSetMember : fieldSet.getFields()) {
                // Enforce field-level security (FLS)
                if (fieldSetMember.getSObjectField().getDescribe().isAccessible()) {
                    this.fields.add(new FieldMetadata(fieldSetMember));
                }
            }
        }
    }

    public class FieldMetadata {
        @AuraEnabled
        public Boolean isNameField { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String fieldName { get; set; }
        @AuraEnabled
        public Boolean sortable { get; set; }
        @AuraEnabled
        public String type { get; set; }

        public FieldMetadata(FieldSetMember fieldSetMember) {
            this.isNameField = fieldSetMember.getSObjectField().getDescribe().isNameField();
            this.label = fieldSetMember.getLabel();
            this.fieldName = fieldSetMember.getFieldPath();
            this.sortable = fieldSetMember.getSObjectField().getDescribe().isSortable();
            this.type = fieldSetMember.getSObjectField().getDescribe().getType().name();
        }
    }
}
