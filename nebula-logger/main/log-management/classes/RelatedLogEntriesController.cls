//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group log-management
 * @description Controller class for the component RelatedLogEntries
 */
public with sharing class RelatedLogEntriesController {
    private static final SObjectType LOG_SOBJECT_TYPE = Schema.Log__c.SObjectType;
    private static final SObjectType LOG_ENTRY_SOBJECT_TYPE = Schema.LogEntry__c.SObjectType;

    @AuraEnabled(cacheable=true) //FIXME don't cache this, but need to change lwc call
    public static LogEntryResult getRelatedLogEntries(
        Id recordId,
        String fieldSetName,
        Integer rowLimit,
        String sortByFieldName,
        String sortDirection,
        String search
    ) {
        FieldSetMetadata fieldSetMetdata = new FieldSetMetadata(LOG_ENTRY_SOBJECT_TYPE, fieldSetName);
        List<String> fieldNames = new List<String>();
        for (FieldMetadata fieldMetadata : fieldSetMetdata.fields) {
            fieldNames.add(fieldMetadata.fieldName);

            // For lookups, also include the display name of parent object
            if(fieldMetadata.displayFieldName != null) {
                fieldNames.add(fieldMetadata.displayFieldName);
            }
        }

        // Handle null parameter values
        sortByFieldName = String.isNotBlank(sortByFieldName)
            ? sortByFieldName
            : String.valueOf(Schema.LogEntry__c.Timestamp__c);
        sortDirection = String.isNotBlank(sortDirection) ? sortDirection : 'DESC';


        String fieldsClause = String.join(fieldNames, ',');
        String whereClause = String.valueOf(Schema.LogEntry__c.RecordId__c) + ' = :recordId';
        String orderByClause = sortByFieldName + ' ' + sortDirection;

        List<LogEntry__c> records;
        if(String.isNotBlank(search) && search.length() > 3) {
            records = search(recordId, search, fieldsClause, orderByClause, rowLimit);
        } else {
            records = query(recordId, fieldsClause, orderByClause, rowLimit);
        }

        Integer totalEntriesCountForRecordId = [SELECT COUNT() FROM LogEntry__c WHERE RecordId__c = :recordId];

        return new LogEntryResult(fieldSetMetdata, records, totalEntriesCountForRecordId);
    }


    private static List<LogEntry__c> search(Id recordId, String searchTerm, String fieldsClause, String orderByClause, Integer rowLimit) {
        searchTerm = String.escapeSingleQuotes(searchTerm);

        List<Object> searchTextReplacements = new List<Object>{
            '\'*' + searchTerm + '*\'',
            String.valueOf(Schema.LogEntry__c.SObjectType),
            fieldsClause,
            String.valueOf(Schema.LogEntry__c.RecordId__c),
            orderByClause,
            rowLimit
        };
        String logEntrySearch = 'FIND {0} IN ALL FIELDS RETURNING {1}({2} WHERE {3} = :recordId ORDER BY {4} LIMIT {5})';
        logEntrySearch = String.format(logEntrySearch, searchTextReplacements);
        System.debug('logEntrySearch==' + logEntrySearch);

        SObjectAccessDecision securityDecision = Security.stripInaccessible(
            AccessType.READABLE,
            Search.query(logEntrySearch).get(0)
        );
        return (List<LogEntry__c>) securityDecision.getRecords();
    }

    private static List<LogEntry__c> query(Id recordId, String fieldsClause, String orderByClause, Integer rowLimit) {
        List<Object> queryTextReplacements = new List<Object>{
            fieldsClause,
            String.valueOf(Schema.LogEntry__c.SObjectType),
            String.valueOf(Schema.LogEntry__c.RecordId__c),
            orderByClause,
            rowLimit
        };
        String logEntryQuery = 'SELECT {0} FROM {1} WHERE {2} = :recordId ORDER BY {3} LIMIT {4}';
        logEntryQuery = String.escapeSingleQuotes(String.format(logEntryQuery, queryTextReplacements));
        System.debug('logEntryQuery==' + logEntryQuery);

        // Somewhat redudant security check for FLS (but extra security > less security)
        SObjectAccessDecision securityDecision = Security.stripInaccessible(
            AccessType.READABLE,
            Database.query(logEntryQuery)
        );
        return (List<LogEntry__c>) securityDecision.getRecords();
    }

    public class LogEntryResult {
        @AuraEnabled
        public FieldSetMetadata fieldSet { get; set; }
        @AuraEnabled
        public List<LogEntry__c> records { get; set; }
        @AuraEnabled
        public Boolean isAccessible { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String labelPlural { get; set; }
        @AuraEnabled
        public String tabIcon { get; set; }
        @AuraEnabled
        public Integer totalEntries { get; set; }

        private LogEntryResult(FieldSetMetadata fieldSetMetadata, List<LogEntry__c> records, Integer totalEntriesCountForRecordId) {
            this.fieldSet = fieldSetMetadata;
            this.records = records;
            this.isAccessible = LOG_ENTRY_SOBJECT_TYPE.getDescribe().isAccessible();
            this.label = LOG_ENTRY_SOBJECT_TYPE.getDescribe().getLabel();
            this.labelPlural = LOG_ENTRY_SOBJECT_TYPE.getDescribe().getLabelPlural();
            this.tabIcon = getTabIcon(LOG_SOBJECT_TYPE);
            this.totalEntries = totalEntriesCountForRecordId;
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
        public String displayFieldName { get; set; }
        @AuraEnabled
        public Boolean sortable { get; set; }
        @AuraEnabled
        public String type { get; set; }

        public FieldMetadata(FieldSetMember fieldSetMember) {
            Schema.DescribeFieldResult fieldDescribe = fieldSetMember.getSObjectField().getDescribe();

            this.isNameField = fieldDescribe.isNameField();
            this.label = fieldSetMember.getLabel();
            this.fieldName = fieldSetMember.getFieldPath();
            this.sortable = fieldDescribe.isSortable();
            this.type = fieldDescribe.getType().name().toLowerCase();

            if(fieldDescribe.getReferenceTo().size() == 1) {
                this.displayFieldName = getDisplayFieldApiName(fieldDescribe.getReferenceTo().get(0));
            }
        }
    }

    // Private static helper methods
    private static String getDisplayFieldApiName(Schema.SObjectType sobjectType) {
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

        String relationshipName = sobjectType.getDescribe().getName().replace('__c', '__r');
        return relationshipName + '.' + displayFieldApiName;
    }

    private static String getTabIcon(Schema.SObjectType sobjectType) {
        String sobjectName = sobjectType.getDescribe().getName();

        String tabIcon;
        for(Schema.DescribeTabSetResult tabSetResult : Schema.describeTabs()) {
            if(tabIcon != null) break;

            for(Schema.DescribeTabResult tabResult : tabSetResult.getTabs()) {
                if(tabIcon != null) break;
                if(tabResult.getSObjectName() != sobjectName) continue;

                String iconType = tabResult.isCustom() ? 'custom' : 'standard';
                String svgIconName;
                for(Schema.DescribeIconResult icon : tabResult.getIcons()) {
                    if(icon.getContentType() != 'image/svg+xml') continue;

                    svgIconName = icon.getUrl().substringAfterLast('/').replace('.svg', '');
                    tabIcon = iconType + ':' + svgIconName;
                    break;
                }
            }
        }
        // Hardcoded exceptions - Salesforce doesn't return SVGs for these objects, so hardcoding is necessary
        if(tabIcon == null && sobjectName == 'Asset') tabIcon = 'standard:maintenance_asset';
        if(tabIcon == null && sobjectName == 'AssetRelationship') tabIcon = 'standard:asset_relationship';

        return tabIcon;
    }
}
