//------------------------------------------------------------------------------------------------//
// Prototype 3 — Dynamic query builder. Production code opts a query into mockability by giving
// it a unique tag (e.g. .tag('LogHandler.parentLookup')). Tests register results against tags:
//
//   LoggerQuery.mockResult('LogHandler.parentLookup', new List<Log__c>{ ... });
//
// Untagged queries always run as real SOQL — there's no fingerprint-matching ambiguity. The
// tradeoff is that production code now carries test concerns (the tag).
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount')
public without sharing class LoggerQuery {
  // ---------------------------------------------------------------------------------------------
  // Mock registry — keyed by tag. Tagged queries hit it; untagged queries skip it.
  // ---------------------------------------------------------------------------------------------

  @TestVisible
  private static final Map<String, Object> MOCK_RESULTS_BY_TAG = new Map<String, Object>();
  @TestVisible
  private static final Map<String, Integer> CALL_COUNTS_BY_TAG = new Map<String, Integer>();

  /**
   * @description Register a mock result for the given tag. Any LoggerQuery in production with
   *              `.tag(theSameString)` will return this value instead of executing SOQL.
   */
  @TestVisible
  private static void mockResult(String tag, Object result) {
    MOCK_RESULTS_BY_TAG.put(tag, result);
  }

  /**
   * @description Returns how many times a tagged query was executed. Useful for
   *              `Assert.areEqual(0, ...)` to prove a code path was skipped.
   */
  @TestVisible
  private static Integer callCountForTag(String tag) {
    return CALL_COUNTS_BY_TAG.containsKey(tag) ? CALL_COUNTS_BY_TAG.get(tag) : 0;
  }

  // ---------------------------------------------------------------------------------------------
  // Fluent query API
  // ---------------------------------------------------------------------------------------------

  private final Schema.SObjectType sobjectType;
  private final Set<String> selectedFieldPaths = new Set<String>();
  private final List<WhereClause> whereClauses = new List<WhereClause>();
  private String queryTag;
  private Integer rowLimit;

  private LoggerQuery(Schema.SObjectType sobjectType) {
    this.sobjectType = sobjectType;
  }

  public static LoggerQuery of(Schema.SObjectType sobjectType) {
    return new LoggerQuery(sobjectType);
  }

  /**
   * @description Marks this query with a unique identifier so tests can stub its result via
   *              `LoggerQuery.mockResult(tag, ...)`. Untagged queries cannot be stubbed.
   *              By convention, tags are dot-separated `<class>.<purpose>` strings.
   */
  public LoggerQuery tag(String tag) {
    this.queryTag = tag;
    return this;
  }

  public LoggerQuery selectFields(List<Schema.SObjectField> fields) {
    for (Schema.SObjectField field : fields) {
      this.selectedFieldPaths.add(String.valueOf(field));
    }
    return this;
  }

  public LoggerQuery selectField(Schema.SObjectField field) {
    this.selectedFieldPaths.add(String.valueOf(field));
    return this;
  }

  public LoggerQuery selectFieldPath(String fieldPath) {
    this.selectedFieldPaths.add(fieldPath);
    return this;
  }

  public WhereBuilder whereField(Schema.SObjectField field) {
    return new WhereBuilder(this, String.valueOf(field));
  }

  public LoggerQuery setLimit(Integer rowLimit) {
    this.rowLimit = rowLimit;
    return this;
  }

  // ---------------------------------------------------------------------------------------------
  // Execution
  // ---------------------------------------------------------------------------------------------

  public List<SObject> toList() {
    if (this.queryTag != null) {
      Integer prior = CALL_COUNTS_BY_TAG.containsKey(this.queryTag) ? CALL_COUNTS_BY_TAG.get(this.queryTag) : 0;
      CALL_COUNTS_BY_TAG.put(this.queryTag, prior + 1);

      if (MOCK_RESULTS_BY_TAG.containsKey(this.queryTag)) {
        return (List<SObject>) MOCK_RESULTS_BY_TAG.get(this.queryTag);
      }
    }
    return System.Database.query(this.toSoql());
  }

  public SObject toRecord() {
    List<SObject> results = this.toList();
    return results.isEmpty() ? null : results.get(0);
  }

  @TestVisible
  private String toSoql() {
    Set<String> fieldPaths = this.selectedFieldPaths.isEmpty() ? new Set<String>{ 'Id' } : this.selectedFieldPaths;
    String soql = 'SELECT ' + String.join(fieldPaths, ', ') + ' FROM ' + this.sobjectType;
    if (this.whereClauses.isEmpty() == false) {
      List<String> clauseStrings = new List<String>();
      for (WhereClause clause : this.whereClauses) {
        clauseStrings.add(clause.toSoql());
      }
      soql += ' WHERE ' + String.join(clauseStrings, ' AND ');
    }
    if (this.rowLimit != null) {
      soql += ' LIMIT ' + this.rowLimit;
    }
    return soql;
  }

  // ---------------------------------------------------------------------------------------------
  // Internal types
  // ---------------------------------------------------------------------------------------------

  public class WhereBuilder {
    private final LoggerQuery query;
    private final String fieldPath;

    private WhereBuilder(LoggerQuery query, String fieldPath) {
      this.query = query;
      this.fieldPath = fieldPath;
    }

    public LoggerQuery inCollection(List<Object> values) {
      this.query.whereClauses.add(new WhereClause(this.fieldPath, 'IN', values));
      return this.query;
    }

    public LoggerQuery equals(Object value) {
      this.query.whereClauses.add(new WhereClause(this.fieldPath, '=', value));
      return this.query;
    }
  }

  private class WhereClause {
    private final String fieldPath;
    private final String operator;
    private final Object value;

    private WhereClause(String fieldPath, String operator, Object value) {
      this.fieldPath = fieldPath;
      this.operator = operator;
      this.value = value;
    }

    @SuppressWarnings('PMD.UnusedLocalVariable')
    public String toSoql() {
      Object bindValue = this.value;
      if (this.operator == 'IN') {
        return this.fieldPath + ' IN :bindValue';
      }
      return this.fieldPath + ' ' + this.operator + ' :bindValue';
    }
  }
}
