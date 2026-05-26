//------------------------------------------------------------------------------------------------//
// Prototype 1 — Dynamic query builder. Mocks are matched by query "fingerprint": SObjectType +
// the set of fields used in WHERE filters. Tests register: "for Log__c queries that filter on
// TransactionId__c, return this list." The query never executes SOQL when a fingerprint matches.
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount')
public without sharing class LoggerQuery {
  // ---------------------------------------------------------------------------------------------
  // Mock registry — populated by tests via LoggerQuery.mockResult()...thenReturn(...)
  // ---------------------------------------------------------------------------------------------
  @TestVisible
  private static final List<MockRegistration> MOCK_REGISTRATIONS = new List<MockRegistration>();

  /**
   * @description Begin registering a mock result. Chain `.forSObjectType(...)`,
   *              `.withFilterOn(...)`, and `.thenReturn(...)` to define the match.
   *              Example:
   *                LoggerQuery.mockResult()
   *                  .forSObjectType(Schema.Log__c.SObjectType)
   *                  .withFilterOn(Schema.Log__c.TransactionId__c)
   *                  .thenReturn(new List<Log__c>{ mockLog });
   */
  @TestVisible
  private static MockRegistrationBuilder mockResult() {
    return new MockRegistrationBuilder();
  }

  // ---------------------------------------------------------------------------------------------
  // Fluent query API
  // ---------------------------------------------------------------------------------------------

  private final Schema.SObjectType sobjectType;
  private final Set<String> selectedFieldPaths = new Set<String>();
  private final List<WhereClause> whereClauses = new List<WhereClause>();
  private final Set<Schema.SObjectField> filterFields = new Set<Schema.SObjectField>();
  private Integer rowLimit;

  private LoggerQuery(Schema.SObjectType sobjectType) {
    this.sobjectType = sobjectType;
  }

  public static LoggerQuery of(Schema.SObjectType sobjectType) {
    return new LoggerQuery(sobjectType);
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

  /** String fallback for parent-field paths and other cases the typed API doesn't cover yet. */
  public LoggerQuery selectFieldPath(String fieldPath) {
    this.selectedFieldPaths.add(fieldPath);
    return this;
  }

  public WhereBuilder whereField(Schema.SObjectField field) {
    this.filterFields.add(field);
    return new WhereBuilder(this, String.valueOf(field));
  }

  public LoggerQuery setLimit(Integer rowLimit) {
    this.rowLimit = rowLimit;
    return this;
  }

  // ---------------------------------------------------------------------------------------------
  // Execution — checks mock registry first
  // ---------------------------------------------------------------------------------------------

  public List<SObject> toList() {
    Object mockResult = this.findMatchingMockResult();
    if (mockResult != null) {
      return (List<SObject>) mockResult;
    }
    return System.Database.query(this.toSoql());
  }

  public SObject toRecord() {
    List<SObject> results = this.toList();
    return results.isEmpty() ? null : results.get(0);
  }

  @TestVisible
  private String toSoql() {
    if (this.selectedFieldPaths.isEmpty()) {
      this.selectedFieldPaths.add('Id');
    }
    String soql = 'SELECT ' + String.join(this.selectedFieldPaths, ', ') + ' FROM ' + this.sobjectType;
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

  private Object findMatchingMockResult() {
    for (MockRegistration registration : MOCK_REGISTRATIONS) {
      if (registration.matches(this.sobjectType, this.filterFields)) {
        return registration.result;
      }
    }
    return null;
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
      // Minimal binding for the prototype: in real impl, bindings need named-variable support.
      // Apex's Database.queryWithBinds exists since API 60.0 and is the right primitive here.
      Object bindValue = this.value;
      if (this.operator == 'IN') {
        return this.fieldPath + ' IN :bindValue';
      }
      return this.fieldPath + ' ' + this.operator + ' :bindValue';
    }
  }

  // ---------------------------------------------------------------------------------------------
  // Mock registration types
  // ---------------------------------------------------------------------------------------------

  @TestVisible
  private class MockRegistrationBuilder {
    private Schema.SObjectType sobjectType;
    private final Set<Schema.SObjectField> filterFields = new Set<Schema.SObjectField>();

    public MockRegistrationBuilder forSObjectType(Schema.SObjectType sobjectType) {
      this.sobjectType = sobjectType;
      return this;
    }

    public MockRegistrationBuilder withFilterOn(Schema.SObjectField field) {
      this.filterFields.add(field);
      return this;
    }

    public MockRegistrationBuilder withFilterOn(List<Schema.SObjectField> fields) {
      this.filterFields.addAll(fields);
      return this;
    }

    public void thenReturn(Object result) {
      MOCK_REGISTRATIONS.add(new MockRegistration(this.sobjectType, this.filterFields, result));
    }
  }

  private class MockRegistration {
    private final Schema.SObjectType sobjectType;
    private final Set<Schema.SObjectField> filterFields;
    private final Object result;

    private MockRegistration(Schema.SObjectType sobjectType, Set<Schema.SObjectField> filterFields, Object result) {
      this.sobjectType = sobjectType;
      this.filterFields = filterFields;
      this.result = result;
    }

    /**
     * @description Matches if the query is for the same SObjectType AND the registered filter
     *              field set is a subset of the query's filter field set. (i.e. registering
     *              "filters on TransactionId__c" matches a query with WHERE TransactionId__c IN
     *              :ids regardless of what other filters the query may add.)
     */
    public Boolean matches(Schema.SObjectType querySObjectType, Set<Schema.SObjectField> queryFilterFields) {
      if (this.sobjectType != querySObjectType) {
        return false;
      }
      return queryFilterFields.containsAll(this.filterFields);
    }
  }
}
