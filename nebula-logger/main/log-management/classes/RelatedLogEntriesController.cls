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
    private static final String DEFAULT_SORT_FIELD_NAME = String.valueOf(Schema.LogEntry__c.Timestamp__c);
    private static final String DEFAULT_SORT_DIRECTION = 'DESC';

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
            if (fieldMetadata.lookupDisplayFieldName != null) {
                fieldNames.add(fieldMetadata.lookupDisplayFieldName);
            }
        }

        // Handle null parameter values
        sortByFieldName = String.isNotBlank(sortByFieldName) ? sortByFieldName : DEFAULT_SORT_FIELD_NAME;
        sortDirection = String.isNotBlank(sortDirection) ? sortDirection : DEFAULT_SORT_DIRECTION;

        String fieldsClause = String.join(fieldNames, ',');
        String orderByClause = sortByFieldName + ' ' + sortDirection;

        List<LogEntry__c> records;
        if (String.isNotBlank(search) && search.length() >= 3) {
            records = search(recordId, search, fieldsClause, orderByClause, rowLimit);
        } else {
            records = query(recordId, fieldsClause, orderByClause, rowLimit);
        }

        // Somewhat redundant security check for FLS (but extra security > less security)
        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, records);
        records = securityDecision.getRecords();

        Integer totalLogEntriesCount = [SELECT COUNT() FROM LogEntry__c WHERE RecordId__c = :recordId];

        return new LogEntryResult(fieldSetMetdata, records, totalLogEntriesCount);
    }

    private static List<LogEntry__c> search(
        Id recordId,
        String searchTerm,
        String fieldsClause,
        String orderByClause,
        Integer rowLimit
    ) {
        searchTerm = '\'*' + String.escapeSingleQuotes(searchTerm) + '*\'';

        List<Object> searchTextReplacements = new List<Object>{
            searchTerm,
            String.valueOf(Schema.LogEntry__c.SObjectType),
            fieldsClause,
            String.valueOf(Schema.LogEntry__c.RecordId__c),
            orderByClause,
            rowLimit
        };
        String logEntrySearch = 'FIND {0} IN ALL FIELDS RETURNING {1}({2} WHERE {3} = :recordId ORDER BY {4} LIMIT {5})';
        logEntrySearch = String.format(logEntrySearch, searchTextReplacements);

        return (List<LogEntry__c>) Search.query(logEntrySearch).get(0);
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
        logEntryQuery = String.format(logEntryQuery, queryTextReplacements);

        return (List<LogEntry__c>) Database.query(logEntryQuery);
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
        public Integer totalLogEntriesCount { get; set; }

        private LogEntryResult(
            FieldSetMetadata fieldSetMetadata,
            List<LogEntry__c> records,
            Integer totalLogEntriesCount
        ) {
            this.fieldSet = fieldSetMetadata;
            this.records = records;
            this.isAccessible = LOG_ENTRY_SOBJECT_TYPE.getDescribe().isAccessible();
            this.label = LOG_ENTRY_SOBJECT_TYPE.getDescribe().getLabel();
            this.labelPlural = LOG_ENTRY_SOBJECT_TYPE.getDescribe().getLabelPlural();
            this.tabIcon = getTabIcon(LOG_SOBJECT_TYPE);
            this.totalLogEntriesCount = totalLogEntriesCount;
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
        public String lookupDisplayFieldName { get; set; }
        @AuraEnabled
        public Boolean sortable { get; set; }
        @AuraEnabled
        public String relationshipName { get; set; }
        @AuraEnabled
        public String type { get; set; }

        public FieldMetadata(FieldSetMember fieldSetMember) {
            Schema.DescribeFieldResult fieldDescribe = fieldSetMember.getSObjectField().getDescribe();

            this.isNameField = fieldDescribe.isNameField();
            this.label = fieldSetMember.getLabel();
            this.fieldName = fieldSetMember.getFieldPath();
            this.relationshipName = fieldDescribe.getRelationshipName();
            this.sortable = fieldDescribe.isSortable();
            this.type = fieldDescribe.getType().name().toLowerCase();
            if (fieldDescribe.getReferenceTo().size() == 1) {
                // Handle single-object (normal) lookups
                this.lookupDisplayFieldName = getDisplayFieldApiName(fieldDescribe);
            }
        }
    }

    // Private static helper methods
    private static String getDisplayFieldApiName(Schema.DescribeFieldResult lookupFieldDescribe) {
        String relationshipName = lookupFieldDescribe.getRelationshipName();
        SObjectType lookupSObjectType = lookupFieldDescribe.getReferenceTo().get(0);

        // Use username instead of name for user
        if (lookupSObjectType == Schema.User.SObjectType) {
            return relationshipName + '.' + Schema.User.Username.getDescribe().getName();
        }

        // There are several commonly used names for the display field name - typically, Name, but check for others
        List<String> educatedGuesses = new List<String>{
            'Name',
            'Title',
            'Subject',
            'AssetRelationshipNumber',
            'CaseNumber',
            'ContractNumber',
            'OrderItemNumber',
            'OrderNumber',
            'DeveloperName',
            'ApiName',
            'Domain',
            'FriendlyName',
            'FunctionName',
            'Label',
            'LocalPart',
            'SolutionName',
            'TestSuiteName'
        };

        String displayFieldApiName;
        for (String fieldName : educatedGuesses) {
            Schema.SObjectField field = lookupSObjectType.getDescribe().fields.getMap().get(fieldName);

            if (field == null) {
                continue;
            }

            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            if (fieldDescribe.isNameField()) {
                displayFieldApiName = fieldDescribe.getName();
                break;
            }
        }

        return relationshipName + '.' + displayFieldApiName;
    }

    private static String getTabIcon(Schema.SObjectType sobjectType) {
        String sobjectName = sobjectType.getDescribe().getName();

        String tabIcon;
        for (Schema.DescribeTabSetResult tabSetResult : Schema.describeTabs()) {
            if (tabIcon != null) {
                break;
            }

            for (Schema.DescribeTabResult tabResult : tabSetResult.getTabs()) {
                if (tabIcon != null) {
                    break;
                }
                if (tabResult.getSObjectName() != sobjectName) {
                    continue;
                }

                String iconType = tabResult.isCustom() ? 'custom' : 'standard';
                String svgIconName;
                for (Schema.DescribeIconResult icon : tabResult.getIcons()) {
                    if (icon.getContentType() != 'image/svg+xml') {
                        continue;
                    }

                    svgIconName = icon.getUrl().substringAfterLast('/').replace('.svg', '');
                    tabIcon = iconType + ':' + svgIconName;
                    break;
                }
            }
        }
        // Hardcoded exceptions - Salesforce doesn't return SVGs for these objects, so hardcoding is necessary
        if (tabIcon == null && sobjectName == 'Asset') {
            tabIcon = 'standard:maintenance_asset';
        } else if (tabIcon == null && sobjectName == 'AssetRelationship') {
            tabIcon = 'standard:asset_relationship';
        }

        return tabIcon;
    }
}
