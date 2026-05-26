//------------------------------------------------------------------------------------------------//
// Prototype 2 — Dynamic query builder. The query never calls Database.query directly; it hands
// itself to a swappable Executor. Production wires up the default executor (which calls
// Database.query); tests provide their own Executor that inspects the query (SObjectType,
// filter fields, filter values, limit, etc.) and returns whatever they want.
//
// This is the most flexible of the three: the Executor can match on anything the test cares
// about because it has the full LoggerQuery in hand. Tradeoff: tests have to write a (small)
// class to do that matching.
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount')
public without sharing class LoggerQuery {
  // ---------------------------------------------------------------------------------------------
  // Executor — swappable for tests
  // ---------------------------------------------------------------------------------------------

  public interface Executor {
    Object execute(LoggerQuery query);
  }

  private static Executor activeExecutor = new DefaultExecutor();

  @TestVisible
  private static void setExecutor(Executor executor) {
    activeExecutor = executor;
  }

  // ---------------------------------------------------------------------------------------------
  // Fluent query API
  // ---------------------------------------------------------------------------------------------

  // Public read-only accessors so test executors can inspect the query.
  public final Schema.SObjectType sobjectType { get; private set; }
  public final List<String> selectedFieldPaths {
    get {
      return new List<String>(this.selectedFieldPathsInternal);
    }
  }
  public final List<Schema.SObjectField> filterFields {
    get {
      return new List<Schema.SObjectField>(this.filterFieldsInternal);
    }
  }
  public final List<Object> filterValues {
    get {
      return new List<Object>(this.filterValuesInternal);
    }
  }
  public Integer rowLimit { get; private set; }

  private final Set<String> selectedFieldPathsInternal = new Set<String>();
  private final List<Schema.SObjectField> filterFieldsInternal = new List<Schema.SObjectField>();
  private final List<Object> filterValuesInternal = new List<Object>();
  private final List<WhereClause> whereClauses = new List<WhereClause>();

  private LoggerQuery(Schema.SObjectType sobjectType) {
    this.sobjectType = sobjectType;
  }

  public static LoggerQuery of(Schema.SObjectType sobjectType) {
    return new LoggerQuery(sobjectType);
  }

  public LoggerQuery selectFields(List<Schema.SObjectField> fields) {
    for (Schema.SObjectField field : fields) {
      this.selectedFieldPathsInternal.add(String.valueOf(field));
    }
    return this;
  }

  public LoggerQuery selectField(Schema.SObjectField field) {
    this.selectedFieldPathsInternal.add(String.valueOf(field));
    return this;
  }

  public LoggerQuery selectFieldPath(String fieldPath) {
    this.selectedFieldPathsInternal.add(fieldPath);
    return this;
  }

  public WhereBuilder whereField(Schema.SObjectField field) {
    this.filterFieldsInternal.add(field);
    return new WhereBuilder(this, field);
  }

  public LoggerQuery setLimit(Integer rowLimit) {
    this.rowLimit = rowLimit;
    return this;
  }

  // ---------------------------------------------------------------------------------------------
  // Execution — delegates to the active executor (real or test-provided)
  // ---------------------------------------------------------------------------------------------

  public List<SObject> toList() {
    return (List<SObject>) activeExecutor.execute(this);
  }

  public SObject toRecord() {
    List<SObject> results = this.toList();
    return results.isEmpty() ? null : results.get(0);
  }

  public String toSoql() {
    Set<String> fieldPaths = this.selectedFieldPathsInternal.isEmpty() ? new Set<String>{ 'Id' } : this.selectedFieldPathsInternal;
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
    private final Schema.SObjectField field;

    private WhereBuilder(LoggerQuery query, Schema.SObjectField field) {
      this.query = query;
      this.field = field;
    }

    public LoggerQuery inCollection(List<Object> values) {
      this.query.whereClauses.add(new WhereClause(this.field, 'IN', values));
      this.query.filterValuesInternal.add(values);
      return this.query;
    }

    public LoggerQuery equals(Object value) {
      this.query.whereClauses.add(new WhereClause(this.field, '=', value));
      this.query.filterValuesInternal.add(value);
      return this.query;
    }
  }

  private class WhereClause {
    private final Schema.SObjectField field;
    private final String operator;
    private final Object value;

    private WhereClause(Schema.SObjectField field, String operator, Object value) {
      this.field = field;
      this.operator = operator;
      this.value = value;
    }

    @SuppressWarnings('PMD.UnusedLocalVariable')
    public String toSoql() {
      Object bindValue = this.value;
      if (this.operator == 'IN') {
        return String.valueOf(this.field) + ' IN :bindValue';
      }
      return String.valueOf(this.field) + ' ' + this.operator + ' :bindValue';
    }
  }

  // ---------------------------------------------------------------------------------------------
  // Default executor — the only place SOQL actually runs
  // ---------------------------------------------------------------------------------------------

  private class DefaultExecutor implements Executor {
    public Object execute(LoggerQuery query) {
      return System.Database.query(query.toSoql());
    }
  }
}
