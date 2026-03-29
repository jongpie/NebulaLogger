//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Controller class for the lightning web component `related-log-entries`
 */
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class RelatedLogEntriesController {
  private static final Schema.SObjectType LOG_SOBJECT_TYPE = Schema.Log__c.SObjectType;
  private static final Schema.SObjectType LOG_ENTRY_SOBJECT_TYPE = Schema.LogEntry__c.SObjectType;
  private static final String DEFAULT_SORT_FIELD_NAME = String.valueOf(Schema.LogEntry__c.Timestamp__c);
  private static final String DEFAULT_SORT_DIRECTION = 'DESC';

  /**
   * @description Used by the component relatedLogEntries to get log entries for a particular record (based on record ID)
   * @param  recordId        Used to filter LogEntry__c records where RecordId__c == recordId
   * @param  fieldSetName    The API/developer name of the field set
   * @param  rowLimit        The max number of rows to query

   * @param  sortByFieldName The field to sort by
   * @param  sortDirection   The direction to sort by (asc or desc))
   * @param  search          An optional search term to filter by
   * @return                 The instance of LogEntryQueryResult, containing matching records and metadata
   */
  @SuppressWarnings('PMD.ExcessiveParameterList')
  @AuraEnabled(cacheable=true)
  public static LogEntryQueryResult getQueryResult(
    Id recordId,
    String fieldSetName,
    Integer rowLimit,
    String sortByFieldName,
    String sortDirection,
    String search
  ) {
    FieldSetMetadata fieldSetMetdata = new FieldSetMetadata(LOG_ENTRY_SOBJECT_TYPE, fieldSetName);

    String fieldsClause = getFieldsClause(fieldSetMetdata.fields);
    String orderByClause = getOrderByClause(sortByFieldName, sortDirection);

    List<LogEntry__c> records = search(recordId, search, fieldsClause, orderByClause, rowLimit);
    return new LogEntryQueryResult(fieldSetMetdata, records);
  }

  @SuppressWarnings('PMD.ExcessiveParameterList')
  private static List<LogEntry__c> search(Id recordId, String searchTerm, String fieldsClause, String orderByClause, Integer rowLimit) {
    // SOSL can search for a 15-character ID, but for some reason, using the 18-character version returns no results (╯‵□′)╯︵┻━┻
    String fullSearchExpression = '*' + String.escapeSingleQuotes(String.valueOf(recordId).left(15)) + '*';
    if (String.isNotBlank(searchTerm)) {
      fullSearchExpression += ' AND *' + String.escapeSingleQuotes(searchTerm) + '*';
    }
    fullSearchExpression = '\'' + fullSearchExpression + '\'';

    List<Object> searchTextReplacements = new List<Object>{
      fullSearchExpression,
      String.valueOf(Schema.LogEntry__c.SObjectType),
      fieldsClause,
      orderByClause,
      rowLimit
    };
    String logEntrySearch = String.format('FIND {0} IN ALL FIELDS RETURNING {1} ({2} ORDER BY {3} LIMIT {4})', searchTextReplacements);

    List<LogEntry__c> matches = (List<LogEntry__c>) System.Search.query(logEntrySearch).get(0);

    // Somewhat redundant security check for FLS (but extra security > less security)
    return System.Security.stripInaccessible(System.AccessType.READABLE, matches).getRecords();
  }

  private static String getFieldsClause(List<FieldMetadata> fields) {
    // Make sure these fields are always included, even if they're not in the fieldset, in case the LWC needs them
    Set<String> fieldNames = new Set<String>{
      LogEntry__c.DatabaseResultJson__c.toString(),
      LogEntry__c.RecordId__c.toString(),
      LogEntry__c.RecordJson__c.toString()
    };
    for (FieldMetadata fieldMetadata : fields) {
      fieldNames.add(fieldMetadata.type == 'picklist' ? ('toLabel(' + fieldMetadata.fieldName + ')') : fieldMetadata.fieldName);

      // For lookups, also include the display name of parent object
      if (fieldMetadata.lookupDisplayFieldName != null) {
        fieldNames.add(fieldMetadata.lookupDisplayFieldName);
      }
    }

    return String.join(fieldNames, ',');
  }

  private static String getOrderByClause(String sortByFieldName, String sortDirection) {
    sortByFieldName = String.isNotBlank(sortByFieldName) ? sortByFieldName : DEFAULT_SORT_FIELD_NAME;
    sortDirection = String.isNotBlank(sortDirection) ? sortDirection : DEFAULT_SORT_DIRECTION;

    Schema.SObjectfield field = LOG_ENTRY_SOBJECT_TYPE.getDescribe().fields.getMap().get(sortByFieldName);
    // For lookups, sort by the parent record's display field name (Name, CaseNumber, Subject, etc.)
    if (field.getDescribe().getType() == Schema.DisplayType.REFERENCE) {
      sortByFieldName = getDisplayFieldApiName(field.getDescribe());
    }

    return sortByFieldName + ' ' + sortDirection;
  }

  private static String getDisplayFieldApiName(Schema.DescribeFieldResult lookupFieldDescribe) {
    String relationshipName = lookupFieldDescribe.getRelationshipName();
    Schema.SObjectType lookupSObjectType = lookupFieldDescribe.getReferenceTo().get(0);

    // Use username instead of name for user
    if (lookupSObjectType == Schema.User.SObjectType) {
      return relationshipName + '.' + Schema.User.Username.toString();
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

      if (field != null) {
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

        if (fieldDescribe.isNameField()) {
          displayFieldApiName = fieldDescribe.getName();
          break;
        }
      }
    }

    return relationshipName + '.' + displayFieldApiName;
  }

  /**
   * @description Inner, wrapper class that contains query result information after querying related log entries.
   */
  public class LogEntryQueryResult {
    /**
     * @description Contains the fieldSet associated with this query.
     */
    @AuraEnabled
    public FieldSetMetadata fieldSet { get; set; }

    /**
     * @description Contains the result of the CRUD check, determining if the log entry is "accessible" for the current user.
     */
    @AuraEnabled
    public Boolean isAccessible { get; set; }

    /**
     * @description Contains the label of the log entry sObject, fetched using a describe call in the constructor.
     */
    @AuraEnabled
    public String label { get; set; }

    /**
     * @description Contains the plural label of the log entry sObject, fetched using a describe call in the constructor.
     */
    @AuraEnabled
    public String labelPlural { get; set; }

    /**
     * @description contains the log entry results from the query.
     */
    @AuraEnabled
    public List<LogEntry__c> records { get; set; }

    private LogEntryQueryResult(FieldSetMetadata fieldSetMetadata, List<LogEntry__c> records) {
      this.fieldSet = fieldSetMetadata;
      this.isAccessible = LOG_ENTRY_SOBJECT_TYPE.getDescribe().isAccessible();
      this.label = LOG_ENTRY_SOBJECT_TYPE.getDescribe().getLabel();
      this.labelPlural = LOG_ENTRY_SOBJECT_TYPE.getDescribe().getLabelPlural();
      this.records = records;
    }
  }

  /**
   * @description Inner, wrapper class, containing metadata around the list of fields used in the related log entry query.
   */
  public class FieldSetMetadata {
    /**
     * @description A list of field related metadata
     */
    @AuraEnabled
    public List<FieldMetadata> fields { get; set; }

    /**
     * @description Contains the label of the desired field set, fetched using a describe call on the field set.
     */
    @AuraEnabled
    public String label { get; set; }

    /**
     * @description A string containing the API name of the field set, including the namespace prefix, if applicable.
     */
    @AuraEnabled
    public String name { get; set; }

    private FieldSetMetadata(Schema.SObjectType sobjectType, String fieldSetName) {
      this.fields = new List<FieldMetadata>();

      Schema.FieldSet fieldSet = sobjectType.getDescribe().fieldSets.getMap().get(fieldSetName);
      for (Schema.FieldSetMember fieldSetMember : fieldSet.getFields()) {
        // Enforce field-level security (FLS)
        if (fieldSetMember.getSObjectField().getDescribe().isAccessible()) {
          this.fields.add(new FieldMetadata(fieldSetMember));
        }
      }

      String namespacePrefix = String.isBlank(fieldSet.getNamespace()) ? '' : fieldSet.getNamespace() + '__';

      this.label = fieldSet.getLabel();
      this.name = namespacePrefix + fieldSet.getName();
    }
  }

  /**
   * @description An inner, wrapper class containing metadata information about an individual field.
   */
  public class FieldMetadata {
    /**
     * @description A string containing the API name of the field, in particular the field path as it relates to the parent field set.
     */
    @AuraEnabled
    public String fieldName { get; set; }

    /**
     * @description Boolean that returns true if this field is the standard Name field for its parent object.
     */
    @AuraEnabled
    public Boolean isNameField { get; set; }

    /**
     * @description A string containing the label of the field.
     */
    @AuraEnabled
    public String label { get; set; }

    /**
     * @description A string used for lookup fields to indicate the display name of the lookup / relationship.
     */
    @AuraEnabled
    public String lookupDisplayFieldName { get; set; }

    /**
     * @description Boolean that returns true if this field is sortable.
     */
    @AuraEnabled
    public Boolean sortable { get; set; }

    /**
     * @description If the field is a lookup or master detail relationship, this string will return the relationship API name.  For instance: Lookup__r instead of Lookup__c.
     */
    @AuraEnabled
    public String relationshipName { get; set; }

    /**
     * @description Returns the type of the field, matching the Schema.DisplayType ENUM values, but in all lowercase letters.
     */
    @AuraEnabled
    public String type { get; set; }

    private FieldMetadata(Schema.FieldSetMember fieldSetMember) {
      Schema.DescribeFieldResult fieldDescribe = fieldSetMember.getSObjectField().getDescribe();

      this.fieldName = fieldSetMember.getFieldPath();
      this.isNameField = fieldDescribe.isNameField();
      this.label = fieldSetMember.getLabel();
      this.relationshipName = fieldDescribe.getRelationshipName();
      this.sortable = fieldDescribe.isSortable();
      this.type = fieldDescribe.getType().name().toLowerCase();
      if (fieldDescribe.getReferenceTo().size() == 1) {
        // Handle single-object (normal) lookups
        this.lookupDisplayFieldName = getDisplayFieldApiName(fieldDescribe);
      }
    }
  }
}
